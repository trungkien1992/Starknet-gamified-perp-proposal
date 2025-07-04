import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web3auth_flutter/web3auth_flutter.dart';
import '../models/wallet_models.dart';

class WalletService {
  static const String _web3AuthClientId = 'YOUR_WEB3AUTH_CLIENT_ID';
  static const String _starknetRpcUrl = 'https://starknet-mainnet.infura.io/v3/YOUR_PROJECT_ID';
  static const String _chainId = '0x534e5f4d41494e'; // Starknet Mainnet
  
  // For development - use Sepolia testnet
  static const String _testnetRpcUrl = 'https://starknet-sepolia.infura.io/v3/YOUR_PROJECT_ID';
  static const String _testnetChainId = '0x534e5f5345504f4c4941'; // Starknet Sepolia
  
  static const _secureStorage = FlutterSecureStorage();

  late Web3AuthFlutter _web3Auth;
  
  // Storage keys
  static const String _userKey = 'wallet_user';
  static const String _walletKey = 'starknet_wallet';
  static const String _onboardingKey = 'onboarding_completed';

  WalletService._();
  static final WalletService _instance = WalletService._();
  static WalletService get instance => _instance;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Web3Auth (mock for now)
      _web3Auth = Web3AuthFlutter();
      
      // For development, we'll skip actual Web3Auth initialization
      // and use mock authentication
      if (kDebugMode) {
        debugPrint('🧪 Using mock Web3Auth for development');
      } else {
        // TODO: Implement real Web3Auth initialization when ready for production
        debugPrint('⚠️ Production Web3Auth not yet implemented');
      }

      _isInitialized = true;
      debugPrint('✅ WalletService initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize WalletService: $e');
      rethrow;
    }
  }

  /// Social authentication using Web3Auth (mock implementation)
  Future<WalletUser> authenticateWithSocial(AuthProvider provider) async {
    if (!_isInitialized) {
      throw Exception('WalletService not initialized');
    }

    try {
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate mock user data
      final mockUser = _generateMockUser(provider);

      // Store user securely
      await _secureStorage.write(
        key: _userKey,
        value: jsonEncode(mockUser.toJson()),
      );

      debugPrint('✅ User authenticated: ${mockUser.email}');
      return mockUser;
    } catch (e) {
      debugPrint('❌ Social authentication failed: $e');
      rethrow;
    }
  }

  /// Generate Starknet wallet (mock implementation)
  Future<StarknetWallet> generateStarknetWallet() async {
    if (!_isInitialized) {
      throw Exception('WalletService not initialized');
    }

    try {
      // Simulate wallet generation delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate mock private key
      final privateKeyHex = _generateMockPrivateKey();
      
      // Generate Starknet-compatible private key
      final starknetPrivateKey = _generateStarknetPrivateKey(privateKeyHex);
      
      // Generate mock address and public key
      final address = _generateMockStarknetAddress(starknetPrivateKey);
      final publicKey = _generateMockPublicKey(starknetPrivateKey);

      final wallet = StarknetWallet(
        address: address,
        privateKey: starknetPrivateKey,
        publicKey: publicKey,
        chainId: kDebugMode ? _testnetChainId : _chainId,
        lastUsed: DateTime.now(),
      );

      // Store wallet securely
      await _secureStorage.write(
        key: _walletKey,
        value: jsonEncode(wallet.toJson()),
      );

      debugPrint('✅ Starknet wallet generated: $address');
      return wallet;
    } catch (e) {
      debugPrint('❌ Starknet wallet generation failed: $e');
      rethrow;
    }
  }

  /// Get stored user
  Future<WalletUser?> getStoredUser() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson == null) return null;
      
      return WalletUser.fromJson(jsonDecode(userJson));
    } catch (e) {
      debugPrint('Failed to get stored user: $e');
      return null;
    }
  }

  /// Get stored wallet
  Future<StarknetWallet?> getStoredWallet() async {
    try {
      final walletJson = await _secureStorage.read(key: _walletKey);
      if (walletJson == null) return null;
      
      return StarknetWallet.fromJson(jsonDecode(walletJson));
    } catch (e) {
      debugPrint('Failed to get stored wallet: $e');
      return null;
    }
  }

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding() async {
    try {
      final completed = await _secureStorage.read(key: _onboardingKey);
      return completed == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    await _secureStorage.write(key: _onboardingKey, value: 'true');
  }

  /// Check wallet balance (mock implementation for now)
  Future<String> getWalletBalance(String address) async {
    try {
      // Mock balance for development
      await Future.delayed(const Duration(milliseconds: 500));
      final random = Random();
      final balance = (random.nextDouble() * 10).toStringAsFixed(4);
      
      debugPrint('Mock wallet balance for $address: $balance ETH');
      return balance;
    } catch (e) {
      debugPrint('Failed to get wallet balance: $e');
      return '0.0000';
    }
  }

  /// Sign out and clear all stored data
  Future<void> signOut() async {
    try {
      // For mock implementation, just clear stored data
      await _secureStorage.deleteAll();
      
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Check if user is currently logged in with Web3Auth
  Future<bool> isLoggedIn() async {
    if (!_isInitialized) return false;
    
    try {
      // Check if we have stored user data
      final userJson = await _secureStorage.read(key: _userKey);
      return userJson != null;
    } catch (e) {
      return false;
    }
  }

  /// Generate Starknet-compatible private key from Web3Auth key
  String _generateStarknetPrivateKey(String web3AuthPrivateKey) {
    // Remove '0x' prefix if present
    final cleanKey = web3AuthPrivateKey.startsWith('0x') 
        ? web3AuthPrivateKey.substring(2) 
        : web3AuthPrivateKey;
    
    // Hash the key with a Starknet-specific salt to create a new key
    final salt = 'starknet_streetcred_clash';
    final combined = cleanKey + salt;
    final digest = sha256.convert(utf8.encode(combined));
    
    // Ensure the key is valid for Starknet (less than the curve order)
    var keyBytes = digest.bytes;
    
    // Convert to hex and ensure it's valid
    final hexKey = keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    return '0x$hexKey';
  }

  /// Generate mock Starknet address
  String _generateMockStarknetAddress(String privateKey) {
    final digest = sha256.convert(utf8.encode(privateKey + 'address'));
    final addressBytes = digest.bytes.take(20).toList();
    final hexAddress = addressBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hexAddress';
  }

  /// Generate mock public key
  String _generateMockPublicKey(String privateKey) {
    final digest = sha256.convert(utf8.encode(privateKey + 'public'));
    final pubKeyBytes = digest.bytes.take(32).toList();
    final hexPubKey = pubKeyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hexPubKey';
  }

  /// Generate mock private key
  String _generateMockPrivateKey() {
    final random = Random();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final hexKey = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hexKey';
  }

  /// Generate mock user for authentication
  WalletUser _generateMockUser(AuthProvider provider) {
    final providerName = provider.displayName.toLowerCase();
    return WalletUser(
      id: 'mock_${providerName}_${DateTime.now().millisecondsSinceEpoch}',
      email: 'demo@${providerName}.com',
      name: 'Demo ${provider.displayName} User',
      profileImage: null,
      provider: provider,
      createdAt: DateTime.now(),
    );
  }

  /// Get available authentication providers based on platform
  List<AuthProvider> getAvailableProviders() {
    final providers = <AuthProvider>[
      AuthProvider.google,
      AuthProvider.discord,
      AuthProvider.twitter,
      AuthProvider.email,
    ];

    // Add Apple only on iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      providers.insert(1, AuthProvider.apple);
    }

    return providers;
  }

  /// Validate wallet address format
  bool isValidStarknetAddress(String address) {
    try {
      // Basic validation - Starknet addresses should be 64 characters (with 0x prefix)
      if (!address.startsWith('0x')) return false;
      if (address.length != 66) return false;
      
      // Try to parse as hex
      BigInt.parse(address.substring(2), radix: 16);
      return true;
    } catch (e) {
      return false;
    }
  }
}