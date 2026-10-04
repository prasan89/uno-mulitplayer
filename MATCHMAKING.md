# Matchmaking — WildDeck

## Overview

WildDeck's matchmaking system lets real players find each other and form a game lobby without manual coordination. The server owns all queue state; clients only send join/cancel signals.

---

## User Flow

```
Home → Play → Online Multiplayer → Find Match
         ↓
Matchmaking Queue  (searching…  N / 4  players)
         ↓
Match Found  →  Lobby  →  Game
```

---

## Queue Mechanics

### Joining

`POST /api/match/queue`  
Body: `{ "game_mode": "casual" | "ranked", "elo": <int> }`

- Server reads the authenticated player's Firebase UID from middleware — the client cannot supply a fake `player_id`.
- A player who is already queued receives `409 Conflict` — duplicate queue entries are impossible.
- ELO defaults to 1000 for new accounts (`elo` ≤ 0 is replaced automatically).

### Matching algorithm

The queue runs a background goroutine (`Service.runMatchmaking`). On each tick:

1. Collect all waiting entries for a given `game_mode`.
2. Sort by join time (oldest first).
3. Group players within an ELO window (default ±200; expands by ±50 every 10 s of waiting).
4. When 2–4 compatible players are found, form a match:
   - Generate a UUID for the new game.
   - Call `GameCreator.CreateGame` (DB-backed in production; injectable for tests).
   - Call `PlayerNotifier.NotifyPlayer` for each player (hub-backed in production).
   - Remove all matched players from the queue.

### Cancelling

`DELETE /api/match/queue`

- Immediately removes the player from the in-memory queue.
- Returns `404` if the player was not queued.
- If a match was already formed at the instant of cancellation, the match proceeds (server is authoritative — the client may receive `match_found` after sending cancel).

### Timeout

After `matchmakingTimeoutSeconds` (default 60 s) with no match found:

- The server emits `matchmaking_timeout` via WebSocket to the player.
- The player is removed from the queue.
- The client shows **No players found yet** with options: **Try Again** / **Play VS AI**.

---

## Private Rooms

`POST /api/match` — creates a room, returns a 6-character `room_code`.  
`POST /api/match/{code}/join` — joins by room code.

Private rooms bypass ELO matching. The host triggers the start via `POST /api/match/{id}/start` once enough players are ready.

---

## WebSocket Events (matchmaking phase)

| Event | Direction | When |
|-------|-----------|------|
| `matchmaking_joined` | S→C | Confirmed queue entry |
| `matchmaking_cancelled` | S→C | Queue exit confirmed |
| `matchmaking_timeout` | S→C | No match found within timeout |
| `match_found` | S→C | Match formed; payload includes `game_id`, `room_code`, `players` |

All events use the envelope: `{ "type": "<event>", "payload": { … }, "seq_num": <uint> }`.

---

## Duplicate / Concurrency Protection

- The in-memory `Queue` uses a `sync.RWMutex` and a `map[playerID]` index.
- `Queue.Add` is atomic: it checks for duplicates and inserts under the same lock.
- `formMatch` removes players from the queue before notifying them, preventing a second match from claiming the same players.
- Integration tests cover: concurrent adds by N goroutines (each must get a unique seat), simultaneous cancel + match (no ghost entries).

---

## Rate Limiting

The `/api/match/queue` routes are covered by the existing per-IP middleware. Rapid successive join→cancel cycles are rejected by the 409-on-duplicate guard before hitting the queue itself.
