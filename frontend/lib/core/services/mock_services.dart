import 'dart:async';
import 'wilddeck_services.dart';

// ─── Mock Player Service ──────────────────────────────────────────────────────

class MockPlayerService implements IPlayerService {
  WildDeckPlayer? _current;

  @override
  Future<WildDeckPlayer?> getCurrentPlayer() async => _current;

  @override
  Future<WildDeckPlayer> signInAsGuest(String displayName) async {
    _current = WildDeckPlayer(
      id: 'guest_001',
      displayName: displayName,
      level: 1,
      xp: 150,
      xpToNextLevel: 1000,
      coins: 500,
      gems: 10,
      isGuest: true,
    );
    return _current!;
  }

  @override
  Future<WildDeckPlayer> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _current = WildDeckPlayer(
      id: 'user_001',
      displayName: email.split('@').first,
      level: 7,
      xp: 630,
      xpToNextLevel: 1000,
      coins: 2400,
      gems: 45,
      wins: 42,
      losses: 18,
    );
    return _current!;
  }

  @override
  Future<WildDeckPlayer> register(String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _current = WildDeckPlayer(
      id: 'user_new',
      displayName: displayName,
      level: 1,
      xp: 0,
      coins: 500,
      gems: 10,
    );
    return _current!;
  }

  @override
  Future<void> signOut() async => _current = null;

  @override
  Future<void> updateProfile({String? displayName, String? avatarId}) async {
    if (_current == null) return;
    _current = WildDeckPlayer(
      id: _current!.id,
      displayName: displayName ?? _current!.displayName,
      avatarId: avatarId ?? _current!.avatarId,
      level: _current!.level,
      xp: _current!.xp,
      xpToNextLevel: _current!.xpToNextLevel,
      coins: _current!.coins,
      gems: _current!.gems,
      wins: _current!.wins,
      losses: _current!.losses,
    );
  }
}

// ─── Mock Matchmaking Service ─────────────────────────────────────────────────

class MockMatchmakingService implements IMatchmakingService {
  final StreamController<MatchmakingState> _controller = StreamController.broadcast();
  Timer? _simulationTimer;
  bool _cancelled = false;

  static const _mockNames = ['Blaze', 'ShadowKing', 'NeonRider', 'WildAce', 'FrostQueen'];

  @override
  Stream<MatchmakingState> searchForMatch({
    required String gameMode,
    required int maxPlayers,
    required bool fillWithBots,
  }) {
    _cancelled = false;
    int elapsed = 0;

    // Seed with current player
    final slots = List<MatchmakingSlot>.generate(
      maxPlayers,
      (i) => i == 0
          ? const MatchmakingSlot(index: 0, isOccupied: true, isCurrentPlayer: true, playerName: 'You')
          : MatchmakingSlot.empty(i),
    );

    var state = MatchmakingState(
      status: MatchmakingStatus.searching,
      slots: slots,
    );
    _controller.add(state);

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cancelled) { timer.cancel(); return; }
      elapsed++;

      final updatedSlots = List<MatchmakingSlot>.from(state.slots);
      // Add a simulated player every 2–3 seconds
      if (elapsed % 2 == 0 || elapsed % 3 == 0) {
        final emptyIdx = updatedSlots.indexWhere((s) => !s.isOccupied && !s.isCurrentPlayer);
        if (emptyIdx != -1) {
          final isBot = elapsed > 8 && fillWithBots;
          updatedSlots[emptyIdx] = MatchmakingSlot(
            index: emptyIdx,
            isOccupied: true,
            playerName: isBot ? 'Bot ${emptyIdx + 1}' : _mockNames[emptyIdx % _mockNames.length],
            isBot: isBot,
          );
        }
      }

      final isFull = updatedSlots.every((s) => s.isOccupied);
      state = MatchmakingState(
        status: isFull ? MatchmakingStatus.found : MatchmakingStatus.searching,
        slots: updatedSlots,
        elapsedSeconds: elapsed,
        matchId: isFull ? 'mock_game_${DateTime.now().millisecondsSinceEpoch}' : null,
      );
      _controller.add(state);
      if (isFull) timer.cancel();
    });

    return _controller.stream;
  }

  @override
  Future<void> cancelSearch() async {
    _cancelled = true;
    _simulationTimer?.cancel();
    _controller.add(const MatchmakingState(
      status: MatchmakingStatus.cancelled,
      slots: [],
    ));
  }

  @override
  Future<String> createPrivateRoom() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'W7D9K2';
  }

  @override
  Future<void> joinPrivateRoom(String roomCode) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void dispose() {
    _simulationTimer?.cancel();
    _controller.close();
  }
}

// ─── Mock Wallet Service ──────────────────────────────────────────────────────

class MockWalletService implements IWalletService {
  @override
  Future<WalletBalance> getBalance() async =>
      const WalletBalance(coins: 2400, gems: 45);

  @override
  Future<void> purchaseProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // No-op for M1
  }

  @override
  Future<List<ShopItem>> getCatalog(ShopCategory category) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCatalog.where((item) => item.category == category).toList();
  }

  static const _mockCatalog = [
    ShopItem(id: 'deck_fire',    name: 'Fire Deck',    description: 'Blazing hot card design',  coinPrice: 1200, category: ShopCategory.cards,   isFeatured: true),
    ShopItem(id: 'deck_ocean',   name: 'Ocean Deck',   description: 'Deep sea card design',     coinPrice: 1200, category: ShopCategory.cards),
    ShopItem(id: 'deck_neon',    name: 'Neon Deck',    description: 'Electric neon style',      gemPrice: 20,    category: ShopCategory.cards,   isFeatured: true),
    ShopItem(id: 'deck_galaxy',  name: 'Galaxy Deck',  description: 'Stellar space design',     gemPrice: 30,    category: ShopCategory.cards),
    ShopItem(id: 'deck_crystal', name: 'Crystal Deck', description: 'Ice-cold shimmer',         coinPrice: 800,  category: ShopCategory.cards),
    ShopItem(id: 'av_phoenix',   name: 'Phoenix',      description: 'Rise from the flames',     coinPrice: 600,  category: ShopCategory.avatars),
    ShopItem(id: 'av_wolf',      name: 'Wild Wolf',    description: 'Run with the pack',        coinPrice: 600,  category: ShopCategory.avatars),
    ShopItem(id: 'av_dragon',    name: 'Dragon',       description: 'Legendary creature',       gemPrice: 15,    category: ShopCategory.avatars),
    ShopItem(id: 'tb_jade',      name: 'Jade Table',   description: 'Emerald green felt',       coinPrice: 400,  category: ShopCategory.tables),
    ShopItem(id: 'tb_obsidian',  name: 'Obsidian',     description: 'Dark luxury table',        gemPrice: 10,    category: ShopCategory.tables),
    ShopItem(id: 'em_fire',      name: 'Fire 🔥',       description: 'Show your heat',           coinPrice: 200,  category: ShopCategory.emotes),
    ShopItem(id: 'em_crown',     name: 'Crown 👑',      description: 'All hail the king',        coinPrice: 200,  category: ShopCategory.emotes),
  ];
}

// ─── Mock data helpers ────────────────────────────────────────────────────────

class MockData {
  static WildDeckPlayer get currentPlayer => const WildDeckPlayer(
    id: 'player_001',
    displayName: 'WildAce',
    level: 7,
    xp: 630,
    xpToNextLevel: 1000,
    coins: 2400,
    gems: 45,
    wins: 42,
    losses: 18,
  );

  static List<WildDeckPlayer> get leaderboardPlayers => const [
    WildDeckPlayer(id: 'p1', displayName: 'NeonStrike',   level: 25, wins: 312, losses: 88,  coins: 0, gems: 0),
    WildDeckPlayer(id: 'p2', displayName: 'BlazeMaster',  level: 22, wins: 278, losses: 94,  coins: 0, gems: 0),
    WildDeckPlayer(id: 'p3', displayName: 'FrostQueen',   level: 21, wins: 251, losses: 107, coins: 0, gems: 0),
    WildDeckPlayer(id: 'p4', displayName: 'ShadowKing',   level: 19, wins: 199, losses: 101, coins: 0, gems: 0),
    WildDeckPlayer(id: 'p5', displayName: 'AceRider',     level: 18, wins: 183, losses: 119, coins: 0, gems: 0),
    WildDeckPlayer(id: 'p6', displayName: 'WildAce',      level: 7,  wins: 42,  losses: 18,  coins: 0, gems: 0),
    WildDeckPlayer(id: 'p7', displayName: 'CardShark',    level: 6,  wins: 38,  losses: 22,  coins: 0, gems: 0),
    WildDeckPlayer(id: 'p8', displayName: 'QuickDraw',    level: 5,  wins: 29,  losses: 31,  coins: 0, gems: 0),
  ];

  static List<WildGamePlayer> get mockGamePlayers => const [
    WildGamePlayer(id: 'p1', displayName: 'Blaze',      cardCount: 3, isCurrentTurn: false),
    WildGamePlayer(id: 'p2', displayName: 'ShadowKing', cardCount: 7),
    WildGamePlayer(id: 'p3', displayName: 'FrostBot',   cardCount: 2, isBot: true),
  ];

  static List<WildGameCard> get mockHand => [
    const WildGameCard(id: 'c1', color: WildCardColor.red,    type: WildCardType.number, number: 5),
    const WildGameCard(id: 'c2', color: WildCardColor.blue,   type: WildCardType.skip),
    const WildGameCard(id: 'c3', color: WildCardColor.green,  type: WildCardType.number, number: 2),
    const WildGameCard(id: 'c4', color: WildCardColor.yellow, type: WildCardType.drawTwo),
    const WildGameCard(id: 'c5', color: WildCardColor.wild,   type: WildCardType.wild),
    const WildGameCard(id: 'c6', color: WildCardColor.red,    type: WildCardType.reverse),
    const WildGameCard(id: 'c7', color: WildCardColor.blue,   type: WildCardType.number, number: 9),
  ];

  static WildGameState buildMockGameState(String gameId) => WildGameState(
    gameId: gameId,
    phase: GamePhase.active,
    mode: GameMode.classic,
    currentPlayerId: 'me',
    players: mockGamePlayers,
    myHand: mockHand,
    topCard: const WildGameCard(id: 'top', color: WildCardColor.red, type: WildCardType.number, number: 4),
    activeColor: WildCardColor.red,
    drawPileCount: 52,
    discardCount: 14,
    isMyTurn: true,
  );

  static List<MissionData> get dailyMissions => [
    const MissionData(id: 'm1', title: 'Play 3 Games',        description: 'Complete 3 matches',     progress: 1, goal: 3, coinReward: 100, xpReward: 50,  type: MissionType.daily),
    const MissionData(id: 'm2', title: 'Win 1 Game',          description: 'Win any match',          progress: 0, goal: 1, coinReward: 150, xpReward: 75,  type: MissionType.daily),
    const MissionData(id: 'm3', title: 'Play 5 Wild Cards',   description: 'Use 5 wild/+4 cards',    progress: 3, goal: 5, coinReward: 80,  xpReward: 40,  type: MissionType.daily),
    const MissionData(id: 'm4', title: 'Call Last Card',      description: 'Announce last card',     progress: 0, goal: 1, coinReward: 50,  xpReward: 25,  type: MissionType.daily),
  ];

  static List<MissionData> get weeklyMissions => [
    const MissionData(id: 'w1', title: 'Win 10 Games',        description: 'Claim 10 victories',     progress: 4,  goal: 10, coinReward: 500, xpReward: 250, type: MissionType.weekly),
    const MissionData(id: 'w2', title: 'Play 25 Special',     description: 'Special cards played',   progress: 11, goal: 25, coinReward: 400, xpReward: 200, type: MissionType.weekly),
    const MissionData(id: 'w3', title: 'Win Streak x3',       description: '3 wins in a row',        progress: 1,  goal: 3,  coinReward: 600, xpReward: 300, type: MissionType.weekly),
  ];

  static List<MissionData> get achievements => [
    const MissionData(id: 'a1', title: 'First Blood',         description: 'Win your first game',    progress: 1, goal: 1,   coinReward: 200,  xpReward: 100, type: MissionType.achievement, completed: true),
    const MissionData(id: 'a2', title: 'Wild Caller',         description: 'Play 50 wild cards',     progress: 23, goal: 50, coinReward: 500,  xpReward: 250, type: MissionType.achievement),
    const MissionData(id: 'a3', title: 'Century Player',      description: 'Play 100 games',         progress: 60, goal: 100,coinReward: 1000, xpReward: 500, type: MissionType.achievement),
    const MissionData(id: 'a4', title: 'Last Card Hero',      description: 'Call last card 25 times',progress: 8,  goal: 25, coinReward: 400,  xpReward: 200, type: MissionType.achievement),
  ];
}

enum MissionType { daily, weekly, achievement }

class MissionData {
  final String id;
  final String title;
  final String description;
  final int progress;
  final int goal;
  final int coinReward;
  final int xpReward;
  final MissionType type;
  final bool completed;

  const MissionData({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.goal,
    required this.coinReward,
    required this.xpReward,
    required this.type,
    this.completed = false,
  });

  double get progressFraction => goal == 0 ? 1 : (progress / goal).clamp(0.0, 1.0);
  bool get isCompleted => completed || progress >= goal;
}
