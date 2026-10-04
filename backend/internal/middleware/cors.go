package middleware

import (
	"net/http"
	"strings"
)

// CORSConfig configures the CORS middleware.
type CORSConfig struct {
	// AllowedOrigins is the list of origins that are allowed.
	// Use ["*"] to allow all origins.
	AllowedOrigins []string

	// AllowedMethods defaults to GET, POST, PUT, PATCH, DELETE, OPTIONS.
	AllowedMethods []string

	// AllowedHeaders defaults to Content-Type, Authorization, X-Request-ID.
	AllowedHeaders []string

	// MaxAge is the value for the Access-Control-Max-Age header in seconds.
	// Defaults to 86400 (24 h).
	MaxAge string

	// AllowCredentials controls whether the Access-Control-Allow-Credentials
	// header is set to "true". Defaults to false. Only enable this when the
	// application explicitly requires cookie- or credential-based cross-origin
	// requests; leaving it false removes a CSRF attack surface.
	AllowCredentials bool
}

var defaultMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"}
var defaultHeaders = []string{"Content-Type", "Authorization", "X-Request-ID"}

// CORS returns middleware that handles Cross-Origin Resource Sharing headers
// and responds to preflight OPTIONS requests.
func CORS(cfg CORSConfig) func(http.Handler) http.Handler {
	if len(cfg.AllowedMethods) == 0 {
		cfg.AllowedMethods = defaultMethods
	}
	if len(cfg.AllowedHeaders) == 0 {
		cfg.AllowedHeaders = defaultHeaders
	}
	if cfg.MaxAge == "" {
		cfg.MaxAge = "86400"
	}

	allowedMethodsStr := strings.Join(cfg.AllowedMethods, ", ")
	allowedHeadersStr := strings.Join(cfg.AllowedHeaders, ", ")
	allowAll := len(cfg.AllowedOrigins) == 1 && cfg.AllowedOrigins[0] == "*"

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			if origin == "" {
				// Not a CORS request.
				next.ServeHTTP(w, r)
				return
			}

			if allowAll || isOriginAllowed(origin, cfg.AllowedOrigins) {
				w.Header().Set("Access-Control-Allow-Origin", origin)
				w.Header().Set("Vary", "Origin")
				if cfg.AllowCredentials {
					w.Header().Set("Access-Control-Allow-Credentials", "true")
				}
			} else {
				// Origin not allowed; continue without CORS headers.
				next.ServeHTTP(w, r)
				return
			}

			if r.Method == http.MethodOptions {
				// Preflight request.
				w.Header().Set("Access-Control-Allow-Methods", allowedMethodsStr)
				w.Header().Set("Access-Control-Allow-Headers", allowedHeadersStr)
				w.Header().Set("Access-Control-Max-Age", cfg.MaxAge)
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// isOriginAllowed returns true when origin is in the allowed list.
func isOriginAllowed(origin string, allowed []string) bool {
	for _, o := range allowed {
		if strings.EqualFold(o, origin) {
			return true
		}
	}
	return false
}
