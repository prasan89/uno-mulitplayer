import 'dart:async';
import 'dart:math';
import 'package:wilddeck/core/services/wilddeck_services.dart';

// ─── AI Difficulty ────────────────────────────────────────────────────────────

enum AIDifficulty { easy, normal, hard }

// ─── AI Personality ───────────────────────────────────────────────────────────

class AIPersonality {
  final String name;
  final double aggression;
  final double riskTolerance;
  final double wildPreference;
  final double actionCardPreference;

  const AIPersonality({
    required this.name,
    required this.aggression,
    required this.riskTolerance,
    required this.wildPreference,
    required this.actionCardPreference,
  });
}

class AIPersonalities {
  static const rex = AIPersonality(
    name: 'Rex',
    aggression: 1.8,
    riskTolerance: 1.2,
    wildPreference: 0.7,
    actionCardPreference: 1.6,
  );
  static const nova = AIPersonality(
    name: 'Nova',
    aggression: 0.8,
    riskTolerance: 0.6,
    wildPreference: 0.5,
    actionCardPreference: 0.9,
  );
  static const milo = AIPersonality(
    name: 'Milo',
    aggression: 0.6,
    riskTolerance: 0.8,
    wildPreference: 1.2,
    actionCardPreference: 0.7,
  );
  static const blaze = AIPersonality(
    name: 'Blaze',
    aggression: 1.3,
    riskTolerance: 2.0,
    wildPreference: 1.8,
    actionCardPreference: 1.1,
  );

  static const List<AIPersonality> all = [rex, nova, milo, blaze];

  static AIPersonality atSeat(int seatIndex) =>
      all[seatIndex % all.length];
}

// ─── AI Player ────────────────────────────────────────────────────────────────

class AIPlayer {
  final String id;
  final String name;
  final AIDifficulty difficulty;
  final AIPersonality personality;

  const AIPlayer({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.personality,
  });
}

// ─── Think delay ranges ───────────────────────────────────────────────────────

(int, int) _thinkDelayRange(AIDifficulty d) {
  return switch (d) {
    AIDifficulty.easy   => (500, 1200),
    AIDifficulty.normal => (700, 1500),
    AIDifficulty.hard   => (900, 1800),
  };
}

// ─── Card helpers (mirrors Go engine logic) ──────────────────────────────────

bool _isWild(WildGameCard c) =>
    c.type == WildCardType.wild || c.type == WildCardType.wildDrawFour;

bool _isAction(WildGameCard c) => c.type != WildCardType.number;

bool _canPlay(WildGameCard card, WildGameCard? top, WildCardColor activeColor) {
  if (top == null) return true;
  if (_isWild(card)) return true;
  if (card.color == activeColor) return true;
  if (card.type == WildCardType.number &&
      top.type == WildCardType.number &&
      card.number != null &&
      card.number == top.number) return true;
  if (!_isWild(card) && card.type != WildCardType.number && card.type == top.type) {
    return true;
  }
  return false;
}

// ─── AI Decision Engine ───────────────────────────────────────────────────────

class AIDecisionEngine {
  final Random _rng;
  final AIDifficulty difficulty;
  final AIPersonality personality;

  AIDecisionEngine({
    required this.difficulty,
    required this.personality,
    Random? rng,
  }) : _rng = rng ?? Random();

  // Choose which card to play. Returns null to draw.
  WildGameCard? chooseCard({
    required List<WildGameCard> hand,
    required WildGameCard? topCard,
    required WildCardColor activeColor,
    required List<AILocalPlayer> players,
    required String myId,
  }) {
    final legal = hand.where((c) => _canPlay(c, topCard, activeColor)).toList();
    if (legal.isEmpty) return null;

    // Easy: 50% random, 50% smart
    if (difficulty == AIDifficulty.easy && _rng.nextBool()) {
      return legal[_rng.nextInt(legal.length)];
    }

    // Normal: 20% random
    if (difficulty == AIDifficulty.normal && _rng.nextInt(10) < 2) {
      return legal[_rng.nextInt(legal.length)];
    }

    // Hard / smart path
    final minOpponentCards = _minOpponentCards(players, myId);
    // Apply personality modifiers
    final aggressionBoost = personality.aggression > 1.2;
    final wildBoost = personality.wildPreference > 1.2;

    // Priority 1: action cards when opponent is close to winning
    if (minOpponentCards <= 3 || aggressionBoost) {
      final draw = legal.where((c) =>
          c.type == WildCardType.drawTwo ||
          c.type == WildCardType.wildDrawFour).toList();
      if (draw.isNotEmpty) return draw.first;

      if (minOpponentCards <= 3) {
        final action = legal.where((c) => _isAction(c) && !_isWild(c)).toList();
        if (action.isNotEmpty) return action.first;
      }
    }

    // Priority 2: matching-color number card (preserve action/wilds)
    if (!wildBoost) {
      final numMatch = legal.where((c) =>
          c.type == WildCardType.number && c.color == activeColor).toList();
      if (numMatch.isNotEmpty) return numMatch.first;
    }

    // Priority 3: any colored action card
    final actionColored = legal.where((c) => _isAction(c) && !_isWild(c)).toList();
    if (actionColored.isNotEmpty) return actionColored.first;

    // Priority 4: any number card
    final numbers = legal.where((c) => c.type == WildCardType.number).toList();
    if (numbers.isNotEmpty) return numbers.first;

    // Priority 5: wilds (prefer plain wild over draw-four unless blazy personality)
    if (personality.riskTolerance < 1.5) {
      final plain = legal.where((c) => c.type == WildCardType.wild).toList();
      if (plain.isNotEmpty) return plain.first;
    }

    return legal.first;
  }

  // Choose color when playing a wild card.
  WildCardColor chooseColor(List<WildGameCard> remainingHand) {
    final counts = <WildCardColor, int>{};
    for (final c in remainingHand) {
      if (c.color != WildCardColor.wild) {
        counts[c.color] = (counts[c.color] ?? 0) + 1;
      }
    }

    // Easy: 50% random color
    if (difficulty == AIDifficulty.easy && _rng.nextBool()) {
      const colors = [
        WildCardColor.red, WildCardColor.blue,
        WildCardColor.green, WildCardColor.yellow,
      ];
      return colors[_rng.nextInt(colors.length)];
    }

    if (counts.isEmpty) {
      const colors = [
        WildCardColor.red, WildCardColor.blue,
        WildCardColor.green, WildCardColor.yellow,
      ];
      return colors[_rng.nextInt(colors.length)];
    }

    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  // Should the AI call Last Card?
  bool shouldCallLastCard(List<WildGameCard> hand) => hand.length == 2;

  int _minOpponentCards(List<AILocalPlayer> players, String myId) {
    int min = 99;
    for (final p in players) {
      if (p.id != myId && p.hand.length < min) {
        min = p.hand.length;
      }
    }
    return min;
  }
}

// ─── Local in-memory player model ────────────────────────────────────────────

class AILocalPlayer {
  final String id;
  final String name;
  final bool isBot;
  final bool isHuman;
  List<WildGameCard> hand;
  bool calledLastCard;

  AILocalPlayer({
    required this.id,
    required this.name,
    required this.isBot,
    required this.isHuman,
    required this.hand,
    this.calledLastCard = false,
  });
}

// ─── Local deck ──────────────────────────────────────────────────────────────

class _LocalDeck {
  final List<WildGameCard> _draw;
  List<WildGameCard> _discard;
  int _idCounter = 0;

  _LocalDeck()
      : _draw = [],
        _discard = [] {
    _build();
    _shuffle(_draw);
  }

  String _nextId() => 'ld_${++_idCounter}';

  void _build() {
    const colors = [WildCardColor.red, WildCardColor.blue, WildCardColor.green, WildCardColor.yellow];
    for (final color in colors) {
      _draw.add(WildGameCard(id: _nextId(), color: color, type: WildCardType.number, number: 0));
      for (int n = 1; n <= 9; n++) {
        for (int k = 0; k < 2; k++) {
          _draw.add(WildGameCard(id: _nextId(), color: color, type: WildCardType.number, number: n));
        }
      }
      for (int k = 0; k < 2; k++) {
        _draw.add(WildGameCard(id: _nextId(), color: color, type: WildCardType.skip));
        _draw.add(WildGameCard(id: _nextId(), color: color, type: WildCardType.reverse));
        _draw.add(WildGameCard(id: _nextId(), color: color, type: WildCardType.drawTwo));
      }
    }
    for (int k = 0; k < 4; k++) {
      _draw.add(WildGameCard(id: _nextId(), color: WildCardColor.wild, type: WildCardType.wild));
      _draw.add(WildGameCard(id: _nextId(), color: WildCardColor.wild, type: WildCardType.wildDrawFour));
    }
  }

  void _shuffle(List<WildGameCard> list) {
    final rng = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = list[i]; list[i] = list[j]; list[j] = tmp;
    }
  }

  WildGameCard? draw() {
    if (_draw.isEmpty) _reshuffle();
    if (_draw.isEmpty) return null;
    final card = _draw.removeAt(0);
    return card;
  }

  void discard(WildGameCard card) => _discard.add(card);

  void _reshuffle() {
    if (_discard.length <= 1) return;
    final top = _discard.removeLast();
    _shuffle(_discard);
    _draw.addAll(_discard);
    _discard = [top];
  }

  WildGameCard? get topDiscard => _discard.isEmpty ? null : _discard.last;
  int get drawCount => _draw.length;
  int get discardCount => _discard.length;
}

// ─── VS AI Game State ─────────────────────────────────────────────────────────

enum AIGamePhase { waiting, playing, lastCard, finished }
enum TurnDirection { clockwise, counterClockwise }

class AIGameState {
  final String gameId;
  final AIGamePhase phase;
  final List<AILocalPlayer> players;
  final int currentPlayerIndex;
  final TurnDirection direction;
  final WildGameCard? topCard;
  final WildCardColor activeColor;
  final int drawPileCount;
  final int discardCount;
  final int drawPenalty;
  final String? winnerId;
  final bool isMyTurn;
  final String humanPlayerId;
  final bool aiThinking;
  final String? thinkingBotName;

  const AIGameState({
    required this.gameId,
    required this.phase,
    required this.players,
    required this.currentPlayerIndex,
    required this.direction,
    required this.topCard,
    required this.activeColor,
    required this.drawPileCount,
    required this.discardCount,
    required this.drawPenalty,
    required this.humanPlayerId,
    this.winnerId,
    this.isMyTurn = false,
    this.aiThinking = false,
    this.thinkingBotName,
  });

  AILocalPlayer get currentPlayer => players[currentPlayerIndex];
  bool get isFinished => phase == AIGamePhase.finished;
}

// ─── AI Game Service ──────────────────────────────────────────────────────────

class AIGameService {
  final String _humanPlayerId;
  final String _humanName;
  final List<AIPlayer> _bots;

  final StreamController<AIGameState> _stateController =
      StreamController<AIGameState>.broadcast();

  Stream<AIGameState> get stateStream => _stateController.stream;

  late _LocalDeck _deck;
  late List<AILocalPlayer> _players;
  int _currentPlayerIndex = 0;
  TurnDirection _direction = TurnDirection.clockwise;
  int _drawPenalty = 0;
  String? _winnerId;
  AIGamePhase _phase = AIGamePhase.waiting;
  bool _aiThinking = false;
  String? _thinkingBotName;
  final String _gameId;

  final Map<String, AIDecisionEngine> _engines = {};

  AIGameService({
    required String humanPlayerId,
    required String humanName,
    required List<AIPlayer> bots,
  })  : _humanPlayerId = humanPlayerId,
        _humanName = humanName,
        _bots = bots,
        _gameId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

  void startGame() {
    _deck = _LocalDeck();
    _players = [];

    // Human is always seat 0
    _players.add(AILocalPlayer(
      id: _humanPlayerId,
      name: _humanName,
      isBot: false,
      isHuman: true,
      hand: [],
    ));

    for (final bot in _bots) {
      _players.add(AILocalPlayer(
        id: bot.id,
        name: bot.name,
        isBot: true,
        isHuman: false,
        hand: [],
      ));
      _engines[bot.id] = AIDecisionEngine(
        difficulty: bot.difficulty,
        personality: bot.personality,
      );
    }

    // Deal 7 cards each
    for (int round = 0; round < 7; round++) {
      for (final p in _players) {
        final card = _deck.draw();
        if (card != null) p.hand.add(card);
      }
    }

    // Flip first non-WD4 card
    WildGameCard? startCard;
    for (;;) {
      startCard = _deck.draw();
      if (startCard == null) break;
      if (startCard.type != WildCardType.wildDrawFour) {
        _deck.discard(startCard);
        break;
      }
      // Put WD4 back by drawing another and re-inserting
      // (simplified: just draw next)
    }

    _currentPlayerIndex = 0;
    _direction = TurnDirection.clockwise;
    _drawPenalty = 0;
    _winnerId = null;
    _phase = AIGamePhase.playing;
    _aiThinking = false;

    // Handle start card effects
    if (startCard != null) {
      _applyStartCardEffect(startCard);
    }

    _emit();
    _scheduleAIIfNeeded();
  }

  void _applyStartCardEffect(WildGameCard card) {
    switch (card.type) {
      case WildCardType.skip:
        _advanceTurn();
      case WildCardType.reverse:
        if (_players.length == 2) {
          _advanceTurn();
        } else {
          _direction = TurnDirection.counterClockwise;
        }
      case WildCardType.drawTwo:
        _drawPenalty += 2;
      default:
        break;
    }
  }

  // Human plays a card
  String? playCard(String cardId, {WildCardColor? chosenColor}) {
    if (_phase != AIGamePhase.playing) return 'Game is not active';
    if (_players[_currentPlayerIndex].id != _humanPlayerId) return 'Not your turn';

    final player = _players[_currentPlayerIndex];
    final cardIdx = player.hand.indexWhere((c) => c.id == cardId);
    if (cardIdx < 0) return 'Card not in hand';

    final card = player.hand[cardIdx];
    final top = _deck.topDiscard;
    final activeColor = _currentActiveColor();

    if (!_canPlay(card, top, activeColor)) return 'Invalid card play';

    // Validate color for wilds
    if (_isWild(card)) {
      if (chosenColor == null || chosenColor == WildCardColor.wild) {
        return 'Must choose a color for wild card';
      }
    }

    player.hand.removeAt(cardIdx);
    player.calledLastCard = false;
    _deck.discard(card);
    _applyPlayedCard(card, chosenColor ?? activeColor, player);
    _emit();
    _scheduleAIIfNeeded();
    return null;
  }

  // Human draws a card
  String? drawCard() {
    if (_phase != AIGamePhase.playing) return 'Game is not active';
    if (_players[_currentPlayerIndex].id != _humanPlayerId) return 'Not your turn';

    _performDraw(_players[_currentPlayerIndex]);
    _advanceTurn();
    _emit();
    _scheduleAIIfNeeded();
    return null;
  }

  // Human calls last card
  String? callLastCard() {
    if (_phase != AIGamePhase.playing) return 'Game is not active';
    final player = _players.firstWhere((p) => p.id == _humanPlayerId,
        orElse: () => _players[0]);
    if (player.hand.length != 1) return 'Can only call Last Card with exactly 1 card';
    player.calledLastCard = true;
    _emit();
    return null;
  }

  void _performDraw(AILocalPlayer player) {
    int count = _drawPenalty > 0 ? _drawPenalty : 1;
    _drawPenalty = 0;
    for (int i = 0; i < count; i++) {
      final card = _deck.draw();
      if (card != null) player.hand.add(card);
    }
    player.calledLastCard = false;
  }

  void _applyPlayedCard(WildGameCard card, WildCardColor chosenColor, AILocalPlayer player) {
    // Check win
    if (player.hand.isEmpty) {
      _phase = AIGamePhase.finished;
      _winnerId = player.id;
      return;
    }

    // Last card penalty: dropped to 1 without calling last card
    if (player.hand.length == 1 && !player.calledLastCard) {
      for (int i = 0; i < 2; i++) {
        final c = _deck.draw();
        if (c != null) player.hand.add(c);
      }
    }

    // Apply card effects and advance
    switch (card.type) {
      case WildCardType.skip:
        _advanceTurn();
        _advanceTurn();
      case WildCardType.reverse:
        if (_players.length == 2) {
          _advanceTurn();
          _advanceTurn();
        } else {
          _direction = _direction == TurnDirection.clockwise
              ? TurnDirection.counterClockwise
              : TurnDirection.clockwise;
          _advanceTurn();
        }
      case WildCardType.drawTwo:
        _advanceTurn();
        // Next player draws 2 immediately
        _performDraw(_players[_currentPlayerIndex]);
        _advanceTurn();
      case WildCardType.wildDrawFour:
        _drawPenalty = 4;
        _advanceTurn();
      default:
        _advanceTurn();
    }
  }

  void _advanceTurn() {
    final n = _players.length;
    final step = _direction == TurnDirection.clockwise ? 1 : -1;
    _currentPlayerIndex = ((_currentPlayerIndex + step) % n + n) % n;
  }

  WildCardColor _currentActiveColor() {
    final top = _deck.topDiscard;
    if (top == null) return WildCardColor.red;
    if (_isWild(top)) {
      // For wilds the color was set at play time; we track it via last-known color
      // by scanning discard pile. For simplicity: store it separately.
      return _lastDeclaredColor ?? WildCardColor.red;
    }
    return top.color;
  }

  WildCardColor? _lastDeclaredColor;

  String? playCardWithColor(String cardId, WildCardColor color) {
    _lastDeclaredColor = color;
    return playCard(cardId, chosenColor: color);
  }

  void _scheduleAIIfNeeded() {
    if (_phase != AIGamePhase.playing) return;
    final current = _players[_currentPlayerIndex];
    if (!current.isBot) return;

    final engine = _engines[current.id];
    if (engine == null) return;

    final (minMs, maxMs) = _thinkDelayRange(engine.difficulty);
    final delay = minMs + Random().nextInt(maxMs - minMs + 1);

    _aiThinking = true;
    _thinkingBotName = current.name;
    _emit();

    Future<void>.delayed(Duration(milliseconds: delay), () {
      if (_phase != AIGamePhase.playing) return;
      // Re-check it's still this bot's turn
      if (_players[_currentPlayerIndex].id != current.id) return;
      _executeAITurn(current, engine);
    });
  }

  void _executeAITurn(AILocalPlayer player, AIDecisionEngine engine) {
    final top = _deck.topDiscard;
    final activeColor = _currentActiveColor();

    // Handle draw penalty
    if (_drawPenalty > 0) {
      _performDraw(player);
      _advanceTurn();
      _aiThinking = false;
      _thinkingBotName = null;
      _emit();
      _scheduleAIIfNeeded();
      return;
    }

    final chosen = engine.chooseCard(
      hand: player.hand,
      topCard: top,
      activeColor: activeColor,
      players: _players,
      myId: player.id,
    );

    if (chosen == null) {
      // Draw
      _performDraw(player);
      _advanceTurn();
    } else {
      // Should call last card?
      if (engine.shouldCallLastCard(player.hand)) {
        player.calledLastCard = true;
      }

      WildCardColor color = activeColor;
      if (_isWild(chosen)) {
        final remaining = List<WildGameCard>.from(player.hand)
          ..removeWhere((c) => c.id == chosen.id);
        color = engine.chooseColor(remaining);
        _lastDeclaredColor = color;
      }

      player.hand.removeWhere((c) => c.id == chosen.id);
      player.calledLastCard = false;
      _deck.discard(chosen);
      _applyPlayedCard(chosen, color, player);
    }

    _aiThinking = false;
    _thinkingBotName = null;
    _emit();
    _scheduleAIIfNeeded();
  }

  void _emit() {
    if (_stateController.isClosed) return;
    final activeColor = _deck.topDiscard == null
        ? WildCardColor.red
        : (_isWild(_deck.topDiscard!) ? (_lastDeclaredColor ?? WildCardColor.red) : _deck.topDiscard!.color);

    final state = AIGameState(
      gameId: _gameId,
      phase: _phase,
      players: List.unmodifiable(_players),
      currentPlayerIndex: _currentPlayerIndex,
      direction: _direction,
      topCard: _deck.topDiscard,
      activeColor: activeColor,
      drawPileCount: _deck.drawCount,
      discardCount: _deck.discardCount,
      drawPenalty: _drawPenalty,
      humanPlayerId: _humanPlayerId,
      winnerId: _winnerId,
      isMyTurn: _players[_currentPlayerIndex].id == _humanPlayerId &&
          _phase == AIGamePhase.playing,
      aiThinking: _aiThinking,
      thinkingBotName: _thinkingBotName,
    );

    _stateController.add(state);
  }

  // Start a fresh game with the same players (Play Again)
  void restartGame() {
    _engines.clear();
    for (final bot in _bots) {
      _engines[bot.id] = AIDecisionEngine(
        difficulty: bot.difficulty,
        personality: bot.personality,
      );
    }
    startGame();
  }

  void dispose() {
    _stateController.close();
  }
}
