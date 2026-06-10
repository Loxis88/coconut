package services

import (
	"fmt"
	"github.com/coconut/backend/internal/core/ports"
	"gopkg.in/gomail.v2"
)

type SMTPEmailService struct {
	Host string
	Port int
	User string
	Pass string
	From string
}

func NewSMTPEmailService(host string, port int, user, pass, from string) ports.EmailService {
	return &SMTPEmailService{
		Host: host,
		Port: port,
		User: user,
		Pass: pass,
		From: from,
	}
}

func (s *SMTPEmailService) SendVerificationEmail(toEmail, verifyURL string) error {
	m := gomail.NewMessage()
	m.SetHeader("From", s.From)
	m.SetHeader("To", toEmail)
	m.SetHeader("Subject", "Подтверждение регистрации Coconut")

	body := fmt.Sprintf(`
		<h1>Добро пожаловать в Coconut!</h1>
		<p>Для завершения регистрации подтвердите свой email, перейдя по ссылке:</p>
		<a href="%s">Подтвердить email</a>
		<br/>
		<p>Если вы не регистрировались в нашем приложении, просто проигнорируйте это письмо.</p>
	`, verifyURL)

	m.SetBody("text/html", body)

	d := gomail.NewDialer(s.Host, s.Port, s.User, s.Pass)

	if err := d.DialAndSend(m); err != nil {
		return fmt.Errorf("could not send email: %v", err)
	}
	return nil
}
