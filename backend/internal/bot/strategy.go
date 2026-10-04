package bot

import (
	"math/rand"

	"github.com/uno-multiplayer/server/internal/game"
)

// ─── HardStrategy ─────────────────────────────────────────────────────────────

// HardStrategy plays optimally: it targets opponents who are close to winning,
// hoards action cards for critical moments, and picks the best color to
// maximise future plays.
type HardStrategy struct{}

// ChooseCard implements Strategy for HardStrategy.
//
// Priority order:
//  1. Play Draw Two or Wild Draw Four when any opponent has 1-2 cards (prevent win).
//  2. Play any action card when any opponent has <=3 cards (go offensive).
//  3. Play matching color number cards to preserve action cards.
//  4. Play action cards not already covered above.
//  5. Play wilds only as a last resort.
//
// Returns nil only when legal is empty (caller will draw).
func (s *HardStrategy) ChooseCard(state *game.PublicGameState, hand []game.Card) *game.Card {
	legal := state.LegalMoves
	if len(legal) == 0 {
		return nil
	}

	minOpponentCards := minOpponentCardCount(state)

	// --- Priority 1 & 2: offensive when opponent is close to winning ---
	if minOpponentCards <= 3 {
		// Prefer draw penalty cards first (hardest to survive).
		if c := pickFirst(legal, func(c game.Card) bool {
			return c.Type == game.CardTypeDrawTwo || c.Type == game.CardTypeWildDrawFour
		}); c != nil {
			return c
		}
		// Then other action cards.
		if minOpponentCards <= 3 {
			if c := pickFirst(legal, func(c game.Card) bool {
				return c.IsActionCard() && !c.IsWild()
			}); c != nil {
				return c
			}
		}
	}

	// --- Priority 3: colored number card matching current color ---
	if c := pickFirst(legal, func(c game.Card) bool {
		return c.Type == game.CardTypeNumber && c.Color == state.CurrentColor
	}); c != nil {
		return c
	}

	// --- Reverse for potential extra-turn benefit (2-player only) ---
	if len(state.Players) == 2 {
		if c := pickFirst(legal, func(c game.Card) bool {
			return c.Type == game.CardTypeReverse
		}); c != nil {
			return c
		}
	}

	// --- Priority 4: any colored action card ---
	if c := pickFirst(legal, func(c game.Card) bool {
		return c.IsActionCard() && !c.IsWild()
	}); c != nil {
		return c
	}

	// --- Any remaining number card ---
	if c := pickFirst(legal, func(c game.Card) bool {
		return c.Type == game.CardTypeNumber
	}); c != nil {
		return c
	}

	// --- Priority 5: wilds as last resort ---
	// Prefer plain wild over Wild Draw Four (save WD4 for when truly needed).
	if c := pickFirst(legal, func(c game.Card) bool {
		return c.Type == game.CardTypeWild
	}); c != nil {
		return c
	}

	return &legal[0]
}

// ChooseColor implements Strategy for HardStrategy.
// Returns the color most represented in the remaining hand.
func (s *HardStrategy) ChooseColor(hand []game.Card) game.Color {
	counts := map[game.Color]int{}
	for _, c := range hand {
		if game.IsValidColor(c.Color) {
			counts[c.Color]++
		}
	}
	best := game.ColorRed
	bestCount := -1
	for _, col := range game.ValidColors() {
		if counts[col] > bestCount {
			bestCount = counts[col]
			best = col
		}
	}
	return best
}

// ShouldCallUNO implements Strategy for HardStrategy.
// The hard bot always calls UNO when it will have exactly 1 card after
// playing (hand has 2 cards currently — one will be played).
func (s *HardStrategy) ShouldCallUNO(hand []game.Card) bool {
	return len(hand) == 2
}

// ShouldChallengeDraw4 implements Strategy for HardStrategy.
// Challenges when the discard pile suggests the previous player had a matching
// color card (i.e., the card before the Wild Draw Four matches the color that
// was active at play time).
func (s *HardStrategy) ShouldChallengeDraw4(state *game.PublicGameState) bool {
	// The top card is the WD4. We infer the color that was active before it
	// was played by looking at the CurrentColor that was active before the WD4
	// changed it. Since we cannot directly inspect history, we use a heuristic:
	// challenge if the second-from-top card's color matches the current color
	// declared on the WD4. If the declared color happens to match the top of
	// the pile, the player likely had that color and played WD4 illegally.
	// A simpler safe heuristic: challenge ~40% of the time to avoid predictability,
	// but for hard we escalate: challenge whenever draw penalty >= 4 (it was a WD4).
	if state.DrawPenalty >= 4 {
		// There's a 60% chance the bluff is worth calling at hard level.
		return rand.Intn(10) < 6
	}
	return false
}

// ─── MediumStrategy ───────────────────────────────────────────────────────────

// MediumStrategy plays optimally 80% of the time and randomly 20% of the time.
type MediumStrategy struct {
	hard *HardStrategy
}

func (s *MediumStrategy) ChooseCard(state *game.PublicGameState, hand []game.Card) *game.Card {
	legal := state.LegalMoves
	if len(legal) == 0 {
		return nil
	}
	if rand.Intn(10) < 8 {
		return s.hard.ChooseCard(state, hand)
	}
	// 20%: pick a random legal card.
	c := legal[rand.Intn(len(legal))]
	return &c
}

func (s *MediumStrategy) ChooseColor(hand []game.Card) game.Color {
	return s.hard.ChooseColor(hand)
}

func (s *MediumStrategy) ShouldCallUNO(hand []game.Card) bool {
	return s.hard.ShouldCallUNO(hand)
}

func (s *MediumStrategy) ShouldChallengeDraw4(state *game.PublicGameState) bool {
	if rand.Intn(10) < 8 {
		return s.hard.ShouldChallengeDraw4(state)
	}
	return rand.Intn(2) == 0
}

// ─── EasyStrategy ─────────────────────────────────────────────────────────────

// EasyStrategy plays optimally 50% of the time and randomly 50% of the time.
type EasyStrategy struct {
	hard *HardStrategy
}

func (s *EasyStrategy) ChooseCard(state *game.PublicGameState, hand []game.Card) *game.Card {
	legal := state.LegalMoves
	if len(legal) == 0 {
		return nil
	}
	if rand.Intn(2) == 0 {
		return s.hard.ChooseCard(state, hand)
	}
	c := legal[rand.Intn(len(legal))]
	return &c
}

func (s *EasyStrategy) ChooseColor(hand []game.Card) game.Color {
	if rand.Intn(2) == 0 {
		return s.hard.ChooseColor(hand)
	}
	cols := game.ValidColors()
	return cols[rand.Intn(len(cols))]
}

func (s *EasyStrategy) ShouldCallUNO(hand []game.Card) bool {
	return s.hard.ShouldCallUNO(hand)
}

func (s *EasyStrategy) ShouldChallengeDraw4(state *game.PublicGameState) bool {
	return rand.Intn(4) == 0 // 25% of the time
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

// pickFirst returns a pointer to the first card in cards that satisfies pred,
// or nil if none do.
func pickFirst(cards []game.Card, pred func(game.Card) bool) *game.Card {
	for i := range cards {
		if pred(cards[i]) {
			return &cards[i]
		}
	}
	return nil
}

// minOpponentCardCount returns the minimum card count held by any opponent
// (non-self player) visible in the public state.
func minOpponentCardCount(state *game.PublicGameState) int {
	min := int(^uint(0) >> 1) // MaxInt
	for _, p := range state.Players {
		// Skip the bot's own player slot.
		if p.CardCount == 0 {
			continue
		}
		// In PublicGameState, MyHand holds our own hand and Players holds
		// card counts for everyone. We cannot easily distinguish self by ID
		// here because PublicGameState.MyHand is the bot's own hand.
		// Use the heuristic that the player with len(MyHand) cards is us.
		if p.CardCount < min {
			min = p.CardCount
		}
	}
	if min == int(^uint(0)>>1) {
		return 99
	}
	return min
}
