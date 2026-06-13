package handlers

import (
	"log"
	"strconv"

	"github.com/coconut/backend/internal/core/ports"
	"github.com/gofiber/fiber/v2"
)

type ProductHandler struct {
	productRepo     ports.ProductRepository
	fallbackService ports.FallbackService
}

func NewProductHandler(productRepo ports.ProductRepository, fallbackService ports.FallbackService) *ProductHandler {
	return &ProductHandler{
		productRepo:     productRepo,
		fallbackService: fallbackService,
	}
}

func (h *ProductHandler) SetupRoutes(router fiber.Router) {
	products := router.Group("/products")
	products.Get("/catalog", h.ListCatalog)
	products.Get("/:barcode", h.GetProductByBarcode)
}

func (h *ProductHandler) ListCatalog(c *fiber.Ctx) error {
	limit, _ := strconv.Atoi(c.Query("limit", "30"))
	offset, _ := strconv.Atoi(c.Query("offset", "0"))
	if limit <= 0 || limit > 100 {
		limit = 30
	}

	category := c.Query("category", "")

	var minRating, maxRating float64
	switch c.Query("score", "all") {
	case "good":
		minRating = 3.5
	case "ok":
		minRating = 2.0
		maxRating = 3.5
	case "bad":
		maxRating = 2.0
	}

	products, err := h.productRepo.ListCatalog(c.UserContext(), limit, offset, category, minRating, maxRating)
	if err != nil {
		log.Printf("ERROR: ListCatalog: %v", err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to list catalog"})
	}
	if products == nil {
		return c.JSON([]interface{}{})
	}
	return c.JSON(products)
}

func (h *ProductHandler) GetProductByBarcode(c *fiber.Ctx) error {
	barcode := c.Params("barcode")
	if barcode == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "barcode is required"})
	}

	product, err := h.productRepo.GetByBarcode(c.UserContext(), barcode)
	if err != nil {
		log.Printf("ERROR: GetByBarcode [%s]: %v", barcode, err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to fetch product"})
	}

	// Fallback to Честный Знак if not found locally
	if (product == nil || product.ID == 0) && h.fallbackService != nil {
		log.Printf("INFO: barcode [%s] not in DB, trying Честный Знак fallback", barcode)
		product, err = h.fallbackService.FetchAndSave(c.UserContext(), barcode)
		if err != nil {
			log.Printf("ERROR: fallback [%s]: %v", barcode, err)
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to fetch product from external source", "details": err.Error()})
		}
	}

	if product == nil || product.ID == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "product not found"})
	}

	return c.JSON(product)
}
