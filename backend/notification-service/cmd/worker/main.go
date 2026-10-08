// Command worker runs the FCM/Mail/SMS notification consumers. It connects
// to RabbitMQ, declares the topology (idempotent), and runs one consumer
// goroutine per channel until it receives SIGINT/SIGTERM.
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"talkmos/notification-service/internal/config"
	"talkmos/notification-service/internal/fcm"
	"talkmos/notification-service/internal/mail"
	"talkmos/notification-service/internal/queue"
	"talkmos/notification-service/internal/sms"
)

func main() {
	if err := run(); err != nil {
		log.Fatalf("fatal: %v", err)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	client, err := queue.Connect(cfg.RabbitMQURL)
	if err != nil {
		return err
	}
	defer client.Close()

	channels := []queue.Channel{queue.ChannelFCM, queue.ChannelMail, queue.ChannelSMS}
	if err := client.Topology(channels); err != nil {
		return err
	}

	fcmSender, err := fcm.NewSender(ctx, cfg.FirebaseCredentialsPath)
	if err != nil {
		return err
	}
	mailSender := mail.NewSender(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPass, cfg.SMTPFrom)
	smsSender := sms.NewSender(cfg.Fast2SMSAPIKey)

	go serveHealth(ctx, cfg.HealthPort)

	var wg sync.WaitGroup
	consume := func(chn queue.Channel, handler queue.HandlerFunc) {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := client.Consume(ctx, chn, cfg.MaxRetries, handler); err != nil {
				log.Printf("[%s] consumer stopped: %v", chn, err)
			}
		}()
	}

	consume(queue.ChannelFCM, fcmSender.Handle)
	consume(queue.ChannelMail, mailSender.Handle)
	consume(queue.ChannelSMS, smsSender.Handle)

	log.Println("notification-service: consumers started (fcm, mail, sms)")
	<-ctx.Done()
	log.Println("shutting down, draining in-flight jobs...")
	wg.Wait()
	return nil
}

func serveHealth(ctx context.Context, port string) {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})
	srv := &http.Server{Addr: ":" + port, Handler: mux}

	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		srv.Shutdown(shutdownCtx)
	}()

	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Printf("health server error: %v", err)
	}
}
