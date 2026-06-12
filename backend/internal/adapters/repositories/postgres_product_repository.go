package repositories

import (
	"context"
	"errors"
	"fmt"
	"strings"

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

	if catID != nil {
		p.Category = &domain.Category{ID: *catID, ImageLink: catImg}
		if catTitle != nil {
			p.Category.Title = *catTitle
		}
	}
	if nf.CaloriesKcal != nil || nf.ProteinG != nil {
		p.NutritionFacts = nf
	}

	ingRows, err := r.db.Query(ctx, `
		SELECT
			pi.ingredient_id, pi.original_name,
			i.name, i.name_ru, i.e_number, i.category, i.is_allergen,
			COALESCE(i.is_additive, false), COALESCE(i.risk_level, 0),
			pi.qty, pi.unit, pi.qualifier
		FROM product_catalog.product_ingredient pi
		JOIN product_catalog.ingredient i ON i.id = pi.ingredient_id
		WHERE pi.product_id = $1 AND pi.ingredient_id IS NOT NULL
	`, p.ID)
	if err == nil {
		defer ingRows.Close()
		for ingRows.Next() {
			var ni domain.NormalizedIngredient
			if err := ingRows.Scan(
				&ni.IngredientID, &ni.OriginalName,
				&ni.Name, &ni.NameRu, &ni.ENumber, &ni.Category, &ni.IsAllergen,
				&ni.IsAdditive, &ni.RiskLevel,
				&ni.Qty, &ni.Unit, &ni.Qualifier,
			); err == nil {
				p.NormalizedIngredients = append(p.NormalizedIngredients, ni)
			}
		}
	}

	riskRows, err := r.db.Query(ctx, `SELECT id, fact FROM product_catalog.health_risks WHERE product_id = $1`, p.ID)
	if err == nil {
		defer riskRows.Close()
		for riskRows.Next() {
			var hr domain.HealthRisk
			if err := riskRows.Scan(&hr.ID, &hr.Fact); err == nil {
				p.HealthRisks = append(p.HealthRisks, hr)
			}
		}
	}
	return p, nil
}

// GetCategoryIDByEmbedding finds the nearest category using pgvector cosine similarity.
func (r *PostgresProductRepository) GetCategoryIDByEmbedding(ctx context.Context, embedding []float32) (*int64, error) {
	var id int64
	err := r.db.QueryRow(ctx, `
		SELECT id FROM product_catalog.category
		WHERE embedding IS NOT NULL
		ORDER BY embedding <=> $1::vector
		LIMIT 1
	`, float32SliceToLiteral(embedding)).Scan(&id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return &id, nil
}

// GetCategoryMedianNutrition returns category-level median nutrition facts.
func (r *PostgresProductRepository) GetCategoryMedianNutrition(ctx context.Context, categoryID int64) (*domain.NutritionFacts, error) {
	nf := &domain.NutritionFacts{}
	err := r.db.QueryRow(ctx, `
		SELECT
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.calories_kcal),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.protein_g),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.fat_g),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.carbs_g),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.fiber_g),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.sugar_g),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.salt_g),
			percentile_cont(0.5) WITHIN GROUP (ORDER BY n.sodium_mg)
		FROM product_catalog.nutrition_facts n
		JOIN product_catalog.product p ON p.id = n.product_id
		WHERE p.category_id = $1 AND n.calories_kcal IS NOT NULL
	`, categoryID).Scan(
		&nf.CaloriesKcal, &nf.ProteinG, &nf.FatG, &nf.CarbsG,
		&nf.FiberG, &nf.SugarG, &nf.SaltG, &nf.SodiumMg,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	if nf.CaloriesKcal == nil {
		return nil, nil
	}
	return nf, nil
}

// SaveFallbackProduct saves a Честный Знак product in one transaction:
// product → barcode → nutrition_facts → staging ingredients → product_ingredient links.
func (r *PostgresProductRepository) SaveFallbackProduct(
	ctx context.Context,
	barcode string,
	p *domain.Product,
	ingredients []domain.ParsedIngredient,
	ingredientEmbeddings [][]float32,
) error {
	tx, err := r.db.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Race-condition guard: skip if barcode already saved
	var existingID int64
	if err := tx.QueryRow(ctx,
		"SELECT product_id FROM product_catalog.product_barcode WHERE barcode = $1", barcode,
	).Scan(&existingID); err == nil {
		return tx.Commit(ctx)
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return err
	}

	// Insert product
	var productID int64
	if err := tx.QueryRow(ctx, `
		INSERT INTO product_catalog.product
			(source_id, source, name, brand, image_link, category_id, total_rating, ingredients)
		VALUES ($1, 'chestny_znak', $2, $3, $4, $5, $6, $7)
		RETURNING id
	`, p.SourceID, p.Name, p.Brand, p.ImageLink, p.CategoryID, p.TotalRating, p.Ingredients,
	).Scan(&productID); err != nil {
		return fmt.Errorf("insert product: %w", err)
	}

	// Link barcode
	if _, err := tx.Exec(ctx,
		"INSERT INTO product_catalog.product_barcode (product_id, barcode) VALUES ($1, $2) ON CONFLICT DO NOTHING",
		productID, barcode,
	); err != nil {
		return fmt.Errorf("insert barcode: %w", err)
	}

	// Nutrition facts (check first — table may have no UNIQUE constraint yet)
	if nf := p.NutritionFacts; nf != nil {
		var nfExists int
		_ = tx.QueryRow(ctx,
			"SELECT 1 FROM product_catalog.nutrition_facts WHERE product_id = $1", productID,
		).Scan(&nfExists)
		if nfExists == 0 {
			if _, err := tx.Exec(ctx, `
				INSERT INTO product_catalog.nutrition_facts
					(product_id, serving_size_g, calories_kcal, protein_g, fat_g, carbs_g, fiber_g, sugar_g, salt_g, sodium_mg)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
			`, productID, nf.ServingSizeG, nf.CaloriesKcal, nf.ProteinG, nf.FatG,
				nf.CarbsG, nf.FiberG, nf.SugarG, nf.SaltG, nf.SodiumMg,
			); err != nil {
				return fmt.Errorf("insert nutrition: %w", err)
			}
		}
	}

	// Parsed ingredients
	sourceID := barcode
	if p.SourceID != nil {
		sourceID = *p.SourceID
	}

	for pos, ing := range ingredients {
		name := strings.ToLower(strings.TrimSpace(ing.Name))
		if name == "" {
			continue
		}

		// staging.raw_product_ingredients (best-effort — schema may not exist)
		_, _ = tx.Exec(ctx, `
			INSERT INTO staging.raw_product_ingredients
				(source_id, ingredient_name, position, is_transparent, qty, unit, qualifier)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			ON CONFLICT DO NOTHING
		`, sourceID, name, pos+1, ing.IsTransparent, ing.Qty, ing.Unit, ing.Qualifier)

		// Find canonical ingredient via pgvector (if embedding available)
		var ingredientID *int64
		if pos < len(ingredientEmbeddings) && ingredientEmbeddings[pos] != nil {
			var id int64
			err := tx.QueryRow(ctx, `
				SELECT id FROM product_catalog.ingredient
				WHERE embedding IS NOT NULL
				ORDER BY embedding <=> $1::vector
				LIMIT 1
			`, float32SliceToLiteral(ingredientEmbeddings[pos])).Scan(&id)
			if err == nil {
				ingredientID = &id
			}
		}

		// product_ingredient link (best-effort — table may not have this product yet)
		_, _ = tx.Exec(ctx, `
			INSERT INTO product_catalog.product_ingredient
				(product_id, ingredient_id, original_name, qty, unit, qualifier)
			VALUES ($1, $2, $3, $4, $5, $6)
			ON CONFLICT DO NOTHING
		`, productID, ingredientID, name, ing.Qty, ing.Unit, ing.Qualifier)
	}

	return tx.Commit(ctx)
}

func float32SliceToLiteral(v []float32) string {
	var sb strings.Builder
	sb.WriteByte('[')
	for i, f := range v {
		if i > 0 {
			sb.WriteByte(',')
		}
		fmt.Fprintf(&sb, "%g", f)
	}
	sb.WriteByte(']')
	return sb.String()
}
