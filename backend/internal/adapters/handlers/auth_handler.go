package handlers

import (
	"strings"

	"github.com/coconut/backend/internal/core/ports"
	jwtutil "github.com/coconut/backend/pkg/jwt"
	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	authService ports.AuthService
	jwtSecret   string
}

func NewAuthHandler(authService ports.AuthService, jwtSecret string) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		jwtSecret:   jwtSecret,
	}
}

func (h *AuthHandler) SetupRoutes(router fiber.Router) {
	authGroup := router.Group("/auth")

	// Mobile-first Google Auth route
	authGroup.Post("/google", h.GoogleLogin)

	// Protected routes
	api := router.Group("/api", h.AuthMiddleware())
	api.Get("/me", h.GetMe)
	api.Patch("/me/nickname", h.UpdateNickname)
}

func (h *AuthHandler) UpdateNickname(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	var req struct {
		Nickname string `json:"nickname"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	if req.Nickname == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "nickname is required"})
	}

	if err := h.authService.UpdateNickname(c.UserContext(), userID, req.Nickname); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to update nickname"})
	}

	return c.JSON(fiber.Map{"message": "nickname updated successfully"})
}

type GoogleLoginRequest struct {
	IDToken string `json:"id_token"`
}

func (h *AuthHandler) GoogleLogin(c *fiber.Ctx) error {
	var req GoogleLoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	if req.IDToken == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "id_token is required"})
	}

	accessToken, refreshToken, user, err := h.authService.VerifyGoogleToken(c.UserContext(), req.IDToken)
	if err != nil {
		// Log the full error for debugging
		println("Auth Error:", err.Error())
		
		if strings.Contains(err.Error(), "failed to validate id_token") {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid google token", "details": err.Error()})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "internal server error during auth", "details": err.Error()})
	}

	return c.JSON(fiber.Map{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"user":          user,
	})
}

// AuthMiddleware protects routes requiring a valid JWT token
func (h *AuthHandler) AuthMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "missing authorization header"})
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid authorization format"})
		}

		tokenString := parts[1]
		claims, err := jwtutil.ValidateToken(tokenString, h.jwtSecret)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid or expired token"})
		}

		// Store user ID and email in context for later use in handlers
		c.Locals("userID", claims.UserID)
		c.Locals("email", claims.Email)

		return c.Next()
	}
}

func (h *AuthHandler) GetMe(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	user, err := h.authService.GetUserByID(c.UserContext(), userID)
	if err != nil || user == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "user not found"})
	}

	return c.JSON(user)
}
