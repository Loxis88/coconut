package main

import (
	"context"
	"log"
	"os"

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


jwtSecret := os.Getenv("JWT_SECRET")

	if jwtSecret == "" {
		log.Fatal("JWT_SECRET environment variable is required")
	}

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
	authService := services.NewAuthService(userRepo, jwtSecret)

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
