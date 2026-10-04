# Single-Player Mode (VS AI) — WildDeck

## Overview

**VS AI** lets a single human player start a game immediately against 1–3 AI opponents, with no waiting for real players to join. The entire session runs locally in the Flutter app — no WebSocket connection or backend server is required.

---

## How to start a VS AI game

1. Open WildDeck and tap **Play** on the home screen.
2. On the Choose Mode screen, tap **VS AI** (marked "NEW").
3. On the VS AI Setup screen:
   - Choose **Difficulty**: Easy / Normal / Hard.
   - Choose **Opponents**: 1, 2, or 3 AI players.
   - Preview your opponents — each has a unique name and personality.
4. Tap **START GAME**.

---

## Opponents

| Seat | Name  | Personality  | Description |
|------|-------|-------------|-------------|
| 0    | Rex   | Aggressive  | Chases action cards; tries to disrupt opponents early |
| 1    | Nova  | Strategic   | Conserves wild cards; plays a calculated long game |
| 2    | Milo  | Casual      | Relaxed play style; not a threat early but steady |
| 3    | Blaze | Risk Taker  | Loves wild cards; plays Wild Draw Four aggressively |

Opponents are always assigned in seat order (Rex first, then Nova, Milo, Blaze). With 1 opponent you face Rex; with 2 you face Rex and Nova; with 3 all three appear.

---

## Game rules

VS AI uses the same rules as a standard WildDeck game:

- Each player starts with 7 cards.
- On your turn: play a legal card, or draw from the pile.
- A card is legal if it matches the top card's **color** or **type/number**, or is a wild.
- **Last Card** must be declared when you play down to 1 card. Failure to declare results in drawing 2 penalty cards.
- First player to empty their hand wins.

---

## AI behaviour

- AI bots observe only the public game state (top card, discard pile, opponent hand counts) plus their own hand — no cheating.
- AI actions are submitted through the same `GameAction` interface used by human players.
- AI never directly modifies game state, deck, turn order, active color, winner, or score.
- Thinking indicators appear in the opponent row while an AI is "deciding".

---

## Play Again

After a game ends the result screen shows **PLAY AGAIN**. Tapping it navigates back to the VS AI Setup screen, letting you choose a fresh difficulty and opponent count. A new in-memory game state is created — no stale data from the previous game.

---

## Rewards

VS AI games award coins and XP on completion:

| Outcome | Coins | XP |
|---------|-------|----|
| Win     | +150  | +80 |
| Loss    | +25   | +15 |

Win streak is incremented on a win.

---

## Architecture notes

- The VS AI session is entirely offline. No backend calls are made during gameplay.
- The Flutter local engine (`AIGameService`) mirrors the Go engine rules for card legality, draw-penalty propagation, skip/reverse/draw-two effects, and wild-color tracking.
- The `POST /api/match/vs-ai` endpoint (backend) is provided for potential future use (server-side VS AI) but is not used by the current Flutter client.
- For implementation details see `AI_ARCHITECTURE.md` and `AI_DIFFICULTY.md`.
