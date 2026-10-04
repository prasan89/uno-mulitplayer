import 'package:freezed_annotation/freezed_annotation.dart';

part 'card.freezed.dart';
part 'card.g.dart';

enum CardColor {
  @JsonValue('red')
  red,
  @JsonValue('green')
  green,
  @JsonValue('blue')
  blue,
  @JsonValue('yellow')
  yellow,
  @JsonValue('wild')
  wild,
}

enum CardType {
  @JsonValue('number')
  number,
  @JsonValue('skip')
  skip,
  @JsonValue('reverse')
  reverse,
  @JsonValue('drawTwo')
  drawTwo,
  @JsonValue('wild')
  wild,
  @JsonValue('wildDrawFour')
  wildDrawFour,
}

@freezed
class UnoCard with _$UnoCard {
  const factory UnoCard({
    required String id,
    required CardColor color,
    required CardType type,
    int? value,
  }) = _UnoCard;

  factory UnoCard.fromJson(Map<String, dynamic> json) =>
      _$UnoCardFromJson(json);
}
