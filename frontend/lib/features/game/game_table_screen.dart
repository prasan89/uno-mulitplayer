import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/providers/wilddeck_providers.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/core/services/mock_services.dart';
import 'package:wilddeck/core/services/wilddeck_services.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// Main game table screen — card play, hand, discard pile, player seats.
class GameTableScreen extends ConsumerStatefulWidget {
  final String gameId;
  const GameTableScreen({required this.gameId, super.key});

  @override
  ConsumerState<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends ConsumerState<GameTableScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _turnCtrl;
  WildGameState? _state;
  int? _selectedCardIndex;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _turnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _loadMockState();
  }

  void _loadMockState() {
    final s = MockData.buildMockGameState(widget.gameId);
    setState(() => _state = s);
    ref.read(gameProvider.notifier).loadMockGame(s);
  }

  @override
  void dispose() {
    _turnCtrl.dispose();
    super.dispose();
  }

  Future<void> _playCard(WildGameCard card) async {
    if (_actionBusy) return;
    final state = _state;
    if (state == null) return;

    if (card.type == WildCardType.wild || card.type == WildCardType.wildDrawFour) {
      context.push(WildRoutes.wildColorPicker, extra: card);
      return;
    }

    setState(() => _actionBusy = true);
    await ref.read(gameProvider.notifier).playCard(card.id);
    setState(() { _selectedCardIndex = null; _actionBusy = false; });
  }

  Future<void> _drawCard() async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    await ref.read(gameProvider.notifier).drawCard();
    setState(() => _actionBusy = false);
  }

  bool _canPlay(WildGameCard card, WildGameCard? topCard) {
    if (topCard == null) return true;
    if (card.type == WildCardType.wild || card.type == WildCardType.wildDrawFour) return true;
    if (card.color == topCard.color) return true;
    if (card.number != null && card.number == topCard.number) return true;
    if (card.type != WildCardType.number && card.type == topCard.type) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final state = gameState ?? _state;
    if (state == null) {
      return const Scaffold(
        backgroundColor: WildDeckTheme.navyDeep,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final hand = state.myHand.isNotEmpty ? state.myHand : MockData.mockHand;
    final topCard = state.topCard;
    final isMyTurn = state.isMyTurn;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            GameStatusBar(
              gameId: widget.gameId,
              drawPileCount: state.drawPileCount,
              discardCount: state.discardCount,
              isClockwise: state.isClockwise,
            ),
            // Opponent seats
            _OpponentRow(players: state.players.skip(1).toList()),
            const Spacer(),
            // Game table
            _GameTable(
              topCard: topCard,
              deckEmpty: state.drawPileCount == 0,
              currentColor: state.activeColor,
              onDraw: isMyTurn ? () { unawaited(_drawCard()); } : null,
              drawPileCount: state.drawPileCount,
            ),
            const Spacer(),
            // Turn indicator
            TurnIndicator(isMyTurn: isMyTurn, currentPlayerName: state.currentPlayerId),
            const SizedBox(height: 8),
            // My hand
            _PlayerHand(
              hand: hand,
              topCard: topCard,
              isMyTurn: isMyTurn,
              selectedIndex: _selectedCardIndex,
              onCardTap: (index) {
                if (!isMyTurn) return;
                final card = hand[index];
                if (!_canPlay(card, topCard)) return;
                if (_selectedCardIndex == index) {
                  unawaited(_playCard(card));
                } else {
                  setState(() => _selectedCardIndex = index);
                }
              },
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

class _OpponentRow extends StatelessWidget {
  final List<WildGamePlayer> players;
  const _OpponentRow({required this.players});

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox(height: 80);
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: players.map((p) => PlayerSeat(
          displayName: p.displayName,
          cardCount: p.cardCount,
          isCurrentTurn: p.isCurrentTurn,
          isBot: p.isBot,
          isConnected: p.isConnected,
        )).toList(),
      ),
    );
  }
}

class _GameTable extends StatelessWidget {
  final WildGameCard? topCard;
  final bool deckEmpty;
  final WildCardColor currentColor;
  final VoidCallback? onDraw;
  final int drawPileCount;

  const _GameTable({
    required this.topCard,
    required this.deckEmpty,
    required this.currentColor,
    required this.onDraw,
    required this.drawPileCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Draw pile
      GestureDetector(
        onTap: onDraw,
        child: Opacity(
          opacity: deckEmpty || onDraw == null ? 0.4 : 1.0,
          child: Stack(children: [
            for (int i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(i * 1.5, i * -1.5),
                child: WildDeckCardWidget(color: WildCardColor.wild, type: WildCardType.wild, isFaceDown: true),
              ),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      Container(
        width: 1, height: 70,
        color: WildDeckTheme.navyBorder,
      ),
      const SizedBox(width: 12),
      // Discard pile
      topCard != null
          ? WildDeckCardWidget(color: topCard!.color, type: topCard!.type, number: topCard!.number, isFaceDown: false)
          : Container(
              width: 56, height: 80,
              decoration: BoxDecoration(
                color: WildDeckTheme.navySurface,
                borderRadius: WildDeckTheme.radiusMedium,
                border: Border.all(color: WildDeckTheme.navyBorder, style: BorderStyle.solid),
              ),
            ),
      ...[
        const SizedBox(width: 12),
        _ColorIndicator(color: currentColor),
      ],
    ]);
  }
}

class _ColorIndicator extends StatelessWidget {
  final WildCardColor color;
  const _ColorIndicator({required this.color});

  Color get _c => switch (color) {
    WildCardColor.red    => WildDeckTheme.cardRed,
    WildCardColor.blue   => WildDeckTheme.cardBlue,
    WildCardColor.green  => WildDeckTheme.cardGreen,
    WildCardColor.yellow => WildDeckTheme.cardYellow,
    WildCardColor.wild   => WildDeckTheme.cardWild,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: _c, shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
        boxShadow: WildDeckTheme.buttonGlow(_c),
      ),
    );
  }
}

class _PlayerHand extends StatelessWidget {
  final List<WildGameCard> hand;
  final WildGameCard? topCard;
  final bool isMyTurn;
  final int? selectedIndex;
  final void Function(int index) onCardTap;

  const _PlayerHand({
    required this.hand,
    required this.topCard,
    required this.isMyTurn,
    required this.selectedIndex,
    required this.onCardTap,
  });

  bool _canPlay(WildGameCard card) {
    if (topCard == null) return true;
    if (card.type == WildCardType.wild || card.type == WildCardType.wildDrawFour) return true;
    if (card.color == topCard!.color) return true;
    if (card.number != null && card.number == topCard!.number) return true;
    if (card.type != WildCardType.number && card.type == topCard!.type) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return const SizedBox(height: 100);
    }
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hand.length,
        itemBuilder: (context, i) {
          final card = hand[i];
          final playable = isMyTurn && _canPlay(card);
          final selected = selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: isMyTurn && !playable ? 0.4 : 1.0,
              child: WildDeckCardWidget(
                color: card.color,
                type: card.type,
                number: card.number,
                isFaceDown: false,
                isSelected: selected,
                onTap: () => onCardTap(i),
              ),
            ),
          );
        },
      ),
    );
  }
}
