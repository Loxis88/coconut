package domain

import (
	"time"
)

type User struct {
	ID           string    `json:"id"`
	Email        string    `json:"email"`
	Nickname     string    `json:"nickname"`
	PasswordHash *string   `json:"-"` // Omitted from JSON for security
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
