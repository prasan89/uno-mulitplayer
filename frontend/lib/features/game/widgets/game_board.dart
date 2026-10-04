import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';
import '../widgets/discard_pile.dart';
import '../widgets/draw_pile.dart';
import '../widgets/player_hand.dart';
import '../widgets/player_info_row.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/uno_button.dart';

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
  final List<UnoCard> myHand;
  final Set<String> playableCardIds;
  final String? selectedCardId;
  final UnoCard? discardTopCard;
  final int discardCount;
  final int drawPileCount;
  final bool isMyTurn;
  final bool canDraw;
  final bool showUnoButton;
  final void Function(UnoCard card) onCardSelected;
  final void Function(UnoCard card) onCardPlayed;
  final VoidCallback onDrawCard;
  final VoidCallback onCallUno;
  final Future<CardColor?> Function() onColorPick;

  const GameBoard({
    super.key,
    required this.gameId,
    this.turnTimeRemaining,
    required this.opponents,
    required this.myHand,
    required this.playableCardIds,
    this.selectedCardId,
    this.discardTopCard,
    this.discardCount = 0,
    this.drawPileCount = 108,
    this.isMyTurn = false,
    this.canDraw = false,
    this.showUnoButton = false,
    required this.onCardSelected,
    required this.onCardPlayed,
    required this.onDrawCard,
    required this.onCallUno,
    required this.onColorPick,
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
        // Player hand + UNO button
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
          bottom: BorderSide(color: Colors.white12, width: 1),
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
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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
          ? const Color(0xFFE53935).withOpacity(0.1)
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
        // UNO button floats above the hand
        Positioned(
          top: -22,
          right: 20,
          child: UnoButton(
            isVisible: showUnoButton && isMyTurn,
            onPressed: onCallUno,
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
            ? const Color(0xFFE53935).withOpacity(0.2)
            : Colors.white12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUrgent ? const Color(0xFFE53935) : Colors.white24,
          width: 1,
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
