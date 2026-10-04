package middleware

import (
	"net"
	"net/http"
	"sync"
	"time"

	"golang.org/x/time/rate"
)

// ipLimiter holds the per-IP limiter and its last-seen time.
type ipLimiter struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// RateLimitConfig configures the RateLimit middleware.
type RateLimitConfig struct {
	// RequestsPerMinute is the number of requests allowed per IP per minute.
	// Defaults to 100.
	RequestsPerMinute int

	// CleanupInterval controls how often stale IP entries are evicted.
	// Defaults to 5 minutes.
	CleanupInterval time.Duration

	// TrustedProxies is an optional list of CIDR ranges (e.g. "10.0.0.0/8",
	// "127.0.0.1/32") whose requests are allowed to supply X-Forwarded-For /
	// X-Real-Ip headers. When empty, proxy headers are ignored and the rate
	// limiter always uses RemoteAddr directly, preventing clients from spoofing
	// their IP to evade rate limiting.
	TrustedProxies []string
}

// RateLimiter implements per-IP token-bucket rate limiting.
type RateLimiter struct {
	mu             sync.Mutex
	limiters       map[string]*ipLimiter
	r              rate.Limit
	b              int
	stop           chan struct{}
	trustedProxies []*net.IPNet
}

// NewRateLimiter creates a RateLimiter that enforces cfg.RequestsPerMinute
// requests per IP per minute with a burst equal to twice that rate.
func NewRateLimiter(cfg RateLimitConfig) *RateLimiter {
	rpm := cfg.RequestsPerMinute
	if rpm <= 0 {
		rpm = 100
	}

	cleanInterval := cfg.CleanupInterval
	if cleanInterval <= 0 {
		cleanInterval = 5 * time.Minute
	}

	var trustedNets []*net.IPNet
	for _, cidr := range cfg.TrustedProxies {
		_, network, err := net.ParseCIDR(cidr)
		if err == nil {
			trustedNets = append(trustedNets, network)
		}
	}

	rl := &RateLimiter{
		limiters:       make(map[string]*ipLimiter),
		r:              rate.Limit(float64(rpm) / 60.0), // per-second rate
		b:              rpm * 2,                          // burst
		stop:           make(chan struct{}),
		trustedProxies: trustedNets,
	}

	go rl.cleanup(cleanInterval)
	return rl
}

// getLimiter returns (or creates) the rate.Limiter for the given IP.
func (rl *RateLimiter) getLimiter(ip string) *rate.Limiter {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	entry, ok := rl.limiters[ip]
	if !ok {
		entry = &ipLimiter{limiter: rate.NewLimiter(rl.r, rl.b)}
		rl.limiters[ip] = entry
	}
	entry.lastSeen = time.Now()
	return entry.limiter
}

// cleanup periodically removes entries that have been idle for more than 3x
// the cleanup interval.
func (rl *RateLimiter) cleanup(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			cutoff := time.Now().Add(-3 * interval)
			rl.mu.Lock()
			for ip, e := range rl.limiters {
				if e.lastSeen.Before(cutoff) {
					delete(rl.limiters, ip)
				}
			}
			rl.mu.Unlock()
		case <-rl.stop:
			return
		}
	}
}

// Stop terminates the background cleanup goroutine.
func (rl *RateLimiter) Stop() {
	close(rl.stop)
}

// Handler returns an http.Handler middleware that enforces the rate limit.
func (rl *RateLimiter) Handler() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := realIP(r, rl.trustedProxies)
			if !rl.getLimiter(ip).Allow() {
				http.Error(w, "rate limit exceeded", http.StatusTooManyRequests)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// remoteAddrIP returns the IP portion of r.RemoteAddr (strips the port).
func remoteAddrIP(r *http.Request) string {
	addr := r.RemoteAddr
	// Handle "[::1]:port" (IPv6) and "1.2.3.4:port" (IPv4).
	host, _, err := net.SplitHostPort(addr)
	if err == nil {
		return host
	}
	// Fallback: scan for the last colon (legacy path, no port present).
	for i := len(addr) - 1; i >= 0; i-- {
		if addr[i] == ':' {
			return addr[:i]
		}
	}
	return addr
}

// isTrustedProxy reports whether the connecting address (r.RemoteAddr) falls
// within one of the configured trusted CIDR ranges.
func isTrustedProxy(r *http.Request, trusted []*net.IPNet) bool {
	if len(trusted) == 0 {
		return false
	}
	raw := remoteAddrIP(r)
	ip := net.ParseIP(raw)
	if ip == nil {
		return false
	}
	for _, network := range trusted {
		if network.Contains(ip) {
			return true
		}
	}
	return false
}

// realIP extracts the real client IP from the request. Proxy headers
// (X-Forwarded-For, X-Real-Ip) are only trusted when the direct connection
// originates from a known trusted proxy CIDR. If the request does not come
// from a trusted proxy, RemoteAddr is used unconditionally, preventing
// clients from spoofing their IP to bypass the per-IP rate limiter.
func realIP(r *http.Request, trusted []*net.IPNet) string {
	if isTrustedProxy(r, trusted) {
		if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
			// X-Forwarded-For can be a comma-separated list; use the first entry
			// (the original client IP added by the outermost proxy).
			parts := splitComma(xff)
			if len(parts) > 0 {
				if ip := trim(parts[0]); ip != "" {
					return ip
				}
			}
		}
		if xri := r.Header.Get("X-Real-Ip"); xri != "" {
			if ip := trim(xri); ip != "" {
				return ip
			}
		}
	}
	return remoteAddrIP(r)
}

func splitComma(s string) []string {
	var parts []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == ',' {
			parts = append(parts, s[start:i])
			start = i + 1
		}
	}
	parts = append(parts, s[start:])
	return parts
}

func trim(s string) string {
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t') {
		s = s[:len(s)-1]
	}
	return s
}
