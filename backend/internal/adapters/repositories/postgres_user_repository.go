package repositories

import (
	"context"
	"errors"
	"time"

	"github.com/coconut/backend/internal/core/domain"
	"github.com/coconut/backend/internal/core/ports"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresUserRepository struct {
	db *pgxpool.Pool
}

func NewPostgresUserRepository(db *pgxpool.Pool) ports.UserRepository {
	return &PostgresUserRepository{db: db}
}

func (r *PostgresUserRepository) Create(ctx context.Context, user *domain.User) error {
	query := `
		INSERT INTO users (id, email, nickname, google_id, password_hash, apple_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := r.db.Exec(ctx, query, user.ID, user.Email, user.Nickname, user.GoogleID, user.PasswordHash, user.AppleID, user.CreatedAt, user.UpdatedAt)
	return err
}

func (r *PostgresUserRepository) GetByID(ctx context.Context, id string) (*domain.User, error) {
	query := `
		SELECT id, email, nickname, google_id, password_hash, apple_id, created_at, updated_at
		FROM users
		WHERE id = $1
	`
	user := &domain.User{}
	err := r.db.QueryRow(ctx, query, id).Scan(
		&user.ID, &user.Email, &user.Nickname, &user.GoogleID, &user.PasswordHash, &user.AppleID, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil // Return nil, nil if not found
		}
		return nil, err
	}
	return user, nil
}

func (r *PostgresUserRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	query := `
		SELECT id, email, nickname, google_id, password_hash, apple_id, created_at, updated_at
		FROM users
		WHERE email = $1
	`
	user := &domain.User{}
	err := r.db.QueryRow(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.Nickname, &user.GoogleID, &user.PasswordHash, &user.AppleID, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return user, nil
}

func (r *PostgresUserRepository) GetByGoogleID(ctx context.Context, googleID string) (*domain.User, error) {
	query := `
		SELECT id, email, nickname, google_id, password_hash, apple_id, created_at, updated_at
		FROM users
		WHERE google_id = $1
	`
	user := &domain.User{}
	err := r.db.QueryRow(ctx, query, googleID).Scan(
		&user.ID, &user.Email, &user.Nickname, &user.GoogleID, &user.PasswordHash, &user.AppleID, &user.CreatedAt, &user.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return user, nil
}

func (r *PostgresUserRepository) UpdateNickname(ctx context.Context, userID, nickname string) error {
	query := `UPDATE users SET nickname = $1, updated_at = $2 WHERE id = $3`
	_, err := r.db.Exec(ctx, query, nickname, time.Now(), userID)
	return err
}
