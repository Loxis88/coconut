package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	jwtutil "github.com/coconut/backend/pkg/jwt"
	"github.com/google/uuid"
	"google.golang.org/api/idtoken"
)

type authService struct {
	userRepo       ports.UserRepository
	allowedClients []string
	jwtSecret      string
}

func NewAuthService(userRepo ports.UserRepository, allowedClients []string, jwtSecret string) ports.AuthService {
	return &authService{
		userRepo:       userRepo,
		allowedClients: allowedClients,
		jwtSecret:      jwtSecret,
	}
}

func (s *authService) VerifyGoogleToken(ctx context.Context, idTokenStr string) (string, string, *domain.User, error) {
	// 1. Validate the ID Token
	// We check against the first client ID.
	// In production, if you have multiple clients (Android, iOS),
	// idtoken.Validate will check if the 'aud' matches the provided client ID.
	// A more robust approach loops through allowedClients if the first fails due to aud mismatch,
	// but providing the expected Android client ID is sufficient for now.
	var payload *idtoken.Payload
	var err error
	var validated bool

	for _, clientID := range s.allowedClients {
		payload, err = idtoken.Validate(ctx, idTokenStr, clientID)
		if err == nil {
			validated = true
			break
		}
	}

	if !validated {
		return "", "", nil, fmt.Errorf("failed to validate id_token: %v", err)
	}

	// 2. Extract User Info
	emailRaw, ok := payload.Claims["email"]
	if !ok {
		return "", "", nil, errors.New("email not found in token claims")
	}
	email, ok := emailRaw.(string)
	if !ok {
		return "", "", nil, errors.New("email claim is not a string")
	}

	googleID := payload.Subject // The 'sub' field is the Google User ID

	// 3. Find or Create User
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed querying user by email: %w", err)
	}

	if user == nil {
		// Create new user
		user = &domain.User{
			ID:        uuid.New().String(),
			Email:     email,
			GoogleID:  &googleID,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		if err := s.userRepo.Create(ctx, user); err != nil {
			return "", "", nil, fmt.Errorf("failed creating new user: %w", err)
		}
	} else if user.GoogleID == nil {
		// Link account if GoogleID is missing
		// user.GoogleID = &googleID
		// s.userRepo.Update(ctx, user)
	}

	// 4. Generate JWT Tokens
	accessToken, refreshToken, err := jwtutil.GenerateTokens(user.ID, user.Email, s.jwtSecret)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed generating tokens: %w", err)
	}

	return accessToken, refreshToken, user, nil
}
