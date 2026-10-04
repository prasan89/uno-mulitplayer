// Package auth provides Firebase ID token verification for the WildDeck server.
// It fetches Google's public RSA keys, caches them per Cache-Control TTL, and validates
// RS256-signed JWTs issued by Firebase Authentication.
package auth

import (
	"context"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"
)

const (
	// googlePublicKeysURL is the endpoint that serves the current RSA public keys
	// Firebase uses to sign ID tokens.
	googlePublicKeysURL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

	// defaultKeyTTL is the fallback cache duration when Cache-Control cannot be parsed.
	defaultKeyTTL = 6 * time.Hour

	// minKeyTTL ensures we never cache stale keys due to clock skew.
	minKeyTTL = 5 * time.Minute

	// fetchTimeout is the HTTP request timeout for key refresh.
	fetchTimeout = 10 * time.Second
)

// Claims contains the verified payload extracted from a Firebase ID token.
type Claims struct {
	// UID is the unique Firebase user identifier (the "sub" JWT claim).
	UID string

	// Email is the user's email address if present.
	Email string

	// EmailVerified reports whether the user's email address has been verified.
	EmailVerified bool

	// Name is the user's display name if present.
	Name string

	// Picture is the URL to the user's profile picture if present.
	Picture string
}

// firebaseClaims extends jwt.RegisteredClaims with Firebase-specific fields.
type firebaseClaims struct {
	jwt.RegisteredClaims

	// firebase wraps user identity data embedded in the token.
	Firebase firebaseIdentities `json:"firebase"`

	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
}

// firebaseIdentities holds the nested identities object inside Firebase tokens.
type firebaseIdentities struct {
	Identities map[string]interface{} `json:"identities"`
	SignInProvider string              `json:"sign_in_provider"`
}

// keyCache holds the cached RSA public keys and their expiry.
type keyCache struct {
	mu      sync.RWMutex
	keys    map[string]*rsa.PublicKey
	expiry  time.Time
}

// FirebaseAuth verifies Firebase ID tokens using Google's public RSA keys.
type FirebaseAuth struct {
	projectID  string
	httpClient *http.Client
	cache      keyCache
	logger     *zap.Logger
}

// NewFirebaseAuth creates a new FirebaseAuth for the given Firebase project ID.
func NewFirebaseAuth(projectID string, logger *zap.Logger) *FirebaseAuth {
	return &FirebaseAuth{
		projectID: projectID,
		httpClient: &http.Client{
			Timeout: fetchTimeout,
		},
		logger: logger,
	}
}

// VerifyToken verifies the Firebase ID token and returns the extracted Claims.
// It returns an error if the token is expired, has an invalid signature, wrong
// audience or issuer, or any other JWT validation failure.
func (fa *FirebaseAuth) VerifyToken(ctx context.Context, idToken string) (*Claims, error) {
	keys, err := fa.getPublicKeys(ctx)
	if err != nil {
		return nil, fmt.Errorf("auth: failed to fetch public keys: %w", err)
	}

	claims := &firebaseClaims{}
	token, err := jwt.ParseWithClaims(idToken, claims, func(t *jwt.Token) (interface{}, error) {
		// Enforce RS256 algorithm – reject any other algorithm to prevent alg confusion.
		if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("auth: unexpected signing method: %v", t.Header["alg"])
		}

		kid, ok := t.Header["kid"].(string)
		if !ok || kid == "" {
			return nil, errors.New("auth: token missing kid header")
		}

		key, found := keys[kid]
		if !found {
			return nil, fmt.Errorf("auth: no public key found for kid %q", kid)
		}
		return key, nil
	},
		jwt.WithAudience(fa.projectID),
		jwt.WithIssuer("https://securetoken.google.com/"+fa.projectID),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
	)
	if err != nil {
		return nil, fmt.Errorf("auth: token validation failed: %w", err)
	}
	if !token.Valid {
		return nil, errors.New("auth: token is not valid")
	}

	// Validate the subject (UID) is non-empty.
	uid, err := claims.GetSubject()
	if err != nil || uid == "" {
		return nil, errors.New("auth: token missing subject claim")
	}

	// Validate issued-at is not in the future.
	if claims.IssuedAt != nil && claims.IssuedAt.After(time.Now().Add(5*time.Minute)) {
		return nil, errors.New("auth: token iat is in the future")
	}

	return &Claims{
		UID:           uid,
		Email:         claims.Email,
		EmailVerified: claims.EmailVerified,
		Name:          claims.Name,
		Picture:       claims.Picture,
	}, nil
}

// getPublicKeys returns the cached RSA public keys or fetches fresh ones if the
// cache has expired.
func (fa *FirebaseAuth) getPublicKeys(ctx context.Context) (map[string]*rsa.PublicKey, error) {
	fa.cache.mu.RLock()
	if time.Now().Before(fa.cache.expiry) && len(fa.cache.keys) > 0 {
		keys := fa.cache.keys
		fa.cache.mu.RUnlock()
		return keys, nil
	}
	fa.cache.mu.RUnlock()

	// Upgrade to write lock to refresh the cache.
	fa.cache.mu.Lock()
	defer fa.cache.mu.Unlock()

	// Double-check after acquiring the write lock; another goroutine may have
	// already refreshed.
	if time.Now().Before(fa.cache.expiry) && len(fa.cache.keys) > 0 {
		return fa.cache.keys, nil
	}

	keys, ttl, err := fa.fetchPublicKeys(ctx)
	if err != nil {
		// If we have stale keys, return them and log the error rather than
		// failing all requests during a temporary outage.
		if len(fa.cache.keys) > 0 {
			fa.logger.Warn("auth: failed to refresh public keys, using stale cache",
				zap.Error(err),
				zap.Time("stale_expiry", fa.cache.expiry),
			)
			// Extend the stale cache for 5 more minutes to avoid hammering the endpoint.
			fa.cache.expiry = time.Now().Add(5 * time.Minute)
			return fa.cache.keys, nil
		}
		return nil, err
	}

	fa.cache.keys = keys
	fa.cache.expiry = time.Now().Add(ttl)
	fa.logger.Info("auth: refreshed Firebase public keys",
		zap.Int("key_count", len(keys)),
		zap.Duration("ttl", ttl),
	)
	return keys, nil
}

// fetchPublicKeys downloads the x509 certificates from Google, parses the RSA
// public keys, and extracts the Cache-Control max-age TTL.
func (fa *FirebaseAuth) fetchPublicKeys(ctx context.Context) (map[string]*rsa.PublicKey, time.Duration, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, googlePublicKeysURL, nil)
	if err != nil {
		return nil, 0, fmt.Errorf("auth: failed to create key request: %w", err)
	}

	resp, err := fa.httpClient.Do(req)
	if err != nil {
		return nil, 0, fmt.Errorf("auth: key request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, 0, fmt.Errorf("auth: key endpoint returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024)) // 64 KB limit
	if err != nil {
		return nil, 0, fmt.Errorf("auth: failed to read key response body: %w", err)
	}

	// Parse the JSON object: map of kid → PEM-encoded x509 certificate.
	var pemCerts map[string]string
	if err := json.Unmarshal(body, &pemCerts); err != nil {
		return nil, 0, fmt.Errorf("auth: failed to unmarshal key response: %w", err)
	}

	keys := make(map[string]*rsa.PublicKey, len(pemCerts))
	for kid, pemStr := range pemCerts {
		key, err := parseRSAPublicKeyFromCert(pemStr)
		if err != nil {
			fa.logger.Warn("auth: failed to parse public key, skipping",
				zap.String("kid", kid),
				zap.Error(err),
			)
			continue
		}
		keys[kid] = key
	}

	if len(keys) == 0 {
		return nil, 0, errors.New("auth: no valid public keys found in response")
	}

	ttl := parseCacheControlMaxAge(resp.Header.Get("Cache-Control"))
	return keys, ttl, nil
}

// parseRSAPublicKeyFromCert parses a PEM-encoded x509 certificate and extracts
// the RSA public key.
func parseRSAPublicKeyFromCert(pemStr string) (*rsa.PublicKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, errors.New("auth: failed to decode PEM block")
	}

	cert, err := x509.ParseCertificate(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("auth: failed to parse x509 certificate: %w", err)
	}

	rsaKey, ok := cert.PublicKey.(*rsa.PublicKey)
	if !ok {
		return nil, errors.New("auth: public key is not RSA")
	}
	return rsaKey, nil
}

// parseCacheControlMaxAge extracts the max-age value from a Cache-Control header
// such as "public, max-age=21600, must-revalidate, no-transform".
// Returns defaultKeyTTL if the header cannot be parsed or the value is below minKeyTTL.
func parseCacheControlMaxAge(header string) time.Duration {
	for _, part := range strings.Split(header, ",") {
		part = strings.TrimSpace(part)
		if strings.HasPrefix(part, "max-age=") {
			seconds, err := strconv.ParseInt(strings.TrimPrefix(part, "max-age="), 10, 64)
			if err == nil && seconds > 0 {
				ttl := time.Duration(seconds) * time.Second
				if ttl < minKeyTTL {
					return minKeyTTL
				}
				return ttl
			}
		}
	}
	return defaultKeyTTL
}
