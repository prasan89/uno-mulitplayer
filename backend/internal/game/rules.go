package game

// IsValidPlay checks whether the given card may be legally played in the
// current game state by the specified player.  It returns nil on success or
// one of the sentinel errors on failure.
//
// Rules enforced here (engine.go enforces turn order separately):
//  1. The card must be in the player's hand.
//  2. A wild card requires a valid chosen color.
//  3. A number/action card must match the current color or the top card's
//     number/type.
//  4. Wild Draw Four is illegal if the player has any card matching the
//     current color (the player may still play it bluffing, but it is
//     flagged here so the engine can track it).
func (g *GameState) IsValidPlay(playerID string, card Card, chosenColor Color) error {
	// Locate the player
	player, err := g.findPlayer(playerID)
	if err != nil {
		return err
	}

	// Card must be in the player's hand
	if !playerHasCard(player, card.ID) {
		return ErrCardNotInHand
	}

	top := g.topCard()

	switch card.Type {
	case CardTypeWild:
		// Wild can always be played; a valid non-wild color must be chosen.
		if !IsValidColor(chosenColor) {
			return ErrInvalidColor
		}

	case CardTypeWildDrawFour:
		if !IsValidColor(chosenColor) {
			return ErrInvalidColor
		}
		// Illegal if the player holds any card matching the current color —
		// we return ErrIllegalWildDraw4 so the engine can record the bluff flag.
		if g.playerHasColorCard(player, g.CurrentColor) {
			return ErrIllegalWildDraw4
		}

	default:
		// Colored card: must match current color OR match the top card's type/value.
		if card.Color != g.CurrentColor &&
			!sameTypeOrValue(card, top) {
			return ErrInvalidCard
		}
	}

	return nil
}

// GetLegalMoves returns all cards in the player's hand that can be legally
// played right now.
//
// When strict is true, Wild Draw Four is excluded from the result if the player
// holds any card matching the current color (the play would be illegal per
// official rules, though the server still accepts it as a bluff via PlayCard).
//
// When strict is false (the recommended setting for populating a play UI),
// Wild Draw Four is always included whenever it is physically playable,
// matching the server-side acceptance logic in PlayCard/IsValidPlay.  The UI
// layer should display a bluff-warning indicator alongside the WD4 when the
// player also holds a matching-color card.
func (g *GameState) GetLegalMoves(playerID string, strict bool) []Card {
	player, err := g.findPlayer(playerID)
	if err != nil {
		return nil
	}

	legal := make([]Card, 0, len(player.Hand))
	for _, card := range player.Hand {
		// In strict mode, exclude WD4 when the player holds a matching-color
		// card (it would be an illegal bluff).  In non-strict mode the WD4 is
		// always shown because PlayCard accepts the bluff play.
		if strict && card.Type == CardTypeWildDrawFour {
			if g.playerHasColorCard(player, g.CurrentColor) {
				continue
			}
		}
		if canPlay(card, g.topCard(), g.CurrentColor) {
			legal = append(legal, card)
		}
	}
	return legal
}

// ─── Internal helpers ────────────────────────────────────────────────────────

// canPlay returns true if the card is playable on top of topCard given the
// current active color.  It does NOT enforce Wild Draw Four legality.
func canPlay(card, top Card, currentColor Color) bool {
	switch card.Type {
	case CardTypeWild, CardTypeWildDrawFour:
		return true
	default:
		return card.Color == currentColor || sameTypeOrValue(card, top)
	}
}

// sameTypeOrValue returns true when two cards share the same non-number type,
// or when both are numbers with the same face value.
func sameTypeOrValue(a, b Card) bool {
	if a.Type == CardTypeNumber && b.Type == CardTypeNumber {
		return a.Value == b.Value
	}
	if a.Type != CardTypeNumber && b.Type != CardTypeNumber {
		// Both action cards — match if same type (skip on skip, etc.)
		return a.Type == b.Type
	}
	return false
}

// playerHasCard returns true if the player's hand contains a card with the
// given ID.
func playerHasCard(p *Player, cardID string) bool {
	for _, c := range p.Hand {
		if c.ID == cardID {
			return true
		}
	}
	return false
}

// playerHasColorCard returns true if the player holds at least one
// non-wild card of the given color.
func (g *GameState) playerHasColorCard(p *Player, color Color) bool {
	for _, c := range p.Hand {
		if c.Color == color && !c.IsWild() {
			return true
		}
	}
	return false
}

// topCard returns the top card of the discard pile, or the zero value if the
// pile is empty.
func (g *GameState) topCard() Card {
	if len(g.DiscardPile) == 0 {
		return Card{}
	}
	return g.DiscardPile[len(g.DiscardPile)-1]
}

// findPlayer looks up a player by ID and returns a pointer to them or an
// error if not found.
func (g *GameState) findPlayer(playerID string) (*Player, error) {
	for i := range g.Players {
		if g.Players[i].ID == playerID {
			return &g.Players[i], nil
		}
	}
	return nil, ErrCardNotInHand // reuse as "player not found" for simplicity
}

// findPlayerIndex returns the index of the player in the Players slice.
func (g *GameState) findPlayerIndex(playerID string) int {
	for i := range g.Players {
		if g.Players[i].ID == playerID {
			return i
		}
	}
	return -1
}

// currentPlayer returns a pointer to the player whose turn it is.
func (g *GameState) currentPlayer() *Player {
	return &g.Players[g.CurrentPlayerIndex]
}

// removeCardFromHand removes the first card with the given ID from the
// player's hand and returns it along with a flag indicating success.
func removeCardFromHand(p *Player, cardID string) (Card, bool) {
	for i, c := range p.Hand {
		if c.ID == cardID {
			p.Hand = append(p.Hand[:i], p.Hand[i+1:]...)
			return c, true
		}
	}
	return Card{}, false
}
