package ports

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
)

type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	GetByID(ctx context.Context, id string) (*domain.User, error)
	GetByEmail(ctx context.Context, email string) (*domain.User, error)
	UpdateNickname(ctx context.Context, userID, nickname string) error
	Delete(ctx context.Context, id string) error
}
