// Package bot implements the AI player system for WildDeck.
// It provides configurable difficulty strategies (easy/medium/hard),
// a BotManager that drives bot turns, and optional takeover of disconnected
// human players.
package bot

import (
	"github.com/wilddeck/server/internal/game"
)

// Difficulty controls how intelligently a bot plays.
type Difficulty string

const (
	DifficultyEasy   Difficulty = "easy"
	DifficultyMedium Difficulty = "medium"
	DifficultyHard   Difficulty = "hard"
)

// Bot represents an AI player participating in a game.
type Bot struct {
	// ID is the unique identifier for this bot instance.
	ID string

	// Name is the display name shown to human players.
	Name string

	// Difficulty controls the strategy used when choosing moves.
	Difficulty Difficulty

	// Personality gives the bot a unique play style.
	Personality Personality

	// GameID is the game this bot is playing in.
	GameID string

	// PlayerID is the in-game player ID this bot acts as.
	PlayerID string

	// strategy is the decision-making implementation.
	strategy Strategy
}

// Strategy defines the decision interface all difficulty levels must implement.
type Strategy interface {
	// ChooseCard selects a card to play from the provided legal moves.
	// It returns nil if no card should be played (bot will draw instead).
	ChooseCard(state *game.PublicGameState, hand []game.Card) *game.Card

	// ChooseColor returns the color to declare when playing a wild card.
	ChooseColor(hand []game.Card) game.Color

	// ShouldCallLastCard returns true when the bot should declare Last Card before
	// or immediately after playing down to one card.
	ShouldCallLastCard(hand []game.Card) bool

	// ShouldChallengeDraw4 returns true when the bot should challenge the
	// most recently played Wild Draw Four.
	ShouldChallengeDraw4(state *game.PublicGameState) bool
}

// newStrategy constructs the appropriate Strategy implementation for the given
// difficulty.
func newStrategy(d Difficulty) Strategy {
	switch d {
	case DifficultyMedium:
		return &MediumStrategy{hard: &HardStrategy{}}
	case DifficultyEasy:
		return &EasyStrategy{hard: &HardStrategy{}}
	default:
		return &HardStrategy{}
	}
}
