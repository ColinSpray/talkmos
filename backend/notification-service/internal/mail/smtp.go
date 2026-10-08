// Package mail sends email via a plain SMTP server (host/port/user/pass) —
// works with any provider (Gmail, SES-SMTP, Mailgun-SMTP, Zoho, ...)
// without a vendor-specific SDK.
package mail

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net/smtp"
	"strings"

	"talkmos/notification-service/internal/messages"
)

type Sender struct {
	host string
	port int
	from string
	auth smtp.Auth
}

func NewSender(host string, port int, user, pass, from string) *Sender {
	return &Sender{
		host: host,
		port: port,
		from: from,
		auth: smtp.PlainAuth("", user, pass, host),
	}
}

// Handle unmarshals a MailJob and sends it. Matches queue.HandlerFunc so it
// can be passed straight to Client.Consume.
func (s *Sender) Handle(ctx context.Context, body []byte) error {
	var job messages.MailJob
	if err := json.Unmarshal(body, &job); err != nil {
		return fmt.Errorf("unmarshal mail job: %w", err)
	}
	if job.To == "" {
		return fmt.Errorf("mail job missing recipient")
	}

	contentType := "text/plain"
	if job.IsHTML {
		contentType = "text/html"
	}

	msg := strings.Join([]string{
		fmt.Sprintf("From: %s", s.from),
		fmt.Sprintf("To: %s", job.To),
		fmt.Sprintf("Subject: %s", job.Subject),
		fmt.Sprintf("Content-Type: %s; charset=UTF-8", contentType),
		"",
		job.Body,
	}, "\r\n")

	addr := fmt.Sprintf("%s:%d", s.host, s.port)
	if err := s.send(addr, job.To, msg); err != nil {
		return fmt.Errorf("send mail to %s: %w", job.To, err)
	}
	return nil
}

// send picks plain SMTP+STARTTLS on 587/25, or implicit TLS on 465 —
// covers the two conventions providers actually use.
func (s *Sender) send(addr, to, msg string) error {
	if s.port == 465 {
		return s.sendImplicitTLS(addr, to, msg)
	}
	return smtp.SendMail(addr, s.auth, s.from, []string{to}, []byte(msg))
}

func (s *Sender) sendImplicitTLS(addr, to, msg string) error {
	conn, err := tls.Dial("tcp", addr, &tls.Config{ServerName: s.host})
	if err != nil {
		return fmt.Errorf("tls dial: %w", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, s.host)
	if err != nil {
		return fmt.Errorf("smtp client: %w", err)
	}
	defer client.Close()

	if err := client.Auth(s.auth); err != nil {
		return fmt.Errorf("auth: %w", err)
	}
	if err := client.Mail(s.from); err != nil {
		return err
	}
	if err := client.Rcpt(to); err != nil {
		return err
	}
	w, err := client.Data()
	if err != nil {
		return err
	}
	if _, err := w.Write([]byte(msg)); err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return err
	}
	return client.Quit()
}
