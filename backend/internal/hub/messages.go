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

	// Matchmaking events.
	MsgMatchmakingJoined    MessageType = "matchmaking_joined"
	MsgMatchmakingCancelled MessageType = "matchmaking_cancelled"
	MsgMatchmakingTimeout   MessageType = "matchmaking_timeout"
	MsgMatchFound           MessageType = "match_found"

	// Lobby events.
	MsgLobbyUpdated  MessageType = "lobby_updated"
	MsgPlayerReady   MessageType = "player_ready"
	MsgPlayerUnready MessageType = "player_unready"
	MsgGameStarting  MessageType = "game_starting"
	MsgGameStarted   MessageType = "game_started"
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

// MatchmakingJoinedPayload confirms a player entered the matchmaking queue.
type MatchmakingJoinedPayload struct {
	QueueSize int    `json:"queue_size"`
	GameMode  string `json:"game_mode"`
}

// MatchmakingCancelledPayload confirms a player left the queue.
type MatchmakingCancelledPayload struct{}

// MatchmakingTimeoutPayload is sent when no match was found within the timeout.
type MatchmakingTimeoutPayload struct {
	Message string `json:"message"`
}

// MatchFoundPayload is sent to all matched players when a lobby is ready.
type MatchFoundPayload struct {
	GameID   string   `json:"game_id"`
	RoomCode string   `json:"room_code"`
	Players  []string `json:"players"`
}

// LobbyPlayerInfo describes one player's lobby slot.
type LobbyPlayerInfo struct {
	PlayerID    string `json:"player_id"`
	DisplayName string `json:"display_name"`
	SeatIndex   int    `json:"seat_index"`
	IsBot       bool   `json:"is_bot"`
	IsReady     bool   `json:"is_ready"`
}

// LobbyUpdatedPayload is broadcast whenever the lobby roster or ready states change.
type LobbyUpdatedPayload struct {
	GameID    string            `json:"game_id"`
	RoomCode  string            `json:"room_code"`
	Players   []LobbyPlayerInfo `json:"players"`
	ReadyCount int              `json:"ready_count"`
	MaxPlayers int              `json:"max_players"`
}

// PlayerReadyPayload is broadcast when a single player toggles ready.
type PlayerReadyPayload struct {
	PlayerID string `json:"player_id"`
	IsReady  bool   `json:"is_ready"`
}

// GameStartingPayload signals the countdown before the game actually starts.
type GameStartingPayload struct {
	GameID      string `json:"game_id"`
	CountdownMs int    `json:"countdown_ms"`
}

// GameStartedPayload signals that the game has transitioned to playing.
type GameStartedPayload struct {
	GameID string `json:"game_id"`
}
