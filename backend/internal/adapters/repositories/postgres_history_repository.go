package repositories

import (
	"context"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresHistoryRepository struct {
	db *pgxpool.Pool
}

func NewPostgresHistoryRepository(db *pgxpool.Pool) ports.HistoryRepository {
	return &PostgresHistoryRepository{db: db}
}

func (r *PostgresHistoryRepository) Create(ctx context.Context, history *domain.SearchHistory) error {
	query := `
		INSERT INTO search_history (id, user_id, barcode, title, score, scanned_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`
	_, err := r.db.Exec(ctx, query, history.ID, history.UserID, history.Barcode, history.Title, history.Score, history.ScannedAt)
	return err
}

func (r *PostgresHistoryRepository) GetByUserID(ctx context.Context, userID string) ([]domain.SearchHistory, error) {
	query := `
		SELECT id, user_id, barcode, title, score, scanned_at
		FROM search_history
		WHERE user_id = $1
		ORDER BY scanned_at DESC
	`
	rows, err := r.db.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var histories []domain.SearchHistory
	for rows.Next() {
		var h domain.SearchHistory
		err := rows.Scan(&h.ID, &h.UserID, &h.Barcode, &h.Title, &h.Score, &h.ScannedAt)
		if err != nil {
			return nil, err
		}
		histories = append(histories, h)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return histories, nil
}

func (r *PostgresHistoryRepository) DeleteAllByUserID(ctx context.Context, userID string) error {
	query := `DELETE FROM search_history WHERE user_id = $1`
	_, err := r.db.Exec(ctx, query, userID)
	return err
}
