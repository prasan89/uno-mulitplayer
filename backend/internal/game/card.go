package game

// Color represents the color of a WildDeck card.
type Color string

const (
	ColorRed    Color = "red"
	ColorGreen  Color = "green"
	ColorBlue   Color = "blue"
	ColorYellow Color = "yellow"
	ColorWild   Color = "wild"
)

// CardType represents the type/face of a WildDeck card.
type CardType string

const (
	CardTypeNumber      CardType = "number"
	CardTypeSkip        CardType = "skip"
	CardTypeReverse     CardType = "reverse"
	CardTypeDrawTwo     CardType = "draw_two"
	CardTypeWild        CardType = "wild"
	CardTypeWildDrawFour CardType = "wild_draw_four"
)

// Card represents a single WildDeck card.
type Card struct {
	ID    string   `json:"id"`
	Color Color    `json:"color"`
	Type  CardType `json:"type"`
	Value int      `json:"value"` // 0-9 for number cards, 20 for action cards, 50 for wild cards
}

// ScoreValue returns the point value of the card for scoring purposes.
func (c Card) ScoreValue() int {
	switch c.Type {
	case CardTypeNumber:
		return c.Value
	case CardTypeSkip, CardTypeReverse, CardTypeDrawTwo:
		return 20
	case CardTypeWild, CardTypeWildDrawFour:
		return 50
	default:
		return 0
	}
}

// IsWild returns true if the card is a wild-type card.
func (c Card) IsWild() bool {
	return c.Type == CardTypeWild || c.Type == CardTypeWildDrawFour
}

// IsActionCard returns true if the card has a special action effect.
func (c Card) IsActionCard() bool {
	return c.Type != CardTypeNumber
}

// ValidColors returns the set of colors that can be legitimately assigned.
func ValidColors() []Color {
	return []Color{ColorRed, ColorGreen, ColorBlue, ColorYellow}
}

// IsValidColor returns true if the color is a non-wild playable color.
func IsValidColor(c Color) bool {
	switch c {
	case ColorRed, ColorGreen, ColorBlue, ColorYellow:
		return true
	default:
		return false
	}
}
