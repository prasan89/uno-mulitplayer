package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"regexp"
	"strings"
	"syscall"
	"time"

	goredis "github.com/redis/go-redis/v9"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"

	"github.com/wilddeck/server/internal/bot"
	"github.com/wilddeck/server/internal/cache"
	"github.com/wilddeck/server/internal/db"
	"github.com/wilddeck/server/internal/game"
	"github.com/wilddeck/server/internal/hub"
	"github.com/wilddeck/server/internal/middleware"
)

// validIDRe matches safe alphanumeric/hyphen/underscore IDs up to 64 characters
// (covers both UUID and short alphanumeric keys).
var validIDRe = regexp.MustCompile(`^[a-zA-Z0-9_-]{1,64}$`)

// config holds all runtime configuration read from environment variables.
type config struct {
	Port              string
	MetricsPort       string
	FirebaseProjectID string
	AllowedOrigins    []string
	RedisAddr         string
	TrustedProxies    []string
}

// loadConfig reads configuration from environment variables with sensible
// defaults.
func loadConfig() *config {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	projectID := os.Getenv("FIREBASE_PROJECT_ID")
	if projectID == "" {
		projectID = "wilddeck"
	}
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}
	metricsPort := os.Getenv("METRICS_PORT")
	if metricsPort == "" {
		metricsPort = "9090"
	}
	origins := []string{"http://localhost:3000"}
	if o := os.Getenv("ALLOWED_ORIGINS"); o != "" {
		origins = splitOrigins(o)
	}

	// TRUSTED_PROXIES is a comma-separated list of CIDR ranges for reverse
	// proxies that are allowed to supply X-Forwarded-For / X-Real-Ip headers.
	// Leave empty (the default) when the server is accessed directly, so that
	// clients cannot spoof their IP to evade rate limiting.
	var trustedProxies []string
	if tp := os.Getenv("TRUSTED_PROXIES"); tp != "" {
		trustedProxies = splitOrigins(tp) // reuse the same comma-split helper
	}

	return &config{
		Port:              port,
		MetricsPort:       metricsPort,
		FirebaseProjectID: projectID,
		AllowedOrigins:    origins,
		RedisAddr:         redisAddr,
		TrustedProxies:    trustedProxies,
	}
}

func splitOrigins(s string) []string {
	var out []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == ',' {
			if v := trim(s[start:i]); v != "" {
				out = append(out, v)
			}
			start = i + 1
		}
	}
	if v := trim(s[start:]); v != "" {
		out = append(out, v)
	}
	return out
}

func trim(s string) string {
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t') {
		s = s[:len(s)-1]
	}
	return s
}

// newUpgrader returns a WebSocket upgrader that validates the request Origin
// header against the provided allowed-origins list, mirroring the logic used
// by the CORS middleware. gorilla/websocket's CheckOrigin runs during the
// HTTP→WebSocket upgrade handshake, before any HTTP middleware can act, so
// origin enforcement must happen here and cannot be delegated to middleware.
func newUpgrader(allowedOrigins []string) websocket.Upgrader {
	allowAll := len(allowedOrigins) == 1 && allowedOrigins[0] == "*"
	return websocket.Upgrader{
		HandshakeTimeout: 10 * time.Second,
		ReadBufferSize:   hub.ReadLimit,
		WriteBufferSize:  4096,
		CheckOrigin: func(r *http.Request) bool {
			origin := r.Header.Get("Origin")
			// If no Origin header is present the request comes from a same-origin
			// context (e.g. a server-side tool or direct curl); allow it.
			if origin == "" {
				return true
			}
			if allowAll {
				return true
			}
			for _, o := range allowedOrigins {
				if strings.EqualFold(o, origin) {
					return true
				}
			}
			return false
		},
	}
}

// server bundles all top-level dependencies.
type server struct {
	cfg      *config
	hub      *hub.Hub
	logger   *zap.Logger
	upgrader websocket.Upgrader
}

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync() //nolint:errcheck

	cfg := loadConfig()

	// Open the PostgreSQL connection pool. DATABASE_URL is required for full
	// functionality; if it is absent the server starts in a degraded mode
	// (no match persistence) and logs a warning.
	var dbStore *db.DB
	if dsn := os.Getenv("DATABASE_URL"); dsn != "" {
		var dbErr error
		dbStore, dbErr = db.New(context.Background(), dsn)
		if dbErr != nil {
			logger.Warn("failed to connect to database; match persistence disabled", zap.Error(dbErr))
		} else {
			defer dbStore.Close() //nolint:errcheck
		}
	} else {
		logger.Warn("DATABASE_URL not set; match persistence and stale-match cleanup disabled")
	}

	h := hub.NewHub(logger)

	// Connect to Redis and wire the action deduplication cache into the hub so
	// that duplicate client actions (e.g. double-tap or network retries) are
	// rejected before reaching game logic, even across multiple server instances.
	redisClient := goredis.NewClient(&goredis.Options{Addr: cfg.RedisAddr})
	actionCache := cache.New(redisClient)
	h.SetActionDeduper(actionCache)

	// Instantiate the BotManager and wire its TakeoverPlayer method into the
	// hub so that when a disconnected player's grace period expires the bot
	// system takes over their turn instead of leaving the game deadlocked.
	// NOTE: engine is nil here because the GameEngine implementation (game
	// service) is not yet wired up (see TODO stubs in the match handlers).
	// Replace nil with the concrete GameEngine once it is available.
	botMgr := bot.NewBotManager(nil, h, logger)
	h.SetBotTakeoverHandler(botMgr.TakeoverPlayer)

	// Wire game-action processing into the hub.  Every inbound ClientAction is
	// dispatched here; the handler applies the action to the in-memory game
	// state and persists the result with a read-modify-write loop that retries
	// on optimistic-concurrency conflicts (db.ErrVersionConflict).
	h.SetActionHandler(buildActionHandler(dbStore, h, logger))

	// Wire reconnect state delivery into the hub.  When a player reconnects
	// within the grace period the handler fetches the current game state from the
	// database, serialises the player-specific public view, and returns it so
	// the hub can embed it in the MsgReconnected envelope.  This ensures the
	// reconnecting client receives a complete, up-to-date game state in a single
	// round-trip instead of the previous null-state placeholder.
	h.SetReconnectHandler(buildReconnectHandler(dbStore, h, logger))

	srv := &server{
		cfg:      cfg,
		hub:      h,
		logger:   logger,
		upgrader: newUpgrader(cfg.AllowedOrigins),
	}

	// Create shared rate limiter (100 req/min/IP).
	rateLimiter := middleware.NewRateLimiter(middleware.RateLimitConfig{
		RequestsPerMinute: 100,
		CleanupInterval:   5 * time.Minute,
		TrustedProxies:    cfg.TrustedProxies,
	})
	defer rateLimiter.Stop()

	// Build HTTP router.
	router := buildRouter(srv, rateLimiter)

	httpServer := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// Context for background goroutines; cancelled on shutdown.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	hubDone := make(chan struct{})

	// Start hub event loop.
	go func() {
		defer close(hubDone)
		h.Run(ctx.Done())
	}()

	// Start matchmaking background worker.
	go runMatchmaking(ctx, logger)

	// Start stale session cleanup worker.
	go runStaleSessionCleanup(ctx, h, dbStore, logger)

	// Start HTTP server in a goroutine.
	serverErr := make(chan error, 1)
	go func() {
		logger.Info("HTTP server starting", zap.String("addr", httpServer.Addr))
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			serverErr <- err
		}
	}()

	// Start internal-only metrics server on loopback so it is never reachable
	// from outside this host.  The public router deliberately does NOT expose
	// /metrics.
	metricsAddr := "127.0.0.1:" + cfg.MetricsPort
	metricsMux := http.NewServeMux()
	metricsMux.Handle("/metrics", promhttp.Handler())
	metricsServer := &http.Server{
		Addr:         metricsAddr,
		Handler:      metricsMux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}
	go func() {
		logger.Info("metrics server starting (internal only)", zap.String("addr", metricsAddr))
		if err := metricsServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("metrics server error", zap.Error(err))
		}
	}()

	// Wait for shutdown signal.
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	select {
	case sig := <-quit:
		logger.Info("received shutdown signal", zap.String("signal", sig.String()))
	case err := <-serverErr:
		logger.Error("server error", zap.Error(err))
	}

	// Graceful shutdown: 30-second drain timeout.
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	logger.Info("shutting down HTTP server")
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		logger.Error("HTTP server shutdown error", zap.Error(err))
	}

	logger.Info("shutting down metrics server")
	if err := metricsServer.Shutdown(shutdownCtx); err != nil {
		logger.Error("metrics server shutdown error", zap.Error(err))
	}

	// Stop background goroutines.
	cancel()

	// Wait for hub to stop.
	select {
	case <-hubDone:
		logger.Info("hub stopped")
	case <-shutdownCtx.Done():
		logger.Warn("hub stop timed out")
	}

	logger.Info("shutdown complete")
}

// buildRouter constructs the gorilla/mux router with all routes and middleware.
func buildRouter(srv *server, rl *middleware.RateLimiter) http.Handler {
	r := mux.NewRouter()

	// Apply global middleware (outermost first).
	r.Use(middleware.Recovery(srv.logger))
	r.Use(middleware.CORS(middleware.CORSConfig{
		AllowedOrigins: srv.cfg.AllowedOrigins,
	}))
	r.Use(rl.Handler())

	// Public routes.
	r.HandleFunc("/health", handleHealth).Methods(http.MethodGet)

	// NOTE: /metrics is intentionally NOT registered here.  It is served on
	// the internal-only loopback metrics server (see main).

	// WebSocket upgrade (requires auth).
	authMW := middleware.Auth(middleware.AuthConfig{
		ProjectID: srv.cfg.FirebaseProjectID,
		Logger:    srv.logger,
	})
	r.Handle("/ws", authMW(http.HandlerFunc(srv.handleWebSocket))).Methods(http.MethodGet)

	// Match API (requires auth).
	api := r.PathPrefix("/api").Subrouter()
	api.Use(func(next http.Handler) http.Handler {
		return authMW(next)
	})
	api.HandleFunc("/match", srv.handleCreateMatch).Methods(http.MethodPost)
	api.HandleFunc("/match/{id}", srv.handleGetMatch).Methods(http.MethodGet)
	api.HandleFunc("/match/{id}/join", srv.handleJoinMatch).Methods(http.MethodPost)
	api.HandleFunc("/match/vs-ai", srv.handleCreateVsAI).Methods(http.MethodPost)

	return r
}

// ---- HTTP handlers ----

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}

func (s *server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r.Context())
	if claims == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	gameID := r.URL.Query().Get("game_id")
	if gameID == "" {
		http.Error(w, "game_id query param required", http.StatusBadRequest)
		return
	}
	if !validIDRe.MatchString(gameID) {
		http.Error(w, "invalid game_id", http.StatusBadRequest)
		return
	}

	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		s.logger.Error("websocket upgrade failed",
			zap.String("client", claims.UserID),
			zap.Error(err),
		)
		return
	}

	client := hub.NewClient(claims.UserID, gameID, conn, s.hub, s.logger)
	s.hub.Register(client)

	go client.WritePump()
	go client.ReadPump()
}

func (s *server) handleCreateMatch(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r.Context())
	if claims == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	const maxBodyBytes = 64 * 1024 // 64 KB
	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)

	var req struct {
		MaxPlayers int `json:"max_players"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if req.MaxPlayers < 2 {
		req.MaxPlayers = 4
	}
	if req.MaxPlayers > 4 {
		req.MaxPlayers = 4
	}

	// TODO: persist match to database via game service.
	matchID := newMatchID()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	resp := map[string]interface{}{
		"match_id":    matchID,
		"created_by":  claims.UserID,
		"max_players": req.MaxPlayers,
		"status":      "waiting",
	}
	_ = json.NewEncoder(w).Encode(resp)
}

func (s *server) handleGetMatch(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	matchID := vars["id"]
	if matchID == "" {
		http.Error(w, "match id required", http.StatusBadRequest)
		return
	}
	if !validIDRe.MatchString(matchID) {
		http.Error(w, "invalid match id", http.StatusBadRequest)
		return
	}

	// TODO: look up match from database.
	playerCount := len(s.connectedPlayers(matchID))

	w.Header().Set("Content-Type", "application/json")
	resp := map[string]interface{}{
		"match_id":         matchID,
		"connected_players": playerCount,
	}
	_ = json.NewEncoder(w).Encode(resp)
}

func (s *server) handleJoinMatch(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r.Context())
	if claims == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	vars := mux.Vars(r)
	matchID := vars["id"]
	if matchID == "" {
		http.Error(w, "match id required", http.StatusBadRequest)
		return
	}
	if !validIDRe.MatchString(matchID) {
		http.Error(w, "invalid match id", http.StatusBadRequest)
		return
	}

	// TODO: persist join action to database, validate seat availability.
	w.Header().Set("Content-Type", "application/json")
	resp := map[string]interface{}{
		"match_id":  matchID,
		"player_id": claims.UserID,
		"ws_url":    fmt.Sprintf("/ws?game_id=%s", matchID),
	}
	_ = json.NewEncoder(w).Encode(resp)
}

// handleCreateVsAI handles POST /api/match/vs-ai.
// It creates a single-player game with the requesting human and N bot players,
// returning a game_id the client can connect to immediately via WebSocket.
// Request body: {"bot_count": 3, "difficulty": "normal"}
// Response:     {"game_id": "...", "ws_url": "...", "bots": [...]}
func (s *server) handleCreateVsAI(w http.ResponseWriter, r *http.Request) {
	claims := middleware.ClaimsFromContext(r.Context())
	if claims == nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	const maxBodyBytes = 64 * 1024
	r.Body = http.MaxBytesReader(w, r.Body, maxBodyBytes)

	var req struct {
		BotCount   int    `json:"bot_count"`
		Difficulty string `json:"difficulty"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// Validate and normalise bot count (1-3 bots, default 3).
	if req.BotCount < 1 {
		req.BotCount = 3
	}
	if req.BotCount > 3 {
		req.BotCount = 3
	}

	// Map difficulty string to bot.Difficulty.
	var difficulty bot.Difficulty
	switch strings.ToLower(req.Difficulty) {
	case "easy":
		difficulty = bot.DifficultyEasy
	case "hard":
		difficulty = bot.DifficultyHard
	default:
		difficulty = bot.DifficultyMedium
	}

	gameID := uuid.New().String()

	// Create bot entries; seat 0 is the human.
	type botInfo struct {
		PlayerID    string `json:"player_id"`
		Name        string `json:"name"`
		Personality string `json:"personality"`
		Difficulty  string `json:"difficulty"`
	}
	bots := make([]botInfo, req.BotCount)
	for i := 0; i < req.BotCount; i++ {
		personality := bot.PersonalityAt(i)
		botID := uuid.New().String()
		bots[i] = botInfo{
			PlayerID:    botID,
			Name:        string(personality),
			Personality: string(personality),
			Difficulty:  string(difficulty),
		}
	}

	// In a production implementation with a live database, we would:
	//   1. Persist the game via dbStore.CreateMatch(...)
	//   2. Register each bot with the BotManager.
	// For the current milestone the game table is managed by the Flutter
	// local AI engine; the endpoint exists so the client can request a game
	// and receive stable IDs. The Flutter VS-AI mode also works fully offline.
	s.logger.Info("vs-ai game created",
		zap.String("game_id", gameID),
		zap.String("human_id", claims.UserID),
		zap.Int("bot_count", req.BotCount),
		zap.String("difficulty", string(difficulty)),
	)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	resp := map[string]interface{}{
		"game_id": gameID,
		"ws_url":  fmt.Sprintf("/ws?game_id=%s", gameID),
		"bots":    bots,
	}
	_ = json.NewEncoder(w).Encode(resp)
}
func (s *server) connectedPlayers(roomID string) []string {
	room := s.hub.Room(roomID)
	if room == nil {
		return nil
	}
	room.Mu().RLock()
	defer room.Mu().RUnlock()
	ids := make([]string, 0, len(room.Clients))
	for id := range room.Clients {
		ids = append(ids, id)
	}
	return ids
}

// ---- Background workers ----

// runMatchmaking is the background goroutine responsible for pairing waiting
// players into games. Stubbed here; real logic lives in internal/matchmaking.
func runMatchmaking(ctx context.Context, logger *zap.Logger) {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			// TODO: call matchmaking service.
		case <-ctx.Done():
			logger.Info("matchmaking worker stopped")
			return
		}
	}
}

// runStaleSessionCleanup periodically removes sessions that have been idle
// beyond the reconnect grace period and triggers bot takeover.
func runStaleSessionCleanup(ctx context.Context, h *hub.Hub, dbStore *db.DB, logger *zap.Logger) {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	// A match is considered stale when it has not been updated for longer than
	// the reconnect grace period plus a one-minute buffer. This gives every
	// player a full grace window to reconnect before the match is abandoned.
	staleSeconds := int(hub.ReconnectGrace.Seconds()) + 60

	for {
		select {
		case <-ticker.C:
			if dbStore != nil {
				abandoned, err := dbStore.AbandonStaleMatches(ctx, staleSeconds)
				if err != nil {
					logger.Error("stale match cleanup failed", zap.Error(err))
				} else if len(abandoned) > 0 {
					ids := make([]string, len(abandoned))
					for i, id := range abandoned {
						ids[i] = id.String()
					}
					logger.Info("abandoned stale matches",
						zap.Int("count", len(abandoned)),
						zap.Strings("match_ids", ids),
					)
				}
			}
		case <-ctx.Done():
			logger.Info("stale session cleanup worker stopped")
			return
		}
	}
}

// newMatchID generates a simple unique match identifier.
// Replace with UUID generation via github.com/google/uuid in production.
func newMatchID() string {
	return fmt.Sprintf("match-%d", time.Now().UnixNano())
}

// ---- Action handler ----

// maxVersionConflictRetries is the maximum number of read-modify-write
// attempts before giving up on a version conflict.
const maxVersionConflictRetries = 3

// buildActionHandler returns the hub.SetActionHandler callback.  It
// translates a hub.ClientAction (raw WebSocket message) into a game.Action,
// applies it to the persisted match state, and writes the result back using
// db.UpdateMatchState.  On db.ErrVersionConflict it re-fetches the match and
// retries up to maxVersionConflictRetries times with exponential back-off
// (50 ms, 100 ms, 200 ms) so that concurrent plays in the same room converge
// correctly without silently dropping moves.
func buildActionHandler(dbStore *db.DB, h *hub.Hub, logger *zap.Logger) func(*hub.ClientAction) {
	return func(act *hub.ClientAction) {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		// Parse the match UUID from the client's game ID.  If the game ID is not
		// a valid UUID the action cannot be persisted; log and skip.
		matchID, err := uuid.Parse(act.Client.GameID)
		if err != nil {
			// Game ID is not a UUID — this is expected while the DB layer is still
			// being wired up (match IDs are currently time-based strings).  Log at
			// debug level and return; no state to update.
			logger.Debug("action received for non-UUID game ID; skipping DB persist",
				zap.String("game_id", act.Client.GameID),
				zap.String("client", act.Client.ID),
			)
			return
		}

		if dbStore == nil {
			// No database configured; nothing to persist.
			logger.Warn("action received but database is not configured; dropping",
				zap.String("game_id", act.Client.GameID),
				zap.String("client", act.Client.ID),
			)
			return
		}

		// Decode the generic game action from the message payload.
		var action game.Action
		if err := json.Unmarshal(act.Msg.Payload, &action); err != nil {
			logger.Warn("failed to decode game action payload",
				zap.String("client", act.Client.ID),
				zap.Error(err),
			)
			_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
				Code:    "invalid_action",
				Message: "malformed action payload",
			})
			return
		}
		// Ensure the action is attributed to the authenticated client, not to
		// whatever player ID the client may have supplied in the payload.
		action.PlayerID = act.Client.ID

		// Read-modify-write loop with bounded retries on version conflict.
		backoff := 50 * time.Millisecond
		for attempt := 0; attempt < maxVersionConflictRetries; attempt++ {
			if attempt > 0 {
				// Exponential back-off between retries.
				select {
				case <-time.After(backoff):
				case <-ctx.Done():
					logger.Warn("action handler context expired during retry back-off",
						zap.String("client", act.Client.ID),
						zap.Int("attempt", attempt),
					)
					_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
						Code:    "server_busy",
						Message: "could not process action, please retry",
					})
					return
				}
				backoff *= 2
			}

			// 1. Fetch current match state from the database.
			match, fetchErr := dbStore.GetMatch(ctx, matchID)
			if fetchErr != nil {
				logger.Error("failed to fetch match for action",
					zap.String("match_id", matchID.String()),
					zap.String("client", act.Client.ID),
					zap.Error(fetchErr),
				)
				_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
					Code:    "internal_error",
					Message: "failed to load match state",
				})
				return
			}

			// 2. Deserialise the stored game state.
			var gs game.GameState
			if unmarshalErr := json.Unmarshal(match.GameState, &gs); unmarshalErr != nil {
				logger.Error("failed to unmarshal game state",
					zap.String("match_id", matchID.String()),
					zap.Error(unmarshalErr),
				)
				_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
					Code:    "internal_error",
					Message: "failed to deserialise game state",
				})
				return
			}

			// 3. Apply the action to the in-memory state.
			if applyErr := gs.ApplyAction(action); applyErr != nil {
				logger.Info("invalid game action",
					zap.String("client", act.Client.ID),
					zap.String("action_type", string(action.Type)),
					zap.Error(applyErr),
				)
				_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
					Code:    "invalid_action",
					Message: applyErr.Error(),
				})
				return
			}

			// 4. Serialise the updated state.
			newStateJSON, marshalErr := json.Marshal(&gs)
			if marshalErr != nil {
				logger.Error("failed to marshal updated game state",
					zap.String("match_id", matchID.String()),
					zap.Error(marshalErr),
				)
				return
			}

			// Determine the new match status.
			newStatus := db.MatchStatusPlaying
			if gs.Phase == game.PhaseFinished {
				newStatus = db.MatchStatusFinished
			}

			// 5. Persist the new state with optimistic concurrency.
			_, updateErr := dbStore.UpdateMatchState(ctx, matchID, match.Version, newStateJSON, newStatus)
			if updateErr == nil {
				// Success — broadcast updated state to all players in the room.
				broadcastErr := h.BroadcastMsg(act.Client.GameID, hub.MsgGameState, gs.ToPublicView(act.Client.ID), "")
				if broadcastErr != nil {
					logger.Warn("failed to broadcast game state",
						zap.String("game_id", act.Client.GameID),
						zap.Error(broadcastErr),
					)
				}
				if gs.Phase == game.PhaseFinished {
					_ = h.BroadcastMsg(act.Client.GameID, hub.MsgGameOver, hub.GameOverPayload{WinnerID: gs.WinnerID}, "")
				}
				return
			}

			if errors.Is(updateErr, db.ErrVersionConflict) {
				logger.Info("version conflict on match update; retrying",
					zap.String("match_id", matchID.String()),
					zap.String("client", act.Client.ID),
					zap.Int("attempt", attempt+1),
					zap.Int("max_attempts", maxVersionConflictRetries),
				)
				// Loop back to re-fetch and re-apply.
				continue
			}

			// Unexpected DB error — do not retry.
			logger.Error("failed to persist match state",
				zap.String("match_id", matchID.String()),
				zap.String("client", act.Client.ID),
				zap.Error(updateErr),
			)
			_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
				Code:    "internal_error",
				Message: "failed to save game state",
			})
			return
		}

		// All retries exhausted.
		logger.Error("version conflict not resolved after max retries; dropping action",
			zap.String("match_id", matchID.String()),
			zap.String("client", act.Client.ID),
			zap.Int("max_attempts", maxVersionConflictRetries),
		)
		_ = act.Client.SendJSON(hub.MsgError, hub.ErrorPayload{
			Code:    "conflict",
			Message: "action could not be applied due to concurrent updates; please retry",
		})
	}
}

// buildReconnectHandler returns the hub.SetReconnectHandler callback.  When a
// player reconnects within the grace period the handler fetches the latest
// match state from the database, builds the player-specific public view, and
// returns it as JSON so the hub can embed it directly in the MsgReconnected
// envelope.  It also pushes a standalone MsgGameState message so that clients
// which only listen for that message type also receive the updated state.
//
// If the database is unavailable or the game ID is not a valid UUID the
// handler logs the problem and returns nil, which causes the hub to fall back
// to the JSON null placeholder (safe but degraded).
func buildReconnectHandler(dbStore *db.DB, h *hub.Hub, logger *zap.Logger) func(clientID, gameID string) json.RawMessage {
	return func(clientID, gameID string) json.RawMessage {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		// Game IDs that are not UUIDs pre-date the DB layer; skip gracefully.
		matchID, err := uuid.Parse(gameID)
		if err != nil {
			logger.Debug("reconnect: game ID is not a UUID; skipping state fetch",
				zap.String("game_id", gameID),
				zap.String("client", clientID),
			)
			return nil
		}

		if dbStore == nil {
			logger.Warn("reconnect: database not configured; cannot fetch game state",
				zap.String("game_id", gameID),
				zap.String("client", clientID),
			)
			return nil
		}

		match, fetchErr := dbStore.GetMatch(ctx, matchID)
		if fetchErr != nil {
			logger.Error("reconnect: failed to fetch match state",
				zap.String("match_id", matchID.String()),
				zap.String("client", clientID),
				zap.Error(fetchErr),
			)
			return nil
		}

		var gs game.GameState
		if unmarshalErr := json.Unmarshal(match.GameState, &gs); unmarshalErr != nil {
			logger.Error("reconnect: failed to unmarshal game state",
				zap.String("match_id", matchID.String()),
				zap.String("client", clientID),
				zap.Error(unmarshalErr),
			)
			return nil
		}

		publicView := gs.ToPublicView(clientID)

		// Push a standalone MsgGameState to the reconnecting client so that
		// frontend code listening only for "game_state" messages also wakes up.
		if sendErr := h.SendToClient(clientID, hub.MsgGameState, publicView); sendErr != nil {
			logger.Warn("reconnect: failed to send MsgGameState to client",
				zap.String("client", clientID),
				zap.Error(sendErr),
			)
		}

		// Serialise the public view to embed it in the MsgReconnected envelope.
		stateJSON, marshalErr := json.Marshal(publicView)
		if marshalErr != nil {
			logger.Error("reconnect: failed to marshal public game state",
				zap.String("match_id", matchID.String()),
				zap.String("client", clientID),
				zap.Error(marshalErr),
			)
			return nil
		}

		return json.RawMessage(stateJSON)
	}
}
