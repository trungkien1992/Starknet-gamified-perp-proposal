import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/street_art_models.dart';
import '../providers/street_art_provider.dart';
import '../../../features/trade/state/ink_providers.dart';
import '../../../state/xp_provider.dart';
import 'widgets/spray_tool_selector.dart';
import 'widgets/art_style_selector.dart';
import 'widgets/creation_progress_widget.dart';
import 'widgets/volatility_indicator.dart';
import 'package:go_router/go_router.dart';

class StreetArtCreationScreen extends ConsumerStatefulWidget {
  const StreetArtCreationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StreetArtCreationScreen> createState() => _StreetArtCreationScreenState();
}

class _StreetArtCreationScreenState extends ConsumerState<StreetArtCreationScreen>
    with TickerProviderStateMixin {
  late AnimationController _neonController;
  late AnimationController _rainController;
  late Animation<double> _neonAnimation;
  late Animation<double> _rainAnimation;
  
  double _leverageSlider = 1.0;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    
    _neonController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rainController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _neonAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _neonController, curve: Curves.easeInOut),
    );
    
    _rainAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rainController, curve: Curves.linear),
    );
    
    _neonController.repeat(reverse: true);
    _rainController.repeat();
  }

  @override
  void dispose() {
    _neonController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  Future<void> _createStreetArt() async {
    if (_isCreating) return;
    
    final selectedTool = ref.read(selectedSprayToolProvider);
    final selectedStyle = ref.read(selectedArtStyleProvider);
    final currentDistrict = ref.read(currentDistrictProvider);
    final streetArtService = ref.read(streetArtServiceProvider);
    final volatility = ref.read(nightlifeVolatilityProvider);
    final currentInk = ref.read(inkProvider);
    
    // Calculate ink cost
    final inkCost = streetArtService.calculateInkCost(
      selectedStyle,
      selectedTool,
      _leverageSlider,
    );
    
    if (currentInk < inkCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough ink! Need $inkCost, have $currentInk',
            style: StreetCredTheme.graffitiBody,
          ),
          backgroundColor: StreetCredTheme.shortColor,
        ),
      );
      return;
    }
    
    setState(() => _isCreating = true);
    
    // Deduct ink
    ref.read(inkProvider.notifier).spendInk(inkCost);
    
    // Add haptic feedback
    HapticFeedback.heavyImpact();
    
    try {
      final streetArtPiece = await streetArtService.createStreetArt(
        style: selectedStyle,
        tool: selectedTool,
        location: currentDistrict.displayName,
        leverage: _leverageSlider,
        volatility: volatility,
      );
      
      // Add piece to collection
      ref.read(streetArtPiecesProvider.notifier).addPiece(streetArtPiece);
      
      // Calculate and award XP
      final xpReward = streetArtService.calculateXPReward(streetArtPiece, volatility);
      ref.read(xpProvider.notifier).addXP(xpReward.round());
      
      // Show success/failure feedback
      final isSuccess = streetArtPiece.isSuccessful;
      final message = isSuccess
          ? 'Art completed! +${xpReward.round()} XP'
          : 'Caught! Art failed... +${(xpReward * 0.3).round()} XP';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: StreetCredTheme.graffitiBody),
          backgroundColor: isSuccess 
              ? StreetCredTheme.longColor 
              : StreetCredTheme.shortColor,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Navigate back or to gallery
      if (isSuccess) {
        context.go('/gallery');
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creation failed: $e', style: StreetCredTheme.graffitiBody),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTool = ref.watch(selectedSprayToolProvider);
    final selectedStyle = ref.watch(selectedArtStyleProvider);
    final currentDistrict = ref.watch(currentDistrictProvider);
    final volatility = ref.watch(nightlifeVolatilityProvider);
    final currentInk = ref.watch(inkProvider);
    final streetArtService = ref.read(streetArtServiceProvider);
    
    final inkCost = streetArtService.calculateInkCost(
      selectedStyle,
      selectedTool,
      _leverageSlider,
    );
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/districts'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated background
          Container(
            decoration: BoxDecoration(
              gradient: StreetCredTheme.rainReflectionGradient,
            ),
          ),
          
          // Rain effect
          AnimatedBuilder(
            animation: _rainAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _RainPainter(animationValue: _rainAnimation.value),
              );
            },
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  StreetCredHeader(
                    title: 'CREATE STREET ART',
                    themeColor: currentDistrict.districtColor,
                    showBrandSymbol: false,
                    actions: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: StreetCredDesignSystem.statusBadgeDecoration(
                          StreetCredTheme.neonYellow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.brush, color: StreetCredTheme.neonYellow, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$currentInk',
                              style: StreetCredDesignSystem.bodyStyle().copyWith(
                                color: StreetCredTheme.neonYellow,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // District info
                  StreetCredCard(
                    themeColor: currentDistrict.districtColor,
                    size: CardSize.medium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentDistrict.displayName,
                          style: StreetCredDesignSystem.subtitleStyle(currentDistrict.districtColor),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: currentDistrict.districtColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Risk Level: ${(currentDistrict.riskLevel * 100).toStringAsFixed(0)}%',
                              style: StreetCredDesignSystem.bodyStyle(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Volatility indicator
                  VolatilityIndicator(volatility: volatility),
                  
                  const SizedBox(height: 20),
                  
                  // Tool selector
                  const SprayToolSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // Art style selector
                  const ArtStyleSelector(),
                  
                  const SizedBox(height: 20),
                  
                  // Leverage slider
                  StreetCredCard(
                    themeColor: StreetCredTheme.neonBlue,
                    size: CardSize.medium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leverage (Risk Level)',
                          style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonBlue),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '1x',
                              style: StreetCredDesignSystem.bodyStyle(),
                            ),
                            Expanded(
                              child: Slider(
                                value: _leverageSlider,
                                min: 1.0,
                                max: 10.0,
                                divisions: 9,
                                activeColor: StreetCredTheme.neonBlue,
                                inactiveColor: StreetCredTheme.neonBlue.withValues(alpha: 0.3),
                                onChanged: (value) {
                                  setState(() => _leverageSlider = value);
                                },
                              ),
                            ),
                            Text(
                              '10x',
                              style: StreetCredDesignSystem.bodyStyle(),
                            ),
                          ],
                        ),
                        Center(
                          child: Text(
                            '${_leverageSlider.toStringAsFixed(1)}x',
                            style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Cost display
                  StreetCredCard(
                    themeColor: StreetCredTheme.neonYellow,
                    size: CardSize.small,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ink Cost:',
                          style: StreetCredDesignSystem.bodyStyle(),
                        ),
                        Text(
                          '$inkCost',
                          style: StreetCredDesignSystem.bodyStyle().copyWith(
                            color: inkCost > currentInk 
                                ? StreetCredTheme.shortColor 
                                : StreetCredTheme.neonYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Create button
                  if (_isCreating) ...[
                    const CreationProgressWidget(),
                  ] else ...[
                    Center(
                      child: AnimatedBuilder(
                        animation: _neonAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _neonAnimation.value,
                            child: scb.StreetCredButton(
                              text: 'START CREATING',
                              themeColor: currentDistrict.districtColor,
                              style: scb.ButtonStyle.primary,
                              onPressed: inkCost <= currentInk ? _createStreetArt : null,
                              leadingIcon: Icons.brush,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double animationValue;
  
  _RainPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StreetCredTheme.neonBlue.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    
    for (int i = 0; i < 50; i++) {
      final x = (i * 15.0) % size.width;
      final y = (animationValue * size.height * 2 + i * 20) % size.height;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 5, y + 20),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}