package ports

type EmailService interface {
	SendVerificationEmail(toEmail, verifyURL string) error
}
