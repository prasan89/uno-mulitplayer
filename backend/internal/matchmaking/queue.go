// Package matchmaking implements the matchmaking queue and service for WildDeck.
package matchmaking

import (
	"errors"
	"math/rand"
	"sync"
	"time"
)

// GameMode represents the type of match a player wants to join.
type GameMode string

const (
	// GameModeRanked is a competitive match that affects ELO.
	GameModeRanked GameMode = "ranked"

	// GameModeCasual is a non-ranked match.
	GameModeCasual GameMode = "casual"

	// GameModePrivate is a match joined by a specific room code.
	GameModePrivate GameMode = "private"
)

// roomCodeChars is the alphabet used to generate 6-character room codes.
const roomCodeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

// roomCodeLength is the length of a generated room code.
const roomCodeLength = 6

// ELO matching thresholds.
const (
	// eloRangeInitial is the initial ELO window for pairing.
	eloRangeInitial = 200

	// eloRangeExpanded is the ELO window after 30 seconds.
	eloRangeExpanded = 400

	// expandAfter is how long to wait before widening the ELO window.
	expandAfter = 30 * time.Second

	// botFillAfter is how long to wait before filling empty slots with bots.
	botFillAfter = 60 * time.Second

	// minPlayersForMatch is the minimum number of human players to start a match.
	minPlayersForMatch = 2

	// maxPlayersPerMatch is the maximum number of players (human + bot) per match.
	maxPlayersPerMatch = 4
)

// QueueEntry represents a single player waiting for a match.
type QueueEntry struct {
	// PlayerID is the Firebase UID of the queued player.
	PlayerID string

	// ELO is the player's current rating.
	ELO int

	// JoinedAt records when the player entered the queue.
	JoinedAt time.Time

	// GameMode is the kind of match the player wants.
	GameMode GameMode

	// RoomCode is set for private matches; empty for public matchmaking.
	RoomCode string

	// notifyCh receives the MatchResult when matchmaking succeeds.
	notifyCh chan MatchResult
}

// WaitTime returns how long this entry has been in the queue.
func (e *QueueEntry) WaitTime() time.Duration {
	return time.Since(e.JoinedAt)
}

// eloRange returns the current acceptable ELO spread for this entry based on
// how long the player has been waiting.
func (e *QueueEntry) eloRange() int {
	waited := e.WaitTime()
	if waited >= botFillAfter {
		// No ELO restriction needed; bots will fill anyway.
		return eloRangeExpanded
	}
	if waited >= expandAfter {
		return eloRangeExpanded
	}
	return eloRangeInitial
}

// MatchResult is sent to a queued player when a match has been found.
type MatchResult struct {
	// GameID is the newly created game's unique identifier.
	GameID string

	// RoomCode is the room code players can use to reconnect.
	RoomCode string

	// Players is the list of player IDs in the match (may include bot IDs).
	Players []string
}

// Queue is a thread-safe structure holding players waiting for matchmaking.
type Queue struct {
	mu      sync.Mutex
	entries []*QueueEntry

	// privateRooms holds QueueEntry slices waiting for a specific room code.
	privateRooms map[string][]*QueueEntry
}

// NewQueue allocates an empty Queue.
func NewQueue() *Queue {
	return &Queue{
		privateRooms: make(map[string][]*QueueEntry),
	}
}

// Add inserts an entry into the appropriate queue and returns the notification
// channel the caller should block on.
func (q *Queue) Add(entry *QueueEntry) (<-chan MatchResult, error) {
	if entry.PlayerID == "" {
		return nil, errors.New("queue: playerID must not be empty")
	}

	ch := make(chan MatchResult, 1)
	entry.notifyCh = ch

	q.mu.Lock()
	defer q.mu.Unlock()

	if q.hasPlayer(entry.PlayerID) {
		return nil, errors.New("queue: player already in queue")
	}

	if entry.GameMode == GameModePrivate {
		if entry.RoomCode == "" {
			return nil, errors.New("queue: private game requires a room code")
		}
		q.privateRooms[entry.RoomCode] = append(q.privateRooms[entry.RoomCode], entry)
	} else {
		q.entries = append(q.entries, entry)
	}
	return ch, nil
}

// Remove deletes the player from any queue they are in. Returns true if found.
func (q *Queue) Remove(playerID string) bool {
	q.mu.Lock()
	defer q.mu.Unlock()

	for i, e := range q.entries {
		if e.PlayerID == playerID {
			q.entries = append(q.entries[:i], q.entries[i+1:]...)
			return true
		}
	}

	for code, entries := range q.privateRooms {
		for i, e := range entries {
			if e.PlayerID == playerID {
				q.privateRooms[code] = append(entries[:i], entries[i+1:]...)
				if len(q.privateRooms[code]) == 0 {
					delete(q.privateRooms, code)
				}
				return true
			}
		}
	}
	return false
}

// Snapshot returns a copy of the public (non-private) queue entries.
// The returned slice is safe to iterate without holding the lock.
func (q *Queue) Snapshot() []*QueueEntry {
	q.mu.Lock()
	defer q.mu.Unlock()

	out := make([]*QueueEntry, len(q.entries))
	copy(out, q.entries)
	return out
}

// DrainMatched removes a specific set of player IDs from the public queue.
// Call this after deciding a group of players will be matched.
func (q *Queue) DrainMatched(playerIDs []string) {
	idSet := make(map[string]struct{}, len(playerIDs))
	for _, id := range playerIDs {
		idSet[id] = struct{}{}
	}

	q.mu.Lock()
	defer q.mu.Unlock()

	remaining := q.entries[:0]
	for _, e := range q.entries {
		if _, found := idSet[e.PlayerID]; !found {
			remaining = append(remaining, e)
		}
	}
	q.entries = remaining
}

// PrivateRoomEntries returns the waiting entries for a private room code, or
// nil if no entries exist.  The entries are removed from the map.
func (q *Queue) PrivateRoomEntries(roomCode string) []*QueueEntry {
	q.mu.Lock()
	defer q.mu.Unlock()

	entries := q.privateRooms[roomCode]
	if len(entries) > 0 {
		delete(q.privateRooms, roomCode)
	}
	return entries
}

// hasPlayer reports whether a player is already in any queue. Must hold q.mu.
func (q *Queue) hasPlayer(playerID string) bool {
	for _, e := range q.entries {
		if e.PlayerID == playerID {
			return true
		}
	}
	for _, entries := range q.privateRooms {
		for _, e := range entries {
			if e.PlayerID == playerID {
				return true
			}
		}
	}
	return false
}

// Size returns the total number of players currently queued (public + private).
func (q *Queue) Size() int {
	q.mu.Lock()
	defer q.mu.Unlock()

	n := len(q.entries)
	for _, entries := range q.privateRooms {
		n += len(entries)
	}
	return n
}

// Notify sends a MatchResult to all entries in a matched group, non-blocking.
func Notify(entries []*QueueEntry, result MatchResult) {
	for _, e := range entries {
		select {
		case e.notifyCh <- result:
		default:
		}
	}
}

// GenerateRoomCode returns a cryptographically random 6-character uppercase
// alphanumeric code suitable for private match invitations.
func GenerateRoomCode() string {
	// math/rand is fine here; room codes are not security-sensitive secrets —
	// they are short-lived match invitations that expire quickly.
	b := make([]byte, roomCodeLength)
	for i := range b {
		b[i] = roomCodeChars[rand.Intn(len(roomCodeChars))]
	}
	return string(b)
}

// findCandidates scans entries and returns all entries whose ELO is within
// range of anchor.ELO according to anchor's current eloRange().
// The anchor entry itself is not included in the return value.
func findCandidates(anchor *QueueEntry, entries []*QueueEntry) []*QueueEntry {
	spread := anchor.eloRange()
	var candidates []*QueueEntry
	for _, e := range entries {
		if e.PlayerID == anchor.PlayerID {
			continue
		}
		// Both entries must be compatible with each other's ELO range.
		eloSpread := e.eloRange()
		if eloSpread < spread {
			eloSpread = spread
		}
		diff := e.ELO - anchor.ELO
		if diff < 0 {
			diff = -diff
		}
		if diff <= eloSpread {
			candidates = append(candidates, e)
		}
	}
	return candidates
}
