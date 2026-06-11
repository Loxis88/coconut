package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/coconut/backend/internal/core/domain"
)

const (
	openaiEmbedURL = "https://api.openai.com/v1/embeddings"
	openaiChatURL  = "https://api.openai.com/v1/chat/completions"
	embedModel     = "text-embedding-3-small"
	chatModel      = "gpt-4o-mini"
)

type openAIClient struct {
	apiKey     string
	httpClient *http.Client
}

func newOpenAIClient(apiKey string) *openAIClient {
	return &openAIClient{
		apiKey:     apiKey,
		httpClient: &http.Client{Timeout: 60 * time.Second},
	}
}

func (c *openAIClient) post(ctx context.Context, endpoint string, body, dst any) error {
	b, err := json.Marshal(body)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	raw, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("openai status %d: %s", resp.StatusCode, raw)
	}
	return json.Unmarshal(raw, dst)
}

// Embed returns a single embedding vector.
func (c *openAIClient) Embed(ctx context.Context, text string) ([]float32, error) {
	vecs, err := c.EmbedBatch(ctx, []string{text})
	if err != nil || len(vecs) == 0 {
		return nil, err
	}
	return vecs[0], nil
}

// EmbedBatch returns embeddings for multiple texts in one API call.
func (c *openAIClient) EmbedBatch(ctx context.Context, texts []string) ([][]float32, error) {
	var resp struct {
		Data []struct {
			Index     int       `json:"index"`
			Embedding []float32 `json:"embedding"`
		} `json:"data"`
	}
	err := c.post(ctx, openaiEmbedURL, map[string]any{
		"model": embedModel,
		"input": texts,
	}, &resp)
	if err != nil {
		return nil, err
	}
	out := make([][]float32, len(texts))
	for _, d := range resp.Data {
		if d.Index < len(out) {
			out[d.Index] = d.Embedding
		}
	}
	return out, nil
}

// Exact JSON schema matching Python ExtractionResponse.model_json_schema()
const extractionJSONSchema = `{
  "$defs": {
    "Ingredient": {
      "properties": {
        "name":           {"type": "string"},
        "is_transparent": {"type": "boolean", "default": true},
        "qty":            {"anyOf": [{"type": "number"}, {"type": "null"}], "default": null},
        "unit":           {"anyOf": [{"type": "string"}, {"type": "null"}], "default": null},
        "qualifier":      {"anyOf": [{"type": "string"}, {"type": "null"}], "default": null}
      },
      "required": ["name"],
      "type": "object"
    },
    "ProductIngredients": {
      "properties": {
        "source_id":   {"type": "string"},
        "ingredients": {"items": {"$ref": "#/$defs/Ingredient"}, "type": "array"}
      },
      "required": ["source_id", "ingredients"],
      "type": "object"
    }
  },
  "properties": {
    "products": {"items": {"$ref": "#/$defs/ProductIngredients"}, "type": "array"}
  },
  "required": ["products"],
  "type": "object"
}`

// System prompt identical to data/staging/extract_ingredients.py SYSTEM_PROMPT.
const ingredientSystemPrompt = `Ты парсер составов продуктов питания. Тебе дан список продуктов с полем "ingredients" (строка состава).

Для каждого продукта извлеки ВСЕ отдельные ингредиенты.

Правила парсинга:
1. Раскрывай скобки: "масло растительное (подсолнечное, пальмовое)" → "масло подсолнечное", "масло пальмовое".
2. "загуститель пектин" → name="пектин". "консервант сорбат калия" → name="сорбат калия". Функция (загуститель, консервант, краситель, эмульгатор, стабилизатор, антиокислитель, регулятор кислотности, разрыхлитель, фиксатор окраски, усилитель вкуса и аромата, глазирователь, подсластитель, желирующий агент, агент влагоудерживающий, уплотнитель) — НЕ часть названия. Убирай её.
3. Если указана ТОЛЬКО функция без конкретики ("ароматизаторы", "красители", "специи") → name = функция в единственном числе ("ароматизатор", "краситель", "специя").
4. "перец черный, белый, зеленый" → "перец черный", "перец белый", "перец зеленый".
6. qty/unit/qualifier — если указано количество: "не менее 25%" → qty=25, unit="%", qualifier="min". "не более 1%" → qty=1, unit="%", qualifier="max". Иначе null.
7. is_transparent — false если производитель использует общую формулировку без конкретики: "ароматизатор" (какой?), "красители" (какие?), "специи" (какие?), "растительные масла" (какие?). Если указано конкретно ("ароматизатор ванилин", "масло подсолнечное") → true.
8. Все названия в нижнем регистре.
9. Текст после точки вне скобок — не ингредиенты (информация о составе), игнорируй.
10. "содержит следы" / "может содержать" — не ингредиенты, игнорируй.`

// ExtractIngredients parses a composition string into structured ingredients,
// using the same prompt and JSON schema as data/staging/extract_ingredients.py.
func (c *openAIClient) ExtractIngredients(ctx context.Context, sourceID, compositionText string) ([]domain.ParsedIngredient, error) {
	userContent, _ := json.Marshal(map[string]any{
		"products": []map[string]string{
			{"source_id": sourceID, "ingredients": compositionText},
		},
	})

	var schema map[string]any
	_ = json.Unmarshal([]byte(extractionJSONSchema), &schema)

	var resp struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	err := c.post(ctx, openaiChatURL, map[string]any{
		"model": chatModel,
		"messages": []map[string]string{
			{"role": "system", "content": ingredientSystemPrompt},
			{"role": "user", "content": string(userContent)},
		},
		"response_format": map[string]any{
			"type": "json_schema",
			"json_schema": map[string]any{
				"name":   "ExtractionResponse",
				"schema": schema,
				"strict": false,
			},
		},
		"temperature": 0.0,
	}, &resp)
	if err != nil {
		return nil, err
	}
	if len(resp.Choices) == 0 {
		return nil, fmt.Errorf("empty response from OpenAI")
	}

	var parsed struct {
		Products []struct {
			SourceID    string                   `json:"source_id"`
			Ingredients []domain.ParsedIngredient `json:"ingredients"`
		} `json:"products"`
	}
	if err := json.Unmarshal([]byte(resp.Choices[0].Message.Content), &parsed); err != nil {
		return nil, fmt.Errorf("parse extraction response: %w", err)
	}
	if len(parsed.Products) == 0 {
		return nil, nil
	}

	// Normalise names
	for i := range parsed.Products[0].Ingredients {
		parsed.Products[0].Ingredients[i].Name = strings.ToLower(
			strings.TrimSpace(parsed.Products[0].Ingredients[i].Name),
		)
	}
	return parsed.Products[0].Ingredients, nil
}
