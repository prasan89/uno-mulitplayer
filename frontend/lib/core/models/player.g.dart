// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerStateImpl _$$PlayerStateImplFromJson(Map<String, dynamic> json) =>
    _$PlayerStateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      cardCount: (json['cardCount'] as num).toInt(),
      isBot: json['isBot'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
      hasCalledLastCard: json['hasCalledLastCard'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$$PlayerStateImplToJson(_$PlayerStateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'cardCount': instance.cardCount,
      'isBot': instance.isBot,
      'isConnected': instance.isConnected,
      'hasCalledLastCard': instance.hasCalledLastCard,
      'avatarUrl': instance.avatarUrl,
    };
