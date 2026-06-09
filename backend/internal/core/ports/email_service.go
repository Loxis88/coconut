package ports

import "context"

type EmailService interface {
	SendVerificationEmail(ctx context.Context, to, token string) error
}
