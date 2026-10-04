// Package cache provides a Redis-backed cache layer for the UNO multiplayer server.
// It wraps go-redis/v9 and exposes typed methods for game state, sessions,
// presence, matchmaking queues, rate limiting, room codes, and action dedup.
package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Key prefixes and TTLs used throughout the cache layer.
const (
	keyPrefixGame      = "game:"
	keyPrefixSession   = "session:"
	keyPrefixPresence  = "presence:"
	keyPrefixQueue     = "queue:"
	keyPrefixRateLimit = "ratelimit:action:"
	keyPrefixRoomCode  = "roomcode:"
	keyPrefixAction    = "action:"

	TTLGameState  = 2 * time.Hour
	TTLSession    = 24 * time.Hour
	TTLPresence   = 90 * time.Second
	TTLRoomCode   = 48 * time.Hour
	TTLActionDedup = 60 * time.Second
)

// Cache wraps a go-redis v9 client and provides all cache operations.
type Cache struct {
	client *redis.Client
}

// New constructs a Cache from the supplied *redis.Client.
// The caller is responsible for configuring the client (address, auth, etc.)
// and for calling client.Close() on shutdown.
func New(client *redis.Client) *Cache {
	return &Cache{client: client}
}

// NewFromOptions is a convenience constructor that creates a new *redis.Client
// from the supplied options and wraps it in a Cache.
func NewFromOptions(opts *redis.Options) (*Cache, error) {
	client := redis.NewClient(opts)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		return nil, fmt.Errorf("cache: redis ping failed: %w", err)
	}

	return New(client), nil
}

// Close closes the underlying Redis client connection.
func (c *Cache) Close() error {
	if err := c.client.Close(); err != nil {
		return fmt.Errorf("cache: close failed: %w", err)
	}
	return nil
}

// gameKey returns the Redis key for a game state entry.
func gameKey(gameID string) string { return keyPrefixGame + gameID }

// roomCodeKey returns the Redis key for a room-code mapping.
func roomCodeKey(code string) string { return keyPrefixRoomCode + code }

// actionKey returns the Redis key for an action dedup entry.
func actionKey(playerID string, seq int) string {
	return fmt.Sprintf("%s%s:%d", keyPrefixAction, playerID, seq)
}
