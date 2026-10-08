// Package sms sends SMS via Fast2SMS's HTTP API (https://www.fast2sms.com) —
// there's no official Go SDK, so this is a thin REST client for their
// "Quick SMS" (bulkV2) endpoint.
package sms

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"time"

	"talkmos/notification-service/internal/messages"
)

const apiURL = "https://www.fast2sms.com/dev/bulkV2"

var nonDigit = regexp.MustCompile(`\D`)

type Sender struct {
	apiKey string
	client *http.Client
}

func NewSender(apiKey string) *Sender {
	return &Sender{
		apiKey: apiKey,
		client: &http.Client{Timeout: 15 * time.Second},
	}
}

type fast2SMSResponse struct {
	Return  bool     `json:"return"`
	Message []string `json:"message"`
}

// Handle unmarshals an SMSJob and sends it. Matches queue.HandlerFunc so it
// can be passed straight to Client.Consume.
func (s *Sender) Handle(ctx context.Context, body []byte) error {
	var job messages.SMSJob
	if err := json.Unmarshal(body, &job); err != nil {
		return fmt.Errorf("unmarshal sms job: %w", err)
	}
	if job.To == "" || job.Message == "" {
		return fmt.Errorf("sms job missing recipient or message")
	}

	number := normalizeIndianNumber(job.To)

	form := url.Values{
		"route":    {"q"}, // quick transactional route
		"message":  {job.Message},
		"language": {"english"},
		"flash":    {"0"},
		"numbers":  {number},
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, strings.NewReader(form.Encode()))
	if err != nil {
		return fmt.Errorf("build fast2sms request: %w", err)
	}
	req.Header.Set("authorization", s.apiKey)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("fast2sms request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read fast2sms response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("fast2sms returned %d: %s", resp.StatusCode, respBody)
	}

	var parsed fast2SMSResponse
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return fmt.Errorf("parse fast2sms response: %w (body: %s)", err, respBody)
	}
	if !parsed.Return {
		return fmt.Errorf("fast2sms rejected message to %s: %v", number, parsed.Message)
	}
	return nil
}

// normalizeIndianNumber strips a leading country code and any non-digit
// characters — Fast2SMS's `numbers` param expects bare 10-digit numbers.
// Only strips a "91" prefix when the extra digits actually indicate a
// country code (12 digits total) — a bare 10-digit number legitimately
// starting with "91" (e.g. 91xxxxxxxx) must be left alone.
func normalizeIndianNumber(raw string) string {
	digits := nonDigit.ReplaceAllString(raw, "")
	if len(digits) == 12 && strings.HasPrefix(digits, "91") {
		digits = digits[2:]
	} else if len(digits) == 11 && strings.HasPrefix(digits, "0") {
		digits = digits[1:]
	}
	return digits
}
