// Package fcm sends push notifications via Firebase Cloud Messaging, using
// the same service-account credentials as the Node backend's fcmService.js
// (credentials/firebase-service-account.json), so no new Firebase setup is
// needed.
//
// This ports fcmService.js's sendPushNotification (the general chat-message
// / misc-alert push) — call-specific VoIP pushes (sendCallNotification,
// sendCallEndedNotification, with their CallKit/Full-Screen-Intent payload
// shapes) stay in the Node backend for now; they're a different enough
// message shape that folding them into this job schema wasn't worth the
// risk of silently changing call-notification behavior.
package fcm

import (
	"context"
	"encoding/json"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"

	"talkmos/notification-service/internal/messages"
)

type Sender struct {
	client *messaging.Client
}

func NewSender(ctx context.Context, credentialsPath string) (*Sender, error) {
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsPath))
	if err != nil {
		return nil, fmt.Errorf("init firebase app: %w", err)
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("init messaging client: %w", err)
	}
	return &Sender{client: client}, nil
}

// Handle unmarshals a FCMJob and sends it. Matches queue.HandlerFunc so it
// can be passed straight to Client.Consume.
func (s *Sender) Handle(ctx context.Context, body []byte) error {
	var job messages.FCMJob
	if err := json.Unmarshal(body, &job); err != nil {
		return fmt.Errorf("unmarshal fcm job: %w", err)
	}
	if job.Token == "" {
		// No registration token — nothing to retry, treat as handled.
		return nil
	}

	// Data-only on Android (no `notification` block): the OS displays
	// nothing and the app renders it via flutter_local_notifications
	// instead, which is what lets the user pick the message tone — an
	// OS-drawn notification is locked to its channel's sound, fixed at
	// channel-creation time. iOS has no equivalent client-side path, so it
	// still gets a real APNs alert below.
	data := map[string]string{"title": job.Title, "body": job.Body}
	for k, v := range job.Data {
		data[k] = v
	}

	_, err := s.client.Send(ctx, &messaging.Message{
		Token: job.Token,
		Data:  data,
		Android: &messaging.AndroidConfig{
			Priority: "high",
		},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{"apns-priority": "10"},
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{
						Title: job.Title,
						Body:  job.Body,
					},
					Sound: "default",
					Badge: intPtr(1),
				},
			},
		},
	})
	if err != nil {
		return fmt.Errorf("send fcm to %s: %w", job.Token, err)
	}
	return nil
}

func intPtr(i int) *int { return &i }
