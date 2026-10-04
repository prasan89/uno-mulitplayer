// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JoinGameMessageImpl _$$JoinGameMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$JoinGameMessageImpl(
      gameId: json['gameId'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$JoinGameMessageImplToJson(
        _$JoinGameMessageImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'runtimeType': instance.$type,
    };

_$PlayCardMessageImpl _$$PlayCardMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayCardMessageImpl(
      cardId: json['cardId'] as String,
      chosenColor: $enumDecodeNullable(_$CardColorEnumMap, json['chosenColor']),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PlayCardMessageImplToJson(
        _$PlayCardMessageImpl instance) =>
    <String, dynamic>{
      'cardId': instance.cardId,
      'chosenColor': _$CardColorEnumMap[instance.chosenColor],
      'runtimeType': instance.$type,
    };

const _$CardColorEnumMap = {
  CardColor.red: 'red',
  CardColor.green: 'green',
  CardColor.blue: 'blue',
  CardColor.yellow: 'yellow',
  CardColor.wild: 'wild',
};

_$DrawCardMessageImpl _$$DrawCardMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$DrawCardMessageImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$DrawCardMessageImplToJson(
        _$DrawCardMessageImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$CallLastCardMessageImpl _$$CallLastCardMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$CallLastCardMessageImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CallLastCardMessageImplToJson(
        _$CallLastCardMessageImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$ChallengeDraw4MessageImpl _$$ChallengeDraw4MessageImplFromJson(
        Map<String, dynamic> json) =>
    _$ChallengeDraw4MessageImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ChallengeDraw4MessageImplToJson(
        _$ChallengeDraw4MessageImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$PingMessageImpl _$$PingMessageImplFromJson(Map<String, dynamic> json) =>
    _$PingMessageImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PingMessageImplToJson(_$PingMessageImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$GameStateMessageImpl _$$GameStateMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$GameStateMessageImpl(
      state: GameState.fromJson(json['state'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$GameStateMessageImplToJson(
        _$GameStateMessageImpl instance) =>
    <String, dynamic>{
      'state': instance.state,
      'runtimeType': instance.$type,
    };

_$GameUpdateMessageImpl _$$GameUpdateMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$GameUpdateMessageImpl(
      state: GameState.fromJson(json['state'] as Map<String, dynamic>),
      description: json['description'] as String?,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$GameUpdateMessageImplToJson(
        _$GameUpdateMessageImpl instance) =>
    <String, dynamic>{
      'state': instance.state,
      'description': instance.description,
      'runtimeType': instance.$type,
    };

_$ErrorMessageImpl _$$ErrorMessageImplFromJson(Map<String, dynamic> json) =>
    _$ErrorMessageImpl(
      code: json['code'] as String,
      message: json['message'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ErrorMessageImplToJson(_$ErrorMessageImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'runtimeType': instance.$type,
    };

_$PongMessageImpl _$$PongMessageImplFromJson(Map<String, dynamic> json) =>
    _$PongMessageImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PongMessageImplToJson(_$PongMessageImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$PlayerJoinedMessageImpl _$$PlayerJoinedMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerJoinedMessageImpl(
      player: PlayerState.fromJson(json['player'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PlayerJoinedMessageImplToJson(
        _$PlayerJoinedMessageImpl instance) =>
    <String, dynamic>{
      'player': instance.player,
      'runtimeType': instance.$type,
    };

_$PlayerLeftMessageImpl _$$PlayerLeftMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$PlayerLeftMessageImpl(
      playerId: json['playerId'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$PlayerLeftMessageImplToJson(
        _$PlayerLeftMessageImpl instance) =>
    <String, dynamic>{
      'playerId': instance.playerId,
      'runtimeType': instance.$type,
    };

_$GameStartedMessageImpl _$$GameStartedMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$GameStartedMessageImpl(
      state: GameState.fromJson(json['state'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$GameStartedMessageImplToJson(
        _$GameStartedMessageImpl instance) =>
    <String, dynamic>{
      'state': instance.state,
      'runtimeType': instance.$type,
    };

_$GameOverMessageImpl _$$GameOverMessageImplFromJson(
        Map<String, dynamic> json) =>
    _$GameOverMessageImpl(
      winnerId: json['winnerId'] as String,
      winnerName: json['winnerName'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$GameOverMessageImplToJson(
        _$GameOverMessageImpl instance) =>
    <String, dynamic>{
      'winnerId': instance.winnerId,
      'winnerName': instance.winnerName,
      'runtimeType': instance.$type,
    };
