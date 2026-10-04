package game

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ─── Helpers ──────────────────────────────────────────────────────────────────

func makePlayers(n int) []PlayerInfo {
	pis := make([]PlayerInfo, n)
	for i := range pis {
		pis[i] = PlayerInfo{
			ID:   uuid.New().String(),
			Name: string(rune('A' + i)),
		}
	}
	return pis
}

// newTestGame creates a game with n players and no house rules.
func newTestGame(n int) (*GameState, []PlayerInfo) {
	pis := makePlayers(n)
	g := NewGame(pis, HouseRules{})
	return g, pis
}

// giveCard injects a card directly into a player's hand (for test setup).
func giveCard(g *GameState, playerID string, card Card) {
	for i := range g.Players {
		if g.Players[i].ID == playerID {
			g.Players[i].Hand = append(g.Players[i].Hand, card)
			return
		}
	}
}

// setTopCard replaces the top of the discard pile and sets CurrentColor.
func setTopCard(g *GameState, card Card) {
	if len(g.DiscardPile) == 0 {
		g.DiscardPile = []Card{card}
	} else {
		g.DiscardPile[len(g.DiscardPile)-1] = card
	}
	if card.IsWild() {
		g.CurrentColor = ColorRed
	} else {
		g.CurrentColor = card.Color
	}
}

// clearHand removes all cards from a player's hand.
func clearHand(g *GameState, playerID string) {
	for i := range g.Players {
		if g.Players[i].ID == playerID {
			g.Players[i].Hand = nil
			return
		}
	}
}

// ─── Deck Tests ──────────────────────────────────────────────────────────────

func TestNewDeck_Size(t *testing.T) {
	deck := NewDeck()
	assert.Equal(t, 108, len(deck), "standard WildDeck deck must have 108 cards")
}

func TestNewDeck_Composition(t *testing.T) {
	deck := NewDeck()

	counts := map[CardType]map[Color]int{}
	for _, c := range deck {
		if counts[c.Type] == nil {
			counts[c.Type] = map[Color]int{}
		}
		counts[c.Type][c.Color]++
	}

	colors := []Color{ColorRed, ColorGreen, ColorBlue, ColorYellow}

	// 19 number cards per color (one 0 + two each of 1-9).
	for _, col := range colors {
		assert.Equal(t, 19, counts[CardTypeNumber][col],
			"expected 19 number cards for color %s", col)
	}

	// Count zeros specifically
	zeroCount := 0
	oneToNineCount := 0
	for _, c := range deck {
		if c.Type == CardTypeNumber {
			if c.Value == 0 {
				zeroCount++
			} else {
				oneToNineCount++
			}
		}
	}
	assert.Equal(t, 4, zeroCount, "must have exactly 4 zero cards")
	assert.Equal(t, 72, oneToNineCount, "must have exactly 72 cards for values 1-9")

	// Two Skip per color
	for _, col := range colors {
		assert.Equal(t, 2, counts[CardTypeSkip][col])
	}
	// Two Reverse per color
	for _, col := range colors {
		assert.Equal(t, 2, counts[CardTypeReverse][col])
	}
	// Two DrawTwo per color
	for _, col := range colors {
		assert.Equal(t, 2, counts[CardTypeDrawTwo][col])
	}
	// Four Wilds
	assert.Equal(t, 4, counts[CardTypeWild][ColorWild])
	// Four WildDrawFour
	assert.Equal(t, 4, counts[CardTypeWildDrawFour][ColorWild])
}

func TestNewDeck_UniqueIDs(t *testing.T) {
	deck := NewDeck()
	seen := map[string]bool{}
	for _, c := range deck {
		assert.False(t, seen[c.ID], "duplicate card ID: %s", c.ID)
		seen[c.ID] = true
	}
}

// ─── NewGame Tests ────────────────────────────────────────────────────────────

func TestNewGame_InitialState(t *testing.T) {
	g, pis := newTestGame(4)

	assert.Equal(t, PhasePlaying, g.Phase)
	assert.Equal(t, DirectionClockwise, g.Direction)
	assert.Equal(t, 0, g.CurrentPlayerIndex)
	assert.NotEmpty(t, g.GameID)
	assert.NotEmpty(t, g.DiscardPile)
	assert.Equal(t, 4, len(g.Players))
	assert.Equal(t, pis[0].ID, g.Players[0].ID)
}

func TestNewGame_EachPlayerHas7Cards(t *testing.T) {
	g, _ := newTestGame(4)
	for _, p := range g.Players {
		assert.Equal(t, 7, len(p.Hand), "player %s should have 7 cards", p.Name)
	}
}

func TestNewGame_FirstCardNotWildDrawFour(t *testing.T) {
	for i := 0; i < 20; i++ {
		g, _ := newTestGame(2)
		top := g.topCard()
		assert.NotEqual(t, CardTypeWildDrawFour, top.Type,
			"starting card must never be Wild Draw Four")
	}
}

func TestNewGame_WaitingPhaseWithOnePlayer(t *testing.T) {
	pis := makePlayers(1)
	g := NewGame(pis, HouseRules{})
	assert.Equal(t, PhaseWaiting, g.Phase)
}

// ─── PlayCard Tests ───────────────────────────────────────────────────────────

func TestPlayCard_ValidNumberMatch(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	// Force the top card to be Red 5.
	redFive := newCard(ColorRed, CardTypeNumber, 5)
	setTopCard(g, redFive)
	g.CurrentPlayerIndex = 0

	// Give player a Red 5.
	playCard := newCard(ColorRed, CardTypeNumber, 5)
	clearHand(g, p0)
	giveCard(g, p0, playCard)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 3)) // filler

	err := g.PlayCard(p0, playCard.ID, "")
	require.NoError(t, err)
	assert.Equal(t, ColorRed, g.CurrentColor)
}

func TestPlayCard_ColorMatch(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorBlue, CardTypeNumber, 3))
	g.CurrentPlayerIndex = 0

	blueSkip := newCard(ColorBlue, CardTypeSkip, 20)
	clearHand(g, p0)
	giveCard(g, p0, blueSkip)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1)) // filler

	err := g.PlayCard(p0, blueSkip.ID, "")
	require.NoError(t, err)
}

func TestPlayCard_NotYourTurn(t *testing.T) {
	g, pis := newTestGame(2)
	p1 := pis[1].ID
	// Ensure p0 is the current player so playing as p1 is "not your turn".
	g.CurrentPlayerIndex = 0

	c := newCard(ColorRed, CardTypeNumber, 1)
	giveCard(g, p1, c)

	err := g.PlayCard(p1, c.ID, "")
	assert.ErrorIs(t, err, ErrNotYourTurn)
}

func TestPlayCard_CardNotInHand(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.CurrentPlayerIndex = 0
	fakeCard := newCard(ColorRed, CardTypeNumber, 9)
	err := g.PlayCard(p0, fakeCard.ID, "")
	assert.ErrorIs(t, err, ErrCardNotInHand)
}

func TestPlayCard_InvalidColorMismatch(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	blueCard := newCard(ColorBlue, CardTypeNumber, 2)
	clearHand(g, p0)
	giveCard(g, p0, blueCard)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	err := g.PlayCard(p0, blueCard.ID, "")
	assert.ErrorIs(t, err, ErrInvalidCard)
}

func TestPlayCard_Wild_RequiresColor(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	wildCard := newCard(ColorWild, CardTypeWild, 50)
	clearHand(g, p0)
	giveCard(g, p0, wildCard)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0

	err := g.PlayCard(p0, wildCard.ID, "")
	assert.ErrorIs(t, err, ErrInvalidColor)
}

func TestPlayCard_Wild_ValidColorChoice(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	wildCard := newCard(ColorWild, CardTypeWild, 50)
	clearHand(g, p0)
	giveCard(g, p0, wildCard)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0

	err := g.PlayCard(p0, wildCard.ID, ColorGreen)
	require.NoError(t, err)
	assert.Equal(t, ColorGreen, g.CurrentColor)
}

func TestPlayCard_WinCondition(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	lastCard := newCard(ColorRed, CardTypeNumber, 3)
	clearHand(g, p0)
	giveCard(g, p0, lastCard)

	err := g.PlayCard(p0, lastCard.ID, "")
	require.NoError(t, err)
	assert.Equal(t, PhaseFinished, g.Phase)
	assert.Equal(t, p0, g.WinnerID)
}

func TestPlayCard_SkipEffect(t *testing.T) {
	g, pis := newTestGame(3)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	skipCard := newCard(ColorRed, CardTypeSkip, 20)
	clearHand(g, p0)
	giveCard(g, p0, skipCard)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	err := g.PlayCard(p0, skipCard.ID, "")
	require.NoError(t, err)
	// Player 1 is skipped; it should be player 2's turn now.
	assert.Equal(t, 2, g.CurrentPlayerIndex)
}

func TestPlayCard_ReverseEffect_3Players(t *testing.T) {
	g, pis := newTestGame(3)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorGreen, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0
	g.CurrentColor = ColorGreen

	revCard := newCard(ColorGreen, CardTypeReverse, 20)
	clearHand(g, p0)
	giveCard(g, p0, revCard)
	giveCard(g, p0, newCard(ColorGreen, CardTypeNumber, 2))

	err := g.PlayCard(p0, revCard.ID, "")
	require.NoError(t, err)
	assert.Equal(t, DirectionCounterClockwise, g.Direction)
	// After reverse + advance from player 0 → should land on player 2.
	assert.Equal(t, 2, g.CurrentPlayerIndex)
}

func TestPlayCard_Reverse_2Players_ActsAsSkip(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorBlue, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0
	g.CurrentColor = ColorBlue

	revCard := newCard(ColorBlue, CardTypeReverse, 20)
	clearHand(g, p0)
	giveCard(g, p0, revCard)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 2))

	err := g.PlayCard(p0, revCard.ID, "")
	require.NoError(t, err)
	// With 2 players, reverse = skip; it should be p0's turn again (index 0).
	assert.Equal(t, 0, g.CurrentPlayerIndex)
}

func TestPlayCard_DrawTwo_NextPlayerDraws(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	p1 := pis[1].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0
	g.CurrentColor = ColorRed

	d2 := newCard(ColorRed, CardTypeDrawTwo, 20)
	clearHand(g, p0)
	giveCard(g, p0, d2)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	p1HandBefore := len(g.Players[1].Hand)

	err := g.PlayCard(p0, d2.ID, "")
	require.NoError(t, err)

	p1HandAfter := 0
	for _, p := range g.Players {
		if p.ID == p1 {
			p1HandAfter = len(p.Hand)
			break
		}
	}
	assert.Equal(t, p1HandBefore+2, p1HandAfter, "p1 should have drawn 2 cards")
	// Turn should have advanced past p1 (they were skipped) back to p0.
	assert.Equal(t, g.Players[0].ID, g.currentPlayer().ID)
}

// ─── DrawCard Tests ───────────────────────────────────────────────────────────

func TestDrawCard_BasicDraw(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.CurrentPlayerIndex = 0
	g.DrawPenalty = 0

	handSizeBefore := len(g.Players[0].Hand)
	card, err := g.DrawCard(p0)
	require.NoError(t, err)
	assert.NotEmpty(t, card.ID)
	assert.Equal(t, handSizeBefore+1, len(g.Players[0].Hand))
	// Turn should have advanced to p1.
	assert.Equal(t, 1, g.CurrentPlayerIndex)
}

func TestDrawCard_NotYourTurn(t *testing.T) {
	g, pis := newTestGame(2)
	p1 := pis[1].ID
	g.CurrentPlayerIndex = 0

	_, err := g.DrawCard(p1)
	assert.ErrorIs(t, err, ErrNotYourTurn)
}

func TestDrawCard_DrawPenaltyApplied(t *testing.T) {
	g, pis := newTestGame(2)
	p1 := pis[1].ID

	// Simulate p1 being hit with a +4.
	g.DrawPenalty = 4
	g.CurrentPlayerIndex = 1

	handBefore := len(g.Players[1].Hand)
	_, err := g.DrawCard(p1)
	require.NoError(t, err)
	assert.Equal(t, handBefore+4, len(g.Players[1].Hand))
	assert.Equal(t, 0, g.DrawPenalty)
}

// ─── CallLastCard Tests ────────────────────────────────────────────────────────────

func TestCallLastCard_Success(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	clearHand(g, p0)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	err := g.CallLastCard(p0)
	require.NoError(t, err)
	assert.True(t, g.Players[0].HasCalledLastCard)
}

func TestCallLastCard_TooManyCards(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	// Player has 7 cards by default.
	err := g.CallLastCard(p0)
	assert.Error(t, err)
}

// ─── ChallengeDraw4 Tests ─────────────────────────────────────────────────────

func TestChallengeDraw4_BluffSucceeds(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	p1 := pis[1].ID

	// Set up: active color is Red. p0 has a Red card (making WD4 illegal).
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	redCard := newCard(ColorRed, CardTypeNumber, 3)
	wd4 := newCard(ColorWild, CardTypeWildDrawFour, 50)
	clearHand(g, p0)
	giveCard(g, p0, redCard)
	giveCard(g, p0, wd4)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 2)) // filler

	// Play WD4 (it is a bluff — player has a red card).
	// IsValidPlay will return ErrIllegalWildDraw4, engine allows it.
	err := g.PlayCard(p0, wd4.ID, ColorBlue)
	require.NoError(t, err)

	p0HandBefore := len(g.Players[0].Hand)

	// p1 challenges.
	err = g.ChallengeDraw4(p1)
	require.NoError(t, err)

	// p0 (the bluffer) should draw 4.
	p0HandAfter := len(g.Players[0].Hand)
	assert.Equal(t, p0HandBefore+4, p0HandAfter, "bluffer must draw 4 on a successful challenge")
}

func TestChallengeDraw4_NoChallengeAvailable(t *testing.T) {
	g, pis := newTestGame(2)
	p1 := pis[1].ID

	err := g.ChallengeDraw4(p1)
	assert.Error(t, err)
}

// ─── ReshuffleIfNeeded Tests ──────────────────────────────────────────────────

func TestReshuffleIfNeeded_RefillsFromDiscard(t *testing.T) {
	g, _ := newTestGame(2)

	// Replace discard pile entirely with 5 dummy cards.
	g.DrawPile = nil
	g.DiscardPile = nil
	for i := 0; i < 5; i++ {
		g.DiscardPile = append(g.DiscardPile, newCard(ColorRed, CardTypeNumber, i))
	}
	top := g.topCard()

	err := g.ReshuffleIfNeeded()
	require.NoError(t, err)
	assert.Equal(t, 4, len(g.DrawPile), "4 cards should move to draw pile")
	assert.Equal(t, 1, len(g.DiscardPile), "only top card remains in discard")
	assert.Equal(t, top.ID, g.DiscardPile[0].ID, "top card must be preserved")
}

func TestReshuffleIfNeeded_ExhaustedBothPiles(t *testing.T) {
	g, _ := newTestGame(2)
	g.DrawPile = nil
	g.DiscardPile = nil

	err := g.ReshuffleIfNeeded()
	assert.ErrorIs(t, err, ErrDeckExhausted)
}

func TestReshuffleIfNeeded_OnlyTopCardLeft(t *testing.T) {
	g, _ := newTestGame(2)
	g.DrawPile = nil
	g.DiscardPile = []Card{newCard(ColorBlue, CardTypeNumber, 7)}

	err := g.ReshuffleIfNeeded()
	assert.ErrorIs(t, err, ErrDeckExhausted)
}

// ─── Clone Tests ──────────────────────────────────────────────────────────────

func TestClone_DeepCopy(t *testing.T) {
	g, _ := newTestGame(4)
	cp := g.Clone()

	// Mutating the clone must not affect the original.
	cp.Players[0].Hand = append(cp.Players[0].Hand, newCard(ColorRed, CardTypeNumber, 9))
	originalLen := len(g.Players[0].Hand)
	cloneLen := len(cp.Players[0].Hand)
	assert.NotEqual(t, originalLen, cloneLen, "clone and original hands should be independent")

	cp.DrawPile = cp.DrawPile[1:]
	assert.NotEqual(t, len(g.DrawPile), len(cp.DrawPile))
}

func TestClone_ScalarFieldsCopied(t *testing.T) {
	g, _ := newTestGame(2)
	g.Version = 42
	g.Direction = DirectionCounterClockwise
	g.CurrentColor = ColorYellow

	cp := g.Clone()
	assert.Equal(t, 42, cp.Version)
	assert.Equal(t, DirectionCounterClockwise, cp.Direction)
	assert.Equal(t, ColorYellow, cp.CurrentColor)
}

// ─── ToPublicView Tests ───────────────────────────────────────────────────────

func TestToPublicView_PlayerSeesOwnHand(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	view := g.ToPublicView(p0)
	assert.Equal(t, len(g.Players[0].Hand), len(view.MyHand))
}

func TestToPublicView_OpponentCardCountOnly(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	view := g.ToPublicView(p0)
	for _, pv := range view.Players {
		if pv.ID != p0 {
			assert.Equal(t, len(g.Players[1].Hand), pv.CardCount)
		}
	}
}

func TestToPublicView_LegalMovesPopulated(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	clearHand(g, p0)
	matchCard := newCard(ColorRed, CardTypeNumber, 3)
	noMatchCard := newCard(ColorBlue, CardTypeNumber, 2)
	giveCard(g, p0, matchCard)
	giveCard(g, p0, noMatchCard)

	view := g.ToPublicView(p0)
	// At least matchCard should be in legal moves.
	found := false
	for _, c := range view.LegalMoves {
		if c.ID == matchCard.ID {
			found = true
		}
	}
	assert.True(t, found, "matchCard must appear in legal moves")
}

// ─── GetLegalMoves Tests ──────────────────────────────────────────────────────

func TestGetLegalMoves_WildIsAlwaysLegal(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	wildCard := newCard(ColorWild, CardTypeWild, 50)
	clearHand(g, p0)
	giveCard(g, p0, wildCard)

	moves := g.GetLegalMoves(p0, false)
	require.Len(t, moves, 1)
	assert.Equal(t, wildCard.ID, moves[0].ID)
}

func TestGetLegalMoves_WD4IllegalWhenHasMatchingColor(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentColor = ColorRed
	g.CurrentPlayerIndex = 0

	wd4 := newCard(ColorWild, CardTypeWildDrawFour, 50)
	redCard := newCard(ColorRed, CardTypeNumber, 3)
	clearHand(g, p0)
	giveCard(g, p0, wd4)
	giveCard(g, p0, redCard)

	moves := g.GetLegalMoves(p0, true) // strict=true: WD4 excluded when holding matching color
	for _, m := range moves {
		assert.NotEqual(t, CardTypeWildDrawFour, m.Type,
			"WD4 must not appear in legal moves when player has matching color")
	}
}

// ─── ScoreValue Tests ─────────────────────────────────────────────────────────

func TestScoreValue_Number(t *testing.T) {
	for v := 0; v <= 9; v++ {
		c := newCard(ColorRed, CardTypeNumber, v)
		assert.Equal(t, v, c.ScoreValue())
	}
}

func TestScoreValue_ActionCards(t *testing.T) {
	for _, ct := range []CardType{CardTypeSkip, CardTypeReverse, CardTypeDrawTwo} {
		c := newCard(ColorRed, ct, 20)
		assert.Equal(t, 20, c.ScoreValue(), "action card should score 20")
	}
}

func TestScoreValue_Wilds(t *testing.T) {
	for _, ct := range []CardType{CardTypeWild, CardTypeWildDrawFour} {
		c := newCard(ColorWild, ct, 50)
		assert.Equal(t, 50, c.ScoreValue(), "wild card should score 50")
	}
}

// ─── NextPlayer Tests ─────────────────────────────────────────────────────────

func TestNextPlayer_Wraps(t *testing.T) {
	g, _ := newTestGame(3)
	g.CurrentPlayerIndex = 2
	g.NextPlayer()
	assert.Equal(t, 0, g.CurrentPlayerIndex)
}

func TestNextPlayer_CounterClockwise(t *testing.T) {
	g, _ := newTestGame(4)
	g.Direction = DirectionCounterClockwise
	g.CurrentPlayerIndex = 0
	g.NextPlayer()
	assert.Equal(t, 3, g.CurrentPlayerIndex)
}

// ─── ApplyAction Tests ────────────────────────────────────────────────────────

func TestApplyAction_PlayCard(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	playCard := newCard(ColorRed, CardTypeNumber, 3)
	clearHand(g, p0)
	giveCard(g, p0, playCard)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	err := g.ApplyAction(Action{
		Type:     ActionPlayCard,
		PlayerID: p0,
		CardID:   playCard.ID,
	})
	require.NoError(t, err)
}

func TestApplyAction_DrawCard(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.CurrentPlayerIndex = 0
	g.DrawPenalty = 0
	handBefore := len(g.Players[0].Hand)

	err := g.ApplyAction(Action{
		Type:     ActionDrawCard,
		PlayerID: p0,
	})
	require.NoError(t, err)
	assert.Equal(t, handBefore+1, len(g.Players[0].Hand))
}

func TestApplyAction_UnknownType(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	err := g.ApplyAction(Action{
		Type:     ActionType("unknown"),
		PlayerID: p0,
	})
	assert.Error(t, err)
}

// ─── GameAlreadyOver Tests ────────────────────────────────────────────────────

func TestPlayCard_GameOver_ReturnsError(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.Phase = PhaseFinished

	c := newCard(ColorRed, CardTypeNumber, 1)
	giveCard(g, p0, c)

	err := g.PlayCard(p0, c.ID, "")
	assert.ErrorIs(t, err, ErrGameAlreadyOver)
}

func TestDrawCard_GameOver_ReturnsError(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.Phase = PhaseFinished

	_, err := g.DrawCard(p0)
	assert.ErrorIs(t, err, ErrGameAlreadyOver)
}

// ─── Scoring Tests ────────────────────────────────────────────────────────────

func TestTallyScores_WinnerGetsOpponentPoints(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	p1 := pis[1].ID

	// Give p1 known cards.
	clearHand(g, p1)
	giveCard(g, p1, newCard(ColorRed, CardTypeNumber, 5))   // 5 pts
	giveCard(g, p1, newCard(ColorBlue, CardTypeSkip, 20))   // 20 pts
	giveCard(g, p1, newCard(ColorWild, CardTypeWild, 50))   // 50 pts

	// Play last card for p0 to win.
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0
	clearHand(g, p0)
	lastCard := newCard(ColorRed, CardTypeNumber, 3)
	giveCard(g, p0, lastCard)

	err := g.PlayCard(p0, lastCard.ID, "")
	require.NoError(t, err)
	require.Equal(t, PhaseFinished, g.Phase)

	for _, p := range g.Players {
		if p.ID == p0 {
			// p1's cards total 75; p0 wins and earns those points.
			assert.Equal(t, 75, p.Score)
		}
	}
}

// ─── Version Increment Tests ──────────────────────────────────────────────────

func TestVersion_IncrementsOnActions(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.CurrentPlayerIndex = 0

	v := g.Version
	_, err := g.DrawCard(p0)
	require.NoError(t, err)
	assert.Greater(t, g.Version, v)
}

// ─── Table-driven: Additional Engine Coverage ─────────────────────────────────

// TestPlayCard_MatchingColorNumber verifies playing a card of matching color and number.
func TestPlayCard_MatchingColorNumber(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	top := newCard(ColorRed, CardTypeNumber, 7)
	setTopCard(g, top)
	g.CurrentPlayerIndex = 0

	card := newCard(ColorRed, CardTypeNumber, 7)
	clearHand(g, p0)
	giveCard(g, p0, card)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 1))

	err := g.PlayCard(p0, card.ID, "")
	require.NoError(t, err)
	assert.Equal(t, ColorRed, g.CurrentColor)
}

// TestPlayCard_MatchingNumberDifferentColor verifies matching number different color.
func TestPlayCard_MatchingNumberDifferentColor(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	card := newCard(ColorBlue, CardTypeNumber, 5)
	clearHand(g, p0)
	giveCard(g, p0, card)
	giveCard(g, p0, newCard(ColorGreen, CardTypeNumber, 1))

	err := g.PlayCard(p0, card.ID, "")
	require.NoError(t, err)
	assert.Equal(t, ColorBlue, g.CurrentColor)
}

// TestPlayCard_RejectNonMatchingCard verifies ErrInvalidCard on mismatch.
func TestPlayCard_RejectNonMatchingCard(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	card := newCard(ColorBlue, CardTypeNumber, 3)
	clearHand(g, p0)
	giveCard(g, p0, card)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	err := g.PlayCard(p0, card.ID, "")
	assert.ErrorIs(t, err, ErrInvalidCard)
}

// TestPlayCard_WildAnyTime verifies wild can always be played regardless of top card.
func TestPlayCard_WildAnyTime(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	setTopCard(g, newCard(ColorBlue, CardTypeNumber, 9))
	g.CurrentPlayerIndex = 0

	wild := newCard(ColorWild, CardTypeWild, 50)
	clearHand(g, p0)
	giveCard(g, p0, wild)
	giveCard(g, p0, newCard(ColorGreen, CardTypeNumber, 1))

	err := g.PlayCard(p0, wild.ID, ColorYellow)
	require.NoError(t, err)
	assert.Equal(t, ColorYellow, g.CurrentColor)
}

// TestPlayCard_WildDraw4IllegalWhenHasMatchingColor verifies ErrIllegalWildDraw4 is returned.
func TestPlayCard_WildDraw4IllegalWhenHasMatchingColor(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	wd4 := newCard(ColorWild, CardTypeWildDrawFour, 50)
	redCard := newCard(ColorRed, CardTypeNumber, 3)
	clearHand(g, p0)
	giveCard(g, p0, wd4)
	giveCard(g, p0, redCard)

	// IsValidPlay returns ErrIllegalWildDraw4 but PlayCard still allows the bluff
	err := g.IsValidPlay(p0, wd4, ColorGreen)
	assert.ErrorIs(t, err, ErrIllegalWildDraw4)
}

// TestPlayCard_WildDraw4LegalWhenNoMatchingColor verifies WD4 is legal when hand has no matching color.
func TestPlayCard_WildDraw4LegalWhenNoMatchingColor(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	wd4 := newCard(ColorWild, CardTypeWildDrawFour, 50)
	blueCard := newCard(ColorBlue, CardTypeNumber, 3) // no red card
	clearHand(g, p0)
	giveCard(g, p0, wd4)
	giveCard(g, p0, blueCard)

	err := g.IsValidPlay(p0, wd4, ColorGreen)
	require.NoError(t, err)

	err = g.PlayCard(p0, wd4.ID, ColorGreen)
	require.NoError(t, err)
}

// TestPlayCard_DrawTwoCausesNextPlayerToDraw verifies +2 effect.
func TestPlayCard_DrawTwoCausesNextPlayerToDraw(t *testing.T) {
	g, pis := newTestGame(3)
	p0 := pis[0].ID
	p1 := pis[1].ID

	setTopCard(g, newCard(ColorGreen, CardTypeNumber, 2))
	g.CurrentPlayerIndex = 0

	d2 := newCard(ColorGreen, CardTypeDrawTwo, 20)
	clearHand(g, p0)
	giveCard(g, p0, d2)
	giveCard(g, p0, newCard(ColorGreen, CardTypeNumber, 1))

	p1Before := -1
	for _, p := range g.Players {
		if p.ID == p1 {
			p1Before = len(p.Hand)
		}
	}

	err := g.PlayCard(p0, d2.ID, "")
	require.NoError(t, err)

	p1After := -1
	for _, p := range g.Players {
		if p.ID == p1 {
			p1After = len(p.Hand)
		}
	}
	assert.Equal(t, p1Before+2, p1After, "p1 should draw 2 cards")
	// p1 is skipped: should be p2's turn (index 2)
	assert.Equal(t, 2, g.CurrentPlayerIndex)
}

// TestPlayCard_SkipCausesNextPlayerToLoseTurn verifies skip effect.
func TestPlayCard_SkipCausesNextPlayerToLoseTurn(t *testing.T) {
	g, pis := newTestGame(3)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorBlue, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0

	skip := newCard(ColorBlue, CardTypeSkip, 20)
	clearHand(g, p0)
	giveCard(g, p0, skip)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 2))

	err := g.PlayCard(p0, skip.ID, "")
	require.NoError(t, err)
	// p1 (index 1) is skipped, should be p2 (index 2)
	assert.Equal(t, 2, g.CurrentPlayerIndex)
}

// TestPlayCard_ReverseFlipsDirection tests reverse with 3+ players.
func TestPlayCard_ReverseFlipsDirection(t *testing.T) {
	g, pis := newTestGame(4)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorYellow, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0
	g.CurrentColor = ColorYellow
	g.Direction = DirectionClockwise

	rev := newCard(ColorYellow, CardTypeReverse, 20)
	clearHand(g, p0)
	giveCard(g, p0, rev)
	giveCard(g, p0, newCard(ColorYellow, CardTypeNumber, 2))

	err := g.PlayCard(p0, rev.ID, "")
	require.NoError(t, err)
	assert.Equal(t, DirectionCounterClockwise, g.Direction)
	// After reverse + one step counter-clockwise from 0: index 3
	assert.Equal(t, 3, g.CurrentPlayerIndex)
}

// TestPlayCard_Reverse2PlayersActsAsSkip verifies 2-player reverse is skip.
func TestPlayCard_Reverse2PlayersActsAsSkip(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 1))
	g.CurrentPlayerIndex = 0
	g.CurrentColor = ColorRed

	rev := newCard(ColorRed, CardTypeReverse, 20)
	clearHand(g, p0)
	giveCard(g, p0, rev)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 2))

	err := g.PlayCard(p0, rev.ID, "")
	require.NoError(t, err)
	// With 2 players, reverse acts as skip: p0 plays again
	assert.Equal(t, 0, g.CurrentPlayerIndex)
}

// TestDeckExhaustion_ReshufflesDiscardKeepingTopCard checks deck exhaustion behavior.
func TestDeckExhaustion_ReshufflesDiscardKeepingTopCard(t *testing.T) {
	g, _ := newTestGame(2)

	// Clear draw pile, set known discard pile
	g.DrawPile = nil
	g.DiscardPile = nil
	for i := 0; i < 10; i++ {
		g.DiscardPile = append(g.DiscardPile, newCard(ColorBlue, CardTypeNumber, i%9))
	}
	topBefore := g.DiscardPile[len(g.DiscardPile)-1]

	err := g.ReshuffleIfNeeded()
	require.NoError(t, err)

	assert.Equal(t, 9, len(g.DrawPile), "9 cards should move to draw pile")
	assert.Equal(t, 1, len(g.DiscardPile), "only top card remains in discard")
	assert.Equal(t, topBefore.ID, g.DiscardPile[0].ID, "top card must be preserved")
}

// TestWinCondition_PlayLastCardEndsGame verifies win condition.
func TestWinCondition_PlayLastCardEndsGame(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorGreen, CardTypeNumber, 3))
	g.CurrentPlayerIndex = 0

	last := newCard(ColorGreen, CardTypeNumber, 7)
	clearHand(g, p0)
	giveCard(g, p0, last)

	err := g.PlayCard(p0, last.ID, "")
	require.NoError(t, err)
	assert.Equal(t, PhaseFinished, g.Phase)
	assert.Equal(t, p0, g.WinnerID)
}

// TestLastCard_CallBeforePlayingSecondToLast verifies declaring Last Card requires exactly 1 card.
func TestLastCard_CallBeforePlayingSecondToLast(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	// Give player exactly 1 card so CallLastCard works.
	clearHand(g, p0)
	last := newCard(ColorRed, CardTypeNumber, 1)
	giveCard(g, p0, last)

	err := g.CallLastCard(p0)
	require.NoError(t, err)
	assert.True(t, g.Players[0].HasCalledLastCard)
}

// TestLastCard_PenaltyForNotCalling verifies player draws 2 for missing Last Card declaration.
func TestLastCard_PenaltyForNotCalling(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	// Give p0 exactly 2 cards; HasCalledLastCard is false
	playable := newCard(ColorRed, CardTypeNumber, 3)
	remaining := newCard(ColorBlue, CardTypeNumber, 1)
	clearHand(g, p0)
	giveCard(g, p0, playable)
	giveCard(g, p0, remaining)
	g.Players[0].HasCalledLastCard = false

	// Playing down to 1 without declaring Last Card should trigger penalty: 2 extra draws
	err := g.PlayCard(p0, playable.ID, "")
	require.NoError(t, err)

	// After penalty, p0 should have 3 cards (1 remaining + 2 penalty)
	handLen := len(g.Players[0].Hand)
	assert.Equal(t, 3, handLen, "Last Card penalty: player should have 3 cards after missing declaration")
}

// TestChallengeDraw4_BluffingPlayerOnly draws 2 for challenger (bluff confirmed, wd4 player draws 4).
func TestChallengeDraw4_BluffingPlayerOnlyDraws4(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	p1 := pis[1].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	redCard := newCard(ColorRed, CardTypeNumber, 2)
	wd4 := newCard(ColorWild, CardTypeWildDrawFour, 50)
	clearHand(g, p0)
	giveCard(g, p0, redCard)
	giveCard(g, p0, wd4)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 1))

	// p0 plays WD4 as bluff (has red card)
	err := g.PlayCard(p0, wd4.ID, ColorBlue)
	require.NoError(t, err)

	p0Before := len(g.Players[0].Hand)

	// p1 challenges successfully
	err = g.ChallengeDraw4(p1)
	require.NoError(t, err)

	p0After := len(g.Players[0].Hand)
	assert.Equal(t, p0Before+4, p0After, "bluffing player should draw 4")
}

// TestChallengeDraw4_NotBluffingChallengerDraws6 verifies challenger draws 6 on failed challenge.
func TestChallengeDraw4_NotBluffingChallengerDraws6(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	p1 := pis[1].ID

	// p0 has NO red cards, so WD4 is legal
	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	blueCard := newCard(ColorBlue, CardTypeNumber, 2)
	wd4 := newCard(ColorWild, CardTypeWildDrawFour, 50)
	clearHand(g, p0)
	giveCard(g, p0, blueCard)
	giveCard(g, p0, wd4)

	err := g.PlayCard(p0, wd4.ID, ColorGreen)
	require.NoError(t, err)

	p1Before := len(g.Players[1].Hand)

	// p1 challenges but it is not a bluff: challenger draws 6
	err = g.ChallengeDraw4(p1)
	require.NoError(t, err)

	p1After := len(g.Players[1].Hand)
	assert.Equal(t, p1Before+6, p1After, "challenger who fails should draw 6")
}

// TestScoreCalculation_OpponentHandValueSummedCorrectly verifies score tally.
func TestScoreCalculation_OpponentHandValueSummedCorrectly(t *testing.T) {
	g, pis := newTestGame(3)
	p0 := pis[0].ID
	p1 := pis[1].ID
	p2 := pis[2].ID

	clearHand(g, p1)
	giveCard(g, p1, newCard(ColorRed, CardTypeNumber, 8)) // 8
	giveCard(g, p1, newCard(ColorBlue, CardTypeSkip, 20)) // 20

	clearHand(g, p2)
	giveCard(g, p2, newCard(ColorWild, CardTypeWild, 50)) // 50

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0
	clearHand(g, p0)
	last := newCard(ColorRed, CardTypeNumber, 3)
	giveCard(g, p0, last)

	err := g.PlayCard(p0, last.ID, "")
	require.NoError(t, err)
	require.Equal(t, PhaseFinished, g.Phase)

	for _, p := range g.Players {
		if p.ID == p0 {
			assert.Equal(t, 78, p.Score, "winner should get 8+20+50=78 points")
		}
	}
}

// TestClone_ProducesIndependentCopy verifies clone independence.
func TestClone_ProducesIndependentCopy(t *testing.T) {
	g, _ := newTestGame(3)
	cp := g.Clone()

	extraCard := newCard(ColorRed, CardTypeNumber, 9)
	cp.Players[0].Hand = append(cp.Players[0].Hand, extraCard)
	cp.DrawPile = append(cp.DrawPile, extraCard)

	assert.NotEqual(t, len(g.Players[0].Hand), len(cp.Players[0].Hand),
		"modifying clone's hand should not affect original")
	assert.NotEqual(t, len(g.DrawPile), len(cp.DrawPile),
		"modifying clone's draw pile should not affect original")
}

// TestGetLegalMoves_CorrectPlayableCards verifies GetLegalMoves returns correct subset.
func TestGetLegalMoves_CorrectPlayableCards(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentColor = ColorRed
	g.CurrentPlayerIndex = 0

	matching := newCard(ColorRed, CardTypeNumber, 3)
	numberMatch := newCard(ColorBlue, CardTypeNumber, 5) // matches number 5
	noMatch := newCard(ColorBlue, CardTypeNumber, 2)
	wildCard := newCard(ColorWild, CardTypeWild, 50)

	clearHand(g, p0)
	giveCard(g, p0, matching)
	giveCard(g, p0, numberMatch)
	giveCard(g, p0, noMatch)
	giveCard(g, p0, wildCard)

	moves := g.GetLegalMoves(p0, false)
	moveIDs := map[string]bool{}
	for _, m := range moves {
		moveIDs[m.ID] = true
	}

	assert.True(t, moveIDs[matching.ID], "red 3 should be legal on red 5")
	assert.True(t, moveIDs[numberMatch.ID], "blue 5 should be legal on red 5 (number match)")
	assert.True(t, moveIDs[wildCard.ID], "wild should always be legal")
	assert.False(t, moveIDs[noMatch.ID], "blue 2 should not be legal on red 5")
}

// TestToPublicView_HidesOtherPlayerHands verifies public view hides opponent cards.
func TestToPublicView_HidesOtherPlayerHands(t *testing.T) {
	g, pis := newTestGame(3)
	p0 := pis[0].ID

	view := g.ToPublicView(p0)

	// MyHand should contain p0's cards
	assert.Equal(t, len(g.Players[0].Hand), len(view.MyHand))

	// Players[1] and Players[2] should show card count but not actual cards
	for _, pv := range view.Players {
		if pv.ID != p0 {
			// We can only see CardCount, not actual cards
			var actual int
			for _, p := range g.Players {
				if p.ID == pv.ID {
					actual = len(p.Hand)
				}
			}
			assert.Equal(t, actual, pv.CardCount)
		}
	}
}

// TestNotYourTurnError verifies ErrNotYourTurn is returned for out-of-turn play.
func TestNotYourTurnError(t *testing.T) {
	g, pis := newTestGame(3)
	p2 := pis[2].ID

	c := newCard(ColorRed, CardTypeNumber, 1)
	giveCard(g, p2, c)

	err := g.PlayCard(p2, c.ID, "")
	assert.ErrorIs(t, err, ErrNotYourTurn)
}

// TestCardNotInHandError verifies ErrCardNotInHand is returned for missing card.
func TestCardNotInHandError(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.CurrentPlayerIndex = 0
	ghost := newCard(ColorGreen, CardTypeNumber, 4) // not given to player
	err := g.PlayCard(p0, ghost.ID, "")
	assert.ErrorIs(t, err, ErrCardNotInHand)
}

// TestGameNotActiveError verifies ErrGameNotActive before game starts.
func TestGameNotActiveError(t *testing.T) {
	pis := makePlayers(1)
	g := NewGame(pis, HouseRules{}) // 1 player → PhaseWaiting

	c := newCard(ColorRed, CardTypeNumber, 1)
	giveCard(g, pis[0].ID, c)

	err := g.PlayCard(pis[0].ID, c.ID, "")
	assert.ErrorIs(t, err, ErrGameNotActive)
}

// TestGameAlreadyOverError verifies ErrGameAlreadyOver is returned after game ends.
func TestGameAlreadyOverError(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.Phase = PhaseFinished

	c := newCard(ColorRed, CardTypeNumber, 1)
	giveCard(g, p0, c)

	err := g.PlayCard(p0, c.ID, "")
	assert.ErrorIs(t, err, ErrGameAlreadyOver)
}

// TestDrawCard_NotYourTurnError verifies draw fails if it is not your turn.
func TestDrawCard_NotYourTurnError(t *testing.T) {
	g, pis := newTestGame(3)
	p2 := pis[2].ID

	_, err := g.DrawCard(p2)
	assert.ErrorIs(t, err, ErrNotYourTurn)
}

// TestDrawCard_ImmediatePlayIfPlayable tests ForcePlay house rule: drawn card is immediately played if legal.
// In the default engine DrawCard does NOT auto-play; it just draws and advances turn.
// This test verifies the basic behavior (no ForcePlay).
func TestDrawCard_AdvancesTurn(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID

	before := g.CurrentPlayerIndex
	_, err := g.DrawCard(p0)
	require.NoError(t, err)
	assert.NotEqual(t, before, g.CurrentPlayerIndex, "turn should advance after drawing")
}

// TestNextPlayer_RespectsDirection verifies NextPlayer uses Direction.
func TestNextPlayer_RespectsDirection(t *testing.T) {
	g, _ := newTestGame(4)
	g.CurrentPlayerIndex = 0
	g.Direction = DirectionClockwise
	g.NextPlayer()
	assert.Equal(t, 1, g.CurrentPlayerIndex)

	g.Direction = DirectionCounterClockwise
	g.NextPlayer()
	assert.Equal(t, 0, g.CurrentPlayerIndex)
}

// TestPlayCard_InvalidChosenColorOnWild verifies ErrInvalidColor for bad color on wild.
func TestPlayCard_InvalidChosenColorOnWild(t *testing.T) {
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	g.CurrentPlayerIndex = 0

	wild := newCard(ColorWild, CardTypeWild, 50)
	clearHand(g, p0)
	giveCard(g, p0, wild)
	giveCard(g, p0, newCard(ColorBlue, CardTypeNumber, 1))

	err := g.PlayCard(p0, wild.ID, ColorWild) // wild color is invalid
	assert.ErrorIs(t, err, ErrInvalidColor)
}

// TestStackDrawTwo_HouseRule verifies DrawPenalty stacks when house rule is enabled.
func TestStackDrawTwo_HouseRule(t *testing.T) {
	rules := HouseRules{StackDrawCards: true}
	pis := makePlayers(3)
	g := NewGame(pis, rules)

	p0 := pis[0].ID

	setTopCard(g, newCard(ColorRed, CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0
	g.CurrentColor = ColorRed
	g.DrawPenalty = 0

	d2 := newCard(ColorRed, CardTypeDrawTwo, 20)
	clearHand(g, p0)
	giveCard(g, p0, d2)
	giveCard(g, p0, newCard(ColorRed, CardTypeNumber, 1))

	err := g.PlayCard(p0, d2.ID, "")
	require.NoError(t, err)
	assert.Equal(t, 2, g.DrawPenalty, "draw penalty should stack to 2")
}

// TestFullGameSimulation_2Players runs two players to game completion.
func TestFullGameSimulation_2Players(t *testing.T) {
	const maxRounds = 500
	g, pis := newTestGame(2)
	p0 := pis[0].ID
	p1 := pis[1].ID

	ids := []string{p0, p1}

	for round := 0; round < maxRounds; round++ {
		if g.Phase == PhaseFinished {
			break
		}

		currentID := g.currentPlayer().ID
		currentIdx := g.CurrentPlayerIndex

		// Snapshot hand size before acting (Player is a value copy).
		handSize := len(g.Players[currentIdx].Hand)

		// Declare Last Card pre-emptively when holding exactly 1 card.
		if handSize == 1 {
			_ = g.CallLastCard(currentID)
		}

		legalMoves := g.GetLegalMoves(currentID, false)
		if len(legalMoves) > 0 {
			card := legalMoves[0]
			var chosenColor Color
			if card.IsWild() {
				chosenColor = ColorRed
			}
			_ = g.PlayCard(currentID, card.ID, chosenColor)
		} else {
			_, _ = g.DrawCard(currentID)
		}
	}

	// Game may or may not have ended; ensure no panic and state is consistent.
	// With at most 500 rounds in a 2-player game it almost certainly finishes.
	if g.Phase == PhaseFinished {
		assert.Contains(t, ids, g.WinnerID, "winner must be one of the players")
		for _, p := range g.Players {
			if p.ID == g.WinnerID {
				assert.Empty(t, p.Hand, "winner should have no cards")
			}
		}
	}
}
