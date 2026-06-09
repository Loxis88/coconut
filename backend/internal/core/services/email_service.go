package services

import (
	"context"
	"fmt"
	"net/smtp"

	"github.com/coconut/backend/internal/core/ports"
)

type emailService struct {
	host     string
	port     string
	user     string
	password string
	from     string
}

func NewEmailService(host, port, user, password, from string) ports.EmailService {
	return &emailService{
		host:     host,
		port:     port,
		user:     user,
		password: password,
		from:     from,
	}
}

func (s *emailService) SendVerificationEmail(ctx context.Context, to, token string) error {
	// For production, use a nice HTML template. For now, a simple text email.
	subject := "Verify your Coconut account"
	// In a real app, this would be a link to the frontend: https://app.coconut.com/verify?token=...
	// For simplicity, let's just say "Here is your token".
	body := fmt.Sprintf("Welcome to Coconut! Please verify your email by clicking this link or using the token: %s", token)

	message := []byte(fmt.Sprintf("To: %s\r\n"+
		"Subject: %s\r\n"+
		"\r\n"+
		"%s\r\n", to, subject, body))

	auth := smtp.PlainAuth("", s.user, s.password, s.host)
	addr := fmt.Sprintf("%s:%s", s.host, s.port)

	if s.host == "" {
		// If no SMTP host is configured, just log it (useful for local dev without SMTP)
		fmt.Printf("MOCK EMAIL to %s: %s\n", to, body)
		return nil
	}

	return smtp.SendMail(addr, auth, s.from, []string{to}, message)
}
