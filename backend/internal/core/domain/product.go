package domain

// ParsedIngredient mirrors the Python Ingredient Pydantic model from extract_ingredients.py.
type ParsedIngredient struct {
	Name          string   `json:"name"`
	IsTransparent bool     `json:"is_transparent"`
	Qty           *float64 `json:"qty"`
	Unit          *string  `json:"unit"`
	Qualifier     *string  `json:"qualifier"`
}

type Category struct {
	ID        int64   `json:"id"`
	Title     string  `json:"title"`
	ImageLink *string `json:"image_link,omitempty"`
}

type NutritionFacts struct {
	ServingSizeG    *float64 `json:"serving_size_g,omitempty"`
	CaloriesKcal    *float64 `json:"calories_kcal,omitempty"`
	ProteinG        *float64 `json:"protein_g,omitempty"`
	FatG            *float64 `json:"fat_g,omitempty"`
	CarbsG          *float64 `json:"carbs_g,omitempty"`
	FiberG          *float64 `json:"fiber_g,omitempty"`
	SugarG          *float64 `json:"sugar_g,omitempty"`
	SaltG           *float64 `json:"salt_g,omitempty"`
	SodiumMg        *float64 `json:"sodium_mg,omitempty"`
	SaturatedFatG   *float64 `json:"saturated_fat_g,omitempty"`
}

type HealthRisk struct {
	ID   int64  `json:"id"`
	Fact string `json:"fact"`
}

type NormalizedIngredient struct {
	IngredientID int64    `json:"ingredient_id"`
	OriginalName string   `json:"original_name"`
	Name         string   `json:"name"`
	NameRu       *string  `json:"name_ru,omitempty"`
	ENumber      *string  `json:"e_number,omitempty"`
	Category     *string  `json:"category,omitempty"`
	IsAllergen   bool     `json:"is_allergen"`
	IsAdditive   bool     `json:"is_additive"`
	RiskLevel    int16    `json:"risk_level"`
	Qty          *float64 `json:"qty,omitempty"`
	Unit         *string  `json:"unit,omitempty"`
	Qualifier    *string  `json:"qualifier,omitempty"`
}

type Product struct {
	ID                    int64                  `json:"id"`
	SourceID              *string                `json:"source_id,omitempty"`
	Source                *string                `json:"source,omitempty"`
	CategoryID            *int64                 `json:"category_id,omitempty"`
	Category              *Category              `json:"category,omitempty"`
	TotalRating           *float64               `json:"total_rating,omitempty"`
	Brand                 *string                `json:"brand,omitempty"`
	ImageLink             *string                `json:"image_link,omitempty"`
	Barcode               *string                `json:"barcode,omitempty"`
	Name                  *string                `json:"name,omitempty"`
	Ingredients           *string                `json:"ingredients,omitempty"`
	NutritionFacts        *NutritionFacts        `json:"nutrition_facts,omitempty"`
	NormalizedIngredients []NormalizedIngredient `json:"normalized_ingredients,omitempty"`
	HealthRisks           []HealthRisk           `json:"health_risks,omitempty"`
}
