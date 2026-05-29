package ports

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
)

type AuthService interface {
	GetGoogleLoginURL(state string) string
	GoogleCallback(ctx context.Context, code string) (string, string, *domain.User, error) // Returns accessToken, refreshToken, user, error
}
