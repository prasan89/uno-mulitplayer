/// WildDeck service interfaces.
/// All service layers are abstracted behind interfaces so mock implementations
/// can be swapped for real implementations in future milestones.
/// No game rules or business logic live inside UI components.

// ─── Player / Auth ────────────────────────────────────────────────────────────

abstract class IPlayerService {
  Future<WildDeckPlayer?> getCurrentPlayer();
  Future<WildDeckPlayer> signInAsGuest(String displayName);
  Future<WildDeckPlayer> signInWithEmail(String email, String password);
  Future<WildDeckPlayer> register(String email, String password, String displayName);
  Future<void> signOut();
  Future<void> updateProfile({String? displayName, String? avatarId});
}

class WildDeckPlayer {
  final String id;
  final String displayName;
  final String? avatarId;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int coins;
  final int gems;
  final int wins;
  final int losses;
  final String? leagueId;
  final bool isGuest;

  const WildDeckPlayer({
    required this.id,
    required this.displayName,
    this.avatarId,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 1000,
    this.coins = 500,
    this.gems = 10,
    this.wins = 0,
    this.losses = 0,
    this.leagueId,
    this.isGuest = false,
  });

  double get winRate => (wins + losses) == 0 ? 0 : wins / (wins + losses);
  int get totalGames => wins + losses;
  double get xpProgress => xpToNextLevel == 0 ? 0 : xp / xpToNextLevel;
}

// ─── Matchmaking ──────────────────────────────────────────────────────────────

/// Matchmaking state model. UI reacts to this; no logic lives in UI.
enum MatchmakingStatus { idle, searching, found, cancelled, error }

class MatchmakingState {
  final MatchmakingStatus status;
  final List<MatchmakingSlot> slots;
  final int elapsedSeconds;
  final String? matchId;
  final String? errorMessage;

  const MatchmakingState({
    required this.status,
    required this.slots,
    this.elapsedSeconds = 0,
    this.matchId,
    this.errorMessage,
  });

  int get filledSlots => slots.where((s) => s.isOccupied).length;
  int get totalSlots => slots.length;
  bool get isFull => filledSlots == totalSlots;
}

class MatchmakingSlot {
  final int index;
  final bool isOccupied;
  final bool isCurrentPlayer;
  final String? playerName;
  final String? avatarId;
  final bool isBot;

  const MatchmakingSlot({
    required this.index,
    this.isOccupied = false,
    this.isCurrentPlayer = false,
    this.playerName,
    this.avatarId,
    this.isBot = false,
  });

  factory MatchmakingSlot.empty(int index) =>
      MatchmakingSlot(index: index);
}

/// Interface — replace MockMatchmakingService with real implementation later.
abstract class IMatchmakingService {
  Stream<MatchmakingState> searchForMatch({
    required String gameMode,
    required int maxPlayers,
    required bool fillWithBots,
  });
  Future<void> cancelSearch();
  Future<String> createPrivateRoom();
  Future<void> joinPrivateRoom(String roomCode);
}

// ─── Game Engine Interface ────────────────────────────────────────────────────

/// The real game rules engine will implement this.
/// M1 UI never calls rules logic directly — always through this interface.
abstract class IGameEngine {
  bool canPlayCard({required WildGameCard card, required WildGameCard topCard, required WildCardColor activeColor});
  WildGameState applyPlayCard({required WildGameState state, required String cardId, WildCardColor? chosenColor});
  WildGameState applyDrawCard(WildGameState state);
  WildGameState applyCallLastCard(WildGameState state);
  bool checkWin(WildGameState state);
}

// ─── Realtime Interface ───────────────────────────────────────────────────────

abstract class IRealtimeService {
  Stream<WildGameState> get gameStateStream;
  Future<void> connect(String gameId, String authToken);
  Future<void> disconnect();
  Future<void> sendPlayCard(String cardId, {WildCardColor? chosenColor});
  Future<void> sendDrawCard();
  Future<void> sendCallLastCard();
}

// ─── Wallet / Economy ─────────────────────────────────────────────────────────

abstract class IWalletService {
  Future<WalletBalance> getBalance();
  Future<void> purchaseProduct(String productId);
  Future<List<ShopItem>> getCatalog(ShopCategory category);
}

class WalletBalance {
  final int coins;
  final int gems;
  const WalletBalance({required this.coins, required this.gems});
}

enum ShopCategory { cards, avatars, tables, emotes }

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int coinPrice;
  final int gemPrice;
  final ShopCategory category;
  final bool owned;
  final bool isFeatured;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    this.coinPrice = 0,
    this.gemPrice = 0,
    required this.category,
    this.owned = false,
    this.isFeatured = false,
  });
}

// ─── Game domain models ───────────────────────────────────────────────────────

class WildGameCard {
  final String id;
  final WildCardColor color;
  final WildCardType type;
  final int? number; // null for action/wild cards

  const WildGameCard({
    required this.id,
    required this.color,
    required this.type,
    this.number,
  });

  bool get isWild => type == WildCardType.wild || type == WildCardType.wildDrawFour;
  bool get isAction => type != WildCardType.number;

  String get displayLabel {
    switch (type) {
      case WildCardType.number:      return '${number ?? 0}';
      case WildCardType.skip:        return '⊘';
      case WildCardType.reverse:     return '↺';
      case WildCardType.drawTwo:     return '+2';
      case WildCardType.wild:        return 'W';
      case WildCardType.wildDrawFour:return '+4';
    }
  }
}

enum GamePhase { waiting, active, lastCard, finished }
enum GameMode  { classic, quick, team2v2, private, tournament }

class WildGameState {
  final String gameId;
  final GamePhase phase;
  final GameMode mode;
  final String currentPlayerId;
  final List<WildGamePlayer> players;
  final List<WildGameCard> myHand;
  final WildGameCard? topCard;
  final WildCardColor activeColor;
  final int drawPileCount;
  final int discardCount;
  final bool isClockwise;
  final String? winnerId;
  final bool isMyTurn;

  const WildGameState({
    required this.gameId,
    required this.phase,
    required this.mode,
    required this.currentPlayerId,
    required this.players,
    required this.myHand,
    this.topCard,
    required this.activeColor,
    this.drawPileCount = 0,
    this.discardCount = 0,
    this.isClockwise = true,
    this.winnerId,
    this.isMyTurn = false,
  });

  bool get isGameOver => phase == GamePhase.finished;
  bool get isLastCard  => myHand.length == 1 && phase == GamePhase.active;
}

class WildGamePlayer {
  final String id;
  final String displayName;
  final String? avatarId;
  final int cardCount;
  final bool isBot;
  final bool isConnected;
  final bool isCurrentTurn;
  final bool hasCalledLastCard;

  const WildGamePlayer({
    required this.id,
    required this.displayName,
    this.avatarId,
    this.cardCount = 0,
    this.isBot = false,
    this.isConnected = true,
    this.isCurrentTurn = false,
    this.hasCalledLastCard = false,
  });
}

// ─── Enums reexport (shared by theme + services) ─────────────────────────────
// WildCardColor and WildCardType are defined in wilddeck_theme.dart
export 'package:uno_multiplayer/shared/theme/wilddeck_theme.dart'
    show WildCardColor, WildCardType;
