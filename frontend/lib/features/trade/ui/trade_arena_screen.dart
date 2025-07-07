import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as Math;
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../providers/wallet_provider.dart';
import '../state/ink_providers.dart';
import '../widgets/swipe_spray_gauge.dart';
import '../widgets/hand_demo_animation.dart';
import '../widgets/brand_symbol.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/reward/ui/reward_widget.dart';
import '../../../state/xp_provider.dart';
import 'asset_selection_screen.dart';
import '../../../data/providers/extended_provider.dart';
import '../../../data/datasources/extended_api_client.dart';
import '../../../providers/weather_provider.dart';
import '../../../components/rain_overlay.dart';
import '../../../components/weather_demo_widget.dart';
import '../../../components/central_background_overlay.dart';
import '../../../services/weather_service.dart';
import '../../territory/providers/territory_provider.dart';
import '../../territory/services/territory_service.dart';
import '../../social/models/meme_models.dart';
import '../../social/providers/social_providers.dart';
import '../../social/ui/share_trade_widget.dart';

class TradeArenaScreen extends ConsumerStatefulWidget {
  const TradeArenaScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TradeArenaScreen> createState() => _TradeArenaScreenState();
}

class _TradeArenaScreenState extends ConsumerState<TradeArenaScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _inkPulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _inkPulseAnimation;
  bool showHandDemo = true;
  TradeOutcome? _pendingShareOutcome;

  // Central Hong Kong focused assets for prototype
  final Map<String, Map<String, dynamic>> _assetConfig = {
    'HSI-HKD': {
      'symbol': 'HSI',
      'name': 'Hang Seng Index',
      'icon': Icons.account_balance,
      'color': Color(0xFFDC143C), // Crimson red for HSI
    },
    'TCEHY-HKD': {
      'symbol': 'TCEHY',
      'name': 'Tencent Holdings',
      'icon': Icons.business_center,
      'color': Color(0xFF00D4FF), // Tencent blue
    },
    'BTC-USDT': {
      'symbol': 'BTC',
      'name': 'Bitcoin',
      'icon': Icons.currency_bitcoin,
      'color': Color(0xFFF7931A), // Bitcoin orange
    },
  };

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _inkPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _inkPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _inkPulseController, curve: Curves.easeInOut),
    );

    _backgroundController.repeat();
    _inkPulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _inkPulseController.dispose();
    super.dispose();
  }

  void _onTradeExecuted(double leverage, String direction) async {
    final inkNotifier = ref.read(inkProvider.notifier);
    final selectedMarket = ref.read(selectedMarketProvider);
    final tradingService = ref.read(extendedTradingServiceProvider);
    final inkEfficiencyBonus = ref.read(inkEfficiencyBonusProvider);
    final volatilityMultiplier = ref.read(volatilityMultiplierProvider);
    final territoriesNotifier = ref.read(territoriesProvider.notifier);
    final territoryService = ref.read(territoryServiceProvider);
    final currentTerritoryId = ref.read(currentTerritoryProvider);

    // Deduct ink based on leverage with weather effects
    final baseInkCost = (leverage * 10).round();
    final actualInkCost = (baseInkCost / inkEfficiencyBonus).round();
    inkNotifier.spendInk(actualInkCost);

    try {
      // Calculate position size based on leverage (simplified)
      final baseQuantity = leverage * 0.01; // Adjust based on account size
      
      // Execute trade through Extended Exchange
      final orderResponse = await tradingService.executeTrade(
        market: selectedMarket,
        direction: direction,
        leverage: leverage,
        quantity: baseQuantity.toStringAsFixed(6),
      );

      // Calculate territory contribution
      final territoryContribution = territoryService.calculateTradeContribution(
        baseQuantity * 1000, // Convert to dollar amount estimate
        leverage,
      );
      
      // Add territory progress if territory is selected
      String territoryBonus = '';
      if (currentTerritoryId != null) {
        territoriesNotifier.addTradeProgress(currentTerritoryId, tradesCompleted: territoryContribution);
        territoryBonus = ' [+$territoryContribution Territory Progress]';
      }

      // Create trade outcome for social sharing
      final tradeOutcome = TradeOutcome(
        direction: direction,
        leverage: leverage,
        pnl: (Math.Random().nextDouble() - 0.5) * 200, // Simulate P&L for demo
        asset: selectedMarket,
        timestamp: DateTime.now(),
        territoryName: currentTerritoryId != null ? 'Central District' : null,
        isWin: territoryContribution > 2, // Simple win logic based on contribution
        streakDays: null, // TODO: Implement streak tracking
        consecutiveWins: null, // TODO: Implement win tracking
      );

      // Add to recent outcomes
      ref.read(addTradeOutcomeProvider(tradeOutcome));

      // Check if we should auto-suggest sharing
      final shouldAutoSuggest = ref.read(autoSuggestShareProvider(tradeOutcome));
      
      // Show success feedback with weather and territory bonus info
      final weatherBonus = inkEfficiencyBonus > 1.0 ? ' (Rain Bonus!)' : '';
      final volatilityInfo = volatilityMultiplier > 1.2 ? ' [High Volatility]' : '';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trade executed: $direction (x${leverage.toStringAsFixed(1)})$weatherBonus$volatilityInfo$territoryBonus',
            style: StreetCredTheme.graffitiBody,
          ),
          backgroundColor: direction == 'LONG'
              ? StreetCredTheme.longColor
              : StreetCredTheme.shortColor,
          duration: const Duration(seconds: 4),
        ),
      );

      // Show share widget if auto-suggested or for significant trades
      if (shouldAutoSuggest || tradeOutcome.pnl.abs() > 50) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _pendingShareOutcome = tradeOutcome;
            });
          }
        });
      }
    } catch (e) {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trade failed: ${e.toString()}',
            style: StreetCredTheme.graffitiBody,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInk = ref.watch(inkProvider);
    final walletState = ref.watch(walletProvider);
    final currentXP = ref.watch(xpProvider);
    final selectedMarket = ref.watch(selectedMarketProvider);
    final marketDataAsync = ref.watch(currentMarketDataProvider);
    final selectedAssetConfig = _assetConfig[selectedMarket] ?? _assetConfig['HSI-HKD']!;
    
    // Weather providers
    final weatherDisplay = ref.watch(weatherDisplayProvider);
    final isRaining = ref.watch(isRainingProvider);
    final weatherStateAsync = ref.watch(weatherStateProvider);
    final weatherActions = ref.read(weatherActionsProvider);
    
    // Territory providers
    final selectedTerritory = ref.watch(selectedTerritoryProvider);
    final userPrestige = ref.watch(userPrestigeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A), // Dark night sky
              Color(0xFF1A1A2E), // Deep purple
              Color(0xFF16213E), // Darker blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Rain effect overlay
            Positioned.fill(
              child: CustomPaint(
                painter: RainPainter(),
              ),
            ),
            
            // Neon street lights
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                width: 4,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFF00FFFF),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00FFFF).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            
            // Hong Kong street wall background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/hong_kong_wall.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.6),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
            
            // Water puddle reflections
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFF001122).withOpacity(0.8),
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: WaterReflectionPainter(),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Neon street sign header
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Neon glow effect for title
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFFFF0080),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF0080).withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            '中環金融區',
                            style: TextStyle(
                              color: Color(0xFFFF0080),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFF0080),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'CENTRAL DISTRICT • STREET ART CLASH',
                          style: TextStyle(
                            color: Color(0xFF00FFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: Color(0xFF00FFFF),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Main spray paint trading area
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Color(0xFF00FF41).withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00FF41).withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Spray can icon
                          Icon(
                            Icons.format_paint,
                            size: 80,
                            color: Color(0xFFFF0080),
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF0080),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // Spray paint instruction
                          Text(
                            'SPRAY YOUR TRADE',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Gesture-based trading on Hong Kong walls',
                            style: TextStyle(
                              color: Color(0xFF00FFFF),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 30),
                          
                          // Trading status
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                            decoration: BoxDecoration(
                              color: Color(0xFF001122),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Color(0xFF00FFFF),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: Color(0xFF00FFFF),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Rain falling • Markets volatile',
                                  style: TextStyle(
                                    color: Color(0xFF00FFFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom neon indicators
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNeonIndicator('INK', '$currentInk', Color(0xFFFFFF00)),
                        _buildNeonIndicator('XP', '$currentXP', Color(0xFF00FF41)),
                        _buildNeonIndicator('ETH', '${(2.5).toStringAsFixed(2)}', Color(0xFFFF0080)),
                      ],
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

  Widget _buildNeonIndicator(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: color,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: StreetCredDesignSystem.captionStyle().copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: StreetCredDesignSystem.spacingXS),
        Text(
          value,
          style: StreetCredDesignSystem.bodyStyle().copyWith(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatVolume(String volume) {
    try {
      final vol = double.parse(volume);
      if (vol >= 1e9) {
        return '${(vol / 1e9).toStringAsFixed(1)}B';
      } else if (vol >= 1e6) {
        return '${(vol / 1e6).toStringAsFixed(1)}M';
      } else if (vol >= 1e3) {
        return '${(vol / 1e3).toStringAsFixed(1)}K';
      }
      return vol.toStringAsFixed(0);
    } catch (e) {
      return volume;
    }
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StreetCredTheme.neonPink.withValues(alpha: 0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw animated grid pattern
    for (int i = 0; i < size.width; i += 50) {
      final x = (i + animationValue * 50) % size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i < size.height; i += 50) {
      final y = (i + animationValue * 50) % size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FFFF).withOpacity(0.3)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final random = Math.Random(DateTime.now().millisecondsSinceEpoch ~/ 100);
    
    // Draw rain drops
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = 10 + random.nextDouble() * 20;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 2, y + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WaterReflectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF00FFFF).withOpacity(0.1),
          Color(0xFFFF0080).withOpacity(0.1),
          Color(0xFF00FF41).withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw ripple effects
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 20.0;
      final center = Offset(size.width * 0.3 + i * 50, size.height * 0.7);
      
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Color(0xFF00FFFF).withOpacity(0.1 - i * 0.02)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    
    // Draw water surface with neon reflections
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    
    for (double x = 0; x <= size.width; x += 10) {
      final y = size.height * 0.8 + Math.sin(x * 0.02) * 3;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
