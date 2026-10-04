package cache

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// ─── Presence ────────────────────────────────────────────────────────────────

// IsOnline returns true if playerID has an active presence key (i.e. the key
// exists and has not expired). The presence key is kept alive by the client
// sending a ping every 30 s, which calls SetOnline to refresh the 90 s TTL.
func (c *Cache) IsOnline(ctx context.Context, playerID string) (bool, error) {
	exists, err := c.client.Exists(ctx, keyPrefixPresence+playerID).Result()
	if err != nil {
		return false, fmt.Errorf("cache.IsOnline %q: %w", playerID, err)
	}
	return exists > 0, nil
}

// SetOnline creates or refreshes the presence key for playerID with a 90 s TTL.
// Call this on every ping (every ~30 s) to keep the player marked as online.
func (c *Cache) SetOnline(ctx context.Context, playerID string) error {
	if err := c.client.Set(ctx, keyPrefixPresence+playerID, "online", TTLPresence).Err(); err != nil {
		return fmt.Errorf("cache.SetOnline %q: %w", playerID, err)
	}
	return nil
}

// ─── Matchmaking queues ──────────────────────────────────────────────────────

// QueueJoin adds playerID to the sorted set queue:{mode} using the current
// Unix nanosecond timestamp as the score (earlier = higher priority).
func (c *Cache) QueueJoin(ctx context.Context, mode, playerID string) error {
	score := float64(time.Now().UnixNano())
	if err := c.client.ZAdd(ctx, keyPrefixQueue+mode, redis.Z{
		Score:  score,
		Member: playerID,
	}).Err(); err != nil {
		return fmt.Errorf("cache.QueueJoin mode=%q player=%q: %w", mode, playerID, err)
	}
	return nil
}

// QueueLeave removes playerID from the sorted set queue:{mode}.
func (c *Cache) QueueLeave(ctx context.Context, mode, playerID string) error {
	if err := c.client.ZRem(ctx, keyPrefixQueue+mode, playerID).Err(); err != nil {
		return fmt.Errorf("cache.QueueLeave mode=%q player=%q: %w", mode, playerID, err)
	}
	return nil
}

// QueuePop atomically removes and returns up to count player IDs from the front
// of the queue (lowest score = earliest join time) using ZPOPMIN.
// Returns an empty slice when the queue is empty.
func (c *Cache) QueuePop(ctx context.Context, mode string, count int) ([]string, error) {
	members, err := c.client.ZPopMin(ctx, keyPrefixQueue+mode, int64(count)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, nil
		}
		return nil, fmt.Errorf("cache.QueuePop mode=%q count=%d: %w", mode, count, err)
	}

	ids := make([]string, 0, len(members))
	for _, m := range members {
		if s, ok := m.Member.(string); ok {
			ids = append(ids, s)
		}
	}
	return ids, nil
}

// QueueSize returns the number of players currently waiting in queue:{mode}.
func (c *Cache) QueueSize(ctx context.Context, mode string) (int64, error) {
	size, err := c.client.ZCard(ctx, keyPrefixQueue+mode).Result()
	if err != nil {
		return 0, fmt.Errorf("cache.QueueSize mode=%q: %w", mode, err)
	}
	return size, nil
}
