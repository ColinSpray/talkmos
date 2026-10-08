package sms

import "testing"

func TestNormalizeIndianNumber(t *testing.T) {
	cases := map[string]string{
		"9876543210":      "9876543210",
		"+919876543210":   "9876543210",
		"919876543210":    "9876543210",
		"09876543210":     "9876543210",
		"+91 98765 43210": "9876543210",
		"9198765432":      "9198765432", // 10-digit number that happens to start with 91 — must not be mistaken for a country code
	}
	for in, want := range cases {
		if got := normalizeIndianNumber(in); got != want {
			t.Errorf("normalizeIndianNumber(%q) = %q, want %q", in, got, want)
		}
	}
}
