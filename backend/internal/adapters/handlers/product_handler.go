package handlers

import (
	"log"

	"github.com/coconut/backend/internal/core/ports"
	"github.com/gofiber/fiber/v2"
)

type ProductHandler struct {
	productRepo ports.ProductRepository
}

func NewProductHandler(productRepo ports.ProductRepository) *ProductHandler {
	return &ProductHandler{
		productRepo: productRepo,
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
		log.Printf("ERROR: Failed to fetch product [%s]: %v", barcode, err)
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to fetch product", "details": err.Error()})
	}

	if product == nil || product.ID == 0 {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "product not found"})
	}

	return c.JSON(product)
}
