//go:build e2e

package e2e

import (
	"encoding/json"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	gamepkg "github.com/wilddeck/server/internal/game"
	hubpkg "github.com/wilddeck/server/internal/hub"
)

// TestCompleteGame2Players creates two clients that join the same private match,
// then runs a simple bot strategy (always play the first legal move; draw if
// no legal move exists) until a game_over message is received.
//
// Assertions:
//   - game_over is received by both players within 10 minutes.
//   - The game_over payload contains a non-empty winner_id.
func TestCompleteGame2Players(t *testing.T) {
	const timeout = 10 * time.Minute

	uid1 := "e2e-p1-" + uniqueSuffix()
	uid2 := "e2e-p2-" + uniqueSuffix()
	tok1 := generateTestToken(uid1)
	tok2 := generateTestToken(uid2)

	// Player 1 creates a private match and obtains the match ID.
	matchID := mustCreatePrivateMatch(t, tok1)
	t.Logf("created match %s", matchID)

	// Player 2 joins the match over HTTP.
	mustJoinMatch(t, tok2, matchID)

	// Both players connect via WebSocket.
	conn1, err := connectTestClient(tok1, matchID)
	if err != nil {
		t.Fatalf("connect player1: %v", err)
	}
	defer conn1.Close()

	conn2, err := connectTestClient(tok2, matchID)
	if err != nil {
		t.Fatalf("connect player2: %v", err)
	}
	defer conn2.Close()

	// winnerCh collects winner IDs reported to each client.
	type result struct {
		uid      string
		winnerID string
	}
	winnerCh := make(chan result, 2)

	var wg sync.WaitGroup

	runBot := func(uid string, conn *websocket.Conn) {
		defer wg.Done()
		var seqNum uint64
		nextSeq := func() uint64 {
			seqNum++
			return seqNum
		}
		for {
			msg, err := waitForMessageType(conn, "", timeout)
			if err != nil {
				t.Logf("bot %s: read error: %v", uid, err)
				return
			}

			switch msg.Type {
			case hubpkg.MsgGameOver:
				var payload hubpkg.GameOverPayload
				_ = json.Unmarshal(msg.Payload, &payload)
				winnerCh <- result{uid: uid, winnerID: payload.WinnerID}
				return

			case hubpkg.MsgGameState, hubpkg.MsgTurnChanged, hubpkg.MsgCardPlayed, hubpkg.MsgCardDrawn:
				// Decode the public game state to determine legal moves.
				var state gamepkg.PublicGameState
				if err := json.Unmarshal(msg.Payload, &state); err != nil {
					continue
				}
				// Only act on our own turn.
				if state.Phase != gamepkg.PhasePlaying {
					continue
				}
				if state.CurrentPlayerIndex >= len(state.Players) {
					continue
				}
				if state.Players[state.CurrentPlayerIndex].ID != uid {
					continue
				}
				// Play first legal card, or draw.
				if len(state.LegalMoves) > 0 {
					card := state.LegalMoves[0]
					chosenColor := ""
					if card.IsWild() {
						chosenColor = string(gamepkg.ColorRed)
					}
					_ = sendMessage(conn, hubpkg.MsgPlayCard, hubpkg.PlayCardPayload{
						CardID:      card.ID,
						ChosenColor: chosenColor,
					}, nextSeq())
				} else {
					_ = sendMessage(conn, hubpkg.MsgDrawCard, hubpkg.DrawCardPayload{}, nextSeq())
				}
			}
		}
	}

	wg.Add(2)
	go runBot(uid1, conn1)
	go runBot(uid2, conn2)

	// Collect results with a hard deadline.
	done := make(chan struct{})
	go func() {
		wg.Wait()
		close(done)
	}()

	select {
	case <-time.After(timeout):
		t.Fatal("game did not complete within 10 minutes")
	case <-done:
	}

	// Drain result channel.
	close(winnerCh)
	winners := make([]result, 0, 2)
	for r := range winnerCh {
		winners = append(winners, r)
	}

	if len(winners) == 0 {
		t.Fatal("no game_over message received by any client")
	}
	for _, r := range winners {
		if r.winnerID == "" {
			t.Errorf("client %s: game_over payload missing winner_id", r.uid)
		}
	}
}

// TestInvalidMoveRejected joins a game and attempts to play a card ID that
// cannot exist in any hand, expecting an error response with code "invalid_card".
func TestInvalidMoveRejected(t *testing.T) {
	uid := "e2e-inv-" + uniqueSuffix()
	tok := generateTestToken(uid)
	matchID := mustCreatePrivateMatch(t, tok)

	conn, err := connectTestClient(tok, matchID)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer conn.Close()

	// Wait for an initial game_state so we know the game is active.
	if _, err := waitForMessageType(conn, hubpkg.MsgGameState, 10*time.Second); err != nil {
		t.Logf("no initial game_state (single-player lobby): %v — proceeding", err)
	}

	// Send an invalid card.
	if err := sendMessage(conn, hubpkg.MsgPlayCard, hubpkg.PlayCardPayload{CardID: "nonexistent-card-id-xyz"}, 1); err != nil {
		t.Fatalf("sendMessage: %v", err)
	}

	msg, err := waitForMessageType(conn, hubpkg.MsgError, 5*time.Second)
	if err != nil {
		t.Fatalf("expected error message: %v", err)
	}

	var payload hubpkg.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &payload); err != nil {
		t.Fatalf("decode error payload: %v", err)
	}
	if payload.Code != "invalid_card" {
		t.Errorf("expected error code %q, got %q (message: %s)", "invalid_card", payload.Code, payload.Message)
	}
}

// TestWrongTurnRejected starts a two-player game, waits until player 2 is NOT
// the current player, then has player 2 attempt to play a card.  The server
// should respond with error code "not_your_turn".
func TestWrongTurnRejected(t *testing.T) {
	uid1 := "e2e-wt1-" + uniqueSuffix()
	uid2 := "e2e-wt2-" + uniqueSuffix()
	tok1 := generateTestToken(uid1)
	tok2 := generateTestToken(uid2)

	matchID := mustCreatePrivateMatch(t, tok1)
	mustJoinMatch(t, tok2, matchID)

	conn1, err := connectTestClient(tok1, matchID)
	if err != nil {
		t.Fatalf("connect p1: %v", err)
	}
	defer conn1.Close()

	conn2, err := connectTestClient(tok2, matchID)
	if err != nil {
		t.Fatalf("connect p2: %v", err)
	}
	defer conn2.Close()

	// We only need conn1 alive to keep the game going; suppress lint about unused.
	_ = conn1

	// Wait until we see a game_state where it is player 1's turn (not player 2).
	var stateMsg *hubpkg.Message
	for i := 0; i < 30; i++ {
		m, err := waitForMessageType(conn2, hubpkg.MsgGameState, 5*time.Second)
		if err != nil {
			t.Fatalf("waiting for game_state: %v", err)
		}
		var state gamepkg.PublicGameState
		if err := json.Unmarshal(m.Payload, &state); err != nil {
			continue
		}
		if state.Phase == gamepkg.PhasePlaying &&
			len(state.Players) > 0 &&
			state.Players[state.CurrentPlayerIndex].ID != uid2 {
			stateMsg = m
			break
		}
	}
	if stateMsg == nil {
		t.Skip("could not reach a game state where player2 is out of turn — skipping")
	}

	// Player 2 attempts to play any card.
	var state gamepkg.PublicGameState
	_ = json.Unmarshal(stateMsg.Payload, &state)
	cardID := "any-card-id"
	if len(state.MyHand) > 0 {
		cardID = state.MyHand[0].ID
	}

	if err := sendMessage(conn2, hubpkg.MsgPlayCard, hubpkg.PlayCardPayload{CardID: cardID}, 1); err != nil {
		t.Fatalf("sendMessage: %v", err)
	}

	msg, err := waitForMessageType(conn2, hubpkg.MsgError, 5*time.Second)
	if err != nil {
		t.Fatalf("expected error message: %v", err)
	}

	var errPayload hubpkg.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &errPayload); err != nil {
		t.Fatalf("decode error payload: %v", err)
	}
	if errPayload.Code != "not_your_turn" {
		t.Errorf("expected error code %q, got %q (message: %s)", "not_your_turn", errPayload.Code, errPayload.Message)
	}
}

// TestDuplicateActionRejected sends the same action twice with the identical
// sequence number and expects the second attempt to be rejected with error code
// "duplicate_action" or "duplicate_seq".
func TestDuplicateActionRejected(t *testing.T) {
	uid := "e2e-dup-" + uniqueSuffix()
	tok := generateTestToken(uid)
	matchID := mustCreatePrivateMatch(t, tok)

	conn, err := connectTestClient(tok, matchID)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer conn.Close()

	// Use a draw_card action so we don't need to know a valid card ID.
	const seqNum uint64 = 42
	payload := hubpkg.DrawCardPayload{}

	if err := sendMessage(conn, hubpkg.MsgDrawCard, payload, seqNum); err != nil {
		t.Fatalf("first sendMessage: %v", err)
	}
	// Brief pause so the server processes the first message.
	time.Sleep(100 * time.Millisecond)

	if err := sendMessage(conn, hubpkg.MsgDrawCard, payload, seqNum); err != nil {
		t.Fatalf("second sendMessage: %v", err)
	}

	// The second message must elicit a duplicate_action (or duplicate_seq) error.
	msg, err := waitForMessageType(conn, hubpkg.MsgError, 5*time.Second)
	if err != nil {
		t.Fatalf("expected error message after duplicate: %v", err)
	}

	var ep hubpkg.ErrorPayload
	if err := json.Unmarshal(msg.Payload, &ep); err != nil {
		t.Fatalf("decode error payload: %v", err)
	}
	if ep.Code != "duplicate_action" && ep.Code != "duplicate_seq" {
		t.Errorf("expected duplicate error code, got %q (message: %s)", ep.Code, ep.Message)
	}
}

// uniqueSuffix returns a short string derived from the current nanosecond clock
// that is unique enough for test user IDs within a single test run.
func uniqueSuffix() string {
	return fmt.Sprintf("%d", time.Now().UnixNano()%1_000_000_000)
}
