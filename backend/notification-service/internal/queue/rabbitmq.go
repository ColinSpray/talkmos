// Package queue owns the RabbitMQ topology and a generic per-channel
// consumer loop shared by the fcm/mail/sms workers.
//
// Topology (plugin-free delayed-retry pattern):
//
//	notifications        (topic exchange) — Node publishes here with
//	                      routing key "notification.<channel>"
//	<channel>_queue       — the real work queue; on nack it dead-letters to
//	                        notifications.retry
//	notifications.retry   (topic exchange)
//	<channel>_queue.retry — same routing key, x-message-ttl parks the
//	                        message for RetryDelay then dead-letters it
//	                        back to the "notifications" exchange, i.e.
//	                        redelivers it to <channel>_queue
//	notifications.dlq     (topic exchange) — where a job goes for good once
//	                        it's failed MaxRetries times
//	<channel>_queue.dlq
//
// RabbitMQ's own x-death header tracks how many times a message has cycled
// through the retry queue, so retry-count tracking needs no extra plugin or
// state.
package queue

import (
	"context"
	"fmt"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

const (
	MainExchange  = "notifications"
	RetryExchange = "notifications.retry"
	DLQExchange   = "notifications.dlq"

	RetryDelay = 30 * time.Second
)

type Channel string

const (
	ChannelFCM  Channel = "fcm"
	ChannelMail Channel = "mail"
	ChannelSMS  Channel = "sms"
)

func (c Channel) RoutingKey() string     { return "notification." + string(c) }
func (c Channel) QueueName() string      { return string(c) + "_queue" }
func (c Channel) RetryQueueName() string { return c.QueueName() + ".retry" }
func (c Channel) DLQName() string        { return c.QueueName() + ".dlq" }

type Client struct {
	conn *amqp.Connection
}

func Connect(url string) (*Client, error) {
	conn, err := amqp.Dial(url)
	if err != nil {
		return nil, fmt.Errorf("connect to rabbitmq: %w", err)
	}
	return &Client{conn: conn}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

// Topology declares the exchanges/queues/bindings for every channel. Safe to
// call on every startup — all declarations are idempotent.
func (c *Client) Topology(channels []Channel) error {
	ch, err := c.conn.Channel()
	if err != nil {
		return fmt.Errorf("open channel: %w", err)
	}
	defer ch.Close()

	for _, ex := range []string{MainExchange, RetryExchange, DLQExchange} {
		if err := ch.ExchangeDeclare(ex, "topic", true, false, false, false, nil); err != nil {
			return fmt.Errorf("declare exchange %s: %w", ex, err)
		}
	}

	for _, chn := range channels {
		if err := declareChannelQueues(ch, chn); err != nil {
			return err
		}
	}
	return nil
}

func declareChannelQueues(ch *amqp.Channel, chn Channel) error {
	routingKey := chn.RoutingKey()

	// Main work queue — failed jobs dead-letter into the retry exchange.
	_, err := ch.QueueDeclare(chn.QueueName(), true, false, false, false, amqp.Table{
		"x-dead-letter-exchange":    RetryExchange,
		"x-dead-letter-routing-key": routingKey,
	})
	if err != nil {
		return fmt.Errorf("declare %s: %w", chn.QueueName(), err)
	}
	if err := ch.QueueBind(chn.QueueName(), routingKey, MainExchange, false, nil); err != nil {
		return fmt.Errorf("bind %s: %w", chn.QueueName(), err)
	}

	// Retry queue — parks the message for RetryDelay, then dead-letters it
	// back to the main exchange for redelivery.
	_, err = ch.QueueDeclare(chn.RetryQueueName(), true, false, false, false, amqp.Table{
		"x-dead-letter-exchange":    MainExchange,
		"x-dead-letter-routing-key": routingKey,
		"x-message-ttl":             int32(RetryDelay / time.Millisecond),
	})
	if err != nil {
		return fmt.Errorf("declare %s: %w", chn.RetryQueueName(), err)
	}
	if err := ch.QueueBind(chn.RetryQueueName(), routingKey, RetryExchange, false, nil); err != nil {
		return fmt.Errorf("bind %s: %w", chn.RetryQueueName(), err)
	}

	// Dead-letter queue — final graveyard past MaxRetries.
	_, err = ch.QueueDeclare(chn.DLQName(), true, false, false, false, nil)
	if err != nil {
		return fmt.Errorf("declare %s: %w", chn.DLQName(), err)
	}
	if err := ch.QueueBind(chn.DLQName(), routingKey, DLQExchange, false, nil); err != nil {
		return fmt.Errorf("bind %s: %w", chn.DLQName(), err)
	}

	return nil
}

// HandlerFunc processes one job's raw JSON body. A returned error triggers
// the retry/DLQ flow.
type HandlerFunc func(ctx context.Context, body []byte) error

// Consume runs handler for every message on chn's queue until ctx is
// cancelled. Jobs that keep failing past maxRetries are routed to the
// channel's DLQ instead of retried forever.
func (c *Client) Consume(ctx context.Context, chn Channel, maxRetries int, handler HandlerFunc) error {
	ch, err := c.conn.Channel()
	if err != nil {
		return fmt.Errorf("open channel: %w", err)
	}
	defer ch.Close()

	if err := ch.Qos(10, 0, false); err != nil {
		return fmt.Errorf("set qos: %w", err)
	}

	deliveries, err := ch.Consume(chn.QueueName(), "", false, false, false, false, nil)
	if err != nil {
		return fmt.Errorf("consume %s: %w", chn.QueueName(), err)
	}

	for {
		select {
		case <-ctx.Done():
			return nil
		case d, ok := <-deliveries:
			if !ok {
				return fmt.Errorf("delivery channel for %s closed", chn.QueueName())
			}
			c.handleDelivery(ctx, ch, chn, maxRetries, d, handler)
		}
	}
}

func (c *Client) handleDelivery(ctx context.Context, ch *amqp.Channel, chn Channel, maxRetries int, d amqp.Delivery, handler HandlerFunc) {
	if err := handler(ctx, d.Body); err == nil {
		d.Ack(false)
		return
	}

	if retryCount(d, chn) >= maxRetries {
		// Out of retries — move it to the DLQ ourselves and ack the
		// original so it stops cycling.
		_ = ch.PublishWithContext(ctx, DLQExchange, chn.RoutingKey(), false, false, amqp.Publishing{
			ContentType: d.ContentType,
			Body:        d.Body,
			Headers:     d.Headers,
		})
		d.Ack(false)
		return
	}

	// Nack without requeue: the queue's dead-letter config routes this to
	// the retry queue, where it waits out RetryDelay before coming back.
	d.Nack(false, false)
}

// retryCount reads how many times this message has already cycled through
// chn's retry queue, via RabbitMQ's own x-death bookkeeping.
func retryCount(d amqp.Delivery, chn Channel) int {
	xDeath, ok := d.Headers["x-death"].([]interface{})
	if !ok {
		return 0
	}
	for _, entry := range xDeath {
		m, ok := entry.(amqp.Table)
		if !ok {
			continue
		}
		if queue, _ := m["queue"].(string); queue == chn.RetryQueueName() {
			if count, ok := m["count"].(int64); ok {
				return int(count)
			}
		}
	}
	return 0
}
