// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameState _$GameStateFromJson(Map<String, dynamic> json) {
  return _GameState.fromJson(json);
}

/// @nodoc
mixin _$GameState {
  String get gameId => throw _privateConstructorUsedError;
  String get currentPlayerId => throw _privateConstructorUsedError;
  List<PlayerState> get players => throw _privateConstructorUsedError;
  List<WildCard> get hand => throw _privateConstructorUsedError;
  WildCard? get topCard => throw _privateConstructorUsedError;
  CardColor? get activeColor => throw _privateConstructorUsedError;
  bool get isClockwise => throw _privateConstructorUsedError;
  GameStatus get status => throw _privateConstructorUsedError;
  String? get winnerId => throw _privateConstructorUsedError;

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameStateCopyWith<GameState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStateCopyWith<$Res> {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) then) =
      _$GameStateCopyWithImpl<$Res, GameState>;
  @useResult
  $Res call(
      {String gameId,
      String currentPlayerId,
      List<PlayerState> players,
      List<WildCard> hand,
      WildCard? topCard,
      CardColor? activeColor,
      bool isClockwise,
      GameStatus status,
      String? winnerId});

  $WildCardCopyWith<$Res>? get topCard;
}

/// @nodoc
class _$GameStateCopyWithImpl<$Res, $Val extends GameState>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? currentPlayerId = null,
    Object? players = null,
    Object? hand = null,
    Object? topCard = freezed,
    Object? activeColor = freezed,
    Object? isClockwise = null,
    Object? status = null,
    Object? winnerId = freezed,
  }) {
    return _then(_value.copyWith(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      currentPlayerId: null == currentPlayerId
          ? _value.currentPlayerId
          : currentPlayerId // ignore: cast_nullable_to_non_nullable
              as String,
      players: null == players
          ? _value.players
          : players // ignore: cast_nullable_to_non_nullable
              as List<PlayerState>,
      hand: null == hand
          ? _value.hand
          : hand // ignore: cast_nullable_to_non_nullable
              as List<WildCard>,
      topCard: freezed == topCard
          ? _value.topCard
          : topCard // ignore: cast_nullable_to_non_nullable
              as WildCard?,
      activeColor: freezed == activeColor
          ? _value.activeColor
          : activeColor // ignore: cast_nullable_to_non_nullable
              as CardColor?,
      isClockwise: null == isClockwise
          ? _value.isClockwise
          : isClockwise // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GameStatus,
      winnerId: freezed == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WildCardCopyWith<$Res>? get topCard {
    if (_value.topCard == null) {
      return null;
    }

    return $WildCardCopyWith<$Res>(_value.topCard!, (value) {
      return _then(_value.copyWith(topCard: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GameStateImplCopyWith<$Res>
    implements $GameStateCopyWith<$Res> {
  factory _$$GameStateImplCopyWith(
          _$GameStateImpl value, $Res Function(_$GameStateImpl) then) =
      __$$GameStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String gameId,
      String currentPlayerId,
      List<PlayerState> players,
      List<WildCard> hand,
      WildCard? topCard,
      CardColor? activeColor,
      bool isClockwise,
      GameStatus status,
      String? winnerId});

  @override
  $WildCardCopyWith<$Res>? get topCard;
}

/// @nodoc
class __$$GameStateImplCopyWithImpl<$Res>
    extends _$GameStateCopyWithImpl<$Res, _$GameStateImpl>
    implements _$$GameStateImplCopyWith<$Res> {
  __$$GameStateImplCopyWithImpl(
      _$GameStateImpl _value, $Res Function(_$GameStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? currentPlayerId = null,
    Object? players = null,
    Object? hand = null,
    Object? topCard = freezed,
    Object? activeColor = freezed,
    Object? isClockwise = null,
    Object? status = null,
    Object? winnerId = freezed,
  }) {
    return _then(_$GameStateImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      currentPlayerId: null == currentPlayerId
          ? _value.currentPlayerId
          : currentPlayerId // ignore: cast_nullable_to_non_nullable
              as String,
      players: null == players
          ? _value._players
          : players // ignore: cast_nullable_to_non_nullable
              as List<PlayerState>,
      hand: null == hand
          ? _value._hand
          : hand // ignore: cast_nullable_to_non_nullable
              as List<WildCard>,
      topCard: freezed == topCard
          ? _value.topCard
          : topCard // ignore: cast_nullable_to_non_nullable
              as WildCard?,
      activeColor: freezed == activeColor
          ? _value.activeColor
          : activeColor // ignore: cast_nullable_to_non_nullable
              as CardColor?,
      isClockwise: null == isClockwise
          ? _value.isClockwise
          : isClockwise // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as GameStatus,
      winnerId: freezed == winnerId
          ? _value.winnerId
          : winnerId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStateImpl extends _GameState {
  const _$GameStateImpl(
      {required this.gameId,
      required this.currentPlayerId,
      required final List<PlayerState> players,
      required final List<WildCard> hand,
      this.topCard,
      this.activeColor,
      this.isClockwise = true,
      this.status = GameStatus.waiting,
      this.winnerId})
      : _players = players,
        _hand = hand,
        super._();

  factory _$GameStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStateImplFromJson(json);

  @override
  final String gameId;
  @override
  final String currentPlayerId;
  final List<PlayerState> _players;
  @override
  List<PlayerState> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  final List<WildCard> _hand;
  @override
  List<WildCard> get hand {
    if (_hand is EqualUnmodifiableListView) return _hand;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hand);
  }

  @override
  final WildCard? topCard;
  @override
  final CardColor? activeColor;
  @override
  @JsonKey()
  final bool isClockwise;
  @override
  @JsonKey()
  final GameStatus status;
  @override
  final String? winnerId;

  @override
  String toString() {
    return 'GameState(gameId: $gameId, currentPlayerId: $currentPlayerId, players: $players, hand: $hand, topCard: $topCard, activeColor: $activeColor, isClockwise: $isClockwise, status: $status, winnerId: $winnerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStateImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.currentPlayerId, currentPlayerId) ||
                other.currentPlayerId == currentPlayerId) &&
            const DeepCollectionEquality().equals(other._players, _players) &&
            const DeepCollectionEquality().equals(other._hand, _hand) &&
            (identical(other.topCard, topCard) || other.topCard == topCard) &&
            (identical(other.activeColor, activeColor) ||
                other.activeColor == activeColor) &&
            (identical(other.isClockwise, isClockwise) ||
                other.isClockwise == isClockwise) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.winnerId, winnerId) ||
                other.winnerId == winnerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      gameId,
      currentPlayerId,
      const DeepCollectionEquality().hash(_players),
      const DeepCollectionEquality().hash(_hand),
      topCard,
      activeColor,
      isClockwise,
      status,
      winnerId);

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      __$$GameStateImplCopyWithImpl<_$GameStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStateImplToJson(
      this,
    );
  }
}

abstract class _GameState extends GameState {
  const factory _GameState(
      {required final String gameId,
      required final String currentPlayerId,
      required final List<PlayerState> players,
      required final List<WildCard> hand,
      final WildCard? topCard,
      final CardColor? activeColor,
      final bool isClockwise,
      final GameStatus status,
      final String? winnerId}) = _$GameStateImpl;
  const _GameState._() : super._();

  factory _GameState.fromJson(Map<String, dynamic> json) =
      _$GameStateImpl.fromJson;

  @override
  String get gameId;
  @override
  String get currentPlayerId;
  @override
  List<PlayerState> get players;
  @override
  List<WildCard> get hand;
  @override
  WildCard? get topCard;
  @override
  CardColor? get activeColor;
  @override
  bool get isClockwise;
  @override
  GameStatus get status;
  @override
  String? get winnerId;

  /// Create a copy of GameState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameStateImplCopyWith<_$GameStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
