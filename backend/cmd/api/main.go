package main

import (
	"context"
	"log"
	"os"
	"strconv"

	"github.com/coconut/backend/internal/adapters/handlers"
	"github.com/coconut/backend/internal/adapters/repositories"
	"github.com/coconut/backend/internal/core/services"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env if present (local development only)
	if err := godotenv.Load(); err != nil && !os.IsNotExist(err) {
		log.Printf("Warning: could not load .env file: %v", err)
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL environment variable is required")
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		log.Fatal("JWT_SECRET environment variable is required")
	}

	ctx := context.Background()
	dbPool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v\n", err)
	}
	defer dbPool.Close()

	if err := dbPool.Ping(ctx); err != nil {
		log.Fatalf("Database ping failed: %v\n", err)
	}
	log.Println("Connected to PostgreSQL successfully")

	userRepo := repositories.NewPostgresUserRepository(dbPool)
	historyRepo := repositories.NewPostgresHistoryRepository(dbPool)
	productRepo := repositories.NewPostgresProductRepository(dbPool)

	smtpHost := os.Getenv("SMTP_HOST")
	smtpPortStr := os.Getenv("SMTP_PORT")
	smtpUser := os.Getenv("SMTP_USER")
	smtpPass := os.Getenv("SMTP_PASS")
	smtpFrom := os.Getenv("SMTP_FROM")

	var smtpPort int
	if smtpPortStr != "" {
		smtpPort, _ = strconv.Atoi(smtpPortStr)
	}

	emailService := services.NewSMTPEmailService(smtpHost, smtpPort, smtpUser, smtpPass, smtpFrom)
	authService := services.NewAuthService(userRepo, emailService, jwtSecret)

	// Честный Знак fallback (requires CHESTNY_ZNAK_API_KEY and OPENAI_API_KEY)
	cznKey := os.Getenv("CHESTNY_ZNAK_API_KEY")
	openaiKey := os.Getenv("OPENAI_API_KEY")
	var fallbackSvc *services.FallbackService
	if cznKey != "" {
		fallbackSvc = services.NewFallbackService(productRepo, cznKey, openaiKey)
		log.Println("Честный Знак fallback enabled")
	} else {
		log.Println("CHESTNY_ZNAK_API_KEY not set — fallback disabled")
	}

	app := fiber.New(fiber.Config{
		AppName: "Coconut Backend",
	})

	app.Use(logger.New())
	app.Use(recover.New())

	authHandler := handlers.NewAuthHandler(authService, jwtSecret)
	authHandler.SetupRoutes(app)

	historyHandler := handlers.NewHistoryHandler(historyRepo)
	productHandler := handlers.NewProductHandler(productRepo, fallbackSvc)

	api := app.Group("/api", authHandler.AuthMiddleware())
	historyHandler.SetupRoutes(api)
	productHandler.SetupRoutes(api)

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.SendString("OK")
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Starting server on port %s...", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("Error starting server: %v\n", err)
	}
}
