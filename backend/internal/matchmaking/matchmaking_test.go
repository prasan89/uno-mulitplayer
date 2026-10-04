package matchmaking

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

// ─── Helpers ──────────────────────────────────────────────────────────────────

func nopLogger() *zap.Logger {
	return zap.NewNop()
}

// noopCreator is a GameCreator that always succeeds without touching a DB.
type noopCreator struct {
	mu      sync.Mutex
	created []string // game IDs created
}

func (c *noopCreator) CreateGame(_ context.Context, gameID string, _ []string, _ GameMode) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.created = append(c.created, gameID)
	return nil
}

func (c *noopCreator) gamesCreated() int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return len(c.created)
}

// capturingNotifier records every notification.
type capturingNotifier struct {
	mu   sync.Mutex
	msgs []notifiedMsg
}

type notifiedMsg struct {
	playerID string
	msg      interface{}
}

func (n *capturingNotifier) NotifyPlayer(playerID string, msg interface{}) error {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.msgs = append(n.msgs, notifiedMsg{playerID, msg})
	return nil
}

func (n *capturingNotifier) count() int {
	n.mu.Lock()
	defer n.mu.Unlock()
	return len(n.msgs)
}

func newTestService(t *testing.T) (*Service, *noopCreator, *capturingNotifier) {
	t.Helper()
	c := &noopCreator{}
	n := &capturingNotifier{}
	svc := NewService(c, n, nopLogger(), nil)
	return svc, c, n
}

// ─── Queue tests ──────────────────────────────────────────────────────────────

func TestQueue_AddAndSize(t *testing.T) {
	q := NewQueue()
	assert.Equal(t, 0, q.Size())

	_, err := q.Add(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual})
	require.NoError(t, err)
	assert.Equal(t, 1, q.Size())
}

func TestQueue_DuplicateAdd(t *testing.T) {
	q := NewQueue()
	_, err := q.Add(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual})
	require.NoError(t, err)

	_, err = q.Add(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual})
	require.Error(t, err, "duplicate player should be rejected")
	assert.Contains(t, err.Error(), "already in queue")
}

func TestQueue_Remove(t *testing.T) {
	q := NewQueue()
	_, err := q.Add(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual})
	require.NoError(t, err)

	removed := q.Remove("p1")
	assert.True(t, removed, "should remove existing player")
	assert.Equal(t, 0, q.Size())

	removed = q.Remove("p1")
	assert.False(t, removed, "removing absent player should return false")
}

func TestQueue_RemoveNotFound(t *testing.T) {
	q := NewQueue()
	removed := q.Remove("nobody")
	assert.False(t, removed)
}

func TestQueue_PrivateRoom(t *testing.T) {
	q := NewQueue()
	code := GenerateRoomCode()

	_, err := q.Add(&QueueEntry{PlayerID: "host", ELO: 1000, GameMode: GameModePrivate, RoomCode: code})
	require.NoError(t, err)

	_, err = q.Add(&QueueEntry{PlayerID: "guest", ELO: 1000, GameMode: GameModePrivate, RoomCode: code})
	require.NoError(t, err)

	assert.Equal(t, 2, q.Size())

	entries := q.PrivateRoomEntries(code)
	assert.Len(t, entries, 2)
	assert.Equal(t, 0, q.Size(), "entries should be drained after retrieval")
}

func TestQueue_PrivateRoom_MissingCode(t *testing.T) {
	q := NewQueue()
	_, err := q.Add(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModePrivate})
	require.Error(t, err, "private entry without room code should be rejected")
}

func TestQueue_Snapshot(t *testing.T) {
	q := NewQueue()
	for i := 0; i < 3; i++ {
		_, err := q.Add(&QueueEntry{
			PlayerID: fmt.Sprintf("p%d", i),
			ELO:      1000,
			GameMode: GameModeCasual,
		})
		require.NoError(t, err)
	}

	snap := q.Snapshot()
	assert.Len(t, snap, 3, "snapshot should reflect current queue size")
}

func TestQueue_DrainMatched(t *testing.T) {
	q := NewQueue()
	_, err1 := q.Add(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual})
	_, err2 := q.Add(&QueueEntry{PlayerID: "p2", ELO: 1000, GameMode: GameModeCasual})
	_, err3 := q.Add(&QueueEntry{PlayerID: "p3", ELO: 1000, GameMode: GameModeCasual})
	require.NoError(t, err1)
	require.NoError(t, err2)
	require.NoError(t, err3)

	q.DrainMatched([]string{"p1", "p3"})
	assert.Equal(t, 1, q.Size(), "only p2 should remain after draining p1 and p3")
	snap := q.Snapshot()
	require.Len(t, snap, 1)
	assert.Equal(t, "p2", snap[0].PlayerID)
}

// ─── ELO matching tests ───────────────────────────────────────────────────────

func TestFindCandidates_WithinRange(t *testing.T) {
	anchor := &QueueEntry{PlayerID: "a", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now()}
	entries := []*QueueEntry{
		{PlayerID: "b", ELO: 1050, GameMode: GameModeCasual, JoinedAt: time.Now()},
		{PlayerID: "c", ELO: 1500, GameMode: GameModeCasual, JoinedAt: time.Now()},
	}
	candidates := findCandidates(anchor, entries)
	// b is within 200 ELO; c is 500 away — out of range.
	assert.Len(t, candidates, 1)
	assert.Equal(t, "b", candidates[0].PlayerID)
}

func TestFindCandidates_ExcludesAnchor(t *testing.T) {
	anchor := &QueueEntry{PlayerID: "a", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now()}
	candidates := findCandidates(anchor, []*QueueEntry{anchor})
	assert.Empty(t, candidates, "anchor should never be returned as its own candidate")
}

func TestFindCandidates_ExpandedAfterWait(t *testing.T) {
	anchor := &QueueEntry{
		PlayerID: "a",
		ELO:      1000,
		GameMode: GameModeCasual,
		JoinedAt: time.Now().Add(-40 * time.Second), // waited > 30 s → expanded range
	}
	// 350 ELO gap — within expanded (400) but outside initial (200).
	entries := []*QueueEntry{
		{PlayerID: "b", ELO: 1350, GameMode: GameModeCasual, JoinedAt: time.Now()},
	}
	candidates := findCandidates(anchor, entries)
	assert.Len(t, candidates, 1, "should find candidate within expanded ELO range")
}

// ─── Service.JoinQueue / LeaveQueue ──────────────────────────────────────────

func TestService_JoinQueue(t *testing.T) {
	svc, _, _ := newTestService(t)

	ch, err := svc.JoinQueue(&QueueEntry{
		PlayerID: "player1",
		ELO:      1000,
		GameMode: GameModeCasual,
		JoinedAt: time.Now(),
	})
	require.NoError(t, err)
	assert.NotNil(t, ch)
	assert.Equal(t, 1, svc.queue.Size())
}

func TestService_DuplicateJoin(t *testing.T) {
	svc, _, _ := newTestService(t)

	entry := &QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now()}
	_, err := svc.JoinQueue(entry)
	require.NoError(t, err)

	_, err = svc.JoinQueue(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now()})
	require.Error(t, err)
}

func TestService_LeaveQueue_NotQueued(t *testing.T) {
	svc, _, _ := newTestService(t)
	removed := svc.LeaveQueue("ghost")
	assert.False(t, removed, "removing a non-queued player should return false")
}

func TestService_LeaveQueue_Removes(t *testing.T) {
	svc, _, _ := newTestService(t)
	_, err := svc.JoinQueue(&QueueEntry{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now()})
	require.NoError(t, err)

	removed := svc.LeaveQueue("p1")
	assert.True(t, removed)
	assert.Equal(t, 0, svc.queue.Size())
}

// ─── formMatch / processQueue ─────────────────────────────────────────────────

func TestService_FormMatch_NotifiesPlayers(t *testing.T) {
	svc, creator, notifier := newTestService(t)

	group := []*QueueEntry{
		{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now(), notifyCh: make(chan MatchResult, 1)},
		{PlayerID: "p2", ELO: 1010, GameMode: GameModeCasual, JoinedAt: time.Now(), notifyCh: make(chan MatchResult, 1)},
	}

	result, err := svc.formMatch(context.Background(), group, "")
	require.NoError(t, err)
	assert.NotEmpty(t, result.GameID)
	assert.NotEmpty(t, result.RoomCode)
	assert.Equal(t, 1, creator.gamesCreated())
	assert.Equal(t, 2, notifier.count(), "both players should be notified")
}

func TestService_FormMatch_BotEntriesNotNotified(t *testing.T) {
	svc, _, notifier := newTestService(t)

	group := []*QueueEntry{
		{PlayerID: "p1", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now(), notifyCh: make(chan MatchResult, 1)},
		{PlayerID: "bot:abc123", ELO: 1000, GameMode: GameModeCasual, JoinedAt: time.Now()},
	}

	_, err := svc.formMatch(context.Background(), group, "ROOM01")
	require.NoError(t, err)
	assert.Equal(t, 1, notifier.count(), "bot entries should not be notified")
}

// ─── Concurrency: simultaneous joins ─────────────────────────────────────────

func TestQueue_ConcurrentAdds(t *testing.T) {
	q := NewQueue()
	n := 50
	var wg sync.WaitGroup

	for i := 0; i < n; i++ {
		wg.Add(1)
		go func(idx int) {
			defer wg.Done()
			_, _ = q.Add(&QueueEntry{
				PlayerID: fmt.Sprintf("player-%d", idx),
				ELO:      1000,
				GameMode: GameModeCasual,
				JoinedAt: time.Now(),
			})
		}(i)
	}

	wg.Wait()
	assert.Equal(t, n, q.Size(), "all concurrent adds should succeed without data race")
}

// ─── Private match ─────────────────────────────────────────────────────────

func TestService_CreatePrivateMatch_ReturnsCode(t *testing.T) {
	svc, _, _ := newTestService(t)
	code := svc.CreatePrivateMatch()
	assert.Len(t, code, roomCodeLength, "room code should be %d characters", roomCodeLength)
}

func TestService_JoinPrivateMatch(t *testing.T) {
	svc, _, _ := newTestService(t)
	code := svc.CreatePrivateMatch()

	ch, err := svc.JoinPrivateMatch("host", 1000, code)
	require.NoError(t, err)
	assert.NotNil(t, ch)

	ch2, err := svc.JoinPrivateMatch("guest", 1000, code)
	require.NoError(t, err)
	assert.NotNil(t, ch2)

	assert.Equal(t, 2, svc.queue.Size())
}

func TestService_StartPrivateMatch_NoPlayers(t *testing.T) {
	svc, _, _ := newTestService(t)
	_, err := svc.StartPrivateMatch(context.Background(), "NOROOM")
	require.Error(t, err, "starting a nonexistent room should fail")
}

func TestService_StartPrivateMatch_Succeeds(t *testing.T) {
	svc, creator, _ := newTestService(t)

	code := svc.CreatePrivateMatch()
	_, err := svc.JoinPrivateMatch("host", 1000, code)
	require.NoError(t, err)
	_, err = svc.JoinPrivateMatch("guest", 1000, code)
	require.NoError(t, err)

	result, err := svc.StartPrivateMatch(context.Background(), code)
	require.NoError(t, err)
	assert.NotEmpty(t, result.GameID)
	assert.Equal(t, code, result.RoomCode)
	assert.Equal(t, 1, creator.gamesCreated())
}

// ─── GenerateRoomCode ─────────────────────────────────────────────────────────

func TestGenerateRoomCode_Length(t *testing.T) {
	for i := 0; i < 20; i++ {
		code := GenerateRoomCode()
		assert.Len(t, code, roomCodeLength, "room code length must be %d", roomCodeLength)
	}
}

func TestGenerateRoomCode_Charset(t *testing.T) {
	for i := 0; i < 50; i++ {
		code := GenerateRoomCode()
		for _, c := range code {
			assert.Contains(t, roomCodeChars, string(c),
				"code %q contains invalid char %q", code, string(c))
		}
	}
}

func TestGenerateRoomCode_NotAlwaysSame(t *testing.T) {
	codes := make(map[string]bool)
	for i := 0; i < 20; i++ {
		codes[GenerateRoomCode()] = true
	}
	// Very unlikely to generate the same code 20 times in a row.
	assert.Greater(t, len(codes), 1, "room codes should not always be identical")
}

// ─── isBotEntry ──────────────────────────────────────────────────────────────

func TestIsBotEntry(t *testing.T) {
	bot := &QueueEntry{PlayerID: "bot:abc123"}
	human := &QueueEntry{PlayerID: "firebase_uid_xyz"}

	assert.True(t, isBotEntry(bot))
	assert.False(t, isBotEntry(human))
}
