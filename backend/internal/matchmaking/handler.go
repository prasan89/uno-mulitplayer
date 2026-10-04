// Package matchmaking implements HTTP handlers for the matchmaking endpoints.
package matchmaking

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"go.uber.org/zap"
)

// contextKey is an unexported type for context keys in this package to avoid
// collisions with other packages.
type contextKey string

const (
	// ContextKeyPlayerID is the context key for the authenticated player's UID.
	ContextKeyPlayerID contextKey = "playerID"

	// ContextKeyPlayerELO is the context key for the authenticated player's ELO.
	ContextKeyPlayerELO contextKey = "playerELO"
)

// Handler exposes the matchmaking HTTP endpoints.
type Handler struct {
	service *Service
	logger  *zap.Logger
}

// NewHandler creates a Handler backed by the given Service.
func NewHandler(service *Service, logger *zap.Logger) *Handler {
	return &Handler{
		service: service,
		logger:  logger,
	}
}

// RegisterRoutes mounts all matchmaking routes onto the provided mux.
// Routes:
//
//	POST   /api/match            – create a private match, returns room code
//	POST   /api/match/queue      – join public matchmaking queue
//	DELETE /api/match/queue      – leave queue
//	POST   /api/match/{id}/join  – join a private match by room code
func (h *Handler) RegisterRoutes(r *mux.Router) {
	r.HandleFunc("/api/match", h.CreatePrivateMatch).Methods(http.MethodPost)
	r.HandleFunc("/api/match/queue", h.JoinQueue).Methods(http.MethodPost)
	r.HandleFunc("/api/match/queue", h.LeaveQueue).Methods(http.MethodDelete)
	r.HandleFunc("/api/match/{id}/join", h.JoinByRoomCode).Methods(http.MethodPost)
}

// ----- Request / Response types -----

// joinQueueRequest is the body for POST /api/match/queue.
type joinQueueRequest struct {
	// ELO is the player's current rating. A client may send 0 to default to 1000.
	ELO int `json:"elo"`

	// GameMode must be "ranked" or "casual".
	GameMode string `json:"game_mode"`
}

// createMatchResponse is the body returned by POST /api/match.
type createMatchResponse struct {
	RoomCode string `json:"room_code"`
}

// joinQueueResponse is the body returned by POST /api/match/queue.
type joinQueueResponse struct {
	// Status is "queued".
	Status  string `json:"status"`
	Message string `json:"message"`
}

// leaveQueueResponse is the body returned by DELETE /api/match/queue.
type leaveQueueResponse struct {
	Status string `json:"status"`
}

// joinRoomResponse is the body returned by POST /api/match/{id}/join.
type joinRoomResponse struct {
	// Status is "queued" if the player was added to the private room, or
	// "started" if the game was started immediately (future extension).
	Status   string `json:"status"`
	RoomCode string `json:"room_code"`
	Message  string `json:"message,omitempty"`
}

// errorResponse is returned for all error conditions.
type errorResponse struct {
	Error string `json:"error"`
}

// ----- Handlers -----

// CreatePrivateMatch handles POST /api/match.
// It creates a new private room and returns the 6-character room code.
// The creating player is automatically added to the room's waiting list.
func (h *Handler) CreatePrivateMatch(w http.ResponseWriter, r *http.Request) {
	playerID, elo, err := playerFromContext(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "authentication required")
		return
	}

	roomCode := h.service.CreatePrivateMatch()

	// Automatically add the creator to the private queue so they wait for others.
	entry := &QueueEntry{
		PlayerID: playerID,
		ELO:      elo,
		JoinedAt: time.Now(),
		GameMode: GameModePrivate,
		RoomCode: roomCode,
	}
	_, err = h.service.JoinQueue(entry)
	if err != nil {
		h.logger.Error("matchmaking: failed to add host to private room",
			zap.String("player_id", playerID),
			zap.String("room_code", roomCode),
			zap.Error(err),
		)
		writeError(w, http.StatusInternalServerError, "failed to create match")
		return
	}

	h.logger.Info("matchmaking: private match created",
		zap.String("player_id", playerID),
		zap.String("room_code", roomCode),
	)
	writeJSON(w, http.StatusCreated, createMatchResponse{RoomCode: roomCode})
}

// JoinQueue handles POST /api/match/queue.
// It adds the authenticated player to the public matchmaking queue.
func (h *Handler) JoinQueue(w http.ResponseWriter, r *http.Request) {
	playerID, elo, err := playerFromContext(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "authentication required")
		return
	}

	var req joinQueueRequest
	if err := decodeBody(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	// Default ELO to 1000 for new players.
	if req.ELO <= 0 {
		req.ELO = elo
	}
	if req.ELO <= 0 {
		req.ELO = 1000
	}

	mode, err := parseGameMode(req.GameMode)
	if err != nil {
		writeError(w, http.StatusBadRequest, "game_mode must be 'ranked' or 'casual'")
		return
	}
	if mode == GameModePrivate {
		writeError(w, http.StatusBadRequest, "use POST /api/match/{id}/join for private matches")
		return
	}

	entry := &QueueEntry{
		PlayerID: playerID,
		ELO:      req.ELO,
		JoinedAt: time.Now(),
		GameMode: mode,
	}

	_, err = h.service.JoinQueue(entry)
	if err != nil {
		if strings.Contains(err.Error(), "already in queue") {
			writeError(w, http.StatusConflict, "player is already in the queue")
			return
		}
		h.logger.Error("matchmaking: join queue error",
			zap.String("player_id", playerID),
			zap.Error(err),
		)
		writeError(w, http.StatusInternalServerError, "failed to join queue")
		return
	}

	h.logger.Info("matchmaking: player joined queue",
		zap.String("player_id", playerID),
		zap.Int("elo", req.ELO),
		zap.String("mode", string(mode)),
	)
	writeJSON(w, http.StatusAccepted, joinQueueResponse{
		Status:  "queued",
		Message: "you have been added to the matchmaking queue",
	})
}

// LeaveQueue handles DELETE /api/match/queue.
// It removes the authenticated player from the queue.
func (h *Handler) LeaveQueue(w http.ResponseWriter, r *http.Request) {
	playerID, _, err := playerFromContext(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "authentication required")
		return
	}

	removed := h.service.LeaveQueue(playerID)
	if !removed {
		writeError(w, http.StatusNotFound, "player is not in the queue")
		return
	}

	h.logger.Info("matchmaking: player left queue", zap.String("player_id", playerID))
	writeJSON(w, http.StatusOK, leaveQueueResponse{Status: "removed"})
}

// JoinByRoomCode handles POST /api/match/{id}/join.
// The {id} path parameter is the 6-character room code.
func (h *Handler) JoinByRoomCode(w http.ResponseWriter, r *http.Request) {
	playerID, elo, err := playerFromContext(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "authentication required")
		return
	}

	vars := mux.Vars(r)
	roomCode := strings.ToUpper(vars["id"])
	if len(roomCode) != roomCodeLength {
		writeError(w, http.StatusBadRequest, "room code must be 6 characters")
		return
	}

	if elo <= 0 {
		elo = 1000
	}

	ch, err := h.service.JoinPrivateMatch(playerID, elo, roomCode)
	if err != nil {
		if strings.Contains(err.Error(), "already in queue") {
			writeError(w, http.StatusConflict, "player is already in this room")
			return
		}
		h.logger.Error("matchmaking: join private match error",
			zap.String("player_id", playerID),
			zap.String("room_code", roomCode),
			zap.Error(err),
		)
		writeError(w, http.StatusInternalServerError, "failed to join match")
		return
	}
	// ch will receive the MatchResult over the WebSocket; HTTP just acknowledges.
	_ = ch

	h.logger.Info("matchmaking: player joined private room",
		zap.String("player_id", playerID),
		zap.String("room_code", roomCode),
	)
	writeJSON(w, http.StatusAccepted, joinRoomResponse{
		Status:   "queued",
		RoomCode: roomCode,
		Message:  "waiting for the host to start the match",
	})
}

// ----- Helpers -----

// playerFromContext extracts the player ID and ELO injected by the auth
// middleware.  Middleware is expected to call r.WithContext with these values
// before dispatching to the handler.
func playerFromContext(r *http.Request) (playerID string, elo int, err error) {
	pid, ok := r.Context().Value(ContextKeyPlayerID).(string)
	if !ok || pid == "" {
		return "", 0, errors.New("handler: playerID not in context")
	}
	eloVal, _ := r.Context().Value(ContextKeyPlayerELO).(int)
	return pid, eloVal, nil
}

// parseGameMode converts a string to a GameMode, rejecting unknown values.
func parseGameMode(s string) (GameMode, error) {
	switch GameMode(strings.ToLower(s)) {
	case GameModeRanked:
		return GameModeRanked, nil
	case GameModeCasual, "":
		return GameModeCasual, nil
	case GameModePrivate:
		return GameModePrivate, nil
	default:
		return "", errors.New("unknown game mode: " + s)
	}
}

// maxRequestBodyBytes is the maximum number of bytes accepted for any JSON
// request body. Requests larger than this are rejected before decoding to
// prevent memory exhaustion attacks.
const maxRequestBodyBytes = 64 * 1024 // 64 KB

// decodeBody reads and JSON-decodes the request body into dst.
// It limits reading to maxRequestBodyBytes to prevent unbounded memory use.
func decodeBody(r *http.Request, dst interface{}) error {
	if r.Body == nil {
		return nil
	}
	defer r.Body.Close() //nolint:errcheck
	limited := http.MaxBytesReader(nil, r.Body, maxRequestBodyBytes)
	return json.NewDecoder(limited).Decode(dst)
}

// writeJSON encodes v as JSON and writes it with the given HTTP status code.
func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		// The header is already sent; nothing we can do except log.
		_ = err
	}
}

// writeError writes a JSON error body with the given status code.
func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, errorResponse{Error: msg})
}
