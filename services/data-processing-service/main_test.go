package main

import (
	"testing"
	"time"
)

func TestGetEnvDefault(t *testing.T) {
	if got := getEnv("THIS_KEY_DOES_NOT_EXIST", "default"); got != "default" {
		t.Fatalf("expected default, got %q", got)
	}
}

func TestProcessMessageUnknownType(t *testing.T) {
	body := []byte(`{"file_id":1,"filename":"a.dwg","s3_key":"k","s3_bucket":"b","project_id":"p","process_type":"unknown","timestamp":"2026-01-01T00:00:00Z"}`)
	if err := processMessage(body); err == nil {
		t.Fatalf("expected error for unknown process type")
	}
}

func TestProcessMessageValidateFast(t *testing.T) {
	start := time.Now()
	body := []byte(`{"file_id":1,"filename":"a.dwg","s3_key":"k","s3_bucket":"b","project_id":"p","process_type":"validate","timestamp":"2026-01-01T00:00:00Z"}`)
	if err := processMessage(body); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if time.Since(start) > 500*time.Millisecond {
		t.Fatalf("validate path too slow")
	}
}

