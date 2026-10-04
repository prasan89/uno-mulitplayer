# AI Architecture — WildDeck

## Overview

WildDeck's AI system is split across two layers:

| Layer | Location | Purpose |
|-------|----------|---------|
| **Backend bot engine** | `backend/internal/bot/` | Multiplayer AI bots driven via WebSocket game loop |
| **Flutter local engine** | `frontend/lib/features/game/ai_game_service.dart` | Offline VS AI mode with in-memory game state |

Both layers share the same game-rule contract: AI may only submit legal `GameAction`s computed from publicly observable state plus its own hand. Neither layer directly mutates deck, turn order, active color, or score.

---

## Backend Bot Package (`backend/internal/bot/`)

### Key types

```
BotManager          — owns all active Bot instances; drives turns via OnTurnStart()
Bot                 — single AI player: ID, GameID, PlayerID, Difficulty, Personality
Strategy interface  — ChooseCard / ChooseColor / ShouldCallLastCard / ShouldChallengeDraw4
HardStrategy        — full priority-based decision tree
MediumStrategy      — hard strategy with 20% random deviation
EasyStrategy        — hard strategy with 50% random deviation
RandomProvider      — abstraction over math/rand for deterministic test injection
Personality         — named character (Rex/Nova/Milo/Blaze) with PersonalityWeights
```

### Decision flow

```
OnTurnStart(gameID, playerID)
  └─ go executeTurn(bot)
       ├─ think delay (per-difficulty range from ThinkDelayRange)
       ├─ GetPublicState(gameID, playerID)
       ├─ ShouldChallengeDraw4? → ApplyAction(ChallengeDraw4)
       ├─ DrawPenalty > 0 && no legal moves? → ApplyAction(DrawCard)
       ├─ Strategy.ChooseCard(state, hand)
       │   ├─ nil → ApplyAction(DrawCard)
       │   └─ card → ShouldCallLastCard? → ApplyAction(CallLastCard)
       │             ChooseColor? (wild only)
       │             → ApplyAction(PlayCard)
       └─ Metrics: bot_turns_total, bot_think_seconds
```

### Think delays by difficulty

| Difficulty | Min | Max |
|------------|-----|-----|
| Easy       | 500 ms | 1200 ms |
| Normal     | 700 ms | 1500 ms |
| Hard       | 900 ms | 1800 ms |

Setting `BotManager.thinkDelay = 0` bypasses delays entirely (used in tests).

### Deterministic testing

Inject a seeded `RandomProvider` via `NewBotManagerWithRNG`:

```go
rng := bot.SeededRandom(42)
mgr := bot.NewBotManagerWithRNG(engine, hub, logger, rng)
```

---

## Flutter Local Engine (`ai_game_service.dart`)

The Flutter VS AI mode runs an entirely in-process game engine — no network round-trips.

### Key types

```
AIGameService     — stream-based game loop; accepts human actions; schedules AI turns
AIDecisionEngine  — mirrors HardStrategy priority logic in Dart
AILocalPlayer     — mutable in-memory player (id, name, isBot, isHuman, hand)
_LocalDeck        — 108-card deck with Fisher-Yates shuffle + discard-pile reshuffle
AIGameState       — immutable snapshot emitted on every state change
AIPersonality     — personality weights (aggression, riskTolerance, wildPreference, …)
AIPersonalities   — factory constants: rex, nova, milo, blaze + atSeat(index)
AIDifficulty      — easy / normal / hard (mirrors backend Difficulty)
```

### Turn cycle

```
Human action (playCard / drawCard / callLastCard)
  └─ validate → mutate state → _emit() → _scheduleAIIfNeeded()

_scheduleAIIfNeeded()
  └─ current player is bot?
       ├─ aiThinking = true → _emit()
       └─ Future.delayed(thinkDelay) → _executeAITurn()
            ├─ AIDecisionEngine.chooseCard(hand, topCard, activeColor, players)
            ├─ null? → draw
            └─ card  → chooseColor? (wild) → applyPlayedCard → _emit() → _scheduleAIIfNeeded()
```

### Game lifecycle

```dart
final service = AIGameService(humanPlayerId: ..., humanName: ..., bots: [...]);
service.stateStream.listen((state) { ... });  // subscribe
service.startGame();                          // deal 7 cards, flip start card
service.playCard(cardId, chosenColor: color); // human plays
service.drawCard();                           // human draws
service.restartGame();                        // Play Again (same players)
service.dispose();                            // close stream
```

---

## Personality system

All four personalities are available in both layers:

| Name  | Trait        | Aggression | Risk Tolerance | Wild Preference | Action Card Pref |
|-------|-------------|------------|----------------|-----------------|-----------------|
| Rex   | Aggressive  | 1.8        | 1.2            | 0.7             | 1.6             |
| Nova  | Strategic   | 0.8        | 0.6            | 0.5             | 0.9             |
| Milo  | Casual      | 0.6        | 0.8            | 1.2             | 0.7             |
| Blaze | Risk Taker  | 1.3        | 2.0            | 1.8             | 1.1             |

Personalities rotate by seat index: seat 0 → Rex, seat 1 → Nova, seat 2 → Milo, seat 3 → Blaze, seat 4 → Rex again.

---

## VS AI HTTP endpoint

`POST /api/match/vs-ai`

```json
{ "bot_count": 3, "difficulty": "hard" }
```

Response (201):

```json
{
  "game_id": "<uuid>",
  "ws_url": "ws://host/ws/<game_id>",
  "bots": [
    { "id": "<uuid>", "name": "Rex",  "player_id": "<uuid>", "difficulty": "hard", "personality": "Rex" },
    { "id": "<uuid>", "name": "Nova", "player_id": "<uuid>", "difficulty": "hard", "personality": "Nova" },
    { "id": "<uuid>", "name": "Milo", "player_id": "<uuid>", "difficulty": "hard", "personality": "Milo" }
  ]
}
```
