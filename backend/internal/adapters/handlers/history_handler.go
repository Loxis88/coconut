package handlers

import (
	"time"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type HistoryHandler struct {
	historyRepo ports.HistoryRepository
}

func NewHistoryHandler(historyRepo ports.HistoryRepository) *HistoryHandler {
	return &HistoryHandler{
		historyRepo: historyRepo,
	}
}

func (h *HistoryHandler) SetupRoutes(router fiber.Router) {
	// All history routes are protected by AuthMiddleware in main.go
	historyGroup := router.Group("/history")
	
	historyGroup.Get("/", h.GetHistory)
	historyGroup.Post("/", h.SaveHistory)
	historyGroup.Delete("/", h.ClearHistory)
}

func (h *HistoryHandler) GetHistory(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	histories, err := h.historyRepo.GetByUserID(c.UserContext(), userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to fetch history"})
	}

	return c.JSON(histories)
}

type SaveHistoryRequest struct {
	Barcode string `json:"barcode"`
	Title   string `json:"title"`
	Score   int    `json:"score"`
}

func (h *HistoryHandler) SaveHistory(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	var req SaveHistoryRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	if req.Barcode == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "barcode is required"})
	}

	history := &domain.SearchHistory{
		ID:        uuid.New().String(),
		UserID:    userID,
		Barcode:   req.Barcode,
		Title:     req.Title,
		Score:     req.Score,
		ScannedAt: time.Now(),
	}

	if err := h.historyRepo.Create(c.UserContext(), history); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to save history"})
	}

	return c.Status(fiber.StatusCreated).JSON(history)
}

func (h *HistoryHandler) ClearHistory(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	if err := h.historyRepo.DeleteAllByUserID(c.UserContext(), userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to clear history"})
	}

	return c.SendStatus(fiber.StatusNoContent)
}
