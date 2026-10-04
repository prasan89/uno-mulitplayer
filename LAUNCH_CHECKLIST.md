# UNO Multiplayer Launch Checklist

> **Instructions:** Each item must be checked off before launch. Update the `Owner` field with the responsible person's name. Mark `[x]` only when the done criteria is fully met.

---

## Infrastructure (Owner: DevOps)

- [ ] **GCP project created and billing enabled**
  - Owner: DevOps
  - How to verify: `gcloud projects describe <PROJECT_ID>` returns ACTIVE; billing account linked in GCP Console > Billing
  - Done criteria: Project status is ACTIVE and billing account is attached

- [ ] **Terraform state initialized and remote backend configured**
  - Owner: DevOps
  - How to verify: `terraform init` completes without error; `terraform state list` returns resources; state bucket exists in GCS
  - Done criteria: Remote state in GCS bucket, no local `.tfstate` files committed

- [ ] **Terraform plan shows zero unexpected changes**
  - Owner: DevOps
  - How to verify: `terraform plan -out=tfplan` and review output for zero destructive changes
  - Done criteria: `terraform plan` exits 0 with "No changes" or only additive changes approved by team

- [ ] **Terraform applied to production environment**
  - Owner: DevOps
  - How to verify: `terraform apply tfplan` completes; all resources show in GCP Console
  - Done criteria: `terraform apply` exits 0 with no errors; all outputs populated

- [ ] **Cloud Run service deployed and serving traffic**
  - Owner: DevOps
  - How to verify: `gcloud run services describe <SERVICE> --region=<REGION>` shows READY; curl the service URL returns HTTP 200
  - Done criteria: Service status is READY, latest revision is serving 100% traffic

- [ ] **Cloud SQL (PostgreSQL) instance running and accessible**
  - Owner: DevOps
  - How to verify: `gcloud sql instances describe <INSTANCE>` shows RUNNABLE; connect via Cloud SQL Proxy and run `SELECT 1`
  - Done criteria: Instance state is RUNNABLE, connection from Cloud Run succeeds

- [ ] **Redis (Memorystore) instance running**
  - Owner: DevOps
  - How to verify: `gcloud redis instances describe <INSTANCE> --region=<REGION>` shows READY; `redis-cli -h <HOST> ping` returns PONG
  - Done criteria: Instance state is READY, PING/PONG succeeds from within VPC

- [ ] **Firebase project configured and linked to GCP project**
  - Owner: DevOps
  - How to verify: Firebase Console shows project linked; `firebase projects:list` includes the production project
  - Done criteria: Firebase project active, Auth and Firestore (if used) enabled, billing plan upgraded if required

- [ ] **Custom domain configured and DNS propagated**
  - Owner: DevOps
  - How to verify: `dig <DOMAIN>` resolves to expected IP/CNAME; `curl -I https://<DOMAIN>` returns HTTP 200
  - Done criteria: DNS TTL expired, domain resolves correctly from at least 3 geographic locations

- [ ] **SSL/TLS certificate issued and auto-renewing**
  - Owner: DevOps
  - How to verify: `openssl s_client -connect <DOMAIN>:443 </dev/null` shows valid cert; expiry >30 days; certificate managed by GCP or cert-manager
  - Done criteria: Valid cert, HTTPS enforced, auto-renewal confirmed

- [ ] **Monitoring dashboards created in Cloud Monitoring**
  - Owner: DevOps
  - How to verify: Open GCP Console > Monitoring > Dashboards; confirm dashboards for error rate, latency, active connections, CPU, memory exist
  - Done criteria: Dashboards display live data with no missing metrics

- [ ] **Alerting policies configured (error rate, latency, uptime)**
  - Owner: DevOps
  - How to verify: GCP Console > Monitoring > Alerting; test alert by temporarily raising threshold; confirm notification channel (PagerDuty/Slack/email) receives alert
  - Done criteria: At least one alert fires successfully in test; notification channels verified

- [ ] **DDoS protection enabled (Cloud Armor policy attached)**
  - Owner: DevOps
  - How to verify: `gcloud compute security-policies list`; policy attached to load balancer backend; verify rules include rate-limiting
  - Done criteria: Cloud Armor policy active on production load balancer, rate-limit rules in place

- [ ] **Firewall rules reviewed and least-privilege applied**
  - Owner: DevOps
  - How to verify: `gcloud compute firewall-rules list --project=<PROJECT>`; no rules allow 0.0.0.0/0 on ports other than 80/443; Cloud SQL only accessible from Cloud Run service account
  - Done criteria: No overly permissive rules; all ingress to backend services restricted to expected sources

- [ ] **Secret Manager populated with all production secrets**
  - Owner: DevOps
  - How to verify: `gcloud secrets list` shows all required secrets (DB_PASSWORD, REDIS_URL, JWT_SECRET, FIREBASE_SA_KEY, etc.); each has at least one active version
  - Done criteria: All secrets listed in `.env.example` exist in Secret Manager with production values

- [ ] **Service account permissions follow least-privilege principle**
  - Owner: DevOps
  - How to verify: `gcloud iam service-accounts list`; for each SA, `gcloud projects get-iam-policy <PROJECT>` confirms no Owner/Editor roles; only specific roles granted
  - Done criteria: No service account has primitive Editor or Owner role; permissions scoped to required services only

- [ ] **GCS storage bucket created with correct ACLs and versioning**
  - Owner: DevOps
  - How to verify: `gsutil ls gs://<BUCKET>`; `gsutil versioning get gs://<BUCKET>` shows Enabled; `gsutil iam get gs://<BUCKET>` shows no allUsers/allAuthenticatedUsers
  - Done criteria: Bucket exists, versioning enabled, no public access, lifecycle policy set

---

## Application (Owner: Backend)

- [ ] **All environment variables set in Cloud Run service configuration**
  - Owner: Backend
  - How to verify: `gcloud run services describe <SERVICE> --format='value(spec.template.spec.containers[0].env)'`; compare against `.env.example`; every key present
  - Done criteria: Zero missing variables compared to `.env.example`; no placeholder values remaining

- [ ] **`/health` endpoint returns HTTP 200 with valid response body**
  - Owner: Backend
  - How to verify: `curl -sf https://<DOMAIN>/health` returns `{"status":"ok"}` (or equivalent) with HTTP 200; Cloud Run health check passing
  - Done criteria: HTTP 200, response body confirms all dependencies healthy (DB, Redis), latency < 500ms

- [ ] **WebSocket connection establishes and maintains session**
  - Owner: Backend
  - How to verify: Connect via `wscat -c wss://<DOMAIN>/ws` or equivalent test client; send ping, receive pong; hold connection for 60s without disconnect
  - Done criteria: Connection established, bidirectional messages exchanged, no unexpected disconnects under idle conditions

- [ ] **Firebase Auth end-to-end flow works in production**
  - Owner: Backend
  - How to verify: Sign in via test account using Firebase Auth SDK; verify ID token issued; call authenticated backend endpoint with token; receive 200
  - Done criteria: Full auth flow completes, token validated server-side, user record created/retrieved in DB

- [ ] **Google Sign-In configured and working**
  - Owner: Backend
  - How to verify: Initiate Google OAuth from mobile app or web; complete sign-in; verify user appears in Firebase Console > Authentication > Users
  - Done criteria: Google provider enabled in Firebase, OAuth client ID configured, sign-in succeeds end-to-end

- [ ] **Apple Sign-In (iOS) configured and working**
  - Owner: Backend
  - How to verify: Initiate Sign in with Apple on iOS device; complete authentication; verify user appears in Firebase Console > Authentication
  - Done criteria: Apple provider enabled in Firebase, Service ID and key configured in Apple Developer Portal, sign-in succeeds on physical iOS device

- [ ] **Database migrations applied to production**
  - Owner: Backend
  - How to verify: Run migration tool (e.g., `goose status` or `migrate version`); all migrations show as applied; `psql` schema matches expected
  - Done criteria: Zero pending migrations, schema version matches codebase version, no migration errors in logs

- [ ] **Materialized view created and refreshing**
  - Owner: Backend
  - How to verify: `psql -c "\dm"` lists the materialized view; `psql -c "SELECT count(*) FROM <view_name>"` returns data; scheduled refresh job exists
  - Done criteria: View exists, contains data, refresh mechanism (pg_cron or application-level) tested and working

- [ ] **`/metrics` endpoint returns Prometheus-formatted metrics**
  - Owner: Backend
  - How to verify: `curl https://<DOMAIN>/metrics` returns text with `# HELP` and `# TYPE` headers; key metrics (http_requests_total, active_games, connected_players) present
  - Done criteria: Metrics endpoint returns valid Prometheus format, Cloud Monitoring scraping confirmed, metrics appear in dashboards

- [ ] **Structured logs appear in Cloud Logging**
  - Owner: Backend
  - How to verify: GCP Console > Logging > Logs Explorer; filter by Cloud Run service; logs show as JSON with severity, message, trace fields
  - Done criteria: Logs are structured JSON, severity levels correct, request logs include method/path/status/latency, no raw text logs from application

- [ ] **Database connection pooling configured correctly**
  - Owner: Backend
  - How to verify: Check Cloud SQL connections in Cloud Monitoring; verify pool size in application config does not exceed Cloud SQL max connections; run load test and confirm no `too many clients` errors
  - Done criteria: No connection pool exhaustion under expected load, pool settings match Cloud SQL instance limits

- [ ] **Error handling returns safe messages (no stack traces to client)**
  - Owner: Backend
  - How to verify: Trigger a known error condition (invalid input, missing resource); confirm response body contains user-safe message only; check logs for full stack trace server-side
  - Done criteria: No internal error details, file paths, or stack traces returned to API clients

---

## Testing (Owner: QA)

- [ ] **All backend unit tests pass with zero failures**
  - Owner: QA
  - How to verify: `go test ./... -count=1` (or equivalent) returns exit 0 with no FAIL lines
  - Done criteria: 100% of unit tests pass, no skipped tests without documented reason, coverage >= project threshold

- [ ] **Flutter unit tests pass with zero failures**
  - Owner: QA
  - How to verify: `flutter test` returns exit 0; no test failures in output
  - Done criteria: All Flutter unit and widget tests pass

- [ ] **`flutter analyze` returns zero errors and zero warnings**
  - Owner: QA
  - How to verify: `flutter analyze` exits 0 with "No issues found!" or only approved info-level hints
  - Done criteria: Zero errors, zero warnings; any remaining hints documented and approved

- [ ] **Integration tests pass against staging environment**
  - Owner: QA
  - How to verify: Run integration test suite pointing at staging URL; all tests green; no flaky tests in last 3 runs
  - Done criteria: All integration tests pass consistently across 3 consecutive runs on staging

- [ ] **E2E game flow tested: lobby creation, join, play, win/lose**
  - Owner: QA
  - How to verify: Run E2E test suite (from `e2e/` directory); complete full game cycle from lobby creation to game end; verify score recorded
  - Done criteria: Full game flow completes without errors, correct winner determined, game state cleaned up post-game

- [ ] **E2E reconnect flow tested: disconnect mid-game and rejoin**
  - Owner: QA
  - How to verify: Start game, force disconnect one client (kill network), reconnect within timeout window; verify player rejoins with correct hand state
  - Done criteria: Player successfully rejoins, hand state preserved, game continues correctly, other players not disrupted

- [ ] **Bot takeover tested: AFK player replaced by bot**
  - Owner: QA
  - How to verify: Join game, go AFK past timeout threshold; verify bot takes over; verify bot plays legal moves; verify human can reclaim seat
  - Done criteria: Bot activates within configured timeout, plays valid UNO moves, human reclaim works correctly

- [ ] **Load test: 100 concurrent matches without errors**
  - Owner: QA
  - How to verify: Run load test script from `load_tests/` with 100 concurrent game sessions; check for zero 5xx errors; all games complete
  - Done criteria: Zero HTTP 5xx errors, zero WebSocket connection failures, all 100 games complete successfully

- [ ] **Load test: 500 concurrent players with p95 latency < 200ms**
  - Owner: QA
  - How to verify: Run load test with 500 concurrent WebSocket connections; use k6/Locust report; check p95 latency metric
  - Done criteria: p95 WebSocket message latency < 200ms, p99 < 500ms, zero timeouts, Cloud Run does not exceed 80% CPU

- [ ] **iOS device tested on physical hardware**
  - Owner: QA
  - How to verify: Install TestFlight build on physical iPhone (not simulator); complete full game flow; test all gestures and UI elements
  - Done criteria: App installs, launches, authenticates, and plays full game on minimum supported iOS version (physical device)

- [ ] **Android device tested on physical hardware**
  - Owner: QA
  - How to verify: Install APK on physical Android device; complete full game flow; test all gestures and UI elements
  - Done criteria: App installs, launches, authenticates, and plays full game on minimum supported Android version (physical device)

- [ ] **Regression test: card draw mechanics follow UNO rules**
  - Owner: QA
  - How to verify: Run rule-validation test suite; play scripted game sequences verifying draw-2 stacking, wild card color selection, UNO call penalty
  - Done criteria: All UNO rule scenarios in test suite pass; no rule violations possible through UI

- [ ] **Regression test: game state consistency across reconnects**
  - Owner: QA
  - How to verify: Simulate server restart mid-game; verify game state recovered from Redis/DB; all players reconnect to correct state
  - Done criteria: Game state 100% consistent after reconnect; no cards lost, duplicated, or order changed

- [ ] **Performance test: app cold start under 3 seconds**
  - Owner: QA
  - How to verify: Time cold launch of app on minimum-spec device using Flutter DevTools or Xcode Instruments; measure from tap to interactive
  - Done criteria: Cold start time < 3 seconds on minimum supported device, hot restart < 1 second

- [ ] **Accessibility: minimum tap target size and contrast ratio met**
  - Owner: QA
  - How to verify: Run Flutter accessibility checker; verify minimum 44x44pt tap targets; check text contrast ratio >= 4.5:1 with contrast analyzer tool
  - Done criteria: Zero accessibility violations from automated checker, manual review of key screens passed

---

## Security (Owner: Security)

- [ ] **No secrets committed to git history**
  - Owner: Security
  - How to verify: `git log --all --full-history -- '*.env' '*.key' '*.pem'`; run `git log -p | grep -iE '(password|secret|token|key)\s*=' | grep -v placeholder`; use truffleHog or gitleaks: `gitleaks detect --source .`
  - Done criteria: Zero secrets found in git history; gitleaks scan returns clean

- [ ] **CORS policy restricts origins to production domains only**
  - Owner: Security
  - How to verify: `curl -H "Origin: https://evil.com" -I https://<DOMAIN>/api/`; confirm `Access-Control-Allow-Origin` does NOT include evil.com; verify only production domain(s) allowed
  - Done criteria: CORS rejects all unauthorized origins; no wildcard `*` in production CORS config

- [ ] **Rate limits tested and enforced**
  - Owner: Security
  - How to verify: Send >rate-limit threshold requests/minute to auth and game endpoints; confirm HTTP 429 responses with Retry-After header
  - Done criteria: Rate limiting triggers correctly, 429 returned, legitimate traffic not affected at normal usage levels

- [ ] **Firebase Security Rules reviewed and tested**
  - Owner: Security
  - How to verify: Review rules in Firebase Console; run Firebase Emulator Suite rules tests (`firebase emulators:exec "npm test"`); verify unauthenticated reads/writes rejected
  - Done criteria: All Firebase rules tests pass; no unauthenticated access to player data; rules reviewed by second team member

- [ ] **Authentication bypass test: unauthenticated requests rejected**
  - Owner: Security
  - How to verify: Call all authenticated API endpoints without Authorization header; call with malformed/expired JWT; call with JWT signed by wrong key; all must return 401
  - Done criteria: 100% of protected endpoints return 401 for unauthenticated requests; no endpoint accidentally public

- [ ] **Trivy container scan returns zero HIGH/CRITICAL vulnerabilities**
  - Owner: Security
  - How to verify: `trivy image <IMAGE>:<TAG>` against production image; review output for HIGH and CRITICAL severity CVEs
  - Done criteria: Zero CRITICAL vulnerabilities; zero HIGH vulnerabilities or all HIGH vulns have documented exception with remediation timeline

- [ ] **gosec static analysis returns zero HIGH severity findings**
  - Owner: Security
  - How to verify: `gosec ./...` from backend directory; review output for HIGH severity findings
  - Done criteria: Zero HIGH severity findings from gosec; MEDIUM findings reviewed and accepted or remediated

- [ ] **HTTPS enforced — HTTP requests redirect to HTTPS**
  - Owner: Security
  - How to verify: `curl -I http://<DOMAIN>` returns 301 or 308 redirect to HTTPS; no content served over plain HTTP
  - Done criteria: All HTTP traffic redirects to HTTPS with permanent redirect code; HSTS header present with min-age >= 31536000

- [ ] **SQL injection and input validation tested**
  - Owner: Security
  - How to verify: Attempt common SQL injection payloads (`' OR 1=1--`, `"; DROP TABLE`) in all text input fields and URL parameters; verify inputs sanitized or parameterized queries used
  - Done criteria: No SQL injection vulnerabilities found; all DB queries use parameterized statements; sqlmap scan clean

- [ ] **WebSocket authentication enforced on connection upgrade**
  - Owner: Security
  - How to verify: Attempt WebSocket connection without valid auth token; attempt with expired token; both must be rejected with 401/4001
  - Done criteria: Unauthenticated WebSocket connections rejected; token validated before upgrade completed

- [ ] **Dependency audit: no known vulnerable packages**
  - Owner: Security
  - How to verify: `go list -m all | nancy sleuth` or `govulncheck ./...` for Go; `flutter pub audit` for Dart dependencies
  - Done criteria: Zero known vulnerabilities in direct dependencies; transitive vulnerabilities reviewed and mitigated

- [ ] **Sensitive data not logged (no PII in logs)**
  - Owner: Security
  - How to verify: Review log output in Cloud Logging; search for email addresses, device IDs, full names, card hand contents in logs; verify no sensitive fields logged
  - Done criteria: Zero PII fields in application logs; Firebase UID used as identifier (not email); card hands only logged at DEBUG level behind feature flag

---

## Operations (Owner: SRE)

- [ ] **Runbook reviewed and up-to-date**
  - Owner: SRE
  - How to verify: Open runbook document; verify all service names, commands, and URLs match production; walk through one procedure end-to-end in staging
  - Done criteria: Runbook reviewed by at least two team members within 30 days of launch; all commands tested against staging

- [ ] **On-call rotation configured with primary and secondary**
  - Owner: SRE
  - How to verify: Open PagerDuty/OpsGenie schedule; verify rotation covers 24/7 for first two weeks post-launch; primary and secondary responders confirmed and available
  - Done criteria: On-call schedule active, all responders have acknowledged and tested alert delivery (SMS, push, call)

- [ ] **Incident response process documented and accessible**
  - Owner: SRE
  - How to verify: Incident process doc accessible via bookmark or on-call guide; includes severity definitions, escalation path, communication templates, and war room setup
  - Done criteria: Document reviewed by all on-call participants; practice incident walkthrough completed

- [ ] **Database backup verified with successful restore**
  - Owner: SRE
  - How to verify: Trigger manual Cloud SQL backup; restore to a separate test instance; run `SELECT count(*)` on key tables; verify row counts match source
  - Done criteria: Backup completes successfully, restore to test instance completes without errors, data integrity verified via row count and spot-check queries

- [ ] **Rollback procedure tested and documented**
  - Owner: SRE
  - How to verify: Deploy previous Cloud Run revision to staging; verify rollback completes in < 5 minutes; confirm traffic shifts to previous revision; test app functionality post-rollback
  - Done criteria: Rollback procedure works in staging; documented steps take < 5 minutes; runbook updated with verified commands

- [ ] **Support contact and escalation path communicated to team**
  - Owner: SRE
  - How to verify: Team channel pinned message or wiki page lists: support email, escalation contacts by severity, external vendor contacts (GCP support, Firebase support)
  - Done criteria: All team members confirm awareness of support contacts; GCP support case submitted and response received (verify support tier active)

- [ ] **Log retention policy configured**
  - Owner: SRE
  - How to verify: GCP Console > Logging > Log Router > Log sinks; verify retention period set per compliance requirements; confirm _Default bucket retention >= 30 days
  - Done criteria: Log retention configured, log sink to GCS/BigQuery for long-term storage if required, retention policy documented

- [ ] **Cost alerts configured to notify on budget overrun**
  - Owner: SRE
  - How to verify: GCP Console > Billing > Budgets & alerts; budget alert set at 80% and 100% of monthly estimate; notification sent to SRE email/Slack
  - Done criteria: Budget alert active, threshold amounts set based on projected costs, notification channels verified

---

## Mobile Release (Owner: Mobile)

- [ ] **Android APK signed with production keystore**
  - Owner: Mobile
  - How to verify: `apksigner verify --print-certs app-release.apk`; confirm certificate fingerprint matches production keystore in password manager; build with `--release` flag
  - Done criteria: APK signed with production key (not debug key), certificate fingerprint documented in secrets manager

- [ ] **Android build submitted to Google Play Store**
  - Owner: Mobile
  - How to verify: Google Play Console shows submission in review or approved; store listing complete (description, screenshots, content rating)
  - Done criteria: App bundle uploaded, all required store listing assets provided, content rating questionnaire completed, build passes Play Store pre-launch report

- [ ] **iOS IPA signed with distribution certificate and provisioning profile**
  - Owner: Mobile
  - How to verify: Xcode Organizer shows archive signed with distribution cert; `codesign -dvvv app.ipa` confirms certificate and provisioning profile; build targets App Store distribution
  - Done criteria: IPA signed with App Store distribution certificate, provisioning profile includes production push notification entitlement if used

- [ ] **iOS build submitted to TestFlight for beta testing**
  - Owner: Mobile
  - How to verify: App Store Connect > TestFlight shows build processed; internal testers invited and able to install
  - Done criteria: Build passes TestFlight processing, at least 5 internal testers have installed and confirmed functionality

- [ ] **App Store listing assets complete (screenshots, description, icon)**
  - Owner: Mobile
  - How to verify: App Store Connect listing shows no missing required assets; preview screenshots for all required device sizes uploaded; app icon 1024x1024 PNG uploaded
  - Done criteria: All required screenshot sizes provided, app description localized if required, keywords and categories set

- [ ] **Privacy policy URL live and accessible**
  - Owner: Mobile
  - How to verify: Open privacy policy URL in browser; page loads without auth; content covers data collection practices for both Google Play and App Store compliance
  - Done criteria: Privacy policy URL returns HTTP 200, content covers all required disclosures per GDPR/CCPA, URL submitted to both stores

- [ ] **Firebase Analytics events verified in DebugView**
  - Owner: Mobile
  - How to verify: Enable Firebase Analytics debug mode; complete game flow; confirm key events (game_started, card_played, game_won, sign_in) appear in Firebase Console > Analytics > DebugView
  - Done criteria: All key analytics events fire correctly, user properties set, no duplicate event firing confirmed

- [ ] **Push notifications tested on both platforms**
  - Owner: Mobile
  - How to verify: Send test FCM notification via Firebase Console; verify delivery on iOS and Android physical devices; verify notification opens correct screen in app
  - Done criteria: Push notifications delivered on both platforms, deep link from notification works, notification permission prompt tested

---

## Post-Launch Monitoring (Owner: All)

- [ ] **Monitor error rate for 24 hours post-launch**
  - Owner: All
  - How to verify: Watch Cloud Monitoring dashboard for HTTP 5xx error rate; set up real-time alerting; assign team member to monitor dashboard for first 24 hours
  - Done criteria: Error rate stays below 0.1% for 24 hours; any spikes investigated and resolved within SLA

- [ ] **Monitor p95 latency for 24 hours post-launch**
  - Owner: All
  - How to verify: Cloud Monitoring > Metrics Explorer; track `request_latencies` p95 metric on Cloud Run service; alert triggers if p95 > 300ms
  - Done criteria: p95 API latency < 200ms sustained, no latency spikes > 500ms lasting more than 60 seconds

- [ ] **Player feedback channel established and monitored**
  - Owner: All
  - How to verify: Feedback channel (Discord/Slack/email) created and linked from app; at least one team member assigned to monitor and respond within 24 hours
  - Done criteria: Feedback channel live, moderation assigned, first-response SLA defined and communicated

- [ ] **Hotfix deployment procedure verified end-to-end**
  - Owner: All
  - How to verify: Walk through hotfix procedure in staging: create branch, make change, run abbreviated test suite, deploy to staging, verify, promote to production; document end-to-end time
  - Done criteria: Hotfix procedure documented and tested; end-to-end time from code-merge to production deploy < 30 minutes

- [ ] **Week 1 review: matchmaking queue times analyzed**
  - Owner: All
  - How to verify: Pull matchmaking latency metrics from Cloud Monitoring or analytics for first 7 days; calculate p50/p95 queue-to-game-start time; compare against target SLA
  - Done criteria: Matchmaking metrics reviewed in team meeting; action items created if p95 queue time > 30 seconds

- [ ] **Week 1 review: bot takeover rate analyzed**
  - Owner: All
  - How to verify: Query analytics or logs for bot_takeover events in first 7 days; calculate percentage of games with at least one bot takeover; segment by time-of-day and platform
  - Done criteria: Bot takeover rate reviewed in team meeting; if rate > 10% of games, root cause analysis initiated and AFK timeout parameters tuned

---

## Sign-Off

| Section | Owner | Signed Off By | Date |
|---|---|---|---|
| Infrastructure | DevOps | | |
| Application | Backend | | |
| Testing | QA | | |
| Security | Security | | |
| Operations | SRE | | |
| Mobile Release | Mobile | | |
| Post-Launch Monitoring | All | | |

**Final launch approval:** _________________________ Date: _____________
