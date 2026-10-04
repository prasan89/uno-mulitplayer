package matchmaking

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/wilddeck/server/internal/db"
	"github.com/wilddeck/server/internal/hub"
)

// LobbyManager handles server-authoritative lobby state: ready toggles,
// lobby state broadcasts, and game start transitions.
// It is wired into the matchmaking Handler at startup.
type LobbyManager struct {
	dbStore *db.DB
	h       *hub.Hub
	logger  *zap.Logger
}

// NewLobbyManager creates a LobbyManager.
func NewLobbyManager(dbStore *db.DB, h *hub.Hub, logger *zap.Logger) *LobbyManager {
	return &LobbyManager{dbStore: dbStore, h: h, logger: logger}
}

// SetReady marks the player ready or unready in the given match lobby.
// It broadcasts an updated lobby state to all players in the match room.
// The playerID is the server-authoritative Firebase UID — never client-supplied.
func (lm *LobbyManager) SetReady(ctx context.Context, matchID uuid.UUID, playerID string, ready bool) error {
	if lm.dbStore == nil {
		return fmt.Errorf("lobby: database not configured")
	}

	if err := lm.dbStore.SetPlayerReady(ctx, matchID, playerID, ready); err != nil {
		return fmt.Errorf("lobby.SetReady: %w", err)
	}

	// Broadcast to all players in the lobby room.
	lm.broadcastLobbyUpdate(ctx, matchID)

	lm.logger.Info("lobby: player toggled ready",
		zap.String("match_id", matchID.String()),
		zap.String("player_id", playerID),
		zap.Bool("ready", ready),
	)
	return nil
}

// StartGame transitions the match from waiting to playing, broadcasts
// game_starting and game_started events to all lobby participants.
// Only succeeds if at least 2 players are ready.
// Returns the match UUID that clients should connect to via WebSocket.
func (lm *LobbyManager) StartGame(ctx context.Context, matchID uuid.UUID, requesterID string) error {
	if lm.dbStore == nil {
		return fmt.Errorf("lobby: database not configured")
	}

	players, err := lm.dbStore.GetMatchPlayers(ctx, matchID)
	if err != nil {
		return fmt.Errorf("lobby.StartGame: %w", err)
	}

	readyCount := 0
	for _, p := range players {
		if p.IsReady && !p.IsBot {
			readyCount++
		}
	}
	if readyCount < 2 {
		return fmt.Errorf("lobby: at least 2 players must be ready (have %d)", readyCount)
	}

	started, err := lm.dbStore.StartMatch(ctx, matchID)
	if err != nil {
		return fmt.Errorf("lobby.StartGame StartMatch: %w", err)
	}
	if !started {
		return fmt.Errorf("lobby: match is not in waiting state")
	}

	gameID := matchID.String()
	roomID := gameID

	// Game starting countdown (500ms).
	_ = lm.h.BroadcastMsg(roomID, hub.MsgGameStarting, hub.GameStartingPayload{
		GameID:      gameID,
		CountdownMs: 500,
	}, "")

	_ = lm.h.BroadcastMsg(roomID, hub.MsgGameStarted, hub.GameStartedPayload{
		GameID: gameID,
	}, "")

	lm.logger.Info("lobby: game started",
		zap.String("match_id", matchID.String()),
		zap.String("requester", requesterID),
		zap.Int("ready_count", readyCount),
	)
	return nil
}

// GetLobbyState returns a hub.LobbyUpdatedPayload for the match.
func (lm *LobbyManager) GetLobbyState(ctx context.Context, matchID uuid.UUID) (*hub.LobbyUpdatedPayload, error) {
	if lm.dbStore == nil {
		return nil, fmt.Errorf("lobby: database not configured")
	}

	match, err := lm.dbStore.GetMatch(ctx, matchID)
	if err != nil {
		return nil, fmt.Errorf("lobby.GetLobbyState GetMatch: %w", err)
	}

	players, err := lm.dbStore.GetMatchPlayers(ctx, matchID)
	if err != nil {
		return nil, fmt.Errorf("lobby.GetLobbyState GetMatchPlayers: %w", err)
	}

	lobbyPlayers := make([]hub.LobbyPlayerInfo, len(players))
	readyCount := 0
	for i, p := range players {
		name := p.PlayerID
		if p.IsBot {
			name = fmt.Sprintf("Bot%d", p.SeatIndex)
		} else if strings.HasPrefix(p.PlayerID, "bot:") {
			name = fmt.Sprintf("Bot%d", p.SeatIndex)
		}
		lobbyPlayers[i] = hub.LobbyPlayerInfo{
			PlayerID:    p.PlayerID,
			DisplayName: name,
			SeatIndex:   p.SeatIndex,
			IsBot:       p.IsBot,
			IsReady:     p.IsReady,
		}
		if p.IsReady {
			readyCount++
		}
	}

	roomCode := ""
	if match.RoomCode.Valid {
		roomCode = match.RoomCode.String
	}

	return &hub.LobbyUpdatedPayload{
		GameID:     matchID.String(),
		RoomCode:   roomCode,
		Players:    lobbyPlayers,
		ReadyCount: readyCount,
		MaxPlayers: match.MaxPlayers,
	}, nil
}

// broadcastLobbyUpdate fetches current lobby state and broadcasts it to the room.
func (lm *LobbyManager) broadcastLobbyUpdate(ctx context.Context, matchID uuid.UUID) {
	payload, err := lm.GetLobbyState(ctx, matchID)
	if err != nil {
		lm.logger.Warn("lobby: failed to build lobby state for broadcast",
			zap.String("match_id", matchID.String()),
			zap.Error(err),
		)
		return
	}
	if broadcastErr := lm.h.BroadcastMsg(matchID.String(), hub.MsgLobbyUpdated, payload, ""); broadcastErr != nil {
		lm.logger.Warn("lobby: failed to broadcast lobby state",
			zap.String("match_id", matchID.String()),
			zap.Error(broadcastErr),
		)
	}
}
