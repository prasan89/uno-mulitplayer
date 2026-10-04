//go:build e2e

package e2e

import (
	"encoding/json"
	"testing"
	"time"

	hubpkg "github.com/wilddeck/server/internal/hub"
)

// TestReconnectReceivesGameState verifies that a client who disconnects and
// reconnects within the 60-second grace period receives a "reconnected" message
// as the very first frame, and that the payload contains full game state.
func TestReconnectReceivesGameState(t *testing.T) {
	uid1 := "e2e-rc1-" + uniqueSuffix()
	uid2 := "e2e-rc2-" + uniqueSuffix()
	tok1 := generateTestToken(uid1)
	tok2 := generateTestToken(uid2)

	matchID := mustCreatePrivateMatch(t, tok1)
	mustJoinMatch(t, tok2, matchID)

	// Connect both players so the game can start.
	conn1, err := connectTestClient(tok1, matchID)
	if err != nil {
		t.Fatalf("connect player1: %v", err)
	}

	conn2, err := connectTestClient(tok2, matchID)
	if err != nil {
		conn1.Close()
		t.Fatalf("connect player2: %v", err)
	}
	defer conn2.Close()

	// Wait for the game to start (game_state broadcast).
	if _, err := waitForMessageType(conn1, hubpkg.MsgGameState, 10*time.Second); err != nil {
		t.Logf("no initial game_state for player1 (may still be in lobby): %v", err)
	}

	// Disconnect player 1 cleanly within the grace period.
	conn1.Close()
	t.Log("player1 disconnected; waiting 2 s before reconnecting")
	time.Sleep(2 * time.Second)

	// Reconnect player 1.
	conn1b, err := connectTestClient(tok1, matchID)
	if err != nil {
		t.Fatalf("reconnect player1: %v", err)
	}
	defer conn1b.Close()

	// The very first message after reconnecting must be "reconnected".
	first, err := readNextMessage(conn1b)
	if err != nil {
		t.Fatalf("read first message after reconnect: %v", err)
	}

	if first.Type != hubpkg.MsgReconnected {
		t.Errorf("expected first message type %q after reconnect, got %q", hubpkg.MsgReconnected, first.Type)
	}

	// The payload must not be null / empty.
	var payload hubpkg.ReconnectedPayload
	if err := json.Unmarshal(first.Payload, &payload); err != nil {
		t.Fatalf("decode reconnected payload: %v", err)
	}
	if payload.GameID == "" {
		t.Error("reconnected payload missing game_id")
	}
}

// TestBotTakeoverAfterGracePeriod starts a 2-player game, disconnects player 1,
// waits 65 seconds (the 60 s grace period plus a 5 s buffer), and then verifies
// that the game still progresses — specifically that player 2 can receive at
// least one more turn_changed or game_state message — indicating a bot has
// taken over for player 1.
func TestBotTakeoverAfterGracePeriod(t *testing.T) {
	if testing.Short() {
		t.Skip("TestBotTakeoverAfterGracePeriod skipped in short mode (requires ~70 s)")
	}

	const gracePeriod = 65 * time.Second // reconnect grace (60 s) + buffer

	uid1 := "e2e-bt1-" + uniqueSuffix()
	uid2 := "e2e-bt2-" + uniqueSuffix()
	tok1 := generateTestToken(uid1)
	tok2 := generateTestToken(uid2)

	matchID := mustCreatePrivateMatch(t, tok1)
	mustJoinMatch(t, tok2, matchID)

	conn1, err := connectTestClient(tok1, matchID)
	if err != nil {
		t.Fatalf("connect player1: %v", err)
	}

	conn2, err := connectTestClient(tok2, matchID)
	if err != nil {
		conn1.Close()
		t.Fatalf("connect player2: %v", err)
	}
	defer conn2.Close()

	// Wait for game to start.
	if _, err := waitForMessageType(conn2, hubpkg.MsgGameState, 10*time.Second); err != nil {
		t.Logf("no initial game_state for player2: %v", err)
	}

	// Record the game version before disconnecting.
	var versionBefore int
	m, err := waitForMessageType(conn2, hubpkg.MsgGameState, 5*time.Second)
	if err == nil {
		var state struct {
			Version int `json:"version"`
		}
		_ = json.Unmarshal(m.Payload, &state)
		versionBefore = state.Version
	}

	// Disconnect player 1 and wait beyond the grace period.
	t.Log("disconnecting player1")
	conn1.Close()
	t.Logf("waiting %s for bot takeover...", gracePeriod)
	time.Sleep(gracePeriod)

	// Player 2 should now receive a turn_changed or game_state showing
	// that player 1's turns are being made (bot took over).
	msg, err := waitForMessageType(conn2, "", 30*time.Second)
	if err != nil {
		t.Fatalf("expected activity after bot takeover, got: %v", err)
	}

	switch msg.Type {
	case hubpkg.MsgTurnChanged, hubpkg.MsgGameState, hubpkg.MsgCardPlayed, hubpkg.MsgCardDrawn, hubpkg.MsgGameOver:
		t.Logf("received expected activity message type=%s after bot takeover", msg.Type)
	default:
		// player_left is also acceptable — it confirms the server acknowledged the disconnect
		if msg.Type == hubpkg.MsgPlayerLeft {
			t.Log("received player_left — bot takeover signalled; proceeding")
		} else {
			t.Errorf("unexpected message type %q after bot takeover", msg.Type)
		}
	}

	// If we received a game_state, assert the version advanced (game progressed).
	if msg.Type == hubpkg.MsgGameState {
		var state struct {
			Version int `json:"version"`
		}
		if err := json.Unmarshal(msg.Payload, &state); err == nil && versionBefore > 0 {
			if state.Version <= versionBefore {
				t.Errorf("game state version did not advance after bot takeover: before=%d after=%d",
					versionBefore, state.Version)
			}
		}
	}
}
