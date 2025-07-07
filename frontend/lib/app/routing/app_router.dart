import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../screens/asset_selection_screen.dart';
import '../../screens/trading_screen.dart';
import '../../screens/trade_result_screen.dart';
import '../../features/wallet/ui/onboarding_screen.dart';
import '../../features/wallet/ui/wallet_connection_screen.dart';
import '../../features/wallet/providers/wallet_providers.dart';
import '../theme/street_cred_design_system.dart';
import '../widgets/street_cred_card.dart';
import '../widgets/street_cred_button.dart' as scb;
import '../widgets/street_cred_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/trade/providers/wallet_provider.dart' as legacy;
import '../../features/tutorial/ui/tutorial_screen.dart';

// Welcome/Login screen with wallet connection
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _flickerController;
  late AnimationController _rainController;
  late AnimationController _entryController;
  late AnimationController _cameraController;
  late AnimationController _neonActivationController;
  
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _flickerAnimation;
  late Animation<double> _rainAnimation;
  late Animation<double> _entryFadeAnimation;
  late Animation<double> _cameraPushAnimation;
  late Animation<double> _neonActivationAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _flickerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _entryController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _cameraController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _neonActivationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _flickerAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );

    _rainAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rainController, curve: Curves.linear),
    );
    
    _entryFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeInOut),
    );
    
    _cameraPushAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut),
    );
    
    _neonActivationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _neonActivationController, curve: Curves.easeInOut),
    );

    // Start cinematic entry sequence
    _startEntrySequence();
  }

  void _startFlickerEffect() {
    Future.delayed(Duration(milliseconds: 2000 + (DateTime.now().millisecondsSinceEpoch % 3000)), () {
      if (mounted) {
        _flickerController.forward(from: 0.0).then((_) {
          _flickerController.reverse().then((_) {
            _startFlickerEffect();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _flickerController.dispose();
    _rainController.dispose();
    _entryController.dispose();
    _cameraController.dispose();
    _neonActivationController.dispose();
    super.dispose();
  }
  
  void _startEntrySequence() async {
    // 1. Fade from black (0-1s)
    await _entryController.forward();
    
    // 2. Start camera push and neon activation (1-4s)
    _cameraController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _neonActivationController.forward();
    
    // 3. Start ambient animations (2s+)
    await Future.delayed(Duration(milliseconds: 1500));
    _glowController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rainController.repeat();
    _startFlickerEffect();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(legacy.walletProvider);

    // Auto-redirect to asset selection if wallet is connected
    if (walletState.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/assets');
      });
    }

    return Scaffold(
      body: Container(
        color: Color(0xFF0A0A1A), // Fallback dark color
        child: Stack(
          children: [
            // Full background alley image recreation
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0A0A1A), // Dark night sky
                      Color(0xFF1A1A2E), // Deep purple
                      Color(0xFF16213E), // Darker blue
                      Color(0xFF0F1419), // Almost black
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rainAnimation, _glowAnimation, _entryFadeAnimation, _cameraPushAnimation, _neonActivationAnimation]),
                  builder: (context, child) {
                    return CustomPaint(
                      painter: HongKongAlleyBackgroundPainter(
                        rainOffset: _rainAnimation.value,
                        glowIntensity: _glowAnimation.value,
                        entryFade: _entryFadeAnimation.value,
                        cameraPush: _cameraPushAnimation.value,
                        neonActivation: _neonActivationAnimation.value,
                      ),
                      child: Container(), // Ensure the painter has a size
                    );
                  },
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Top title area with flickering neon effect
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_pulseAnimation, _flickerAnimation, _glowAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Opacity(
                              opacity: _flickerAnimation.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Main title with advanced cyberpunk styling
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 30),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Color(0xFF00FFFF).withOpacity(_glowAnimation.value * _flickerAnimation.value),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        // Inner glow
                                        BoxShadow(
                                          color: Color(0xFF00FFFF).withOpacity(_glowAnimation.value * _flickerAnimation.value * 0.9),
                                          blurRadius: 15,
                                          spreadRadius: 1,
                                        ),
                                        // Mid glow
                                        BoxShadow(
                                          color: Color(0xFF00FFFF).withOpacity(_glowAnimation.value * _flickerAnimation.value * 0.6),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                        // Outer atmospheric glow
                                        BoxShadow(
                                          color: Color(0xFF00FFFF).withOpacity(_glowAnimation.value * _flickerAnimation.value * 0.3),
                                          blurRadius: 60,
                                          spreadRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'STREETCRED CLASH',
                                      style: TextStyle(
                                        color: Color(0xFF00FFFF),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        height: 1.0,
                                        shadows: [
                                          // Core neon glow
                                          Shadow(
                                            color: Color(0xFF00FFFF).withOpacity(_glowAnimation.value * _flickerAnimation.value),
                                            blurRadius: 20,
                                          ),
                                          // Bright center
                                          Shadow(
                                            color: Colors.white.withOpacity(_flickerAnimation.value * 0.9),
                                            blurRadius: 8,
                                          ),
                                          // Scan line effect
                                          Shadow(
                                            color: Color(0xFF00FFFF).withOpacity(_flickerAnimation.value * 0.4),
                                            offset: Offset(0, 1),
                                            blurRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  SizedBox(height: 12),
                                  
                                  // Subtitle with pink neon
                                  Text(
                                    '街頭藝術 • RHYTHM CLASH',
                                    style: TextStyle(
                                      color: Color(0xFFFF0080).withOpacity(_glowAnimation.value),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFFF0080).withOpacity(_glowAnimation.value * 0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  SizedBox(height: 6),
                                  
                                  // Atmospheric tagline
                                  Text(
                                    'Hong Kong Underground',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Bottom navigation area
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Single demo entry button
                          GestureDetector(
                            onTap: () => context.go('/assets'),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                              decoration: BoxDecoration(
                                color: Color(0xFF00FFFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFF00FFFF),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF00FFFF).withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow,
                                    color: Color(0xFF00FFFF),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'ENTER THE ALLEY',
                                    style: TextStyle(
                                      color: Color(0xFF00FFFF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Powered by Starknet
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Powered by ',
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'STARKNET',
                                style: TextStyle(
                                  color: Color(0xFF8C8DFC),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoogleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Google signup will be implemented in next iteration'),
        backgroundColor: Color(0xFF4285F4),
      ),
    );
  }

  void _handleAppleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apple signup will be implemented in next iteration'),
        backgroundColor: Color(0xFFFFFFFF).withOpacity(0.9),
      ),
    );
  }

  void _handleImportWallet() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wallet import will be implemented in next iteration'),
        backgroundColor: Color(0xFFFF0080),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/arena');
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                  onPressed: () => Navigator.of(context).pop(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/arena');
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                  onPressed: () => Navigator.of(context).pop(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/arena');
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                  onPressed: () => Navigator.of(context).pop(),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/arena');
            }
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Advanced cyberpunk alleyway painter with cinematic depth
class HongKongAlleyBackgroundPainter extends CustomPainter {
  final double rainOffset;
  final double glowIntensity;
  final double entryFade;
  final double cameraPush;
  final double neonActivation;
  
  HongKongAlleyBackgroundPainter({
    this.rainOffset = 0.0,
    this.glowIntensity = 1.0,
    this.entryFade = 1.0,
    this.cameraPush = 1.0,
    this.neonActivation = 1.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Apply entry fade
    if (entryFade < 1.0) {
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withOpacity(1.0 - entryFade));
    }
    
    // Calculate camera perspective depth
    final depth = 0.3 + (cameraPush * 0.7); // 0.3 to 1.0 depth
    
    // Render scene with depth-based layering
    _drawAtmosphericDepth(canvas, size, paint, depth);
    _drawAlleyGeometry(canvas, size, paint, depth);
    _drawWeatheredTextures(canvas, size, paint, depth);
    _drawAdvancedNeonSigns(canvas, size, paint, glowIntensity * neonActivation, depth);
    _drawVolumetricLighting(canvas, size, paint, glowIntensity, depth);
    _drawWetSurfaceReflections(canvas, size, paint, glowIntensity, depth);
    _drawAtmosphericParticles(canvas, size, paint, rainOffset, depth);
    _drawFogAndMist(canvas, size, paint, depth);
    
    if (entryFade < 1.0) {
      canvas.restore();
    }
  }
  
  // 1. Atmospheric depth with volumetric fog
  void _drawAtmosphericDepth(Canvas canvas, Size size, Paint paint, double depth) {
    final atmosphereGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0A0A1A), // Deep space black
        Color(0xFF1A1A3A), // Midnight blue
        Color(0xFF2A2A4A), // Deep purple-blue
        Color(0xFF1A2A4A), // Atmospheric blue
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    );
    
    paint.shader = atmosphereGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paint.style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;
  }
  
  // 2. Sophisticated alley geometry with realistic perspective
  void _drawAlleyGeometry(Canvas canvas, Size size, Paint paint, double depth) {
    final vanishingPointX = size.width * 0.5;
    final vanishingPointY = size.height * (0.2 + depth * 0.1); // Depth-based horizon
    final alleyWidth = size.width * (0.15 + depth * 0.35); // Expands with depth
    
    // Left wall with atmospheric perspective
    final leftWallPath = Path()
      ..moveTo(0, 0)
      ..lineTo(vanishingPointX - alleyWidth, vanishingPointY)
      ..lineTo(vanishingPointX - alleyWidth, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    // Right wall with atmospheric perspective
    final rightWallPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(vanishingPointX + alleyWidth, vanishingPointY)
      ..lineTo(vanishingPointX + alleyWidth, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    
    // Left wall - weathered brick with blue atmospheric tint
    final leftGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF1A1A3A), // Shadow side
        Color(0xFF2A2A4A), // Mid tone
        Color(0xFF3A3A5A), // Light side
      ],
    );
    paint.shader = leftGradient.createShader(leftWallPath.getBounds());
    paint.style = PaintingStyle.fill;
    canvas.drawPath(leftWallPath, paint);
    
    // Right wall - warmer brick with red atmospheric tint
    final rightGradient = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        Color(0xFF3A1A1A), // Shadow side
        Color(0xFF4A2A2A), // Mid tone  
        Color(0xFF5A3A3A), // Light side
      ],
    );
    paint.shader = rightGradient.createShader(rightWallPath.getBounds());
    canvas.drawPath(rightWallPath, paint);
    
    // Wet cobblestone street
    final streetPath = Path()
      ..moveTo(vanishingPointX - alleyWidth, vanishingPointY)
      ..lineTo(vanishingPointX + alleyWidth, vanishingPointY)
      ..lineTo(vanishingPointX + alleyWidth * 1.5, size.height)
      ..lineTo(vanishingPointX - alleyWidth * 1.5, size.height)
      ..close();
    
    final streetGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1A1A1A), // Distant dark
        Color(0xFF2A2A2A), // Mid ground
        Color(0xFF0A0A0A), // Foreground wet asphalt
      ],
    );
    paint.shader = streetGradient.createShader(streetPath.getBounds());
    canvas.drawPath(streetPath, paint);
    
    paint.shader = null;
  }
  
  // 3. Weathered textures with realistic material details
  void _drawWeatheredTextures(Canvas canvas, Size size, Paint paint, double depth) {
    final vanishingPointX = size.width * 0.5;
    final vanishingPointY = size.height * (0.2 + depth * 0.1);
    final alleyWidth = size.width * (0.15 + depth * 0.35);
    
    // Rolling door shutters with perspective
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.8;
    paint.color = Color(0xFF2A2A2A).withOpacity(0.8);
    
    // Left wall rolling doors
    for (int i = 0; i < 35; i++) {
      final y = size.height * 0.3 + (i * (size.height * 0.7 / 35));
      final perspectiveFactor = 1 - ((y - size.height * 0.3) / (size.height * 0.7)) * 0.6;
      final leftEnd = vanishingPointX - alleyWidth * perspectiveFactor;
      
      canvas.drawLine(
        Offset(0, y),
        Offset(leftEnd, y),
        paint,
      );
    }
    
    // Right wall rolling doors
    for (int i = 0; i < 35; i++) {
      final y = size.height * 0.3 + (i * (size.height * 0.7 / 35));
      final perspectiveFactor = 1 - ((y - size.height * 0.3) / (size.height * 0.7)) * 0.6;
      final rightEnd = vanishingPointX + alleyWidth * perspectiveFactor;
      
      canvas.drawLine(
        Offset(size.width, y),
        Offset(rightEnd, y),
        paint,
      );
    }
    
    // Weathered graffiti and stains
    paint.style = PaintingStyle.fill;
    paint.color = Color(0xFF1A1A1A).withOpacity(0.4);
    
    // Left wall stains
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.08, size.height * 0.6),
        width: size.width * 0.05,
        height: size.height * 0.12,
      ),
      paint,
    );
    
    // Right wall stains
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.92, size.height * 0.55),
        width: size.width * 0.06,
        height: size.height * 0.15,
      ),
      paint,
    );
    
    // Cobblestone texture on street
    paint.color = Color(0xFF1A1A1A).withOpacity(0.3);
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 12; j++) {
        final stoneX = (vanishingPointX - alleyWidth * 1.2) + (j * alleyWidth * 2.4 / 12);
        final stoneY = vanishingPointY + (i * (size.height - vanishingPointY) / 8);
        final stoneSize = 3 + (i * 2); // Larger stones in foreground
        
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(stoneX, stoneY),
            width: stoneSize.toDouble(),
            height: stoneSize.toDouble() * 0.6,
          ),
          paint,
        );
      }
    }
  }
  
  // 4. Advanced neon signage system with sequential activation
  void _drawAdvancedNeonSigns(Canvas canvas, Size size, Paint paint, double activation, double depth) {
    final vanishingPointX = size.width * 0.5;
    final vanishingPointY = size.height * (0.2 + depth * 0.1);
    
    // Sequential neon activation timing
    final sign1Activation = (activation * 3).clamp(0.0, 1.0);
    final sign2Activation = ((activation - 0.33) * 3).clamp(0.0, 1.0);
    final sign3Activation = ((activation - 0.66) * 3).clamp(0.0, 1.0);
    
    // Primary blue vertical sign (left wall) - 茶餐廳
    if (sign1Activation > 0) {
      _drawCinematicNeonSign(
        canvas,
        Offset(size.width * 0.06, size.height * 0.25),
        Size(size.width * 0.08, size.height * 0.35),
        ['茶', '餐', '廳'],
        Color(0xFF0088FF), // Primary blue
        paint,
        sign1Activation,
        isVertical: true,
      );
    }
    
    // Secondary magenta horizontal signs (background depth)
    if (sign2Activation > 0) {
      _drawCinematicNeonSign(
        canvas,
        Offset(vanishingPointX - size.width * 0.12, vanishingPointY + size.height * 0.05),
        Size(size.width * 0.24, size.height * 0.04),
        ['麵食', '小食'],
        Color(0xFFFF0088), // Magenta
        paint,
        sign2Activation,
        isVertical: false,
      );
    }
    
    // Accent warm neon (right wall) - Ramen bowl icon
    if (sign3Activation > 0) {
      _drawRamenBowlNeon(
        canvas,
        Offset(size.width * 0.88, size.height * 0.22),
        size.width * 0.06,
        Color(0xFFFFAA00), // Warm orange
        paint,
        sign3Activation,
      );
    }
    
    // Small business signs in deep background
    if (activation > 0.8) {
      _drawBackgroundBusinessSigns(canvas, size, paint, activation - 0.8, vanishingPointX, vanishingPointY);
    }
  }
  
  void _drawCinematicNeonSign(Canvas canvas, Offset position, Size signSize, List<String> characters, Color neonColor, Paint paint, double activation, {required bool isVertical}) {
    if (activation <= 0) return;
    
    // Power-on flicker effect
    final flickerIntensity = activation < 0.8 ? (activation / 0.8) : 1.0;
    final glowStrength = flickerIntensity * (0.8 + 0.2 * math.sin(DateTime.now().millisecondsSinceEpoch / 100.0));
    
    // Sign housing/background
    paint.style = PaintingStyle.fill;
    paint.color = Color(0xFF0A0A0A).withOpacity(0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, signSize.width, signSize.height),
        Radius.circular(3),
      ),
      paint,
    );
    
    // Neon tube border with realistic glow
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    paint.color = neonColor.withOpacity(glowStrength);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, signSize.width, signSize.height),
        Radius.circular(3),
      ),
      paint,
    );
    
    // Volumetric glow effect
    for (int i = 0; i < 3; i++) {
      paint.strokeWidth = 3 + (i * 2);
      paint.color = neonColor.withOpacity(glowStrength * 0.3 / (i + 1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(position.dx - i, position.dy - i, signSize.width + (i * 2), signSize.height + (i * 2)),
          Radius.circular(3.0 + i.toDouble()),
        ),
        paint,
      );
    }
    
    // Individual character illumination
    for (int i = 0; i < characters.length; i++) {
      final charActivation = ((activation - (i * 0.1)) * 2).clamp(0.0, 1.0);
      if (charActivation <= 0) continue;
      
      late Offset charCenter;
      late Size charSize;
      
      if (isVertical) {
        charCenter = Offset(
          position.dx + signSize.width * 0.5,
          position.dy + (signSize.height / characters.length) * (i + 0.5),
        );
        charSize = Size(signSize.width * 0.7, signSize.height / characters.length * 0.7);
      } else {
        charCenter = Offset(
          position.dx + (signSize.width / characters.length) * (i + 0.5),
          position.dy + signSize.height * 0.5,
        );
        charSize = Size(signSize.width / characters.length * 0.7, signSize.height * 0.7);
      }
      
      // Character glow core
      paint.style = PaintingStyle.fill;
      paint.color = neonColor.withOpacity(charActivation * glowStrength);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: charCenter, width: charSize.width, height: charSize.height),
          Radius.circular(2),
        ),
        paint,
      );
      
      // Character bright core
      paint.color = Colors.white.withOpacity(charActivation * glowStrength * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: charCenter, width: charSize.width * 0.6, height: charSize.height * 0.6),
          Radius.circular(1),
        ),
        paint,
      );
    }
  }
  
  void _drawRamenBowlNeon(Canvas canvas, Offset position, double radius, Color neonColor, Paint paint, double activation) {
    if (activation <= 0) return;
    
    final glowStrength = activation * (0.8 + 0.2 * math.sin(DateTime.now().millisecondsSinceEpoch / 80.0));
    
    // Bowl outline with glow
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = neonColor.withOpacity(glowStrength);
    
    // Outer glow
    for (int i = 0; i < 4; i++) {
      paint.strokeWidth = 2 + (i * 1.5);
      paint.color = neonColor.withOpacity(glowStrength * 0.4 / (i + 1));
      canvas.drawCircle(position, radius + i, paint);
    }
    
    // Bowl shape
    paint.strokeWidth = 2;
    paint.color = neonColor.withOpacity(glowStrength);
    canvas.drawArc(
      Rect.fromCenter(center: position, width: radius * 1.6, height: radius * 1.0),
      0,
      math.pi,
      false,
      paint,
    );
    
    // Chopsticks with glowing tips
    paint.strokeWidth = 1.5;
    canvas.drawLine(
      Offset(position.dx - radius * 0.4, position.dy - radius * 0.3),
      Offset(position.dx + radius * 0.5, position.dy - radius * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(position.dx - radius * 0.3, position.dy - radius * 0.2),
      Offset(position.dx + radius * 0.6, position.dy - radius * 0.7),
      paint,
    );
    
    // Steam effect
    if (activation > 0.5) {
      paint.strokeWidth = 1;
      paint.color = neonColor.withOpacity((activation - 0.5) * 0.6);
      for (int i = 0; i < 3; i++) {
        final steamX = position.dx + (i - 1) * radius * 0.2;
        canvas.drawLine(
          Offset(steamX, position.dy - radius * 0.2),
          Offset(steamX + radius * 0.1, position.dy - radius * 0.6),
          paint,
        );
      }
    }
  }
  
  void _drawBackgroundBusinessSigns(Canvas canvas, Size size, Paint paint, double activation, double vanishingPointX, double vanishingPointY) {
    // Distant small signs creating depth
    final signs = [
      {'pos': Offset(vanishingPointX - size.width * 0.08, vanishingPointY + size.height * 0.08), 'color': Color(0xFF00FFAA), 'size': 0.02},
      {'pos': Offset(vanishingPointX + size.width * 0.06, vanishingPointY + size.height * 0.12), 'color': Color(0xFFAA00FF), 'size': 0.025},
      {'pos': Offset(vanishingPointX - size.width * 0.04, vanishingPointY + size.height * 0.15), 'color': Color(0xFFFFAA88), 'size': 0.018},
    ];
    
    for (int i = 0; i < signs.length; i++) {
      final signActivation = ((activation - (i * 0.2)) * 2).clamp(0.0, 1.0);
      if (signActivation <= 0) continue;
      
      final sign = signs[i];
      final signSize = size.width * (sign['size'] as double);
      
      paint.style = PaintingStyle.fill;
      paint.color = (sign['color'] as Color).withOpacity(signActivation * 0.6);
      canvas.drawOval(
        Rect.fromCenter(
          center: sign['pos'] as Offset,
          width: signSize,
          height: signSize * 0.5,
        ),
        paint,
      );
    }
  }
  
  // 5. Volumetric lighting with atmospheric scattering
  void _drawVolumetricLighting(Canvas canvas, Size size, Paint paint, double glowIntensity, double depth) {
    final vanishingPointX = size.width * 0.5;
    final vanishingPointY = size.height * (0.2 + depth * 0.1);
    
    // Light shafts from neon signs
    _drawLightShaft(canvas, size, paint, 
      Offset(size.width * 0.1, size.height * 0.4), // From left neon
      Color(0xFF0088FF), glowIntensity * 0.4);
    
    _drawLightShaft(canvas, size, paint, 
      Offset(size.width * 0.9, size.height * 0.3), // From right neon
      Color(0xFFFFAA00), glowIntensity * 0.3);
    
    // Atmospheric depth lighting
    final depthGradient = RadialGradient(
      center: Alignment(0, -0.3),
      radius: 1.2,
      colors: [
        Color(0xFF2A3A5A).withOpacity(0.6 * glowIntensity),
        Color(0xFF1A2A4A).withOpacity(0.3 * glowIntensity),
        Colors.transparent,
      ],
    );
    
    paint.shader = depthGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paint.style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    paint.shader = null;
  }
  
  void _drawLightShaft(Canvas canvas, Size size, Paint paint, Offset source, Color lightColor, double intensity) {
    final shaftGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 0.8,
      colors: [
        lightColor.withOpacity(intensity),
        lightColor.withOpacity(intensity * 0.3),
        Colors.transparent,
      ],
    );
    
    paint.shader = shaftGradient.createShader(
      Rect.fromCenter(center: source, width: size.width * 0.4, height: size.height * 0.6)
    );
    paint.style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: source, width: size.width * 0.4, height: size.height * 0.6),
      paint,
    );
    paint.shader = null;
  }
  
  // 6. Real-time wet surface reflections
  void _drawWetSurfaceReflections(Canvas canvas, Size size, Paint paint, double glowIntensity, double depth) {
    final vanishingPointX = size.width * 0.5;
    final vanishingPointY = size.height * (0.2 + depth * 0.1);
    final alleyWidth = size.width * (0.15 + depth * 0.35);
    
    // Define puddle areas with realistic shapes
    final puddles = [
      {
        'center': Offset(vanishingPointX - alleyWidth * 0.3, size.height * 0.85),
        'size': Size(alleyWidth * 0.4, size.height * 0.08),
        'color': Color(0xFF0088FF), // Blue neon reflection
      },
      {
        'center': Offset(vanishingPointX + alleyWidth * 0.2, size.height * 0.92),
        'size': Size(alleyWidth * 0.3, size.height * 0.06),
        'color': Color(0xFFFF0088), // Magenta neon reflection
      },
      {
        'center': Offset(vanishingPointX, size.height * 0.78),
        'size': Size(alleyWidth * 0.5, size.height * 0.04),
        'color': Color(0xFFFFAA00), // Orange neon reflection
      },
    ];
    
    for (final puddle in puddles) {
      final center = puddle['center'] as Offset;
      final puddleSize = puddle['size'] as Size;
      final reflectionColor = puddle['color'] as Color;
      
      // Base puddle surface
      paint.style = PaintingStyle.fill;
      paint.color = Color(0xFF0A0A0A).withOpacity(0.8);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: puddleSize.width, height: puddleSize.height),
        paint,
      );
      
      // Neon color reflection
      final reflectionGradient = RadialGradient(
        colors: [
          reflectionColor.withOpacity(0.8 * glowIntensity),
          reflectionColor.withOpacity(0.4 * glowIntensity),
          reflectionColor.withOpacity(0.1 * glowIntensity),
          Colors.transparent,
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      );
      
      paint.shader = reflectionGradient.createShader(
        Rect.fromCenter(center: center, width: puddleSize.width, height: puddleSize.height)
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: puddleSize.width, height: puddleSize.height),
        paint,
      );
      
      // Surface ripples
      paint.shader = null;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 0.5;
      paint.color = Colors.white.withOpacity(0.2 * glowIntensity);
      
      for (int i = 0; i < 3; i++) {
        final rippleRadius = (puddleSize.width * 0.5) * (0.3 + i * 0.2);
        canvas.drawOval(
          Rect.fromCenter(center: center, width: rippleRadius, height: rippleRadius * 0.3),
          paint,
        );
      }
    }
  }
  
  // 7. Atmospheric particle system with rain and mist
  void _drawAtmosphericParticles(Canvas canvas, Size size, Paint paint, double rainOffset, double depth) {
    // Advanced rain with perspective
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    
    final random = (DateTime.now().millisecondsSinceEpoch ~/ 50) + (rainOffset * 1000).toInt();
    
    for (int i = 0; i < 120; i++) {
      final seed = random + i * 7919; // Prime number for better distribution
      final normalizedX = ((seed * 1234567) % 10000) / 10000.0;
      final normalizedY = ((seed * 7654321) % 10000) / 10000.0;
      
      // Calculate perspective depth for rain drops
      final depthFactor = 0.3 + (normalizedY * 0.7); // Closer drops are larger
      final x = size.width * normalizedX;
      final y = (size.height * normalizedY + (rainOffset * size.height * 2)) % (size.height * 1.2);
      
      // Rain drop properties based on depth
      final dropLength = 6 + (depthFactor * 12);
      final dropWidth = 0.5 + (depthFactor * 1.5);
      final dropOpacity = 0.2 + (depthFactor * 0.4);
      
      paint.strokeWidth = dropWidth;
      paint.color = Color(0xFF4A90E2).withOpacity(dropOpacity);
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 1, y + dropLength),
        paint,
      );
      
      // Occasional larger rain streaks
      if (i % 8 == 0) {
        paint.strokeWidth = dropWidth * 1.5;
        paint.color = Color(0xFF6AA0F2).withOpacity(dropOpacity * 0.7);
        canvas.drawLine(
          Offset(x - 0.5, y),
          Offset(x + 1.5, y + dropLength * 1.3),
          paint,
        );
      }
    }
    
    // Floating mist particles
    for (int i = 0; i < 25; i++) {
      final seed = random + i * 3571;
      final mistX = ((seed * 2345678) % size.width.toInt()).toDouble();
      final mistY = ((seed * 8765432) % size.height.toInt()).toDouble();
      final mistSize = 2 + ((seed % 4));
      final mistOpacity = 0.1 + ((seed % 200) / 1000.0);
      
      paint.style = PaintingStyle.fill;
      paint.color = Color(0xFF9ABADC).withOpacity(mistOpacity);
      canvas.drawCircle(Offset(mistX, mistY), mistSize.toDouble(), paint);
    }
  }
  
  // 8. Fog and mist with depth layering
  void _drawFogAndMist(Canvas canvas, Size size, Paint paint, double depth) {
    final vanishingPointX = size.width * 0.5;
    final vanishingPointY = size.height * (0.2 + depth * 0.1);
    
    // Ground-level mist rising from wet surfaces
    final mistGradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.center,
      colors: [
        Color(0xFF3A4A6A).withOpacity(0.6),
        Color(0xFF2A3A5A).withOpacity(0.3),
        Color(0xFF1A2A4A).withOpacity(0.1),
        Colors.transparent,
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    );
    
    paint.shader = mistGradient.createShader(
      Rect.fromLTWH(vanishingPointX - size.width * 0.3, vanishingPointY, size.width * 0.6, size.height * 0.5)
    );
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(vanishingPointX - size.width * 0.3, vanishingPointY, size.width * 0.6, size.height * 0.5),
      paint,
    );
    
    // Atmospheric depth fog in alley distance
    final depthFogGradient = RadialGradient(
      center: Alignment(0, -0.5),
      radius: 0.8,
      colors: [
        Color(0xFF1A2A4A).withOpacity(0.8),
        Color(0xFF0A1A3A).withOpacity(0.4),
        Colors.transparent,
      ],
    );
    
    paint.shader = depthFogGradient.createShader(
      Rect.fromCenter(center: Offset(vanishingPointX, vanishingPointY), width: size.width * 0.4, height: size.height * 0.3)
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(vanishingPointX, vanishingPointY), width: size.width * 0.4, height: size.height * 0.3),
      paint,
    );
    
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class VerticalNeonSignPainter extends CustomPainter {
  final String text;
  final Color color;
  
  VerticalNeonSignPainter({required this.text, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final lines = text.split('\n');
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Sign background
    paint.color = Color(0xFF0A0A0A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(4),
      ),
      paint,
    );
    
    // Sign border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(4),
      ),
      paint,
    );
    
    // Draw vertical text
    for (int i = 0; i < lines.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: lines[i],
          style: TextStyle(
            color: color,
            fontSize: size.width * 0.6,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: color, blurRadius: 8),
              Shadow(color: Colors.white, blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final x = (size.width - textPainter.width) / 2;
      final y = (size.height / lines.length) * i + 
                (size.height / lines.length - textPainter.height) / 2;
      
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WelcomeRainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FFFF).withOpacity(0.4)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final random = DateTime.now().millisecondsSinceEpoch ~/ 200;
    
    // Draw diagonal rain drops
    for (int i = 0; i < 60; i++) {
      final seed = random + i;
      final x = (seed * 1234567) % size.width.toInt();
      final y = (seed * 7654321) % size.height.toInt();
      final length = 8 + (seed % 15);
      
      canvas.drawLine(
        Offset(x.toDouble(), y.toDouble()),
        Offset(x + 2.0, y + length.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RollingDoorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw rolling door horizontal lines
    for (int i = 0; i < 15; i++) {
      final y = (size.height * 0.3) + (i * 25.0);
      if (y > size.height) break;
      
      paint.color = Color(0xFF444444).withOpacity(0.6);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      
      // Add graffiti streaks
      if (i % 3 == 0) {
        paint.color = Color(0xFFFF0080).withOpacity(0.4);
        paint.strokeWidth = 1;
        canvas.drawLine(
          Offset(size.width * 0.1, y - 5),
          Offset(size.width * 0.9, y + 5),
          paint,
        );
      }
    }
    
    // STREETCRED CLASH graffiti on door
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'STREETCRED',
        style: TextStyle(
          color: Color(0xFFFF0080).withOpacity(0.3),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(size.width * 0.1, size.height * 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WetStreetReflectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Wet asphalt base
    paint.color = Color(0xFF0A0A0A).withOpacity(0.9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Street perspective lines
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = Color(0xFF333333).withOpacity(0.6);
    
    // Center perspective lines
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.45, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.55, size.height),
      paint,
    );
    
    // Neon light reflections on wet street
    final reflections = [
      {'color': Color(0xFF00FFFF), 'x': 0.2, 'width': 0.15},
      {'color': Color(0xFFFF0080), 'x': 0.5, 'width': 0.1},
      {'color': Color(0xFF00FF41), 'x': 0.8, 'width': 0.12},
    ];
    
    for (final reflection in reflections) {
      final gradient = RadialGradient(
        colors: [
          (reflection['color'] as Color).withOpacity(0.6),
          (reflection['color'] as Color).withOpacity(0.1),
          Colors.transparent,
        ],
        stops: [0.0, 0.5, 1.0],
      );
      
      final rect = Rect.fromLTWH(
        size.width * (reflection['x'] as double) - size.width * (reflection['width'] as double) / 2,
        size.height * 0.3,
        size.width * (reflection['width'] as double),
        size.height * 0.7,
      );
      
      paint.shader = gradient.createShader(rect);
      paint.style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
      paint.shader = null;
    }
    
    // Small puddle reflections
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + i * 0.1);
      final y = size.height * (0.6 + (i % 3) * 0.1);
      final puddle = Rect.fromCenter(
        center: Offset(x, y),
        width: 20 + (i % 4) * 5,
        height: 8 + (i % 3) * 2,
      );
      
      paint.color = Color(0xFF001122).withOpacity(0.8);
      canvas.drawOval(puddle, paint);
      
      // Mini neon reflection in puddle
      paint.color = [Color(0xFF00FFFF), Color(0xFFFF0080), Color(0xFF00FF41)][i % 3].withOpacity(0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: puddle.width * 0.6,
          height: puddle.height * 0.4,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    
    // Simplified: no complex redirects for prototype V0
    // If fully connected and on welcome, redirect to assets
    if (isLoggedIn && path == '/') {
      return '/assets';
    }
    
    // If not logged in and trying to access protected route, redirect to welcome
    if (!isLoggedIn && !isOnPublic) {
      return '/';
    }
    
    return null;
  },
  routes: [
    // Welcome screen for wallet connection
    GoRoute(
      path: '/', 
      builder: (context, state) => const WelcomeScreen(),
    ),
    // Asset selection screen (main app)
    GoRoute(
      path: '/assets', 
      builder: (context, state) => const AssetSelectionScreen(),
    ),
    GoRoute(
      path: '/trade/:assetPair',
      builder: (context, state) => TradingScreen(
        assetPair: state.pathParameters['assetPair']!,
      ),
    ),
    GoRoute(
      path: '/trade-result',
      builder: (context, state) => TradeResultScreen(
        tradeData: state.extra as Map<String, dynamic>,
      ),
    ),
    
    // Legacy routes kept for reference (can be removed later)
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
  ],
);
