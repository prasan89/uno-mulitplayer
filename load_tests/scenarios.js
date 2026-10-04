/**
 * Reusable scenario configurations for the UNO Multiplayer load test suite.
 *
 * Import individual scenario objects or the complete scenarios map into your
 * k6 test scripts.
 *
 * Usage example:
 *   import { scenarios, thresholds } from './scenarios.js';
 *   export const options = { scenarios, thresholds };
 */

// ---------------------------------------------------------------------------
// Scenario definitions
// ---------------------------------------------------------------------------

/**
 * concurrent_matches
 *
 * Goal: validate steady-state behaviour at the target concurrency of
 * 100 simultaneous 4-player matches (400 VUs).
 *
 * When to use:
 *   - Baseline performance benchmarking before and after code changes.
 *   - SLA verification (all thresholds must stay green for the full 5 min).
 */
export const concurrentMatchesScenario = {
  executor: 'constant-vus',
  vus: 400,
  duration: '5m',
  tags: { scenario: 'concurrent_matches' },
  exec: 'default',
};

/**
 * ramp_players
 *
 * Goal: discover the load level at which the server's error rate or latency
 * begins to degrade (i.e., the practical concurrency ceiling).
 *
 * Stages:
 *   0 → 100 VUs  in 2 min  — gentle warm-up
 *   100 → 300 VUs in 3 min — moderate load
 *   300 → 500 VUs in 3 min — high load
 *   500 → 0 VUs   in 2 min — drain
 *
 * When to use:
 *   - Capacity planning before infrastructure changes.
 *   - Identifying the concurrency break point after server optimisations.
 */
export const rampPlayersScenario = {
  executor: 'ramping-vus',
  startVUs: 0,
  stages: [
    { duration: '2m', target: 100 },
    { duration: '3m', target: 300 },
    { duration: '3m', target: 500 },
    { duration: '2m', target: 0 },
  ],
  tags: { scenario: 'ramp_players' },
  exec: 'default',
};

/**
 * spike
 *
 * Goal: ensure the server survives and recovers from a sudden traffic burst
 * (e.g., a viral moment or a marketing event).
 *
 * Stages:
 *   100 VUs for 1 min   — stable baseline
 *   100 → 500 in 30 s   — rapid spike
 *   500 VUs for 2 min   — hold spike
 *   500 → 100 in 30 s   — rapid ramp-down
 *   100 VUs for 1 min   — verify recovery
 *
 * When to use:
 *   - Pre-launch resilience testing.
 *   - Validating auto-scaling policies.
 */
export const spikeScenario = {
  executor: 'ramping-vus',
  startVUs: 100,
  stages: [
    { duration: '1m',  target: 100 },
    { duration: '30s', target: 500 },
    { duration: '2m',  target: 500 },
    { duration: '30s', target: 100 },
    { duration: '1m',  target: 100 },
  ],
  tags: { scenario: 'spike' },
  exec: 'default',
};

/**
 * soak
 *
 * Goal: surface memory leaks, goroutine leaks, or slow resource exhaustion
 * that only appear after extended operation.
 *
 * Parameters:
 *   - 200 VUs (50 concurrent matches) for 30 minutes.
 *
 * When to use:
 *   - Weekly regression runs.
 *   - Before major releases.
 *
 * Note: this scenario is NOT included in the default export to keep the
 * standard test run to a manageable duration.  Enable it explicitly when needed.
 */
export const soakScenario = {
  executor: 'constant-vus',
  vus: 200,
  duration: '30m',
  tags: { scenario: 'soak' },
  exec: 'default',
};

/**
 * reconnect_churn
 *
 * Goal: stress-test the reconnect grace-period logic by rapidly cycling
 * connections.  Each VU connects, waits 5–15 seconds, disconnects, then
 * immediately reconnects.
 *
 * Parameters:
 *   - 100 VUs iterating as fast as their think-time allows.
 *   - Runs for 5 minutes.
 *
 * When to use:
 *   - After changes to hub.go reconnect handling.
 *   - Validating that stale disconnectedEntry cleanup does not leak memory.
 *
 * Note: requires a separate exec function (`reconnectVU`) to be exported from
 * the test script.
 */
export const reconnectChurnScenario = {
  executor: 'constant-vus',
  vus: 100,
  duration: '5m',
  tags: { scenario: 'reconnect_churn' },
  exec: 'reconnectVU',
};

// ---------------------------------------------------------------------------
// All production scenarios (default test run)
// ---------------------------------------------------------------------------

/**
 * Complete map of scenarios used by the default test run.
 * Import this into the test script as `options.scenarios`.
 */
export const scenarios = {
  concurrent_matches: concurrentMatchesScenario,
  ramp_players: rampPlayersScenario,
  spike: spikeScenario,
};

// ---------------------------------------------------------------------------
// Threshold definitions
// ---------------------------------------------------------------------------

/**
 * Performance thresholds that must hold across all scenarios.
 *
 * ws_connection_errors  — fewer than 1 % of WS upgrade attempts fail.
 * game_action_latency   — p95 round-trip (send → game_state) under 200 ms.
 * http_req_failed       — fewer than 1 % of REST calls fail.
 * game_completions      — at least 10 games complete per scenario run
 *                          (sanity check that VUs reach game_over).
 * matchmaking_wait_time — median queue wait under 5 seconds.
 */
export const thresholds = {
  ws_connection_errors:  [{ threshold: 'rate<0.01',    abortOnFail: false }],
  game_action_latency:   [{ threshold: 'p(95)<200',    abortOnFail: false }],
  http_req_failed:       [{ threshold: 'rate<0.01',    abortOnFail: false }],
  game_completions:      [{ threshold: 'count>10',     abortOnFail: false }],
  matchmaking_wait_time: [{ threshold: 'p(50)<5000',   abortOnFail: false }],
};

// ---------------------------------------------------------------------------
// Target constants (used in assertions / documentation)
// ---------------------------------------------------------------------------

export const targets = {
  /** Target number of simultaneous 4-player matches. */
  concurrentMatches: 100,

  /** Target number of simultaneous connected players. */
  concurrentPlayers: 500,

  /** Maximum acceptable p95 game-action latency in milliseconds. */
  p95LatencyMs: 200,

  /** Critical (hard-fail) p95 latency ceiling in milliseconds. */
  criticalLatencyMs: 500,

  /** Maximum acceptable WebSocket error rate (fraction, not percent). */
  maxWsErrorRate: 0.01,

  /** Maximum acceptable median matchmaking wait time in milliseconds. */
  maxMatchmakingWaitMs: 5000,
};
