package domain

import (
	"time"
)

type SearchHistory struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	Barcode   string    `json:"barcode"`
	Title     string    `json:"title"`
	Score     int       `json:"score"`
	ScannedAt time.Time `json:"scanned_at"`
}
