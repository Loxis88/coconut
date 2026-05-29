package handlers

import (
	"strings"

	"github.com/coconut/backend/internal/core/ports"
	jwtutil "github.com/coconut/backend/pkg/jwt"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
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

	// Google OAuth routes
	googleGroup := authGroup.Group("/google")
	googleGroup.Get("/login", h.GoogleLogin)
	googleGroup.Get("/callback", h.GoogleCallback)

	// Protected routes
	api := router.Group("/api", h.AuthMiddleware())
	api.Get("/me", h.GetMe)
}

func (h *AuthHandler) GoogleLogin(c *fiber.Ctx) error {
	// Generate a random state for CSRF protection
	state := uuid.New().String()

	// In a real app, you should store this state in a secure HttpOnly cookie
	// to verify it in the callback. For simplicity, we skip it here, but it's recommended.
	c.Cookie(&fiber.Cookie{
		Name:     "oauth_state",
		Value:    state,
		HTTPOnly: true,
		Secure:   false, // Set to true in production
	})

	url := h.authService.GetGoogleLoginURL(state)
	return c.Redirect(url, fiber.StatusTemporaryRedirect)
}

func (h *AuthHandler) GoogleCallback(c *fiber.Ctx) error {
	state := c.Query("state")
	code := c.Query("code")

	// Verify state from cookie (recommended)
	cookieState := c.Cookies("oauth_state")
	if state != cookieState {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid state"})
	}

	accessToken, refreshToken, user, err := h.authService.GoogleCallback(c.Context(), code)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to authenticate", "details": err.Error()})
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
	email := c.Locals("email").(string)

	return c.JSON(fiber.Map{
		"message": "You are authenticated!",
		"user_id": userID,
		"email":   email,
	})
}
