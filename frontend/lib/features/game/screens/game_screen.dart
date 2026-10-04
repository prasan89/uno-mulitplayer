import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';
import '../widgets/game_board.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/game_over_dialog.dart';

/// Represents the current state of the game.
/// In production this would be driven by Riverpod/a WebSocket provider.
class GameState {
  final String gameId;
  final List<WildCard> myHand;
  final WildCard? discardTopCard;
  final int discardCount;
  final int drawPileCount;
  final bool isMyTurn;
  final bool canDraw;
  final List<OpponentPlayer> opponents;
  final Duration? turnTimeRemaining;
  final String? winnerName;
  final List<PlayerScore> finalScores;

  const GameState({
    required this.gameId,
    required this.myHand,
    this.discardTopCard,
    this.discardCount = 0,
    this.drawPileCount = 108,
    this.isMyTurn = false,
    this.canDraw = false,
    required this.opponents,
    this.turnTimeRemaining,
    this.winnerName,
    this.finalScores = const [],
  });

  bool get isGameOver => winnerName != null;
}

class GameScreen extends StatefulWidget {
  final String gameId;

  /// Provide an initial state for testing / previewing. If null the screen
  /// bootstraps an internal demo state.
  final GameState? initialState;

  const GameScreen({
    super.key,
    required this.gameId,
    this.initialState,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _gameState;
  String? _selectedCardId;
  Timer? _turnTimer;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _gameState = widget.initialState ?? _buildDemoState();
    if (_gameState.isMyTurn && _gameState.turnTimeRemaining != null) {
      _startTurnTimer(_gameState.turnTimeRemaining!);
    }
  }

  @override
  void dispose() {
    _turnTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Demo / stub state
  // ---------------------------------------------------------------------------

  GameState _buildDemoState() {
    return GameState(
      gameId: widget.gameId,
      myHand: [
        const WildCard(color: CardColor.red, value: CardValue.five, id: 'c1'),
        const WildCard(color: CardColor.blue, value: CardValue.skip, id: 'c2'),
        const WildCard(color: CardColor.green, value: CardValue.two, id: 'c3'),
        const WildCard(color: CardColor.yellow, value: CardValue.drawTwo, id: 'c4'),
        const WildCard(color: CardColor.wild, value: CardValue.wild, id: 'c5'),
        const WildCard(color: CardColor.red, value: CardValue.reverse, id: 'c6'),
        const WildCard(color: CardColor.blue, value: CardValue.nine, id: 'c7'),
      ],
      discardTopCard: const WildCard(
          color: CardColor.red, value: CardValue.four, id: 'top'),
      discardCount: 14,
      drawPileCount: 52,
      isMyTurn: true,
      canDraw: true,
      opponents: const [
        OpponentPlayer(id: 'p2', name: 'Alice', cardCount: 3),
        OpponentPlayer(id: 'p3', name: 'Bob', cardCount: 7, isCurrentTurn: false),
        OpponentPlayer(id: 'p4', name: 'Charlie', cardCount: 2),
      ],
      turnTimeRemaining: const Duration(seconds: 30),
    );
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTurnTimer(Duration initial) {
    _turnTimer?.cancel();
    Duration remaining = initial;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        remaining = remaining - const Duration(seconds: 1);
        _gameState = _withTurnTime(remaining);
        if (remaining.inSeconds <= 0) {
          timer.cancel();
          _handleDrawCard(); // auto-draw on timeout
        }
      });
    });
  }

  GameState _withTurnTime(Duration remaining) {
    return GameState(
      gameId: _gameState.gameId,
      myHand: _gameState.myHand,
      discardTopCard: _gameState.discardTopCard,
      discardCount: _gameState.discardCount,
      drawPileCount: _gameState.drawPileCount,
      isMyTurn: _gameState.isMyTurn,
      canDraw: _gameState.canDraw,
      opponents: _gameState.opponents,
      turnTimeRemaining: remaining,
      winnerName: _gameState.winnerName,
      finalScores: _gameState.finalScores,
    );
  }

  // ---------------------------------------------------------------------------
  // Computed helpers
  // ---------------------------------------------------------------------------

  Set<String> get _playableCardIds {
    final top = _gameState.discardTopCard;
    if (top == null) return _gameState.myHand.map((c) => c.id).toSet();
    return _gameState.myHand
        .where((card) =>
            card.isWild ||
            card.color == top.color ||
            card.value == top.value)
        .map((c) => c.id)
        .toSet();
  }

  bool get _showLastCardButton => _gameState.myHand.length == 1;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _handleCardSelected(WildCard card) {
    setState(() {
      _selectedCardId = _selectedCardId == card.id ? null : card.id;
    });
  }

  Future<void> _handleCardPlayed(WildCard card) async {
    CardColor? chosenColor;
    if (card.isWild) {
      chosenColor = await ColorPickerDialog.show(context);
      if (chosenColor == null) return; // user dismissed
    }

    // TODO: send play_card event via WebSocket provider
    setState(() {
      _selectedCardId = null;
      final newHand = _gameState.myHand.where((c) => c.id != card.id).toList();
      _gameState = GameState(
        gameId: _gameState.gameId,
        myHand: newHand,
        discardTopCard: card,
        discardCount: _gameState.discardCount + 1,
        drawPileCount: _gameState.drawPileCount,
        isMyTurn: false,
        canDraw: false,
        opponents: _gameState.opponents,
        turnTimeRemaining: null,
        winnerName: newHand.isEmpty ? 'You' : _gameState.winnerName,
        finalScores: _gameState.finalScores,
      );
    });
    _turnTimer?.cancel();
  }

  void _handleDrawCard() {
    if (!_gameState.isMyTurn || !_gameState.canDraw) return;
    // TODO: send draw_card event via WebSocket provider
    setState(() {
      _gameState = GameState(
        gameId: _gameState.gameId,
        myHand: [
          ..._gameState.myHand,
          WildCard(
            color: CardColor.values[
                DateTime.now().millisecond % (CardColor.values.length - 1)],
            value: CardValue.values[
                DateTime.now().second % CardValue.values.length],
            id: 'drawn_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ],
        discardTopCard: _gameState.discardTopCard,
        discardCount: _gameState.discardCount,
        drawPileCount: _gameState.drawPileCount - 1,
        isMyTurn: false,
        canDraw: false,
        opponents: _gameState.opponents,
        turnTimeRemaining: null,
        winnerName: _gameState.winnerName,
        finalScores: _gameState.finalScores,
      );
    });
    _turnTimer?.cancel();
  }

  void _handleCallLastCard() {
    // TODO: send call_last_card event via WebSocket provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('LAST CARD!',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFE53935),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<CardColor?> _handleColorPick() {
    return ColorPickerDialog.show(context);
  }

  Future<void> _showGameOver() async {
    if (_gameState.winnerName == null) return;
    await GameOverDialog.show(
      context: context,
      winnerName: _gameState.winnerName!,
      playerScores: _gameState.finalScores.isNotEmpty
          ? _gameState.finalScores
          : [
              const PlayerScore(
                name: 'You',
                score: 0,
                eloChange: 15,
                isCurrentPlayer: true,
              ),
              const PlayerScore(
                name: 'Alice',
                score: 120,
                eloChange: -8,
              ),
            ],
      onPlayAgain: () {
        Navigator.pop(context);
        // TODO: navigate to matchmaking
      },
      onBackToLobby: () {
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Show game over dialog after the frame builds
    if (_gameState.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showGameOver());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: GameBoard(
          gameId: _gameState.gameId,
          turnTimeRemaining: _gameState.turnTimeRemaining,
          opponents: _gameState.opponents,
          myHand: _gameState.myHand,
          playableCardIds: _playableCardIds,
          selectedCardId: _selectedCardId,
          discardTopCard: _gameState.discardTopCard,
          discardCount: _gameState.discardCount,
          drawPileCount: _gameState.drawPileCount,
          isMyTurn: _gameState.isMyTurn,
          canDraw: _gameState.canDraw,
          showLastCardButton: _showLastCardButton,
          onCardSelected: _handleCardSelected,
          onCardPlayed: _handleCardPlayed,
          onDrawCard: _handleDrawCard,
          onCallLastCard: _handleCallLastCard,
          onColorPick: _handleColorPick,
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
        onPressed: () => _confirmLeave(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game #${_gameState.gameId.length > 8 ? _gameState.gameId.substring(0, 8) : _gameState.gameId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_gameState.opponents.length + 1} players',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        if (_gameState.turnTimeRemaining != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _TurnTimerChip(remaining: _gameState.turnTimeRemaining!),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white70),
          onPressed: () => _showGameMenu(context),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Leave Game?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will forfeit this game if you leave now.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  void _showGameMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.white70),
              title: const Text('Forfeit Game',
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context);
                _confirmLeave(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.volume_off, color: Colors.white70),
              title: const Text('Mute Sounds',
                  style: TextStyle(color: Colors.white70)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnTimerChip extends StatelessWidget {
  final Duration remaining;

  const _TurnTimerChip({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inSeconds;
    final isUrgent = seconds <= 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFE53935).withOpacity(0.15)
            : Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? const Color(0xFFE53935) : Colors.white24,
        ),
      ),
      child: Text(
        '${seconds}s',
        style: TextStyle(
          color: isUrgent ? const Color(0xFFE53935) : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
