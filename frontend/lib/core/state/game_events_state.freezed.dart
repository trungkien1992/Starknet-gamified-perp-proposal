// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_events_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GameEventsState {
  List<GameEvent> get recentEvents => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;
  String? get lastError => throw _privateConstructorUsedError;
  DateTime? get lastEventTime => throw _privateConstructorUsedError;
  int get totalEventsReceived => throw _privateConstructorUsedError;

  /// Create a copy of GameEventsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameEventsStateCopyWith<GameEventsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameEventsStateCopyWith<$Res> {
  factory $GameEventsStateCopyWith(
    GameEventsState value,
    $Res Function(GameEventsState) then,
  ) = _$GameEventsStateCopyWithImpl<$Res, GameEventsState>;
  @useResult
  $Res call({
    List<GameEvent> recentEvents,
    bool isConnected,
    String? lastError,
    DateTime? lastEventTime,
    int totalEventsReceived,
  });
}

/// @nodoc
class _$GameEventsStateCopyWithImpl<$Res, $Val extends GameEventsState>
    implements $GameEventsStateCopyWith<$Res> {
  _$GameEventsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GameEventsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recentEvents = null,
    Object? isConnected = null,
    Object? lastError = freezed,
    Object? lastEventTime = freezed,
    Object? totalEventsReceived = null,
  }) {
    return _then(
      _value.copyWith(
            recentEvents: null == recentEvents
                ? _value.recentEvents
                : recentEvents // ignore: cast_nullable_to_non_nullable
                      as List<GameEvent>,
            isConnected: null == isConnected
                ? _value.isConnected
                : isConnected // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastEventTime: freezed == lastEventTime
                ? _value.lastEventTime
                : lastEventTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            totalEventsReceived: null == totalEventsReceived
                ? _value.totalEventsReceived
                : totalEventsReceived // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameEventsStateImplCopyWith<$Res>
    implements $GameEventsStateCopyWith<$Res> {
  factory _$$GameEventsStateImplCopyWith(
    _$GameEventsStateImpl value,
    $Res Function(_$GameEventsStateImpl) then,
  ) = __$$GameEventsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<GameEvent> recentEvents,
    bool isConnected,
    String? lastError,
    DateTime? lastEventTime,
    int totalEventsReceived,
  });
}

/// @nodoc
class __$$GameEventsStateImplCopyWithImpl<$Res>
    extends _$GameEventsStateCopyWithImpl<$Res, _$GameEventsStateImpl>
    implements _$$GameEventsStateImplCopyWith<$Res> {
  __$$GameEventsStateImplCopyWithImpl(
    _$GameEventsStateImpl _value,
    $Res Function(_$GameEventsStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GameEventsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recentEvents = null,
    Object? isConnected = null,
    Object? lastError = freezed,
    Object? lastEventTime = freezed,
    Object? totalEventsReceived = null,
  }) {
    return _then(
      _$GameEventsStateImpl(
        recentEvents: null == recentEvents
            ? _value._recentEvents
            : recentEvents // ignore: cast_nullable_to_non_nullable
                  as List<GameEvent>,
        isConnected: null == isConnected
            ? _value.isConnected
            : isConnected // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastEventTime: freezed == lastEventTime
            ? _value.lastEventTime
            : lastEventTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        totalEventsReceived: null == totalEventsReceived
            ? _value.totalEventsReceived
            : totalEventsReceived // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$GameEventsStateImpl implements _GameEventsState {
  const _$GameEventsStateImpl({
    final List<GameEvent> recentEvents = const [],
    this.isConnected = false,
    this.lastError = null,
    this.lastEventTime = null,
    this.totalEventsReceived = 0,
  }) : _recentEvents = recentEvents;

  final List<GameEvent> _recentEvents;
  @override
  @JsonKey()
  List<GameEvent> get recentEvents {
    if (_recentEvents is EqualUnmodifiableListView) return _recentEvents;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recentEvents);
  }

  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final String? lastError;
  @override
  @JsonKey()
  final DateTime? lastEventTime;
  @override
  @JsonKey()
  final int totalEventsReceived;

  @override
  String toString() {
    return 'GameEventsState(recentEvents: $recentEvents, isConnected: $isConnected, lastError: $lastError, lastEventTime: $lastEventTime, totalEventsReceived: $totalEventsReceived)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameEventsStateImpl &&
            const DeepCollectionEquality().equals(
              other._recentEvents,
              _recentEvents,
            ) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError) &&
            (identical(other.lastEventTime, lastEventTime) ||
                other.lastEventTime == lastEventTime) &&
            (identical(other.totalEventsReceived, totalEventsReceived) ||
                other.totalEventsReceived == totalEventsReceived));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_recentEvents),
    isConnected,
    lastError,
    lastEventTime,
    totalEventsReceived,
  );

  /// Create a copy of GameEventsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameEventsStateImplCopyWith<_$GameEventsStateImpl> get copyWith =>
      __$$GameEventsStateImplCopyWithImpl<_$GameEventsStateImpl>(
        this,
        _$identity,
      );
}

abstract class _GameEventsState implements GameEventsState {
  const factory _GameEventsState({
    final List<GameEvent> recentEvents,
    final bool isConnected,
    final String? lastError,
    final DateTime? lastEventTime,
    final int totalEventsReceived,
  }) = _$GameEventsStateImpl;

  @override
  List<GameEvent> get recentEvents;
  @override
  bool get isConnected;
  @override
  String? get lastError;
  @override
  DateTime? get lastEventTime;
  @override
  int get totalEventsReceived;

  /// Create a copy of GameEventsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameEventsStateImplCopyWith<_$GameEventsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
