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
	GetCategoryIDByEmbedding(ctx context.Context, embedding []float32) (*int64, error)
	GetCategoryMedianNutrition(ctx context.Context, categoryID int64) (*domain.NutritionFacts, error)
}
