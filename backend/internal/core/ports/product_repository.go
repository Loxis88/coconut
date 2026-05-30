package ports

import (
	"context"
	"github.com/coconut/backend/internal/core/domain"
)

type ProductRepository interface {
	GetByBarcode(ctx context.Context, barcode string) (*domain.Product, error)
}
