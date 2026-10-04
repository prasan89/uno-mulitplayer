package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MatchStatus enumerates the valid values for matches.status.
type MatchStatus string

const (
	MatchStatusWaiting   MatchStatus = "waiting"
	MatchStatusPlaying   MatchStatus = "playing"
	MatchStatusFinished  MatchStatus = "finished"
	MatchStatusAbandoned MatchStatus = "abandoned"
)

// Match mirrors the matches table row.
type Match struct {
	ID          uuid.UUID
	RoomCode    sql.NullString
	GameMode    string
	Status      MatchStatus
	MaxPlayers  int
	HouseRules  json.RawMessage
	GameState   json.RawMessage
	Version     int
	WinnerID    sql.NullString
	StartedAt   sql.NullTime
	FinishedAt  sql.NullTime
	AbandonedAt sql.NullTime
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// MatchPlayer mirrors the match_players join table.
type MatchPlayer struct {
	MatchID        uuid.UUID
	PlayerID       string
	SeatIndex      int
	IsBot          bool
	EloBefore      sql.NullInt32
	EloAfter       sql.NullInt32
	Score          int
	Placement      sql.NullInt32
	DisconnectedAt sql.NullTime
	ReconnectedAt  sql.NullTime
}

// ---- SQL statements ----

const sqlCreateMatch = `
INSERT INTO matches (game_mode, max_players, house_rules, room_code)
VALUES ($1, $2, $3, $4)
RETURNING id, room_code, game_mode, status, max_players, house_rules, game_state,
          version, winner_id, started_at, finished_at, abandoned_at, created_at, updated_at`

const sqlGetMatch = `
SELECT id, room_code, game_mode, status, max_players, house_rules, game_state,
       version, winner_id, started_at, finished_at, abandoned_at, created_at, updated_at
FROM matches WHERE id = $1`

const sqlGetMatchByRoomCode = `
SELECT id, room_code, game_mode, status, max_players, house_rules, game_state,
       version, winner_id, started_at, finished_at, abandoned_at, created_at, updated_at
FROM matches WHERE room_code = $1`

// sqlUpdateMatchState uses optimistic concurrency: the UPDATE only succeeds
// when the current version equals the caller's expected version.
const sqlUpdateMatchState = `
UPDATE matches
SET game_state = $3,
    status     = $4,
    version    = version + 1,
    updated_at = NOW()
WHERE id = $1 AND version = $2
RETURNING version`

const sqlFinishMatch = `
UPDATE matches
SET status      = 'finished',
    winner_id   = $2,
    finished_at = NOW(),
    updated_at  = NOW()
WHERE id = $1`

const sqlAbandonStaleMatches = `
UPDATE matches
SET status       = 'abandoned',
    abandoned_at = NOW(),
    updated_at   = NOW()
WHERE status IN ('waiting', 'playing')
  AND updated_at < NOW() - make_interval(secs => $1)
RETURNING id`

// ErrVersionConflict is returned by UpdateMatchState when the optimistic
// concurrency check fails.
var ErrVersionConflict = fmt.Errorf("db: version conflict — match was modified concurrently")

// CreateMatch inserts a new match row and returns it.
func (d *DB) CreateMatch(ctx context.Context, gameMode string, maxPlayers int, houseRules json.RawMessage, roomCode sql.NullString) (*Match, error) {
	if houseRules == nil {
		houseRules = json.RawMessage("{}")
	}
	row := d.pool.QueryRowContext(ctx, sqlCreateMatch, gameMode, maxPlayers, houseRules, roomCode)
	m, err := scanMatch(row)
	if err != nil {
		return nil, fmt.Errorf("db.CreateMatch: %w", err)
	}
	return m, nil
}

// GetMatch fetches a match by UUID.
func (d *DB) GetMatch(ctx context.Context, id uuid.UUID) (*Match, error) {
	row := d.pool.QueryRowContext(ctx, sqlGetMatch, id)
	m, err := scanMatch(row)
	if err != nil {
		return nil, fmt.Errorf("db.GetMatch: %w", err)
	}
	return m, nil
}

// GetMatchByRoomCode fetches a match by its 6-character room code.
func (d *DB) GetMatchByRoomCode(ctx context.Context, code string) (*Match, error) {
	row := d.pool.QueryRowContext(ctx, sqlGetMatchByRoomCode, code)
	m, err := scanMatch(row)
	if err != nil {
		return nil, fmt.Errorf("db.GetMatchByRoomCode: %w", err)
	}
	return m, nil
}

// UpdateMatchState persists a new game_state and status using optimistic
// concurrency. expectedVersion must equal the current version column value;
// if it does not, ErrVersionConflict is returned and the caller should re-fetch
// the match before retrying.
func (d *DB) UpdateMatchState(ctx context.Context, id uuid.UUID, expectedVersion int, newState json.RawMessage, newStatus MatchStatus) (newVersion int, err error) {
	row := d.pool.QueryRowContext(ctx, sqlUpdateMatchState, id, expectedVersion, newState, string(newStatus))
	if err = row.Scan(&newVersion); err != nil {
		if err == sql.ErrNoRows {
			return 0, ErrVersionConflict
		}
		return 0, fmt.Errorf("db.UpdateMatchState: %w", err)
	}
	return newVersion, nil
}

// FinishMatch marks a match as finished and records the winner.
func (d *DB) FinishMatch(ctx context.Context, id uuid.UUID, winnerID string) error {
	_, err := d.pool.ExecContext(ctx, sqlFinishMatch, id, winnerID)
	if err != nil {
		return fmt.Errorf("db.FinishMatch: %w", err)
	}
	return nil
}

// AbandonStaleMatches marks every waiting/playing match that has not been
// updated in more than staleSeconds seconds as abandoned, and returns their IDs.
func (d *DB) AbandonStaleMatches(ctx context.Context, staleSeconds int) ([]uuid.UUID, error) {
	rows, err := d.pool.QueryContext(ctx, sqlAbandonStaleMatches, staleSeconds)
	if err != nil {
		return nil, fmt.Errorf("db.AbandonStaleMatches: %w", err)
	}
	defer rows.Close() //nolint:errcheck

	var ids []uuid.UUID
	for rows.Next() {
		var id uuid.UUID
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("db.AbandonStaleMatches scan: %w", err)
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

// ---- helpers ----

func scanMatch(row rowScanner) (*Match, error) {
	var m Match
	err := row.Scan(
		&m.ID, &m.RoomCode, &m.GameMode, &m.Status, &m.MaxPlayers,
		&m.HouseRules, &m.GameState,
		&m.Version, &m.WinnerID,
		&m.StartedAt, &m.FinishedAt, &m.AbandonedAt,
		&m.CreatedAt, &m.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &m, nil
}
