// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletUserImpl _$$WalletUserImplFromJson(Map<String, dynamic> json) =>
    _$WalletUserImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      profileImage: json['profileImage'] as String?,
      provider: $enumDecode(_$AuthProviderEnumMap, json['provider']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WalletUserImplToJson(_$WalletUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'profileImage': instance.profileImage,
      'provider': _$AuthProviderEnumMap[instance.provider]!,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$AuthProviderEnumMap = {
  AuthProvider.google: 'google',
  AuthProvider.apple: 'apple',
  AuthProvider.discord: 'discord',
  AuthProvider.twitter: 'twitter',
  AuthProvider.facebook: 'facebook',
  AuthProvider.email: 'email',
  AuthProvider.walletConnect: 'wallet_connect',
  AuthProvider.metamask: 'metamask',
};

_$StarknetWalletImpl _$$StarknetWalletImplFromJson(Map<String, dynamic> json) =>
    _$StarknetWalletImpl(
      address: json['address'] as String,
      privateKey: json['privateKey'] as String,
      publicKey: json['publicKey'] as String,
      chainId: json['chainId'] as String,
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
    );

Map<String, dynamic> _$$StarknetWalletImplToJson(
        _$StarknetWalletImpl instance) =>
    <String, dynamic>{
      'address': instance.address,
      'privateKey': instance.privateKey,
      'publicKey': instance.publicKey,
      'chainId': instance.chainId,
      'lastUsed': instance.lastUsed?.toIso8601String(),
    };

_$WalletAuthStateImpl _$$WalletAuthStateImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletAuthStateImpl(
      isInitialized: json['isInitialized'] as bool? ?? false,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      isLoading: json['isLoading'] as bool? ?? false,
      isConnectingWallet: json['isConnectingWallet'] as bool? ?? false,
      user: json['user'] == null
          ? null
          : WalletUser.fromJson(json['user'] as Map<String, dynamic>),
      wallet: json['wallet'] == null
          ? null
          : StarknetWallet.fromJson(json['wallet'] as Map<String, dynamic>),
      error: json['error'] as String?,
      currentProvider:
          $enumDecodeNullable(_$AuthProviderEnumMap, json['currentProvider']),
    );

Map<String, dynamic> _$$WalletAuthStateImplToJson(
        _$WalletAuthStateImpl instance) =>
    <String, dynamic>{
      'isInitialized': instance.isInitialized,
      'isAuthenticated': instance.isAuthenticated,
      'isLoading': instance.isLoading,
      'isConnectingWallet': instance.isConnectingWallet,
      'user': instance.user,
      'wallet': instance.wallet,
      'error': instance.error,
      'currentProvider': _$AuthProviderEnumMap[instance.currentProvider],
    };

_$OnboardingStepImpl _$$OnboardingStepImplFromJson(Map<String, dynamic> json) =>
    _$OnboardingStepImpl(
      index: (json['index'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      buttonText: json['buttonText'] as String,
      illustration: json['illustration'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$OnboardingStepImplToJson(
        _$OnboardingStepImpl instance) =>
    <String, dynamic>{
      'index': instance.index,
      'title': instance.title,
      'description': instance.description,
      'buttonText': instance.buttonText,
      'illustration': instance.illustration,
      'isCompleted': instance.isCompleted,
    };
