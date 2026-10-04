/**
 * k6 WebSocket load test for the WildDeck server.
 *
 * Usage:
 *   k6 run --env WS_URL=ws://localhost:8080 load_tests/k6_websocket_test.js
 *
 * Environment variables:
 *   WS_URL   - WebSocket base URL, e.g. ws://localhost:8080  (default: ws://localhost:8080)
 *   AUTH_TOKEN - Bearer token for the Authorization header   (optional; omit to bypass auth in dev)
 */

import ws from 'k6/ws';
import { Rate, Trend, Counter } from 'k6/metrics';
import { check, sleep } from 'k6';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

// ---------------------------------------------------------------------------
// Custom metrics
// ---------------------------------------------------------------------------

/** Rate of WebSocket connection errors relative to total connection attempts. */
const wsConnectionErrors = new Rate('ws_connection_errors');

/** Latency (ms) from sending a game action to receiving the next game_state. */
const gameActionLatency = new Trend('game_action_latency', true);

/** Total number of completed games (game_over message received). */
const gameCompletions = new Counter('game_completions');

/** Time (ms) a virtual player spends in the matchmaking queue before a game starts. */
const matchmakingWaitTime = new Trend('matchmaking_wait_time', true);

// ---------------------------------------------------------------------------
// Test configuration
// ---------------------------------------------------------------------------

export const options = {
  scenarios: {
    /**
     * concurrent_matches
     * Simulates 100 simultaneous WildDeck matches, each with 4 players (400 VUs).
     * Steady-state duration: 5 minutes.
     */
    concurrent_matches: {
      executor: 'constant-vus',
      vus: 400,
      duration: '5m',
      tags: { scenario: 'concurrent_matches' },
    },

    /**
     * ramp_players
     * Gradually increases concurrent players to find the point at which latency
     * or error rate degrades.  Runs for 10 minutes.
     */
    ramp_players: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '3m', target: 300 },
        { duration: '3m', target: 500 },
        { duration: '2m', target: 0 },
      ],
      tags: { scenario: 'ramp_players' },
    },

    /**
     * spike
     * Validates that the server recovers gracefully from a sudden traffic spike.
     * Baseline 100 VUs, spike to 500 for 2 minutes, then return to baseline.
     */
    spike: {
      executor: 'ramping-vus',
      startVUs: 100,
      stages: [
        { duration: '1m', target: 100 },   // warm-up at baseline
        { duration: '30s', target: 500 },  // rapid spike up
        { duration: '2m', target: 500 },   // hold spike
        { duration: '30s', target: 100 },  // rapid ramp down
        { duration: '1m', target: 100 },   // settle at baseline
      ],
      tags: { scenario: 'spike' },
    },
  },

  thresholds: {
    /** Less than 1 % of WebSocket connections may fail. */
    ws_connection_errors: [{ threshold: 'rate<0.01', abortOnFail: false }],

    /** 95th-percentile game action round-trip must be under 200 ms. */
    game_action_latency: [{ threshold: 'p(95)<200', abortOnFail: false }],

    /** Less than 1 % of HTTP requests (health / queue endpoints) may fail. */
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: false }],
  },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Returns the target WebSocket URL, including the game_id query parameter.
 *
 * @param {string} gameID - The UUID of the game/room to join.
 * @returns {string} Fully qualified ws:// URL.
 */
function buildWsUrl(gameID) {
  const base = __ENV.WS_URL || 'ws://localhost:8080';
  // Strip a trailing slash so we never get double-slash.
  return `${base.replace(/\/$/, '')}/ws?game_id=${gameID}`;
}

/**
 * Builds the HTTP headers used for every WebSocket upgrade request.
 * The AUTH_TOKEN env var is optional; in development the server may skip auth.
 *
 * @returns {Object} Headers object suitable for ws.connect().
 */
function buildHeaders() {
  const headers = { 'Content-Type': 'application/json' };
  if (__ENV.AUTH_TOKEN) {
    headers['Authorization'] = `Bearer ${__ENV.AUTH_TOKEN}`;
  }
  return headers;
}

/**
 * Assigns a virtual-player ID derived from the k6 VU number so that each
 * iteration is deterministically identifiable in the server logs.
 *
 * @returns {string} A stable player identifier string.
 */
function playerID() {
  return `load-test-player-${__VU}`;
}

/**
 * Returns a JSON-encoded game action message chosen randomly from the set of
 * valid client-to-server message types.
 *
 * draw_card is weighted 3:1 over play_card because the virtual player has no
 * knowledge of its own hand and a draw is always safe, whereas attempting to
 * play a specific card will often result in a server-side "invalid action"
 * error that would mask real performance problems.
 *
 * @param {number} seqNum - Incrementing sequence number for duplicate detection.
 * @returns {string} JSON string ready to send over the WebSocket.
 */
function playRandomMove(seqNum) {
  // Weighted action pool: draw_card appears 3 times, play_card once.
  const actions = [
    { type: 'draw_card', payload: {} },
    { type: 'draw_card', payload: {} },
    { type: 'draw_card', payload: {} },
    {
      type: 'play_card',
      payload: {
        card_id: `card-${Math.floor(Math.random() * 107)}`,
        chosen_color: ['red', 'blue', 'green', 'yellow'][Math.floor(Math.random() * 4)],
      },
    },
  ];
  const action = actions[Math.floor(Math.random() * actions.length)];
  return JSON.stringify({ type: action.type, payload: action.payload, seq_num: seqNum });
}

// ---------------------------------------------------------------------------
// Default scenario function (executed by every VU on every iteration)
// ---------------------------------------------------------------------------

/**
 * Each VU simulates one player:
 *   1. Connects to the WebSocket endpoint.
 *   2. Sends a join_queue message and records matchmaking wait time.
 *   3. On receiving game_state, waits 1 second then plays a random move.
 *   4. Tracks game_over events as completed games.
 *   5. Closes the connection after 5 minutes of activity.
 */
export default function () {
  // Each group of 4 consecutive VUs shares a game ID so they land in the
  // same room, simulating a full 4-player match.
  const matchIndex = Math.floor((__VU - 1) / 4);
  const gameID = `load-test-game-${matchIndex}`;
  const url = buildWsUrl(gameID);
  const headers = buildHeaders();
  const player = playerID();

  let actionSeqNum = 1;
  let actionSentAt = 0;
  let queueJoinedAt = 0;
  let gameStarted = false;
  let connected = false;

  // Maximum session duration: 5 minutes.
  const sessionDeadline = Date.now() + 5 * 60 * 1000;

  const res = ws.connect(url, { headers }, function (socket) {
    connected = true;

    // ---- Connection established ----
    socket.on('open', function () {
      // Record that the connection succeeded (no error).
      wsConnectionErrors.add(false);

      // Join the matchmaking queue.
      queueJoinedAt = Date.now();
      socket.send(
        JSON.stringify({
          type: 'join_game',
          payload: { game_id: gameID },
          seq_num: actionSeqNum++,
        })
      );
    });

    // ---- Inbound message handler ----
    socket.on('message', function (rawData) {
      let msg;
      try {
        msg = JSON.parse(rawData);
      } catch (_) {
        // Ignore non-JSON frames (e.g., ping/pong control frames as text).
        return;
      }

      switch (msg.type) {
        case 'game_state': {
          // The first game_state message means the match started.
          if (!gameStarted) {
            gameStarted = true;
            if (queueJoinedAt > 0) {
              matchmakingWaitTime.add(Date.now() - queueJoinedAt);
            }
          }

          // Track action round-trip latency if we sent an action previously.
          if (actionSentAt > 0) {
            gameActionLatency.add(Date.now() - actionSentAt);
            actionSentAt = 0;
          }

          // Simulate human "think time" before playing.
          sleep(1);

          // Only send actions if the session deadline has not passed.
          if (Date.now() < sessionDeadline) {
            const move = playRandomMove(actionSeqNum++);
            actionSentAt = Date.now();
            socket.send(move);
          } else {
            socket.close();
          }
          break;
        }

        case 'game_over': {
          gameCompletions.add(1);
          socket.close();
          break;
        }

        case 'error': {
          // Server-side validation errors are expected (e.g., play_card with an
          // invalid card ID).  Reset the sent-at timer so we do not skew latency
          // measurements.
          actionSentAt = 0;
          break;
        }

        case 'pong': {
          // No-op: keepalive round-trip handled by the server.
          break;
        }

        default:
          break;
      }
    });

    // ---- Error handler ----
    socket.on('error', function (e) {
      wsConnectionErrors.add(true);
      console.error(`[VU ${__VU}] WebSocket error: ${e.error()}`);
    });

    // ---- Close handler ----
    socket.on('close', function () {
      // Nothing to clean up; metrics are already recorded.
    });

    // Enforce maximum session duration with a periodic deadline check.
    socket.setInterval(function () {
      if (Date.now() >= sessionDeadline) {
        socket.close();
      }
    }, 10000); // check every 10 s
  });

  // Record a connection error if ws.connect itself failed (non-101 response).
  if (!connected) {
    wsConnectionErrors.add(true);
  }

  check(res, {
    'WebSocket connection established (101)': (r) => r && r.status === 101,
  });
}
