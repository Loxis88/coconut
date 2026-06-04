package ports

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
)

type AuthService interface {
	VerifyGoogleToken(ctx context.Context, idToken string) (string, string, *domain.User, error) // Returns accessToken, refreshToken, user, error
	RefreshTokens(ctx context.Context, refreshToken string) (string, string, error)              // Returns new accessToken, new refreshToken, error
	UpdateNickname(ctx context.Context, userID, nickname string) error
	GetUserByID(ctx context.Context, userID string) (*domain.User, error)
	DeleteAccount(ctx context.Context, userID string) error
}
