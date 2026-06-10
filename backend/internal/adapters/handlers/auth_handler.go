package handlers

import (
	"strings"
	"errors"

	"github.com/coconut/backend/internal/core/ports"
	"github.com/coconut/backend/internal/core/services"
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

	authGroup.Post("/refresh", h.RefreshTokens)
	authGroup.Post("/register", h.Register)
	authGroup.Post("/login", h.Login)
	authGroup.Get("/verify", h.VerifyEmail)
	authGroup.Post("/resend-verification", h.ResendVerification)

	// Protected routes
	api := router.Group("/api", h.AuthMiddleware())
	api.Get("/me", h.GetMe)
	api.Patch("/me/nickname", h.UpdateNickname)
	api.Delete("/me", h.DeleteAccount)
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type CredentialsRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req CredentialsRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}
	if req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "email and password are required"})
	}

	user, err := h.authService.Register(c.UserContext(), req.Email, req.Password)
	if err != nil {
		if errors.Is(err, services.ErrUserAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "user already exists"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "registration failed", "details": err.Error()})
	}

	verifyURLBase := c.BaseURL() + "/auth/verify"
	_ = h.authService.SendVerificationEmail(c.UserContext(), user.ID, user.Email, verifyURLBase)

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"message": "registration successful, please verify your email"})
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req CredentialsRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	accessToken, refreshToken, user, err := h.authService.Login(c.UserContext(), req.Email, req.Password)
	if err != nil {
		if errors.Is(err, services.ErrInvalidCredentials) {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid credentials"})
		}
		if errors.Is(err, services.ErrEmailNotVerified) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "email not verified"})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "login failed"})
	}

	return c.JSON(fiber.Map{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"user":          user,
	})
}

func (h *AuthHandler) VerifyEmail(c *fiber.Ctx) error {
	token := c.Query("token")
	if token == "" {
		return c.Status(fiber.StatusBadRequest).SendString("Token is required")
	}

	if err := h.authService.VerifyEmail(c.UserContext(), token); err != nil {
		return c.Status(fiber.StatusBadRequest).SendString("Invalid or expired verification token")
	}

	html := `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Coconut - Email Verified</title>
    <script>
        setTimeout(function() {
            window.location.href = "coconut://verify/success";
        }, 1000);
    </script>
</head>
<body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
    <h2>Email успешно подтверждён!</h2>
    <p>Если вы открыли ссылку с телефона, приложение запустится автоматически.</p>
    <p>Иначе вы можете вернуться в приложение и войти.</p>
</body>
</html>`
	c.Set("Content-Type", "text/html")
	return c.SendString(html)
}

func (h *AuthHandler) ResendVerification(c *fiber.Ctx) error {
	var req struct {
		Email string `json:"email"`
	}
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request"})
	}

	user, _ := h.authService.GetUserByEmail(c.UserContext(), req.Email)
	if user != nil && !user.IsVerified {
		verifyURLBase := c.BaseURL() + "/auth/verify"
		_ = h.authService.SendVerificationEmail(c.UserContext(), user.ID, user.Email, verifyURLBase)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{"message": "verification email sent if account exists"})
}

func (h *AuthHandler) RefreshTokens(c *fiber.Ctx) error {
	var req RefreshRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid request body"})
	}

	if req.RefreshToken == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "refresh_token is required"})
	}

	accessToken, refreshToken, err := h.authService.RefreshTokens(c.UserContext(), req.RefreshToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "invalid refresh token", "details": err.Error()})
	}

	return c.JSON(fiber.Map{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
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

func (h *AuthHandler) DeleteAccount(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	if err := h.authService.DeleteAccount(c.UserContext(), userID); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "failed to delete account"})
	}

	return c.SendStatus(fiber.StatusNoContent)
}
