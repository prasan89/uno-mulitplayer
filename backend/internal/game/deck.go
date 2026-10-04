package game

import (
	"math/rand"

	"github.com/google/uuid"
)

// newCard creates a new card with a fresh UUID.
func newCard(color Color, cardType CardType, value int) Card {
	return Card{
		ID:    uuid.New().String(),
		Color: color,
		Type:  cardType,
		Value: value,
	}
}

// NewDeck creates and returns a standard shuffled 108-card WildDeck deck.
//
// Composition:
//   - 4 colors x 1 zero card              =  4 cards
//   - 4 colors x 2 each of 1-9            = 72 cards
//   - 4 colors x 2 Skip                   =  8 cards
//   - 4 colors x 2 Reverse                =  8 cards
//   - 4 colors x 2 Draw Two               =  8 cards
//   - 4 Wild                              =  4 cards
//   - 4 Wild Draw Four                    =  4 cards
//   Total                                 = 108 cards
func NewDeck() []Card {
	cards := make([]Card, 0, 108)

	coloredSuits := []Color{ColorRed, ColorGreen, ColorBlue, ColorYellow}

	for _, color := range coloredSuits {
		// One zero per color
		cards = append(cards, newCard(color, CardTypeNumber, 0))

		// Two of each 1-9 per color
		for i := 1; i <= 9; i++ {
			cards = append(cards, newCard(color, CardTypeNumber, i))
			cards = append(cards, newCard(color, CardTypeNumber, i))
		}

		// Two Skip per color
		cards = append(cards, newCard(color, CardTypeSkip, 20))
		cards = append(cards, newCard(color, CardTypeSkip, 20))

		// Two Reverse per color
		cards = append(cards, newCard(color, CardTypeReverse, 20))
		cards = append(cards, newCard(color, CardTypeReverse, 20))

		// Two Draw Two per color
		cards = append(cards, newCard(color, CardTypeDrawTwo, 20))
		cards = append(cards, newCard(color, CardTypeDrawTwo, 20))
	}

	// Four Wild cards
	for i := 0; i < 4; i++ {
		cards = append(cards, newCard(ColorWild, CardTypeWild, 50))
	}

	// Four Wild Draw Four cards
	for i := 0; i < 4; i++ {
		cards = append(cards, newCard(ColorWild, CardTypeWildDrawFour, 50))
	}

	shuffle(cards)
	return cards
}

// shuffle performs an in-place Fisher-Yates shuffle on the provided slice.
func shuffle(cards []Card) {
	for i := len(cards) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		cards[i], cards[j] = cards[j], cards[i]
	}
}

// NewDeckWithRand creates a deck shuffled with the provided random source.
// Useful for deterministic testing.
func NewDeckWithRand(r *rand.Rand) []Card {
	cards := make([]Card, 0, 108)
	coloredSuits := []Color{ColorRed, ColorGreen, ColorBlue, ColorYellow}
	for _, color := range coloredSuits {
		cards = append(cards, newCard(color, CardTypeNumber, 0))
		for i := 1; i <= 9; i++ {
			cards = append(cards, newCard(color, CardTypeNumber, i))
			cards = append(cards, newCard(color, CardTypeNumber, i))
		}
		cards = append(cards, newCard(color, CardTypeSkip, 20))
		cards = append(cards, newCard(color, CardTypeSkip, 20))
		cards = append(cards, newCard(color, CardTypeReverse, 20))
		cards = append(cards, newCard(color, CardTypeReverse, 20))
		cards = append(cards, newCard(color, CardTypeDrawTwo, 20))
		cards = append(cards, newCard(color, CardTypeDrawTwo, 20))
	}
	for i := 0; i < 4; i++ {
		cards = append(cards, newCard(ColorWild, CardTypeWild, 50))
	}
	for i := 0; i < 4; i++ {
		cards = append(cards, newCard(ColorWild, CardTypeWildDrawFour, 50))
	}
	for i := len(cards) - 1; i > 0; i-- {
		j := r.Intn(i + 1)
		cards[i], cards[j] = cards[j], cards[i]
	}
	return cards
}

// cloneCards returns a shallow copy of the provided card slice.
// Because Card contains no pointer fields the shallow copy is a full copy.
func cloneCards(src []Card) []Card {
	if src == nil {
		return nil
	}
	dst := make([]Card, len(src))
	copy(dst, src)
	return dst
}
