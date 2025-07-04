// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drip_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DripState {
  List<DripNFT> get nfts => throw _privateConstructorUsedError;
  String? get equippedId => throw _privateConstructorUsedError;
  bool get loading => throw _privateConstructorUsedError;
  String? get lastEquippedId => throw _privateConstructorUsedError;
  DateTime? get lastEquipTime => throw _privateConstructorUsedError;
  Map<String, bool> get newNftFlags => throw _privateConstructorUsedError;

  /// Create a copy of DripState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DripStateCopyWith<DripState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DripStateCopyWith<$Res> {
  factory $DripStateCopyWith(DripState value, $Res Function(DripState) then) =
      _$DripStateCopyWithImpl<$Res, DripState>;
  @useResult
  $Res call(
      {List<DripNFT> nfts,
      String? equippedId,
      bool loading,
      String? lastEquippedId,
      DateTime? lastEquipTime,
      Map<String, bool> newNftFlags});
}

/// @nodoc
class _$DripStateCopyWithImpl<$Res, $Val extends DripState>
    implements $DripStateCopyWith<$Res> {
  _$DripStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DripState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nfts = null,
    Object? equippedId = freezed,
    Object? loading = null,
    Object? lastEquippedId = freezed,
    Object? lastEquipTime = freezed,
    Object? newNftFlags = null,
  }) {
    return _then(_value.copyWith(
      nfts: null == nfts
          ? _value.nfts
          : nfts // ignore: cast_nullable_to_non_nullable
              as List<DripNFT>,
      equippedId: freezed == equippedId
          ? _value.equippedId
          : equippedId // ignore: cast_nullable_to_non_nullable
              as String?,
      loading: null == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool,
      lastEquippedId: freezed == lastEquippedId
          ? _value.lastEquippedId
          : lastEquippedId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastEquipTime: freezed == lastEquipTime
          ? _value.lastEquipTime
          : lastEquipTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      newNftFlags: null == newNftFlags
          ? _value.newNftFlags
          : newNftFlags // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DripStateImplCopyWith<$Res>
    implements $DripStateCopyWith<$Res> {
  factory _$$DripStateImplCopyWith(
          _$DripStateImpl value, $Res Function(_$DripStateImpl) then) =
      __$$DripStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<DripNFT> nfts,
      String? equippedId,
      bool loading,
      String? lastEquippedId,
      DateTime? lastEquipTime,
      Map<String, bool> newNftFlags});
}

/// @nodoc
class __$$DripStateImplCopyWithImpl<$Res>
    extends _$DripStateCopyWithImpl<$Res, _$DripStateImpl>
    implements _$$DripStateImplCopyWith<$Res> {
  __$$DripStateImplCopyWithImpl(
      _$DripStateImpl _value, $Res Function(_$DripStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DripState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? nfts = null,
    Object? equippedId = freezed,
    Object? loading = null,
    Object? lastEquippedId = freezed,
    Object? lastEquipTime = freezed,
    Object? newNftFlags = null,
  }) {
    return _then(_$DripStateImpl(
      nfts: null == nfts
          ? _value._nfts
          : nfts // ignore: cast_nullable_to_non_nullable
              as List<DripNFT>,
      equippedId: freezed == equippedId
          ? _value.equippedId
          : equippedId // ignore: cast_nullable_to_non_nullable
              as String?,
      loading: null == loading
          ? _value.loading
          : loading // ignore: cast_nullable_to_non_nullable
              as bool,
      lastEquippedId: freezed == lastEquippedId
          ? _value.lastEquippedId
          : lastEquippedId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastEquipTime: freezed == lastEquipTime
          ? _value.lastEquipTime
          : lastEquipTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      newNftFlags: null == newNftFlags
          ? _value._newNftFlags
          : newNftFlags // ignore: cast_nullable_to_non_nullable
              as Map<String, bool>,
    ));
  }
}

/// @nodoc

class _$DripStateImpl implements _DripState {
  const _$DripStateImpl(
      {final List<DripNFT> nfts = const [],
      this.equippedId = null,
      this.loading = false,
      this.lastEquippedId = null,
      this.lastEquipTime = null,
      final Map<String, bool> newNftFlags = const {}})
      : _nfts = nfts,
        _newNftFlags = newNftFlags;

  final List<DripNFT> _nfts;
  @override
  @JsonKey()
  List<DripNFT> get nfts {
    if (_nfts is EqualUnmodifiableListView) return _nfts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nfts);
  }

  @override
  @JsonKey()
  final String? equippedId;
  @override
  @JsonKey()
  final bool loading;
  @override
  @JsonKey()
  final String? lastEquippedId;
  @override
  @JsonKey()
  final DateTime? lastEquipTime;
  final Map<String, bool> _newNftFlags;
  @override
  @JsonKey()
  Map<String, bool> get newNftFlags {
    if (_newNftFlags is EqualUnmodifiableMapView) return _newNftFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_newNftFlags);
  }

  @override
  String toString() {
    return 'DripState(nfts: $nfts, equippedId: $equippedId, loading: $loading, lastEquippedId: $lastEquippedId, lastEquipTime: $lastEquipTime, newNftFlags: $newNftFlags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DripStateImpl &&
            const DeepCollectionEquality().equals(other._nfts, _nfts) &&
            (identical(other.equippedId, equippedId) ||
                other.equippedId == equippedId) &&
            (identical(other.loading, loading) || other.loading == loading) &&
            (identical(other.lastEquippedId, lastEquippedId) ||
                other.lastEquippedId == lastEquippedId) &&
            (identical(other.lastEquipTime, lastEquipTime) ||
                other.lastEquipTime == lastEquipTime) &&
            const DeepCollectionEquality()
                .equals(other._newNftFlags, _newNftFlags));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_nfts),
      equippedId,
      loading,
      lastEquippedId,
      lastEquipTime,
      const DeepCollectionEquality().hash(_newNftFlags));

  /// Create a copy of DripState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DripStateImplCopyWith<_$DripStateImpl> get copyWith =>
      __$$DripStateImplCopyWithImpl<_$DripStateImpl>(this, _$identity);
}

abstract class _DripState implements DripState {
  const factory _DripState(
      {final List<DripNFT> nfts,
      final String? equippedId,
      final bool loading,
      final String? lastEquippedId,
      final DateTime? lastEquipTime,
      final Map<String, bool> newNftFlags}) = _$DripStateImpl;

  @override
  List<DripNFT> get nfts;
  @override
  String? get equippedId;
  @override
  bool get loading;
  @override
  String? get lastEquippedId;
  @override
  DateTime? get lastEquipTime;
  @override
  Map<String, bool> get newNftFlags;

  /// Create a copy of DripState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DripStateImplCopyWith<_$DripStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
