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
			p.id, p.source_id, p.source, p.total_rating, p.brand, p.image_link, pb.barcode, p.name, p.ingredients,
			c.id, c.name, NULL::text,
			n.serving_size_g, n.calories_kcal, n.protein_g, n.fat_g, n.carbs_g, n.fiber_g, n.sugar_g, n.salt_g, n.sodium_mg
		FROM product_catalog.product p
		JOIN product_catalog.product_barcode pb ON p.id = pb.product_id
		LEFT JOIN product_catalog.category c ON p.category_id = c.id
		LEFT JOIN product_catalog.nutrition_facts n ON p.id = n.product_id
		WHERE pb.barcode = $1
		LIMIT 1
	`

	p := &domain.Product{}
	
	// Temporary variables for LEFT JOIN columns that can be NULL
	var catID *int64
	var catTitle *string
	var catImg *string
	
	nf := &domain.NutritionFacts{}

	err := r.db.QueryRow(ctx, query, barcode).Scan(
		&p.ID, &p.SourceID, &p.Source, &p.TotalRating, &p.Brand, &p.ImageLink, &p.Barcode, &p.Name, &p.Ingredients,
		&catID, &catTitle, &catImg,
		&nf.ServingSizeG, &nf.CaloriesKcal, &nf.ProteinG, &nf.FatG, &nf.CarbsG, &nf.FiberG, &nf.SugarG, &nf.SaltG, &nf.SodiumMg,
	)

	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	// Map category if it exists
	if catID != nil {
		p.Category = &domain.Category{
			ID:        *catID,
			Title:     "",
			ImageLink: catImg,
		}
		if catTitle != nil {
			p.Category.Title = *catTitle
		}
	}

	// Map nutrition facts if at least one field is not null
	if nf.CaloriesKcal != nil || nf.ProteinG != nil {
		p.NutritionFacts = nf
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
