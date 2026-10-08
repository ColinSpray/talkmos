package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	RabbitMQURL string

	FirebaseCredentialsPath string

	SMTPHost string
	SMTPPort int
	SMTPUser string
	SMTPPass string
	SMTPFrom string

	Fast2SMSAPIKey string

	HealthPort string

	// MaxRetries is how many times a failed job is redelivered (via the
	// retry-queue TTL/DLX chain) before it's routed to its channel's
	// permanent dead-letter queue.
	MaxRetries int
}

func Load() (*Config, error) {
	cfg := &Config{
		RabbitMQURL:             getEnv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/"),
		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", "/credentials/firebase-service-account.json"),
		SMTPHost:                os.Getenv("SMTP_HOST"),
		SMTPUser:                os.Getenv("SMTP_USER"),
		SMTPPass:                os.Getenv("SMTP_PASS"),
		SMTPFrom:                getEnv("SMTP_FROM", os.Getenv("SMTP_USER")),
		Fast2SMSAPIKey:          os.Getenv("FAST2SMS_API_KEY"),
		HealthPort:              getEnv("HEALTH_PORT", "8080"),
	}

	port, err := strconv.Atoi(getEnv("SMTP_PORT", "587"))
	if err != nil {
		return nil, fmt.Errorf("invalid SMTP_PORT: %w", err)
	}
	cfg.SMTPPort = port

	retries, err := strconv.Atoi(getEnv("MAX_RETRIES", "5"))
	if err != nil {
		return nil, fmt.Errorf("invalid MAX_RETRIES: %w", err)
	}
	cfg.MaxRetries = retries

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
