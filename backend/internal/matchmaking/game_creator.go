package matchmaking

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/wilddeck/server/internal/db"
	"github.com/wilddeck/server/internal/game"
)

// DBGameCreator implements GameCreator using the PostgreSQL database layer.
// It creates a new game via game.NewGame, persists it as a match row, and
// adds each player to match_players.
type DBGameCreator struct {
	dbStore *db.DB
	logger  *zap.Logger
}

// NewDBGameCreator returns a DBGameCreator backed by the given DB.
func NewDBGameCreator(dbStore *db.DB, logger *zap.Logger) *DBGameCreator {
	return &DBGameCreator{dbStore: dbStore, logger: logger}
}

// CreateGame implements GameCreator. It:
//  1. Builds game.PlayerInfo entries from playerIDs (bot IDs start with "bot:").
//  2. Calls game.NewGame to create the in-memory state.
//  3. Persists the match to the DB (with the provided gameID as the UUID).
//  4. Adds each player to match_players.
//  5. Stores the initial game state via UpdateMatchState.
func (c *DBGameCreator) CreateGame(ctx context.Context, gameID string, playerIDs []string, mode GameMode) error {
	matchUUID, err := uuid.Parse(gameID)
	if err != nil {
		return fmt.Errorf("game_creator: invalid gameID %q: %w", gameID, err)
	}

	// Build PlayerInfo list. Bot IDs start with "bot:" — give them a short name.
	players := make([]game.PlayerInfo, len(playerIDs))
	for i, id := range playerIDs {
		isBot := strings.HasPrefix(id, botIDPrefix)
		name := id
		if isBot {
			name = fmt.Sprintf("Bot%d", i)
		}
		players[i] = game.PlayerInfo{
			ID:    id,
			Name:  name,
			IsBot: isBot,
		}
	}

	gs := game.NewGame(players, game.HouseRules{})
	// Override the auto-generated GameID so the persisted state matches the DB row.
	gs.GameID = gameID

	stateJSON, err := json.Marshal(gs)
	if err != nil {
		return fmt.Errorf("game_creator: marshal game state: %w", err)
	}

	// Insert the match row. We need a specific UUID, but CreateMatch generates its
	// own via gen_random_uuid(). We therefore use a raw INSERT with the provided
	// UUID.
	roomCode := sql.NullString{String: GenerateRoomCode(), Valid: true}
	_, err = c.dbStore.CreateMatchWithID(ctx, matchUUID, string(mode), len(playerIDs), json.RawMessage("{}"), roomCode)
	if err != nil {
		return fmt.Errorf("game_creator: CreateMatchWithID: %w", err)
	}

	// Add each player to match_players.
	for i, id := range playerIDs {
		isBot := strings.HasPrefix(id, botIDPrefix)
		if addErr := c.dbStore.AddMatchPlayer(ctx, matchUUID, id, i, isBot); addErr != nil {
			c.logger.Warn("game_creator: failed to add match player",
				zap.String("game_id", gameID),
				zap.String("player_id", id),
				zap.Error(addErr),
			)
		}
	}

	// Persist initial game state at version 0.
	if _, updateErr := c.dbStore.UpdateMatchState(ctx, matchUUID, 0, stateJSON, db.MatchStatusWaiting); updateErr != nil {
		c.logger.Warn("game_creator: failed to persist initial game state",
			zap.String("game_id", gameID),
			zap.Error(updateErr),
		)
	}

	c.logger.Info("game_creator: game created",
		zap.String("game_id", gameID),
		zap.Int("players", len(playerIDs)),
		zap.String("mode", string(mode)),
	)
	return nil
}
