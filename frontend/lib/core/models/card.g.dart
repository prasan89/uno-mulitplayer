// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WildCardImpl _$$WildCardImplFromJson(Map<String, dynamic> json) =>
    _$WildCardImpl(
      id: json['id'] as String,
      color: $enumDecode(_$CardColorEnumMap, json['color']),
      type: $enumDecode(_$CardTypeEnumMap, json['type']),
      value: (json['value'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$WildCardImplToJson(_$WildCardImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'color': _$CardColorEnumMap[instance.color]!,
      'type': _$CardTypeEnumMap[instance.type]!,
      'value': instance.value,
    };

const _$CardColorEnumMap = {
  CardColor.red: 'red',
  CardColor.green: 'green',
  CardColor.blue: 'blue',
  CardColor.yellow: 'yellow',
  CardColor.wild: 'wild',
};

const _$CardTypeEnumMap = {
  CardType.number: 'number',
  CardType.skip: 'skip',
  CardType.reverse: 'reverse',
  CardType.drawTwo: 'drawTwo',
  CardType.wild: 'wild',
  CardType.wildDrawFour: 'wildDrawFour',
};
