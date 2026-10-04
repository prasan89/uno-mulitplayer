#!/bin/bash
# scripts/load_test.sh
#
# Wrapper script for running the UNO Multiplayer k6 load tests.
#
# Usage:
#   ./scripts/load_test.sh [WS_URL] [SCENARIO]
#
# Arguments:
#   WS_URL    - WebSocket base URL to test against.
#               Default: ws://localhost:8080
#               Example: ws://staging.uno-multiplayer.example.com
#
#   SCENARIO  - Name of a single k6 scenario to run (concurrent_matches,
#               ramp_players, spike).  Omit to run all scenarios.
#
# Environment variables (override positional args):
#   WS_URL          - Same as first positional argument.
#   AUTH_TOKEN      - JWT bearer token passed to every WebSocket upgrade.
#   K6_RESULTS_DIR  - Directory for output files.  Default: ./load_test_results
#
# Examples:
#   # Run all scenarios against localhost
#   ./scripts/load_test.sh
#
#   # Run only the spike scenario against staging
#   ./scripts/load_test.sh ws://staging.example.com spike
#
#   # Pass an auth token
#   AUTH_TOKEN=eyJ... ./scripts/load_test.sh ws://localhost:8080

set -euo pipefail

# ---------------------------------------------------------------------------
# Colour helpers (disabled when not a tty or NO_COLOR is set)
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Prerequisite checks
# ---------------------------------------------------------------------------

check_k6() {
  if ! command -v k6 &>/dev/null; then
    error "k6 is not installed or not in PATH."
    echo ""
    echo "  Install k6 >= 0.47:"
    echo "    macOS:   brew install k6"
    echo "    Linux:   https://k6.io/docs/get-started/installation/#linux"
    echo "    Docker:  docker run --rm grafana/k6 version"
    echo ""
    die "Aborting."
  fi

  local k6_version
  k6_version=$(k6 version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)
  if [[ -n "$k6_version" ]]; then
    local major minor
    major=$(echo "$k6_version" | cut -d. -f1)
    minor=$(echo "$k6_version" | cut -d. -f2)
    if (( major == 0 && minor < 47 )); then
      warn "k6 version ${k6_version} detected; >= 0.47 is recommended."
    else
      info "k6 version ${k6_version} found."
    fi
  fi
}

# ---------------------------------------------------------------------------
# Parse arguments / environment
# ---------------------------------------------------------------------------

POSITIONAL_WS_URL="${1:-}"
POSITIONAL_SCENARIO="${2:-}"

WS_URL="${WS_URL:-${POSITIONAL_WS_URL:-ws://localhost:8080}}"
SCENARIO="${SCENARIO:-${POSITIONAL_SCENARIO:-}}"
AUTH_TOKEN="${AUTH_TOKEN:-}"
K6_RESULTS_DIR="${K6_RESULTS_DIR:-./load_test_results}"

# Resolve the path to the test script relative to this script's location.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_SCRIPT="${REPO_ROOT}/load_tests/k6_websocket_test.js"

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

if [[ ! -f "$TEST_SCRIPT" ]]; then
  die "Test script not found: ${TEST_SCRIPT}"
fi

# Basic URL format check (ws:// or wss://).
if [[ ! "$WS_URL" =~ ^wss?:// ]]; then
  die "WS_URL must begin with ws:// or wss://, got: ${WS_URL}"
fi

# ---------------------------------------------------------------------------
# Prepare output directory
# ---------------------------------------------------------------------------

mkdir -p "$K6_RESULTS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="${K6_RESULTS_DIR}/load_test_${TIMESTAMP}.json"
SUMMARY_FILE="${K6_RESULTS_DIR}/load_test_${TIMESTAMP}_summary.txt"

# ---------------------------------------------------------------------------
# Print run plan
# ---------------------------------------------------------------------------

echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD} UNO Multiplayer — k6 Load Test Runner  ${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""
info "Target URL   : ${WS_URL}"
info "Scenario     : ${SCENARIO:-all}"
info "Results dir  : ${K6_RESULTS_DIR}"
info "JSON output  : ${RESULTS_FILE}"
if [[ -n "$AUTH_TOKEN" ]]; then
  info "Auth token   : (set)"
else
  warn "Auth token   : (not set — server must allow unauthenticated WS for dev)"
fi
echo ""

# ---------------------------------------------------------------------------
# Check prerequisites (after printing plan so the user sees what we intend)
# ---------------------------------------------------------------------------

check_k6

# ---------------------------------------------------------------------------
# Build the k6 command
# ---------------------------------------------------------------------------

K6_ARGS=(
  run
  --env "WS_URL=${WS_URL}"
  --out "json=${RESULTS_FILE}"
  --summary-export "${SUMMARY_FILE}"
)

# Pass auth token only when provided.
if [[ -n "$AUTH_TOKEN" ]]; then
  K6_ARGS+=(--env "AUTH_TOKEN=${AUTH_TOKEN}")
fi

# Restrict to a single scenario when requested.
if [[ -n "$SCENARIO" ]]; then
  valid_scenarios=("concurrent_matches" "ramp_players" "spike")
  found=false
  for s in "${valid_scenarios[@]}"; do
    [[ "$s" == "$SCENARIO" ]] && found=true && break
  done
  if [[ "$found" != "true" ]]; then
    die "Unknown scenario '${SCENARIO}'. Valid values: ${valid_scenarios[*]}"
  fi
  info "Restricting to scenario: ${SCENARIO}"
  # k6 allows filtering via --env; the test script's options object handles all
  # scenarios, but we can use k6's built-in --scenario flag (>= 0.47).
  K6_ARGS+=(--scenario "$SCENARIO")
fi

K6_ARGS+=("$TEST_SCRIPT")

# ---------------------------------------------------------------------------
# Run k6
# ---------------------------------------------------------------------------

info "Starting k6…"
echo ""

START_TIME=$(date +%s)

# Capture exit code without causing the script to abort (set -e is active).
set +e
k6 "${K6_ARGS[@]}"
K6_EXIT_CODE=$?
set -e

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

# ---------------------------------------------------------------------------
# Print summary
# ---------------------------------------------------------------------------

echo ""
echo -e "${BOLD}========================================${RESET}"
echo -e "${BOLD} Results Summary                        ${RESET}"
echo -e "${BOLD}========================================${RESET}"
echo ""
info "Elapsed time : ${ELAPSED}s"
info "JSON results : ${RESULTS_FILE}"
info "Text summary : ${SUMMARY_FILE}"

if [[ $K6_EXIT_CODE -eq 0 ]]; then
  success "All thresholds passed."
else
  error "One or more thresholds failed (k6 exit code: ${K6_EXIT_CODE})."
  echo ""
  echo "  Investigate:"
  echo "    1. Check ws_connection_errors rate in ${RESULTS_FILE}"
  echo "    2. Check game_action_latency p95 — target < 200 ms"
  echo "    3. Review server logs for goroutine/memory warnings"
  echo "    4. See LOAD_TEST.md for bottleneck identification guidance"
fi

echo ""

# Propagate k6's exit code so CI pipelines detect failures.
exit $K6_EXIT_CODE
