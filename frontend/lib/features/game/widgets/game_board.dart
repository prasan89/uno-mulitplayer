import 'package:flutter/material.dart';
import 'package:wilddeck/features/game/widgets/card_widget.dart';
import 'package:wilddeck/features/game/widgets/discard_pile.dart';
import 'package:wilddeck/features/game/widgets/draw_pile.dart';
import 'package:wilddeck/features/game/widgets/last_card_button.dart';
import 'package:wilddeck/features/game/widgets/player_hand.dart';
import 'package:wilddeck/features/game/widgets/player_info_row.dart';

/// Represents another player in the game (not the current user)
class OpponentPlayer {
  final String id;
  final String name;
  final int cardCount;
  final bool isCurrentTurn;

  const OpponentPlayer({
    required this.id,
    required this.name,
    required this.cardCount,
    this.isCurrentTurn = false,
  });
}

class GameBoard extends StatelessWidget {
  final String gameId;
  final Duration? turnTimeRemaining;
  final List<OpponentPlayer> opponents;
  final List<WildCard> myHand;
  final Set<String> playableCardIds;
  final String? selectedCardId;
  final WildCard? discardTopCard;
  final int discardCount;
  final int drawPileCount;
  final bool isMyTurn;
  final bool canDraw;
  final bool showLastCardButton;
  final void Function(WildCard card) onCardSelected;
  final void Function(WildCard card) onCardPlayed;
  final VoidCallback onDrawCard;
  final VoidCallback onCallLastCard;
  final Future<CardColor?> Function() onColorPick;

  const GameBoard({
    required this.gameId, required this.opponents, required this.myHand, required this.playableCardIds, required this.onCardSelected, required this.onCardPlayed, required this.onDrawCard, required this.onCallLastCard, required this.onColorPick, super.key,
    this.turnTimeRemaining,
    this.selectedCardId,
    this.discardTopCard,
    this.discardCount = 0,
    this.drawPileCount = 108,
    this.isMyTurn = false,
    this.canDraw = false,
    this.showLastCardButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Opponents row
        _buildOpponentsRow(context),
        // Center play area
        Expanded(
          child: _buildCenterArea(context),
        ),
        // Turn indicator
        _buildTurnIndicator(context),
        // Player hand + Last Card button
        _buildBottomSection(context),
      ],
    );
  }

  Widget _buildOpponentsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(
          bottom: BorderSide(color: Colors.white12),
        ),
      ),
      child: opponents.isEmpty
          ? const SizedBox(height: 80)
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: opponents
                    .map(
                      (op) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PlayerInfoRow(
                          playerName: op.name,
                          cardCount: op.cardCount,
                          isCurrentTurn: op.isCurrentTurn,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }

  Widget _buildCenterArea(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF121212),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DrawPile(
              cardCount: drawPileCount,
              onDraw: onDrawCard,
              canDraw: isMyTurn && canDraw,
            ),
            const SizedBox(width: 32),
            DiscardPile(
              topCard: discardTopCard,
              totalDiscarded: discardCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: isMyTurn
          ? const Color(0xFFE53935).withValues(alpha: 0.1)
          : Colors.transparent,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMyTurn) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              isMyTurn ? 'Your Turn!' : 'Waiting...',
              style: TextStyle(
                color: isMyTurn ? const Color(0xFFE53935) : Colors.white38,
                fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                letterSpacing: isMyTurn ? 0.5 : 0,
              ),
            ),
            if (isMyTurn && turnTimeRemaining != null) ...[
              const SizedBox(width: 8),
              _TurnTimer(remaining: turnTimeRemaining!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        PlayerHand(
          cards: myHand,
          playableCardIds: isMyTurn ? playableCardIds : {},
          selectedCardId: selectedCardId,
          onCardTap: (card) {
            if (selectedCardId == card.id) {
              onCardPlayed(card);
            } else {
              onCardSelected(card);
            }
          },
        ),
        // Last Card button floats above the hand
        Positioned(
          top: -22,
          right: 20,
          child: LastCardButton(
            isVisible: showLastCardButton && isMyTurn,
            onPressed: onCallLastCard,
          ),
        ),
      ],
    );
  }
}

class _TurnTimer extends StatelessWidget {
  final Duration remaining;

  const _TurnTimer({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inSeconds;
    final isUrgent = seconds <= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFE53935).withValues(alpha: 0.2)
            : Colors.white12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUrgent ? const Color(0xFFE53935) : Colors.white24,
        ),
      ),
      child: Text(
        '${seconds}s',
        style: TextStyle(
          color: isUrgent ? const Color(0xFFE53935) : Colors.white70,
          fontSize: 12,
          fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
