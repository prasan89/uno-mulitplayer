package middleware

import (
	"context"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"
)

// contextKey is an unexported type for context keys used in this package.
type contextKey int

const (
	// ClaimsKey is the context key for the validated Firebase Claims.
	ClaimsKey contextKey = iota
)

// Claims holds the validated Firebase JWT claims.
// UserID is populated from the JWT "sub" (subject) field after successful validation.
type Claims struct {
	// UserID is the Firebase UID, copied from RegisteredClaims.Subject after
	// parsing so callers do not need to know about the standard claim layout.
	UserID string
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// FirebaseKeySet caches Google's public keys used to verify Firebase JWTs.
type FirebaseKeySet struct {
	mu      sync.RWMutex
	keys    map[string]*rsa.PublicKey
	expires time.Time
}

var globalKeySet = &FirebaseKeySet{}

const googleCertURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

// fetchKeys downloads and caches the Google public keys.
func (ks *FirebaseKeySet) fetchKeys() error {
	resp, err := http.Get(googleCertURL) //nolint:gosec
	if err != nil {
		return fmt.Errorf("fetch firebase keys: %w", err)
	}
	defer resp.Body.Close()

	// Parse cache-control max-age so we know when to refresh.
	expires := time.Now().Add(1 * time.Hour)
	if cc := resp.Header.Get("Cache-Control"); cc != "" {
		var maxAge int
		if _, err := fmt.Sscanf(cc, "public, max-age=%d", &maxAge); err == nil && maxAge > 0 {
			expires = time.Now().Add(time.Duration(maxAge) * time.Second)
		}
	}

	var rawCerts map[string]string
	if err := json.NewDecoder(io.LimitReader(resp.Body, 64*1024)).Decode(&rawCerts); err != nil {
		return fmt.Errorf("decode firebase certs: %w", err)
	}

	keys := make(map[string]*rsa.PublicKey, len(rawCerts))
	for kid, certPEM := range rawCerts {
		pub, err := jwt.ParseRSAPublicKeyFromPEM([]byte(certPEM))
		if err != nil {
			continue
		}
		keys[kid] = pub
	}

	ks.mu.Lock()
	ks.keys = keys
	ks.expires = expires
	ks.mu.Unlock()
	return nil
}

// getKey returns the RSA public key for the given key ID, refreshing the cache
// if necessary.
func (ks *FirebaseKeySet) getKey(kid string) (*rsa.PublicKey, error) {
	ks.mu.RLock()
	expired := time.Now().After(ks.expires)
	key := ks.keys[kid]
	ks.mu.RUnlock()

	if expired || key == nil {
		if err := ks.fetchKeys(); err != nil {
			return nil, err
		}
		ks.mu.RLock()
		key = ks.keys[kid]
		ks.mu.RUnlock()
	}

	if key == nil {
		return nil, fmt.Errorf("unknown key id: %s", kid)
	}
	return key, nil
}

// parseJWKS parses a JWKS JSON document and returns an RSA public key for the
// given kid. Used as a fallback for environments where the cert endpoint is
// unavailable.
func parseJWKSKey(jwksJSON []byte, kid string) (*rsa.PublicKey, error) {
	var jwks struct {
		Keys []struct {
			Kid string `json:"kid"`
			N   string `json:"n"`
			E   string `json:"e"`
		} `json:"keys"`
	}
	if err := json.Unmarshal(jwksJSON, &jwks); err != nil {
		return nil, err
	}
	for _, k := range jwks.Keys {
		if k.Kid != kid {
			continue
		}
		nBytes, err := base64.RawURLEncoding.DecodeString(k.N)
		if err != nil {
			return nil, err
		}
		eBytes, err := base64.RawURLEncoding.DecodeString(k.E)
		if err != nil {
			return nil, err
		}
		eInt := new(big.Int).SetBytes(eBytes)
		return &rsa.PublicKey{
			N: new(big.Int).SetBytes(nBytes),
			E: int(eInt.Int64()),
		}, nil
	}
	return nil, fmt.Errorf("kid %s not found in JWKS", kid)
}

// AuthConfig configures the Auth middleware.
type AuthConfig struct {
	// ProjectID is the Firebase project ID used to validate audience and issuer.
	ProjectID string
	Logger    *zap.Logger
}

// Auth validates a Firebase ID token passed in the Authorization header.
// On success it injects the parsed Claims into the request context.
func Auth(cfg AuthConfig) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, "missing authorization header", http.StatusUnauthorized)
				return
			}

			parts := strings.SplitN(authHeader, " ", 2)
			if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
				http.Error(w, "invalid authorization header format", http.StatusUnauthorized)
				return
			}
			tokenStr := parts[1]

			claims := &Claims{}
			token, err := jwt.ParseWithClaims(tokenStr, claims, func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
					return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
				}
				kid, ok := t.Header["kid"].(string)
				if !ok || kid == "" {
					return nil, fmt.Errorf("missing kid in token header")
				}
				return globalKeySet.getKey(kid)
			},
				jwt.WithAudience(cfg.ProjectID),
				jwt.WithIssuer("https://securetoken.google.com/"+cfg.ProjectID),
				jwt.WithExpirationRequired(),
			)

			if err != nil || !token.Valid {
				if cfg.Logger != nil {
					cfg.Logger.Debug("auth failed", zap.Error(err))
				}
				http.Error(w, "invalid or expired token", http.StatusUnauthorized)
				return
			}

			// Firebase stores the UID in the "sub" claim.
			claims.UserID = claims.Subject

			// Inject validated claims into context.
			ctx := context.WithValue(r.Context(), ClaimsKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// ClaimsFromContext extracts the Claims from the request context.
// Returns nil if no claims are present.
func ClaimsFromContext(ctx context.Context) *Claims {
	c, _ := ctx.Value(ClaimsKey).(*Claims)
	return c
}

// ensure parseJWKSKey is referenced to avoid unused-export lint noise in tests.
var _ = parseJWKSKey
