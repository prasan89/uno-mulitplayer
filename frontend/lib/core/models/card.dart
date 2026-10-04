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
class WildCard with _$WildCard {
  const factory WildCard({
    required String id,
    required CardColor color,
    required CardType type,
    int? value,
  }) = _WildCard;

  factory WildCard.fromJson(Map<String, dynamic> json) =>
      _$WildCardFromJson(json);
}
