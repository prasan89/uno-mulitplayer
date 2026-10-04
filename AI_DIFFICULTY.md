# AI Difficulty — WildDeck

## Overview

WildDeck offers three AI difficulty levels. Difficulty controls two independent axes:

1. **Decision quality** — how intelligently the AI selects cards
2. **Think delay** — how long the AI appears to "think" before acting

---

## Difficulty levels

### Easy
- **Decision quality:** 50% of turns use a random legal card; the other 50% use the full priority logic.
- **Color selection:** 50% of wild-color choices are random; otherwise picks the most-common color in hand.
- **Think delay:** 500–1200 ms
- **Target player:** New players, children, casual sessions.

### Normal
- **Decision quality:** 20% of turns deviate randomly; 80% use the full priority logic.
- **Color selection:** Always picks the most-common color in hand.
- **Think delay:** 700–1500 ms
- **Target player:** Average players wanting a fair match.

### Hard
- **Decision quality:** Full priority decision tree — no random deviation.
- **Think delay:** 900–1800 ms
- **Target player:** Experienced players who want a challenge.

---

## Decision priority (Hard / 80% of Normal / 50% of Easy)

When choosing a card to play the engine evaluates legal moves in the following order:

1. **Draw cards when opponent is close to winning** — if the minimum opponent hand size is ≤ 3, or the bot is Aggressive-personality: play Draw Two or Wild Draw Four first.
2. **Action cards against dangerous opponents** — if an opponent has ≤ 3 cards: prefer Skip, Reverse, Draw Two over number cards.
3. **Matching-color number card** — preserve action/wild cards for later (unless Wild-preference personality overrides).
4. **Any colored action card** — Reverse, Skip, Draw Two in any color.
5. **Any number card** — lowest-commitment play.
6. **Plain Wild** — preferred over Wild Draw Four unless the bot has high risk tolerance.
7. **Wild Draw Four** — fallback when nothing else is playable or bot has high risk tolerance.

---

## Think delay mechanics

Think delays are sampled uniformly from the per-difficulty range on each turn:

```
actualDelay = min + rand.Intn(max - min + 1)    // Go backend
actualDelay = min + Random().nextInt(max - min + 1)  // Flutter local
```

In the Go backend, setting `BotManager.thinkDelay = 0` disables all delays (used in tests). The Flutter engine does the same via `Future.delayed(Duration.zero)`.

---

## Interaction with Personality

Difficulty sets the base random-deviation rate. Personality modifiers layer on top to create distinct characters at the same difficulty:

- A **Hard + Rex** bot is aggressive and focuses on action cards.
- A **Hard + Nova** bot is strategic and preserves wilds until they matter.
- A **Hard + Blaze** bot is a risk-taker who plays Wild Draw Four more aggressively.
- An **Easy + Milo** bot makes random choices half the time AND is inherently casual.

See `AI_ARCHITECTURE.md` for full personality weights.
