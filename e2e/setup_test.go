//go:build e2e

package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"
	hubpkg "github.com/wilddeck/server/internal/hub"
)

// serverURL is the base URL of the running test server.
// Override via the E2E_SERVER_URL environment variable.
var serverURL string

// TestMain configures the test suite and initialises the shared server URL.
func TestMain(m *testing.M) {
	serverURL = os.Getenv("E2E_SERVER_URL")
	if serverURL == "" {
		serverURL = "http://localhost:8080"
	}
	os.Exit(m.Run())
}

// wsURL converts the HTTP base URL to a WebSocket URL (ws:// or wss://).
func wsURL(base, gameID string) string {
	if len(base) >= 5 && base[:5] == "https" {
		return "wss" + base[5:] + "/ws?game_id=" + gameID
	}
	if len(base) >= 4 && base[:4] == "http" {
		return "ws" + base[4:] + "/ws?game_id=" + gameID
	}
	return base + "/ws?game_id=" + gameID
}

// generateTestToken creates a self-signed HMAC-SHA256 JWT that the test server
// can verify when TEST_AUTH_SECRET is set in the environment (bypassing
// Firebase validation). The "sub" and "uid" claims are both set to uid.
//
// For a fully realistic E2E run the server must accept these tokens; the
// recommended approach is to expose a --test-mode flag on the server that
// swaps the Firebase verifier for a local HMAC verifier keyed by
// TEST_AUTH_SECRET.
func generateTestToken(uid string) string {
	secret := os.Getenv("TEST_AUTH_SECRET")
	if secret == "" {
		secret = "e2e-test-secret"
	}
	now := time.Now()
	claims := jwt.MapClaims{
		"sub": uid,
		"uid": uid,
		"iss": "e2e-test",
		"aud": jwt.ClaimStrings{"wilddeck"},
		"iat": now.Unix(),
		"exp": now.Add(2 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	// Use a deterministic kid so the server can look up the key.
	token.Header["kid"] = "e2e"
	signed, err := token.SignedString([]byte(secret))
	if err != nil {
		panic(fmt.Sprintf("generateTestToken: sign error: %v", err))
	}
	return signed
}

// connectTestClient dials the WebSocket endpoint for gameID using token for
// authentication. The caller is responsible for closing the returned *websocket.Conn.
func connectTestClient(token, gameID string) (*websocket.Conn, error) {
	header := http.Header{}
	header.Set("Authorization", "Bearer "+token)

	dialer := websocket.Dialer{
		HandshakeTimeout: 10 * time.Second,
	}
	conn, resp, err := dialer.Dial(wsURL(serverURL, gameID), header)
	if err != nil {
		if resp != nil {
			return nil, fmt.Errorf("dial %s: HTTP %d: %w", wsURL(serverURL, gameID), resp.StatusCode, err)
		}
		return nil, fmt.Errorf("dial %s: %w", wsURL(serverURL, gameID), err)
	}
	return conn, nil
}

// Message mirrors hub.Message so that e2e tests have a local type to decode into
// without importing the hub's internal package directly for JSON manipulation.
type Message = hubpkg.Message

// sendMessage encodes msgType + payload into a hub.Message envelope and writes
// it as a WebSocket text frame. seqNum may be 0 to omit sequence tracking.
func sendMessage(conn *websocket.Conn, msgType hubpkg.MessageType, payload interface{}, seqNum uint64) error {
	raw, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("sendMessage marshal payload: %w", err)
	}
	msg := hubpkg.Message{
		Type:    msgType,
		Payload: raw,
		SeqNum:  seqNum,
	}
	data, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("sendMessage marshal message: %w", err)
	}
	return conn.WriteMessage(websocket.TextMessage, data)
}

// readNextMessage reads a single WebSocket text frame and decodes it as a
// hub.Message. It returns an error if the read times out or fails.
func readNextMessage(conn *websocket.Conn) (*hubpkg.Message, error) {
	if err := conn.SetReadDeadline(time.Now().Add(15 * time.Second)); err != nil {
		return nil, err
	}
	_, raw, err := conn.ReadMessage()
	if err != nil {
		return nil, err
	}
	var msg hubpkg.Message
	if err := json.Unmarshal(raw, &msg); err != nil {
		return nil, fmt.Errorf("readNextMessage decode: %w", err)
	}
	return &msg, nil
}

// waitForMessageType reads messages until one with the desired type arrives, or
// until timeout elapses. Messages of other types are silently discarded.
func waitForMessageType(conn *websocket.Conn, msgType hubpkg.MessageType, timeout time.Duration) (*hubpkg.Message, error) {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		remaining := time.Until(deadline)
		if err := conn.SetReadDeadline(time.Now().Add(remaining)); err != nil {
			return nil, err
		}
		_, raw, err := conn.ReadMessage()
		if err != nil {
			return nil, fmt.Errorf("waitForMessageType(%s): %w", msgType, err)
		}
		var msg hubpkg.Message
		if err := json.Unmarshal(raw, &msg); err != nil {
			continue // skip malformed frames
		}
		// An empty msgType means "accept any message type".
		if msgType == "" || msg.Type == msgType {
			return &msg, nil
		}
	}
	return nil, fmt.Errorf("waitForMessageType: timed out waiting for %q", msgType)
}

// mustCreatePrivateMatch calls POST /api/match and returns the room code.
// It fails the test immediately on any error.
func mustCreatePrivateMatch(t *testing.T, token string) string {
	t.Helper()
	req, err := http.NewRequest(http.MethodPost, serverURL+"/api/match", http.NoBody)
	if err != nil {
		t.Fatalf("mustCreatePrivateMatch: new request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("mustCreatePrivateMatch: do request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("mustCreatePrivateMatch: unexpected status %d", resp.StatusCode)
	}
	var body struct {
		MatchID string `json:"match_id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatalf("mustCreatePrivateMatch: decode response: %v", err)
	}
	if body.MatchID == "" {
		t.Fatal("mustCreatePrivateMatch: empty match_id in response")
	}
	return body.MatchID
}

// mustJoinMatch calls POST /api/match/{id}/join and returns the ws_url hint.
func mustJoinMatch(t *testing.T, token, matchID string) {
	t.Helper()
	req, err := http.NewRequest(http.MethodPost, serverURL+"/api/match/"+matchID+"/join", http.NoBody)
	if err != nil {
		t.Fatalf("mustJoinMatch: new request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("mustJoinMatch: do request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusAccepted && resp.StatusCode != http.StatusCreated {
		t.Fatalf("mustJoinMatch: unexpected status %d", resp.StatusCode)
	}
}
