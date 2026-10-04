package hub

import (
	"encoding/json"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

const (
	// ReadLimit is the maximum message size allowed from the peer.
	ReadLimit = 4096

	// WriteDeadline is the time allowed to write a message to the peer.
	WriteDeadline = 10 * time.Second

	// PingInterval is the period between pings.
	PingInterval = 30 * time.Second

	// PongTimeout is the deadline to read the next pong message.
	PongTimeout = 60 * time.Second

	// ReconnectGrace is the time a disconnected player has to reconnect before
	// a bot takes over or they are considered left.
	ReconnectGrace = 60 * time.Second
)

// Client represents a connected WebSocket player.
type Client struct {
	// ID is the Firebase UID of the player.
	ID string

	// GameID is the room/game the client is currently in.
	GameID string

	// Conn is the underlying WebSocket connection.
	Conn *websocket.Conn

	// Send is the buffered channel of outbound messages.
	Send chan []byte

	// Hub is the central hub managing this client.
	Hub *Hub

	// LastPing tracks when the last ping was received for staleness detection.
	LastPing time.Time

	// lastSeq tracks the last processed sequence number to detect duplicates.
	lastSeq uint64

	// mu protects lastSeq and LastPing.
	mu sync.Mutex

	logger *zap.Logger
}

// NewClient creates a new Client.
func NewClient(id, gameID string, conn *websocket.Conn, hub *Hub, logger *zap.Logger) *Client {
	return &Client{
		ID:       id,
		GameID:   gameID,
		Conn:     conn,
		Send:     make(chan []byte, 256),
		Hub:      hub,
		LastPing: time.Now(),
		logger:   logger,
	}
}

// ReadPump pumps messages from the WebSocket connection to the hub.
// The application runs one ReadPump goroutine per connection. The application
// ensures that there is at most one reader on a connection by executing all
// reads from this goroutine.
func (c *Client) ReadPump() {
	defer func() {
		select {
		case c.Hub.unregister <- c:
		default:
			c.logger.Warn("unregister channel full, closing connection without hub unregister",
				zap.String("client", c.ID),
			)
		}
		c.Conn.Close() //nolint:errcheck
	}()

	c.Conn.SetReadLimit(ReadLimit)
	if err := c.Conn.SetReadDeadline(time.Now().Add(PongTimeout)); err != nil {
		c.logger.Error("set read deadline", zap.String("client", c.ID), zap.Error(err))
		return
	}
	c.Conn.SetPongHandler(func(string) error {
		c.mu.Lock()
		c.LastPing = time.Now()
		c.mu.Unlock()
		return c.Conn.SetReadDeadline(time.Now().Add(PongTimeout))
	})

	for {
		_, raw, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err,
				websocket.CloseGoingAway,
				websocket.CloseAbnormalClosure,
			) {
				c.logger.Warn("unexpected close", zap.String("client", c.ID), zap.Error(err))
			}
			break
		}

		var msg Message
		if err := json.Unmarshal(raw, &msg); err != nil {
			c.sendError("invalid_message", "malformed JSON")
			continue
		}

		// Duplicate sequence number detection.
		if msg.SeqNum != 0 {
			c.mu.Lock()
			duplicate := msg.SeqNum <= c.lastSeq
			if !duplicate {
				c.lastSeq = msg.SeqNum
			}
			c.mu.Unlock()
			if duplicate {
				c.sendError("duplicate_seq", "duplicate sequence number")
				continue
			}
		}

		c.handleMessage(&msg)
	}
}

// WritePump pumps messages from the hub to the WebSocket connection.
// A goroutine running WritePump is started for each connection. The
// application ensures that there is at most one writer to a connection by
// executing all writes from this goroutine.
func (c *Client) WritePump() {
	ticker := time.NewTicker(PingInterval)
	defer func() {
		ticker.Stop()
		c.Conn.Close() //nolint:errcheck
	}()

	for {
		select {
		case message, ok := <-c.Send:
			if err := c.Conn.SetWriteDeadline(time.Now().Add(WriteDeadline)); err != nil {
				c.logger.Error("set write deadline", zap.String("client", c.ID), zap.Error(err))
				return
			}
			if !ok {
				// The hub closed the channel.
				_ = c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			if _, err = w.Write(message); err != nil {
				c.logger.Error("write message", zap.String("client", c.ID), zap.Error(err))
			}

			// Drain any queued messages into the same write.
			n := len(c.Send)
			for i := 0; i < n; i++ {
				_, _ = w.Write([]byte("\n"))
				_, _ = w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			if err := c.Conn.SetWriteDeadline(time.Now().Add(WriteDeadline)); err != nil {
				return
			}
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

// handleMessage dispatches an incoming client message to the hub.
func (c *Client) handleMessage(msg *Message) {
	switch msg.Type {
	case MsgPing:
		c.mu.Lock()
		c.LastPing = time.Now()
		c.mu.Unlock()
		pongMsg, err := NewMessage(MsgPong, PongPayload{Timestamp: time.Now().UnixMilli()})
		if err != nil {
			return
		}
		data, err := pongMsg.Encode()
		if err != nil {
			return
		}
		select {
		case c.Send <- data:
		default:
		}
	default:
		// Route all game messages through the hub's action channel.
		select {
		case c.Hub.action <- &ClientAction{Client: c, Msg: msg}:
		default:
			c.logger.Warn("action channel full, dropping message",
				zap.String("client", c.ID),
				zap.String("type", string(msg.Type)),
			)
			c.sendError("server_busy", "server is busy, please retry")
		}
	}
}

// sendError sends an error message to the client.
func (c *Client) sendError(code, message string) {
	msg, err := NewMessage(MsgError, ErrorPayload{Code: code, Message: message})
	if err != nil {
		return
	}
	data, err := msg.Encode()
	if err != nil {
		return
	}
	select {
	case c.Send <- data:
	default:
		c.logger.Warn("send channel full, dropping error", zap.String("client", c.ID))
	}
}

// SendJSON marshals v and queues it for delivery.
func (c *Client) SendJSON(msgType MessageType, v interface{}) error {
	msg, err := NewMessage(msgType, v)
	if err != nil {
		return err
	}
	data, err := msg.Encode()
	if err != nil {
		return err
	}
	select {
	case c.Send <- data:
		return nil
	default:
		return nil
	}
}

// ClientAction carries a parsed message together with the originating client.
type ClientAction struct {
	Client *Client
	Msg    *Message
}
