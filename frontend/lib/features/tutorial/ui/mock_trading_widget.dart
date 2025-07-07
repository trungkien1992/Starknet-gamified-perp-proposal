import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../models/tutorial_models.dart';
import '../providers/tutorial_providers.dart';
import '../../trade/widgets/swipe_spray_gauge.dart';

class MockTradingWidget extends ConsumerStatefulWidget {
  final String asset;
  final Function(MockTrade) onTradeExecuted;

  const MockTradingWidget({
    Key? key,
    required this.asset,
    required this.onTradeExecuted,
  }) : super(key: key);

  @override
  ConsumerState<MockTradingWidget> createState() => _MockTradingWidgetState();
}

class _MockTradingWidgetState extends ConsumerState<MockTradingWidget>
    with TickerProviderStateMixin {
  late AnimationController _priceController;
  late AnimationController _executeController;
  late Animation<double> _priceAnimation;
  late Animation<double> _executeAnimation;
  
  double _leverage = 2.0;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    
    _priceController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _executeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _priceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _priceController, curve: Curves.easeInOut),
    );

    _executeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _executeController, curve: Curves.elasticOut),
    );

    _priceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _executeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mockData = ref.watch(mockMarketDataProvider(widget.asset));
    final basePrice = ref.watch(mockPriceProvider(widget.asset));

    return Column(
      children: [
        // Market display
        _buildMarketDisplay(mockData, basePrice),
        
        const SizedBox(height: 20),
        
        // Leverage control
        _buildLeverageControl(),
        
        const SizedBox(height: 20),
        
        // Trading interface
        _buildTradingInterface(),
        
        // Execution feedback
        if (_isExecuting)
          _buildExecutionFeedback(),
      ],
    );
  }

  Widget _buildMarketDisplay(Map<String, dynamic> mockData, double basePrice) {
    return StreetCredCard(
      themeColor: StreetCredTheme.neonBlue,
      size: CardSize.medium,
      enablePressEffect: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.asset,
                    style: StreetCredDesignSystem.subtitleStyle(
                      StreetCredTheme.neonBlue,
                    ).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _priceAnimation,
                    builder: (context, child) {
                      // Simulate price movement
                      final priceVariation = ((_priceAnimation.value - 0.5) * 100);
                      final currentPrice = basePrice + priceVariation;
                      final isPositive = priceVariation >= 0;
                      
                      return Text(
                        '\$${currentPrice.toStringAsFixed(2)}',
                        style: StreetCredDesignSystem.bodyStyle().copyWith(
                          color: isPositive 
                              ? StreetCredTheme.longColor 
                              : StreetCredTheme.shortColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: StreetCredDesignSystem.statusBadgeDecoration(
                  StreetCredTheme.neonGreen,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: StreetCredTheme.neonGreen,
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'DEMO MODE',
                      style: StreetCredDesignSystem.captionStyle().copyWith(
                        color: StreetCredTheme.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Mock stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMockStat('24h Change', '${mockData['change']}%', 
                  mockData['isPositive'] ? StreetCredTheme.longColor : StreetCredTheme.shortColor),
              _buildMockStat('Volume', mockData['volume'], Colors.grey[400]!),
              _buildMockStat('High/Low', '${mockData['high24h']}/${mockData['low24h']}', 
                  StreetCredTheme.neonYellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: StreetCredDesignSystem.bodyStyle().copyWith(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLeverageControl() {
    return StreetCredCard(
      themeColor: StreetCredTheme.neonYellow,
      size: CardSize.small,
      enablePressEffect: false,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEVERAGE',
                style: StreetCredDesignSystem.subtitleStyle(
                  StreetCredTheme.neonYellow,
                ).copyWith(fontSize: 14),
              ),
              Text(
                '${_leverage.toStringAsFixed(1)}x',
                style: StreetCredDesignSystem.titleStyle(Colors.white).copyWith(
                  fontSize: 18,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Slider(
            value: _leverage,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            activeColor: StreetCredTheme.neonYellow,
            inactiveColor: Colors.white24,
            onChanged: (value) {
              setState(() {
                _leverage = value;
              });
            },
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risk Level: ${_getRiskLevel(_leverage)}',
                style: StreetCredDesignSystem.captionStyle().copyWith(
                  fontSize: 10,
                  color: _getRiskColor(_leverage),
                ),
              ),
              Text(
                'Max Profit: ${(_leverage * 100).toStringAsFixed(0)}%',
                style: StreetCredDesignSystem.captionStyle().copyWith(
                  fontSize: 10,
                  color: StreetCredTheme.longColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradingInterface() {
    return Container(
      height: 200,
      child: SwipeSprayGauge(
        isEnabled: !_isExecuting,
        isDemoMode: true,
        onTrade: (direction, leverage) => _executeMockTrade(direction, _leverage),
      ),
    );
  }

  Widget _buildExecutionFeedback() {
    return AnimatedBuilder(
      animation: _executeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _executeAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  StreetCredTheme.neonGreen.withValues(alpha: 0.3),
                  StreetCredTheme.neonBlue.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StreetCredTheme.neonGreen, width: 2),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: StreetCredTheme.neonGreen,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'TRADE EXECUTED!',
                  style: StreetCredDesignSystem.titleStyle(StreetCredTheme.neonGreen).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Practice trade completed successfully',
                  style: StreetCredDesignSystem.captionStyle().copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRiskLevel(double leverage) {
    if (leverage <= 2.0) return 'LOW';
    if (leverage <= 5.0) return 'MEDIUM';
    if (leverage <= 8.0) return 'HIGH';
    return 'EXTREME';
  }

  Color _getRiskColor(double leverage) {
    if (leverage <= 2.0) return StreetCredTheme.neonGreen;
    if (leverage <= 5.0) return StreetCredTheme.neonYellow;
    if (leverage <= 8.0) return Colors.orange;
    return StreetCredTheme.shortColor;
  }

  void _executeMockTrade(String direction, double leverage) async {
    setState(() {
      _isExecuting = true;
    });

    _executeController.forward();

    // Generate mock trade
    final mockTrade = ref.read(tutorialServiceProvider).executeMockTrade(
      asset: widget.asset,
      direction: direction,
      leverage: leverage,
    );

    // Simulate execution delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Show result
    _showTradeResult(mockTrade);

    // Call callback
    widget.onTradeExecuted(mockTrade);

    // Reset state
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
        _executeController.reset();
      }
    });
  }

  void _showTradeResult(MockTrade trade) {
    final isWin = trade.isWin;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWin ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mock Trade ${isWin ? 'Profit' : 'Loss'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${trade.direction} ${trade.asset} ${trade.leverage}x: ${trade.pnl.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isWin ? StreetCredTheme.longColor : StreetCredTheme.shortColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}