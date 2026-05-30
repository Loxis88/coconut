package ports

import (
	"context"
	"github.com/coconut/backend/internal/core/domain"
)

type HistoryRepository interface {
	GetByUserID(ctx context.Context, userID string) ([]domain.SearchHistory, error)
	Create(ctx context.Context, history *domain.SearchHistory) error
	DeleteAllByUserID(ctx context.Context, userID string) error
}
