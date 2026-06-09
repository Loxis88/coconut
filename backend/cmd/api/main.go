package main

import (
	"context"
	"log"
	"os"
	"strings"

	"github.com/coconut/backend/internal/adapters/handlers"
	"github.com/coconut/backend/internal/adapters/repositories"
	"github.com/coconut/backend/internal/core/services"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	// 1. Load Configuration
	// In a real app, use a library like viper or godotenv to load these from .env or environment
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}
googleClientID := os.Getenv("GOOGLE_CLIENT_ID")
var allowedClients []string
if googleClientID != "" {
	allowedClients = strings.Split(googleClientID, ",")
} else {
	log.Println("Warning: GOOGLE_CLIENT_ID environment variable is not set")
}

jwtSecret := os.Getenv("JWT_SECRET")

if jwtSecret == "" {
	log.Fatal("JWT_SECRET environment variable is required")
}

// SMTP Configuration
smtpHost := os.Getenv("SMTP_HOST")
smtpPort := os.Getenv("SMTP_PORT")
smtpUser := os.Getenv("SMTP_USER")
smtpPass := os.Getenv("SMTP_PASS")
smtpFrom := os.Getenv("SMTP_FROM")

// 2. Initialize Database Connection
ctx := context.Background()
dbPool, err := pgxpool.New(ctx, dbURL)
if err != nil {
	log.Fatalf("Unable to connect to database: %v\n", err)
}
defer dbPool.Close()

// Verify connection
if err := dbPool.Ping(ctx); err != nil {
	log.Fatalf("Database ping failed: %v\n", err)
}
log.Println("Connected to PostgreSQL successfully")

// 3. Initialize Repositories
userRepo := repositories.NewPostgresUserRepository(dbPool)
historyRepo := repositories.NewPostgresHistoryRepository(dbPool)
productRepo := repositories.NewPostgresProductRepository(dbPool)

// 4. Initialize Services
emailService := services.NewEmailService(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom)
authService := services.NewAuthService(userRepo, emailService, allowedClients, jwtSecret)
	// 5. Initialize Fiber App
	app := fiber.New(fiber.Config{
		AppName: "Coconut Backend",
	})

	// Middleware
	app.Use(logger.New())
	app.Use(recover.New())

	// 6. Setup Routes
	authHandler := handlers.NewAuthHandler(authService, jwtSecret)
	authHandler.SetupRoutes(app)

	historyHandler := handlers.NewHistoryHandler(historyRepo)
	productHandler := handlers.NewProductHandler(productRepo)
	// Apply AuthMiddleware to /api group
	api := app.Group("/api", authHandler.AuthMiddleware())
	historyHandler.SetupRoutes(api)
	productHandler.SetupRoutes(api)

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.SendString("OK")
	})

	// 7. Start Server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Starting server on port %s...", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Error starting server: %v\n", err)
	}
}
