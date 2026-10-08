// Package messages defines the JSON payload each queue carries. These
// structs are the contract with the Node backend's publisher — keep field
// names in sync with src/services/notificationQueue.js.
package messages

// FCMJob is published to the fcm_queue (routing key notification.fcm).
type FCMJob struct {
	Token string            `json:"token"`
	Title string            `json:"title"`
	Body  string            `json:"body"`
	Data  map[string]string `json:"data,omitempty"`
}

// MailJob is published to the mail_queue (routing key notification.mail).
type MailJob struct {
	To      string `json:"to"`
	Subject string `json:"subject"`
	Body    string `json:"body"`
	IsHTML  bool   `json:"isHtml"`
}

// SMSJob is published to the sms_queue (routing key notification.sms).
type SMSJob struct {
	To      string `json:"to"`
	Message string `json:"message"`
}
