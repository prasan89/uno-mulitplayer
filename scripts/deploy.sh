#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — Build, push, migrate, and deploy to Cloud Run

PROJECT_ID="${GCP_PROJECT_ID:?GCP_PROJECT_ID must be set}"
REGION="${CLOUD_RUN_REGION:-us-central1}"
SERVICE_NAME="${CLOUD_RUN_SERVICE:-uno-server}"
IMAGE_REPO="${GCR_REPO:-gcr.io/${PROJECT_ID}/uno-server}"
CLOUD_SQL_INSTANCE="${CLOUD_SQL_INSTANCE:-}"

GIT_SHA="$(git rev-parse --short HEAD)"
IMAGE_TAG="${IMAGE_REPO}:${GIT_SHA}"
PREVIOUS_TAG=""

log() { echo "[deploy] $*"; }

# --- 1. Build image ---
log "Building image for git SHA ${GIT_SHA}..."
docker build -t "${IMAGE_TAG}" ./backend
docker tag "${IMAGE_TAG}" "${IMAGE_REPO}:latest"

# --- 2. Push to GCR ---
log "Pushing ${IMAGE_TAG} to GCR..."
docker push "${IMAGE_TAG}"
docker push "${IMAGE_REPO}:latest"

# --- 3. Run migrations via Cloud SQL proxy ---
if [[ -n "${CLOUD_SQL_INSTANCE}" ]]; then
  log "Running migrations via Cloud SQL proxy..."
  cloud_sql_proxy -instances="${CLOUD_SQL_INSTANCE}"=tcp:5432 &
  PROXY_PID=$!
  sleep 3
  bash "$(dirname "$0")/migrate.sh"
  kill "${PROXY_PID}" 2>/dev/null || true
else
  log "CLOUD_SQL_INSTANCE not set; skipping proxy-based migration"
fi

# --- 4. Capture previous revision for rollback ---
PREVIOUS_TAG="$(gcloud run services describe "${SERVICE_NAME}" \
  --region "${REGION}" \
  --format 'value(spec.template.spec.containers[0].image)' 2>/dev/null || true)"

# --- 5. Deploy to Cloud Run ---
log "Deploying ${IMAGE_TAG} to Cloud Run service '${SERVICE_NAME}' in ${REGION}..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE_TAG}" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated

# --- 6. Health check loop ---
SERVICE_URL="$(gcloud run services describe "${SERVICE_NAME}" \
  --region "${REGION}" \
  --format 'value(status.url)')"

log "Health-checking ${SERVICE_URL}/health ..."
MAX_RETRIES=10
RETRY_INTERVAL=5
for i in $(seq 1 "${MAX_RETRIES}"); do
  HTTP_STATUS="$(curl -s -o /dev/null -w '%{http_code}' "${SERVICE_URL}/health" || true)"
  if [[ "${HTTP_STATUS}" == "200" ]]; then
    log "Health check passed (attempt ${i})."
    break
  fi
  log "Attempt ${i}/${MAX_RETRIES}: got HTTP ${HTTP_STATUS}, retrying in ${RETRY_INTERVAL}s..."
  if [[ "${i}" -eq "${MAX_RETRIES}" ]]; then
    log "ERROR: Health check failed after ${MAX_RETRIES} attempts. Rolling back..."
    if [[ -n "${PREVIOUS_TAG}" ]]; then
      gcloud run deploy "${SERVICE_NAME}" \
        --image "${PREVIOUS_TAG}" \
        --region "${REGION}" \
        --platform managed \
        --allow-unauthenticated
      log "Rollback to ${PREVIOUS_TAG} complete."
    else
      log "No previous image recorded; manual intervention required."
    fi
    exit 1
  fi
  sleep "${RETRY_INTERVAL}"
done

log "Deployment complete: ${IMAGE_TAG}"
