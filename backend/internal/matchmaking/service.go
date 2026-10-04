// Package matchmaking implements the matchmaking service for WildDeck.
package matchmaking

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"go.uber.org/zap"
)

// botIDPrefix is prepended to bot player IDs so the game engine can distinguish
// bots from humans.
const botIDPrefix = "bot:"

// pollInterval is how frequently the service scans the queue for potential matches.
const pollInterval = 500 * time.Millisecond

// Metrics holds the Prometheus metrics for the matchmaking system.
type Metrics struct {
	queueSize        prometheus.Gauge
	waitSeconds      prometheus.Observer
	matchesCreated   prometheus.Counter
	matchesCompleted prometheus.Counter
}

// newMetrics registers and returns matchmaking Prometheus metrics.
// If reg is nil, the default registry is used.
func newMetrics(reg prometheus.Registerer) *Metrics {
	factory := promauto.With(reg)
	return &Metrics{
		queueSize: factory.NewGauge(prometheus.GaugeOpts{
			Name: "matchmaking_queue_size",
			Help: "Current number of players waiting in the matchmaking queue.",
		}),
		waitSeconds: factory.NewHistogram(prometheus.HistogramOpts{
			Name:    "matchmaking_wait_seconds",
			Help:    "Time in seconds a player waited before a match was found.",
			Buckets: prometheus.DefBuckets,
		}),
		matchesCreated: factory.NewCounter(prometheus.CounterOpts{
			Name: "matches_created_total",
			Help: "Total number of matches created.",
		}),
		matchesCompleted: factory.NewCounter(prometheus.CounterOpts{
			Name: "matches_completed_total",
			Help: "Total number of matches that completed.",
		}),
	}
}

// GameCreator is the interface the matchmaking service uses to create a new game.
// The concrete implementation lives in the game package and is injected at startup.
type GameCreator interface {
	// CreateGame initialises a new game with the given player IDs and returns
	// the game ID. Player IDs starting with botIDPrefix are treated as bots.
	CreateGame(ctx context.Context, gameID string, playerIDs []string, mode GameMode) error
}

// PlayerNotifier is the interface used to send matchmaking_found WebSocket
// messages to connected players.
type PlayerNotifier interface {
	// NotifyPlayer delivers a JSON payload to the player's WebSocket connection.
	// If the player is not connected the implementation must not block.
	NotifyPlayer(playerID string, msg interface{}) error
}

// matchFoundMsg is the WebSocket message sent to players when a match is ready.
type matchFoundMsg struct {
	Type     string   `json:"type"`
	GameID   string   `json:"game_id"`
	RoomCode string   `json:"room_code"`
	Players  []string `json:"players"`
}

// Service orchestrates matchmaking: it manages the queue, pairs players, and
// kicks off new games.
type Service struct {
	queue     *Queue
	creator   GameCreator
	notifier  PlayerNotifier
	logger    *zap.Logger
	metrics   *Metrics

	// activeGames is a simple in-memory set of game IDs for completed-game
	// tracking.  A real production service would use a distributed store.
	activeGamesMu sync.Mutex
	activeGames   map[string]struct{}
}

// NewService creates a Service ready to run.
// reg may be nil to use the default Prometheus registry.
func NewService(
	creator GameCreator,
	notifier PlayerNotifier,
	logger *zap.Logger,
	reg prometheus.Registerer,
) *Service {
	return &Service{
		queue:       NewQueue(),
		creator:     creator,
		notifier:    notifier,
		logger:      logger,
		metrics:     newMetrics(reg),
		activeGames: make(map[string]struct{}),
	}
}

// Queue exposes the underlying Queue so HTTP handlers can enqueue/dequeue
// players directly.
func (s *Service) Queue() *Queue {
	return s.queue
}

// Run starts the matchmaking polling loop and blocks until ctx is cancelled.
func (s *Service) Run(ctx context.Context) {
	ticker := time.NewTicker(pollInterval)
	defer ticker.Stop()

	s.logger.Info("matchmaking: service started")
	for {
		select {
		case <-ctx.Done():
			s.logger.Info("matchmaking: service shutting down")
			return
		case <-ticker.C:
			s.metrics.queueSize.Set(float64(s.queue.Size()))
			s.processQueue(ctx)
		}
	}
}

// RecordMatchCompleted increments the completed-matches counter. Call this from
// the game engine when a game concludes.
func (s *Service) RecordMatchCompleted(gameID string) {
	s.activeGamesMu.Lock()
	delete(s.activeGames, gameID)
	s.activeGamesMu.Unlock()
	s.metrics.matchesCompleted.Inc()
}

// JoinQueue adds a player to the matchmaking queue and returns a channel that
// will receive a MatchResult when a match is found.
func (s *Service) JoinQueue(entry *QueueEntry) (<-chan MatchResult, error) {
	return s.queue.Add(entry)
}

// LeaveQueue removes a player from the queue.
func (s *Service) LeaveQueue(playerID string) bool {
	removed := s.queue.Remove(playerID)
	if removed {
		s.metrics.queueSize.Set(float64(s.queue.Size()))
	}
	return removed
}

// CreatePrivateMatch creates an empty private room, returning the generated room
// code.  Players join by calling JoinQueue with GameModePrivate and the code.
func (s *Service) CreatePrivateMatch() string {
	return GenerateRoomCode()
}

// JoinPrivateMatch adds a player to a private room queue identified by roomCode.
// It returns a channel that receives the MatchResult once the host starts the game,
// or an error if the room code is invalid/expired.
func (s *Service) JoinPrivateMatch(playerID string, elo int, roomCode string) (<-chan MatchResult, error) {
	entry := &QueueEntry{
		PlayerID: playerID,
		ELO:      elo,
		JoinedAt: time.Now(),
		GameMode: GameModePrivate,
		RoomCode: roomCode,
	}
	return s.queue.Add(entry)
}

// StartPrivateMatch forces a private room to start immediately with the current
// players, optionally filling with bots.  Called by the host via the HTTP API.
func (s *Service) StartPrivateMatch(ctx context.Context, roomCode string) (MatchResult, error) {
	entries := s.queue.PrivateRoomEntries(roomCode)
	if len(entries) == 0 {
		return MatchResult{}, fmt.Errorf("matchmaking: no players found for room code %q", roomCode)
	}

	return s.formMatch(ctx, entries, roomCode)
}

// processQueue scans the public queue and forms matches when possible.
func (s *Service) processQueue(ctx context.Context) {
	snapshot := s.queue.Snapshot()
	if len(snapshot) == 0 {
		return
	}

	matched := make(map[string]bool)

	for _, anchor := range snapshot {
		if matched[anchor.PlayerID] {
			continue
		}

		// Build a list of unmatched candidates compatible with this anchor.
		var pool []*QueueEntry
		for _, e := range snapshot {
			if !matched[e.PlayerID] {
				pool = append(pool, e)
			}
		}
		candidates := findCandidates(anchor, pool)

		// Include the anchor itself as the first player.
		group := []*QueueEntry{anchor}
		for _, c := range candidates {
			if len(group) >= maxPlayersPerMatch {
				break
			}
			group = append(group, c)
		}

		// We need at least minPlayersForMatch, or a single player who has
		// been waiting long enough to be filled with bots.
		if len(group) < minPlayersForMatch {
			if anchor.WaitTime() < botFillAfter {
				continue
			}
			// Fill remainder with bots.
			botsNeeded := minPlayersForMatch - len(group)
			group = append(group, makeBotEntries(botsNeeded)...)
		}

		// Fill remaining slots with bots if bots are warranted.
		if anchor.WaitTime() >= botFillAfter && len(group) < maxPlayersPerMatch {
			botsNeeded := maxPlayersPerMatch - len(group)
			group = append(group, makeBotEntries(botsNeeded)...)
		}

		// Mark all human players as matched.
		for _, e := range group {
			matched[e.PlayerID] = true
		}

		// Remove matched humans from the live queue.
		realPlayers := filterHumans(group)
		realPlayerIDs := make([]string, 0, len(realPlayers))
		for _, e := range realPlayers {
			realPlayerIDs = append(realPlayerIDs, e.PlayerID)
		}
		s.queue.DrainMatched(realPlayerIDs)

		// Form the match asynchronously so we don't block the poll loop.
		go func(g []*QueueEntry) {
			defer func() {
				if r := recover(); r != nil {
					s.logger.Error("matchmaking: panic in formMatch goroutine", zap.Any("panic", r))
				}
			}()
			result, err := s.formMatch(ctx, g, "")
			if err != nil {
				s.logger.Error("matchmaking: failed to form match", zap.Error(err))
				return
			}
			Notify(filterHumans(g), result)
		}(group)
	}
}

// formMatch creates a game for the given group, records metrics, and returns the
// MatchResult.  roomCode may be empty for public matches (one will be generated).
func (s *Service) formMatch(ctx context.Context, group []*QueueEntry, roomCode string) (MatchResult, error) {
	if roomCode == "" {
		roomCode = GenerateRoomCode()
	}

	gameID := uuid.New().String()
	playerIDs := make([]string, 0, len(group))
	for _, e := range group {
		playerIDs = append(playerIDs, e.PlayerID)
	}

	mode := GameModeRanked
	if len(group) > 0 {
		mode = group[0].GameMode
	}

	if err := s.creator.CreateGame(ctx, gameID, playerIDs, mode); err != nil {
		return MatchResult{}, fmt.Errorf("matchmaking: CreateGame failed: %w", err)
	}

	s.activeGamesMu.Lock()
	s.activeGames[gameID] = struct{}{}
	s.activeGamesMu.Unlock()

	s.metrics.matchesCreated.Inc()

	// Record wait time for each human player.
	for _, e := range group {
		if !isBotEntry(e) {
			s.metrics.waitSeconds.Observe(e.WaitTime().Seconds())
		}
	}

	result := MatchResult{
		GameID:   gameID,
		RoomCode: roomCode,
		Players:  playerIDs,
	}

	// Notify players via WebSocket.
	msg := matchFoundMsg{
		Type:     "matchmaking_found",
		GameID:   gameID,
		RoomCode: roomCode,
		Players:  playerIDs,
	}
	for _, e := range group {
		if isBotEntry(e) {
			continue
		}
		if err := s.notifier.NotifyPlayer(e.PlayerID, msg); err != nil {
			s.logger.Warn("matchmaking: failed to notify player",
				zap.String("player_id", e.PlayerID),
				zap.Error(err),
			)
		}
	}

	s.logger.Info("matchmaking: match formed",
		zap.String("game_id", gameID),
		zap.String("room_code", roomCode),
		zap.Int("player_count", len(playerIDs)),
	)
	return result, nil
}

// makeBotEntries creates n synthetic QueueEntry values representing bots.
func makeBotEntries(n int) []*QueueEntry {
	entries := make([]*QueueEntry, n)
	for i := range entries {
		entries[i] = &QueueEntry{
			PlayerID: fmt.Sprintf("%s%s", botIDPrefix, uuid.New().String()),
			ELO:      1000, // neutral ELO for bots
			JoinedAt: time.Now(),
			GameMode: GameModeCasual,
		}
	}
	return entries
}

// filterHumans returns only the non-bot entries from a group.
func filterHumans(group []*QueueEntry) []*QueueEntry {
	var out []*QueueEntry
	for _, e := range group {
		if !isBotEntry(e) {
			out = append(out, e)
		}
	}
	return out
}

// isBotEntry reports whether an entry represents a bot.
func isBotEntry(e *QueueEntry) bool {
	return len(e.PlayerID) >= len(botIDPrefix) && e.PlayerID[:len(botIDPrefix)] == botIDPrefix
}
