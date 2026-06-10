package services

import (
	"context"
	"errors"
	"fmt"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	jwtutil "github.com/coconut/backend/pkg/jwt"
)

type authService struct {
	userRepo       ports.UserRepository
	jwtSecret      string
}

func NewAuthService(userRepo ports.UserRepository, jwtSecret string) ports.AuthService {
	return &authService{
		userRepo:       userRepo,
		jwtSecret:      jwtSecret,
	}
}


func (s *authService) RefreshTokens(ctx context.Context, refreshToken string) (string, string, error) {
	// Validate the refresh token
	claims, err := jwtutil.ValidateToken(refreshToken, s.jwtSecret)
	if err != nil {
		return "", "", fmt.Errorf("invalid refresh token: %w", err)
	}

	// Verify user still exists
	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return "", "", fmt.Errorf("failed to get user: %w", err)
	}
	if user == nil {
		return "", "", errors.New("user not found")
	}

	// Generate new tokens
	newAccessToken, newRefreshToken, err := jwtutil.GenerateTokens(user.ID, user.Email, s.jwtSecret)
	if err != nil {
		return "", "", fmt.Errorf("failed generating tokens: %w", err)
	}

	return newAccessToken, newRefreshToken, nil
}

func (s *authService) UpdateNickname(ctx context.Context, userID, nickname string) error {
	return s.userRepo.UpdateNickname(ctx, userID, nickname)
}

func (s *authService) GetUserByID(ctx context.Context, userID string) (*domain.User, error) {
	return s.userRepo.GetByID(ctx, userID)
}

func (s *authService) DeleteAccount(ctx context.Context, userID string) error {
	return s.userRepo.Delete(ctx, userID)
}
