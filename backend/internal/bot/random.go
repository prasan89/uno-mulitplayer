package bot

import "math/rand"

// RandomProvider abstracts the source of randomness used by bot decision logic.
// Injecting this interface allows tests to use a deterministic seeded source
// while production code uses a cryptographically-seeded global source.
type RandomProvider interface {
	// Intn returns, as an int, a non-negative pseudo-random integer in [0,n).
	Intn(n int) int
}

// globalRandom uses the math/rand package-level functions backed by the
// default global source (automatically seeded since Go 1.20).
type globalRandom struct{}

func (globalRandom) Intn(n int) int { return rand.Intn(n) }

// GlobalRandom is the production RandomProvider that uses the global rand source.
var GlobalRandom RandomProvider = globalRandom{}

// SeededRandom creates a deterministic RandomProvider from the given seed.
// Use this in tests to make AI decisions fully reproducible.
func SeededRandom(seed int64) RandomProvider {
	src := rand.New(rand.NewSource(seed)) //nolint:gosec
	return src
}
