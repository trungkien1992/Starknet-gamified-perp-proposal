// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reward_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RewardState {
  int get xpGained => throw _privateConstructorUsedError;
  String? get nftName => throw _privateConstructorUsedError;
  bool get show => throw _privateConstructorUsedError;
  DateTime? get showTimestamp => throw _privateConstructorUsedError;
  RewardType get type => throw _privateConstructorUsedError;

  /// Create a copy of RewardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RewardStateCopyWith<RewardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RewardStateCopyWith<$Res> {
  factory $RewardStateCopyWith(
    RewardState value,
    $Res Function(RewardState) then,
  ) = _$RewardStateCopyWithImpl<$Res, RewardState>;
  @useResult
  $Res call({
    int xpGained,
    String? nftName,
    bool show,
    DateTime? showTimestamp,
    RewardType type,
  });
}

/// @nodoc
class _$RewardStateCopyWithImpl<$Res, $Val extends RewardState>
    implements $RewardStateCopyWith<$Res> {
  _$RewardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RewardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? xpGained = null,
    Object? nftName = freezed,
    Object? show = null,
    Object? showTimestamp = freezed,
    Object? type = null,
  }) {
    return _then(
      _value.copyWith(
            xpGained: null == xpGained
                ? _value.xpGained
                : xpGained // ignore: cast_nullable_to_non_nullable
                      as int,
            nftName: freezed == nftName
                ? _value.nftName
                : nftName // ignore: cast_nullable_to_non_nullable
                      as String?,
            show: null == show
                ? _value.show
                : show // ignore: cast_nullable_to_non_nullable
                      as bool,
            showTimestamp: freezed == showTimestamp
                ? _value.showTimestamp
                : showTimestamp // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as RewardType,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RewardStateImplCopyWith<$Res>
    implements $RewardStateCopyWith<$Res> {
  factory _$$RewardStateImplCopyWith(
    _$RewardStateImpl value,
    $Res Function(_$RewardStateImpl) then,
  ) = __$$RewardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int xpGained,
    String? nftName,
    bool show,
    DateTime? showTimestamp,
    RewardType type,
  });
}

/// @nodoc
class __$$RewardStateImplCopyWithImpl<$Res>
    extends _$RewardStateCopyWithImpl<$Res, _$RewardStateImpl>
    implements _$$RewardStateImplCopyWith<$Res> {
  __$$RewardStateImplCopyWithImpl(
    _$RewardStateImpl _value,
    $Res Function(_$RewardStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RewardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? xpGained = null,
    Object? nftName = freezed,
    Object? show = null,
    Object? showTimestamp = freezed,
    Object? type = null,
  }) {
    return _then(
      _$RewardStateImpl(
        xpGained: null == xpGained
            ? _value.xpGained
            : xpGained // ignore: cast_nullable_to_non_nullable
                  as int,
        nftName: freezed == nftName
            ? _value.nftName
            : nftName // ignore: cast_nullable_to_non_nullable
                  as String?,
        show: null == show
            ? _value.show
            : show // ignore: cast_nullable_to_non_nullable
                  as bool,
        showTimestamp: freezed == showTimestamp
            ? _value.showTimestamp
            : showTimestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as RewardType,
      ),
    );
  }
}

/// @nodoc

class _$RewardStateImpl implements _RewardState {
  const _$RewardStateImpl({
    this.xpGained = 0,
    this.nftName = null,
    this.show = false,
    this.showTimestamp = null,
    this.type = RewardType.none,
  });

  @override
  @JsonKey()
  final int xpGained;
  @override
  @JsonKey()
  final String? nftName;
  @override
  @JsonKey()
  final bool show;
  @override
  @JsonKey()
  final DateTime? showTimestamp;
  @override
  @JsonKey()
  final RewardType type;

  @override
  String toString() {
    return 'RewardState(xpGained: $xpGained, nftName: $nftName, show: $show, showTimestamp: $showTimestamp, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RewardStateImpl &&
            (identical(other.xpGained, xpGained) ||
                other.xpGained == xpGained) &&
            (identical(other.nftName, nftName) || other.nftName == nftName) &&
            (identical(other.show, show) || other.show == show) &&
            (identical(other.showTimestamp, showTimestamp) ||
                other.showTimestamp == showTimestamp) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, xpGained, nftName, show, showTimestamp, type);

  /// Create a copy of RewardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RewardStateImplCopyWith<_$RewardStateImpl> get copyWith =>
      __$$RewardStateImplCopyWithImpl<_$RewardStateImpl>(this, _$identity);
}

abstract class _RewardState implements RewardState {
  const factory _RewardState({
    final int xpGained,
    final String? nftName,
    final bool show,
    final DateTime? showTimestamp,
    final RewardType type,
  }) = _$RewardStateImpl;

  @override
  int get xpGained;
  @override
  String? get nftName;
  @override
  bool get show;
  @override
  DateTime? get showTimestamp;
  @override
  RewardType get type;

  /// Create a copy of RewardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RewardStateImplCopyWith<_$RewardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
