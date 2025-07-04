// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WalletUser _$WalletUserFromJson(Map<String, dynamic> json) {
  return _WalletUser.fromJson(json);
}

/// @nodoc
mixin _$WalletUser {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get profileImage => throw _privateConstructorUsedError;
  AuthProvider get provider => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WalletUser to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletUserCopyWith<WalletUser> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletUserCopyWith<$Res> {
  factory $WalletUserCopyWith(
          WalletUser value, $Res Function(WalletUser) then) =
      _$WalletUserCopyWithImpl<$Res, WalletUser>;
  @useResult
  $Res call(
      {String id,
      String email,
      String name,
      String? profileImage,
      AuthProvider provider,
      DateTime createdAt});
}

/// @nodoc
class _$WalletUserCopyWithImpl<$Res, $Val extends WalletUser>
    implements $WalletUserCopyWith<$Res> {
  _$WalletUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? profileImage = freezed,
    Object? provider = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as AuthProvider,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletUserImplCopyWith<$Res>
    implements $WalletUserCopyWith<$Res> {
  factory _$$WalletUserImplCopyWith(
          _$WalletUserImpl value, $Res Function(_$WalletUserImpl) then) =
      __$$WalletUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      String name,
      String? profileImage,
      AuthProvider provider,
      DateTime createdAt});
}

/// @nodoc
class __$$WalletUserImplCopyWithImpl<$Res>
    extends _$WalletUserCopyWithImpl<$Res, _$WalletUserImpl>
    implements _$$WalletUserImplCopyWith<$Res> {
  __$$WalletUserImplCopyWithImpl(
      _$WalletUserImpl _value, $Res Function(_$WalletUserImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletUser
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? name = null,
    Object? profileImage = freezed,
    Object? provider = null,
    Object? createdAt = null,
  }) {
    return _then(_$WalletUserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      profileImage: freezed == profileImage
          ? _value.profileImage
          : profileImage // ignore: cast_nullable_to_non_nullable
              as String?,
      provider: null == provider
          ? _value.provider
          : provider // ignore: cast_nullable_to_non_nullable
              as AuthProvider,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletUserImpl implements _WalletUser {
  const _$WalletUserImpl(
      {required this.id,
      required this.email,
      required this.name,
      this.profileImage,
      required this.provider,
      required this.createdAt});

  factory _$WalletUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletUserImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  final String name;
  @override
  final String? profileImage;
  @override
  final AuthProvider provider;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WalletUser(id: $id, email: $email, name: $name, profileImage: $profileImage, provider: $provider, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletUserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.profileImage, profileImage) ||
                other.profileImage == profileImage) &&
            (identical(other.provider, provider) ||
                other.provider == provider) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, email, name, profileImage, provider, createdAt);

  /// Create a copy of WalletUser
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletUserImplCopyWith<_$WalletUserImpl> get copyWith =>
      __$$WalletUserImplCopyWithImpl<_$WalletUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletUserImplToJson(
      this,
    );
  }
}

abstract class _WalletUser implements WalletUser {
  const factory _WalletUser(
      {required final String id,
      required final String email,
      required final String name,
      final String? profileImage,
      required final AuthProvider provider,
      required final DateTime createdAt}) = _$WalletUserImpl;

  factory _WalletUser.fromJson(Map<String, dynamic> json) =
      _$WalletUserImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  String get name;
  @override
  String? get profileImage;
  @override
  AuthProvider get provider;
  @override
  DateTime get createdAt;

  /// Create a copy of WalletUser
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletUserImplCopyWith<_$WalletUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StarknetWallet _$StarknetWalletFromJson(Map<String, dynamic> json) {
  return _StarknetWallet.fromJson(json);
}

/// @nodoc
mixin _$StarknetWallet {
  String get address => throw _privateConstructorUsedError;
  String get privateKey => throw _privateConstructorUsedError;
  String get publicKey => throw _privateConstructorUsedError;
  String get chainId => throw _privateConstructorUsedError;
  DateTime? get lastUsed => throw _privateConstructorUsedError;

  /// Serializes this StarknetWallet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StarknetWallet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StarknetWalletCopyWith<StarknetWallet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StarknetWalletCopyWith<$Res> {
  factory $StarknetWalletCopyWith(
          StarknetWallet value, $Res Function(StarknetWallet) then) =
      _$StarknetWalletCopyWithImpl<$Res, StarknetWallet>;
  @useResult
  $Res call(
      {String address,
      String privateKey,
      String publicKey,
      String chainId,
      DateTime? lastUsed});
}

/// @nodoc
class _$StarknetWalletCopyWithImpl<$Res, $Val extends StarknetWallet>
    implements $StarknetWalletCopyWith<$Res> {
  _$StarknetWalletCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StarknetWallet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? privateKey = null,
    Object? publicKey = null,
    Object? chainId = null,
    Object? lastUsed = freezed,
  }) {
    return _then(_value.copyWith(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      privateKey: null == privateKey
          ? _value.privateKey
          : privateKey // ignore: cast_nullable_to_non_nullable
              as String,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsed: freezed == lastUsed
          ? _value.lastUsed
          : lastUsed // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StarknetWalletImplCopyWith<$Res>
    implements $StarknetWalletCopyWith<$Res> {
  factory _$$StarknetWalletImplCopyWith(_$StarknetWalletImpl value,
          $Res Function(_$StarknetWalletImpl) then) =
      __$$StarknetWalletImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String address,
      String privateKey,
      String publicKey,
      String chainId,
      DateTime? lastUsed});
}

/// @nodoc
class __$$StarknetWalletImplCopyWithImpl<$Res>
    extends _$StarknetWalletCopyWithImpl<$Res, _$StarknetWalletImpl>
    implements _$$StarknetWalletImplCopyWith<$Res> {
  __$$StarknetWalletImplCopyWithImpl(
      _$StarknetWalletImpl _value, $Res Function(_$StarknetWalletImpl) _then)
      : super(_value, _then);

  /// Create a copy of StarknetWallet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? address = null,
    Object? privateKey = null,
    Object? publicKey = null,
    Object? chainId = null,
    Object? lastUsed = freezed,
  }) {
    return _then(_$StarknetWalletImpl(
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      privateKey: null == privateKey
          ? _value.privateKey
          : privateKey // ignore: cast_nullable_to_non_nullable
              as String,
      publicKey: null == publicKey
          ? _value.publicKey
          : publicKey // ignore: cast_nullable_to_non_nullable
              as String,
      chainId: null == chainId
          ? _value.chainId
          : chainId // ignore: cast_nullable_to_non_nullable
              as String,
      lastUsed: freezed == lastUsed
          ? _value.lastUsed
          : lastUsed // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StarknetWalletImpl implements _StarknetWallet {
  const _$StarknetWalletImpl(
      {required this.address,
      required this.privateKey,
      required this.publicKey,
      required this.chainId,
      this.lastUsed});

  factory _$StarknetWalletImpl.fromJson(Map<String, dynamic> json) =>
      _$$StarknetWalletImplFromJson(json);

  @override
  final String address;
  @override
  final String privateKey;
  @override
  final String publicKey;
  @override
  final String chainId;
  @override
  final DateTime? lastUsed;

  @override
  String toString() {
    return 'StarknetWallet(address: $address, privateKey: $privateKey, publicKey: $publicKey, chainId: $chainId, lastUsed: $lastUsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StarknetWalletImpl &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.privateKey, privateKey) ||
                other.privateKey == privateKey) &&
            (identical(other.publicKey, publicKey) ||
                other.publicKey == publicKey) &&
            (identical(other.chainId, chainId) || other.chainId == chainId) &&
            (identical(other.lastUsed, lastUsed) ||
                other.lastUsed == lastUsed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, address, privateKey, publicKey, chainId, lastUsed);

  /// Create a copy of StarknetWallet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StarknetWalletImplCopyWith<_$StarknetWalletImpl> get copyWith =>
      __$$StarknetWalletImplCopyWithImpl<_$StarknetWalletImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StarknetWalletImplToJson(
      this,
    );
  }
}

abstract class _StarknetWallet implements StarknetWallet {
  const factory _StarknetWallet(
      {required final String address,
      required final String privateKey,
      required final String publicKey,
      required final String chainId,
      final DateTime? lastUsed}) = _$StarknetWalletImpl;

  factory _StarknetWallet.fromJson(Map<String, dynamic> json) =
      _$StarknetWalletImpl.fromJson;

  @override
  String get address;
  @override
  String get privateKey;
  @override
  String get publicKey;
  @override
  String get chainId;
  @override
  DateTime? get lastUsed;

  /// Create a copy of StarknetWallet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StarknetWalletImplCopyWith<_$StarknetWalletImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WalletAuthState _$WalletAuthStateFromJson(Map<String, dynamic> json) {
  return _WalletAuthState.fromJson(json);
}

/// @nodoc
mixin _$WalletAuthState {
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get isAuthenticated => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isConnectingWallet => throw _privateConstructorUsedError;
  WalletUser? get user => throw _privateConstructorUsedError;
  StarknetWallet? get wallet => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  AuthProvider? get currentProvider => throw _privateConstructorUsedError;

  /// Serializes this WalletAuthState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletAuthStateCopyWith<WalletAuthState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletAuthStateCopyWith<$Res> {
  factory $WalletAuthStateCopyWith(
          WalletAuthState value, $Res Function(WalletAuthState) then) =
      _$WalletAuthStateCopyWithImpl<$Res, WalletAuthState>;
  @useResult
  $Res call(
      {bool isInitialized,
      bool isAuthenticated,
      bool isLoading,
      bool isConnectingWallet,
      WalletUser? user,
      StarknetWallet? wallet,
      String? error,
      AuthProvider? currentProvider});

  $WalletUserCopyWith<$Res>? get user;
  $StarknetWalletCopyWith<$Res>? get wallet;
}

/// @nodoc
class _$WalletAuthStateCopyWithImpl<$Res, $Val extends WalletAuthState>
    implements $WalletAuthStateCopyWith<$Res> {
  _$WalletAuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isAuthenticated = null,
    Object? isLoading = null,
    Object? isConnectingWallet = null,
    Object? user = freezed,
    Object? wallet = freezed,
    Object? error = freezed,
    Object? currentProvider = freezed,
  }) {
    return _then(_value.copyWith(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isAuthenticated: null == isAuthenticated
          ? _value.isAuthenticated
          : isAuthenticated // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isConnectingWallet: null == isConnectingWallet
          ? _value.isConnectingWallet
          : isConnectingWallet // ignore: cast_nullable_to_non_nullable
              as bool,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as WalletUser?,
      wallet: freezed == wallet
          ? _value.wallet
          : wallet // ignore: cast_nullable_to_non_nullable
              as StarknetWallet?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      currentProvider: freezed == currentProvider
          ? _value.currentProvider
          : currentProvider // ignore: cast_nullable_to_non_nullable
              as AuthProvider?,
    ) as $Val);
  }

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WalletUserCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $WalletUserCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StarknetWalletCopyWith<$Res>? get wallet {
    if (_value.wallet == null) {
      return null;
    }

    return $StarknetWalletCopyWith<$Res>(_value.wallet!, (value) {
      return _then(_value.copyWith(wallet: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WalletAuthStateImplCopyWith<$Res>
    implements $WalletAuthStateCopyWith<$Res> {
  factory _$$WalletAuthStateImplCopyWith(_$WalletAuthStateImpl value,
          $Res Function(_$WalletAuthStateImpl) then) =
      __$$WalletAuthStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isInitialized,
      bool isAuthenticated,
      bool isLoading,
      bool isConnectingWallet,
      WalletUser? user,
      StarknetWallet? wallet,
      String? error,
      AuthProvider? currentProvider});

  @override
  $WalletUserCopyWith<$Res>? get user;
  @override
  $StarknetWalletCopyWith<$Res>? get wallet;
}

/// @nodoc
class __$$WalletAuthStateImplCopyWithImpl<$Res>
    extends _$WalletAuthStateCopyWithImpl<$Res, _$WalletAuthStateImpl>
    implements _$$WalletAuthStateImplCopyWith<$Res> {
  __$$WalletAuthStateImplCopyWithImpl(
      _$WalletAuthStateImpl _value, $Res Function(_$WalletAuthStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isAuthenticated = null,
    Object? isLoading = null,
    Object? isConnectingWallet = null,
    Object? user = freezed,
    Object? wallet = freezed,
    Object? error = freezed,
    Object? currentProvider = freezed,
  }) {
    return _then(_$WalletAuthStateImpl(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isAuthenticated: null == isAuthenticated
          ? _value.isAuthenticated
          : isAuthenticated // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isConnectingWallet: null == isConnectingWallet
          ? _value.isConnectingWallet
          : isConnectingWallet // ignore: cast_nullable_to_non_nullable
              as bool,
      user: freezed == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as WalletUser?,
      wallet: freezed == wallet
          ? _value.wallet
          : wallet // ignore: cast_nullable_to_non_nullable
              as StarknetWallet?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      currentProvider: freezed == currentProvider
          ? _value.currentProvider
          : currentProvider // ignore: cast_nullable_to_non_nullable
              as AuthProvider?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletAuthStateImpl implements _WalletAuthState {
  const _$WalletAuthStateImpl(
      {this.isInitialized = false,
      this.isAuthenticated = false,
      this.isLoading = false,
      this.isConnectingWallet = false,
      this.user,
      this.wallet,
      this.error,
      this.currentProvider});

  factory _$WalletAuthStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletAuthStateImplFromJson(json);

  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool isAuthenticated;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isConnectingWallet;
  @override
  final WalletUser? user;
  @override
  final StarknetWallet? wallet;
  @override
  final String? error;
  @override
  final AuthProvider? currentProvider;

  @override
  String toString() {
    return 'WalletAuthState(isInitialized: $isInitialized, isAuthenticated: $isAuthenticated, isLoading: $isLoading, isConnectingWallet: $isConnectingWallet, user: $user, wallet: $wallet, error: $error, currentProvider: $currentProvider)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletAuthStateImpl &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isAuthenticated, isAuthenticated) ||
                other.isAuthenticated == isAuthenticated) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isConnectingWallet, isConnectingWallet) ||
                other.isConnectingWallet == isConnectingWallet) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.wallet, wallet) || other.wallet == wallet) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.currentProvider, currentProvider) ||
                other.currentProvider == currentProvider));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, isInitialized, isAuthenticated,
      isLoading, isConnectingWallet, user, wallet, error, currentProvider);

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletAuthStateImplCopyWith<_$WalletAuthStateImpl> get copyWith =>
      __$$WalletAuthStateImplCopyWithImpl<_$WalletAuthStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletAuthStateImplToJson(
      this,
    );
  }
}

abstract class _WalletAuthState implements WalletAuthState {
  const factory _WalletAuthState(
      {final bool isInitialized,
      final bool isAuthenticated,
      final bool isLoading,
      final bool isConnectingWallet,
      final WalletUser? user,
      final StarknetWallet? wallet,
      final String? error,
      final AuthProvider? currentProvider}) = _$WalletAuthStateImpl;

  factory _WalletAuthState.fromJson(Map<String, dynamic> json) =
      _$WalletAuthStateImpl.fromJson;

  @override
  bool get isInitialized;
  @override
  bool get isAuthenticated;
  @override
  bool get isLoading;
  @override
  bool get isConnectingWallet;
  @override
  WalletUser? get user;
  @override
  StarknetWallet? get wallet;
  @override
  String? get error;
  @override
  AuthProvider? get currentProvider;

  /// Create a copy of WalletAuthState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletAuthStateImplCopyWith<_$WalletAuthStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OnboardingStep _$OnboardingStepFromJson(Map<String, dynamic> json) {
  return _OnboardingStep.fromJson(json);
}

/// @nodoc
mixin _$OnboardingStep {
  int get index => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get buttonText => throw _privateConstructorUsedError;
  String? get illustration => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;

  /// Serializes this OnboardingStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OnboardingStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OnboardingStepCopyWith<OnboardingStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingStepCopyWith<$Res> {
  factory $OnboardingStepCopyWith(
          OnboardingStep value, $Res Function(OnboardingStep) then) =
      _$OnboardingStepCopyWithImpl<$Res, OnboardingStep>;
  @useResult
  $Res call(
      {int index,
      String title,
      String description,
      String buttonText,
      String? illustration,
      bool isCompleted});
}

/// @nodoc
class _$OnboardingStepCopyWithImpl<$Res, $Val extends OnboardingStep>
    implements $OnboardingStepCopyWith<$Res> {
  _$OnboardingStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OnboardingStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? title = null,
    Object? description = null,
    Object? buttonText = null,
    Object? illustration = freezed,
    Object? isCompleted = null,
  }) {
    return _then(_value.copyWith(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      buttonText: null == buttonText
          ? _value.buttonText
          : buttonText // ignore: cast_nullable_to_non_nullable
              as String,
      illustration: freezed == illustration
          ? _value.illustration
          : illustration // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OnboardingStepImplCopyWith<$Res>
    implements $OnboardingStepCopyWith<$Res> {
  factory _$$OnboardingStepImplCopyWith(_$OnboardingStepImpl value,
          $Res Function(_$OnboardingStepImpl) then) =
      __$$OnboardingStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int index,
      String title,
      String description,
      String buttonText,
      String? illustration,
      bool isCompleted});
}

/// @nodoc
class __$$OnboardingStepImplCopyWithImpl<$Res>
    extends _$OnboardingStepCopyWithImpl<$Res, _$OnboardingStepImpl>
    implements _$$OnboardingStepImplCopyWith<$Res> {
  __$$OnboardingStepImplCopyWithImpl(
      _$OnboardingStepImpl _value, $Res Function(_$OnboardingStepImpl) _then)
      : super(_value, _then);

  /// Create a copy of OnboardingStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? title = null,
    Object? description = null,
    Object? buttonText = null,
    Object? illustration = freezed,
    Object? isCompleted = null,
  }) {
    return _then(_$OnboardingStepImpl(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      buttonText: null == buttonText
          ? _value.buttonText
          : buttonText // ignore: cast_nullable_to_non_nullable
              as String,
      illustration: freezed == illustration
          ? _value.illustration
          : illustration // ignore: cast_nullable_to_non_nullable
              as String?,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OnboardingStepImpl implements _OnboardingStep {
  const _$OnboardingStepImpl(
      {required this.index,
      required this.title,
      required this.description,
      required this.buttonText,
      this.illustration,
      this.isCompleted = false});

  factory _$OnboardingStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnboardingStepImplFromJson(json);

  @override
  final int index;
  @override
  final String title;
  @override
  final String description;
  @override
  final String buttonText;
  @override
  final String? illustration;
  @override
  @JsonKey()
  final bool isCompleted;

  @override
  String toString() {
    return 'OnboardingStep(index: $index, title: $title, description: $description, buttonText: $buttonText, illustration: $illustration, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingStepImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.buttonText, buttonText) ||
                other.buttonText == buttonText) &&
            (identical(other.illustration, illustration) ||
                other.illustration == illustration) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, index, title, description,
      buttonText, illustration, isCompleted);

  /// Create a copy of OnboardingStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingStepImplCopyWith<_$OnboardingStepImpl> get copyWith =>
      __$$OnboardingStepImplCopyWithImpl<_$OnboardingStepImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OnboardingStepImplToJson(
      this,
    );
  }
}

abstract class _OnboardingStep implements OnboardingStep {
  const factory _OnboardingStep(
      {required final int index,
      required final String title,
      required final String description,
      required final String buttonText,
      final String? illustration,
      final bool isCompleted}) = _$OnboardingStepImpl;

  factory _OnboardingStep.fromJson(Map<String, dynamic> json) =
      _$OnboardingStepImpl.fromJson;

  @override
  int get index;
  @override
  String get title;
  @override
  String get description;
  @override
  String get buttonText;
  @override
  String? get illustration;
  @override
  bool get isCompleted;

  /// Create a copy of OnboardingStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OnboardingStepImplCopyWith<_$OnboardingStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
