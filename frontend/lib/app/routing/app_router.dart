import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/trade/ui/trade_arena_screen.dart';
import '../../features/trade/ui/asset_selection_screen.dart';
import '../../features/trade/widgets/brand_symbol.dart';
import '../../features/wallet/ui/onboarding_screen.dart';
import '../../features/wallet/ui/wallet_connection_screen.dart';
import '../../features/wallet/providers/wallet_providers.dart';
import '../theme/street_cred_design_system.dart';
import '../widgets/street_cred_card.dart';
import '../widgets/street_cred_button.dart' as scb;
import '../widgets/street_cred_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/trade/providers/wallet_provider.dart' as legacy;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Welcome/Login screen with wallet connection
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(legacy.walletProvider);
    final isLoading = ref.watch(legacy.walletLoadingProvider);

    // Auto-redirect to asset selection if wallet is connected
    if (walletState.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/assets');
      });
    }

    const themeColor = Color(0xFFFF0080); // Primary pink theme

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(StreetCredDesignSystem.spacingXL),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Brand header card
                StreetCredCard(
                  themeColor: themeColor,
                  size: CardSize.medium,
                  isSelected: true,
                  enablePressEffect: false,
                  child: Column(
                    children: [
                      Text(
                        'STREETCRED\nCLASH',
                        textAlign: TextAlign.center,
                        style: StreetCredDesignSystem.titleStyle(
                          Colors.white,
                        ).copyWith(fontSize: 24, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingL),

                // Subtitle
                Text(
                  'Street Art Meets DeFi',
                  textAlign: TextAlign.center,
                  style: StreetCredDesignSystem.subtitleStyle(
                    const Color(0xFF00FFFF),
                  ).copyWith(fontSize: 16),
                ),
                const SizedBox(height: StreetCredDesignSystem.spacingXS),
                Text(
                  'Tag walls • Earn street cred • Battle crews',
                  textAlign: TextAlign.center,
                  style: StreetCredDesignSystem.bodyStyle().copyWith(fontSize: 13),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingL),

                // How to Play card
                StreetCredCard(
                  themeColor: const Color(0xFF00FFFF),
                  size: CardSize.small,
                  isSelected: false,
                  enablePressEffect: false,
                  child: Column(
                    children: [
                      Text(
                        'THE STREETS',
                        style: StreetCredDesignSystem.titleStyle(
                          const Color(0xFF00FFFF),
                        ).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      _buildFeature('Tag trades on walls'),
                      _buildFeature('Build street cred'),
                      _buildFeature('Earn graffiti NFTs'),
                      _buildFeature('Battle rival crews'),
                    ],
                  ),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXL),

                // Main action button
                scb.StreetCredButton(
                  text: 'JOIN THE CREW',
                  themeColor: const Color(0xFF00FF41),
                  style: scb.ButtonStyle.primary,
                  width: double.infinity,
                  height: 56,
                  onPressed: () => context.go('/onboarding'),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingM),

                // Quick connect button
                scb.StreetCredButton(
                  text: isLoading
                      ? 'Hitting the streets...'
                      : 'QUICK CONNECT',
                  themeColor: const Color(0xFF00FFFF),
                  style: scb.ButtonStyle.secondary,
                  width: double.infinity,
                  height: 44,
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () => context.go('/wallet-connect'),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingM),

                // Practice mode button
                scb.StreetCredButton(
                  text: 'PRACTICE MODE',
                  themeColor: const Color(0xFF888888),
                  style: scb.ButtonStyle.secondary,
                  width: double.infinity,
                  height: 40,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '🎮 Practice mode coming soon!',
                        ),
                        backgroundColor: const Color(0xFF2A2A2A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingL),

                // Footer with Starknet branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Powered by ',
                      style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 10),
                    ),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final Uri url = Uri.parse('https://starknet.io');
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          print('Could not launch Starknet URL: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration:
                            StreetCredDesignSystem.secondaryCardDecoration(
                              const Color(0xFF8C8DFC),
                            ),
                        child: Text(
                          'STARKNET',
                          style: GoogleFonts.workSans(
                            fontSize: 8,
                            color: const Color(0xFF8C8DFC),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String title, [String? description]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeColor = Color(0xFFFFD700); // Gold theme for rewards

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(StreetCredDesignSystem.spacingXL),
            child: Column(
              children: [
                // Header
                StreetCredHeader(
                  title: 'REWARDS',
                  themeColor: themeColor,
                  showBrandSymbol: false,
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXXL),

                // Rewards card
                StreetCredCard(
                  themeColor: themeColor,
                  size: CardSize.large,
                  child: Column(
                    children: [
                      Text(
                        'ACHIEVEMENTS',
                        style: StreetCredDesignSystem.titleStyle(themeColor),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingL),
                      Text(
                        '🏆 First Trade',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      Text(
                        '🔥 5-Trade Streak',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      Text(
                        '💎 Diamond Hands',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXL),

                // Back button
                scb.StreetCredButton(
                  text: 'BACK TO ARENA',
                  themeColor: themeColor,
                  style: scb.ButtonStyle.primary,
                  width: double.infinity,
                  onPressed: () => context.go('/arena'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeColor = Color(0xFF00FFFF); // Cyan theme for profile

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(StreetCredDesignSystem.spacingXL),
            child: Column(
              children: [
                // Header
                StreetCredHeader(
                  title: 'PROFILE',
                  themeColor: themeColor,
                  showBrandSymbol: false,
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXXL),

                // Profile stats card
                StreetCredCard(
                  themeColor: themeColor,
                  size: CardSize.large,
                  child: Column(
                    children: [
                      Text(
                        'YOUR STATS',
                        style: StreetCredDesignSystem.titleStyle(themeColor),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingL),
                      Text(
                        'Rank: #1337',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      Text(
                        'Total Trades: 42',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      Text(
                        'Win Rate: 69%',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXL),

                // Back button
                scb.StreetCredButton(
                  text: 'BACK TO ARENA',
                  themeColor: themeColor,
                  style: scb.ButtonStyle.primary,
                  width: double.infinity,
                  onPressed: () => context.go('/arena'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DripScreen extends ConsumerWidget {
  const DripScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeColor = Color(0xFF8A2BE2); // Purple theme for drip

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(StreetCredDesignSystem.spacingXL),
            child: Column(
              children: [
                // Header
                StreetCredHeader(
                  title: 'DRIP COLLECTION',
                  themeColor: themeColor,
                  showBrandSymbol: false,
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXXL),

                // NFT collection card
                StreetCredCard(
                  themeColor: themeColor,
                  size: CardSize.large,
                  child: Column(
                    children: [
                      Text(
                        'YOUR NFT COLLECTION',
                        style: StreetCredDesignSystem.titleStyle(themeColor),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingL),
                      Text(
                        '🎨 Spray Can Badge',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      Text(
                        '🔮 Crystal Ball',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingS),
                      Text(
                        '⚡ Lightning Boost',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXL),

                // Back button
                scb.StreetCredButton(
                  text: 'BACK TO ARENA',
                  themeColor: themeColor,
                  style: scb.ButtonStyle.primary,
                  width: double.infinity,
                  onPressed: () => context.go('/arena'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeColor = Color(0xFFFF4500); // Orange theme for streaks

    return Scaffold(
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(themeColor),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(StreetCredDesignSystem.spacingXL),
            child: Column(
              children: [
                // Header
                StreetCredHeader(
                  title: 'STREAK BOARD',
                  themeColor: themeColor,
                  showBrandSymbol: false,
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXXL),

                // Streak card
                StreetCredCard(
                  themeColor: themeColor,
                  size: CardSize.large,
                  child: Column(
                    children: [
                      Text(
                        'CURRENT STREAK',
                        style: StreetCredDesignSystem.titleStyle(themeColor),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingL),
                      Text(
                        '🔥 7 DAYS',
                        style: StreetCredDesignSystem.subtitleStyle(
                          themeColor,
                        ).copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: StreetCredDesignSystem.spacingL),
                      Text(
                        'Keep trading to maintain your streak!',
                        style: StreetCredDesignSystem.bodyStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: StreetCredDesignSystem.spacingXL),

                // Back button
                scb.StreetCredButton(
                  text: 'BACK TO ARENA',
                  themeColor: themeColor,
                  style: scb.ButtonStyle.primary,
                  width: double.infinity,
                  onPressed: () => context.go('/arena'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final routerRefreshNotifier = ValueNotifier(0);

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    
    // Check new wallet auth state
    final walletAuth = container.read(walletAuthProvider);
    final isWalletConnected = walletAuth.isAuthenticated && 
                             walletAuth.wallet != null && 
                             !walletAuth.isLoading;
    
    // Check legacy wallet state for backward compatibility
    final legacyWallet = container.read(legacy.walletProvider);
    final isLegacyConnected = legacyWallet.isConnected;
    
    final isLoggedIn = isWalletConnected || isLegacyConnected;
    final path = state.uri.toString();
    
    // Public routes that don't require authentication
    final publicRoutes = ['/', '/tutorial', '/onboarding', '/wallet-connect'];
    final isOnPublic = publicRoutes.contains(path);
    
    // Check if user has completed onboarding
    if (isWalletConnected && path == '/') {
      // If fully connected, go to assets
      return '/assets';
    }
    
    if (!isLoggedIn && !isOnPublic) {
      return '/';
    }
    
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const TutorialScreen()),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/wallet-connect',
      builder: (context, state) => const WalletConnectionScreen(),
    ),
    GoRoute(
      path: '/assets',
      builder: (context, state) => const AssetSelectionScreen(),
    ),
    GoRoute(
      path: '/arena',
      builder: (context, state) => const TradeArenaScreen(),
    ),
    GoRoute(path: '/reward', builder: (context, state) => const RewardScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(path: '/drip', builder: (context, state) => const DripScreen()),
    GoRoute(
      path: '/streaks',
      builder: (context, state) => const StreakScreen(),
    ),
  ],
);
