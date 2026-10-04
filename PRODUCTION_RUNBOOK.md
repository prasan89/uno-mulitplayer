# UNO Multiplayer Production Runbook

> Last updated: 2026-10-04
> On-call rotation: check PagerDuty for current owner.
> Emergency escalation: ping #oncall-eng in Slack, or call the number in 1Password under "On-Call Escalation".

---

## 1. Architecture Overview

```
  Flutter Web / Mobile App
          |
          | HTTPS / WSS (port 443)
          v
  Cloud Run (uno-server)
  https://uno-server-<hash>-uc.a.run.app
  Internal container port: 8080 (HTTP/2 cleartext, h2c)
  Metrics port: 9090 (/metrics, Prometheus)
  Max concurrency per instance: 80
  Min instances: 1  |  Max instances: 10
  Request timeout: 300s (long-lived for WebSocket game sessions)
          |
          |-- PostgreSQL (Cloud SQL)
          |   Host: private IP via VPC connector
          |   Port: 5432
          |   Instance: uno-postgres-production (POSTGRES_15, REGIONAL HA)
          |   Database: uno
          |   User: uno
          |   Max connections: 100
          |   Backups: daily at 02:00 UTC, 7-day retention, PITR enabled
          |
          |-- Redis (Memorystore)
          |   Host: private IP via VPC connector
          |   Port: 6379
          |   Default memory: 1 GB
          |   Key pattern: game:<match_uuid>
          |
          `-- Firebase Auth
              Used for JWT verification (FIREBASE_PROJECT_ID env var)
              Firebase project: see FIREBASE_PROJECT_ID secret

Cloud Storage (Flutter web static hosting):
  https://storage.googleapis.com/<GCP_PROJECT_ID>-uno-web

VPC: private egress only for Cloud SQL and Redis (PRIVATE_RANGES_ONLY)
Region: us-central1 (default; check infra/variables.tf)
```

**Service URLs** — retrieve with:

```sh
gcloud run services describe uno-server --region us-central1 \
  --format 'value(status.url)'

# Cloud SQL connection name (for proxy / migrations):
gcloud sql instances describe uno-postgres-production \
  --format 'value(connectionName)'

# Redis host:
gcloud redis instances describe uno-redis-production \
  --region us-central1 --format 'value(host)'
```

---

## 2. SLA Targets

| Metric            | Target          | Alert threshold       |
|-------------------|-----------------|-----------------------|
| Uptime            | >= 99.9%        | < 99.9% over 30 days  |
| p50 latency       | < 50 ms         | > 75 ms sustained     |
| p95 latency       | < 200 ms        | > 300 ms sustained    |
| p99 latency       | < 500 ms        | > 500 ms sustained    |
| HTTP error rate   | < 0.1%          | > 0.1% over 5 min     |
| WebSocket drops   | < 1%            | > 2% over 5 min       |

Prometheus metric names to use in alerts:

- `http_request_duration_seconds` (histogram) — latency SLOs
- `http_requests_total{status=~"5.."}` / `http_requests_total` — error rate
- `ws_connections_active` — websocket health
- `db_query_duration_seconds` — DB latency

---

## 3. Deployment

### 3.1 Prerequisites

Ensure the following environment variables are set in your shell (or CI environment):

| Variable               | Description                                              | Example                                      |
|------------------------|----------------------------------------------------------|----------------------------------------------|
| `GCP_PROJECT_ID`       | **Required.** GCP project ID                             | `uno-multiplayer-prod`                       |
| `CLOUD_RUN_REGION`     | Cloud Run region (default: `us-central1`)                | `us-central1`                                |
| `CLOUD_RUN_SERVICE`    | Cloud Run service name (default: `uno-server`)           | `uno-server`                                 |
| `GCR_REPO`             | GCR image repository (default: `gcr.io/$GCP_PROJECT_ID/uno-server`) | `gcr.io/uno-multiplayer-prod/uno-server` |
| `CLOUD_SQL_INSTANCE`   | Cloud SQL connection name for migration proxy            | `uno-multiplayer-prod:us-central1:uno-postgres-production` |
| `DATABASE_URL`         | PostgreSQL connection URL (used by migrate.sh)           | `postgres://uno:PASSWORD@127.0.0.1:5432/uno` |

Application runtime secrets are injected via Secret Manager — do **not** set them as plain environment variables in Cloud Run:

| Secret Manager ID  | Cloud Run env var  | Description               |
|--------------------|--------------------|---------------------------|
| `database-url`     | `DATABASE_URL`     | PostgreSQL connection URL |
| `redis-url`        | `REDIS_URL`        | Redis connection URL      |
| `jwt-secret`       | `JWT_SECRET`       | JWT signing secret        |

To update a secret value:

```sh
echo -n "new-value" | gcloud secrets versions add database-url --data-file=-
```

### 3.2 Deploy Steps

```sh
# 1. Authenticate Docker with GCR (one-time or after token expiry)
gcloud auth configure-docker

# 2. Set required variables
export GCP_PROJECT_ID=uno-multiplayer-prod
export CLOUD_SQL_INSTANCE=uno-multiplayer-prod:us-central1:uno-postgres-production
export DATABASE_URL="postgres://uno:PASSWORD@127.0.0.1:5432/uno"

# 3. Run the deploy script (build -> push -> migrate -> deploy -> health-check)
./scripts/deploy.sh
```

The script automatically:
1. Builds and pushes the Docker image tagged with the git SHA.
2. Runs pending SQL migrations via Cloud SQL Auth Proxy.
3. Captures the current revision for rollback.
4. Deploys the new image to Cloud Run.
5. Health-checks `GET /health` up to 10 times (5 s apart). Auto-rolls back on failure.

### 3.3 Rollback Procedure

**Option A — Automatic rollback** (handled by `deploy.sh` if health check fails)

**Option B — Manual traffic rollback to a specific revision**

```sh
# List revisions to find the last known-good one
gcloud run revisions list --service uno-server --region us-central1

# Roll 100% traffic back to that revision
gcloud run services update-traffic uno-server \
  --region us-central1 \
  --to-revisions=REVISION_ID=100

# Verify
gcloud run services describe uno-server --region us-central1 \
  --format 'value(status.traffic)'
```

Replace `REVISION_ID` with the actual revision name, e.g. `uno-server-00042-xyz`.

### 3.4 Migration Rollback

Migrations are applied by `scripts/migrate.sh` and tracked in the `schema_migrations` table. There are no automatic down migrations; to roll back a schema change:

```sh
# Connect to Cloud SQL via proxy
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

# Write and apply a compensating migration manually
psql "$DATABASE_URL" -f db/migrations/003_rollback_xyz.sql

# Record the rollback in schema_migrations if the file was never registered
psql "$DATABASE_URL" -c \
  "INSERT INTO schema_migrations(version) VALUES ('003_rollback_xyz.sql');"

kill %1  # stop proxy
```

---

## 4. Health Monitoring

### 4.1 Health Check

```sh
# Retrieve service URL
SERVICE_URL=$(gcloud run services describe uno-server --region us-central1 \
  --format 'value(status.url)')

# Check health (expects HTTP 200 with {"status":"ok"})
curl -s "${SERVICE_URL}/health" | jq .

# Full dependency health (database + redis + websocket counts)
curl -s "${SERVICE_URL}/health" | jq '.checks'
# Returns: {"database":{"status":"healthy","latency_ms":3}, "redis":{"status":"healthy","latency_ms":1}, "websocket":{"status":"healthy","message":"active_connections=42"}}
# HTTP 200 = healthy; HTTP 503 = degraded or unhealthy
```

### 4.2 Key Prometheus Metrics

Scrape endpoint: `GET /metrics` on port 9090 (or port 8080 in the default config).

| Metric                              | Labels                      | What to watch                     |
|-------------------------------------|-----------------------------|-----------------------------------|
| `http_requests_total`               | `method`, `path`, `status`  | Error rate (5xx / total)          |
| `http_request_duration_seconds`     | —                           | p50/p95/p99 latency               |
| `ws_connections_active`             | —                           | Active WebSocket sessions         |
| `games_active`                      | —                           | Live game count                   |
| `matchmaking_queue_size`            | `mode`                      | Queue buildup; should drain fast  |
| `db_query_duration_seconds`         | `operation`                 | Slow queries (p95 > 50 ms alert)  |
| `db_connections_active`             | —                           | Pool exhaustion (max 100)         |
| `db_errors_total`                   | `operation`                 | Database error rate               |
| `cache_hits_total` / `cache_misses_total` | `key_type`            | Cache hit ratio                   |
| `cache_operation_seconds`           | `operation`                 | Redis latency                     |
| `bot_takeovers_active`              | —                           | Players replaced by bots          |

### 4.3 Grafana Dashboard Setup

```sh
# Port-forward Grafana if running in-cluster (or use GCP Managed Prometheus)
kubectl port-forward svc/grafana 3000:3000 -n monitoring   # adjust namespace

# Or for GCP Managed Service for Prometheus, open:
# https://console.cloud.google.com/monitoring/dashboards
```

Recommended panels:
1. **Request rate** — `rate(http_requests_total[5m])` grouped by status
2. **Latency heatmap** — `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`
3. **Active WebSockets** — `ws_connections_active`
4. **DB connection pool** — `db_connections_active` with threshold line at 90
5. **Matchmaking queue** — `matchmaking_queue_size` by mode
6. **Error rate** — `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])`

### 4.4 Alert Thresholds

| Alert                  | Query (PromQL)                                                                                          | Threshold      | Window |
|------------------------|--------------------------------------------------------------------------------------------------------|----------------|--------|
| High error rate        | `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])`                        | > 0.001 (0.1%) | 5 min  |
| High p95 latency       | `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`                             | > 0.3 s        | 5 min  |
| DB connections high    | `db_connections_active`                                                                                 | > 85           | 2 min  |
| Matchmaking queue stuck| `matchmaking_queue_size`                                                                                | > 50           | 2 min  |
| Health check failing   | Cloud Run uptime check on `GET /health` returns non-200                                                 | 2 failures     | —      |

---

## 5. Common Operations

### 5.1 Check Active Games

```sh
# Via Redis: list all game keys
redis-cli -h REDIS_HOST -p 6379 KEYS 'game:*'

# Count active games
redis-cli -h REDIS_HOST -p 6379 KEYS 'game:*' | wc -l

# Also check via Prometheus (no Redis access required)
curl -s "${SERVICE_URL}/metrics" | grep '^games_active'
```

Replace `REDIS_HOST` with the private IP from `gcloud redis instances describe`.

### 5.2 Force-End a Stuck Game

A game is "stuck" if its match row is in `playing` status but no heartbeat has come from the server, or the hub room is empty.

```sh
# 1. Connect via Cloud SQL proxy
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

# 2. Mark the match as abandoned in PostgreSQL (replace MATCH_UUID)
psql "$DATABASE_URL" -c \
  "UPDATE matches SET status='abandoned', abandoned_at=NOW(), updated_at=NOW() \
   WHERE id='MATCH_UUID';"

# 3. Remove the game state from Redis
redis-cli -h REDIS_HOST -p 6379 DEL 'game:MATCH_UUID'

# 4. Kill proxy
kill %1
```

### 5.3 Ban a Player

```sh
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

# Ban the player (replace PLAYER_ID and BAN_REASON)
psql "$DATABASE_URL" -c \
  "UPDATE players \
   SET is_banned=true, ban_reason='BAN_REASON', updated_at=NOW() \
   WHERE id='PLAYER_ID';"

kill %1
```

The player's Firebase JWT will still be valid until expiry, but game logic should check `is_banned` on match join. To immediately invalidate their session, revoke their Firebase tokens:

```sh
# Requires firebase-admin CLI or a custom admin endpoint
firebase auth:revoke-refresh-tokens PLAYER_ID
```

### 5.4 Scale Instances

```sh
# Scale to N minimum and M maximum instances
gcloud run services update uno-server \
  --region us-central1 \
  --min-instances N \
  --max-instances M

# Example: scale up for an expected spike
gcloud run services update uno-server \
  --region us-central1 \
  --min-instances 5 \
  --max-instances 20

# Return to defaults after the spike
gcloud run services update uno-server \
  --region us-central1 \
  --min-instances 1 \
  --max-instances 10
```

### 5.5 Flush Redis

> **DANGER**: `FLUSHDB` deletes ALL keys in the selected database.
> This will destroy all active game states. Every player in a live game will be disconnected and unable to resume. Only use as a last resort during a severe incident (e.g., Redis OOM with corrupted game state, or Redis compromise).

```sh
# Step 1: Confirm no games are actively in-progress or accept the disruption
redis-cli -h REDIS_HOST -p 6379 KEYS 'game:*' | wc -l  # how many games will be lost?

# Step 2: Optionally abandon them in PostgreSQL first (see section 5.2 for single games)
psql "$DATABASE_URL" -c \
  "UPDATE matches SET status='abandoned', abandoned_at=NOW() WHERE status='playing';"

# Step 3: Flush Redis (current DB only, not all DBs)
redis-cli -h REDIS_HOST -p 6379 FLUSHDB

# FLUSHALL would flush ALL Redis databases — do NOT use unless you understand all tenants
```

### 5.6 View Logs

```sh
# Last 100 Cloud Run log lines
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=uno-server" \
  --limit=100 \
  --order=desc \
  --format='table(timestamp,severity,textPayload)'

# Filter by severity (ERROR only)
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server AND severity>=ERROR' \
  --limit=50 --order=desc

# Filter by a specific match ID
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server AND jsonPayload.match_id="MATCH_UUID"' \
  --limit=50 --order=desc

# Tail live logs (streaming)
gcloud beta run services logs tail uno-server --region us-central1
```

---

## 6. Incident Playbooks

### 6a. Server Returning 5xx

**Detection**: alert fires on `http_requests_total{status=~"5.."}` > 0.1% error rate, or customer reports.

**Diagnosis**

```sh
# 1. Check recent error logs
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server AND severity>=ERROR' \
  --limit=50 --order=desc

# 2. Check current health
curl -s "${SERVICE_URL}/health" | jq .
# Look at "database" and "redis" check status

# 3. Check DB connectivity from a jump host or via Cloud SQL proxy
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &
psql "$DATABASE_URL" -c "SELECT 1;"
kill %1

# 4. Check Redis connectivity
redis-cli -h REDIS_HOST -p 6379 PING
# Expected: PONG

# 5. Check Cloud Run service status
gcloud run services describe uno-server --region us-central1 \
  --format 'table(status.conditions.type,status.conditions.status,status.conditions.message)'
```

**Mitigation**

- If DB is unreachable: see Playbook 6b.
- If Redis is unreachable: see Playbook 6c.
- If a bad deploy caused the 5xx: roll back (section 3.3).
- If instances are OOMing: scale up memory via a new deploy with `--memory 1Gi` flag.

**Resolution**: error rate drops below 0.1%, health check returns 200.

**Postmortem**: document root cause, timeline, customer impact, and preventive actions in the incident tracker.

---

### 6b. DB Connection Exhaustion

**Detection**: `db_connections_active` > 85, or PostgreSQL errors in logs: `FATAL: remaining connection slots are reserved`.

**Diagnosis**

```sh
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

# Check total connections by state and application
psql "$DATABASE_URL" -c \
  "SELECT state, application_name, COUNT(*) \
   FROM pg_stat_activity \
   GROUP BY state, application_name \
   ORDER BY count DESC;"

# Check max_connections setting
psql "$DATABASE_URL" -c "SHOW max_connections;"

# Identify idle connections older than 5 minutes (leak candidates)
psql "$DATABASE_URL" -c \
  "SELECT pid, usename, application_name, state, query_start, NOW() - query_start AS duration \
   FROM pg_stat_activity \
   WHERE state = 'idle' AND NOW() - query_start > interval '5 minutes' \
   ORDER BY duration DESC;"

kill %1
```

**Mitigation**

```sh
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

# Terminate idle connections (safe for idle, review before terminating active)
psql "$DATABASE_URL" -c \
  "SELECT pg_terminate_backend(pid) \
   FROM pg_stat_activity \
   WHERE state = 'idle' \
     AND pid <> pg_backend_pid() \
     AND NOW() - query_start > interval '10 minutes';"

kill %1

# Restart the Cloud Run service to flush its connection pool
gcloud run services update uno-server \
  --region us-central1 \
  --update-env-vars=RESTART_TRIGGER="$(date +%s)"
```

**Resolution**: `db_connections_active` returns below 50.

**Postmortem**: check if connection pool is sized correctly; consider PgBouncer if this recurs.

---

### 6c. Redis OOM (Out of Memory)

**Detection**: Redis logs `OOM command not allowed when used memory > 'maxmemory'`, or cache operations start failing.

**Diagnosis**

```sh
# Check memory usage
redis-cli -h REDIS_HOST -p 6379 INFO memory | grep -E 'used_memory_human|maxmemory_human|mem_fragmentation_ratio'

# List the 10 largest keys
redis-cli -h REDIS_HOST -p 6379 --bigkeys

# Check key counts by prefix
redis-cli -h REDIS_HOST -p 6379 DBSIZE
redis-cli -h REDIS_HOST -p 6379 KEYS 'game:*' | wc -l

# Check TTLs on game keys (no TTL = potential leak)
redis-cli -h REDIS_HOST -p 6379 KEYS 'game:*' | while read key; do
  echo "$key: $(redis-cli -h REDIS_HOST TTL "$key")"
done
```

**Mitigation (ordered by blast radius)**

```sh
# Option 1: Delete game keys for finished/abandoned matches only
# Cross-reference with PostgreSQL first:
psql "$DATABASE_URL" -c \
  "SELECT id FROM matches WHERE status IN ('finished','abandoned');" \
  | tail -n +3 | head -n -2 | while read id; do
    redis-cli -h REDIS_HOST -p 6379 DEL "game:$id"
  done

# Option 2: If memory is critically exhausted and games are already broken
# See section 5.5 (FLUSHDB) — acknowledge game loss before proceeding

# Option 3: Scale up Memorystore (requires Terraform apply or gcloud command)
gcloud redis instances update uno-redis-production \
  --region us-central1 \
  --size 2   # GB
```

**Resolution**: `used_memory_human` below 80% of `maxmemory_human`.

**Postmortem**: add TTLs to all game keys in code; review memory provisioning.

---

### 6d. WebSocket Connections Dropping

**Detection**: `ws_connections_active` drops suddenly, players report disconnections, reconnect storms in logs.

**Diagnosis**

```sh
# Check Cloud Run timeout setting (should be 300s for long-lived WS)
gcloud run services describe uno-server --region us-central1 \
  --format 'value(spec.template.spec.timeoutSeconds)'

# Look for timeout errors in logs
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server \
   AND textPayload:"timeout"' \
  --limit=50 --order=desc

# Check client reconnect attempts (look for repeated ws upgrade requests)
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server \
   AND httpRequest.requestUrl:"/ws"' \
  --limit=100 --order=desc
```

**Mitigation**

```sh
# If timeout is < 300s, update it
gcloud run services update uno-server \
  --region us-central1 \
  --timeout 300

# If a specific bad revision caused it, roll back (section 3.3)

# If load-balancer keepalive is the issue, verify h2c port is configured:
gcloud run services describe uno-server --region us-central1 \
  --format 'value(spec.template.spec.containers[0].ports)'
# Should show: name=h2c, containerPort=8080
```

**Resolution**: `ws_connections_active` stabilises, no reconnect storm in logs.

---

### 6e. Matchmaking Queue Stuck

**Detection**: `matchmaking_queue_size{mode="*"}` stays above 10 for > 2 minutes; players report never being matched.

**Diagnosis**

```sh
# Check queue size in Redis
redis-cli -h REDIS_HOST -p 6379 KEYS 'matchmaking:*'
redis-cli -h REDIS_HOST -p 6379 LLEN matchmaking:queue:classic   # adjust key name if different

# Check matchmaking worker logs
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server \
   AND jsonPayload.worker="matchmaking"' \
  --limit=50 --order=desc

# Check if the matchmaking goroutine is alive (look for its ticker log)
gcloud logging read \
  'resource.type=cloud_run_revision AND resource.labels.service_name=uno-server \
   AND textPayload:"matchmaking"' \
  --limit=20 --order=desc
```

**Mitigation**

```sh
# Force a restart of the Cloud Run service to respawn the matchmaking goroutine
gcloud run services update uno-server \
  --region us-central1 \
  --update-env-vars=RESTART_TRIGGER="$(date +%s)"

# If queue entries are stale (players disconnected while waiting), clear them
redis-cli -h REDIS_HOST -p 6379 DEL matchmaking:queue:classic
redis-cli -h REDIS_HOST -p 6379 DEL matchmaking:queue:blitz   # all modes as needed
```

**Resolution**: `matchmaking_queue_size` drains; matches are created (`matches_created_total` counter increases).

---

### 6f. High Latency (p95 > 500 ms)

**Detection**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))` > 0.5 s.

**Diagnosis**

```sh
# Check DB slow queries (queries > 100ms)
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

psql "$DATABASE_URL" -c \
  "SELECT query, calls, mean_exec_time, total_exec_time \
   FROM pg_stat_statements \
   ORDER BY mean_exec_time DESC \
   LIMIT 20;"

# Check if indexes exist on hot paths
psql "$DATABASE_URL" -c \
  "SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read \
   FROM pg_stat_user_indexes \
   ORDER BY idx_scan ASC \
   LIMIT 20;"

kill %1

# Profile the running server with pprof (requires access to the container)
# Port-forward if running locally:
# curl http://localhost:8080/debug/pprof/profile?seconds=30 > profile.out
# go tool pprof profile.out

# Check Redis latency
redis-cli -h REDIS_HOST -p 6379 LATENCY HISTORY event
redis-cli -h REDIS_HOST -p 6379 SLOWLOG GET 10

# Check Prometheus cache miss rate
curl -s "${SERVICE_URL}/metrics" | grep -E '^cache_(hits|misses)_total'
```

**Mitigation**

```sh
# Add missing index for a hot query (example)
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &
psql "$DATABASE_URL" -c \
  "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_status ON matches(status);"
kill %1

# Scale out to reduce per-instance load
gcloud run services update uno-server \
  --region us-central1 \
  --min-instances 5
```

**Resolution**: p95 latency drops below 200 ms.

**Postmortem**: add slow query to regression test suite; consider query optimisation or caching.

---

## 7. Database Operations

### 7.1 Connection String Format

```
postgresql://uno:PASSWORD@PRIVATE_IP:5432/uno?sslmode=require
```

Via Cloud SQL Auth Proxy (from a machine with `CLOUD_SQL_INSTANCE` access):

```
postgresql://uno:PASSWORD@127.0.0.1:5432/uno
```

The actual value is stored in Secret Manager under `database-url`. Retrieve it with:

```sh
gcloud secrets versions access latest --secret=database-url
```

### 7.2 Verify Latest Backup

```sh
# List automated backups for the instance
gcloud sql backups list \
  --instance=uno-postgres-production \
  --limit=10

# Describe the most recent backup
gcloud sql backups describe BACKUP_ID \
  --instance=uno-postgres-production
```

### 7.3 Point-in-Time Recovery (PITR)

PITR is enabled; recovery granularity is to the nearest second within the 7-day backup retention window.

```sh
# Step 1: Identify the target time (ISO 8601, UTC)
# e.g., recover to 2026-10-03T14:30:00Z

# Step 2: Restore to a NEW instance (never restore over production directly)
gcloud sql instances clone uno-postgres-production uno-postgres-restore-$(date +%Y%m%d) \
  --point-in-time="2026-10-03T14:30:00Z"

# Step 3: Verify data integrity on the restored instance
gcloud sql connect uno-postgres-restore-20261003 --user=uno --database=uno

# Step 4: If data looks correct, promote the restore instance
# Update the DATABASE_URL secret to point to the restored instance's IP
# Then deploy to pick up the new connection string
# See Section 8 for full DR steps

# Step 5: Delete the restore instance when done (billing!)
gcloud sql instances delete uno-postgres-restore-20261003
```

### 7.4 Refresh Leaderboard

The `leaderboard` materialized view is not auto-refreshed. Refresh it manually or via a scheduled job:

```sh
cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &

# Refresh without locking reads (safe in production)
psql "$DATABASE_URL" -c \
  "REFRESH MATERIALIZED VIEW CONCURRENTLY leaderboard;"

kill %1
```

Recommended: schedule this to run every 5 minutes via Cloud Scheduler or a cron job in Cloud Run Jobs.

### 7.5 Schema Migrations (manual)

```sh
export CLOUD_SQL_INSTANCE=uno-multiplayer-prod:us-central1:uno-postgres-production
export DATABASE_URL="postgres://uno:PASSWORD@127.0.0.1:5432/uno"

cloud_sql_proxy -instances="$CLOUD_SQL_INSTANCE"=tcp:5432 &
bash scripts/migrate.sh
kill %1
```

Check applied migrations:

```sh
psql "$DATABASE_URL" -c \
  "SELECT version, applied_at FROM schema_migrations ORDER BY applied_at;"
```

---

## 8. Disaster Recovery

**RTO (Recovery Time Objective)**: 1 hour
**RPO (Recovery Point Objective)**: 1 hour (limited by Cloud SQL PITR granularity and backup schedule)

### 8.1 Region Failure

GCP us-central1 is down or Cloud Run is unavailable.

```sh
# Step 1: Declare an incident in #oncall-eng

# Step 2: Provision infrastructure in the failover region (us-east1)
cd infra
terraform workspace new us-east1-dr || terraform workspace select us-east1-dr
terraform apply -var="region=us-east1" -var="project_id=$GCP_PROJECT_ID"

# Step 3: Restore the latest backup to the new Cloud SQL instance
gcloud sql backups list --instance=uno-postgres-production --limit=1
gcloud sql backups restore BACKUP_ID \
  --restore-instance=uno-postgres-dr-$(date +%Y%m%d) \
  --backup-instance=uno-postgres-production

# Step 4: Update secrets in the new region to point to DR database and Redis
echo -n "postgresql://uno:PASSWORD@DR_PRIVATE_IP:5432/uno" | \
  gcloud secrets versions add database-url --data-file=- \
  --project=$GCP_PROJECT_ID

echo -n "redis://:PASSWORD@DR_REDIS_IP:6379" | \
  gcloud secrets versions add redis-url --data-file=- \
  --project=$GCP_PROJECT_ID

# Step 5: Deploy the latest image to the DR Cloud Run service
GCP_PROJECT_ID=$GCP_PROJECT_ID CLOUD_RUN_REGION=us-east1 ./scripts/deploy.sh

# Step 6: Update DNS / load balancer to point to the DR Cloud Run URL
# (Manual step — update your DNS A/CNAME record to the new service URL)
DR_URL=$(gcloud run services describe uno-server --region us-east1 \
  --format 'value(status.url)')
echo "Update DNS to: $DR_URL"

# Step 7: Verify health
curl -s "${DR_URL}/health" | jq .

# Step 8: Notify users of service restoration
```

**Expected timeline**:
- 0–5 min: detect, declare incident, start DR
- 5–20 min: provision infrastructure
- 20–35 min: restore database backup
- 35–50 min: deploy application, update DNS
- 50–60 min: verify, notify users

### 8.2 Data Corruption Recovery

Database rows corrupted by a bug, bad migration, or operator error.

```sh
# Step 1: Stop writes immediately to prevent further corruption
# Scale Cloud Run to 0 instances (this will disconnect all players)
gcloud run services update uno-server \
  --region us-central1 \
  --min-instances 0 \
  --max-instances 0

# Step 2: Take a manual backup snapshot before recovery attempts
gcloud sql backups create \
  --instance=uno-postgres-production \
  --description="pre-recovery-snapshot-$(date +%Y%m%dT%H%M%S)"

# Step 3: Identify the last known-good timestamp
# (Check deployment times, migration history, and incident timeline)
gcloud sql backups list --instance=uno-postgres-production --limit=10

# Step 4: Clone to a restore instance using PITR (section 7.3)
gcloud sql instances clone uno-postgres-production uno-postgres-restore-$(date +%Y%m%d) \
  --point-in-time="LAST_KNOWN_GOOD_TIMESTAMP"

# Step 5: Validate the restored data
gcloud sql connect uno-postgres-restore-$(date +%Y%m%d) --user=uno --database=uno
# Run verification queries against players, matches tables

# Step 6: If valid, promote: update DATABASE_URL secret to restored instance
echo -n "postgresql://uno:PASSWORD@RESTORED_PRIVATE_IP:5432/uno" | \
  gcloud secrets versions add database-url --data-file=-

# Step 7: Apply any missing migrations on top of restored data (if applicable)
bash scripts/migrate.sh

# Step 8: Scale Cloud Run back up
gcloud run services update uno-server \
  --region us-central1 \
  --min-instances 1 \
  --max-instances 10

# Step 9: Verify health and monitor for 30 minutes
curl -s "${SERVICE_URL}/health" | jq .

# Step 10: Decommission old corrupted instance (after data is confirmed good)
# gcloud sql instances delete uno-postgres-production  # DANGER: only after full verification
```

**Post-recovery**:
- Write a postmortem within 48 hours.
- Add regression test for the corruption vector.
- Review and tighten migration review process.

---

*For urgent issues not covered here, escalate to the on-call lead via PagerDuty or Slack #oncall-eng.*
