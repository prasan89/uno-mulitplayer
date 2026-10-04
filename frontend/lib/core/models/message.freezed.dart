// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ClientMessage _$ClientMessageFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'joinGame':
      return JoinGameMessage.fromJson(json);
    case 'playCard':
      return PlayCardMessage.fromJson(json);
    case 'drawCard':
      return DrawCardMessage.fromJson(json);
    case 'callLastCard':
      return CallLastCardMessage.fromJson(json);
    case 'challengeDraw4':
      return ChallengeDraw4Message.fromJson(json);
    case 'ping':
      return PingMessage.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ClientMessage',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ClientMessage {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ClientMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientMessageCopyWith<$Res> {
  factory $ClientMessageCopyWith(
          ClientMessage value, $Res Function(ClientMessage) then) =
      _$ClientMessageCopyWithImpl<$Res, ClientMessage>;
}

/// @nodoc
class _$ClientMessageCopyWithImpl<$Res, $Val extends ClientMessage>
    implements $ClientMessageCopyWith<$Res> {
  _$ClientMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$JoinGameMessageImplCopyWith<$Res> {
  factory _$$JoinGameMessageImplCopyWith(_$JoinGameMessageImpl value,
          $Res Function(_$JoinGameMessageImpl) then) =
      __$$JoinGameMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String gameId});
}

/// @nodoc
class __$$JoinGameMessageImplCopyWithImpl<$Res>
    extends _$ClientMessageCopyWithImpl<$Res, _$JoinGameMessageImpl>
    implements _$$JoinGameMessageImplCopyWith<$Res> {
  __$$JoinGameMessageImplCopyWithImpl(
      _$JoinGameMessageImpl _value, $Res Function(_$JoinGameMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
  }) {
    return _then(_$JoinGameMessageImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$JoinGameMessageImpl implements JoinGameMessage {
  const _$JoinGameMessageImpl({required this.gameId, final String? $type})
      : $type = $type ?? 'joinGame';

  factory _$JoinGameMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$JoinGameMessageImplFromJson(json);

  @override
  final String gameId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ClientMessage.joinGame(gameId: $gameId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JoinGameMessageImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, gameId);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JoinGameMessageImplCopyWith<_$JoinGameMessageImpl> get copyWith =>
      __$$JoinGameMessageImplCopyWithImpl<_$JoinGameMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) {
    return joinGame(gameId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) {
    return joinGame?.call(gameId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) {
    if (joinGame != null) {
      return joinGame(gameId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) {
    return joinGame(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) {
    return joinGame?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) {
    if (joinGame != null) {
      return joinGame(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$JoinGameMessageImplToJson(
      this,
    );
  }
}

abstract class JoinGameMessage implements ClientMessage {
  const factory JoinGameMessage({required final String gameId}) =
      _$JoinGameMessageImpl;

  factory JoinGameMessage.fromJson(Map<String, dynamic> json) =
      _$JoinGameMessageImpl.fromJson;

  String get gameId;

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JoinGameMessageImplCopyWith<_$JoinGameMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlayCardMessageImplCopyWith<$Res> {
  factory _$$PlayCardMessageImplCopyWith(_$PlayCardMessageImpl value,
          $Res Function(_$PlayCardMessageImpl) then) =
      __$$PlayCardMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String cardId, CardColor? chosenColor});
}

/// @nodoc
class __$$PlayCardMessageImplCopyWithImpl<$Res>
    extends _$ClientMessageCopyWithImpl<$Res, _$PlayCardMessageImpl>
    implements _$$PlayCardMessageImplCopyWith<$Res> {
  __$$PlayCardMessageImplCopyWithImpl(
      _$PlayCardMessageImpl _value, $Res Function(_$PlayCardMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cardId = null,
    Object? chosenColor = freezed,
  }) {
    return _then(_$PlayCardMessageImpl(
      cardId: null == cardId
          ? _value.cardId
          : cardId // ignore: cast_nullable_to_non_nullable
              as String,
      chosenColor: freezed == chosenColor
          ? _value.chosenColor
          : chosenColor // ignore: cast_nullable_to_non_nullable
              as CardColor?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayCardMessageImpl implements PlayCardMessage {
  const _$PlayCardMessageImpl(
      {required this.cardId, this.chosenColor, final String? $type})
      : $type = $type ?? 'playCard';

  factory _$PlayCardMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayCardMessageImplFromJson(json);

  @override
  final String cardId;
  @override
  final CardColor? chosenColor;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ClientMessage.playCard(cardId: $cardId, chosenColor: $chosenColor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayCardMessageImpl &&
            (identical(other.cardId, cardId) || other.cardId == cardId) &&
            (identical(other.chosenColor, chosenColor) ||
                other.chosenColor == chosenColor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, cardId, chosenColor);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayCardMessageImplCopyWith<_$PlayCardMessageImpl> get copyWith =>
      __$$PlayCardMessageImplCopyWithImpl<_$PlayCardMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) {
    return playCard(cardId, chosenColor);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) {
    return playCard?.call(cardId, chosenColor);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) {
    if (playCard != null) {
      return playCard(cardId, chosenColor);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) {
    return playCard(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) {
    return playCard?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) {
    if (playCard != null) {
      return playCard(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayCardMessageImplToJson(
      this,
    );
  }
}

abstract class PlayCardMessage implements ClientMessage {
  const factory PlayCardMessage(
      {required final String cardId,
      final CardColor? chosenColor}) = _$PlayCardMessageImpl;

  factory PlayCardMessage.fromJson(Map<String, dynamic> json) =
      _$PlayCardMessageImpl.fromJson;

  String get cardId;
  CardColor? get chosenColor;

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayCardMessageImplCopyWith<_$PlayCardMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DrawCardMessageImplCopyWith<$Res> {
  factory _$$DrawCardMessageImplCopyWith(_$DrawCardMessageImpl value,
          $Res Function(_$DrawCardMessageImpl) then) =
      __$$DrawCardMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DrawCardMessageImplCopyWithImpl<$Res>
    extends _$ClientMessageCopyWithImpl<$Res, _$DrawCardMessageImpl>
    implements _$$DrawCardMessageImplCopyWith<$Res> {
  __$$DrawCardMessageImplCopyWithImpl(
      _$DrawCardMessageImpl _value, $Res Function(_$DrawCardMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$DrawCardMessageImpl implements DrawCardMessage {
  const _$DrawCardMessageImpl({final String? $type})
      : $type = $type ?? 'drawCard';

  factory _$DrawCardMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrawCardMessageImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ClientMessage.drawCard()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DrawCardMessageImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) {
    return drawCard();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) {
    return drawCard?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) {
    if (drawCard != null) {
      return drawCard();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) {
    return drawCard(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) {
    return drawCard?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) {
    if (drawCard != null) {
      return drawCard(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DrawCardMessageImplToJson(
      this,
    );
  }
}

abstract class DrawCardMessage implements ClientMessage {
  const factory DrawCardMessage() = _$DrawCardMessageImpl;

  factory DrawCardMessage.fromJson(Map<String, dynamic> json) =
      _$DrawCardMessageImpl.fromJson;
}

/// @nodoc
abstract class _$$CallLastCardMessageImplCopyWith<$Res> {
  factory _$$CallLastCardMessageImplCopyWith(_$CallLastCardMessageImpl value,
          $Res Function(_$CallLastCardMessageImpl) then) =
      __$$CallLastCardMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CallLastCardMessageImplCopyWithImpl<$Res>
    extends _$ClientMessageCopyWithImpl<$Res, _$CallLastCardMessageImpl>
    implements _$$CallLastCardMessageImplCopyWith<$Res> {
  __$$CallLastCardMessageImplCopyWithImpl(_$CallLastCardMessageImpl _value,
      $Res Function(_$CallLastCardMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$CallLastCardMessageImpl implements CallLastCardMessage {
  const _$CallLastCardMessageImpl({final String? $type})
      : $type = $type ?? 'callLastCard';

  factory _$CallLastCardMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$CallLastCardMessageImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ClientMessage.callLastCard()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallLastCardMessageImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) {
    return callLastCard();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) {
    return callLastCard?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) {
    if (callLastCard != null) {
      return callLastCard();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) {
    return callLastCard(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) {
    return callLastCard?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) {
    if (callLastCard != null) {
      return callLastCard(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CallLastCardMessageImplToJson(
      this,
    );
  }
}

abstract class CallLastCardMessage implements ClientMessage {
  const factory CallLastCardMessage() = _$CallLastCardMessageImpl;

  factory CallLastCardMessage.fromJson(Map<String, dynamic> json) =
      _$CallLastCardMessageImpl.fromJson;
}

/// @nodoc
abstract class _$$ChallengeDraw4MessageImplCopyWith<$Res> {
  factory _$$ChallengeDraw4MessageImplCopyWith(
          _$ChallengeDraw4MessageImpl value,
          $Res Function(_$ChallengeDraw4MessageImpl) then) =
      __$$ChallengeDraw4MessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChallengeDraw4MessageImplCopyWithImpl<$Res>
    extends _$ClientMessageCopyWithImpl<$Res, _$ChallengeDraw4MessageImpl>
    implements _$$ChallengeDraw4MessageImplCopyWith<$Res> {
  __$$ChallengeDraw4MessageImplCopyWithImpl(_$ChallengeDraw4MessageImpl _value,
      $Res Function(_$ChallengeDraw4MessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$ChallengeDraw4MessageImpl implements ChallengeDraw4Message {
  const _$ChallengeDraw4MessageImpl({final String? $type})
      : $type = $type ?? 'challengeDraw4';

  factory _$ChallengeDraw4MessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChallengeDraw4MessageImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ClientMessage.challengeDraw4()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChallengeDraw4MessageImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) {
    return challengeDraw4();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) {
    return challengeDraw4?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) {
    if (challengeDraw4 != null) {
      return challengeDraw4();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) {
    return challengeDraw4(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) {
    return challengeDraw4?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) {
    if (challengeDraw4 != null) {
      return challengeDraw4(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChallengeDraw4MessageImplToJson(
      this,
    );
  }
}

abstract class ChallengeDraw4Message implements ClientMessage {
  const factory ChallengeDraw4Message() = _$ChallengeDraw4MessageImpl;

  factory ChallengeDraw4Message.fromJson(Map<String, dynamic> json) =
      _$ChallengeDraw4MessageImpl.fromJson;
}

/// @nodoc
abstract class _$$PingMessageImplCopyWith<$Res> {
  factory _$$PingMessageImplCopyWith(
          _$PingMessageImpl value, $Res Function(_$PingMessageImpl) then) =
      __$$PingMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PingMessageImplCopyWithImpl<$Res>
    extends _$ClientMessageCopyWithImpl<$Res, _$PingMessageImpl>
    implements _$$PingMessageImplCopyWith<$Res> {
  __$$PingMessageImplCopyWithImpl(
      _$PingMessageImpl _value, $Res Function(_$PingMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$PingMessageImpl implements PingMessage {
  const _$PingMessageImpl({final String? $type}) : $type = $type ?? 'ping';

  factory _$PingMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PingMessageImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ClientMessage.ping()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PingMessageImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String gameId) joinGame,
    required TResult Function(String cardId, CardColor? chosenColor) playCard,
    required TResult Function() drawCard,
    required TResult Function() callLastCard,
    required TResult Function() challengeDraw4,
    required TResult Function() ping,
  }) {
    return ping();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String gameId)? joinGame,
    TResult? Function(String cardId, CardColor? chosenColor)? playCard,
    TResult? Function()? drawCard,
    TResult? Function()? callLastCard,
    TResult? Function()? challengeDraw4,
    TResult? Function()? ping,
  }) {
    return ping?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String gameId)? joinGame,
    TResult Function(String cardId, CardColor? chosenColor)? playCard,
    TResult Function()? drawCard,
    TResult Function()? callLastCard,
    TResult Function()? challengeDraw4,
    TResult Function()? ping,
    required TResult orElse(),
  }) {
    if (ping != null) {
      return ping();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(JoinGameMessage value) joinGame,
    required TResult Function(PlayCardMessage value) playCard,
    required TResult Function(DrawCardMessage value) drawCard,
    required TResult Function(CallLastCardMessage value) callLastCard,
    required TResult Function(ChallengeDraw4Message value) challengeDraw4,
    required TResult Function(PingMessage value) ping,
  }) {
    return ping(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(JoinGameMessage value)? joinGame,
    TResult? Function(PlayCardMessage value)? playCard,
    TResult? Function(DrawCardMessage value)? drawCard,
    TResult? Function(CallLastCardMessage value)? callLastCard,
    TResult? Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult? Function(PingMessage value)? ping,
  }) {
    return ping?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(JoinGameMessage value)? joinGame,
    TResult Function(PlayCardMessage value)? playCard,
    TResult Function(DrawCardMessage value)? drawCard,
    TResult Function(CallLastCardMessage value)? callLastCard,
    TResult Function(ChallengeDraw4Message value)? challengeDraw4,
    TResult Function(PingMessage value)? ping,
    required TResult orElse(),
  }) {
    if (ping != null) {
      return ping(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PingMessageImplToJson(
      this,
    );
  }
}

abstract class PingMessage implements ClientMessage {
  const factory PingMessage() = _$PingMessageImpl;

  factory PingMessage.fromJson(Map<String, dynamic> json) =
      _$PingMessageImpl.fromJson;
}

ServerMessage _$ServerMessageFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'gameState':
      return GameStateMessage.fromJson(json);
    case 'gameUpdate':
      return GameUpdateMessage.fromJson(json);
    case 'error':
      return ErrorMessage.fromJson(json);
    case 'pong':
      return PongMessage.fromJson(json);
    case 'playerJoined':
      return PlayerJoinedMessage.fromJson(json);
    case 'playerLeft':
      return PlayerLeftMessage.fromJson(json);
    case 'gameStarted':
      return GameStartedMessage.fromJson(json);
    case 'gameOver':
      return GameOverMessage.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'ServerMessage',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$ServerMessage {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this ServerMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServerMessageCopyWith<$Res> {
  factory $ServerMessageCopyWith(
          ServerMessage value, $Res Function(ServerMessage) then) =
      _$ServerMessageCopyWithImpl<$Res, ServerMessage>;
}

/// @nodoc
class _$ServerMessageCopyWithImpl<$Res, $Val extends ServerMessage>
    implements $ServerMessageCopyWith<$Res> {
  _$ServerMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$GameStateMessageImplCopyWith<$Res> {
  factory _$$GameStateMessageImplCopyWith(_$GameStateMessageImpl value,
          $Res Function(_$GameStateMessageImpl) then) =
      __$$GameStateMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameState state});

  $GameStateCopyWith<$Res> get state;
}

/// @nodoc
class __$$GameStateMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$GameStateMessageImpl>
    implements _$$GameStateMessageImplCopyWith<$Res> {
  __$$GameStateMessageImplCopyWithImpl(_$GameStateMessageImpl _value,
      $Res Function(_$GameStateMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
  }) {
    return _then(_$GameStateMessageImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as GameState,
    ));
  }

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameStateCopyWith<$Res> get state {
    return $GameStateCopyWith<$Res>(_value.state, (value) {
      return _then(_value.copyWith(state: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateMessageImpl implements GameStateMessage {
  const _$GameStateMessageImpl({required this.state, final String? $type})
      : $type = $type ?? 'gameState';

  factory _$GameStateMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateMessageImplFromJson(json);

  @override
  final GameState state;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.gameState(state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateMessageImpl &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateMessageImplCopyWith<_$GameStateMessageImpl> get copyWith =>
      __$$GameStateMessageImplCopyWithImpl<_$GameStateMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return gameState(state);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return gameState?.call(state);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (gameState != null) {
      return gameState(state);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return gameState(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return gameState?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (gameState != null) {
      return gameState(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateMessageImplToJson(
      this,
    );
  }
}

abstract class GameStateMessage implements ServerMessage {
  const factory GameStateMessage({required final GameState state}) =
      _$GameStateMessageImpl;

  factory GameStateMessage.fromJson(Map<String, dynamic> json) =
      _$GameStateMessageImpl.fromJson;

  GameState get state;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateMessageImplCopyWith<_$GameStateMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GameUpdateMessageImplCopyWith<$Res> {
  factory _$$GameUpdateMessageImplCopyWith(_$GameUpdateMessageImpl value,
          $Res Function(_$GameUpdateMessageImpl) then) =
      __$$GameUpdateMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameState state, String? description});

  $GameStateCopyWith<$Res> get state;
}

/// @nodoc
class __$$GameUpdateMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$GameUpdateMessageImpl>
    implements _$$GameUpdateMessageImplCopyWith<$Res> {
  __$$GameUpdateMessageImplCopyWithImpl(_$GameUpdateMessageImpl _value,
      $Res Function(_$GameUpdateMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? description = freezed,
  }) {
    return _then(_$GameUpdateMessageImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as GameState,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameStateCopyWith<$Res> get state {
    return $GameStateCopyWith<$Res>(_value.state, (value) {
      return _then(_value.copyWith(state: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$GameUpdateMessageImpl implements GameUpdateMessage {
  const _$GameUpdateMessageImpl(
      {required this.state, this.description, final String? $type})
      : $type = $type ?? 'gameUpdate';

  factory _$GameUpdateMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameUpdateMessageImplFromJson(json);

  @override
  final GameState state;
  @override
  final String? description;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.gameUpdate(state: $state, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameUpdateMessageImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state, description);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameUpdateMessageImplCopyWith<_$GameUpdateMessageImpl> get copyWith =>
      __$$GameUpdateMessageImplCopyWithImpl<_$GameUpdateMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return gameUpdate(state, description);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return gameUpdate?.call(state, description);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (gameUpdate != null) {
      return gameUpdate(state, description);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return gameUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return gameUpdate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (gameUpdate != null) {
      return gameUpdate(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GameUpdateMessageImplToJson(
      this,
    );
  }
}

abstract class GameUpdateMessage implements ServerMessage {
  const factory GameUpdateMessage(
      {required final GameState state,
      final String? description}) = _$GameUpdateMessageImpl;

  factory GameUpdateMessage.fromJson(Map<String, dynamic> json) =
      _$GameUpdateMessageImpl.fromJson;

  GameState get state;
  String? get description;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameUpdateMessageImplCopyWith<_$GameUpdateMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorMessageImplCopyWith<$Res> {
  factory _$$ErrorMessageImplCopyWith(
          _$ErrorMessageImpl value, $Res Function(_$ErrorMessageImpl) then) =
      __$$ErrorMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String code, String message});
}

/// @nodoc
class __$$ErrorMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$ErrorMessageImpl>
    implements _$$ErrorMessageImplCopyWith<$Res> {
  __$$ErrorMessageImplCopyWithImpl(
      _$ErrorMessageImpl _value, $Res Function(_$ErrorMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
  }) {
    return _then(_$ErrorMessageImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ErrorMessageImpl implements ErrorMessage {
  const _$ErrorMessageImpl(
      {required this.code, required this.message, final String? $type})
      : $type = $type ?? 'error';

  factory _$ErrorMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ErrorMessageImplFromJson(json);

  @override
  final String code;
  @override
  final String message;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.error(code: $code, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorMessageImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorMessageImplCopyWith<_$ErrorMessageImpl> get copyWith =>
      __$$ErrorMessageImplCopyWithImpl<_$ErrorMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return error(code, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return error?.call(code, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(code, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ErrorMessageImplToJson(
      this,
    );
  }
}

abstract class ErrorMessage implements ServerMessage {
  const factory ErrorMessage(
      {required final String code,
      required final String message}) = _$ErrorMessageImpl;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) =
      _$ErrorMessageImpl.fromJson;

  String get code;
  String get message;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorMessageImplCopyWith<_$ErrorMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PongMessageImplCopyWith<$Res> {
  factory _$$PongMessageImplCopyWith(
          _$PongMessageImpl value, $Res Function(_$PongMessageImpl) then) =
      __$$PongMessageImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PongMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$PongMessageImpl>
    implements _$$PongMessageImplCopyWith<$Res> {
  __$$PongMessageImplCopyWithImpl(
      _$PongMessageImpl _value, $Res Function(_$PongMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$PongMessageImpl implements PongMessage {
  const _$PongMessageImpl({final String? $type}) : $type = $type ?? 'pong';

  factory _$PongMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PongMessageImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.pong()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PongMessageImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return pong();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return pong?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (pong != null) {
      return pong();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return pong(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return pong?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (pong != null) {
      return pong(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PongMessageImplToJson(
      this,
    );
  }
}

abstract class PongMessage implements ServerMessage {
  const factory PongMessage() = _$PongMessageImpl;

  factory PongMessage.fromJson(Map<String, dynamic> json) =
      _$PongMessageImpl.fromJson;
}

/// @nodoc
abstract class _$$PlayerJoinedMessageImplCopyWith<$Res> {
  factory _$$PlayerJoinedMessageImplCopyWith(_$PlayerJoinedMessageImpl value,
          $Res Function(_$PlayerJoinedMessageImpl) then) =
      __$$PlayerJoinedMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({PlayerState player});

  $PlayerStateCopyWith<$Res> get player;
}

/// @nodoc
class __$$PlayerJoinedMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$PlayerJoinedMessageImpl>
    implements _$$PlayerJoinedMessageImplCopyWith<$Res> {
  __$$PlayerJoinedMessageImplCopyWithImpl(_$PlayerJoinedMessageImpl _value,
      $Res Function(_$PlayerJoinedMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? player = null,
  }) {
    return _then(_$PlayerJoinedMessageImpl(
      player: null == player
          ? _value.player
          : player // ignore: cast_nullable_to_non_nullable
              as PlayerState,
    ));
  }

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlayerStateCopyWith<$Res> get player {
    return $PlayerStateCopyWith<$Res>(_value.player, (value) {
      return _then(_value.copyWith(player: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerJoinedMessageImpl implements PlayerJoinedMessage {
  const _$PlayerJoinedMessageImpl({required this.player, final String? $type})
      : $type = $type ?? 'playerJoined';

  factory _$PlayerJoinedMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerJoinedMessageImplFromJson(json);

  @override
  final PlayerState player;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.playerJoined(player: $player)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerJoinedMessageImpl &&
            (identical(other.player, player) || other.player == player));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, player);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerJoinedMessageImplCopyWith<_$PlayerJoinedMessageImpl> get copyWith =>
      __$$PlayerJoinedMessageImplCopyWithImpl<_$PlayerJoinedMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return playerJoined(player);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return playerJoined?.call(player);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (playerJoined != null) {
      return playerJoined(player);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return playerJoined(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return playerJoined?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (playerJoined != null) {
      return playerJoined(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerJoinedMessageImplToJson(
      this,
    );
  }
}

abstract class PlayerJoinedMessage implements ServerMessage {
  const factory PlayerJoinedMessage({required final PlayerState player}) =
      _$PlayerJoinedMessageImpl;

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) =
      _$PlayerJoinedMessageImpl.fromJson;

  PlayerState get player;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerJoinedMessageImplCopyWith<_$PlayerJoinedMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlayerLeftMessageImplCopyWith<$Res> {
  factory _$$PlayerLeftMessageImplCopyWith(_$PlayerLeftMessageImpl value,
          $Res Function(_$PlayerLeftMessageImpl) then) =
      __$$PlayerLeftMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String playerId});
}

/// @nodoc
class __$$PlayerLeftMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$PlayerLeftMessageImpl>
    implements _$$PlayerLeftMessageImplCopyWith<$Res> {
  __$$PlayerLeftMessageImplCopyWithImpl(_$PlayerLeftMessageImpl _value,
      $Res Function(_$PlayerLeftMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
  }) {
    return _then(_$PlayerLeftMessageImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerLeftMessageImpl implements PlayerLeftMessage {
  const _$PlayerLeftMessageImpl({required this.playerId, final String? $type})
      : $type = $type ?? 'playerLeft';

  factory _$PlayerLeftMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerLeftMessageImplFromJson(json);

  @override
  final String playerId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.playerLeft(playerId: $playerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerLeftMessageImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, playerId);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerLeftMessageImplCopyWith<_$PlayerLeftMessageImpl> get copyWith =>
      __$$PlayerLeftMessageImplCopyWithImpl<_$PlayerLeftMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return playerLeft(playerId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return playerLeft?.call(playerId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (playerLeft != null) {
      return playerLeft(playerId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return playerLeft(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return playerLeft?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (playerLeft != null) {
      return playerLeft(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerLeftMessageImplToJson(
      this,
    );
  }
}

abstract class PlayerLeftMessage implements ServerMessage {
  const factory PlayerLeftMessage({required final String playerId}) =
      _$PlayerLeftMessageImpl;

  factory PlayerLeftMessage.fromJson(Map<String, dynamic> json) =
      _$PlayerLeftMessageImpl.fromJson;

  String get playerId;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerLeftMessageImplCopyWith<_$PlayerLeftMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GameStartedMessageImplCopyWith<$Res> {
  factory _$$GameStartedMessageImplCopyWith(_$GameStartedMessageImpl value,
          $Res Function(_$GameStartedMessageImpl) then) =
      __$$GameStartedMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({GameState state});

  $GameStateCopyWith<$Res> get state;
}

/// @nodoc
class __$$GameStartedMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$GameStartedMessageImpl>
    implements _$$GameStartedMessageImplCopyWith<$Res> {
  __$$GameStartedMessageImplCopyWithImpl(_$GameStartedMessageImpl _value,
      $Res Function(_$GameStartedMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
  }) {
    return _then(_$GameStartedMessageImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as GameState,
    ));
  }

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GameStateCopyWith<$Res> get state {
    return $GameStateCopyWith<$Res>(_value.state, (value) {
      return _then(_value.copyWith(state: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStartedMessageImpl implements GameStartedMessage {
  const _$GameStartedMessageImpl({required this.state, final String? $type})
      : $type = $type ?? 'gameStarted';

  factory _$GameStartedMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStartedMessageImplFromJson(json);

  @override
  final GameState state;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.gameStarted(state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStartedMessageImpl &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, state);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStartedMessageImplCopyWith<_$GameStartedMessageImpl> get copyWith =>
      __$$GameStartedMessageImplCopyWithImpl<_$GameStartedMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return gameStarted(state);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return gameStarted?.call(state);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (gameStarted != null) {
      return gameStarted(state);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return gameStarted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return gameStarted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (gameStarted != null) {
      return gameStarted(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStartedMessageImplToJson(
      this,
    );
  }
}

abstract class GameStartedMessage implements ServerMessage {
  const factory GameStartedMessage({required final GameState state}) =
      _$GameStartedMessageImpl;

  factory GameStartedMessage.fromJson(Map<String, dynamic> json) =
      _$GameStartedMessageImpl.fromJson;

  GameState get state;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStartedMessageImplCopyWith<_$GameStartedMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GameOverMessageImplCopyWith<$Res> {
  factory _$$GameOverMessageImplCopyWith(_$GameOverMessageImpl value,
          $Res Function(_$GameOverMessageImpl) then) =
      __$$GameOverMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String winnerId, String winnerName});
}

/// @nodoc
class __$$GameOverMessageImplCopyWithImpl<$Res>
    extends _$ServerMessageCopyWithImpl<$Res, _$GameOverMessageImpl>
    implements _$$GameOverMessageImplCopyWith<$Res> {
  __$$GameOverMessageImplCopyWithImpl(
      _$GameOverMessageImpl _value, $Res Function(_$GameOverMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? winnerId = null,
    Object? winnerName = null,
  }) {
    return _then(_$GameOverMessageImpl(
      winnerId: null == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String,
      winnerName: null == winnerName
          ? _value.winnerName
          : winnerName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameOverMessageImpl implements GameOverMessage {
  const _$GameOverMessageImpl(
      {required this.winnerId, required this.winnerName, final String? $type})
      : $type = $type ?? 'gameOver';

  factory _$GameOverMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameOverMessageImplFromJson(json);

  @override
  final String winnerId;
  @override
  final String winnerName;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ServerMessage.gameOver(winnerId: $winnerId, winnerName: $winnerName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameOverMessageImpl &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId) &&
            (identical(other.winnerName, winnerName) ||
                other.winnerName == winnerName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, winnerId, winnerName);

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameOverMessageImplCopyWith<_$GameOverMessageImpl> get copyWith =>
      __$$GameOverMessageImplCopyWithImpl<_$GameOverMessageImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(GameState state) gameState,
    required TResult Function(GameState state, String? description) gameUpdate,
    required TResult Function(String code, String message) error,
    required TResult Function() pong,
    required TResult Function(PlayerState player) playerJoined,
    required TResult Function(String playerId) playerLeft,
    required TResult Function(GameState state) gameStarted,
    required TResult Function(String winnerId, String winnerName) gameOver,
  }) {
    return gameOver(winnerId, winnerName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(GameState state)? gameState,
    TResult? Function(GameState state, String? description)? gameUpdate,
    TResult? Function(String code, String message)? error,
    TResult? Function()? pong,
    TResult? Function(PlayerState player)? playerJoined,
    TResult? Function(String playerId)? playerLeft,
    TResult? Function(GameState state)? gameStarted,
    TResult? Function(String winnerId, String winnerName)? gameOver,
  }) {
    return gameOver?.call(winnerId, winnerName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(GameState state)? gameState,
    TResult Function(GameState state, String? description)? gameUpdate,
    TResult Function(String code, String message)? error,
    TResult Function()? pong,
    TResult Function(PlayerState player)? playerJoined,
    TResult Function(String playerId)? playerLeft,
    TResult Function(GameState state)? gameStarted,
    TResult Function(String winnerId, String winnerName)? gameOver,
    required TResult orElse(),
  }) {
    if (gameOver != null) {
      return gameOver(winnerId, winnerName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GameStateMessage value) gameState,
    required TResult Function(GameUpdateMessage value) gameUpdate,
    required TResult Function(ErrorMessage value) error,
    required TResult Function(PongMessage value) pong,
    required TResult Function(PlayerJoinedMessage value) playerJoined,
    required TResult Function(PlayerLeftMessage value) playerLeft,
    required TResult Function(GameStartedMessage value) gameStarted,
    required TResult Function(GameOverMessage value) gameOver,
  }) {
    return gameOver(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GameStateMessage value)? gameState,
    TResult? Function(GameUpdateMessage value)? gameUpdate,
    TResult? Function(ErrorMessage value)? error,
    TResult? Function(PongMessage value)? pong,
    TResult? Function(PlayerJoinedMessage value)? playerJoined,
    TResult? Function(PlayerLeftMessage value)? playerLeft,
    TResult? Function(GameStartedMessage value)? gameStarted,
    TResult? Function(GameOverMessage value)? gameOver,
  }) {
    return gameOver?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GameStateMessage value)? gameState,
    TResult Function(GameUpdateMessage value)? gameUpdate,
    TResult Function(ErrorMessage value)? error,
    TResult Function(PongMessage value)? pong,
    TResult Function(PlayerJoinedMessage value)? playerJoined,
    TResult Function(PlayerLeftMessage value)? playerLeft,
    TResult Function(GameStartedMessage value)? gameStarted,
    TResult Function(GameOverMessage value)? gameOver,
    required TResult orElse(),
  }) {
    if (gameOver != null) {
      return gameOver(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$GameOverMessageImplToJson(
      this,
    );
  }
}

abstract class GameOverMessage implements ServerMessage {
  const factory GameOverMessage(
      {required final String winnerId,
      required final String winnerName}) = _$GameOverMessageImpl;

  factory GameOverMessage.fromJson(Map<String, dynamic> json) =
      _$GameOverMessageImpl.fromJson;

  String get winnerId;
  String get winnerName;

  /// Create a copy of ServerMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameOverMessageImplCopyWith<_$GameOverMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
