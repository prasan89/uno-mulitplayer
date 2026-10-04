package game

import (
	"fmt"

	"github.com/google/uuid"
)

// ─── NewGame ─────────────────────────────────────────────────────────────────

// NewGame initialises a fresh WildDeck game.  It deals 7 cards to each player,
// places the first non-wild card face-up on the discard pile, and sets the
// phase to PhaseWaiting until Start is called (or immediately to PhasePlaying
// if at least 2 players are given).
func NewGame(players []PlayerInfo, rules HouseRules) *GameState {
	deck := NewDeck()

	gamePlayers := make([]Player, len(players))
	for i, pi := range players {
		gamePlayers[i] = Player{
			ID:          pi.ID,
			Name:        pi.Name,
			Hand:        make([]Card, 0, 7),
			IsBot:       pi.IsBot,
			IsConnected: true,
		}
	}

	g := &GameState{
		GameID:             uuid.New().String(),
		Players:            gamePlayers,
		DrawPile:           deck,
		DiscardPile:        make([]Card, 0),
		CurrentPlayerIndex: 0,
		Direction:          DirectionClockwise,
		Phase:              PhaseWaiting,
		HouseRules:         rules,
		Version:            1,
	}

	// Deal 7 cards to each player
	for round := 0; round < 7; round++ {
		for i := range g.Players {
			card, err := g.drawFromPile()
			if err != nil {
				break
			}
			g.Players[i].Hand = append(g.Players[i].Hand, card)
		}
	}

	// Flip the first card to the discard pile; skip Wild Draw Four starters.
	for len(g.DrawPile) > 0 {
		startCard := g.DrawPile[0]
		g.DrawPile = g.DrawPile[1:]
		if startCard.Type == CardTypeWildDrawFour {
			// Put it back at the bottom and try again.
			g.DrawPile = append(g.DrawPile, startCard)
			continue
		}
		g.DiscardPile = append(g.DiscardPile, startCard)
		g.CurrentColor = startCard.Color
		if startCard.IsWild() {
			// On a wild start, default to red (per common house rule).
			g.CurrentColor = ColorRed
		}
		break
	}

	if len(players) >= 2 {
		g.Phase = PhasePlaying
		// Handle special first-card effects.
		g.applyStartCardEffect()
	}

	return g
}

// applyStartCardEffect applies the effect of the first face-up card when it is
// an action card.
func (g *GameState) applyStartCardEffect() {
	top := g.topCard()
	switch top.Type {
	case CardTypeSkip:
		g.NextPlayer()
	case CardTypeReverse:
		if len(g.Players) == 2 {
			// With 2 players reverse acts like skip.
			g.NextPlayer()
		} else {
			g.Direction = DirectionCounterClockwise
		}
	case CardTypeDrawTwo:
		g.DrawPenalty += 2
	}
}

// ─── PlayCard ─────────────────────────────────────────────────────────────────

// PlayCard attempts to play a card from the current player's hand.
//
//  1. Validates that it is the player's turn.
//  2. Calls IsValidPlay (enforces matching rules and WD4 legality).
//  3. Removes the card from the hand.
//  4. Pushes it onto the discard pile and updates CurrentColor.
//  5. Applies the card's effect (skip, reverse, draw penalty, etc.).
//  6. Checks for a win condition.
//  7. Advances to the next player (unless the card already did so).
func (g *GameState) PlayCard(playerID, cardID string, chosenColor Color) error {
	if g.Phase == PhaseFinished {
		return ErrGameAlreadyOver
	}
	if g.Phase != PhasePlaying {
		return ErrGameNotActive
	}
	if g.currentPlayer().ID != playerID {
		return ErrNotYourTurn
	}

	player := g.currentPlayer()

	// Find the card in hand first so we can snapshot it for WD4 challenge.
	var cardToPlay Card
	found := false
	for _, c := range player.Hand {
		if c.ID == cardID {
			cardToPlay = c
			found = true
			break
		}
	}
	if !found {
		return ErrCardNotInHand
	}

	// For Wild Draw Four, store the player's current hand BEFORE removing the
	// card so a challenge can verify legitimacy.  Also snapshot the current
	// active color now (before it is overwritten) so ChallengeDraw4 can
	// recover it even when the previous card was itself a wild.
	var handSnapshot []Card
	if cardToPlay.Type == CardTypeWildDrawFour {
		handSnapshot = cloneCards(player.Hand)
		g.lastWildDraw4Color = g.CurrentColor
	}

	// Validate play — for WD4 we allow the bluff (return value is
	// ErrIllegalWildDraw4 only), but we still permit it to be played.
	err := g.IsValidPlay(playerID, cardToPlay, chosenColor)
	if err != nil && err != ErrIllegalWildDraw4 {
		return err
	}
	// If err == ErrIllegalWildDraw4 the play is allowed but flagged.
	wasIllegalWD4 := (err == ErrIllegalWildDraw4)
	_ = wasIllegalWD4 // recorded via lastWildDraw4Hand snapshot

	// Remove card from hand.
	removed, ok := removeCardFromHand(player, cardID)
	if !ok {
		return ErrCardNotInHand
	}

	// Place on discard pile.
	g.DiscardPile = append(g.DiscardPile, removed)

	// Update active color.
	if removed.IsWild() {
		g.CurrentColor = chosenColor
	} else {
		g.CurrentColor = removed.Color
	}

	// Track WD4 for potential challenge.
	if removed.Type == CardTypeWildDrawFour {
		g.lastWildDraw4PlayerID = playerID
		g.lastWildDraw4Hand = handSnapshot
	} else {
		g.lastWildDraw4PlayerID = ""
		g.lastWildDraw4Hand = nil
	}

	// Capture Last Card call status BEFORE resetting it so we can check the penalty.
	calledLastCard := player.HasCalledLastCard

	// Reset Last Card call flag for the player (they just played, card count changed).
	player.HasCalledLastCard = false

	g.Version++

	// Check win condition.
	if len(player.Hand) == 0 {
		g.Phase = PhaseFinished
		g.WinnerID = playerID
		g.tallyScores(playerID)
		return nil
	}

	// Last Card penalty: if the player dropped to exactly 1 card and had NOT
	// previously declared Last Card, they draw 2 penalty cards.
	if len(player.Hand) == 1 && !calledLastCard {
		_ = g.applyLastCardPenalty(playerID)
	}

	// Apply card effect and advance turn.
	skipExtra := g.applyCardEffect(removed, chosenColor)
	if !skipExtra {
		g.NextPlayer()
	}

	return nil
}

// applyCardEffect applies special effects of a just-played card.
// Returns true if NextPlayer was already called inside (e.g., for Skip).
func (g *GameState) applyCardEffect(card Card, chosenColor Color) bool {
	n := len(g.Players)
	switch card.Type {
	case CardTypeSkip:
		// Skip the next player: advance twice.
		g.NextPlayer()
		g.NextPlayer()
		return true

	case CardTypeReverse:
		if n == 2 {
			// With 2 players reverse acts as skip.
			g.NextPlayer()
			g.NextPlayer()
			return true
		}
		g.Direction *= -1
		g.NextPlayer()
		return true

	case CardTypeDrawTwo:
		if g.HouseRules.StackDrawCards {
			g.DrawPenalty += 2
			g.NextPlayer()
			return true
		}
		// Immediate: next player draws 2 and is skipped.
		g.NextPlayer()
		next := g.currentPlayer()
		for i := 0; i < 2; i++ {
			drawn, err := g.drawFromPileReshuffle()
			if err == nil {
				next.Hand = append(next.Hand, drawn)
			}
		}
		g.NextPlayer()
		return true

	case CardTypeWildDrawFour:
		if g.HouseRules.StackDrawCards {
			g.DrawPenalty += 4
			g.NextPlayer()
			return true
		}
		// Advance to the victim and set the draw penalty.  Do NOT draw cards
		// yet: the victim must first decide whether to challenge (ChallengeDraw4)
		// or accept (DrawCard, which will consume the DrawPenalty of 4).
		g.DrawPenalty = 4
		g.NextPlayer()
		return true

	case CardTypeWild:
		// Just changes color; already set above.
		return false

	case CardTypeNumber:
		if g.HouseRules.SevenSwap && card.Value == 7 {
			// Seven: swap hands with any player — for engine purposes we do
			// not implement the "choose" step here; leave it to the action layer.
			return false
		}
		if g.HouseRules.ZeroRotate && card.Value == 0 {
			// Zero: rotate hands in the direction of play.
			g.rotateHands()
			return false
		}
	}
	return false
}

// rotateHands rotates all players' hands one step in the current direction.
func (g *GameState) rotateHands() {
	n := len(g.Players)
	if n <= 1 {
		return
	}
	if g.Direction == DirectionClockwise {
		last := g.Players[n-1].Hand
		for i := n - 1; i > 0; i-- {
			g.Players[i].Hand = g.Players[i-1].Hand
		}
		g.Players[0].Hand = last
	} else {
		first := g.Players[0].Hand
		for i := 0; i < n-1; i++ {
			g.Players[i].Hand = g.Players[i+1].Hand
		}
		g.Players[n-1].Hand = first
	}
}

// ─── DrawCard ────────────────────────────────────────────────────────────────

// DrawCard draws a card for the given player on their turn.  If there is an
// accumulated DrawPenalty the player draws that many cards; otherwise they
// draw one.  If ForcePlay is enabled and the drawn card is legal, it is
// immediately played.
func (g *GameState) DrawCard(playerID string) (Card, error) {
	if g.Phase == PhaseFinished {
		return Card{}, ErrGameAlreadyOver
	}
	if g.Phase != PhasePlaying {
		return Card{}, ErrGameNotActive
	}
	if g.currentPlayer().ID != playerID {
		return Card{}, ErrNotYourTurn
	}

	player := g.currentPlayer()

	drawCount := 1
	if g.DrawPenalty > 0 {
		drawCount = g.DrawPenalty
		g.DrawPenalty = 0
	}

	var lastDrawn Card
	for i := 0; i < drawCount; i++ {
		card, err := g.drawFromPileReshuffle()
		if err != nil {
			if i == 0 {
				return Card{}, err
			}
			break
		}
		player.Hand = append(player.Hand, card)
		lastDrawn = card
	}

	// Drawing a card invalidates any prior Last Card declaration; the player now
	// holds more than one card so the flag must be cleared.
	player.HasCalledLastCard = false

	g.Version++
	g.NextPlayer()
	return lastDrawn, nil
}

// ─── CallLastCard ─────────────────────────────────────────────────────────────────

// CallLastCard lets the current player (or any player with one card) declare Last Card.
// Must be called before or immediately after playing down to one card.
func (g *GameState) CallLastCard(playerID string) error {
	if g.Phase != PhasePlaying {
		return ErrGameNotActive
	}
	player, err := g.findPlayer(playerID)
	if err != nil {
		return err
	}
	if len(player.Hand) != 1 {
		// Can only declare Last Card when holding exactly 1 card.
		return fmt.Errorf("can only declare Last Card with exactly 1 card (have %d)", len(player.Hand))
	}
	player.HasCalledLastCard = true
	g.Version++
	return nil
}

// applyLastCardPenalty draws 2 cards for a player who forgot to declare Last Card.
func (g *GameState) applyLastCardPenalty(playerID string) error {
	player, err := g.findPlayer(playerID)
	if err != nil {
		return err
	}
	for i := 0; i < 2; i++ {
		card, err := g.drawFromPileReshuffle()
		if err != nil {
			break
		}
		player.Hand = append(player.Hand, card)
	}
	player.HasCalledLastCard = false
	return nil
}

// ─── ChallengeDraw4 ──────────────────────────────────────────────────────────

// ChallengeDraw4 allows the player who was just hit with a Wild Draw Four to
// challenge it.
//
//   - If the challenge succeeds (the WD4 was illegal): the player who played
//     the WD4 draws 4, and the challenger draws nothing (standard rule).
//   - If the challenge fails: the challenger draws 6 instead of 4.
func (g *GameState) ChallengeDraw4(challengerID string) error {
	if g.Phase == PhaseFinished {
		return ErrGameAlreadyOver
	}
	if g.Phase != PhasePlaying {
		return ErrGameNotActive
	}
	if g.lastWildDraw4PlayerID == "" {
		return fmt.Errorf("no Wild Draw Four to challenge")
	}

	// The challenger must be the player who was targeted (the one right after
	// the WD4 player in play order).
	// For simplicity we accept any player ID here; server should validate
	// the correct targeted player before calling.

	wd4Player, err := g.findPlayer(g.lastWildDraw4PlayerID)
	if err != nil {
		return err
	}
	challenger, err := g.findPlayer(challengerID)
	if err != nil {
		return err
	}

	// Check whether the WD4 was illegal: did wd4Player have a matching-color
	// card in the snapshot taken at play time?
	// Use the color that was active when the WD4 was played, stored explicitly
	// to handle the case where the card before the WD4 was itself a wild
	// (inspecting DiscardPile[len-2].Color would yield "" in that case).
	colorAtPlay := g.lastWildDraw4Color

	wasBluff := false
	for _, c := range g.lastWildDraw4Hand {
		if !c.IsWild() && c.Color == colorAtPlay && c.Type != CardTypeWildDrawFour {
			wasBluff = true
			break
		}
	}

	if wasBluff {
		// Challenge succeeds: WD4 player draws 4, challenger draws nothing.
		// Clear the pending DrawPenalty so the challenger is not forced to draw.
		g.DrawPenalty = 0
		for i := 0; i < 4; i++ {
			card, err := g.drawFromPileReshuffle()
			if err != nil {
				break
			}
			wd4Player.Hand = append(wd4Player.Hand, card)
		}
	} else {
		// Challenge fails: challenger must draw 6 (4 + 2 extra penalty).
		// Consume the DrawPenalty (4) plus the 2-card extra via a direct draw
		// so DrawCard is not called a second time.
		g.DrawPenalty = 0
		for i := 0; i < 6; i++ {
			card, err := g.drawFromPileReshuffle()
			if err != nil {
				break
			}
			challenger.Hand = append(challenger.Hand, card)
		}
	}

	// Clear the challenge state and advance past the challenger (victim).
	// After applyCardEffect the current player is already the victim; once the
	// challenge is resolved their turn is over.
	g.lastWildDraw4PlayerID = ""
	g.lastWildDraw4Hand = nil
	g.lastWildDraw4Color = ""
	g.NextPlayer()
	g.Version++
	return nil
}

// ─── NextPlayer ──────────────────────────────────────────────────────────────

// NextPlayer advances CurrentPlayerIndex one step in the current Direction,
// wrapping around.
func (g *GameState) NextPlayer() {
	n := len(g.Players)
	if n == 0 {
		return
	}
	g.CurrentPlayerIndex = ((g.CurrentPlayerIndex + g.Direction) % n + n) % n
}

// ─── ApplyAction ─────────────────────────────────────────────────────────────

// ApplyAction is a convenience dispatcher that delegates to the appropriate
// method based on the action type.
func (g *GameState) ApplyAction(action Action) error {
	switch action.Type {
	case ActionPlayCard:
		return g.PlayCard(action.PlayerID, action.CardID, action.ChosenColor)
	case ActionDrawCard:
		_, err := g.DrawCard(action.PlayerID)
		return err
	case ActionCallLastCard:
		return g.CallLastCard(action.PlayerID)
	case ActionChallengeDraw4:
		return g.ChallengeDraw4(action.ChallengerID)
	default:
		return fmt.Errorf("unknown action type: %s", action.Type)
	}
}

// ─── Clone ───────────────────────────────────────────────────────────────────

// Clone returns a deep copy of the GameState.  All slices are independently
// allocated so mutations to the clone do not affect the original.
func (g *GameState) Clone() *GameState {
	cp := *g // copy all scalar fields

	// Deep-copy players (each player deep-copies their hand).
	cp.Players = make([]Player, len(g.Players))
	for i, p := range g.Players {
		cp.Players[i] = p.clone()
	}

	cp.DrawPile = cloneCards(g.DrawPile)
	cp.DiscardPile = cloneCards(g.DiscardPile)
	cp.lastWildDraw4Hand = cloneCards(g.lastWildDraw4Hand)

	return &cp
}

// ─── ToPublicView ─────────────────────────────────────────────────────────────

// ToPublicView returns the game state as visible to the player with the given
// ID: they see their own full hand; opponents are shown only card counts.
func (g *GameState) ToPublicView(playerID string) PublicGameState {
	views := make([]PublicPlayerView, len(g.Players))
	var myHand []Card

	for i, p := range g.Players {
		views[i] = PublicPlayerView{
			ID:           p.ID,
			Name:         p.Name,
			CardCount:    len(p.Hand),
			Score:        p.Score,
			IsBot:        p.IsBot,
			IsConnected:  p.IsConnected,
			HasCalledLastCard: p.HasCalledLastCard,
		}
		if p.ID == playerID {
			myHand = cloneCards(p.Hand)
		}
	}

	return PublicGameState{
		GameID:             g.GameID,
		MyHand:             myHand,
		Players:            views,
		TopCard:            g.topCard(),
		CurrentColor:       g.CurrentColor,
		CurrentPlayerIndex: g.CurrentPlayerIndex,
		Direction:          g.Direction,
		Phase:              g.Phase,
		DrawPileCount:      len(g.DrawPile),
		DrawPenalty:        g.DrawPenalty,
		Version:            g.Version,
		WinnerID:           g.WinnerID,
		LegalMoves:         g.GetLegalMoves(playerID, false), // strict=false: show WD4 even as a bluff option
		HouseRules:         g.HouseRules,
	}
}

// ─── ReshuffleIfNeeded ───────────────────────────────────────────────────────

// ReshuffleIfNeeded checks whether the draw pile is empty and, if so,
// reshuffles the discard pile (minus the top card) into a new draw pile.
// Returns ErrDeckExhausted if neither pile has cards.
func (g *GameState) ReshuffleIfNeeded() error {
	if len(g.DrawPile) > 0 {
		return nil
	}
	if len(g.DiscardPile) <= 1 {
		return ErrDeckExhausted
	}

	top := g.DiscardPile[len(g.DiscardPile)-1]
	newDraw := g.DiscardPile[:len(g.DiscardPile)-1]
	shuffle(newDraw)

	g.DrawPile = newDraw
	g.DiscardPile = []Card{top}
	return nil
}

// ─── Internal draw helpers ───────────────────────────────────────────────────

// drawFromPile draws the top card from the draw pile without reshuffling.
func (g *GameState) drawFromPile() (Card, error) {
	if len(g.DrawPile) == 0 {
		return Card{}, ErrDeckExhausted
	}
	card := g.DrawPile[0]
	g.DrawPile = g.DrawPile[1:]
	return card, nil
}

// drawFromPileReshuffle draws a card, reshuffling the discard pile first if
// the draw pile is empty.
func (g *GameState) drawFromPileReshuffle() (Card, error) {
	if len(g.DrawPile) == 0 {
		if err := g.ReshuffleIfNeeded(); err != nil {
			return Card{}, err
		}
	}
	return g.drawFromPile()
}

// ─── Scoring ────────────────────────────────────────────────────────────────

// tallyScores adds the point value of all remaining cards to the winner's
// score.
func (g *GameState) tallyScores(winnerID string) {
	total := 0
	for _, p := range g.Players {
		if p.ID == winnerID {
			continue
		}
		for _, c := range p.Hand {
			total += c.ScoreValue()
		}
	}
	for i := range g.Players {
		if g.Players[i].ID == winnerID {
			g.Players[i].Score += total
			break
		}
	}
}
