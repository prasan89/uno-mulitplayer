// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GameStateImpl _$$GameStateImplFromJson(Map<String, dynamic> json) =>
    _$GameStateImpl(
      gameId: json['gameId'] as String,
      currentPlayerId: json['currentPlayerId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((e) => PlayerState.fromJson(e as Map<String, dynamic>))
          .toList(),
      hand: (json['hand'] as List<dynamic>)
          .map((e) => WildCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCard: json['topCard'] == null
          ? null
          : WildCard.fromJson(json['topCard'] as Map<String, dynamic>),
      activeColor: $enumDecodeNullable(_$CardColorEnumMap, json['activeColor']),
      isClockwise: json['isClockwise'] as bool? ?? true,
      status: $enumDecodeNullable(_$GameStatusEnumMap, json['status']) ??
          GameStatus.waiting,
      winnerId: json['winnerId'] as String?,
    );

Map<String, dynamic> _$$GameStateImplToJson(_$GameStateImpl instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'currentPlayerId': instance.currentPlayerId,
      'players': instance.players,
      'hand': instance.hand,
      'topCard': instance.topCard,
      'activeColor': _$CardColorEnumMap[instance.activeColor],
      'isClockwise': instance.isClockwise,
      'status': _$GameStatusEnumMap[instance.status]!,
      'winnerId': instance.winnerId,
    };

const _$CardColorEnumMap = {
  CardColor.red: 'red',
  CardColor.green: 'green',
  CardColor.blue: 'blue',
  CardColor.yellow: 'yellow',
  CardColor.wild: 'wild',
};

const _$GameStatusEnumMap = {
  GameStatus.waiting: 'waiting',
  GameStatus.active: 'active',
  GameStatus.finished: 'finished',
};
