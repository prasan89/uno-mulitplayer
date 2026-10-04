package game

import "errors"

// ─── Sentinel errors ────────────────────────────────────────────────────────

var (
	// ErrNotYourTurn is returned when a player tries to act out of turn.
	ErrNotYourTurn = errors.New("not your turn")

	// ErrInvalidCard is returned when a card cannot be legally played on the
	// current discard pile top.
	ErrInvalidCard = errors.New("invalid card play")

	// ErrCardNotInHand is returned when the specified card is not in the
	// player's hand.
	ErrCardNotInHand = errors.New("card not in hand")

	// ErrIllegalWildDraw4 is returned when a Wild Draw Four is challenged and
	// it is found that the player had a matching-color card and could have
	// played it instead.
	ErrIllegalWildDraw4 = errors.New("illegal wild draw four: player had a playable card")

	// ErrGameNotActive is returned when an action requires the game to be in
	// the "playing" phase but it is not.
	ErrGameNotActive = errors.New("game is not active")

	// ErrGameAlreadyOver is returned when an action is attempted after the
	// game has finished.
	ErrGameAlreadyOver = errors.New("game is already over")

	// ErrDeckExhausted is returned when the deck cannot be replenished because
	// both the draw pile and the discard pile are empty.
	ErrDeckExhausted = errors.New("deck is exhausted")

	// ErrInvalidColor is returned when an invalid or nil chosen color is
	// supplied for a wild card.
	ErrInvalidColor = errors.New("invalid color choice for wild card")
)

// ─── Game phases ─────────────────────────────────────────────────────────────

const (
	PhaseWaiting  = "waiting"
	PhasePlaying  = "playing"
	PhaseFinished = "finished"
)

// Direction constants: 1 = clockwise, -1 = counter-clockwise.
const (
	DirectionClockwise        = 1
	DirectionCounterClockwise = -1
)

// ─── HouseRules ──────────────────────────────────────────────────────────────

// HouseRules contains optional rule variants that can be toggled per game.
type HouseRules struct {
	// StackDrawCards allows players to stack +2 and +4 cards.
	StackDrawCards bool `json:"stack_draw_cards"`

	// ForcePlay requires a player to play a drawn card if it is legal.
	ForcePlay bool `json:"force_play"`

	// JumpIn allows any player to play an identical card out of turn.
	JumpIn bool `json:"jump_in"`

	// SevenSwap: playing a 7 lets you swap hands with another player.
	SevenSwap bool `json:"seven_swap"`

	// ZeroRotate: playing a 0 rotates hands in the direction of play.
	ZeroRotate bool `json:"zero_rotate"`
}

// ─── PlayerInfo ──────────────────────────────────────────────────────────────

// PlayerInfo is the creation-time data needed to add a player to a new game.
type PlayerInfo struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	IsBot bool   `json:"is_bot"`
}

// ─── Player ───────────────────────────────────────────────────────────────────

// Player represents one participant in an UNO game.
type Player struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Hand        []Card `json:"hand"`
	Score       int    `json:"score"`
	IsBot       bool   `json:"is_bot"`
	IsConnected bool   `json:"is_connected"`
	HasCalledUno bool  `json:"has_called_uno"`
}

// clone returns a deep copy of the player (including a copy of the hand).
func (p Player) clone() Player {
	cp := p
	cp.Hand = cloneCards(p.Hand)
	return cp
}

// ─── GameState ────────────────────────────────────────────────────────────────

// GameState is the authoritative server-side state for an UNO game.
type GameState struct {
	GameID             string     `json:"game_id"`
	Players            []Player   `json:"players"`
	DrawPile           []Card     `json:"draw_pile"`
	DiscardPile        []Card     `json:"discard_pile"`
	CurrentPlayerIndex int        `json:"current_player_index"`
	Direction          int        `json:"direction"` // 1 or -1
	Phase              string     `json:"phase"`
	CurrentColor       Color      `json:"current_color"`
	DrawPenalty        int        `json:"draw_penalty"` // accumulated +2/+4 stacks
	Version            int        `json:"version"`
	WinnerID           string     `json:"winner_id"`
	HouseRules         HouseRules `json:"house_rules"`

	// lastWildDraw4PlayerID tracks the player who last played a Wild Draw Four,
	// needed to resolve a Draw Four challenge.
	lastWildDraw4PlayerID string

	// lastWildDraw4Hand is the snapshot of the Wild Draw Four player's hand at
	// the moment they played it, needed to verify the challenge.
	lastWildDraw4Hand []Card

	// lastWildDraw4Color is the active color at the moment the Wild Draw Four
	// was played (i.e. CurrentColor before it was updated to the chosen color).
	// Stored explicitly so ChallengeDraw4 can recover it correctly even when
	// the card played just before the WD4 was itself a wild.
	lastWildDraw4Color Color
}

// ─── Action ──────────────────────────────────────────────────────────────────

// ActionType enumerates the types of actions a player can take.
type ActionType string

const (
	ActionPlayCard       ActionType = "play_card"
	ActionDrawCard       ActionType = "draw_card"
	ActionCallUNO        ActionType = "call_uno"
	ActionChallengeDraw4 ActionType = "challenge_draw4"
)

// Action is a player-issued game command.
type Action struct {
	Type         ActionType `json:"type"`
	PlayerID     string     `json:"player_id"`
	CardID       string     `json:"card_id,omitempty"`
	ChosenColor  Color      `json:"chosen_color,omitempty"`
	ChallengerID string     `json:"challenger_id,omitempty"`
}

// ─── PublicGameState ─────────────────────────────────────────────────────────

// PublicPlayerView is what one player can see about another player.
type PublicPlayerView struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	CardCount    int    `json:"card_count"`
	Score        int    `json:"score"`
	IsBot        bool   `json:"is_bot"`
	IsConnected  bool   `json:"is_connected"`
	HasCalledUno bool   `json:"has_called_uno"`
}

// PublicGameState is the game state sent to a specific player: they see their
// own hand but only the card count of opponents.
type PublicGameState struct {
	GameID             string             `json:"game_id"`
	MyHand             []Card             `json:"my_hand"`
	Players            []PublicPlayerView `json:"players"`
	TopCard            Card               `json:"top_card"`
	CurrentColor       Color              `json:"current_color"`
	CurrentPlayerIndex int                `json:"current_player_index"`
	Direction          int                `json:"direction"`
	Phase              string             `json:"phase"`
	DrawPileCount      int                `json:"draw_pile_count"`
	DrawPenalty        int                `json:"draw_penalty"`
	Version            int                `json:"version"`
	WinnerID           string             `json:"winner_id"`
	LegalMoves         []Card             `json:"legal_moves"`
	HouseRules         HouseRules         `json:"house_rules"`
}
