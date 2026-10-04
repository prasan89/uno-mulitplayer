#!/usr/bin/env bash
set -euo pipefail

# migrate.sh — Apply pending SQL migrations from db/migrations/ against $DATABASE_URL

DATABASE_URL="${DATABASE_URL:?DATABASE_URL must be set}"
MIGRATIONS_DIR="$(cd "$(dirname "$0")/../db/migrations" && pwd)"

log() { echo "[migrate] $*"; }

# Ensure psql is available
if ! command -v psql &>/dev/null; then
  echo "ERROR: psql not found in PATH" >&2
  exit 1
fi

# Ensure the schema_migrations tracking table exists
log "Ensuring schema_migrations table exists..."
psql "${DATABASE_URL}" <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version     TEXT PRIMARY KEY,
    applied_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SQL

# Collect migration files in lexicographic order
mapfile -t MIGRATION_FILES < <(find "${MIGRATIONS_DIR}" -maxdepth 1 -name '*.sql' | sort)

if [[ ${#MIGRATION_FILES[@]} -eq 0 ]]; then
  log "No migration files found in ${MIGRATIONS_DIR}."
  exit 0
fi

APPLIED=0
SKIPPED=0

for FILE in "${MIGRATION_FILES[@]}"; do
  VERSION="$(basename "${FILE}")"
  ALREADY_RAN="$(psql "${DATABASE_URL}" -tAc \
    "SELECT COUNT(*) FROM schema_migrations WHERE version = '${VERSION}';")"

  if [[ "${ALREADY_RAN}" -gt 0 ]]; then
    log "Skipping (already applied): ${VERSION}"
    SKIPPED=$(( SKIPPED + 1 ))
    continue
  fi

  log "Applying: ${VERSION}"
  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${FILE}"

  psql "${DATABASE_URL}" -c \
    "INSERT INTO schema_migrations (version) VALUES ('${VERSION}');"

  log "Applied: ${VERSION}"
  APPLIED=$(( APPLIED + 1 ))
done

log "Done. Applied: ${APPLIED}, Skipped: ${SKIPPED}."
