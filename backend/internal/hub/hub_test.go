package hub

import (
	"encoding/json"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"
)

// ─── Helpers ──────────────────────────────────────────────────────────────────

// newTestHub creates a Hub backed by a no-op logger, suitable for unit tests.
func newTestHub(t *testing.T) *Hub {
	t.Helper()
	logger, err := zap.NewDevelopment()
	require.NoError(t, err)
	return NewHub(logger)
}

// newTestClient creates a minimal Client with no WebSocket connection.
// The Send channel is open so the hub can enqueue messages without blocking.
func newTestClient(id, gameID string, h *Hub) *Client {
	return &Client{
		ID:     id,
		GameID: gameID,
		Send:   make(chan []byte, 64),
		Hub:    h,
	}
}

// drainHub processes all pending channel operations in the Hub by running one
// iteration of the event loop.  It starts Run in a goroutine, sends the
// work, then closes the done channel to stop the loop.
func runHubOnce(h *Hub, work func()) {
	done := make(chan struct{})
	go h.Run(done)
	// Give the goroutine a moment to start.
	time.Sleep(5 * time.Millisecond)
	work()
	time.Sleep(20 * time.Millisecond)
	close(done)
	time.Sleep(10 * time.Millisecond)
}

// ─── Room Tests ───────────────────────────────────────────────────────────────

func TestRoom_AddAndRemove(t *testing.T) {
	r := NewRoom("game-1")

	c1 := &Client{ID: "p1", Send: make(chan []byte, 4)}
	c2 := &Client{ID: "p2", Send: make(chan []byte, 4)}

	r.Add(c1)
	r.Add(c2)
	assert.False(t, r.IsEmpty())

	r.Remove("p1")
	assert.False(t, r.IsEmpty())

	r.Remove("p2")
	assert.True(t, r.IsEmpty())
}

func TestRoom_IsEmpty_InitiallyEmpty(t *testing.T) {
	r := NewRoom("empty-room")
	assert.True(t, r.IsEmpty())
}

func TestRoom_Broadcast_DeliversToAllClients(t *testing.T) {
	r := NewRoom("room-1")

	send1 := make(chan []byte, 4)
	send2 := make(chan []byte, 4)
	c1 := &Client{ID: "c1", Send: send1}
	c2 := &Client{ID: "c2", Send: send2}

	r.Add(c1)
	r.Add(c2)

	msg := []byte(`{"type":"test"}`)
	r.Broadcast(msg)

	assert.Len(t, send1, 1)
	assert.Len(t, send2, 1)
	assert.Equal(t, msg, <-send1)
	assert.Equal(t, msg, <-send2)
}

func TestRoom_BroadcastExcept_SkipsExcluded(t *testing.T) {
	r := NewRoom("room-2")

	send1 := make(chan []byte, 4)
	send2 := make(chan []byte, 4)
	c1 := &Client{ID: "c1", Send: send1}
	c2 := &Client{ID: "c2", Send: send2}

	r.Add(c1)
	r.Add(c2)

	msg := []byte(`{"type":"test"}`)
	r.BroadcastExcept(msg, "c1")

	assert.Len(t, send1, 0, "excluded client should not receive the message")
	assert.Len(t, send2, 1, "other client should receive the message")
}

func TestRoom_Broadcast_FullChannelDrops(t *testing.T) {
	r := NewRoom("room-3")

	// Create a client with a full (size=0) send channel to test the default drop.
	c := &Client{ID: "c-full", Send: make(chan []byte, 0)}
	r.Add(c)

	// Should not block even though channel is full (uses select/default).
	msg := []byte(`{"type":"overflow"}`)
	done := make(chan struct{})
	go func() {
		r.Broadcast(msg)
		close(done)
	}()

	select {
	case <-done:
		// success: broadcast completed without blocking
	case <-time.After(500 * time.Millisecond):
		t.Fatal("Broadcast blocked on a full channel")
	}
}

// ─── Hub Registration Tests ───────────────────────────────────────────────────

func TestHub_Register_AddsClientToRoom(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)

	time.Sleep(5 * time.Millisecond) // let goroutine start

	c := newTestClient("player-1", "game-A", h)
	h.Register(c)
	time.Sleep(30 * time.Millisecond)

	h.mu.RLock()
	room := h.rooms["game-A"]
	_, clientExists := h.clients["player-1"]
	h.mu.RUnlock()

	require.NotNil(t, room)
	assert.True(t, clientExists)

	room.mu.RLock()
	_, inRoom := room.Clients["player-1"]
	room.mu.RUnlock()
	assert.True(t, inRoom)
}

func TestHub_Unregister_RemovesClientAndRoom(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	c := newTestClient("player-2", "game-B", h)
	h.Register(c)
	time.Sleep(30 * time.Millisecond)

	// Manually trigger unregister (mimics ReadPump defer)
	h.unregister <- c
	time.Sleep(30 * time.Millisecond)

	h.mu.RLock()
	_, exists := h.clients["player-2"]
	room := h.rooms["game-B"]
	h.mu.RUnlock()

	assert.False(t, exists, "client should be removed from hub")
	assert.Nil(t, room, "empty room should be removed from hub")
}

func TestHub_Unregister_TracksDisconnected(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	c := newTestClient("player-3", "game-C", h)
	h.Register(c)
	time.Sleep(30 * time.Millisecond)

	h.unregister <- c
	time.Sleep(30 * time.Millisecond)

	h.mu.RLock()
	entry, tracked := h.disconnected["player-3"]
	h.mu.RUnlock()

	assert.True(t, tracked, "disconnected player should be tracked for reconnect")
	if tracked {
		assert.Equal(t, "game-C", entry.gameID)
	}
}

func TestHub_Reconnect_ResumesSession(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	// First registration
	c := newTestClient("player-4", "game-D", h)
	h.Register(c)
	time.Sleep(30 * time.Millisecond)

	// Disconnect
	h.unregister <- c
	time.Sleep(30 * time.Millisecond)

	// Reconnect with same ID and game
	c2 := newTestClient("player-4", "game-D", h)
	h.Register(c2)
	time.Sleep(30 * time.Millisecond)

	h.mu.RLock()
	_, exists := h.clients["player-4"]
	_, inDisconnected := h.disconnected["player-4"]
	h.mu.RUnlock()

	assert.True(t, exists, "reconnected client should be in hub")
	assert.False(t, inDisconnected, "reconnected client should be removed from disconnected map")
}

// ─── Hub Broadcast Tests ──────────────────────────────────────────────────────

func TestHub_Broadcast_RoutesToRoom(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	c1 := newTestClient("p1", "room-X", h)
	c2 := newTestClient("p2", "room-X", h)
	c3 := newTestClient("p3", "room-Y", h) // different room

	h.Register(c1)
	h.Register(c2)
	h.Register(c3)
	time.Sleep(30 * time.Millisecond)

	payload := []byte(`{"type":"hello"}`)
	h.Broadcast("room-X", payload, "")
	time.Sleep(30 * time.Millisecond)

	assert.Len(t, c1.Send, 1, "c1 in room-X should receive the broadcast")
	assert.Len(t, c2.Send, 1, "c2 in room-X should receive the broadcast")
	assert.Len(t, c3.Send, 0, "c3 in room-Y should NOT receive room-X broadcast")
}

func TestHub_BroadcastMsg_MarshalsAndRoutes(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	c := newTestClient("px", "room-Z", h)
	h.Register(c)
	time.Sleep(30 * time.Millisecond)

	payload := GameOverPayload{WinnerID: "px"}
	err := h.BroadcastMsg("room-Z", MsgGameOver, payload, "")
	require.NoError(t, err)
	time.Sleep(30 * time.Millisecond)

	require.Len(t, c.Send, 1)
	raw := <-c.Send
	var msg Message
	require.NoError(t, json.Unmarshal(raw, &msg))
	assert.Equal(t, MsgGameOver, msg.Type)
}

func TestHub_BroadcastExclude_SkipsSender(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	c1 := newTestClient("sender", "room-E", h)
	c2 := newTestClient("receiver", "room-E", h)

	h.Register(c1)
	h.Register(c2)
	time.Sleep(30 * time.Millisecond)

	h.Broadcast("room-E", []byte(`{"type":"move"}`), "sender")
	time.Sleep(30 * time.Millisecond)

	assert.Len(t, c1.Send, 0, "sender should be excluded")
	assert.Len(t, c2.Send, 1, "receiver should get the broadcast")
}

// ─── Hub Action Handler Tests ─────────────────────────────────────────────────

func TestHub_SetActionHandler_InvokedOnAction(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	received := make(chan *ClientAction, 1)
	h.SetActionHandler(func(act *ClientAction) {
		received <- act
	})

	c := newTestClient("actor", "room-F", h)
	h.Register(c)
	time.Sleep(30 * time.Millisecond)

	msg := &Message{Type: MsgPlayCard}
	h.action <- &ClientAction{Client: c, Msg: msg}

	select {
	case act := <-received:
		assert.Equal(t, MsgPlayCard, act.Msg.Type)
	case <-time.After(200 * time.Millisecond):
		t.Fatal("action handler was not called")
	}
}

// ─── Hub Room Lookup Tests ─────────────────────────────────────────────────────

func TestHub_Room_ReturnsNilForMissingRoom(t *testing.T) {
	h := newTestHub(t)
	assert.Nil(t, h.Room("nonexistent"))
}

// ─── Hub Concurrent Access Tests (run with -race) ─────────────────────────────

func TestHub_ConcurrentRegisterUnregister(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	const goroutines = 20
	var wg sync.WaitGroup

	for i := 0; i < goroutines; i++ {
		wg.Add(1)
		go func(n int) {
			defer wg.Done()
			id := fmt.Sprintf("concurrent-player-%d", n)
			c := newTestClient(id, "concurrent-room", h)
			h.Register(c)
			time.Sleep(5 * time.Millisecond)
			h.unregister <- c
		}(i)
	}

	wg.Wait()
	time.Sleep(100 * time.Millisecond)
	// No data races should be detected; room may or may not exist at this point.
}

func TestHub_ConcurrentBroadcast(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	for i := 0; i < 5; i++ {
		c := newTestClient(fmt.Sprintf("bc-client-%d", i), "bcast-room", h)
		h.Register(c)
	}
	time.Sleep(30 * time.Millisecond)

	const broadcasts = 50
	var wg sync.WaitGroup
	for i := 0; i < broadcasts; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			h.Broadcast("bcast-room", []byte(`{"type":"tick"}`), "")
		}()
	}
	wg.Wait()
	time.Sleep(100 * time.Millisecond)
	// No data races; we don't assert on message counts because channels may be full.
}

func TestHub_ConcurrentRoomBroadcastAndUnregister(t *testing.T) {
	h := newTestHub(t)
	done := make(chan struct{})
	go h.Run(done)
	defer close(done)
	time.Sleep(5 * time.Millisecond)

	clients := make([]*Client, 10)
	for i := range clients {
		clients[i] = newTestClient(fmt.Sprintf("mixed-client-%d", i), "mixed-room", h)
		h.Register(clients[i])
	}
	time.Sleep(30 * time.Millisecond)

	var wg sync.WaitGroup
	// Half goroutines broadcast, half unregister
	for i := 0; i < 5; i++ {
		wg.Add(2)
		go func() {
			defer wg.Done()
			h.Broadcast("mixed-room", []byte(`{"type":"x"}`), "")
		}()
		go func(n int) {
			defer wg.Done()
			h.unregister <- clients[n]
		}(i)
	}
	wg.Wait()
	time.Sleep(50 * time.Millisecond)
}

// ─── Message Tests ────────────────────────────────────────────────────────────

func TestMessage_NewMessage_Encode_Roundtrip(t *testing.T) {
	payload := ErrorPayload{Code: "test", Message: "a test error"}
	msg, err := NewMessage(MsgError, payload)
	require.NoError(t, err)
	assert.Equal(t, MsgError, msg.Type)

	data, err := msg.Encode()
	require.NoError(t, err)

	var decoded Message
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, MsgError, decoded.Type)

	var decodedPayload ErrorPayload
	require.NoError(t, json.Unmarshal(decoded.Payload, &decodedPayload))
	assert.Equal(t, "test", decodedPayload.Code)
	assert.Equal(t, "a test error", decodedPayload.Message)
}

func TestMessage_SeqNum_Preserved(t *testing.T) {
	msg := &Message{Type: MsgPlayCard, SeqNum: 42}
	data, err := msg.Encode()
	require.NoError(t, err)

	var decoded Message
	require.NoError(t, json.Unmarshal(data, &decoded))
	assert.Equal(t, uint64(42), decoded.SeqNum)
}

// ─── SendToClient Tests ───────────────────────────────────────────────────────

func TestHub_SendToClient_NoopForUnknownClient(t *testing.T) {
	h := newTestHub(t)
	// Should return nil for unknown client, not panic.
	err := h.SendToClient("unknown-id", MsgError, ErrorPayload{})
	assert.NoError(t, err)
}
