package bot

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/wilddeck/server/internal/game"
	"github.com/wilddeck/server/internal/hub"
	"go.uber.org/zap"
)

// ─── Metrics ─────────────────────────────────────────────────────────────────

var (
	metricBotTurnsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "bot_turns_total",
		Help: "Total number of turns taken by bots.",
	}, []string{"difficulty"})

	metricBotThinkSeconds = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "bot_think_seconds",
		Help:    "Time a bot spends \"thinking\" before making a move.",
		Buckets: prometheus.DefBuckets,
	})

	metricBotTakeoversActive = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "bot_takeovers_active",
		Help: "Number of disconnected-player slots currently taken over by bots.",
	})
)

// ─── GameEngine interface ─────────────────────────────────────────────────────

// GameEngine is a minimal interface the BotManager uses to read game state and
// apply actions. The concrete implementation lives in the matchmaking/game
// server layer; we depend on the interface here to stay decoupled.
type GameEngine interface {
	// GetPublicState returns a public view of the game for the given player.
	GetPublicState(gameID, playerID string) (*game.PublicGameState, error)

	// ApplyAction applies a validated action on behalf of a player.
	ApplyAction(gameID string, action game.Action) error
}

// ─── BotManager ──────────────────────────────────────────────────────────────

// BotManager owns all bot instances and coordinates their turns.
type BotManager struct {
	mu sync.RWMutex

	// bots holds every active bot keyed by bot ID.
	bots map[string]*Bot

	// takeoverIndex maps "gameID:playerID" -> botID for hijacked human slots.
	takeoverIndex map[string]string

	engine     GameEngine
	hub        *hub.Hub
	thinkDelay time.Duration
	logger     *zap.Logger
}

// defaultThinkDelayMS is the fallback think delay when BOT_THINK_DELAY_MS is
// not set.
const defaultThinkDelayMS = 1500

// NewBotManager creates a BotManager, reading BOT_THINK_DELAY_MS from the
// environment for the base think delay.
func NewBotManager(engine GameEngine, h *hub.Hub, logger *zap.Logger) *BotManager {
	delay := defaultThinkDelayMS
	if v := os.Getenv("BOT_THINK_DELAY_MS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			delay = n
		}
	}
	return &BotManager{
		bots:          make(map[string]*Bot),
		takeoverIndex: make(map[string]string),
		engine:        engine,
		hub:           h,
		thinkDelay:    time.Duration(delay) * time.Millisecond,
		logger:        logger,
	}
}

// AddBot creates a new bot player for the given game and returns it.
// seatIndex is passed for informational purposes (the bot's player slot in the
// game is determined by the engine when the player is added to the game).
func (m *BotManager) AddBot(gameID string, seatIndex int, difficulty Difficulty) *Bot {
	botID := uuid.New().String()
	playerID := uuid.New().String()

	b := &Bot{
		ID:         botID,
		Name:       fmt.Sprintf("Bot-%s-%d", string(difficulty[:1]), seatIndex),
		Difficulty: difficulty,
		GameID:     gameID,
		PlayerID:   playerID,
		strategy:   newStrategy(difficulty),
	}

	m.mu.Lock()
	m.bots[botID] = b
	m.mu.Unlock()

	m.logger.Info("bot added",
		zap.String("bot_id", botID),
		zap.String("player_id", playerID),
		zap.String("game_id", gameID),
		zap.String("difficulty", string(difficulty)),
		zap.Int("seat", seatIndex),
	)
	return b
}

// RemoveBot removes the bot with the given ID from the manager.
func (m *BotManager) RemoveBot(botID string) {
	m.mu.Lock()
	b, ok := m.bots[botID]
	if ok {
		delete(m.bots, botID)
	}
	m.mu.Unlock()

	if ok {
		m.logger.Info("bot removed",
			zap.String("bot_id", botID),
			zap.String("game_id", b.GameID),
		)
	}
}

// TakeoverPlayer creates a bot that acts on behalf of a disconnected human
// player. If a takeover already exists for the slot it is silently replaced.
func (m *BotManager) TakeoverPlayer(gameID, playerID string) {
	key := takeoverKey(gameID, playerID)
	botID := uuid.New().String()

	suffix := playerID
	if len(suffix) > 8 {
		suffix = suffix[:8]
	}
	b := &Bot{
		ID:         botID,
		Name:       fmt.Sprintf("Bot(sub-%s)", suffix),
		Difficulty: DifficultyMedium,
		GameID:     gameID,
		PlayerID:   playerID,
		strategy:   newStrategy(DifficultyMedium),
	}

	m.mu.Lock()
	// Remove any previous takeover for this slot.
	if oldID, exists := m.takeoverIndex[key]; exists {
		delete(m.bots, oldID)
		metricBotTakeoversActive.Dec()
	}
	m.bots[botID] = b
	m.takeoverIndex[key] = botID
	m.mu.Unlock()

	metricBotTakeoversActive.Inc()

	m.logger.Info("bot takeover started",
		zap.String("game_id", gameID),
		zap.String("player_id", playerID),
		zap.String("bot_id", botID),
	)
}

// ReleaseTakeover removes the bot that was substituting for the given player,
// typically because the player has reconnected.
func (m *BotManager) ReleaseTakeover(gameID, playerID string) {
	key := takeoverKey(gameID, playerID)

	m.mu.Lock()
	botID, ok := m.takeoverIndex[key]
	if ok {
		delete(m.bots, botID)
		delete(m.takeoverIndex, key)
	}
	m.mu.Unlock()

	if ok {
		metricBotTakeoversActive.Dec()
		m.logger.Info("bot takeover released",
			zap.String("game_id", gameID),
			zap.String("player_id", playerID),
			zap.String("bot_id", botID),
		)
	}
}

// OnTurnStart is called by the game server when it detects the current player
// is a bot (or a taken-over slot). It launches the bot's turn asynchronously
// so it does not block the caller.
func (m *BotManager) OnTurnStart(gameID, playerID string) {
	m.mu.RLock()
	var b *Bot
	for _, candidate := range m.bots {
		if candidate.GameID == gameID && candidate.PlayerID == playerID {
			b = candidate
			break
		}
	}
	m.mu.RUnlock()

	if b == nil {
		return
	}

	go m.executeTurn(b)
}

// executeTurn performs the full think-then-act cycle for a single bot turn.
func (m *BotManager) executeTurn(b *Bot) {
	defer func() {
		if r := recover(); r != nil {
			m.logger.Error("bot: recovered from panic in executeTurn",
				zap.String("bot_id", b.ID),
				zap.String("game_id", b.GameID),
				zap.String("player_id", b.PlayerID),
				zap.Any("panic", r),
			)
		}
	}()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// --- Think delay with ±20% jitter ---
	base := int(m.thinkDelay.Milliseconds())
	jitter := base / 5 // 20% of base
	var actualDelay int
	if jitter > 0 {
		actualDelay = base - jitter + rand.Intn(2*jitter+1)
	} else {
		actualDelay = base
	}

	thinkStart := time.Now()
	select {
	case <-time.After(time.Duration(actualDelay) * time.Millisecond):
	case <-ctx.Done():
		return
	}
	thinkElapsed := time.Since(thinkStart).Seconds()
	metricBotThinkSeconds.Observe(thinkElapsed)

	// --- Fetch game state ---
	state, err := m.engine.GetPublicState(b.GameID, b.PlayerID)
	if err != nil {
		m.logger.Warn("bot: failed to get game state",
			zap.String("bot_id", b.ID),
			zap.Error(err),
		)
		return
	}

	if state.Phase != game.PhasePlaying {
		return
	}

	// Confirm it is still our turn (state may have advanced).
	if state.CurrentPlayerIndex < 0 || state.CurrentPlayerIndex >= len(state.Players) {
		return
	}
	if state.Players[state.CurrentPlayerIndex].ID != b.PlayerID {
		return
	}

	// --- ShouldChallengeDraw4 ---
	if state.DrawPenalty >= 4 && b.strategy.ShouldChallengeDraw4(state) {
		action := game.Action{
			Type:         game.ActionChallengeDraw4,
			PlayerID:     b.PlayerID,
			ChallengerID: b.PlayerID,
		}
		if applyErr := m.engine.ApplyAction(b.GameID, action); applyErr == nil {
			metricBotTurnsTotal.WithLabelValues(string(b.Difficulty)).Inc()
			return
		}
	}

	// --- DrawPenalty: forced draw when stacking not in effect ---
	if state.DrawPenalty > 0 && len(state.LegalMoves) == 0 {
		m.applyDraw(b)
		metricBotTurnsTotal.WithLabelValues(string(b.Difficulty)).Inc()
		return
	}

	// --- Choose and play a card, or draw ---
	chosen := b.strategy.ChooseCard(state, state.MyHand)
	if chosen == nil {
		m.applyDraw(b)
		metricBotTurnsTotal.WithLabelValues(string(b.Difficulty)).Inc()
		return
	}

	// Determine chosen color for wild cards.
	var chosenColor game.Color
	if chosen.IsWild() {
		// Hand after playing this card.
		remaining := handWithout(state.MyHand, chosen.ID)
		chosenColor = b.strategy.ChooseColor(remaining)
	}

	// ShouldCallLastCard: call before playing when hand will drop to 1.
	if b.strategy.ShouldCallLastCard(state.MyHand) {
		lastCardAction := game.Action{
			Type:     game.ActionCallLastCard,
			PlayerID: b.PlayerID,
		}
		// Best-effort; ignore error (engine validates).
		_ = m.engine.ApplyAction(b.GameID, lastCardAction)
	}

	playAction := game.Action{
		Type:        game.ActionPlayCard,
		PlayerID:    b.PlayerID,
		CardID:      chosen.ID,
		ChosenColor: chosenColor,
	}
	if applyErr := m.engine.ApplyAction(b.GameID, playAction); applyErr != nil {
		// Card play failed — fall back to draw.
		m.logger.Warn("bot: play card failed, falling back to draw",
			zap.String("bot_id", b.ID),
			zap.String("card_id", chosen.ID),
			zap.Error(applyErr),
		)
		m.applyDraw(b)
	}

	metricBotTurnsTotal.WithLabelValues(string(b.Difficulty)).Inc()
}

// applyDraw submits a draw-card action for the bot.
func (m *BotManager) applyDraw(b *Bot) {
	action := game.Action{
		Type:     game.ActionDrawCard,
		PlayerID: b.PlayerID,
	}
	if err := m.engine.ApplyAction(b.GameID, action); err != nil {
		m.logger.Warn("bot: draw card failed",
			zap.String("bot_id", b.ID),
			zap.Error(err),
		)
	}
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

// takeoverKey returns the map key for a gameID+playerID takeover entry.
func takeoverKey(gameID, playerID string) string {
	return gameID + ":" + playerID
}

// handWithout returns a copy of hand with the card matching cardID removed.
func handWithout(hand []game.Card, cardID string) []game.Card {
	result := make([]game.Card, 0, len(hand))
	for _, c := range hand {
		if c.ID != cardID {
			result = append(result, c)
		}
	}
	return result
}
