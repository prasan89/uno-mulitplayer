import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:wilddeck/core/models/game_state.dart';
import 'package:wilddeck/core/models/player.dart';

part 'message.freezed.dart';
part 'message.g.dart';

// ---------------------------------------------------------------------------
// Client -> Server messages
// ---------------------------------------------------------------------------

enum ClientMessageType {
  @JsonValue('join_game')
  joinGame,
  @JsonValue('play_card')
  playCard,
  @JsonValue('draw_card')
  drawCard,
  @JsonValue('call_last_card')
  callLastCard,
  @JsonValue('challenge_draw4')
  challengeDraw4,
  @JsonValue('ping')
  ping,
}

@freezed
class ClientMessage with _$ClientMessage {
  const factory ClientMessage.joinGame({
    required String gameId,
  }) = JoinGameMessage;

  const factory ClientMessage.playCard({
    required String cardId,
    CardColor? chosenColor,
  }) = PlayCardMessage;

  const factory ClientMessage.drawCard() = DrawCardMessage;

  const factory ClientMessage.callLastCard() = CallLastCardMessage;

  const factory ClientMessage.challengeDraw4() = ChallengeDraw4Message;

  const factory ClientMessage.ping() = PingMessage;

  factory ClientMessage.fromJson(Map<String, dynamic> json) =>
      _$ClientMessageFromJson(json);
}

// ---------------------------------------------------------------------------
// Server -> Client messages
// ---------------------------------------------------------------------------

enum ServerMessageType {
  @JsonValue('game_state')
  gameState,
  @JsonValue('game_update')
  gameUpdate,
  @JsonValue('error')
  error,
  @JsonValue('pong')
  pong,
  @JsonValue('player_joined')
  playerJoined,
  @JsonValue('player_left')
  playerLeft,
  @JsonValue('game_started')
  gameStarted,
  @JsonValue('game_over')
  gameOver,
}

@freezed
class ServerMessage with _$ServerMessage {
  const factory ServerMessage.gameState({
    required GameState state,
  }) = GameStateMessage;

  const factory ServerMessage.gameUpdate({
    required GameState state,
    String? description,
  }) = GameUpdateMessage;

  const factory ServerMessage.error({
    required String code,
    required String message,
  }) = ErrorMessage;

  const factory ServerMessage.pong() = PongMessage;

  const factory ServerMessage.playerJoined({
    required PlayerState player,
  }) = PlayerJoinedMessage;

  const factory ServerMessage.playerLeft({
    required String playerId,
  }) = PlayerLeftMessage;

  const factory ServerMessage.gameStarted({
    required GameState state,
  }) = GameStartedMessage;

  const factory ServerMessage.gameOver({
    required String winnerId,
    required String winnerName,
  }) = GameOverMessage;

  factory ServerMessage.fromJson(Map<String, dynamic> json) =>
      _$ServerMessageFromJson(json);
}
