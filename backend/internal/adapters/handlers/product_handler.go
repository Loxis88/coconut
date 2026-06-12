package handlers

import (
	"log"

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
	products.Get("/:barcode", h.GetProductByBarcode)
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
