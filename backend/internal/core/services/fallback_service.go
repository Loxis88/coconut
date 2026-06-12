package services

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"time"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	"golang.org/x/net/idna"
)

// ── Честный Знак API types ────────────────────────────────────────────────────

type cznCategory struct {
	CatID   int    `json:"cat_id"`
	CatName string `json:"cat_name"`
}

type cznAttr struct {
	AttrName  string `json:"attr_name"`
	AttrValue string `json:"attr_value"`
}

type cznProduct struct {
	GoodName   string        `json:"good_name"`
	GoodImg    string        `json:"good_img"`
	BrandName  string        `json:"brand_name"`
	Categories []cznCategory `json:"categories"`
	GoodAttrs  []cznAttr     `json:"good_attrs"`
}

type cznResponse struct {
	Result []cznProduct `json:"result"`
}

func (p *cznProduct) shortestCategoryName() string {
	best := ""
	for _, c := range p.Categories {
		if best == "" || len(c.CatName) < len(best) {
			best = c.CatName
		}
	}
	return best
}

func (p *cznProduct) composition() string {
	for _, a := range p.GoodAttrs {
		if a.AttrName == "Состав" {
			return a.AttrValue
		}
	}
	return ""
}

// ── FallbackService ───────────────────────────────────────────────────────────

type FallbackService struct {
	repo       ports.ProductRepository
	openai     *openAIClient
	cznAPIKey  string
	httpClient *http.Client
}

func NewFallbackService(repo ports.ProductRepository, cznAPIKey, openAIKey string) *FallbackService {
	return &FallbackService{
		repo:       repo,
		openai:     newOpenAIClient(openAIKey),
		cznAPIKey:  cznAPIKey,
		httpClient: &http.Client{Timeout: 15 * time.Second},
	}
}

func (s *FallbackService) FetchAndSave(ctx context.Context, barcode string) (*domain.Product, error) {
	// 1. Call Честный Знак API
	raw, err := s.fetchCZN(ctx, barcode)
	if err != nil {
		return nil, fmt.Errorf("czn api: %w", err)
	}
	if raw == nil {
		return nil, nil
	}

	ingredientsText := raw.composition()
	categoryQueryText := raw.shortestCategoryName()

	// 2. Embed category name → nearest DB category
	var categoryID *int64
	if categoryQueryText != "" && s.openai.apiKey != "" {
		emb, embErr := s.openai.Embed(ctx, categoryQueryText)
		if embErr != nil {
			log.Printf("fallback: embed category %q: %v", categoryQueryText, embErr)
		} else {
			catID, catErr := s.repo.GetCategoryIDByEmbedding(ctx, emb)
			if catErr != nil {
				log.Printf("fallback: category lookup: %v", catErr)
			} else {
				categoryID = catID
			}
		}
	}

	// 3. Category-median nutrition
	var nf *domain.NutritionFacts
	if categoryID != nil {
		nf, _ = s.repo.GetCategoryMedianNutrition(ctx, *categoryID)
	}

	// 4. Nutri-Score
	rating := calcNutriScore(nf)

	// 5. LLM ingredient extraction (exact pipeline prompt + JSON schema)
	var parsedIngredients []domain.ParsedIngredient
	if ingredientsText != "" && s.openai.apiKey != "" {
		parsedIngredients, err = s.openai.ExtractIngredients(ctx, barcode, ingredientsText)
		if err != nil {
			log.Printf("fallback: extract ingredients: %v", err)
		}
	}

	// 6. Batch-embed all ingredient names in one API call
	var ingredientEmbeddings [][]float32
	if len(parsedIngredients) > 0 && s.openai.apiKey != "" {
		names := make([]string, len(parsedIngredients))
		for i, ing := range parsedIngredients {
			names[i] = ing.Name
		}
		embeddings, embErr := s.openai.EmbedBatch(ctx, names)
		if embErr != nil {
			log.Printf("fallback: embed ingredients: %v", embErr)
		} else {
			ingredientEmbeddings = embeddings
		}
	}

	// 7. Save to DB
	product := &domain.Product{
		Source:         strPtr("chestny_znak"),
		SourceID:       strPtr(barcode),
		Name:           strPtr(raw.GoodName),
		Brand:          strPtr(raw.BrandName),
		ImageLink:      strPtr(raw.GoodImg),
		CategoryID:     categoryID,
		TotalRating:    rating,
		Ingredients:    strPtr(ingredientsText),
		NutritionFacts: nf,
	}
	if err := s.repo.SaveFallbackProduct(ctx, barcode, product, parsedIngredients, ingredientEmbeddings); err != nil {
		return nil, fmt.Errorf("save fallback product: %w", err)
	}

	return s.repo.GetByBarcode(ctx, barcode)
}

func (s *FallbackService) fetchCZN(ctx context.Context, gtin string) (*cznProduct, error) {
	apiURL, err := buildCZNURL(s.cznAPIKey, gtin)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, apiURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("czn status %d: %s", resp.StatusCode, body)
	}

	var parsed cznResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return nil, fmt.Errorf("czn decode: %w", err)
	}
	if len(parsed.Result) == 0 {
		return nil, nil
	}
	return &parsed.Result[0], nil
}

func buildCZNURL(apiKey, gtin string) (string, error) {
	const cznHostCyrillic = "апи.национальный-каталог.рф"
	const cznPath = "/v3/product"

	asciiHost, err := idna.New(idna.StrictDomainName(false)).ToASCII(cznHostCyrillic)
	if err != nil {
		return "", fmt.Errorf("IDN encode: %w", err)
	}
	u := &url.URL{
		Scheme: "https",
		Host:   asciiHost,
		Path:   cznPath,
	}
	q := u.Query()
	q.Set("apikey", apiKey)
	q.Set("gtin", gtin)
	u.RawQuery = q.Encode()

	return u.String(), nil
}

func strPtr(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}
