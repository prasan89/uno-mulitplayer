import 'package:freezed_annotation/freezed_annotation.dart';

import 'card.dart';
import 'player.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

export 'card.dart' show CardColor, CardType, WildCard;
export 'player.dart' show PlayerState;

enum GameStatus {
  @JsonValue('waiting')
  waiting,
  @JsonValue('active')
  active,
  @JsonValue('finished')
  finished,
}

@freezed
class GameState with _$GameState {
  const GameState._();

  const factory GameState({
    required String gameId,
    required String currentPlayerId,
    required List<PlayerState> players,
    required List<WildCard> hand,
    WildCard? topCard,
    CardColor? activeColor,
    @Default(true) bool isClockwise,
    @Default(GameStatus.waiting) GameStatus status,
    String? winnerId,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  /// Returns true if [playerId] is the current player whose turn it is.
  bool isCurrentPlayer(String playerId) => currentPlayerId == playerId;

  /// Returns the [PlayerState] for the given [playerId], or null.
  PlayerState? playerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }
}
