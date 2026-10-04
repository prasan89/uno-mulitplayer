package matchmaking

import (
	"fmt"

	"go.uber.org/zap"

	"github.com/wilddeck/server/internal/hub"
)

// HubPlayerNotifier implements PlayerNotifier using the WebSocket hub.
// Messages are delivered to the player's active WebSocket connection if they
// are online. If the player is not connected the delivery silently fails (the
// hub's SendToClient already handles the not-connected case gracefully).
type HubPlayerNotifier struct {
	h      *hub.Hub
	logger *zap.Logger
}

// NewHubPlayerNotifier returns a notifier backed by the given hub.
func NewHubPlayerNotifier(h *hub.Hub, logger *zap.Logger) *HubPlayerNotifier {
	return &HubPlayerNotifier{h: h, logger: logger}
}

// NotifyPlayer sends a match_found WebSocket message to the player.
// It implements PlayerNotifier.
func (n *HubPlayerNotifier) NotifyPlayer(playerID string, msg interface{}) error {
	// Convert the generic matchFoundMsg into the typed hub payload.
	switch v := msg.(type) {
	case matchFoundMsg:
		payload := hub.MatchFoundPayload{
			GameID:   v.GameID,
			RoomCode: v.RoomCode,
			Players:  v.Players,
		}
		if err := n.h.SendToClient(playerID, hub.MsgMatchFound, payload); err != nil {
			return fmt.Errorf("notifier: SendToClient %s: %w", playerID, err)
		}
		n.logger.Info("notifier: match_found sent",
			zap.String("player_id", playerID),
			zap.String("game_id", v.GameID),
		)
		return nil
	default:
		// Fallback: send raw struct as whatever type it is with match_found type.
		if err := n.h.SendToClient(playerID, hub.MsgMatchFound, msg); err != nil {
			return fmt.Errorf("notifier: SendToClient (generic) %s: %w", playerID, err)
		}
		return nil
	}
}
