package services

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
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
	AttrID    int    `json:"attr_id"`
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

func (p *cznProduct) composition() string {
	for _, a := range p.GoodAttrs {
		if a.AttrName == "Состав" {
			return a.AttrValue
		}
	}
	return ""
}

// nutritionFromAttrs extracts КБЖУ directly from CZ good_attrs by stable attr_id.
// Returns nil when none of the nutrition attrs are present.
func (p *cznProduct) nutritionFromAttrs() *domain.NutritionFacts {
	const (
		idProtein   = 23862
		idFat       = 23865
		idCarbs     = 23868
		idKcal      = 23874
		idKj        = 23880
	)
	attrMap := make(map[int]string, len(p.GoodAttrs))
	for _, a := range p.GoodAttrs {
		attrMap[a.AttrID] = strings.TrimSpace(a.AttrValue)
	}
	parseF := func(id int) *float64 {
		s, ok := attrMap[id]
		if !ok || s == "" {
			return nil
		}
		s = strings.ReplaceAll(s, ",", ".")
		v, err := strconv.ParseFloat(s, 64)
		if err != nil {
			return nil
		}
		return &v
	}

	protein := parseF(idProtein)
	fat := parseF(idFat)
	carbs := parseF(idCarbs)
	kcal := parseF(idKcal)
	kj := parseF(idKj)

	// Derive kcal from kJ when kcal absent
	if kcal == nil && kj != nil {
		v := *kj / 4.184
		kcal = &v
	}
	// Sanity: if kJ < kcal it means units are swapped — use the smaller as kcal
	if kcal != nil && kj != nil && *kj < *kcal {
		v := *kj
		kcal = &v
	}

	if protein == nil && fat == nil && carbs == nil && kcal == nil {
		return nil
	}
	return &domain.NutritionFacts{
		CaloriesKcal: kcal,
		ProteinG:     protein,
		FatG:         fat,
		CarbsG:       carbs,
	}
}

// ── FallbackService ───────────────────────────────────────────────────────────

type FallbackService struct {
	repo            ports.ProductRepository
	openai          *openAIClient
	cznAPIKey       string
	httpClient      *http.Client
	categoryMapping map[string]*string // czn cat_name → OFF category ID (nil = no match)
	nutrScript      string             // path to predict_nutr.py (empty = disabled)
	pythonBin       string             // python executable
}

func NewFallbackService(repo ports.ProductRepository, cznAPIKey, openAIKey, mappingFile string) *FallbackService {
	pythonBin := os.Getenv("NUTR_PYTHON_BIN")
	if pythonBin == "" {
		pythonBin = "python"
	}
	svc := &FallbackService{
		repo:            repo,
		openai:          newOpenAIClient(openAIKey),
		cznAPIKey:       cznAPIKey,
		httpClient:      &http.Client{Timeout: 15 * time.Second},
		categoryMapping: loadCategoryMapping(mappingFile),
		nutrScript:      os.Getenv("NUTR_PREDICT_SCRIPT"),
		pythonBin:       pythonBin,
	}
	return svc
}

func loadCategoryMapping(path string) map[string]*string {
	data, err := os.ReadFile(path)
	if err != nil {
		log.Printf("fallback: category mapping not loaded (%s): %v", path, err)
		return nil
	}
	var raw map[string]*string
	if err := json.Unmarshal(data, &raw); err != nil {
		log.Printf("fallback: category mapping parse error: %v", err)
		return nil
	}
	log.Printf("fallback: loaded %d CZ category mappings from %s", len(raw), path)
	return raw
}

// resolveCategoryID looks up CZ categories in the pre-built mapping (most specific first).
// Returns (db category ID, OFF category name), or (nil, "") if none matched.
func (s *FallbackService) resolveCategoryID(ctx context.Context, categories []cznCategory) (*int64, string) {
	if s.categoryMapping == nil {
		return nil, ""
	}
	// Sort by cat_id descending — higher IDs are deeper/more specific in the CZ tree.
	sorted := make([]cznCategory, len(categories))
	copy(sorted, categories)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].CatID > sorted[j].CatID
	})
	for _, cat := range sorted {
		offID, ok := s.categoryMapping[cat.CatName]
		if !ok || offID == nil {
			continue
		}
		catID, err := s.repo.GetCategoryIDByName(ctx, *offID)
		if err != nil {
			log.Printf("fallback: category DB lookup %q: %v", *offID, err)
			continue
		}
		if catID != nil {
			return catID, *offID
		}
	}
	return nil, ""
}

// enrichNutrition calls predict_nutr.py subprocess to fill secondary nutrients.
// Only fills fields that are still nil in nf (never overwrites CZ data).
func (s *FallbackService) enrichNutrition(nf *domain.NutritionFacts, offCategory, ingredients string) {
	if s.nutrScript == "" || nf == nil {
		return
	}
	args := []string{s.nutrScript, "--category", offCategory, "--ingredients", ingredients}
	fmtF := func(v *float64) string {
		if v == nil {
			return ""
		}
		return strconv.FormatFloat(*v, 'f', 4, 64)
	}
	if s := fmtF(nf.CaloriesKcal); s != "" {
		args = append(args, "--kcal", s)
	}
	if s := fmtF(nf.ProteinG); s != "" {
		args = append(args, "--protein", s)
	}
	if s := fmtF(nf.FatG); s != "" {
		args = append(args, "--fat", s)
	}
	if s := fmtF(nf.CarbsG); s != "" {
		args = append(args, "--carbs", s)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, s.pythonBin, args...).Output()
	if err != nil {
		log.Printf("fallback: nutr enrichment subprocess: %v", err)
		return
	}

	var result struct {
		SugarG        *float64 `json:"sugar_g"`
		SodiumMg      *float64 `json:"sodium_mg"`
		SaltG         *float64 `json:"salt_g"`
		FiberG        *float64 `json:"fiber_g"`
		SaturatedFatG *float64 `json:"saturated_fat_g"`
	}
	if err := json.Unmarshal(out, &result); err != nil {
		log.Printf("fallback: nutr enrichment parse: %v", err)
		return
	}
	if nf.SugarG == nil        { nf.SugarG = result.SugarG }
	if nf.SodiumMg == nil      { nf.SodiumMg = result.SodiumMg }
	if nf.SaltG == nil         { nf.SaltG = result.SaltG }
	if nf.FiberG == nil        { nf.FiberG = result.FiberG }
	if nf.SaturatedFatG == nil { nf.SaturatedFatG = result.SaturatedFatG }
	log.Printf("fallback: secondary nutrients enriched via ML model")
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

	// 2. Resolve category via pre-built mapping (most specific CZ category first)
	categoryID, offCatName := s.resolveCategoryID(ctx, raw.Categories)
	if categoryID != nil {
		log.Printf("fallback: barcode %s → category %d (%s)", barcode, *categoryID, offCatName)
	} else {
		log.Printf("fallback: barcode %s → no category match", barcode)
	}

	// 3. Nutrition: use CZ attrs directly; nil when CZ doesn't provide them
	nf := raw.nutritionFromAttrs()
	if nf != nil {
		log.Printf("fallback: barcode %s → nutrition from CZ attrs (kcal=%v prot=%v fat=%v carbs=%v)",
			barcode, nf.CaloriesKcal, nf.ProteinG, nf.FatG, nf.CarbsG)
		s.enrichNutrition(nf, offCatName, ingredientsText)
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
