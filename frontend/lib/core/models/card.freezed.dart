// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WildCard _$WildCardFromJson(Map<String, dynamic> json) {
  return _WildCard.fromJson(json);
}

/// @nodoc
mixin _$WildCard {
  String get id => throw _privateConstructorUsedError;
  CardColor get color => throw _privateConstructorUsedError;
  CardType get type => throw _privateConstructorUsedError;
  int? get value => throw _privateConstructorUsedError;

  /// Serializes this WildCard to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WildCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WildCardCopyWith<WildCard> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WildCardCopyWith<$Res> {
  factory $WildCardCopyWith(WildCard value, $Res Function(WildCard) then) =
      _$WildCardCopyWithImpl<$Res, WildCard>;
  @useResult
  $Res call({String id, CardColor color, CardType type, int? value});
}

/// @nodoc
class _$WildCardCopyWithImpl<$Res, $Val extends WildCard>
    implements $WildCardCopyWith<$Res> {
  _$WildCardCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WildCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? color = null,
    Object? type = null,
    Object? value = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as CardColor,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CardType,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WildCardImplCopyWith<$Res>
    implements $WildCardCopyWith<$Res> {
  factory _$$WildCardImplCopyWith(
          _$WildCardImpl value, $Res Function(_$WildCardImpl) then) =
      __$$WildCardImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, CardColor color, CardType type, int? value});
}

/// @nodoc
class __$$WildCardImplCopyWithImpl<$Res>
    extends _$WildCardCopyWithImpl<$Res, _$WildCardImpl>
    implements _$$WildCardImplCopyWith<$Res> {
  __$$WildCardImplCopyWithImpl(
      _$WildCardImpl _value, $Res Function(_$WildCardImpl) _then)
      : super(_value, _then);

  /// Create a copy of WildCard
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? color = null,
    Object? type = null,
    Object? value = freezed,
  }) {
    return _then(_$WildCardImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as CardColor,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CardType,
      value: freezed == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WildCardImpl implements _WildCard {
  const _$WildCardImpl(
      {required this.id, required this.color, required this.type, this.value});

  factory _$WildCardImpl.fromJson(Map<String, dynamic> json) =>
      _$$WildCardImplFromJson(json);

  @override
  final String id;
  @override
  final CardColor color;
  @override
  final CardType type;
  @override
  final int? value;

  @override
  String toString() {
    return 'WildCard(id: $id, color: $color, type: $type, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WildCardImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.value, value) || other.value == value));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, color, type, value);

  /// Create a copy of WildCard
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WildCardImplCopyWith<_$WildCardImpl> get copyWith =>
      __$$WildCardImplCopyWithImpl<_$WildCardImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WildCardImplToJson(
      this,
    );
  }
}

abstract class _WildCard implements WildCard {
  const factory _WildCard(
      {required final String id,
      required final CardColor color,
      required final CardType type,
      final int? value}) = _$WildCardImpl;

  factory _WildCard.fromJson(Map<String, dynamic> json) =
      _$WildCardImpl.fromJson;

  @override
  String get id;
  @override
  CardColor get color;
  @override
  CardType get type;
  @override
  int? get value;

  /// Create a copy of WildCard
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WildCardImplCopyWith<_$WildCardImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
