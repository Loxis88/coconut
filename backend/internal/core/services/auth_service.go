package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	jwtutil "github.com/coconut/backend/pkg/jwt"
	"github.com/google/uuid"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

type authService struct {
	userRepo    ports.UserRepository
	oauthConfig *oauth2.Config
	jwtSecret   string
}

func NewAuthService(userRepo ports.UserRepository, clientID, clientSecret, redirectURL, jwtSecret string) ports.AuthService {
	conf := &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Scopes: []string{
			"https://www.googleapis.com/auth/userinfo.email",
			"https://www.googleapis.com/auth/userinfo.profile",
		},
		Endpoint: google.Endpoint,
	}

	return &authService{
		userRepo:    userRepo,
		oauthConfig: conf,
		jwtSecret:   jwtSecret,
	}
}

func (s *authService) GetGoogleLoginURL(state string) string {
	return s.oauthConfig.AuthCodeURL(state)
}

func (s *authService) GoogleCallback(ctx context.Context, code string) (string, string, *domain.User, error) {
	// 1. Exchange code for token
	token, err := s.oauthConfig.Exchange(ctx, code)
	if err != nil {
		return "", "", nil, fmt.Errorf("code exchange failed: %w", err)
	}

	// 2. Fetch user info from Google
	client := s.oauthConfig.Client(ctx, token)
	resp, err := client.Get("https://www.googleapis.com/oauth2/v2/userinfo")
	if err != nil {
		return "", "", nil, fmt.Errorf("failed getting user info: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", "", nil, fmt.Errorf("google api returned status %d: %s", resp.StatusCode, body)
	}

	var googleUser struct {
		ID    string `json:"id"`
		Email string `json:"email"`
		Name  string `json:"name"`
		// Picture string `json:"picture"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&googleUser); err != nil {
		return "", "", nil, fmt.Errorf("failed decoding user info: %w", err)
	}

	if googleUser.Email == "" || googleUser.ID == "" {
		return "", "", nil, errors.New("incomplete user info received from Google")
	}

	// 3. Find or Create User
	user, err := s.userRepo.GetByEmail(ctx, googleUser.Email)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed querying user by email: %w", err)
	}

	if user == nil {
		// Create new user
		user = &domain.User{
			ID:        uuid.New().String(),
			Email:     googleUser.Email,
			GoogleID:  &googleUser.ID,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}
		if err := s.userRepo.Create(ctx, user); err != nil {
			return "", "", nil, fmt.Errorf("failed creating new user: %w", err)
		}
	} else if user.GoogleID == nil {
		// Update existing user with Google ID (if they signed up with email first, for future proofing)
		// TODO: Implement an Update method in UserRepository to set GoogleID.
		// For now, we will just proceed, but ideally we link the account.
		// user.GoogleID = &googleUser.ID
		// s.userRepo.Update(ctx, user)
	}

	// 4. Generate JWT Tokens
	accessToken, refreshToken, err := jwtutil.GenerateTokens(user.ID, user.Email, s.jwtSecret)
	if err != nil {
		return "", "", nil, fmt.Errorf("failed generating tokens: %w", err)
	}

	return accessToken, refreshToken, user, nil
}
