import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../models/wallet_models.dart';
import '../providers/wallet_providers.dart';
import 'widgets/provider_selection_widget.dart';

class WalletConnectionScreen extends ConsumerStatefulWidget {
  const WalletConnectionScreen({super.key});

  @override
  ConsumerState<WalletConnectionScreen> createState() => _WalletConnectionScreenState();
}

class _WalletConnectionScreenState extends ConsumerState<WalletConnectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(walletAuthProvider);
    
    // Auto-redirect when wallet is connected
    ref.listen(walletAuthProvider, (previous, next) {
      if (next.isAuthenticated && next.wallet != null && !next.isLoading) {
        context.go('/assets');
      }
    });

    const themeColor = Color(0xFF00FF41);

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(StreetCredDesignSystem.spacingL),
                child: Column(
                  children: [
                    // Header
                    StreetCredHeader(
                      title: 'CONNECT WALLET',
                      themeColor: themeColor,
                      showBrandSymbol: true,
                    ),

                    const SizedBox(height: StreetCredDesignSystem.spacingXXL),

                    // Connection status or provider selection
                    if (authState.isAuthenticated && authState.wallet == null) ...[
                      _buildWalletCreationCard(authState),
                    ] else if (authState.isAuthenticated && authState.wallet != null) ...[
                      _buildConnectedCard(authState),
                    ] else ...[
                      _buildWelcomeCard(),
                      const SizedBox(height: StreetCredDesignSystem.spacingXL),
                      ProviderSelectionWidget(
                        onProviderSelected: _handleProviderSelection,
                        isLoading: authState.isLoading,
                      ),
                    ],

                    const SizedBox(height: StreetCredDesignSystem.spacingXXL),

                    // Action buttons
                    _buildActionButtons(authState),

                    const SizedBox(height: StreetCredDesignSystem.spacingXL),

                    // Help section
                    _buildHelpSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return StreetCredCard(
      themeColor: const Color(0xFF00FF41),
      size: CardSize.large,
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF00FF41),
            size: 64,
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingL),
          Text(
            'Connect Your Wallet',
            style: StreetCredDesignSystem.titleStyle(
              const Color(0xFF00FF41),
            ),
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingM),
          Text(
            'Sign in with your social account to automatically create a secure Starknet wallet.',
            style: StreetCredDesignSystem.bodyStyle(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCreationCard(WalletAuthState authState) {
    return StreetCredCard(
      themeColor: const Color(0xFF00FFFF),
      size: CardSize.large,
      child: Column(
        children: [
          if (authState.isConnectingWallet) ...[
            const CircularProgressIndicator(
              color: Color(0xFF00FFFF),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingL),
            Text(
              'Creating Your Wallet...',
              style: StreetCredDesignSystem.titleStyle(
                const Color(0xFF00FFFF),
              ),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingM),
            Text(
              'Please wait while we generate your secure Starknet wallet.',
              style: StreetCredDesignSystem.bodyStyle(),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const Icon(
              Icons.security,
              color: Color(0xFF00FFFF),
              size: 64,
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingL),
            Text(
              'Ready to Create Wallet',
              style: StreetCredDesignSystem.titleStyle(
                const Color(0xFF00FFFF),
              ),
            ),
            const SizedBox(height: StreetCredDesignSystem.spacingM),
            Text(
              'You\'re authenticated! Now let\'s create your Starknet wallet for trading.',
              style: StreetCredDesignSystem.bodyStyle(),
              textAlign: TextAlign.center,
            ),
            if (authState.user != null) ...[
              const SizedBox(height: StreetCredDesignSystem.spacingL),
              Container(
                padding: const EdgeInsets.all(StreetCredDesignSystem.spacingM),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getProviderIcon(authState.user!.provider),
                      color: const Color(0xFF00FFFF),
                      size: 20,
                    ),
                    const SizedBox(width: StreetCredDesignSystem.spacingS),
                    Expanded(
                      child: Text(
                        'Signed in as ${authState.user!.name}',
                        style: StreetCredDesignSystem.captionStyle(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConnectedCard(WalletAuthState authState) {
    return StreetCredCard(
      themeColor: const Color(0xFF00FF41),
      size: CardSize.large,
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF00FF41),
            size: 64,
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingL),
          Text(
            'Wallet Connected!',
            style: StreetCredDesignSystem.titleStyle(
              const Color(0xFF00FF41),
            ),
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingM),
          Text(
            'Your Starknet wallet is ready for trading.',
            style: StreetCredDesignSystem.bodyStyle(),
            textAlign: TextAlign.center,
          ),
          if (authState.wallet != null) ...[
            const SizedBox(height: StreetCredDesignSystem.spacingL),
            Container(
              padding: const EdgeInsets.all(StreetCredDesignSystem.spacingM),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Wallet Address:',
                    style: StreetCredDesignSystem.captionStyle(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _truncateAddress(authState.wallet!.address),
                    style: StreetCredDesignSystem.bodyStyle().copyWith(
                      fontFamily: 'monospace',
                      color: const Color(0xFF00FF41),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(WalletAuthState authState) {
    if (authState.isAuthenticated && authState.wallet != null) {
      return scb.StreetCredButton(
        text: 'Start Trading',
        themeColor: const Color(0xFF00FF41),
        style: scb.ButtonStyle.primary,
        width: double.infinity,
        height: 56,
        onPressed: () => context.go('/assets'),
      );
    }

    if (authState.isAuthenticated && authState.wallet == null) {
      return Column(
        children: [
          scb.StreetCredButton(
            text: authState.isConnectingWallet 
                ? 'Creating Wallet...' 
                : 'Create Starknet Wallet',
            themeColor: const Color(0xFF00FFFF),
            style: scb.ButtonStyle.primary,
            width: double.infinity,
            height: 56,
            isLoading: authState.isConnectingWallet,
            onPressed: authState.isConnectingWallet ? null : _createWallet,
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingM),
          scb.StreetCredButton(
            text: 'Sign Out',
            themeColor: const Color(0xFF666666),
            style: scb.ButtonStyle.secondary,
            width: double.infinity,
            onPressed: _signOut,
          ),
        ],
      );
    }

    return Column(
      children: [
        scb.StreetCredButton(
          text: 'New User? Start Onboarding',
          themeColor: const Color(0xFF00FFFF),
          style: scb.ButtonStyle.secondary,
          width: double.infinity,
          onPressed: () => context.go('/onboarding'),
        ),
        const SizedBox(height: StreetCredDesignSystem.spacingM),
        scb.StreetCredButton(
          text: 'Skip Wallet Connection',
          themeColor: const Color(0xFF666666),
          style: scb.ButtonStyle.secondary,
          width: double.infinity,
          onPressed: () => context.go('/assets'),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(StreetCredDesignSystem.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FF41).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: Color(0xFF00FF41),
                size: 20,
              ),
              const SizedBox(width: StreetCredDesignSystem.spacingS),
              Text(
                'Need Help?',
                style: StreetCredDesignSystem.captionStyle().copyWith(
                  color: const Color(0xFF00FF41),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: StreetCredDesignSystem.spacingS),
          Text(
            'Your wallet is secured by Web3Auth and uses Starknet for fast, low-cost trading. No seed phrases to remember!',
            style: StreetCredDesignSystem.captionStyle(),
          ),
        ],
      ),
    );
  }

  void _handleProviderSelection(AuthProvider provider) async {
    try {
      await ref.read(walletAuthProvider.notifier).authenticateWithSocial(provider);
    } catch (e) {
      _showError('Authentication failed: ${e.toString()}');
    }
  }

  void _createWallet() async {
    try {
      await ref.read(walletAuthProvider.notifier).connectStarknetWallet();
    } catch (e) {
      _showError('Wallet creation failed: ${e.toString()}');
    }
  }

  void _signOut() async {
    try {
      await ref.read(walletAuthProvider.notifier).signOut();
    } catch (e) {
      _showError('Sign out failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  IconData _getProviderIcon(AuthProvider provider) {
    switch (provider) {
      case AuthProvider.google:
        return Icons.g_mobiledata;
      case AuthProvider.apple:
        return Icons.apple;
      case AuthProvider.discord:
        return Icons.discord;
      case AuthProvider.twitter:
        return Icons.alternate_email;
      case AuthProvider.facebook:
        return Icons.facebook;
      case AuthProvider.email:
        return Icons.email;
      default:
        return Icons.login;
    }
  }
}