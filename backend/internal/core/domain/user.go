package domain

import (
	"time"
)

type User struct {
	ID                string    `json:"id"`
	Email             string    `json:"email"`
	Nickname          string    `json:"nickname"`
	GoogleID          *string   `json:"google_id,omitempty"`
	PasswordHash      *string   `json:"-"` // Omitted from JSON for security
	AppleID           *string   `json:"apple_id,omitempty"`
	IsVerified        bool      `json:"is_verified"`
	VerificationToken *string   `json:"-"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}
