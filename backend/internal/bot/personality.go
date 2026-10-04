package bot

// Personality defines a named AI character that modifies decision weights.
// Personalities sit on top of the difficulty Strategy: they influence
// card-selection probabilities without replacing the core engine.
type Personality string

const (
	PersonalityRex   Personality = "Rex"   // Aggressive: chases action cards
	PersonalityNova  Personality = "Nova"  // Strategic: preserves wilds, plans ahead
	PersonalityMilo  Personality = "Milo"  // Casual: mostly relaxed, low pressure
	PersonalityBlaze Personality = "Blaze" // Risk Taker: loves wildcards, bluffs
)

// PersonalityWeights controls how a personality adjusts the AI's decisions.
// All fields are multipliers applied to the base strategy probability.
type PersonalityWeights struct {
	// Aggression increases the tendency to play action cards (skip/reverse/draw).
	Aggression float64

	// RiskTolerance increases willingness to play Wild Draw Four as a bluff.
	RiskTolerance float64

	// WildPreference increases tendency to play wild cards earlier.
	WildPreference float64

	// ActionCardPreference increases preference for action cards over number cards.
	ActionCardPreference float64
}

// defaultWeights is the baseline: neutral modifier on all factors.
var defaultWeights = PersonalityWeights{
	Aggression:           1.0,
	RiskTolerance:        1.0,
	WildPreference:       1.0,
	ActionCardPreference: 1.0,
}

// personalityWeights maps each personality to its modifier profile.
var personalityWeights = map[Personality]PersonalityWeights{
	PersonalityRex: {
		Aggression:           1.8,
		RiskTolerance:        1.2,
		WildPreference:       0.7,
		ActionCardPreference: 1.6,
	},
	PersonalityNova: {
		Aggression:           0.8,
		RiskTolerance:        0.6,
		WildPreference:       0.5,
		ActionCardPreference: 0.9,
	},
	PersonalityMilo: {
		Aggression:           0.6,
		RiskTolerance:        0.8,
		WildPreference:       1.2,
		ActionCardPreference: 0.7,
	},
	PersonalityBlaze: {
		Aggression:           1.3,
		RiskTolerance:        2.0,
		WildPreference:       1.8,
		ActionCardPreference: 1.1,
	},
}

// WeightsFor returns the PersonalityWeights for the given personality,
// falling back to defaultWeights for unknown values.
func WeightsFor(p Personality) PersonalityWeights {
	if w, ok := personalityWeights[p]; ok {
		return w
	}
	return defaultWeights
}

// allPersonalities is the ordered pool of AI personalities used when assigning
// bots to seats in a VS AI game.
var allPersonalities = []Personality{
	PersonalityRex,
	PersonalityNova,
	PersonalityMilo,
	PersonalityBlaze,
}

// PersonalityAt returns the personality for the given seat index (0-based),
// cycling through allPersonalities.
func PersonalityAt(seatIndex int) Personality {
	return allPersonalities[seatIndex%len(allPersonalities)]
}

// ThinkDelayRange returns the min/max think delay in milliseconds for a given
// difficulty level.
func ThinkDelayRange(d Difficulty) (minMs, maxMs int) {
	switch d {
	case DifficultyEasy:
		return 500, 1200
	case DifficultyMedium:
		return 700, 1500
	default: // Hard
		return 900, 1800
	}
}
