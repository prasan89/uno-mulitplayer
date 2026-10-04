package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// Player mirrors the players table.
type Player struct {
	ID          string
	Email       string
	DisplayName string
	AvatarURL   sql.NullString
	EloRating   int
	GamesPlayed int
	GamesWon    int
	TotalScore  int
	CreatedAt   time.Time
	UpdatedAt   time.Time
	LastSeenAt  time.Time
	IsBanned    bool
	BanReason   sql.NullString
}

// LeaderboardEntry is a single row from the leaderboard materialized view.
type LeaderboardEntry struct {
	ID          string
	DisplayName string
	AvatarURL   sql.NullString
	EloRating   int
	GamesPlayed int
	GamesWon    int
	WinRate     sql.NullFloat64
}

// ---- prepared statement SQL ----

const sqlGetPlayer = `
SELECT id, email, display_name, avatar_url,
       elo_rating, games_played, games_won, total_score,
       created_at, updated_at, last_seen_at,
       is_banned, ban_reason
FROM players WHERE id = $1`

const sqlUpsertPlayer = `
INSERT INTO players (id, email, display_name, avatar_url, last_seen_at)
VALUES ($1, $2, $3, $4, NOW())
ON CONFLICT (id) DO UPDATE SET
    email        = EXCLUDED.email,
    display_name = EXCLUDED.display_name,
    avatar_url   = EXCLUDED.avatar_url,
    last_seen_at = NOW(),
    updated_at   = NOW()
RETURNING id, email, display_name, avatar_url,
          elo_rating, games_played, games_won, total_score,
          created_at, updated_at, last_seen_at, is_banned, ban_reason`

const sqlUpdatePlayerELO = `
UPDATE players
SET elo_rating  = $2,
    games_played = games_played + 1,
    games_won    = games_won + $3,
    updated_at   = NOW()
WHERE id = $1`

const sqlGetLeaderboard = `
SELECT id, display_name, avatar_url, elo_rating, games_played, games_won, win_rate
FROM leaderboard`

// GetPlayer fetches a player by Firebase UID. Returns sql.ErrNoRows if not found.
func (d *DB) GetPlayer(ctx context.Context, id string) (*Player, error) {
	row := d.pool.QueryRowContext(ctx, sqlGetPlayer, id)
	p, err := scanPlayer(row)
	if err != nil {
		return nil, fmt.Errorf("db.GetPlayer: %w", err)
	}
	return p, nil
}

// UpsertPlayer creates or updates a player record and returns the latest state.
func (d *DB) UpsertPlayer(ctx context.Context, id, email, displayName string, avatarURL sql.NullString) (*Player, error) {
	row := d.pool.QueryRowContext(ctx, sqlUpsertPlayer, id, email, displayName, avatarURL)
	p, err := scanPlayer(row)
	if err != nil {
		return nil, fmt.Errorf("db.UpsertPlayer: %w", err)
	}
	return p, nil
}

// UpdatePlayerELO atomically updates both players' ELO ratings and game
// counters inside a single transaction.
//   - wonA: 1 if player A won this match, 0 otherwise.
//   - wonB: 1 if player B won this match, 0 otherwise.
func (d *DB) UpdatePlayerELO(ctx context.Context, playerAID string, newEloA int, wonA int, playerBID string, newEloB int, wonB int) error {
	tx, err := d.pool.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("db.UpdatePlayerELO begin tx: %w", err)
	}
	defer func() {
		if err != nil {
			_ = tx.Rollback()
		}
	}()

	if _, err = tx.ExecContext(ctx, sqlUpdatePlayerELO, playerAID, newEloA, wonA); err != nil {
		return fmt.Errorf("db.UpdatePlayerELO update A: %w", err)
	}
	if _, err = tx.ExecContext(ctx, sqlUpdatePlayerELO, playerBID, newEloB, wonB); err != nil {
		return fmt.Errorf("db.UpdatePlayerELO update B: %w", err)
	}

	if err = tx.Commit(); err != nil {
		return fmt.Errorf("db.UpdatePlayerELO commit: %w", err)
	}
	return nil
}

// GetLeaderboard returns the top-100 rows from the leaderboard materialized
// view. Callers should call RefreshLeaderboard periodically to keep it fresh.
func (d *DB) GetLeaderboard(ctx context.Context) ([]LeaderboardEntry, error) {
	rows, err := d.pool.QueryContext(ctx, sqlGetLeaderboard)
	if err != nil {
		return nil, fmt.Errorf("db.GetLeaderboard: %w", err)
	}
	defer rows.Close() //nolint:errcheck

	var out []LeaderboardEntry
	for rows.Next() {
		var e LeaderboardEntry
		if err := rows.Scan(
			&e.ID, &e.DisplayName, &e.AvatarURL,
			&e.EloRating, &e.GamesPlayed, &e.GamesWon, &e.WinRate,
		); err != nil {
			return nil, fmt.Errorf("db.GetLeaderboard scan: %w", err)
		}
		out = append(out, e)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("db.GetLeaderboard rows: %w", err)
	}
	return out, nil
}

// RefreshLeaderboard triggers a CONCURRENTLY refresh of the materialized view.
func (d *DB) RefreshLeaderboard(ctx context.Context) error {
	_, err := d.pool.ExecContext(ctx, `REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard`)
	if err != nil {
		return fmt.Errorf("db.RefreshLeaderboard: %w", err)
	}
	return nil
}

// ---- helpers ----

type rowScanner interface {
	Scan(dest ...any) error
}

func scanPlayer(row rowScanner) (*Player, error) {
	var p Player
	err := row.Scan(
		&p.ID, &p.Email, &p.DisplayName, &p.AvatarURL,
		&p.EloRating, &p.GamesPlayed, &p.GamesWon, &p.TotalScore,
		&p.CreatedAt, &p.UpdatedAt, &p.LastSeenAt,
		&p.IsBanned, &p.BanReason,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, sql.ErrNoRows
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}
