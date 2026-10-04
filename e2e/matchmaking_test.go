//go:build e2e

package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	gamepkg "github.com/wilddeck/server/internal/game"
	hubpkg "github.com/wilddeck/server/internal/hub"
)

// joinPublicQueue calls POST /api/match/queue for the given player and game mode.
// It returns a non-nil error on unexpected HTTP status codes.
func joinPublicQueue(token, gameMode string) error {
	body := strings.NewReader(`{"elo":1000,"game_mode":"` + gameMode + `"}`)
	req, err := http.NewRequest(http.MethodPost, serverURL+"/api/match/queue", body)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("joinPublicQueue: unexpected status %d", resp.StatusCode)
	}
	return nil
}

// TestMatchmakingConnects2Players puts two players into the public casual queue
// and asserts that both receive a game_state message within 10 seconds, meaning
// the matchmaking service paired them and started a game.
func TestMatchmakingConnects2Players(t *testing.T) {
	const timeout = 10 * time.Second

	uid1 := "e2e-mm1-" + uniqueSuffix()
	uid2 := "e2e-mm2-" + uniqueSuffix()
	tok1 := generateTestToken(uid1)
	tok2 := generateTestToken(uid2)

	if err := joinPublicQueue(tok1, "casual"); err != nil {
		t.Fatalf("player1 join queue: %v", err)
	}
	if err := joinPublicQueue(tok2, "casual"); err != nil {
		t.Fatalf("player2 join queue: %v", err)
	}

	// Poll the matchmaking result endpoint until both players are assigned a
	// game_id or the timeout elapses.  In lieu of a dedicated "await match" REST
	// endpoint we derive the game_id from the player_joined WebSocket push.
	//
	// For now, connect both players to the lobby WebSocket and wait for a
	// game_state broadcast from the matchmaker.  The server is expected to push
	// game_state once a match is formed.
	matchedCh := make(chan string, 2) // receives game IDs

	waitForMatch := func(uid, tok string) {
		// We don't know the game_id yet; connect to the "lobby" channel on
		// game_id="queue" to receive match notifications, then reconnect.
		// This is a best-effort approach — the actual handshake depends on
		// server implementation details.
		//
		// A more robust implementation would poll GET /api/match/status or use
		// the queue WebSocket feed.  Here we simulate the typical client flow:
		// connect to ws?game_id=queue, wait for a player_joined or game_state
		// message that includes a game_id, then report that.
		conn, err := connectTestClient(tok, "queue")
		if err != nil {
			t.Logf("uid=%s queue connect: %v — waiting via polling", uid, err)
			matchedCh <- ""
			return
		}
		defer conn.Close()

		msg, err := waitForMessageType(conn, hubpkg.MsgGameState, timeout)
		if err != nil {
			t.Logf("uid=%s timed out waiting for game_state: %v", uid, err)
			matchedCh <- ""
			return
		}

		var state gamepkg.PublicGameState
		if err := json.Unmarshal(msg.Payload, &state); err != nil {
			t.Logf("uid=%s decode game state: %v", uid, err)
			matchedCh <- ""
			return
		}
		matchedCh <- state.GameID
	}

	go waitForMatch(uid1, tok1)
	go waitForMatch(uid2, tok2)

	var matched int
	timer := time.NewTimer(timeout + 2*time.Second)
	defer timer.Stop()
	for matched < 2 {
		select {
		case gameID := <-matchedCh:
			if gameID == "" {
				t.Error("a player did not receive game_state from matchmaking")
			} else {
				t.Logf("player matched to game %s", gameID)
			}
			matched++
		case <-timer.C:
			t.Fatalf("timed out: only %d/2 players matched", matched)
		}
	}
}

// TestMatchmakingTimeout verifies that when a single player is in the queue and
// no opponent shows up within the matchmaking timeout (60 s), a bot is added
// and the game is started.  The lone player should receive a game_state message
// with at least two players (one of which is a bot).
func TestMatchmakingTimeout(t *testing.T) {
	if testing.Short() {
		t.Skip("TestMatchmakingTimeout skipped in short mode (requires ~65 s)")
	}

	const botFillTimeout = 65 * time.Second // matchmaking timeout + buffer

	uid := "e2e-mmt-" + uniqueSuffix()
	tok := generateTestToken(uid)

	if err := joinPublicQueue(tok, "casual"); err != nil {
		t.Fatalf("join queue: %v", err)
	}

	// Connect to the queue/lobby WebSocket feed.
	conn, err := connectTestClient(tok, "queue")
	if err != nil {
		t.Fatalf("connect to queue feed: %v", err)
	}
	defer conn.Close()

	t.Log("waiting up to 65 s for bot to fill the game...")
	msg, err := waitForMessageType(conn, hubpkg.MsgGameState, botFillTimeout)
	if err != nil {
		t.Fatalf("expected game_state after bot fill timeout: %v", err)
	}

	var state gamepkg.PublicGameState
	if err := json.Unmarshal(msg.Payload, &state); err != nil {
		t.Fatalf("decode game state: %v", err)
	}

	if len(state.Players) < 2 {
		t.Fatalf("expected at least 2 players after bot fill, got %d", len(state.Players))
	}

	var hasBot bool
	for _, p := range state.Players {
		if p.IsBot {
			hasBot = true
			break
		}
	}
	if !hasBot {
		t.Error("expected at least one bot player after matchmaking timeout")
	}
}
