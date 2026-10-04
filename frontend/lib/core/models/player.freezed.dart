// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerState _$PlayerStateFromJson(Map<String, dynamic> json) {
  return _PlayerState.fromJson(json);
}

/// @nodoc
mixin _$PlayerState {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get cardCount => throw _privateConstructorUsedError;
  bool get isBot => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;
  bool get hasCalledLastCard => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;

  /// Serializes this PlayerState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerStateCopyWith<PlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStateCopyWith<$Res> {
  factory $PlayerStateCopyWith(
          PlayerState value, $Res Function(PlayerState) then) =
      _$PlayerStateCopyWithImpl<$Res, PlayerState>;
  @useResult
  $Res call(
      {String id,
      String name,
      int cardCount,
      bool isBot,
      bool isConnected,
      bool hasCalledLastCard,
      String? avatarUrl});
}

/// @nodoc
class _$PlayerStateCopyWithImpl<$Res, $Val extends PlayerState>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? cardCount = null,
    Object? isBot = null,
    Object? isConnected = null,
    Object? hasCalledLastCard = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      cardCount: null == cardCount
          ? _value.cardCount
          : cardCount // ignore: cast_nullable_to_non_nullable
              as int,
      isBot: null == isBot
          ? _value.isBot
          : isBot // ignore: cast_nullable_to_non_nullable
              as bool,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCalledLastCard: null == hasCalledLastCard
          ? _value.hasCalledLastCard
          : hasCalledLastCard // ignore: cast_nullable_to_non_nullable
              as bool,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerStateImplCopyWith<$Res>
    implements $PlayerStateCopyWith<$Res> {
  factory _$$PlayerStateImplCopyWith(
          _$PlayerStateImpl value, $Res Function(_$PlayerStateImpl) then) =
      __$$PlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int cardCount,
      bool isBot,
      bool isConnected,
      bool hasCalledLastCard,
      String? avatarUrl});
}

/// @nodoc
class __$$PlayerStateImplCopyWithImpl<$Res>
    extends _$PlayerStateCopyWithImpl<$Res, _$PlayerStateImpl>
    implements _$$PlayerStateImplCopyWith<$Res> {
  __$$PlayerStateImplCopyWithImpl(
      _$PlayerStateImpl _value, $Res Function(_$PlayerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? cardCount = null,
    Object? isBot = null,
    Object? isConnected = null,
    Object? hasCalledLastCard = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$PlayerStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      cardCount: null == cardCount
          ? _value.cardCount
          : cardCount // ignore: cast_nullable_to_non_nullable
              as int,
      isBot: null == isBot
          ? _value.isBot
          : isBot // ignore: cast_nullable_to_non_nullable
              as bool,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      hasCalledLastCard: null == hasCalledLastCard
          ? _value.hasCalledLastCard
          : hasCalledLastCard // ignore: cast_nullable_to_non_nullable
              as bool,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerStateImpl implements _PlayerState {
  const _$PlayerStateImpl(
      {required this.id,
      required this.name,
      required this.cardCount,
      this.isBot = false,
      this.isConnected = true,
      this.hasCalledLastCard = false,
      this.avatarUrl});

  factory _$PlayerStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerStateImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int cardCount;
  @override
  @JsonKey()
  final bool isBot;
  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final bool hasCalledLastCard;
  @override
  final String? avatarUrl;

  @override
  String toString() {
    return 'PlayerState(id: $id, name: $name, cardCount: $cardCount, isBot: $isBot, isConnected: $isConnected, hasCalledLastCard: $hasCalledLastCard, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.cardCount, cardCount) ||
                other.cardCount == cardCount) &&
            (identical(other.isBot, isBot) || other.isBot == isBot) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.hasCalledLastCard, hasCalledLastCard) ||
                other.hasCalledLastCard == hasCalledLastCard) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, cardCount, isBot,
      isConnected, hasCalledLastCard, avatarUrl);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      __$$PlayerStateImplCopyWithImpl<_$PlayerStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerStateImplToJson(
      this,
    );
  }
}

abstract class _PlayerState implements PlayerState {
  const factory _PlayerState(
      {required final String id,
      required final String name,
      required final int cardCount,
      final bool isBot,
      final bool isConnected,
      final bool hasCalledLastCard,
      final String? avatarUrl}) = _$PlayerStateImpl;

  factory _PlayerState.fromJson(Map<String, dynamic> json) =
      _$PlayerStateImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  int get cardCount;
  @override
  bool get isBot;
  @override
  bool get isConnected;
  @override
  bool get hasCalledLastCard;
  @override
  String? get avatarUrl;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
