import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_models.freezed.dart';
part 'wallet_models.g.dart';

@freezed
class WalletUser with _$WalletUser {
  const factory WalletUser({
    required String id,
    required String email,
    required String name,
    String? profileImage,
    required AuthProvider provider,
    required DateTime createdAt,
  }) = _WalletUser;

  factory WalletUser.fromJson(Map<String, dynamic> json) =>
      _$WalletUserFromJson(json);
}

@freezed
class StarknetWallet with _$StarknetWallet {
  const factory StarknetWallet({
    required String address,
    required String privateKey,
    required String publicKey,
    required String chainId,
    DateTime? lastUsed,
  }) = _StarknetWallet;

  factory StarknetWallet.fromJson(Map<String, dynamic> json) =>
      _$StarknetWalletFromJson(json);
}

@freezed
class WalletAuthState with _$WalletAuthState {
  const factory WalletAuthState({
    @Default(false) bool isInitialized,
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading,
    @Default(false) bool isConnectingWallet,
    WalletUser? user,
    StarknetWallet? wallet,
    String? error,
    AuthProvider? currentProvider,
  }) = _WalletAuthState;

  factory WalletAuthState.fromJson(Map<String, dynamic> json) =>
      _$WalletAuthStateFromJson(json);
}

enum AuthProvider {
  @JsonValue('google')
  google,
  @JsonValue('apple')
  apple,
  @JsonValue('discord')
  discord,
  @JsonValue('twitter')
  twitter,
  @JsonValue('facebook')
  facebook,
  @JsonValue('email')
  email,
  @JsonValue('wallet_connect')
  walletConnect,
  @JsonValue('metamask')
  metamask,
}

extension AuthProviderExtension on AuthProvider {
  String get displayName {
    switch (this) {
      case AuthProvider.google:
        return 'Google';
      case AuthProvider.apple:
        return 'Apple';
      case AuthProvider.discord:
        return 'Discord';
      case AuthProvider.twitter:
        return 'Twitter';
      case AuthProvider.facebook:
        return 'Facebook';
      case AuthProvider.email:
        return 'Email';
      case AuthProvider.walletConnect:
        return 'WalletConnect';
      case AuthProvider.metamask:
        return 'MetaMask';
    }
  }

  String get iconAsset {
    switch (this) {
      case AuthProvider.google:
        return 'assets/icons/google.svg';
      case AuthProvider.apple:
        return 'assets/icons/apple.svg';
      case AuthProvider.discord:
        return 'assets/icons/discord.svg';
      case AuthProvider.twitter:
        return 'assets/icons/twitter.svg';
      case AuthProvider.facebook:
        return 'assets/icons/facebook.svg';
      case AuthProvider.email:
        return 'assets/icons/email.svg';
      case AuthProvider.walletConnect:
        return 'assets/icons/wallet_connect.svg';
      case AuthProvider.metamask:
        return 'assets/icons/metamask.svg';
    }
  }
}

@freezed
class OnboardingStep with _$OnboardingStep {
  const factory OnboardingStep({
    required int index,
    required String title,
    required String description,
    required String buttonText,
    String? illustration,
    @Default(false) bool isCompleted,
  }) = _OnboardingStep;

  factory OnboardingStep.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStepFromJson(json);
}