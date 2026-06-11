package ports

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
)

type FallbackService interface {
	FetchAndSave(ctx context.Context, barcode string) (*domain.Product, error)
}
