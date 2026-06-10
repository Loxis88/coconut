package services

import (
	"context"
	"errors"
	"fmt"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	jwtutil "github.com/coconut/backend/pkg/jwt"
	"golang.org/x/crypto/bcrypt"
	"github.com/google/uuid"
	"time"
)

type authService struct {
	userRepo     ports.UserRepository
	emailService ports.EmailService
	jwtSecret    string
}

func NewAuthService(userRepo ports.UserRepository, emailService ports.EmailService, jwtSecret string) ports.AuthService {
	return &authService{
		userRepo:     userRepo,
		emailService: emailService,
		jwtSecret:    jwtSecret,
	}
}

var ErrEmailNotVerified = errors.New("email not verified")
var ErrInvalidCredentials = errors.New("invalid credentials")
var ErrUserAlreadyExists = errors.New("user already exists")

func (s *authService) Register(ctx context.Context, email, password string) (*domain.User, error) {
	existing, _ := s.userRepo.GetByEmail(ctx, email)
	if existing != nil {
		return nil, ErrUserAlreadyExists
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}
	hashStr := string(hash)

	user := &domain.User{
		ID:           uuid.New().String(),
		Email:        email,
		PasswordHash: &hashStr,
		IsVerified:   false,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

func (s *authService) Login(ctx context.Context, email, password string) (string, string, *domain.User, error) {
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed to get user: %w", err)
	}
	if user == nil || user.PasswordHash == nil {
		return "", "", nil, ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(*user.PasswordHash), []byte(password)); err != nil {
		return "", "", nil, ErrInvalidCredentials
	}

	if !user.IsVerified {
		return "", "", user, ErrEmailNotVerified
	}

	accessToken, refreshToken, err := jwtutil.GenerateTokens(user.ID, user.Email, s.jwtSecret)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed to generate tokens: %w", err)
	}

	return accessToken, refreshToken, user, nil
}

func (s *authService) SendVerificationEmail(ctx context.Context, userID, email, verifyURLBase string) error {
	token, err := jwtutil.GenerateVerificationToken(userID, email, s.jwtSecret)
	if err != nil {
		return fmt.Errorf("failed to generate verification token: %w", err)
	}

	verifyURL := fmt.Sprintf("%s?token=%s", verifyURLBase, token)
	return s.emailService.SendVerificationEmail(email, verifyURL)
}

func (s *authService) VerifyEmail(ctx context.Context, token string) error {
	claims, err := jwtutil.ValidateToken(token, s.jwtSecret)
	if err != nil {
		return fmt.Errorf("invalid verification token: %w", err)
	}

	user, err := s.userRepo.GetByID(ctx, claims.UserID)
	if err != nil {
		return fmt.Errorf("failed to get user: %w", err)
	}
	if user == nil {
		return errors.New("user not found")
	}

	if user.IsVerified {
		return nil // already verified
	}

	if err := s.userRepo.MarkVerified(ctx, user.ID); err != nil {
		return fmt.Errorf("failed to mark user as verified: %w", err)
	}

	return nil
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

func (s *authService) GetUserByEmail(ctx context.Context, email string) (*domain.User, error) {
	return s.userRepo.GetByEmail(ctx, email)
}

func (s *authService) DeleteAccount(ctx context.Context, userID string) error {
	return s.userRepo.Delete(ctx, userID)
}
