package hub

import (
	"context"
	"encoding/json"
	"sync"
	"time"

	"go.uber.org/zap"
)

// ActionDeduper is the interface the Hub uses to detect duplicate client
// actions across instances (backed by Redis in production).
// CheckAndSetActionDedup returns (true, nil) when the (playerID, seq) pair has
// already been seen, indicating a duplicate that should be dropped.
type ActionDeduper interface {
	CheckAndSetActionDedup(ctx context.Context, playerID string, seq int) (bool, error)
}

// Room represents a single game room.
type Room struct {
	// ID is the unique game/room identifier.
	ID string

	// Clients holds all currently connected clients keyed by Firebase UID.
	Clients map[string]*Client

	mu sync.RWMutex
}

// NewRoom creates a new Room with the given ID.
func NewRoom(id string) *Room {
	return &Room{
		ID:      id,
		Clients: make(map[string]*Client),
	}
}

// Add adds a client to the room.
func (r *Room) Add(c *Client) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.Clients[c.ID] = c
}

// Remove removes a client from the room by client ID.
func (r *Room) Remove(clientID string) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.Clients, clientID)
}

// IsEmpty returns true when no clients are in the room.
func (r *Room) IsEmpty() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.Clients) == 0
}

// Mu exposes the room's RWMutex so callers in the same package or via the
// returned pointer can safely iterate Clients.
func (r *Room) Mu() *sync.RWMutex {
	return &r.mu
}

// Broadcast sends data to every client currently in the room.
func (r *Room) Broadcast(data []byte) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, c := range r.Clients {
		select {
		case c.Send <- data:
		default:
		}
	}
}

// BroadcastExcept broadcasts data to every client except the excluded one.
func (r *Room) BroadcastExcept(data []byte, excludeID string) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for id, c := range r.Clients {
		if id == excludeID {
			continue
		}
		select {
		case c.Send <- data:
		default:
		}
	}
}

// ---- disconnected player tracking ----

// disconnectedEntry tracks a recently-disconnected player for reconnect grace
// period handling.
type disconnectedEntry struct {
	clientID string
	gameID   string
	seqNum   uint64
	at       time.Time
}

// Hub maintains the set of active clients and rooms, and coordinates message
// broadcasts.
type Hub struct {
	// rooms holds all active game rooms.
	rooms map[string]*Room

	// clients holds all connected clients.
	clients map[string]*Client

	// disconnected holds recently-disconnected clients pending reconnect.
	disconnected map[string]*disconnectedEntry

	mu sync.RWMutex

	// register is a channel for new client registrations.
	register chan *Client

	// unregister is a channel for client disconnections.
	unregister chan *Client

	// broadcast delivers a message to all clients in a room.
	broadcast chan *RoomBroadcast

	// action routes a validated client action for game processing.
	action chan *ClientAction

	logger *zap.Logger

	// deduper is used to detect duplicate actions across server instances.
	// When non-nil, handleAction calls CheckAndSetActionDedup before forwarding
	// actions to onAction; duplicate seq numbers are rejected with an error.
	deduper ActionDeduper

	// onAction is an optional hook called with each validated game action.
	// Set by the server layer to plug in game logic.
	onAction func(action *ClientAction)

	// onBotTakeover is called when a disconnected player's reconnect grace period
	// expires.  The callback receives the game ID and the disconnected player's
	// ID so the caller can hand the slot to a bot.  If nil, no takeover occurs.
	onBotTakeover func(gameID, playerID string)

	// onReconnect is called after a client successfully reconnects, before the
	// MsgReconnected envelope is sent.  The callback must fetch the current
	// game state for the player and deliver it via Hub.SendToClient.  It also
	// returns the serialised public game state to embed in ReconnectedPayload so
	// the client receives state in a single round-trip.  If nil, the State field
	// in ReconnectedPayload is left as JSON null (legacy behaviour).
	onReconnect func(clientID, gameID string) json.RawMessage
}

// RoomBroadcast carries a payload to be delivered to all members of a room.
type RoomBroadcast struct {
	RoomID  string
	Data    []byte
	Exclude string // optional client ID to skip
}

// NewHub creates and returns a new Hub.
func NewHub(logger *zap.Logger) *Hub {
	return &Hub{
		rooms:        make(map[string]*Room),
		clients:      make(map[string]*Client),
		disconnected: make(map[string]*disconnectedEntry),
		register:     make(chan *Client, 64),
		unregister:   make(chan *Client, 64),
		broadcast:    make(chan *RoomBroadcast, 256),
		action:       make(chan *ClientAction, 256),
		logger:       logger,
	}
}

// SetActionHandler sets the callback invoked for each inbound game action.
func (h *Hub) SetActionHandler(fn func(action *ClientAction)) {
	h.onAction = fn
}

// SetActionDeduper wires the Redis-backed deduplication helper into the hub.
// Once set, handleAction will call CheckAndSetActionDedup for every message
// that carries a non-zero SeqNum, rejecting duplicates before they reach the
// game-logic callback.
func (h *Hub) SetActionDeduper(d ActionDeduper) {
	h.deduper = d
}

// SetBotTakeoverHandler registers a callback that is invoked when a
// disconnected player's reconnect grace period expires.  The callback receives
// the game ID and the player ID so the caller can initiate a bot takeover.
func (h *Hub) SetBotTakeoverHandler(fn func(gameID, playerID string)) {
	h.onBotTakeover = fn
}

// SetReconnectHandler registers a callback invoked immediately after a client
// reconnects (within the grace period).  The callback receives the reconnecting
// client ID and game ID; it should fetch the current public game state for that
// player and return it as a JSON-encoded json.RawMessage to embed in the
// MsgReconnected envelope.  It may additionally push a standalone MsgGameState
// message via Hub.SendToClient.  A nil return is safe and leaves the State
// field as JSON null.
func (h *Hub) SetReconnectHandler(fn func(clientID, gameID string) json.RawMessage) {
	h.onReconnect = fn
}

// Run starts the Hub event loop. It blocks until the provided done channel is
// closed.
func (h *Hub) Run(done <-chan struct{}) {
	staleTicker := time.NewTicker(10 * time.Second)
	defer staleTicker.Stop()

	for {
		select {
		case client := <-h.register:
			h.handleRegister(client)

		case client := <-h.unregister:
			h.handleUnregister(client)

		case rb := <-h.broadcast:
			h.handleBroadcast(rb)

		case act := <-h.action:
			h.handleAction(act)

		case <-staleTicker.C:
			h.cleanupStale()

		case <-done:
			h.logger.Info("hub shutting down")
			h.closeAll()
			return
		}
	}
}

// Register enqueues a client for registration.
func (h *Hub) Register(c *Client) {
	h.register <- c
}

// Broadcast enqueues a broadcast to a room.
func (h *Hub) Broadcast(roomID string, data []byte, excludeID string) {
	h.broadcast <- &RoomBroadcast{RoomID: roomID, Data: data, Exclude: excludeID}
}

// BroadcastMsg marshals a typed message and broadcasts to a room.
func (h *Hub) BroadcastMsg(roomID string, msgType MessageType, payload interface{}, excludeID string) error {
	msg, err := NewMessage(msgType, payload)
	if err != nil {
		return err
	}
	data, err := msg.Encode()
	if err != nil {
		return err
	}
	h.Broadcast(roomID, data, excludeID)
	return nil
}

// SendToClient delivers a typed message directly to a single client.
func (h *Hub) SendToClient(clientID string, msgType MessageType, payload interface{}) error {
	h.mu.RLock()
	c, ok := h.clients[clientID]
	h.mu.RUnlock()
	if !ok {
		return nil
	}
	return c.SendJSON(msgType, payload)
}

// Room returns the room with the given ID, or nil.
func (h *Hub) Room(id string) *Room {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return h.rooms[id]
}

// handleRegister processes a new client registration.
func (h *Hub) handleRegister(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	// Check for a reconnect within the grace period.
	if entry, ok := h.disconnected[c.ID]; ok && entry.gameID == c.GameID {
		delete(h.disconnected, c.ID)
		c.lastSeq = entry.seqNum
		h.clients[c.ID] = c

		room := h.rooms[c.GameID]
		if room == nil {
			room = NewRoom(c.GameID)
			h.rooms[c.GameID] = room
		}
		room.Add(c)

		h.logger.Info("client reconnected",
			zap.String("client", c.ID),
			zap.String("game", c.GameID),
		)

		// Fetch the current public game state for this player so it can be
		// embedded directly in the MsgReconnected envelope.  The lock is held
		// here, so the callback must not call back into the hub synchronously.
		stateJSON := json.RawMessage("null")
		if h.onReconnect != nil {
			if s := h.onReconnect(c.ID, c.GameID); s != nil {
				stateJSON = s
			}
		}

		// Send MsgReconnected with the populated state so the client can restore
		// its UI in a single round-trip without waiting for a second message.
		reconnectMsg, err := NewMessage(MsgReconnected, ReconnectedPayload{
			GameID: c.GameID,
			State:  stateJSON,
		})
		if err == nil {
			if data, err := reconnectMsg.Encode(); err == nil {
				select {
				case c.Send <- data:
				default:
				}
			}
		}
		return
	}

	h.clients[c.ID] = c

	room := h.rooms[c.GameID]
	if room == nil {
		room = NewRoom(c.GameID)
		h.rooms[c.GameID] = room
	}
	room.Add(c)

	h.logger.Info("client registered",
		zap.String("client", c.ID),
		zap.String("game", c.GameID),
	)
}

// handleUnregister handles client disconnection.
func (h *Hub) handleUnregister(c *Client) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if _, ok := h.clients[c.ID]; !ok {
		return
	}

	delete(h.clients, c.ID)

	if room, ok := h.rooms[c.GameID]; ok {
		room.Remove(c.ID)
		if room.IsEmpty() {
			delete(h.rooms, c.GameID)
		}
	}

	// Track for reconnect grace period.
	h.disconnected[c.ID] = &disconnectedEntry{
		clientID: c.ID,
		gameID:   c.GameID,
		seqNum:   c.lastSeq,
		at:       time.Now(),
	}

	close(c.Send)

	h.logger.Info("client unregistered",
		zap.String("client", c.ID),
		zap.String("game", c.GameID),
	)
}

// handleBroadcast delivers a RoomBroadcast.
func (h *Hub) handleBroadcast(rb *RoomBroadcast) {
	h.mu.RLock()
	room := h.rooms[rb.RoomID]
	h.mu.RUnlock()

	if room == nil {
		return
	}

	if rb.Exclude != "" {
		room.BroadcastExcept(rb.Data, rb.Exclude)
	} else {
		room.Broadcast(rb.Data)
	}
}

// handleAction routes a client action to the registered handler.
// When a deduper is configured and the message carries a non-zero SeqNum,
// the action is checked against Redis before being forwarded; duplicate
// sequence numbers are rejected with a "duplicate_seq" error response so
// that card plays / draws cannot be applied twice on network retries.
func (h *Hub) handleAction(act *ClientAction) {
	if h.deduper != nil && act.Msg.SeqNum != 0 {
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		isDup, err := h.deduper.CheckAndSetActionDedup(ctx, act.Client.ID, int(act.Msg.SeqNum))
		if err != nil {
			h.logger.Error("action dedup check failed",
				zap.String("client", act.Client.ID),
				zap.Uint64("seq", act.Msg.SeqNum),
				zap.Error(err),
			)
			// On Redis error, fall through and process the action rather than
			// silently dropping it — availability is preferred over strict dedup
			// when the dedup store is unavailable.
		} else if isDup {
			h.logger.Debug("duplicate action rejected",
				zap.String("client", act.Client.ID),
				zap.Uint64("seq", act.Msg.SeqNum),
			)
			act.Client.sendError("duplicate_seq", "duplicate sequence number")
			return
		}
	}

	if h.onAction != nil {
		h.onAction(act)
	}
}

// cleanupStale removes disconnected entries whose grace period has expired and
// triggers bot takeover notifications.
func (h *Hub) cleanupStale() {
	now := time.Now()
	h.mu.Lock()
	expired := make([]*disconnectedEntry, 0)
	for id, entry := range h.disconnected {
		if now.Sub(entry.at) > ReconnectGrace {
			expired = append(expired, entry)
			delete(h.disconnected, id)
		}
	}
	h.mu.Unlock()

	for _, entry := range expired {
		h.logger.Info("reconnect grace expired, triggering bot takeover",
			zap.String("client", entry.clientID),
			zap.String("game", entry.gameID),
		)
		// Notify remaining room members that the player has left.
		_ = h.BroadcastMsg(entry.gameID, MsgPlayerLeft,
			PlayerLeftPayload{PlayerID: entry.clientID}, "")
		// Hand the vacated slot to a bot so the game is not permanently stuck.
		if h.onBotTakeover != nil {
			h.onBotTakeover(entry.gameID, entry.clientID)
		}
	}
}

// closeAll closes every registered client's send channel.
func (h *Hub) closeAll() {
	h.mu.Lock()
	defer h.mu.Unlock()
	for _, c := range h.clients {
		close(c.Send)
	}
	h.clients = make(map[string]*Client)
	h.rooms = make(map[string]*Room)
}
