// Standalone GameState model used in unit tests, independent of generated code.
// This mirrors the structure of lib/core/models/game_state.dart.

enum _CardColor { red, green, blue, yellow, wild }
enum _GameStatus { waiting, active, finished }

class _UnoCard {
  final _CardColor color;
  final String value;

  const _UnoCard({required this.color, required this.value});

  factory _UnoCard.fromJson(Map<String, dynamic> json) {
    return _UnoCard(
      color: _CardColor.values.firstWhere(
        (c) => c.name == (json['color'] as String),
        orElse: () => _CardColor.wild,
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
      other is _UnoCard && other.color == color && other.value == value;

  @override
  int get hashCode => Object.hash(color, value);
}

class _Player {
  final String id;
  final String displayName;
  final int cardCount;
  final bool isConnected;

  const _Player({
    required this.id,
    required this.displayName,
    required this.cardCount,
    this.isConnected = true,
  });

  factory _Player.fromJson(Map<String, dynamic> json) {
    return _Player(
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

class _GameState {
  final String gameId;
  final String currentPlayerId;
  final List<_Player> players;
  final List<_UnoCard> hand;
  final _UnoCard? topCard;
  final _CardColor? activeColor;
  final bool isClockwise;
  final _GameStatus status;
  final String? winnerId;

  const _GameState({
    required this.gameId,
    required this.currentPlayerId,
    required this.players,
    required this.hand,
    this.topCard,
    this.activeColor,
    this.isClockwise = true,
    this.status = _GameStatus.waiting,
    this.winnerId,
  });

  factory _GameState.fromJson(Map<String, dynamic> json) {
    return _GameState(
      gameId: json['gameId'] as String,
      currentPlayerId: json['currentPlayerId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => _Player.fromJson(p as Map<String, dynamic>))
          .toList(),
      hand: (json['hand'] as List<dynamic>)
          .map((c) => _UnoCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      topCard: json['topCard'] != null
          ? _UnoCard.fromJson(json['topCard'] as Map<String, dynamic>)
          : null,
      activeColor: json['activeColor'] != null
          ? _CardColor.values.firstWhere(
              (c) => c.name == (json['activeColor'] as String),
              orElse: () => _CardColor.wild,
            )
          : null,
      isClockwise: json['isClockwise'] as bool? ?? true,
      status: _GameStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'waiting'),
        orElse: () => _GameStatus.waiting,
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

  _Player? playerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }
}
