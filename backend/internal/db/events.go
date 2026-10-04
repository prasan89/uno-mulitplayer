package db

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// GameEvent mirrors one row of the game_events table.
type GameEvent struct {
	ID        int64
	MatchID   uuid.UUID
	Sequence  int
	PlayerID  string
	EventType string
	Payload   json.RawMessage
	CreatedAt time.Time
}

// ---- SQL ----

const sqlAppendEvent = `
INSERT INTO game_events (match_id, sequence, player_id, event_type, payload)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, match_id, sequence, player_id, event_type, payload, created_at`

const sqlGetMatchEvents = `
SELECT id, match_id, sequence, player_id, event_type, payload, created_at
FROM game_events
WHERE match_id = $1
ORDER BY sequence ASC`

const sqlGetMatchEventsSince = `
SELECT id, match_id, sequence, player_id, event_type, payload, created_at
FROM game_events
WHERE match_id = $1 AND sequence > $2
ORDER BY sequence ASC`

// AppendEvent inserts a new event for a match.  sequence must be unique per
// match; the caller should derive it from the last known sequence + 1.  On
// duplicate-sequence conflicts the database will return a unique-violation
// error which the caller may handle as a retry signal.
func (d *DB) AppendEvent(ctx context.Context, matchID uuid.UUID, sequence int, playerID, eventType string, payload json.RawMessage) (*GameEvent, error) {
	if payload == nil {
		payload = json.RawMessage("{}")
	}
	row := d.pool.QueryRowContext(ctx, sqlAppendEvent,
		matchID, sequence, playerID, eventType, payload)

	var e GameEvent
	err := row.Scan(&e.ID, &e.MatchID, &e.Sequence, &e.PlayerID, &e.EventType, &e.Payload, &e.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("db.AppendEvent: %w", err)
	}
	return &e, nil
}

// GetMatchEvents returns all events for a match ordered by sequence.
func (d *DB) GetMatchEvents(ctx context.Context, matchID uuid.UUID) ([]GameEvent, error) {
	rows, err := d.pool.QueryContext(ctx, sqlGetMatchEvents, matchID)
	if err != nil {
		return nil, fmt.Errorf("db.GetMatchEvents: %w", err)
	}
	defer rows.Close() //nolint:errcheck
	return scanEvents(rows)
}

// GetMatchEventsSince returns events for a match with sequence > afterSequence.
// Useful for incremental catch-up after a reconnect.
func (d *DB) GetMatchEventsSince(ctx context.Context, matchID uuid.UUID, afterSequence int) ([]GameEvent, error) {
	rows, err := d.pool.QueryContext(ctx, sqlGetMatchEventsSince, matchID, afterSequence)
	if err != nil {
		return nil, fmt.Errorf("db.GetMatchEventsSince: %w", err)
	}
	defer rows.Close() //nolint:errcheck
	return scanEvents(rows)
}

func scanEvents(rows interface {
	Next() bool
	Scan(dest ...any) error
	Err() error
}) ([]GameEvent, error) {
	var out []GameEvent
	for rows.Next() {
		var e GameEvent
		if err := rows.Scan(
			&e.ID, &e.MatchID, &e.Sequence, &e.PlayerID,
			&e.EventType, &e.Payload, &e.CreatedAt,
		); err != nil {
			return nil, fmt.Errorf("db scanEvents: %w", err)
		}
		out = append(out, e)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("db scanEvents rows: %w", err)
	}
	return out, nil
}
