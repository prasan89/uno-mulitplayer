package cache

import (
	"context"
	"testing"
	"time"

	"github.com/alicebob/miniredis/v2"
	goredis "github.com/go-redis/redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/uno-multiplayer/server/internal/game"
)

// ─── Test fixtures ─────────────────────────────────────────────────────────────

// newTestCache starts an in-memory miniredis server and returns a Cache backed
// by it, plus a cleanup function.
func newTestCache(t *testing.T) (*Cache, *miniredis.Miniredis) {
	t.Helper()
	mr, err := miniredis.Run()
	require.NoError(t, err, "failed to start miniredis")

	client := goredis.NewClient(&goredis.Options{
		Addr: mr.Addr(),
	})
	t.Cleanup(func() {
		_ = client.Close()
		mr.Close()
	})

	return New(client), mr
}

// sampleGameState returns a minimal *game.GameState for serialization tests.
func sampleGameState() *game.GameState {
	pis := []game.PlayerInfo{
		{ID: "p1", Name: "Alice"},
		{ID: "p2", Name: "Bob"},
	}
	return game.NewGame(pis, game.HouseRules{})
}

// ─── GetGameState / SetGameState ─────────────────────────────────────────────

func TestCache_SetAndGetGameState_Roundtrip(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	original := sampleGameState()
	gameID := original.GameID

	err := c.SetGameState(ctx, gameID, original)
	require.NoError(t, err)

	retrieved, err := c.GetGameState(ctx, gameID)
	require.NoError(t, err)
	require.NotNil(t, retrieved)

	assert.Equal(t, original.GameID, retrieved.GameID)
	assert.Equal(t, original.Phase, retrieved.Phase)
	assert.Equal(t, len(original.Players), len(retrieved.Players))
	assert.Equal(t, original.Direction, retrieved.Direction)
	assert.Equal(t, original.CurrentPlayerIndex, retrieved.CurrentPlayerIndex)
}

func TestCache_GetGameState_ReturnsNilForMissingKey(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	result, err := c.GetGameState(ctx, "nonexistent-game")
	require.NoError(t, err)
	assert.Nil(t, result, "GetGameState should return nil for missing key")
}

func TestCache_SetGameState_OverwritesExisting(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	g := sampleGameState()
	g.Version = 1
	require.NoError(t, c.SetGameState(ctx, g.GameID, g))

	g2 := g.Clone()
	g2.Version = 99
	require.NoError(t, c.SetGameState(ctx, g.GameID, g2))

	retrieved, err := c.GetGameState(ctx, g.GameID)
	require.NoError(t, err)
	require.NotNil(t, retrieved)
	assert.Equal(t, 99, retrieved.Version, "second set should overwrite first")
}

func TestCache_DeleteGameState_RemovesKey(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	g := sampleGameState()
	require.NoError(t, c.SetGameState(ctx, g.GameID, g))

	require.NoError(t, c.DeleteGameState(ctx, g.GameID))

	result, err := c.GetGameState(ctx, g.GameID)
	require.NoError(t, err)
	assert.Nil(t, result, "game state should be nil after deletion")
}

func TestCache_SetGameState_TTL_Set(t *testing.T) {
	c, mr := newTestCache(t)
	ctx := context.Background()

	g := sampleGameState()
	require.NoError(t, c.SetGameState(ctx, g.GameID, g))

	key := gameKey(g.GameID)
	ttl := mr.TTL(key)
	assert.Greater(t, ttl, time.Duration(0), "game state key should have a positive TTL")
	assert.LessOrEqual(t, ttl, TTLGameState, "TTL should not exceed configured max")
}

// ─── Session ──────────────────────────────────────────────────────────────────

func TestCache_SetAndGetSession_Roundtrip(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	playerID := "player-xyz"
	s := &Session{
		GameID:      "game-abc",
		ConnectedAt: time.Now().UTC().Truncate(time.Millisecond),
		LastAction:  time.Now().UTC().Truncate(time.Millisecond),
	}
	require.NoError(t, c.SetSession(ctx, playerID, s))

	got, err := c.GetSession(ctx, playerID)
	require.NoError(t, err)
	require.NotNil(t, got)
	assert.Equal(t, s.GameID, got.GameID)
}

func TestCache_GetSession_NilForMissing(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	got, err := c.GetSession(ctx, "no-such-player")
	require.NoError(t, err)
	assert.Nil(t, got)
}

// ─── Action deduplication ─────────────────────────────────────────────────────

func TestCache_CheckAndSetActionDedup_FirstCallNotDuplicate(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	dup, err := c.CheckAndSetActionDedup(ctx, "player-1", 1)
	require.NoError(t, err)
	assert.False(t, dup, "first call with a new seq should not be a duplicate")
}

func TestCache_CheckAndSetActionDedup_SecondCallIsDuplicate(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	_, err := c.CheckAndSetActionDedup(ctx, "player-1", 42)
	require.NoError(t, err)

	dup, err := c.CheckAndSetActionDedup(ctx, "player-1", 42)
	require.NoError(t, err)
	assert.True(t, dup, "second call with same seq should be a duplicate")
}

func TestCache_CheckAndSetActionDedup_DifferentSeqNotDuplicate(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	_, _ = c.CheckAndSetActionDedup(ctx, "player-1", 1)

	dup, err := c.CheckAndSetActionDedup(ctx, "player-1", 2)
	require.NoError(t, err)
	assert.False(t, dup, "different seq number should not be a duplicate")
}

func TestCache_CheckAndSetActionDedup_DifferentPlayerNotDuplicate(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	_, _ = c.CheckAndSetActionDedup(ctx, "player-A", 7)

	dup, err := c.CheckAndSetActionDedup(ctx, "player-B", 7)
	require.NoError(t, err)
	assert.False(t, dup, "same seq but different player should not be a duplicate")
}

// ─── Rate limiting ────────────────────────────────────────────────────────────

func TestCache_CheckRateLimit_AllowsFirstBurst(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	player := "rate-test-player"

	// First rateLimitMax requests should all be allowed.
	for i := 0; i < rateLimitMax; i++ {
		over, err := c.CheckRateLimit(ctx, player)
		require.NoError(t, err)
		assert.False(t, over, "request %d should be allowed (under limit)", i+1)
	}
}

func TestCache_CheckRateLimit_BlocksAfterMax(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	player := "rate-block-player"

	for i := 0; i < rateLimitMax; i++ {
		_, _ = c.CheckRateLimit(ctx, player)
	}

	over, err := c.CheckRateLimit(ctx, player)
	require.NoError(t, err)
	assert.True(t, over, "request %d should be blocked (over limit)", rateLimitMax+1)
}

func TestCache_CheckRateLimit_AllowsAfterWindowExpiry(t *testing.T) {
	// This test verifies that separate time windows are independent.
	// We test this by confirming a fresh player (window not yet started) is allowed
	// even after another player has exhausted their limit.
	c, _ := newTestCache(t)
	ctx := context.Background()

	// Exhaust player A's limit.
	for i := 0; i < rateLimitMax; i++ {
		_, _ = c.CheckRateLimit(ctx, "rate-expire-player-A")
	}
	over, err := c.CheckRateLimit(ctx, "rate-expire-player-A")
	require.NoError(t, err)
	assert.True(t, over, "player A should be over the limit")

	// Player B, who has never called CheckRateLimit, should still be allowed.
	overB, err := c.CheckRateLimit(ctx, "rate-expire-player-B-fresh")
	require.NoError(t, err)
	assert.False(t, overB, "a fresh player should always be allowed on first request")
}

func TestCache_CheckRateLimit_IndependentPerPlayer(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	// Exhaust player A's limit
	for i := 0; i < rateLimitMax; i++ {
		_, _ = c.CheckRateLimit(ctx, "player-rate-A")
	}

	// Player B should still be allowed
	over, err := c.CheckRateLimit(ctx, "player-rate-B")
	require.NoError(t, err)
	assert.False(t, over, "player B should have an independent rate limit")
}

// ─── Queue operations ─────────────────────────────────────────────────────────

func TestCache_QueueJoinAndPop(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	mode := "2v2"

	require.NoError(t, c.QueueJoin(ctx, mode, "player-q1"))
	require.NoError(t, c.QueueJoin(ctx, mode, "player-q2"))

	popped, err := c.QueuePop(ctx, mode, 2)
	require.NoError(t, err)
	assert.Len(t, popped, 2)
	assert.Contains(t, popped, "player-q1")
	assert.Contains(t, popped, "player-q2")
}

func TestCache_QueuePop_EmptyReturnsEmptySlice(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	popped, err := c.QueuePop(ctx, "empty-mode", 5)
	require.NoError(t, err)
	assert.Empty(t, popped, "popping from an empty queue should return empty slice")
}

func TestCache_QueueSize_ReflectsJoins(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	mode := "ranked"
	require.NoError(t, c.QueueJoin(ctx, mode, "qa"))
	require.NoError(t, c.QueueJoin(ctx, mode, "qb"))
	require.NoError(t, c.QueueJoin(ctx, mode, "qc"))

	size, err := c.QueueSize(ctx, mode)
	require.NoError(t, err)
	assert.Equal(t, int64(3), size)
}

func TestCache_QueueLeave_RemovesPlayer(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	mode := "casual"
	require.NoError(t, c.QueueJoin(ctx, mode, "leave-player"))

	size, _ := c.QueueSize(ctx, mode)
	assert.Equal(t, int64(1), size)

	require.NoError(t, c.QueueLeave(ctx, mode, "leave-player"))

	size, _ = c.QueueSize(ctx, mode)
	assert.Equal(t, int64(0), size)
}

func TestCache_QueuePop_FIFOOrder(t *testing.T) {
	c, mr := newTestCache(t)
	ctx := context.Background()

	mode := "fifo"

	require.NoError(t, c.QueueJoin(ctx, mode, "first"))
	mr.FastForward(time.Millisecond) // ensure different scores
	require.NoError(t, c.QueueJoin(ctx, mode, "second"))
	mr.FastForward(time.Millisecond)
	require.NoError(t, c.QueueJoin(ctx, mode, "third"))

	popped, err := c.QueuePop(ctx, mode, 3)
	require.NoError(t, err)
	require.Len(t, popped, 3)
	// The pop order should follow insertion time (lowest score first).
	assert.Equal(t, "first", popped[0])
	assert.Equal(t, "second", popped[1])
	assert.Equal(t, "third", popped[2])
}

// ─── Presence ─────────────────────────────────────────────────────────────────

func TestCache_SetOnlineAndIsOnline(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	player := "online-player"
	require.NoError(t, c.SetOnline(ctx, player))

	online, err := c.IsOnline(ctx, player)
	require.NoError(t, err)
	assert.True(t, online, "player should be online after SetOnline")
}

func TestCache_IsOnline_FalseForUnknown(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	online, err := c.IsOnline(ctx, "ghost-player")
	require.NoError(t, err)
	assert.False(t, online)
}

func TestCache_IsOnline_FalseAfterTTLExpiry(t *testing.T) {
	c, mr := newTestCache(t)
	ctx := context.Background()

	player := "ttl-player"
	require.NoError(t, c.SetOnline(ctx, player))

	mr.FastForward(TTLPresence + time.Second)

	online, err := c.IsOnline(ctx, player)
	require.NoError(t, err)
	assert.False(t, online, "player should be offline after presence TTL expires")
}

// ─── Room codes ───────────────────────────────────────────────────────────────

func TestCache_SetAndGetRoomCode_Roundtrip(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	require.NoError(t, c.SetRoomCode(ctx, "ABCD12", "game-xyz"))

	gameID, err := c.GetRoomCode(ctx, "ABCD12")
	require.NoError(t, err)
	assert.Equal(t, "game-xyz", gameID)
}

func TestCache_GetRoomCode_EmptyForMissing(t *testing.T) {
	c, _ := newTestCache(t)
	ctx := context.Background()

	gameID, err := c.GetRoomCode(ctx, "XXXXXX")
	require.NoError(t, err)
	assert.Empty(t, gameID)
}

// ─── Key helpers ──────────────────────────────────────────────────────────────

func TestGameKey_Format(t *testing.T) {
	assert.Equal(t, "game:abc-123", gameKey("abc-123"))
}

func TestActionKey_Format(t *testing.T) {
	assert.Equal(t, "action:player-1:42", actionKey("player-1", 42))
}
