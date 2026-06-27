package ports

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
)

type ProductRepository interface {
	GetByBarcode(ctx context.Context, barcode string) (*domain.Product, error)
	// SaveFallbackProduct saves a product from Честный Знак with optional nutrition and ingredients.
	// ingredientEmbeddings[i] corresponds to ingredients[i]; used for pgvector canonical matching.
	SaveFallbackProduct(ctx context.Context, barcode string, p *domain.Product, ingredients []domain.ParsedIngredient, ingredientEmbeddings [][]float32) error
	GetCategoryIDByName(ctx context.Context, offCategoryID string) (*int64, error)
	GetCategoryMedianNutrition(ctx context.Context, categoryID int64) (*domain.NutritionFacts, error)
	// ListCatalog returns lightweight product cards for the catalog browse screen.
	// category="" means no filter; minRating/maxRating=0 means unbounded.
	ListCatalog(ctx context.Context, limit, offset int, category string, minRating, maxRating float64) ([]*domain.Product, error)
}
