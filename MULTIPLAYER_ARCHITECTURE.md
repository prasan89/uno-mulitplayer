# Multiplayer Architecture — WildDeck

## High-Level Overview

```
Flutter Client
      │  REST (HTTP/JSON)         │  WebSocket (ws://)
      ▼                           ▼
┌─────────────────────────────────────────┐
│              Go HTTP Server             │
│  ┌──────────┐  ┌────────────┐           │
│  │  Router  │  │  Auth MW   │           │
│  └────┬─────┘  └────────────┘           │
│       │                                 │
│  ┌────▼──────────────────────────────┐  │
│  │          matchmaking.Handler      │  │
│  │  JoinQueue / LeaveQueue / Ready   │  │
│  │  CreatePrivateMatch / StartLobby  │  │
│  └────┬──────────────┬──────────────┘  │
│       │              │                 │
│  ┌────▼────┐   ┌─────▼──────┐          │
│  │ Service │   │LobbyManager│          │
│  │ (Queue) │   │(Ready/Start│          │
│  └────┬────┘   └─────┬──────┘          │
│       │              │                 │
│  ┌────▼──────────────▼──────────────┐  │
│  │            hub.Hub               │  │
│  │   BroadcastMsg / SendToClient    │  │
│  └────────────────┬─────────────────┘  │
│                   │ WebSocket frames    │
└───────────────────┼─────────────────────┘
                    │
              Flutter Client
```

---

## Component Responsibilities

### matchmaking.Service

Owns the in-memory `Queue`. Runs a background goroutine that ticks every second to attempt match formation. Exposes:
- `JoinQueue(entry)` — add player, reject duplicates
- `LeaveQueue(playerID)` — remove player
- `CreatePrivateMatch()` — generate room code
- `JoinPrivateMatch(playerID, elo, roomCode)` — join private queue

Match formation calls `GameCreator.CreateGame` then `PlayerNotifier.NotifyPlayer` for each matched player.

### matchmaking.LobbyManager

Owns server-authoritative ready state. All reads and writes go to PostgreSQL; results are broadcast to the WebSocket room. Exposes:
- `SetReady(ctx, matchID, playerID, bool)` — toggle ready + broadcast
- `StartGame(ctx, matchID, requesterID)` — validate ≥2 ready, mark playing, broadcast countdown

### hub.Hub

The existing M2/M3 WebSocket hub. Unchanged by M5 except for new message type constants in `messages.go`. The hub routes messages by `game_id` room. Matchmaking uses `SendToClient` (keyed by Firebase UID) for `match_found` — the player is not yet in a room.

### db.DB

PostgreSQL via `database/sql`. M5 adds:
- `CreateMatchWithID` — insert match with caller-supplied UUID
- `AddMatchPlayer` — insert into `match_players`
- `SetPlayerReady` — UPDATE `is_ready`
- `GetMatchPlayers` — SELECT all players for a match
- `StartMatch` — conditional UPDATE `status = 'playing' WHERE status = 'waiting'`

---

## Authentication

All matchmaking and lobby endpoints require a Firebase ID token:

```
Authorization: Bearer <firebase_id_token>
```

The `middleware.Auth` handler verifies the token against Firebase, extracts the UID, and stores it in the request context as `Claims.UserID`. The matchmaking handler reads identity exclusively from `middleware.ClaimsFromContext` — it never accepts a client-supplied player ID.

---

## Interfaces for Testability

Two interfaces decouple the matchmaking service from infrastructure:

```go
type GameCreator interface {
    CreateGame(ctx context.Context, gameID string, playerIDs []string, mode GameMode) error
}

type PlayerNotifier interface {
    NotifyPlayer(playerID string, msg interface{}) error
}
```

Production: `DBGameCreator` (PostgreSQL) + `HubPlayerNotifier` (WebSocket hub).  
Tests: `noopCreator` + `capturingNotifier` (in-memory, no DB required).

---

## Data Flow: Quick Match

```
1. Client: POST /api/match/queue {"game_mode":"casual","elo":1200}
   Server: adds entry to Queue, responds 202 {"status":"queued"}

2. Client: opens WebSocket /ws?game_id=matchmaking&token=<jwt>

3. Server (background tick): 2–4 compatible players found
   → GameCreator.CreateGame(gameID, playerIDs, casual)
   → PlayerNotifier.NotifyPlayer(each player, match_found{game_id, room_code, players})

4. Client receives match_found via WebSocket
   → navigates to GameLobbyScreen(gameId)

5. Client: WebSocket /ws?game_id=<match_uuid>&token=<jwt>
   Server: lobby_updated broadcast (all current players + ready states)

6. Client: POST /api/match/<uuid>/ready
   Server: UPDATE match_players SET is_ready=true, broadcast lobby_updated

7. When readyCount >= 2:
   Client (host) or Server: POST /api/match/<uuid>/start
   Server: UPDATE match status='playing', broadcast game_starting + game_started

8. Client: navigates to GameTableScreen(gameId)
   (existing M3 game engine takes over)
```

---

## Data Flow: VS AI (M4 — unaffected)

VS AI runs entirely in Flutter (`AIGameService`). No backend calls are made during gameplay. The `POST /api/match/vs-ai` endpoint exists for future server-side VS AI but is not used by the current Flutter client. M5 changes do not touch any VS AI code paths.

---

## Concurrency Safety

- `Queue` uses `sync.RWMutex`; `Add` holds the write lock for the full duplicate-check + insert.
- `formMatch` removes players from the queue before notifying — a player cannot be claimed twice.
- `StartMatch` uses a conditional DB UPDATE (`WHERE status = 'waiting'`) — concurrent start requests are idempotent.
- All `LobbyManager` methods are stateless (reads/writes go to DB); concurrent HTTP calls are safe.

---

## Failure Handling

| Failure | Behaviour |
|---------|-----------|
| Client disconnects during matchmaking | Hub removes WebSocket; player remains in queue until timeout or explicit cancel |
| Client disconnects in lobby | Hub removes from room; `player_left` broadcast; ready count recalculated |
| DB unavailable during `SetReady` | Returns 500; client retries |
| `CreateGame` fails | Match not formed; players remain in queue for next tick |
| Double `StartGame` | Second call returns `lobby: match is not in waiting state` (409-like) |
| Matchmaking timeout | `matchmaking_timeout` WS event; player auto-removed from queue |

---

## Files Added / Modified in M5

| File | Change |
|------|--------|
| `backend/internal/matchmaking/handler.go` | All matchmaking + lobby HTTP handlers |
| `backend/internal/matchmaking/lobby.go` | `LobbyManager` |
| `backend/internal/matchmaking/game_creator.go` | `DBGameCreator`, `HubPlayerNotifier` |
| `backend/internal/matchmaking/matchmaking_test.go` | 30 unit tests (no DB) |
| `backend/internal/hub/messages.go` | Matchmaking + lobby WebSocket message types |
| `backend/internal/db/matches.go` | `CreateMatchWithID`, `AddMatchPlayer`, `SetPlayerReady`, `GetMatchPlayers`, `StartMatch` |
| `backend/cmd/server/main.go` | Wires `DBGameCreator`, `HubPlayerNotifier`, `LobbyManager` into `Handler` |
| `db/migrations/003_lobby_ready.sql` | `is_ready` column + index on `match_players` |
| `frontend/lib/core/services/real_matchmaking_service.dart` | `RealMatchmakingService` + `RealLobbyService` |
| `frontend/lib/features/game_lobby/game_lobby_screen.dart` | Live lobby via WebSocket |
| `frontend/lib/features/matchmaking/matchmaking_screen.dart` | Wired to `realMatchmakingServiceProvider` |
| `frontend/lib/core/providers/wilddeck_providers.dart` | `realMatchmakingServiceProvider` + `realLobbyServiceProvider` |
| `MATCHMAKING.md` | Matchmaking documentation |
| `LOBBY.md` | Lobby documentation |
| `MULTIPLAYER_ARCHITECTURE.md` | This file |
