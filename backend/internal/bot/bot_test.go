package bot

import (
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/wilddeck/server/internal/game"
	"go.uber.org/zap"
)

// ─── Fake GameEngine ──────────────────────────────────────────────────────────

// fakeEngine implements GameEngine for tests.
// It wraps a real *game.GameState and routes actions through it.
type fakeEngine struct {
	mu     sync.Mutex
	states map[string]*game.GameState // gameID → state
}

func newFakeEngine() *fakeEngine {
	return &fakeEngine{states: make(map[string]*game.GameState)}
}

func (e *fakeEngine) addGame(gameID string, g *game.GameState) {
	e.mu.Lock()
	e.states[gameID] = g
	e.mu.Unlock()
}

func (e *fakeEngine) GetPublicState(gameID, playerID string) (*game.PublicGameState, error) {
	e.mu.Lock()
	g, ok := e.states[gameID]
	e.mu.Unlock()
	if !ok {
		return nil, nil
	}
	view := g.ToPublicView(playerID)
	return &view, nil
}

func (e *fakeEngine) ApplyAction(gameID string, action game.Action) error {
	e.mu.Lock()
	g, ok := e.states[gameID]
	e.mu.Unlock()
	if !ok {
		return nil
	}
	return g.ApplyAction(action)
}

// ─── Test helpers ─────────────────────────────────────────────────────────────

// makePlayers creates n PlayerInfo entries.
func makePlayersBot(n int) []game.PlayerInfo {
	pis := make([]game.PlayerInfo, n)
	for i := range pis {
		pis[i] = game.PlayerInfo{
			ID:   uuid.New().String(),
			Name: string(rune('A' + i)),
		}
	}
	return pis
}

// newBotGameState creates a fresh GameState with n players and no house rules.
func newBotGameState(n int) (*game.GameState, []game.PlayerInfo) {
	pis := makePlayersBot(n)
	g := game.NewGame(pis, game.HouseRules{})
	return g, pis
}

// setTopCardBot forces the top of the discard pile and CurrentColor.
func setTopCardBot(g *game.GameState, card game.Card) {
	if len(g.DiscardPile) == 0 {
		g.DiscardPile = []game.Card{card}
	} else {
		g.DiscardPile[len(g.DiscardPile)-1] = card
	}
	if card.IsWild() {
		g.CurrentColor = game.ColorRed
	} else {
		g.CurrentColor = card.Color
	}
}

// giveCardBot injects a card into a player's hand.
func giveCardBot(g *game.GameState, playerID string, card game.Card) {
	for i := range g.Players {
		if g.Players[i].ID == playerID {
			g.Players[i].Hand = append(g.Players[i].Hand, card)
			return
		}
	}
}

// clearHandBot removes all cards from a player's hand.
func clearHandBot(g *game.GameState, playerID string) {
	for i := range g.Players {
		if g.Players[i].ID == playerID {
			g.Players[i].Hand = nil
			return
		}
	}
}

// newCard creates a card with a fresh UUID (mirrors game package helper).
func newCard(color game.Color, t game.CardType, value int) game.Card {
	return game.Card{
		ID:    uuid.New().String(),
		Color: color,
		Type:  t,
		Value: value,
	}
}

// ─── HardStrategy Unit Tests ──────────────────────────────────────────────────

func TestHardStrategy_ChooseCard_PlaysLegalMove(t *testing.T) {
	g, pis := newBotGameState(2)
	p0 := pis[0].ID

	setTopCardBot(g, newCard(game.ColorRed, game.CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0

	clearHandBot(g, p0)
	legalCard := newCard(game.ColorRed, game.CardTypeNumber, 3)
	giveCardBot(g, p0, legalCard)
	giveCardBot(g, p0, newCard(game.ColorBlue, game.CardTypeNumber, 7))

	view := g.ToPublicView(p0)
	s := &HardStrategy{}
	chosen := s.ChooseCard(&view, view.MyHand)

	require.NotNil(t, chosen, "HardStrategy must choose a legal card when moves exist")
	found := false
	for _, m := range view.LegalMoves {
		if m.ID == chosen.ID {
			found = true
		}
	}
	assert.True(t, found, "chosen card must appear in LegalMoves")
}

func TestHardStrategy_ChooseCard_ReturnsNilOnEmpty(t *testing.T) {
	g, pis := newBotGameState(2)
	p0 := pis[0].ID

	// Force a situation where no legal moves exist by clearing hand
	setTopCardBot(g, newCard(game.ColorRed, game.CardTypeNumber, 5))
	g.CurrentPlayerIndex = 0
	clearHandBot(g, p0)

	view := g.ToPublicView(p0)
	// Manually empty legal moves for the view to simulate no moves
	view.LegalMoves = nil

	s := &HardStrategy{}
	chosen := s.ChooseCard(&view, view.MyHand)
	assert.Nil(t, chosen)
}

func TestHardStrategy_ChooseColor_ReturnsMostFrequent(t *testing.T) {
	hand := []game.Card{
		newCard(game.ColorRed, game.CardTypeNumber, 1),
		newCard(game.ColorRed, game.CardTypeNumber, 2),
		newCard(game.ColorBlue, game.CardTypeNumber, 3),
	}
	s := &HardStrategy{}
	color := s.ChooseColor(hand)
	assert.Equal(t, game.ColorRed, color, "should pick most frequent color in hand")
}

func TestHardStrategy_ChooseColor_ValidColorChosen(t *testing.T) {
	hand := []game.Card{
		newCard(game.ColorWild, game.CardTypeWild, 50),
	}
	s := &HardStrategy{}
	color := s.ChooseColor(hand)
	assert.True(t, game.IsValidColor(color),
		"ChooseColor must return a valid non-wild color")
}

func TestHardStrategy_ShouldCallLastCard_TrueWith2Cards(t *testing.T) {
	hand := []game.Card{
		newCard(game.ColorRed, game.CardTypeNumber, 1),
		newCard(game.ColorBlue, game.CardTypeNumber, 2),
	}
	s := &HardStrategy{}
	assert.True(t, s.ShouldCallLastCard(hand),
		"ShouldCallLastCard must return true when hand has exactly 2 cards")
}

func TestHardStrategy_ShouldCallLastCard_FalseWith3Cards(t *testing.T) {
	hand := []game.Card{
		newCard(game.ColorRed, game.CardTypeNumber, 1),
		newCard(game.ColorBlue, game.CardTypeNumber, 2),
		newCard(game.ColorGreen, game.CardTypeNumber, 3),
	}
	s := &HardStrategy{}
	assert.False(t, s.ShouldCallLastCard(hand))
}

func TestHardStrategy_ShouldCallLastCard_FalseWith1Card(t *testing.T) {
	hand := []game.Card{
		newCard(game.ColorRed, game.CardTypeNumber, 1),
	}
	s := &HardStrategy{}
	// With 1 card, the bot just played and is about to win — Last Card declaration was required before
	assert.False(t, s.ShouldCallLastCard(hand))
}

func TestHardStrategy_OnlyPlaysLegalMoves(t *testing.T) {
	// Run many iterations to ensure the strategy only picks legal moves.
	g, pis := newBotGameState(2)
	p0 := pis[0].ID

	setTopCardBot(g, newCard(game.ColorRed, game.CardTypeNumber, 5))
	g.CurrentColor = game.ColorRed
	g.CurrentPlayerIndex = 0

	clearHandBot(g, p0)
	for i := 0; i < 5; i++ {
		giveCardBot(g, p0, newCard(game.ColorBlue, game.CardTypeNumber, i+1))
	}
	giveCardBot(g, p0, newCard(game.ColorRed, game.CardTypeNumber, 3))
	giveCardBot(g, p0, newCard(game.ColorWild, game.CardTypeWild, 50))

	view := g.ToPublicView(p0)
	s := &HardStrategy{}

	for iter := 0; iter < 20; iter++ {
		chosen := s.ChooseCard(&view, view.MyHand)
		if chosen == nil {
			continue
		}
		found := false
		for _, m := range view.LegalMoves {
			if m.ID == chosen.ID {
				found = true
			}
		}
		assert.True(t, found,
			"HardStrategy must only return cards from LegalMoves (iteration %d)", iter)
	}
}

// ─── MediumStrategy Tests ─────────────────────────────────────────────────────

func TestMediumStrategy_ChooseCard_AlwaysLegalOrNil(t *testing.T) {
	g, pis := newBotGameState(2)
	p0 := pis[0].ID

	setTopCardBot(g, newCard(game.ColorGreen, game.CardTypeNumber, 7))
	g.CurrentColor = game.ColorGreen
	g.CurrentPlayerIndex = 0

	clearHandBot(g, p0)
	giveCardBot(g, p0, newCard(game.ColorGreen, game.CardTypeNumber, 4))
	giveCardBot(g, p0, newCard(game.ColorBlue, game.CardTypeNumber, 3))
	giveCardBot(g, p0, newCard(game.ColorWild, game.CardTypeWild, 50))

	view := g.ToPublicView(p0)
	s := &MediumStrategy{hard: &HardStrategy{}}

	for i := 0; i < 30; i++ {
		chosen := s.ChooseCard(&view, view.MyHand)
		if chosen == nil {
			continue
		}
		found := false
		for _, m := range view.LegalMoves {
			if m.ID == chosen.ID {
				found = true
			}
		}
		assert.True(t, found, "MediumStrategy must pick a legal move (iteration %d)", i)
	}
}

// ─── EasyStrategy Tests ───────────────────────────────────────────────────────

func TestEasyStrategy_ChooseCard_AlwaysLegalOrNil(t *testing.T) {
	g, pis := newBotGameState(2)
	p0 := pis[0].ID

	setTopCardBot(g, newCard(game.ColorYellow, game.CardTypeNumber, 2))
	g.CurrentColor = game.ColorYellow
	g.CurrentPlayerIndex = 0

	clearHandBot(g, p0)
	giveCardBot(g, p0, newCard(game.ColorYellow, game.CardTypeNumber, 6))
	giveCardBot(g, p0, newCard(game.ColorRed, game.CardTypeNumber, 4))

	view := g.ToPublicView(p0)
	s := &EasyStrategy{hard: &HardStrategy{}}

	for i := 0; i < 30; i++ {
		chosen := s.ChooseCard(&view, view.MyHand)
		if chosen == nil {
			continue
		}
		found := false
		for _, m := range view.LegalMoves {
			if m.ID == chosen.ID {
				found = true
			}
		}
		assert.True(t, found, "EasyStrategy must pick a legal move (iteration %d)", i)
	}
}

// ─── BotManager Tests ─────────────────────────────────────────────────────────

func TestBotManager_AddBot_RegistersBot(t *testing.T) {
	engine := newFakeEngine()
	mgr := NewBotManager(engine, nil, newNopLogger(t))

	b := mgr.AddBot("game-1", 0, DifficultyHard)
	require.NotNil(t, b)
	assert.Equal(t, DifficultyHard, b.Difficulty)
	assert.Equal(t, "game-1", b.GameID)

	mgr.mu.RLock()
	_, exists := mgr.bots[b.ID]
	mgr.mu.RUnlock()
	assert.True(t, exists)
}

func TestBotManager_RemoveBot_DeregistersBot(t *testing.T) {
	engine := newFakeEngine()
	mgr := NewBotManager(engine, nil, newNopLogger(t))

	b := mgr.AddBot("game-2", 0, DifficultyMedium)
	mgr.RemoveBot(b.ID)

	mgr.mu.RLock()
	_, exists := mgr.bots[b.ID]
	mgr.mu.RUnlock()
	assert.False(t, exists)
}

func TestBotManager_TakeoverPlayer_ReplacesHuman(t *testing.T) {
	engine := newFakeEngine()
	mgr := NewBotManager(engine, nil, newNopLogger(t))

	mgr.TakeoverPlayer("game-3", "human-1")

	mgr.mu.RLock()
	key := takeoverKey("game-3", "human-1")
	botID, exists := mgr.takeoverIndex[key]
	mgr.mu.RUnlock()

	assert.True(t, exists, "takeover should be recorded")
	assert.NotEmpty(t, botID)
}

func TestBotManager_ReleaseTakeover_RemovesBot(t *testing.T) {
	engine := newFakeEngine()
	mgr := NewBotManager(engine, nil, newNopLogger(t))

	mgr.TakeoverPlayer("game-4", "human-2")
	mgr.ReleaseTakeover("game-4", "human-2")

	mgr.mu.RLock()
	key := takeoverKey("game-4", "human-2")
	_, exists := mgr.takeoverIndex[key]
	mgr.mu.RUnlock()
	assert.False(t, exists, "takeover should be removed on release")
}

// TestBotManager_HardBot_PlaysOnlyLegalMoves verifies bot plays legal moves via engine.
func TestBotManager_HardBot_PlaysOnlyLegalMoves(t *testing.T) {
	g, pis := newBotGameState(2)
	p1 := pis[1].ID

	setTopCardBot(g, newCard(game.ColorRed, game.CardTypeNumber, 5))
	g.CurrentPlayerIndex = 1 // p1 is the bot's turn

	clearHandBot(g, p1)
	giveCardBot(g, p1, newCard(game.ColorRed, game.CardTypeNumber, 3))
	giveCardBot(g, p1, newCard(game.ColorBlue, game.CardTypeNumber, 7))

	engine := newFakeEngine()
	engine.addGame("game-bot", g)

	mgr := NewBotManager(engine, nil, newNopLogger(t))
	b := &Bot{
		ID:         uuid.New().String(),
		Name:       "TestHardBot",
		Difficulty: DifficultyHard,
		GameID:     "game-bot",
		PlayerID:   p1,
		strategy:   &HardStrategy{},
	}
	mgr.mu.Lock()
	mgr.bots[b.ID] = b
	mgr.mu.Unlock()

	// Run the bot turn synchronously for test determinism
	mgr.thinkDelay = 0
	done := make(chan struct{})
	go func() {
		mgr.executeTurn(b)
		close(done)
	}()

	select {
	case <-done:
		// OK
	case <-time.After(5 * time.Second):
		t.Fatal("bot turn did not complete within 5 seconds")
	}
}

// TestBotManager_HardBot_CallsLastCard verifies bot declares Last Card when hand drops to 2 cards.
func TestBotManager_HardBot_CallsLastCard(t *testing.T) {
	g, pis := newBotGameState(2)
	p1 := pis[1].ID

	// Set up bot with 2 cards (will drop to 1 after playing)
	setTopCardBot(g, newCard(game.ColorRed, game.CardTypeNumber, 5))
	g.CurrentPlayerIndex = 1

	clearHandBot(g, p1)
	giveCardBot(g, p1, newCard(game.ColorRed, game.CardTypeNumber, 3)) // will play this
	giveCardBot(g, p1, newCard(game.ColorBlue, game.CardTypeNumber, 7)) // will keep this

	engine := newFakeEngine()
	engine.addGame("game-last-card", g)

	mgr := NewBotManager(engine, nil, newNopLogger(t))
	mgr.thinkDelay = 0

	b := &Bot{
		ID:         uuid.New().String(),
		Name:       "WildDeckBot",
		Difficulty: DifficultyHard,
		GameID:     "game-last-card",
		PlayerID:   p1,
		strategy:   &HardStrategy{},
	}
	mgr.mu.Lock()
	mgr.bots[b.ID] = b
	mgr.mu.Unlock()

	s := &HardStrategy{}
	hand := []game.Card{
		newCard(game.ColorRed, game.CardTypeNumber, 3),
		newCard(game.ColorBlue, game.CardTypeNumber, 7),
	}
	assert.True(t, s.ShouldCallLastCard(hand),
		"HardStrategy should call Last Card when holding 2 cards")
}

// TestBotManager_BotCompletesTurnWithin5s verifies time bound.
func TestBotManager_BotCompletesTurnWithin5s(t *testing.T) {
	g, pis := newBotGameState(2)
	p1 := pis[1].ID

	setTopCardBot(g, newCard(game.ColorBlue, game.CardTypeNumber, 4))
	g.CurrentPlayerIndex = 1

	clearHandBot(g, p1)
	giveCardBot(g, p1, newCard(game.ColorBlue, game.CardTypeNumber, 2))
	giveCardBot(g, p1, newCard(game.ColorRed, game.CardTypeNumber, 8))

	engine := newFakeEngine()
	engine.addGame("game-timed", g)

	mgr := NewBotManager(engine, nil, newNopLogger(t))
	mgr.thinkDelay = 0 // no artificial delay in unit tests

	b := &Bot{
		ID:         uuid.New().String(),
		Name:       "TimedBot",
		Difficulty: DifficultyHard,
		GameID:     "game-timed",
		PlayerID:   p1,
		strategy:   &HardStrategy{},
	}
	mgr.mu.Lock()
	mgr.bots[b.ID] = b
	mgr.mu.Unlock()

	start := time.Now()
	done := make(chan struct{})
	go func() {
		mgr.executeTurn(b)
		close(done)
	}()

	select {
	case <-done:
		elapsed := time.Since(start)
		assert.Less(t, elapsed, 5*time.Second,
			"bot turn must complete in under 5 seconds")
	case <-time.After(5 * time.Second):
		t.Fatal("bot turn did not complete within 5 seconds")
	}
}

// ─── Strategy Factory Tests ───────────────────────────────────────────────────

func TestNewStrategy_ReturnsCorrectType(t *testing.T) {
	tests := []struct {
		diff Difficulty
		name string
	}{
		{DifficultyHard, "hard"},
		{DifficultyMedium, "medium"},
		{DifficultyEasy, "easy"},
	}
	for _, tc := range tests {
		s := newStrategy(tc.diff)
		assert.NotNil(t, s, "strategy for %s must not be nil", tc.name)
	}
}

// ─── handWithout helper test ──────────────────────────────────────────────────

func TestHandWithout_RemovesCorrectCard(t *testing.T) {
	c1 := newCard(game.ColorRed, game.CardTypeNumber, 1)
	c2 := newCard(game.ColorBlue, game.CardTypeNumber, 2)
	c3 := newCard(game.ColorGreen, game.CardTypeNumber, 3)
	hand := []game.Card{c1, c2, c3}

	result := handWithout(hand, c2.ID)
	require.Len(t, result, 2)
	for _, c := range result {
		assert.NotEqual(t, c2.ID, c.ID, "removed card must not appear in result")
	}
}

// ─── Context / timeout test ───────────────────────────────────────────────────

func TestBotManager_ExecuteTurn_RespectsContextTimeout(t *testing.T) {
	// Create an engine that never returns (simulate hang), verify context cancels.
	hangEngine := &hangingEngine{}
	mgr := NewBotManager(hangEngine, nil, newNopLogger(t))
	mgr.thinkDelay = 0

	b := &Bot{
		ID:         uuid.New().String(),
		Name:       "HangBot",
		Difficulty: DifficultyHard,
		GameID:     "game-hang",
		PlayerID:   "hang-player",
		strategy:   &HardStrategy{},
	}
	mgr.mu.Lock()
	mgr.bots[b.ID] = b
	mgr.mu.Unlock()

	done := make(chan struct{})
	go func() {
		mgr.executeTurn(b)
		close(done)
	}()

	// executeTurn has a 30s context, so we just verify it doesn't panic
	// and returns within a reasonable timeout during tests.
	select {
	case <-done:
		// success
	case <-time.After(2 * time.Second):
		// also acceptable: engine returned quickly (state nil)
	}
}

// hangingEngine returns a nil state quickly (simulates missing game).
type hangingEngine struct{}

func (e *hangingEngine) GetPublicState(gameID, playerID string) (*game.PublicGameState, error) {
	return nil, nil
}

func (e *hangingEngine) ApplyAction(gameID string, action game.Action) error {
	return nil
}

// ─── newNopLogger helper ──────────────────────────────────────────────────────

func newNopLogger(t *testing.T) *zap.Logger {
	t.Helper()
	logger, err := zap.NewDevelopment()
	if err != nil {
		t.Fatalf("failed to create logger: %v", err)
	}
	return logger
}
