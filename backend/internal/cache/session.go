package cache

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/go-redis/redis/v9"
	"github.com/uno-multiplayer/server/internal/game"
)

// Session holds the data stored under session:{playerID}.
type Session struct {
	GameID      string    `json:"game_id"`
	ConnectedAt time.Time `json:"connected_at"`
	LastAction  time.Time `json:"last_action"`
}

// ─── Game state ──────────────────────────────────────────────────────────────

// GetGameState retrieves and deserialises the game state for gameID.
// Returns (nil, nil) when the key does not exist.
func (c *Cache) GetGameState(ctx context.Context, gameID string) (*game.GameState, error) {
	raw, err := c.client.Get(ctx, gameKey(gameID)).Bytes()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, nil
		}
		return nil, fmt.Errorf("cache.GetGameState %q: %w", gameID, err)
	}

	var state game.GameState
	if err := json.Unmarshal(raw, &state); err != nil {
		return nil, fmt.Errorf("cache.GetGameState %q: unmarshal: %w", gameID, err)
	}
	return &state, nil
}

// SetGameState serialises state and stores it under game:{gameID} with a 2 h TTL.
func (c *Cache) SetGameState(ctx context.Context, gameID string, state *game.GameState) error {
	raw, err := json.Marshal(state)
	if err != nil {
		return fmt.Errorf("cache.SetGameState %q: marshal: %w", gameID, err)
	}
	if err := c.client.Set(ctx, gameKey(gameID), raw, TTLGameState).Err(); err != nil {
		return fmt.Errorf("cache.SetGameState %q: %w", gameID, err)
	}
	return nil
}

// DeleteGameState removes the game state key for gameID.
func (c *Cache) DeleteGameState(ctx context.Context, gameID string) error {
	if err := c.client.Del(ctx, gameKey(gameID)).Err(); err != nil {
		return fmt.Errorf("cache.DeleteGameState %q: %w", gameID, err)
	}
	return nil
}

// ─── Sessions ────────────────────────────────────────────────────────────────

// GetSession returns the session for playerID or (nil, nil) if not found.
func (c *Cache) GetSession(ctx context.Context, playerID string) (*Session, error) {
	raw, err := c.client.Get(ctx, keyPrefixSession+playerID).Bytes()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, nil
		}
		return nil, fmt.Errorf("cache.GetSession %q: %w", playerID, err)
	}

	var s Session
	if err := json.Unmarshal(raw, &s); err != nil {
		return nil, fmt.Errorf("cache.GetSession %q: unmarshal: %w", playerID, err)
	}
	return &s, nil
}

// SetSession stores s under session:{playerID} with a 24 h TTL.
func (c *Cache) SetSession(ctx context.Context, playerID string, s *Session) error {
	raw, err := json.Marshal(s)
	if err != nil {
		return fmt.Errorf("cache.SetSession %q: marshal: %w", playerID, err)
	}
	if err := c.client.Set(ctx, keyPrefixSession+playerID, raw, TTLSession).Err(); err != nil {
		return fmt.Errorf("cache.SetSession %q: %w", playerID, err)
	}
	return nil
}

// ─── Room codes ──────────────────────────────────────────────────────────────

// SetRoomCode stores the mapping code -> gameID with a 48 h TTL.
func (c *Cache) SetRoomCode(ctx context.Context, code, gameID string) error {
	if err := c.client.Set(ctx, roomCodeKey(code), gameID, TTLRoomCode).Err(); err != nil {
		return fmt.Errorf("cache.SetRoomCode %q: %w", code, err)
	}
	return nil
}

// GetRoomCode returns the gameID for code, or ("", nil) if not found.
func (c *Cache) GetRoomCode(ctx context.Context, code string) (string, error) {
	val, err := c.client.Get(ctx, roomCodeKey(code)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return "", nil
		}
		return "", fmt.Errorf("cache.GetRoomCode %q: %w", code, err)
	}
	return val, nil
}

// ─── Action deduplication ────────────────────────────────────────────────────

// CheckAndSetActionDedup performs an atomic SET NX on action:{playerID}:{seq}.
// Returns true if the action is a duplicate (key already existed), false otherwise.
func (c *Cache) CheckAndSetActionDedup(ctx context.Context, playerID string, seq int) (bool, error) {
	key := actionKey(playerID, seq)
	set, err := c.client.SetNX(ctx, key, "1", TTLActionDedup).Result()
	if err != nil {
		return false, fmt.Errorf("cache.CheckAndSetActionDedup player=%q seq=%d: %w", playerID, seq, err)
	}
	// SetNX returns true if the key was newly set (not a duplicate).
	return !set, nil
}
