package observability

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
)

// Status values for HealthStatus and CheckResult.
const (
	StatusHealthy   = "healthy"
	StatusDegraded  = "degraded"
	StatusUnhealthy = "unhealthy"
)

// Pinger is the minimal interface required of dependencies for health checking.
// Both *sql.DB and *redis.Client satisfy this interface.
type Pinger interface {
	// PingContext verifies the connection to the underlying resource is still
	// alive, establishing a connection if necessary.
	PingContext(ctx context.Context) error
}

// WSCounter provides the current WebSocket connection count. Implement this
// on *hub.Hub (or any wrapper) by reading from the hub's active-client map.
type WSCounter interface {
	// ActiveConnections returns the number of currently active connections.
	ActiveConnections() int
}

// CheckResult carries the outcome of a single dependency health check.
type CheckResult struct {
	// Status is one of StatusHealthy, StatusDegraded, or StatusUnhealthy.
	Status string `json:"status"`

	// LatencyMS is the round-trip time of the check in milliseconds.
	LatencyMS int64 `json:"latency_ms"`

	// Error is non-empty when the check failed.
	Error string `json:"error,omitempty"`

	// Message carries optional human-readable context for healthy checks (e.g.
	// the active connection count for the websocket check).
	Message string `json:"message,omitempty"`
}

// HealthStatus is the top-level payload returned by GET /health.
type HealthStatus struct {
	// Status is the aggregate status of all checks.
	// healthy   – all checks passed.
	// degraded  – at least one check is degraded but none are unhealthy.
	// unhealthy – at least one check is unhealthy.
	Status string `json:"status"`

	// Version is the build version of the running binary, set at link time.
	Version string `json:"version"`

	// Timestamp is the RFC-3339 time at which the check was performed.
	Timestamp string `json:"timestamp"`

	// Checks contains the individual check results keyed by name.
	Checks map[string]CheckResult `json:"checks"`
}

// HealthChecker runs all registered health checks and aggregates the result.
type HealthChecker struct {
	mu        sync.RWMutex
	checks    map[string]checkFn
	version   string
}

// checkFn is the internal function signature for a single health check.
type checkFn func(ctx context.Context) CheckResult

// NewHealthChecker creates a HealthChecker with the given build version string.
func NewHealthChecker(version string) *HealthChecker {
	return &HealthChecker{
		checks:  make(map[string]checkFn),
		version: version,
	}
}

// RegisterDatabase adds a "database" check that pings the supplied Pinger.
func (hc *HealthChecker) RegisterDatabase(db Pinger) {
	hc.register("database", func(ctx context.Context) CheckResult {
		return pingCheck(ctx, db)
	})
}

// RegisterRedis adds a "redis" check that pings the supplied Pinger.
func (hc *HealthChecker) RegisterRedis(rdb Pinger) {
	hc.register("redis", func(ctx context.Context) CheckResult {
		return pingCheck(ctx, rdb)
	})
}

// RegisterWebSocket adds a "websocket" check that reports the active connection
// count. The check is always healthy; it exists to expose the metric in the
// health payload.
func (hc *HealthChecker) RegisterWebSocket(counter WSCounter) {
	hc.register("websocket", func(_ context.Context) CheckResult {
		n := counter.ActiveConnections()
		return CheckResult{
			Status:    StatusHealthy,
			LatencyMS: 0,
			Message:   fmt.Sprintf("active_connections=%d", n),
		}
	})
}

// Register adds a named custom check function. The function must return
// quickly (callers impose a per-check deadline via the context).
func (hc *HealthChecker) Register(name string, fn func(ctx context.Context) CheckResult) {
	hc.register(name, fn)
}

func (hc *HealthChecker) register(name string, fn checkFn) {
	hc.mu.Lock()
	defer hc.mu.Unlock()
	hc.checks[name] = fn
}

// Check runs all registered checks concurrently with a 5-second per-check
// deadline derived from ctx, then aggregates and returns a HealthStatus.
func (hc *HealthChecker) Check(ctx context.Context) HealthStatus {
	hc.mu.RLock()
	// Snapshot the map so we can release the lock before running checks.
	snapshot := make(map[string]checkFn, len(hc.checks))
	for k, v := range hc.checks {
		snapshot[k] = v
	}
	hc.mu.RUnlock()

	type namedResult struct {
		name   string
		result CheckResult
	}

	results := make(chan namedResult, len(snapshot))
	checkCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var wg sync.WaitGroup
	for name, fn := range snapshot {
		wg.Add(1)
		go func(n string, f checkFn) {
			defer wg.Done()
			results <- namedResult{name: n, result: f(checkCtx)}
		}(name, fn)
	}

	// Close the channel once all goroutines have sent.
	go func() {
		wg.Wait()
		close(results)
	}()

	checks := make(map[string]CheckResult, len(snapshot))
	for r := range results {
		checks[r.name] = r.result
	}

	return HealthStatus{
		Status:    aggregate(checks),
		Version:   hc.version,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Checks:    checks,
	}
}

// HTTPHandler returns an http.HandlerFunc that serves GET /health.
// It responds with 200 OK when status is "healthy" and 503 Service Unavailable
// when status is "degraded" or "unhealthy".
func (hc *HealthChecker) HTTPHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		status := hc.Check(r.Context())

		code := http.StatusOK
		if status.Status != StatusHealthy {
			code = http.StatusServiceUnavailable
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(code)
		_ = json.NewEncoder(w).Encode(status)
	}
}

// ---- helpers ----

// pingCheck runs Pinger.PingContext and returns a CheckResult.
func pingCheck(ctx context.Context, p Pinger) CheckResult {
	start := time.Now()
	err := p.PingContext(ctx)
	latency := time.Since(start).Milliseconds()

	if err != nil {
		return CheckResult{
			Status:    StatusUnhealthy,
			LatencyMS: latency,
			Error:     err.Error(),
		}
	}

	return CheckResult{
		Status:    StatusHealthy,
		LatencyMS: latency,
	}
}

// aggregate computes the overall status from all individual check results.
// unhealthy dominates degraded which dominates healthy.
func aggregate(checks map[string]CheckResult) string {
	result := StatusHealthy
	for _, c := range checks {
		switch c.Status {
		case StatusUnhealthy:
			return StatusUnhealthy
		case StatusDegraded:
			result = StatusDegraded
		}
	}
	return result
}
