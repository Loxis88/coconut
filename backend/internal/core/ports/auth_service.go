package ports

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
)

type AuthService interface {
	Register(ctx context.Context, email, password string) (*domain.User, error)
	Login(ctx context.Context, email, password string) (string, string, *domain.User, error)
	VerifyEmail(ctx context.Context, token string) error
	SendVerificationEmail(ctx context.Context, userID, email, verifyURLBase string) error
	RefreshTokens(ctx context.Context, refreshToken string) (string, string, error) // Returns new accessToken, new refreshToken, error
	UpdateNickname(ctx context.Context, userID, nickname string) error
	GetUserByID(ctx context.Context, userID string) (*domain.User, error)
	GetUserByEmail(ctx context.Context, email string) (*domain.User, error)
	DeleteAccount(ctx context.Context, userID string) error
}
