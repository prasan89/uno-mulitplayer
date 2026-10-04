package hub

import "encoding/json"

// MessageType defines the type of a WebSocket message.
type MessageType string

// Client -> Server message types.
const (
	MsgJoinGame       MessageType = "join_game"
	MsgPlayCard       MessageType = "play_card"
	MsgDrawCard       MessageType = "draw_card"
	MsgCallLastCard    MessageType = "call_last_card"
	MsgChallengeDraw4 MessageType = "challenge_draw4"
	MsgPing           MessageType = "ping"
)

// Server -> Client message types.
const (
	MsgGameState     MessageType = "game_state"
	MsgPlayerJoined  MessageType = "player_joined"
	MsgPlayerLeft    MessageType = "player_left"
	MsgCardPlayed    MessageType = "card_played"
	MsgCardDrawn     MessageType = "card_drawn"
	MsgTurnChanged   MessageType = "turn_changed"
	MsgGameOver      MessageType = "game_over"
	MsgError         MessageType = "error"
	MsgPong          MessageType = "pong"
	MsgReconnected   MessageType = "reconnected"
)

// Message is the top-level envelope for all WebSocket messages.
type Message struct {
	Type     MessageType     `json:"type"`
	Payload  json.RawMessage `json:"payload,omitempty"`
	// SeqNum is used for duplicate-action detection.
	SeqNum uint64 `json:"seq_num,omitempty"`
}

// NewMessage creates a new Message with the given type and payload.
func NewMessage(msgType MessageType, payload interface{}) (*Message, error) {
	data, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	return &Message{Type: msgType, Payload: data}, nil
}

// Encode serialises a Message to JSON bytes.
func (m *Message) Encode() ([]byte, error) {
	return json.Marshal(m)
}

// --- Payload structs ---

// JoinGamePayload is the payload for join_game messages.
type JoinGamePayload struct {
	GameID string `json:"game_id"`
}

// PlayCardPayload is the payload for play_card messages.
type PlayCardPayload struct {
	CardID    string `json:"card_id"`
	ChosenColor string `json:"chosen_color,omitempty"` // for wild cards
}

// DrawCardPayload is the payload for draw_card messages.
type DrawCardPayload struct{}

// CallLastCardPayload is the payload for call_last_card messages.
type CallLastCardPayload struct{}

// ChallengeDraw4Payload is the payload for challenge_draw4 messages.
type ChallengeDraw4Payload struct{}

// ErrorPayload is sent when an error occurs.
type ErrorPayload struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// PongPayload is sent in response to a ping.
type PongPayload struct {
	Timestamp int64 `json:"timestamp"`
}

// PlayerJoinedPayload is sent when a player joins.
type PlayerJoinedPayload struct {
	PlayerID string `json:"player_id"`
	Username string `json:"username"`
}

// PlayerLeftPayload is sent when a player leaves.
type PlayerLeftPayload struct {
	PlayerID string `json:"player_id"`
}

// TurnChangedPayload is sent when the active turn changes.
type TurnChangedPayload struct {
	PlayerID string `json:"player_id"`
}

// GameOverPayload is sent when the game ends.
type GameOverPayload struct {
	WinnerID string `json:"winner_id"`
}

// ReconnectedPayload is sent to a reconnecting player with full state.
type ReconnectedPayload struct {
	GameID string          `json:"game_id"`
	State  json.RawMessage `json:"state"`
}
