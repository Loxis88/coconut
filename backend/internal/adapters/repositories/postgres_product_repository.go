package repositories

import (
	"context"
	"errors"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresProductRepository struct {
	db *pgxpool.Pool
}

func NewPostgresProductRepository(db *pgxpool.Pool) ports.ProductRepository {
	return &PostgresProductRepository{db: db}
}

func (r *PostgresProductRepository) GetByBarcode(ctx context.Context, barcode string) (*domain.Product, error) {
	query := `
		SELECT 
			p.id, p.source_id, p.source, p.total_rating, p.brand, p.image_link, p.barcode, p.name, p.ingredients,
			c.category_id, c.title, c.image_link,
			n.serving_size_g, n.calories_kcal, n.protein_g, n.fat_g, n.carbs_g, n.fiber_g, n.sugar_g, n.salt_g, n.sodium_mg
		FROM product_catalog.product p
		LEFT JOIN product_catalog.category c ON p.category_id = c.category_id
		LEFT JOIN product_catalog.nutrition_facts n ON p.id = n.product_id
		WHERE p.barcode = $1
		LIMIT 1
	`

	p := &domain.Product{
		Category:       &domain.Category{},
		NutritionFacts: &domain.NutritionFacts{},
	}

	err := r.db.QueryRow(ctx, query, barcode).Scan(
		&p.ID, &p.SourceID, &p.Source, &p.TotalRating, &p.Brand, &p.ImageLink, &p.Barcode, &p.Name, &p.Ingredients,
		&p.Category.ID, &p.Category.Title, &p.Category.ImageLink,
		&p.NutritionFacts.ServingSizeG, &p.NutritionFacts.CaloriesKcal, &p.NutritionFacts.ProteinG, &p.NutritionFacts.FatG, &p.NutritionFacts.CarbsG, &p.NutritionFacts.FiberG, &p.NutritionFacts.SugarG, &p.NutritionFacts.SaltG, &p.NutritionFacts.SodiumMg,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	// Fetch Health Risks
	riskQuery := `SELECT id, fact FROM product_catalog.health_risks WHERE product_id = $1`
	rows, err := r.db.Query(ctx, riskQuery, p.ID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var hr domain.HealthRisk
			if err := rows.Scan(&hr.ID, &hr.Fact); err == nil {
				p.HealthRisks = append(p.HealthRisks, hr)
			}
		}
	}

	return p, nil
}
