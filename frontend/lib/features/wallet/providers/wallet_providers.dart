import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_models.dart';
import '../services/wallet_service.dart';

/// Provider for the WalletService singleton
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService.instance;
});

/// StateNotifier for managing wallet authentication state
class WalletAuthNotifier extends StateNotifier<WalletAuthState> {
  WalletAuthNotifier(this._walletService) : super(const WalletAuthState()) {
    _initialize();
  }

  final WalletService _walletService;
  Timer? _balanceTimer;

  /// Initialize the wallet service and restore session
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Initialize wallet service
      await _walletService.initialize();
      
      // Try to restore previous session
      await _restoreSession();
      
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Wallet initialization failed: $e');
      state = state.copyWith(
        isInitialized: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Restore previous authentication session
  Future<void> _restoreSession() async {
    try {
      // Check if user is logged in with Web3Auth
      final isLoggedIn = await _walletService.isLoggedIn();
      if (!isLoggedIn) return;

      // Get stored user and wallet
      final user = await _walletService.getStoredUser();
      final wallet = await _walletService.getStoredWallet();

      if (user != null && wallet != null) {
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          wallet: wallet,
          currentProvider: user.provider,
        );
        
        // Start balance monitoring
        _startBalanceMonitoring();
        
        debugPrint('✅ Session restored for ${user.email}');
      }
    } catch (e) {
      debugPrint('Failed to restore session: $e');
    }
  }

  /// Authenticate with social provider
  Future<void> authenticateWithSocial(AuthProvider provider) async {
    if (!state.isInitialized) {
      throw Exception('Wallet service not initialized');
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      // Authenticate with Web3Auth
      final user = await _walletService.authenticateWithSocial(provider);
      
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        currentProvider: provider,
        isLoading: false,
      );

      debugPrint('✅ Authentication successful for ${user.email}');
    } catch (e) {
      debugPrint('❌ Authentication failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Generate and connect Starknet wallet
  Future<void> connectStarknetWallet() async {
    if (!state.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    state = state.copyWith(
      isConnectingWallet: true,
      error: null,
    );

    try {
      // Generate Starknet wallet
      final wallet = await _walletService.generateStarknetWallet();
      
      state = state.copyWith(
        wallet: wallet,
        isConnectingWallet: false,
      );

      // Start monitoring wallet balance
      _startBalanceMonitoring();

      debugPrint('✅ Starknet wallet connected: ${wallet.address}');
    } catch (e) {
      debugPrint('❌ Wallet connection failed: $e');
      state = state.copyWith(
        isConnectingWallet: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Complete onboarding flow
  Future<void> completeOnboarding() async {
    try {
      await _walletService.markOnboardingCompleted();
      debugPrint('✅ Onboarding completed');
    } catch (e) {
      debugPrint('❌ Failed to complete onboarding: $e');
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      _stopBalanceMonitoring();
      
      await _walletService.signOut();
      
      state = const WalletAuthState(isInitialized: true);
      
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Start monitoring wallet balance
  void _startBalanceMonitoring() {
    if (state.wallet == null) return;
    
    _balanceTimer?.cancel();
    _balanceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateWalletBalance(),
    );
    
    // Initial balance fetch
    _updateWalletBalance();
  }

  /// Stop monitoring wallet balance
  void _stopBalanceMonitoring() {
    _balanceTimer?.cancel();
    _balanceTimer = null;
  }

  /// Update wallet balance
  Future<void> _updateWalletBalance() async {
    if (state.wallet == null) return;
    
    try {
      final balance = await _walletService.getWalletBalance(state.wallet!.address);
      // You can extend this to update balance in state if needed
      debugPrint('Wallet balance: $balance ETH');
    } catch (e) {
      debugPrint('Failed to update balance: $e');
    }
  }

  @override
  void dispose() {
    _stopBalanceMonitoring();
    super.dispose();
  }
}

/// Provider for wallet authentication state
final walletAuthProvider = StateNotifierProvider<WalletAuthNotifier, WalletAuthState>((ref) {
  final walletService = ref.read(walletServiceProvider);
  return WalletAuthNotifier(walletService);
});

/// Provider for checking if onboarding is completed
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.hasCompletedOnboarding();
});

/// Provider for available authentication providers
final availableProvidersProvider = Provider<List<AuthProvider>>((ref) {
  final walletService = ref.read(walletServiceProvider);
  return walletService.getAvailableProviders();
});

/// Provider for wallet balance
final walletBalanceProvider = FutureProvider.family<String, String>((ref, address) async {
  final walletService = ref.read(walletServiceProvider);
  return await walletService.getWalletBalance(address);
});

/// Provider for checking if wallet is fully connected
final isWalletConnectedProvider = Provider<bool>((ref) {
  final authState = ref.watch(walletAuthProvider);
  return authState.isAuthenticated && 
         authState.wallet != null && 
         !authState.isLoading && 
         !authState.isConnectingWallet;
});

/// Provider for current user
final currentUserProvider = Provider<WalletUser?>((ref) {
  final authState = ref.watch(walletAuthProvider);
  return authState.user;
});

/// Provider for current wallet
final currentWalletProvider = Provider<StarknetWallet?>((ref) {
  final authState = ref.watch(walletAuthProvider);
  return authState.wallet;
});

/// Provider for wallet loading state
final walletLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(walletAuthProvider);
  return authState.isLoading || authState.isConnectingWallet;
});

/// Provider for onboarding steps
final onboardingStepsProvider = Provider<List<OnboardingStep>>((ref) {
  return [
    const OnboardingStep(
      index: 0,
      title: 'Welcome to StreetCred Clash',
      description: 'Turn trading into art. Spray paint your trades, earn XP, and battle friends in the ultimate gamified perpetual trading experience.',
      buttonText: 'Get Started',
      illustration: 'assets/onboarding/welcome.svg',
    ),
    const OnboardingStep(
      index: 1,
      title: 'Connect Your Social Account',
      description: 'Sign in with your favorite social account. We use Web3Auth to create a secure wallet for you automatically.',
      buttonText: 'Connect Account',
      illustration: 'assets/onboarding/social_login.svg',
    ),
    const OnboardingStep(
      index: 2,
      title: 'Your Starknet Wallet',
      description: 'We\'ve created a secure Starknet wallet for you. Use it to trade with low fees and lightning-fast transactions.',
      buttonText: 'Setup Wallet',
      illustration: 'assets/onboarding/wallet.svg',
    ),
    const OnboardingStep(
      index: 3,
      title: 'Ready to Trade!',
      description: 'You\'re all set! Start spray painting your trades, build combos, and climb the leaderboards.',
      buttonText: 'Start Trading',
      illustration: 'assets/onboarding/ready.svg',
    ),
  ];
});