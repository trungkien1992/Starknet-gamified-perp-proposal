import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Asset display configuration mapped to Extended Exchange markets
  final Map<String, Map<String, dynamic>> _assetConfig = {
    'BTC-USDT': {
      'symbol': 'BTC',
      'name': 'Bitcoin',
      'icon': Icons.currency_bitcoin,
      'color': Color(0xFFF7931A), // Bitcoin orange
    },
    'ETH-USDT': {
      'symbol': 'ETH',
      'name': 'Ethereum',
      'icon': Icons.diamond,
      'color': Color(0xFF627EEA), // Ethereum blue
    },
    'STRK-USDT': {
      'symbol': 'STRK',
      'name': 'Starknet',
      'icon': Icons.blur_on,
      'color': Color(0xFF8C8DFC), // Starknet purple
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

    // Deduct ink based on leverage
    final inkCost = (leverage * 10).round();
    inkNotifier.spendInk(inkCost);

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

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trade executed: $direction (x${leverage.toStringAsFixed(1)}) - Order ID: ${orderResponse.orderId}',
            style: StreetCredTheme.graffitiBody,
          ),
          backgroundColor: direction == 'LONG'
              ? StreetCredTheme.longColor
              : StreetCredTheme.shortColor,
          duration: const Duration(seconds: 3),
        ),
      );
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
    final selectedAssetConfig = _assetConfig[selectedMarket] ?? _assetConfig['BTC-USDT']!;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: StreetCredDesignSystem.backgroundGradient(
              selectedAssetConfig['color'],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header using design system
                  StreetCredHeader(
                    title: 'STREETCRED CLASH',
                    themeColor: selectedAssetConfig['color'],
                    showBrandSymbol: false,
                    actions: [
                      // Ink Display with pulse animation
                      AnimatedBuilder(
                        animation: _inkPulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _inkPulseAnimation.value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration:
                                      StreetCredDesignSystem.statusBadgeDecoration(
                                        StreetCredTheme.neonYellow,
                                      ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.brush,
                                        color: StreetCredTheme.neonYellow,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$currentInk',
                                        style:
                                            StreetCredDesignSystem.bodyStyle()
                                                .copyWith(
                                                  color: StreetCredTheme
                                                      .neonYellow,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration:
                                      StreetCredDesignSystem.statusBadgeDecoration(
                                        StreetCredTheme.neonBlue,
                                      ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: StreetCredTheme.neonBlue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$currentXP XP',
                                        style:
                                            StreetCredDesignSystem.bodyStyle()
                                                .copyWith(
                                                  color:
                                                      StreetCredTheme.neonBlue,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      scb.StreetCredButton(
                        text: '',
                        themeColor: selectedAssetConfig['color'],
                        style: scb.ButtonStyle.navigation,
                        leadingIcon: Icons.person,
                        onPressed: () => context.go('/profile'),
                      ),
                    ],
                  ),

                  // Animated background pattern
                  Expanded(
                    child: Stack(
                      children: [
                        // Animated background
                        AnimatedBuilder(
                          animation: _backgroundAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: _BackgroundPainter(
                                animationValue: _backgroundAnimation.value,
                              ),
                            );
                          },
                        ),

                        // Main content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Market Display Section using design system
                              StreetCredCard(
                                themeColor: selectedAssetConfig['color'],
                                size: CardSize.large,
                                enablePressEffect: false,
                                child: marketDataAsync.when(
                                  data: (marketData) => Column(
                                    children: [
                                      // Asset Pair Display
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                selectedAssetConfig['icon'],
                                                color: selectedAssetConfig['color'],
                                                size: 24,
                                              ),
                                              const SizedBox(
                                                width: StreetCredDesignSystem
                                                    .spacingM,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    selectedMarket,
                                                    style:
                                                        StreetCredDesignSystem.subtitleStyle(
                                                          selectedAssetConfig['color'],
                                                        ).copyWith(
                                                          fontSize: 18,
                                                          letterSpacing: 1,
                                                        ),
                                                  ),
                                                  const SizedBox(
                                                    height: StreetCredDesignSystem
                                                        .spacingXS,
                                                  ),
                                                  Text(
                                                    '\$${marketData.price}',
                                                    style:
                                                        StreetCredDesignSystem.bodyStyle()
                                                            .copyWith(
                                                              color: marketData.isPositive
                                                                  ? StreetCredTheme.longColor
                                                                  : StreetCredTheme.shortColor,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                            ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          // Market Status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal:
                                                  StreetCredDesignSystem.spacingM,
                                              vertical:
                                                  StreetCredDesignSystem.spacingS,
                                            ),
                                            decoration:
                                                StreetCredDesignSystem.statusBadgeDecoration(
                                                  marketData.isPositive
                                                      ? StreetCredTheme.longColor
                                                      : StreetCredTheme.shortColor,
                                                ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.fiber_manual_record,
                                                  color: marketData.isPositive
                                                      ? StreetCredTheme.longColor
                                                      : StreetCredTheme.shortColor,
                                                  size: 8,
                                                ),
                                                const SizedBox(
                                                  width: StreetCredDesignSystem
                                                      .spacingS,
                                                ),
                                                Text(
                                                  marketData.isPositive ? 'BULLISH' : 'BEARISH',
                                                  style:
                                                      StreetCredDesignSystem.captionStyle()
                                                          .copyWith(
                                                            color: marketData.isPositive
                                                                ? StreetCredTheme.longColor
                                                                : StreetCredTheme.shortColor,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: StreetCredDesignSystem.spacingL,
                                      ),

                                      // Market Stats
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildMarketStat(
                                            '24h Change',
                                            '${marketData.changePercent >= 0 ? '+' : ''}${marketData.changePercent.toStringAsFixed(2)}%',
                                            marketData.isPositive
                                                ? StreetCredTheme.longColor
                                                : StreetCredTheme.shortColor,
                                          ),
                                          _buildMarketStat(
                                            'Volume',
                                            '\$${_formatVolume(marketData.volume24h)}',
                                            Colors.grey[400]!,
                                          ),
                                          _buildMarketStat(
                                            'High/Low',
                                            '${marketData.high24h}/${marketData.low24h}',
                                            StreetCredTheme.neonYellow,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  loading: () => Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            selectedAssetConfig['icon'],
                                            color: selectedAssetConfig['color'],
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedMarket,
                                                style: StreetCredDesignSystem.subtitleStyle(
                                                  selectedAssetConfig['color'],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Loading...',
                                                style: StreetCredDesignSystem.bodyStyle(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  error: (error, stack) => Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            selectedAssetConfig['icon'],
                                            color: selectedAssetConfig['color'],
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedMarket,
                                                style: StreetCredDesignSystem.subtitleStyle(
                                                  selectedAssetConfig['color'],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Market data unavailable',
                                                style: StreetCredDesignSystem.bodyStyle()
                                                    .copyWith(color: Colors.red),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                    if (walletState.isConnected) ...[
                                      const SizedBox(
                                        height: StreetCredDesignSystem.spacingL,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              StreetCredDesignSystem.spacingM,
                                          vertical:
                                              StreetCredDesignSystem.spacingS,
                                        ),
                                        decoration:
                                            StreetCredDesignSystem.statusBadgeDecoration(
                                              StreetCredTheme.neonGreen,
                                            ),
                                        child: Text(
                                          'READY TO TRADE',
                                          style:
                                              StreetCredDesignSystem.captionStyle()
                                                  .copyWith(
                                                    color: StreetCredTheme
                                                        .neonGreen,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Spray paint swipe area
                              Expanded(
                                child: Stack(
                                  children: [
                                    SwipeSprayGauge(
                                      isEnabled:
                                          walletState.isConnected &&
                                          currentInk > 0,
                                      onTrade: (direction, leverage) {
                                        setState(() => showHandDemo = false);
                                        // Deduct ink based on leverage
                                        final inkCost = (leverage * 10).round();
                                        if (currentInk >= inkCost) {
                                          _onTradeExecuted(leverage, direction);
                                        } else {
                                          // Not enough ink
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Not enough ink!',
                                                style: StreetCredTheme
                                                    .graffitiBody,
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    if (showHandDemo) const HandDemoAnimation(),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const RewardWidget(),
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
