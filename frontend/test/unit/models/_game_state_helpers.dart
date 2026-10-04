// Standalone GameState model used in unit tests, independent of generated code.
// This mirrors the structure of lib/core/models/game_state.dart.

enum TestCardColor { red, green, blue, yellow, wild }
enum TestGameStatus { waiting, active, finished }

class TestWildCard {
  final TestCardColor color;
  final String value;

  const TestWildCard({required this.color, required this.value});

  factory TestWildCard.fromJson(Map<String, dynamic> json) {
    return TestWildCard(
      color: TestCardColor.values.firstWhere(
        (c) => c.name == (json['color'] as String),
        orElse: () => TestCardColor.wild,
      ),
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'color': color.name,
        'value': value,
      };

  @override
  bool operator ==(Object other) =>
      other is TestWildCard && other.color == color && other.value == value;

  @override
  int get hashCode => Object.hash(color, value);
}

class TestPlayer {
  final String id;
  final String displayName;
  final int cardCount;
  final bool isConnected;

  const TestPlayer({
    required this.id,
    required this.displayName,
    required this.cardCount,
    this.isConnected = true,
  });

  factory TestPlayer.fromJson(Map<String, dynamic> json) {
    return TestPlayer(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      cardCount: json['cardCount'] as int,
      isConnected: json['isConnected'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'cardCount': cardCount,
        'isConnected': isConnected,
      };
}

class TestGameState {
  final String gameId;
  final String currentPlayerId;
  final List<TestPlayer> players;
  final List<TestWildCard> hand;
  final TestWildCard? topCard;
  final TestCardColor? activeColor;
  final bool isClockwise;
  final TestGameStatus status;
  final String? winnerId;

  const TestGameState({
    required this.gameId,
    required this.currentPlayerId,
    required this.players,
    required this.hand,
    this.topCard,
    this.activeColor,
    this.isClockwise = true,
    this.status = TestGameStatus.waiting,
    this.winnerId,
  });

  factory TestGameState.fromJson(Map<String, dynamic> json) {
    return TestGameState(
      gameId: json['gameId'] as String,
      currentPlayerId: json['currentPlayerId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => TestPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      hand: (json['hand'] as List<dynamic>)
          .map((c) => TestWildCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      topCard: json['topCard'] != null
          ? TestWildCard.fromJson(json['topCard'] as Map<String, dynamic>)
          : null,
      activeColor: json['activeColor'] != null
          ? TestCardColor.values.firstWhere(
              (c) => c.name == (json['activeColor'] as String),
              orElse: () => TestCardColor.wild,
            )
          : null,
      isClockwise: json['isClockwise'] as bool? ?? true,
      status: TestGameStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'waiting'),
        orElse: () => TestGameStatus.waiting,
      ),
      winnerId: json['winnerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'currentPlayerId': currentPlayerId,
        'players': players.map((p) => p.toJson()).toList(),
        'hand': hand.map((c) => c.toJson()).toList(),
        'topCard': topCard?.toJson(),
        'activeColor': activeColor?.name,
        'isClockwise': isClockwise,
        'status': status.name,
        'winnerId': winnerId,
      };

  bool isCurrentPlayer(String playerId) => currentPlayerId == playerId;

  TestPlayer? playerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }
}
