# UNO Multiplayer Security Documentation

## 1. Threat Model

| Threat | Description | Attack Vector | Impact | Mitigation Implemented |
|--------|-------------|---------------|--------|------------------------|
| **Auth Bypass** | Attacker accesses game resources without valid credentials | Forged or missing JWT tokens in requests | High | Firebase JWT verification (RS256) on every protected route; token signature validated against Firebase public keys |
| **Authorization Escalation** | Player accesses or modifies another player's resources or game rooms they have not joined | Crafted requests with valid token but unauthorized resource IDs | High | Server-side ownership checks before every action; room membership verified on each WebSocket message |
| **Game State Manipulation / Cheating** | Player plays cards they do not hold, skips turns illegally, or sends crafted game state | Malformed WebSocket messages bypassing client-side validation | High | All game logic executed server-side; card ownership verified before every PlayCard action; WD4 legality enforced against server-held hand |
| **Rate Limit Bypass / DoS** | Attacker floods HTTP endpoints or WebSocket with requests to exhaust resources | High-volume requests from single IP or authenticated user | High | 100 req/min per IP on HTTP; 10 actions/sec per player on WebSocket via Redis Lua sliding window |
| **SQL Injection** | Attacker injects SQL through user-supplied input to read or corrupt database | Game room codes, player names, card IDs passed to database queries | High | Parameterized queries only; no string interpolation in SQL; input validated to typed structs before reaching data layer |
| **WebSocket Hijacking** | Attacker intercepts or takes over an established WebSocket connection | Man-in-the-middle on unencrypted connection; session token theft | High | WSS (TLS) enforced in production; token re-verified on upgrade handshake; connections scoped to authenticated player ID |
| **Token Theft** | Attacker steals a valid JWT to impersonate a player | XSS, insecure storage, network sniffing | High | Tokens transmitted in Authorization header only (never in URLs or cookies); HTTPS/WSS enforced; 1-hour expiry limits exposure window |
| **Bot Abuse** | Automated clients spam matchmaking, inflate game counts, or disrupt real players | Scripted clients with valid tokens | Medium | Matchmaking rate-limited to 5 joins/min per player; all actions logged to game_events for anomaly detection |
| **Information Disclosure (Opponent Hands)** | Player receives card data for opponents they should not see | Server broadcasting full game state to all connections | High | WebSocket broadcast scoped to room membership; each player's hand transmitted only to that player's connection |
| **Replay Attacks** | Attacker re-sends a previously captured valid game action | Captured WebSocket frames replayed to repeat a move | Medium | Sequence numbers on all game actions; server rejects out-of-order or duplicate sequence numbers |

---

## 2. Authentication

### Firebase JWT Verification

All protected routes verify the incoming Firebase ID token using RS256 asymmetric verification against Firebase's published public keys.

**Verification steps performed on every request:**

1. Token extracted from the `Authorization: Bearer <token>` header. Tokens in query parameters or request bodies are rejected.
2. Signature verified with the RS256 public key fetched from `https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com`.
3. `aud` claim must equal the configured Firebase project ID.
4. `iss` claim must equal `https://securetoken.google.com/<PROJECT_ID>`.
5. `exp` claim checked: tokens older than 1 hour are rejected.
6. `iat` claim checked: tokens issued in the future are rejected (clock skew tolerance: 5 minutes).

### Token Handling Rules

- Tokens are transmitted exclusively in the `Authorization` header to avoid server-side logging of URLs.
- Tokens are never stored in localStorage on the client; the Firebase SDK manages token storage and rotation.
- Token refresh is handled transparently by the Firebase client SDK before expiry.
- On WebSocket upgrade, the token is passed as a header (not as a query parameter) and verified before the connection is accepted.

### Unprotected Routes

The following routes are intentionally exempt from authentication:

- `GET /health` - liveness probe for Cloud Run
- `GET /metrics` - Prometheus scrape endpoint (restricted to internal network)

All other HTTP and WebSocket endpoints require a valid token.

---

## 3. Authorization

### Card Play Authorization

Before processing any `PlayCard` action, the server performs the following checks in order:

1. Confirm the requesting player is a member of the game room.
2. Confirm it is the requesting player's turn.
3. Confirm the specified card ID exists in the server-side record of that player's hand.
4. Confirm the card is a legal play given the current top-of-pile card and game state.

If any check fails, the action is rejected with an error and the game state is not modified.

### WebSocket Room Scoping

- On connection, each WebSocket is registered to the authenticated player ID and their current room.
- Game state broadcasts are sent only to connections that are members of the target room.
- A player who leaves or is disconnected from a room is removed from the broadcast list immediately.
- There is no mechanism for a player to receive messages from a room they have not joined.

### Resource Ownership

- Room management actions (start game, kick player) are restricted to the room creator.
- Players may only perform actions on their own game state (draw cards, play cards, call UNO).
- Admin-level operations are restricted by a separate role claim in the JWT and are not accessible to regular players.

---

## 4. Input Validation

All input is validated at the boundary before any processing occurs.

### WebSocket Messages

- Messages are decoded from JSON into strongly typed Go structs.
- Unknown fields in the JSON payload cause the message to be rejected; there is no pass-through of arbitrary data.
- Message type is validated against an allowlist of known action types before routing.

### Card IDs

- Must conform to UUID v4 format (`xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx`).
- Validated with a strict regular expression before any database or game logic lookup.

### Player Names

- Maximum length: 50 characters.
- HTML tags are stripped before storage and display to prevent stored XSS.
- Only printable Unicode characters are accepted.

### Room Codes

- Must be exactly 6 characters, uppercase alphanumeric (`[A-Z0-9]{6}`).
- Validated by regular expression; any non-conforming value is rejected with a 400 response.

### General Rules

- All integer inputs (e.g., card counts, player counts) are bounds-checked against defined game minimums and maximums.
- File uploads are not accepted anywhere in the application.

---

## 5. Rate Limiting

### HTTP Endpoints

- **Limit:** 100 requests per minute per source IP.
- Implemented at the load balancer / reverse proxy layer.
- Exceeding the limit returns HTTP 429 with a `Retry-After` header.

### WebSocket Game Actions

- **Limit:** 10 game actions per second per authenticated player.
- Implemented as a sliding window counter using a Redis Lua script to ensure atomicity across multiple backend instances.
- Actions exceeding the limit are dropped and the player receives an error message; the connection is not terminated on first violation.
- Repeated sustained violations result in a temporary connection ban.

### Matchmaking

- **Limit:** 5 room join or create attempts per minute per authenticated player.
- Prevents rapid room churn and matchmaking queue flooding.

### Authentication

- Login rate limiting and account lockout are delegated to Firebase Authentication, which enforces its own per-IP and per-account limits.

---

## 6. Anti-Cheat

### Server-Side Game Logic

All game rules are enforced exclusively on the server. The client is treated as untrusted input. Specifically:

- The authoritative copy of each player's hand is held only in server memory and Redis; the client receives only its own hand.
- Turn order, skip effects, reverse effects, and draw effects are computed server-side.
- The draw pile and discard pile state are never exposed to clients beyond what the game rules permit.

### Sequence Numbers

- Every game action message includes a monotonically increasing sequence number scoped to the game session.
- The server rejects any action whose sequence number has already been processed or is out of expected order.
- This prevents replay of captured WebSocket frames and duplicate action submission.

### Wild Draw Four Legality

- Before accepting a WD4 play, the server checks the playing player's hand to verify they hold no card of the current suit.
- If the player holds a matching suit card, the WD4 play is rejected as illegal.
- This check cannot be bypassed through client manipulation.

### UNO Penalty Enforcement

- The server tracks whether a player has called UNO after reducing their hand to one card.
- The penalty window (the interval during which another player may challenge) is enforced server-side with a timestamp.
- A player cannot retroactively call UNO after the window has closed; the penalty draw is applied automatically.

### Audit Logging

- All game actions (play card, draw card, call UNO, challenge, skip) are written to the `game_events` table with player ID, timestamp, action type, and relevant card/state data.
- Logs are retained for post-game review and anomaly detection.

---

## 7. Data Security

### Database Access

- The PostgreSQL database is deployed on a private IP address with no public internet access.
- Backend services connect over the internal VPC network only.
- Database credentials are never embedded in application code or container images.

### Secret Management

- All secrets (database passwords, Redis credentials, Firebase service account keys, API keys) are stored in GCP Secret Manager.
- The backend retrieves secrets at startup via the Secret Manager API using the Cloud Run service account's identity.
- Secrets are never written to disk, environment variable files committed to version control, or included in Docker image layers.

### Logging Restrictions

The following data is never written to application logs:

- Individual player card hands or deck contents.
- JWT tokens or any portion thereof.
- Personally identifiable information beyond a hashed or truncated player ID for correlation.
- Raw WebSocket message payloads (only action type and outcome are logged).

### Redis Encryption

- Game state cached in Redis (player hands, game phase, turn order) is encrypted at rest using GCP-managed encryption keys on the Memorystore instance.
- Redis is accessible only from within the private VPC; there is no public endpoint.

---

## 8. Network Security

### Transport Encryption

- HTTPS is enforced for all HTTP traffic in production. Cloud Run rejects plain HTTP requests.
- WSS (WebSocket Secure) is enforced for all WebSocket connections. Plain WS connections are not accepted.
- TLS 1.2 is the minimum accepted version; TLS 1.0 and 1.1 are disabled.

### CORS Policy

- Cross-Origin Resource Sharing is configured with an explicit allowlist of permitted origins.
- Only the production frontend domain and, in staging environments, the staging domain are permitted.
- Wildcard (`*`) origins are never used in production.
- Credentials mode is enabled only for the allowlisted origins.

### Security Headers

The following HTTP response headers are set on all responses:

- `Strict-Transport-Security: max-age=31536000; includeSubDomains` (HSTS)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Content-Security-Policy` restricting script, style, and connection sources to known origins
- `Referrer-Policy: strict-origin-when-cross-origin`

### Redirect Policy

- There are no server-side HTTP-to-HTTP redirects. All redirects go from HTTP to HTTPS.
- Open redirects are not present; redirect targets are validated against an allowlist.

---

## 9. Dependencies

### Go Module Verification

- `go mod verify` is run in CI on every pull request and merge to main to confirm module checksums match the module proxy record.
- The `go.sum` file is committed to version control and any unexpected changes fail the CI build.

### Container Image Scanning

- Trivy is integrated into the CI pipeline and scans the production Docker image for known CVEs on every build.
- Builds with HIGH or CRITICAL severity CVEs that have available fixes are blocked from deployment.
- Scan results are archived as CI artifacts for audit purposes.

### Automated Dependency Updates

- Dependabot is configured for both Go modules and GitHub Actions dependencies.
- Security updates are applied automatically; version bumps are opened as pull requests for review.
- Dependabot PRs require passing CI and a code review before merge.

---

## 10. Pre-Launch Security Checklist

Use this checklist before each production deployment. All items must be checked before launch.

### Authentication and Authorization
- [ ] Firebase project ID is set correctly in production configuration; staging project ID is not used in production.
- [ ] JWT verification rejects tokens with incorrect `aud` and `iss` claims.
- [ ] All routes except `/health` and `/metrics` return 401 for requests without a valid token.
- [ ] Card ownership is verified server-side before every PlayCard action in integration tests.
- [ ] WebSocket upgrade is rejected for requests without a valid token.

### Input Validation and Anti-Cheat
- [ ] WebSocket messages with unknown fields are rejected and logged.
- [ ] Card IDs that are not valid UUIDs return an error and do not reach the database.
- [ ] Player names exceeding 50 characters are rejected or truncated before storage.
- [ ] Room codes not matching the 6-character alphanumeric pattern are rejected.
- [ ] WD4 legality check is covered by server-side unit tests with a hand containing the current suit.
- [ ] Sequence number replay rejection is covered by unit tests.

### Rate Limiting
- [ ] HTTP rate limit (100 req/min per IP) is verified with a load test returning 429 responses.
- [ ] WebSocket rate limit (10 actions/sec per player) returns an error message without disconnecting on first violation.
- [ ] Matchmaking rate limit (5 joins/min per player) is active in production configuration.

### Data and Secrets
- [ ] No secrets, credentials, or API keys appear in the repository (run `git log --all -S 'password\|secret\|token\|key' -- '*.go' '*.yaml' '*.env'` to verify).
- [ ] All secrets are sourced from GCP Secret Manager; no `.env` files are deployed with the container.
- [ ] Database is confirmed to have no public IP address in the Cloud SQL console.
- [ ] Redis instance has no public IP address in the Memorystore console.
- [ ] Application logs do not contain card hand data, JWT tokens, or raw message payloads (verified by log sampling in staging).

### Network and Headers
- [ ] HSTS header is present on production HTTPS responses.
- [ ] CORS allowlist contains only the production frontend domain (no wildcard, no localhost).
- [ ] Content-Security-Policy header is present and does not use `unsafe-inline` for scripts.
- [ ] Trivy scan passes with no unmitigated HIGH or CRITICAL CVEs in the deployed image.
- [ ] `go mod verify` passes in CI with no checksum mismatches.
- [ ] Dependabot has no open security advisories that have not been reviewed.

---

## 11. Responsible Disclosure

We take security seriously and appreciate the security research community's efforts to help keep UNO Multiplayer safe for all players.

### Reporting a Vulnerability

If you discover a security vulnerability, please report it by emailing:

**security@yourdomain.com**

Please include:

- A description of the vulnerability and the potential impact.
- Steps to reproduce the issue, including any relevant request or WebSocket payloads.
- The version or deployment environment where the issue was observed.
- Your contact information for follow-up questions.

### Our Commitment

- We will acknowledge receipt of your report within **48 hours**.
- We will provide an initial assessment of the severity and scope within **7 days**.
- We will work to remediate confirmed vulnerabilities and keep you informed of progress.
- We will notify you when the fix has been deployed.

### Disclosure Policy

- We follow a **90-day coordinated disclosure policy**. We ask that you do not publicly disclose the vulnerability until 90 days after your initial report, or until we have released a fix, whichever comes first.
- If we require more time due to complexity, we will communicate this and request an extension.
- We will credit researchers who report valid vulnerabilities in our release notes, unless they prefer to remain anonymous.

### Scope

The following are in scope for responsible disclosure:

- Authentication bypass or token forgery
- Authorization flaws allowing access to other players' data
- Server-side game logic exploits enabling cheating
- SQL injection or other data-layer vulnerabilities
- WebSocket session hijacking

The following are out of scope:

- Denial of service through resource exhaustion that requires significant infrastructure
- Social engineering of players or staff
- Vulnerabilities in third-party services (Firebase, GCP) not caused by our configuration
- Clickjacking on pages that do not handle sensitive actions
