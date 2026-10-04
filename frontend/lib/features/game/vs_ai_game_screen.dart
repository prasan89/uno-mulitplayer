import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/features/game/ai_game_service.dart';
import 'package:wilddeck/features/game/vs_ai_setup_screen.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// Game table screen for VS AI single-player mode.
class VsAIGameScreen extends StatefulWidget {
  final VsAIGameArgs args;
  const VsAIGameScreen({required this.args, super.key});

  @override
  State<VsAIGameScreen> createState() => _VsAIGameScreenState();
}

class _VsAIGameScreenState extends State<VsAIGameScreen>
    with SingleTickerProviderStateMixin {
  late AIGameService _service;
  late AnimationController _turnCtrl;
  AIGameState? _state;
  int? _selectedCardIndex;
  bool _actionBusy = false;
  StreamSubscription<AIGameState>? _sub;

  @override
  void initState() {
    super.initState();
    _turnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    unawaited(_turnCtrl.repeat(reverse: true));

    _service = AIGameService(
      humanPlayerId: widget.args.humanPlayerId,
      humanName: widget.args.humanName,
      bots: widget.args.bots,
    );

    _sub = _service.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
      if (state.isFinished) {
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            context.pushReplacement(
              WildRoutes.vsAiResult,
              extra: VsAIResultArgs(
                winnerId: state.winnerId,
                humanPlayerId: widget.args.humanPlayerId,
                gameArgs: widget.args,
              ),
            );
          }
        });
      }
    });

    _service.startGame();
  }

  @override
  void dispose() {
    _turnCtrl.dispose();
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  bool _canPlay(WildGameCard card) {
    final state = _state;
    if (state == null) return false;
    final top = state.topCard;
    final color = state.activeColor;
    if (top == null) return true;
    if (card.type == WildCardType.wild || card.type == WildCardType.wildDrawFour) return true;
    if (card.color == color) return true;
    if (card.type == WildCardType.number && top.type == WildCardType.number &&
        card.number != null && card.number == top.number) return true;
    if (card.type != WildCardType.number && !card.isWild && card.type == top.type) return true;
    return false;
  }

  Future<void> _onCardTap(int index) async {
    final state = _state;
    if (state == null || !state.isMyTurn || _actionBusy) return;
    final humanPlayer = state.players.firstWhere(
        (p) => p.id == widget.args.humanPlayerId,
        orElse: () => state.players.first);
    final hand = humanPlayer.hand;
    if (index >= hand.length) return;
    final card = hand[index];
    if (!_canPlay(card)) return;

    if (_selectedCardIndex == index) {
      // Second tap: play the card
      if (card.isWild) {
        // Navigate to color picker
        final color = await context.push<WildCardColor>(
          WildRoutes.wildColorPicker,
          extra: card,
        );
        if (color != null && mounted) {
          setState(() { _actionBusy = true; _selectedCardIndex = null; });
          _service.playCardWithColor(card.id, color);
          setState(() => _actionBusy = false);
        }
      } else {
        setState(() { _actionBusy = true; _selectedCardIndex = null; });
        _service.playCard(card.id);
        setState(() => _actionBusy = false);
      }
    } else {
      setState(() => _selectedCardIndex = index);
    }
  }

  void _onDraw() {
    final state = _state;
    if (state == null || !state.isMyTurn || _actionBusy) return;
    setState(() => _actionBusy = true);
    _service.drawCard();
    setState(() { _actionBusy = false; _selectedCardIndex = null; });
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    if (state == null) {
      return const Scaffold(
        backgroundColor: WildDeckTheme.navyDeep,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final humanPlayer = state.players.firstWhere(
        (p) => p.id == widget.args.humanPlayerId,
        orElse: () => state.players.first);
    final hand = humanPlayer.hand;
    final topCard = state.topCard;
    final isMyTurn = state.isMyTurn;
    final opponents = state.players.where((p) => !p.isHuman).toList();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            // Status bar
            _AIGameStatusBar(
              gameId: state.gameId,
              drawPileCount: state.drawPileCount,
              discardCount: state.discardCount,
              isClockwise: state.direction == TurnDirection.clockwise,
            ),
            // Opponent row
            _AIOpponentRow(
              opponents: opponents,
              currentPlayerId: state.currentPlayer.id,
              aiThinking: state.aiThinking,
              thinkingBotName: state.thinkingBotName,
            ),
            const Spacer(),
            // Game table center
            _AIGameTable(
              topCard: topCard,
              deckEmpty: state.drawPileCount == 0,
              currentColor: state.activeColor,
              onDraw: isMyTurn ? _onDraw : null,
              drawPileCount: state.drawPileCount,
              drawPenalty: state.drawPenalty,
            ),
            const Spacer(),
            // Turn indicator
            TurnIndicator(
              isMyTurn: isMyTurn,
              currentPlayerName: state.currentPlayer.name,
            ),
            const SizedBox(height: 8),
            // My hand
            _AIPlayerHand(
              hand: hand,
              isMyTurn: isMyTurn,
              selectedIndex: _selectedCardIndex,
              canPlay: _canPlay,
              onCardTap: _onCardTap,
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}

// ─── AI Game Status Bar ───────────────────────────────────────────────────────

class _AIGameStatusBar extends StatelessWidget {
  final String gameId;
  final int drawPileCount;
  final int discardCount;
  final bool isClockwise;

  const _AIGameStatusBar({
    required this.gameId,
    required this.drawPileCount,
    required this.discardCount,
    required this.isClockwise,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => context.go(WildRoutes.gameMode),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        Row(children: [
          const Icon(Icons.style_rounded, color: WildDeckTheme.textMuted, size: 14),
          const SizedBox(width: 4),
          Text('$drawPileCount', style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 13)),
          const SizedBox(width: 12),
          Icon(isClockwise ? Icons.rotate_right_rounded : Icons.rotate_left_rounded,
              color: WildDeckTheme.textMuted, size: 14),
          const SizedBox(width: 12),
          const Icon(Icons.layers_rounded, color: WildDeckTheme.textMuted, size: 14),
          const SizedBox(width: 4),
          Text('$discardCount', style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 13)),
          const SizedBox(width: 4),
          const Text('VS AI', style: TextStyle(
            color: WildDeckTheme.cardRed, fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1,
          )),
        ]),
      ]),
    );
  }
}

// ─── AI Opponent Row ──────────────────────────────────────────────────────────

class _AIOpponentRow extends StatelessWidget {
  final List<AILocalPlayer> opponents;
  final String currentPlayerId;
  final bool aiThinking;
  final String? thinkingBotName;

  const _AIOpponentRow({
    required this.opponents,
    required this.currentPlayerId,
    required this.aiThinking,
    required this.thinkingBotName,
  });

  @override
  Widget build(BuildContext context) {
    if (opponents.isEmpty) return const SizedBox(height: 80);
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: opponents.map((p) {
          final isCurrent = p.id == currentPlayerId;
          final isThinking = aiThinking && thinkingBotName == p.name;
          return _AIPlayerSeat(
            name: p.name,
            cardCount: p.hand.length,
            isCurrentTurn: isCurrent,
            isThinking: isThinking,
          );
        }).toList(),
      ),
    );
  }
}

class _AIPlayerSeat extends StatelessWidget {
  final String name;
  final int cardCount;
  final bool isCurrentTurn;
  final bool isThinking;

  const _AIPlayerSeat({
    required this.name,
    required this.cardCount,
    required this.isCurrentTurn,
    required this.isThinking,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PlayerAvatar(
              displayName: name,
              size: 40,
              isBot: true,
              isCurrentTurn: isCurrentTurn,
            ),
            if (isThinking)
              Positioned(
                bottom: -4, right: -4,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                    color: WildDeckTheme.navyDeep, shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: WildDeckTheme.gold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isThinking ? '${name}…' : name,
          style: TextStyle(
            color: isCurrentTurn ? WildDeckTheme.gold : WildDeckTheme.textMuted,
            fontSize: 10, fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: cardCount == 1
                ? WildDeckTheme.cardRed.withValues(alpha: 0.25)
                : WildDeckTheme.navyCard,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('$cardCount', style: TextStyle(
            color: cardCount == 1 ? WildDeckTheme.cardRed : Colors.white70,
            fontSize: 10, fontWeight: FontWeight.w700,
          )),
        ),
      ],
    );
  }
}

// ─── AI Game Table ────────────────────────────────────────────────────────────

class _AIGameTable extends StatelessWidget {
  final WildGameCard? topCard;
  final bool deckEmpty;
  final WildCardColor currentColor;
  final VoidCallback? onDraw;
  final int drawPileCount;
  final int drawPenalty;

  const _AIGameTable({
    required this.topCard,
    required this.deckEmpty,
    required this.currentColor,
    required this.onDraw,
    required this.drawPileCount,
    required this.drawPenalty,
  });

  Color get _colorValue => switch (currentColor) {
    WildCardColor.red    => WildDeckTheme.cardRed,
    WildCardColor.blue   => WildDeckTheme.cardBlue,
    WildCardColor.green  => WildDeckTheme.cardGreen,
    WildCardColor.yellow => WildDeckTheme.cardYellow,
    WildCardColor.wild   => WildDeckTheme.cardWild,
  };

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
                child: const WildDeckCardWidget(
                  color: WildCardColor.wild, type: WildCardType.wild, isFaceDown: true),
              ),
            if (drawPenalty > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: WildDeckTheme.cardRed, borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('+$drawPenalty', style: const TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                  )),
                ),
              ),
          ]),
        ),
      ),
      const SizedBox(width: 12),
      Container(width: 1, height: 70, color: WildDeckTheme.navyBorder),
      const SizedBox(width: 12),
      // Discard pile
      topCard != null
          ? WildDeckCardWidget(
              color: topCard!.color, type: topCard!.type, number: topCard!.number)
          : Container(
              width: 56, height: 80,
              decoration: BoxDecoration(
                color: WildDeckTheme.navySurface, borderRadius: WildDeckTheme.radiusMedium,
                border: Border.all(color: WildDeckTheme.navyBorder),
              ),
            ),
      const SizedBox(width: 12),
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: _colorValue, shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
          boxShadow: WildDeckTheme.buttonGlow(_colorValue),
        ),
      ),
    ]);
  }
}

// ─── AI Player Hand ───────────────────────────────────────────────────────────

class _AIPlayerHand extends StatelessWidget {
  final List<WildGameCard> hand;
  final bool isMyTurn;
  final int? selectedIndex;
  final bool Function(WildGameCard) canPlay;
  final Future<void> Function(int) onCardTap;

  const _AIPlayerHand({
    required this.hand,
    required this.isMyTurn,
    required this.selectedIndex,
    required this.canPlay,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) return const SizedBox(height: 100);
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hand.length,
        itemBuilder: (context, i) {
          final card = hand[i];
          final playable = isMyTurn && canPlay(card);
          final selected = selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: isMyTurn && !playable ? 0.4 : 1.0,
              child: WildDeckCardWidget(
                color: card.color,
                type: card.type,
                number: card.number,
                isSelected: selected,
                onTap: () => unawaited(onCardTap(i)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── AI Result Screen ─────────────────────────────────────────────────────────

class VsAIResultArgs {
  final String? winnerId;
  final String humanPlayerId;
  final VsAIGameArgs gameArgs;

  const VsAIResultArgs({
    required this.winnerId,
    required this.humanPlayerId,
    required this.gameArgs,
  });
}
