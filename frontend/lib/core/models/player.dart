import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class PlayerState with _$PlayerState {
  const factory PlayerState({
    required String id,
    required String name,
    required int cardCount,
    @Default(false) bool isBot,
    @Default(true) bool isConnected,
    @Default(false) bool hasCalledUno,
    String? avatarUrl,
  }) = _PlayerState;

  factory PlayerState.fromJson(Map<String, dynamic> json) =>
      _$PlayerStateFromJson(json);
}
