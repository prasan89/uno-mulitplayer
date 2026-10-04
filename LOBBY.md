# Lobby — WildDeck

## Overview

A WildDeck lobby is the waiting room between matchmaking and the actual game. Players confirm their intent by toggling ready; the server starts the game when conditions are met.

---

## Lifecycle

```
match_found
     ↓
Lobby created (match row, status = "waiting")
     ↓
Players connect via WebSocket (game_id room)
     ↓
Players toggle READY
     ↓
Start conditions met → game_starting → game_started
     ↓
GameTableScreen (M3)
```

---

## REST Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/match/{id}/ready` | Mark authenticated player ready |
| `DELETE` | `/api/match/{id}/ready` | Mark authenticated player unready |
| `POST` | `/api/match/{id}/start` | Host triggers game start (private rooms; auto-triggered for quick matches) |

`{id}` is the match UUID returned in `match_found.game_id`.

All endpoints require a valid Firebase ID token in the `Authorization: Bearer <token>` header. The server extracts the player's UID from the token — the client cannot supply a different player ID.

---

## Server Authority

- **Ready state** is stored in `match_players.is_ready` (PostgreSQL). The client cannot set another player's ready state.
- **Game start** requires `readyCount ≥ 2` (human players only — bots are excluded from the ready count).
- `StartMatch` uses a conditional UPDATE (`WHERE status = 'waiting'`) to prevent double-starts under concurrent requests.

---

## WebSocket Events (lobby phase)

| Event | Direction | Payload | When |
|-------|-----------|---------|------|
| `lobby_updated` | S→C | `LobbyUpdatedPayload` | Any player joins, leaves, or toggles ready |
| `player_ready` | S→C | `PlayerReadyPayload` | A specific player set ready |
| `player_unready` | S→C | `PlayerReadyPayload` | A specific player unset ready |
| `game_starting` | S→C | `GameStartingPayload` | Countdown broadcast |
| `game_started` | S→C | `GameStartedPayload` | Transition to game |

`LobbyUpdatedPayload` is the full lobby snapshot (all player slots, ready counts, max players). Clients rebuild their UI entirely from this event — no partial diffs to reconcile.

---

## Player Slots

Up to 4 slots. Each slot shows:
- `player_id` — Firebase UID
- `display_name` — username or "Bot N" for bots
- `seat_index` — deterministic seat assigned at match creation
- `is_bot` — whether the slot is an AI player
- `is_ready` — current ready state

Empty slots (below max_players) are shown as **Waiting for player…** in the Flutter UI.

---

## Player Leaves Lobby

If a player disconnects before the game starts:
- The WebSocket hub removes them from the room.
- The server emits `player_left` to the remaining players.
- `lobby_updated` is broadcast with the updated roster.
- If the ready count drops below 2, the game cannot start.

---

## Reconnect

A player who reconnects to the same `game_id` WebSocket room immediately receives the current `lobby_updated` snapshot. Their `is_ready` state is preserved in the DB — they do not need to re-ready unless they explicitly unready.

---

## Database Schema

```sql
-- match_players (added in migration 003)
ALTER TABLE match_players
    ADD COLUMN is_ready BOOL NOT NULL DEFAULT FALSE;

CREATE INDEX idx_match_players_match_ready
    ON match_players (match_id, is_ready);
```

`match.status` values: `waiting` → `playing` → `finished`.
