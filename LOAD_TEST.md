# UNO Multiplayer — Load Test Guide

## 1. Overview and Goals

This document describes the load testing strategy for the UNO Multiplayer backend.
The test suite is built with [k6](https://k6.io) and targets the WebSocket endpoint
(`/ws`) that drives all real-time game play.

### Primary goals

| Goal | Target |
|------|--------|
| Concurrent matches | 100 simultaneous 4-player matches (400 connected players) |
| Peak concurrent players | 500 connected WebSocket clients |
| Game-action p95 latency | < 200 ms (send action → receive next `game_state`) |
| WebSocket connection error rate | < 1 % |
| Matchmaking queue wait (p50) | < 5 s |

These numbers are derived from the expected player base at launch.  Re-evaluate
them whenever traffic projections change significantly.

---

## 2. Prerequisites

### 2.1 k6

Install k6 **>= 0.47** (required for the `--scenario` flag used by the runner script):

```bash
# macOS (Homebrew)
brew install k6

# Linux (Debian/Ubuntu)
sudo gpg -k
sudo gpg --no-default-keyring \
     --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
     --keyserver hkp://keyserver.ubuntu.com:80 \
     --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
     https://dl.k6.io/deb stable main" \
     | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6

# Docker (no installation required)
docker run --rm grafana/k6 version
```

Verify the install:

```bash
k6 version
# k6 v0.47.0 (go1.21.0, ...)
```

### 2.2 Running server

The backend must be reachable at the target URL before you start a test run.

```bash
# Local development (Docker Compose)
docker compose up -d

# Verify the health endpoint
curl -s http://localhost:8080/health
# {"status":"ok"}
```

### 2.3 Authentication tokens

The WebSocket endpoint (`/ws`) is protected by Firebase Auth middleware.  For
**local development** you can bypass auth by setting `FIREBASE_PROJECT_ID` to a
permissive value and commenting out the `authMW` middleware in
`backend/cmd/server/main.go`.

For **staging and production** runs you need a valid JWT for each virtual user.
Because k6 does not support dynamic per-VU Firebase token generation natively,
the recommended approach is to pre-mint a long-lived token (e.g., a custom token
via the Firebase Admin SDK) and pass it via `AUTH_TOKEN`:

```bash
AUTH_TOKEN=$(firebase-admin-sdk generate-token --uid load-test-player --ttl 1h)
export AUTH_TOKEN
```

All 400 VUs will share the same token.  The server will accept it as long as
it is valid; individual player identifiers are constructed from the VU number
(`load-test-player-<VU>`), so game state is still isolated per VU.

---

## 3. Test Scenarios

### 3.1 `concurrent_matches` — Steady-State Baseline

| Parameter | Value |
|-----------|-------|
| Executor | `constant-vus` |
| VUs | 400 |
| Duration | 5 minutes |

Simulates 100 simultaneous 4-player matches running at a constant concurrency.
VUs 1–4 share `load-test-game-0`, VUs 5–8 share `load-test-game-1`, and so on.

**Use for:** verifying that the server meets all SLA thresholds under
steady-state production load before and after code changes.

---

### 3.2 `ramp_players` — Capacity Discovery

| Stage | Duration | Target VUs |
|-------|----------|------------|
| Warm-up | 2 min | 0 → 100 |
| Moderate load | 3 min | 100 → 300 |
| High load | 3 min | 300 → 500 |
| Drain | 2 min | 500 → 0 |

Gradually increases load to discover the concurrency level at which error rates
or latency begin to degrade.

**Use for:** capacity planning before infrastructure changes; identifying the
server's practical concurrency ceiling.

---

### 3.3 `spike` — Resilience Under Sudden Load

| Stage | Duration | Target VUs |
|-------|----------|------------|
| Baseline | 1 min | 100 |
| Spike up | 30 s | 100 → 500 |
| Hold spike | 2 min | 500 |
| Ramp down | 30 s | 500 → 100 |
| Recovery | 1 min | 100 |

Validates that the server survives and recovers from a sudden traffic burst
without data loss or cascading failures.

**Use for:** pre-launch resilience testing; validating Kubernetes HPA or
other auto-scaling policies.

---

### 3.4 Additional Scenarios (not in default run)

- **`soak`** (defined in `load_tests/scenarios.js`): 200 VUs for 30 minutes.
  Used for detecting slow memory leaks or goroutine accumulation.
- **`reconnect_churn`**: 100 VUs rapidly cycling WebSocket connections to
  stress-test the reconnect grace-period logic in `hub.go`.

---

## 4. How to Run

### 4.1 Local development (all scenarios)

```bash
./scripts/load_test.sh
# Equivalent to:
./scripts/load_test.sh ws://localhost:8080
```

### 4.2 Single scenario

```bash
./scripts/load_test.sh ws://localhost:8080 spike
./scripts/load_test.sh ws://localhost:8080 concurrent_matches
./scripts/load_test.sh ws://localhost:8080 ramp_players
```

### 4.3 Against staging

```bash
AUTH_TOKEN="<staging-jwt>" \
  ./scripts/load_test.sh ws://staging.uno-multiplayer.example.com
```

### 4.4 Against production (read-only observation)

Run only `concurrent_matches` at a reduced VU count against production to
establish a real-traffic baseline without disrupting players:

```bash
AUTH_TOKEN="<prod-jwt>" \
  K6_RESULTS_DIR=./load_test_results/prod \
  k6 run \
    --env WS_URL=wss://api.uno-multiplayer.example.com \
    --env AUTH_TOKEN="$AUTH_TOKEN" \
    --scenario concurrent_matches \
    --vus 40 \
    --duration 2m \
    --out json=load_test_results/prod/baseline_$(date +%Y%m%d).json \
    load_tests/k6_websocket_test.js
```

### 4.5 Docker (no local k6 install)

```bash
docker run --rm \
  -v "$(pwd)":/app \
  -w /app \
  -e WS_URL=ws://host.docker.internal:8080 \
  grafana/k6 run load_tests/k6_websocket_test.js
```

---

## 5. Performance Targets

| Metric | Target | Critical Threshold | Notes |
|--------|--------|--------------------|-------|
| `ws_connection_errors` rate | < 0.1 % | > 1 % | WebSocket upgrade failures |
| `game_action_latency` p50 | < 50 ms | > 300 ms | Round-trip: send action → `game_state` |
| `game_action_latency` p95 | < 200 ms | > 500 ms | 95th-percentile latency |
| `game_action_latency` p99 | < 500 ms | > 1 000 ms | Long-tail latency |
| `matchmaking_wait_time` p50 | < 2 s | > 10 s | Queue wait for 4-player match |
| `matchmaking_wait_time` p95 | < 5 s | > 30 s | Slow-path matchmaking |
| `http_req_failed` rate | < 0.1 % | > 1 % | REST endpoint errors |
| `game_completions` total | > 10 | 0 | Sanity: games must reach `game_over` |

"Critical Threshold" is the k6 threshold at which a CI run is marked failed.
"Target" is the ideal value for a healthy production deployment.

---

## 6. How to Read k6 Output

### 6.1 Live console output

k6 prints a progress bar and a rolling summary to stdout during a run.  Key
fields to watch:

```
✓ ws_connection_errors.....: 0.00%  ✓ 0   ✗ 0
  game_action_latency.......: avg=42.1ms min=3ms  med=38ms  max=812ms p(90)=95ms p(95)=148ms
  game_completions..........: 47     0/s
  matchmaking_wait_time.....: avg=1.2s  min=0s   med=980ms max=8.4s  p(90)=3.1s p(95)=4.9s
```

### 6.2 JSON results file

The runner writes a line-delimited JSON file to
`load_test_results/load_test_<timestamp>.json`.  Each line is a k6 data point:

```jsonc
{
  "type": "Point",
  "metric": "game_action_latency",
  "data": { "time": "2026-10-04T12:00:01Z", "value": 42.1, "tags": { "scenario": "concurrent_matches" } }
}
```

Query the file with [jq](https://stedolan.github.io/jq/):

```bash
# p95 latency for the spike scenario
jq 'select(.metric=="game_action_latency") | .data.value' \
  load_test_results/load_test_*.json \
  | sort -n | awk 'BEGIN{c=0} {a[c++]=$1} END{print a[int(c*0.95)]}'
```

### 6.3 Summary export

The runner also writes a human-readable summary to
`load_test_results/load_test_<timestamp>_summary.txt`.  This file contains
the final aggregated metric values and pass/fail status for each threshold.

### 6.4 Grafana (optional)

Send metrics to a Grafana Cloud k6 account for interactive dashboards:

```bash
k6 run \
  --out cloud \
  --env WS_URL=ws://localhost:8080 \
  load_tests/k6_websocket_test.js
```

---

## 7. Common Bottlenecks and How to Identify Them

### 7.1 High `game_action_latency`

**Symptom:** p95 latency climbs above 200 ms, especially during the
`ramp_players` scenario.

**Likely causes:**

| Cause | How to confirm |
|-------|----------------|
| Hub event-loop goroutine blocking | Check `goroutines` in `/metrics` (Prometheus); look for spikes in `go_goroutines` or `hub_action_queue_depth` |
| Redis latency under concurrent reads | Run `redis-cli --latency-history` during the test; p99 > 10 ms is a warning sign |
| Database slow queries | Check `pg_stat_activity` for long-running queries; enable `log_min_duration_statement = 100` |
| WebSocket write buffer saturation | Look for `select { case c.Send <- data: default: }` drop logs in the server output |

**Mitigation:** Increase Hub channel buffer sizes in `hub.go`; add Redis
read replicas; optimise hot SQL queries; scale horizontally behind a load balancer.

---

### 7.2 Elevated `ws_connection_errors`

**Symptom:** error rate approaches or exceeds 1 %.

**Likely causes:**

| Cause | How to confirm |
|-------|----------------|
| File-descriptor limit | `ulimit -n` on the server; should be >= 65 536 for 500 players |
| Port exhaustion (load generator side) | Run `ss -s` on the k6 host; `TIME-WAIT` count should be < 30 000 |
| Gorilla/mux rate limiter rejecting connections | Look for HTTP 429 responses in the k6 output; default limit is 100 req/min/IP |
| TLS handshake timeout (wss://) | Increase `HandshakeTimeout` in `upgrader` config in `main.go` |

**Mitigation:** Tune OS limits (`sysctl net.core.somaxconn`); whitelist the
load-generator IP from rate limiting; distribute load across multiple k6
instances with different source IPs.

---

### 7.3 Long `matchmaking_wait_time`

**Symptom:** p50 queue wait exceeds 2 s during the `concurrent_matches` scenario.

**Likely causes:**

| Cause | How to confirm |
|-------|----------------|
| Matchmaking ticker too infrequent | Default is 5 s in `runMatchmaking`; check the ticker interval |
| ELO spread prevents fast pairing | Enable verbose matchmaking logs to count bracket mismatches |
| Only 4 × VU allocated per game ID | VUs 1–4 share `load-test-game-0`; if fewer VUs are active, the room never fills |

**Mitigation:** Reduce the matchmaking ticker interval; widen ELO brackets
for casual mode; use `expand_window` logic after N seconds in queue.

---

### 7.4 Low `game_completions`

**Symptom:** almost no `game_over` events are recorded despite high VU counts.

**Likely causes:**

- The test duration (5 min) is shorter than a typical game.
- The virtual players' `draw_card` bias means the deck empties before anyone wins.
- A bug in game-over detection on the server (check `engine.go` rules).

This is expected for short runs.  Use the `soak` scenario for completion metrics.

---

## 8. Scaling Recommendations Based on Results

After running all three scenarios, use the following decision matrix:

| Observation | Recommendation |
|-------------|----------------|
| p95 latency < 100 ms at 500 VUs | Current deployment is comfortably over-provisioned; scale down to reduce cost |
| p95 latency 100–200 ms at 500 VUs | Healthy; monitor weekly; consider adding a Redis read replica |
| p95 latency > 200 ms at 300 VUs | Add a second backend pod; implement hub sharding by game ID |
| p95 latency > 200 ms at 100 VUs | Investigate slow database queries or Redis latency immediately |
| WS error rate > 0.1 % at any load | Raise OS `ulimit`; check for TLS cert issues; verify rate-limiter config |
| Matchmaking wait > 5 s p95 | Reduce matchmaking ticker to 1 s; add ELO bracket relaxation |
| `game_completions` = 0 in soak run | Critical: investigate `engine.go` game-over logic |

### Horizontal scaling checklist

Before adding pods behind a load balancer:

1. Ensure the WebSocket upgrade uses sticky sessions (`session_affinity: ClientIP`
   in Kubernetes) or that Hub state is externalised to Redis.
2. The current `Hub` implementation is in-process; two pods cannot share game
   state.  Externalise `Hub` state to Redis pub/sub before scaling horizontally.
3. Update `ALLOWED_ORIGINS` and the `WS_URL` used in load tests to point to the
   load-balancer address rather than individual pod addresses.

---

## 9. Historical Baseline Comparison

Track performance over time by archiving the JSON results from each run.

### 9.1 Naming convention

Results are saved to:

```
load_test_results/
  load_test_<YYYYMMDD_HHMMSS>.json
  load_test_<YYYYMMDD_HHMMSS>_summary.txt
```

Commit the `_summary.txt` files (not the raw JSON) to the repository for a
lightweight change log:

```bash
git add load_test_results/*_summary.txt
git commit -m "chore: update load test baseline $(date +%Y-%m-%d)"
```

### 9.2 Automated comparison

Use the k6 summary export to extract key metrics and compare against a stored
baseline:

```bash
#!/bin/bash
# compare_baseline.sh — example comparison script
BASELINE="load_test_results/baseline.json"
CURRENT="load_test_results/$(ls -t load_test_results/*.json | head -1)"

for metric in game_action_latency matchmaking_wait_time; do
  baseline_p95=$(jq --arg m "$metric" \
    '[.[] | select(.metric==$m) | .data.value] | sort | .[(length*0.95|floor)]' \
    "$BASELINE")
  current_p95=$(jq --arg m "$metric" \
    '[.[] | select(.metric==$m) | .data.value] | sort | .[(length*0.95|floor)]' \
    "$CURRENT")
  echo "${metric} p95: baseline=${baseline_p95}ms  current=${current_p95}ms"
done
```

### 9.3 Regression gate in CI

Add this step to your CI pipeline to fail on performance regressions:

```yaml
# .github/workflows/load-test.yml
- name: Run load test (spike scenario, staging)
  run: |
    AUTH_TOKEN="${{ secrets.STAGING_LOAD_TEST_TOKEN }}" \
      ./scripts/load_test.sh wss://staging.uno-multiplayer.example.com spike
  # k6 exits non-zero when thresholds fail; CI step inherits the exit code.
```

Store the `_summary.txt` artefact so you can compare across PR runs:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: load-test-results
    path: load_test_results/
```

---

## File Reference

| File | Purpose |
|------|---------|
| `load_tests/k6_websocket_test.js` | Main k6 test: metrics, options, VU function |
| `load_tests/scenarios.js` | Reusable scenario and threshold exports |
| `scripts/load_test.sh` | Shell wrapper: prerequisite checks, argument parsing, k6 invocation |
| `load_test_results/` | Output directory (created on first run; gitignored for JSON, keep summaries) |
