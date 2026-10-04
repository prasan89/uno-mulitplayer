package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v9"
)

// rateLimitWindow is the sliding-window duration for the per-player action rate limit.
const rateLimitWindow = time.Second

// rateLimitMax is the maximum number of actions allowed within rateLimitWindow.
const rateLimitMax = 10

// rateLimitScript is a Lua script that implements a sliding-window rate limit
// using a sorted set.
//
// KEYS[1]  - the sorted-set key, e.g. "ratelimit:action:{playerID}"
// ARGV[1]  - current Unix timestamp in nanoseconds (used as both score and member)
// ARGV[2]  - window start in nanoseconds (nowNano - windowNano)
// ARGV[3]  - window size in nanoseconds
// ARGV[4]  - max allowed requests
//
// Returns 1 if the caller is over the limit, 0 if the request is allowed.
var rateLimitScript = redis.NewScript(`
local key     = KEYS[1]
local now     = tonumber(ARGV[1])
local winStart= tonumber(ARGV[2])
local winNs   = tonumber(ARGV[3])
local maxReqs = tonumber(ARGV[4])

-- Remove entries outside the sliding window.
redis.call("ZREMRANGEBYSCORE", key, "-inf", winStart)

-- Count remaining entries in the window.
local count = redis.call("ZCARD", key)

if count >= maxReqs then
    return 1
end

-- Add this request as a new entry (member = now as string to ensure uniqueness).
redis.call("ZADD", key, now, tostring(now))

-- Refresh TTL so the key does not linger after inactivity.
redis.call("PEXPIRE", key, math.ceil(winNs / 1000000))

return 0
`)

// CheckRateLimit checks whether playerID has exceeded the per-second action rate
// limit (10 actions per second, sliding window).
// Returns true if the player is over the limit, false if the request is allowed.
func (c *Cache) CheckRateLimit(ctx context.Context, playerID string) (bool, error) {
	key := keyPrefixRateLimit + playerID

	nowNano := time.Now().UnixNano()
	windowNano := rateLimitWindow.Nanoseconds()
	winStart := nowNano - windowNano

	result, err := rateLimitScript.Run(
		ctx,
		c.client,
		[]string{key},
		nowNano,
		winStart,
		windowNano,
		rateLimitMax,
	).Int()
	if err != nil {
		return false, fmt.Errorf("cache.CheckRateLimit player=%q: %w", playerID, err)
	}

	return result == 1, nil
}
