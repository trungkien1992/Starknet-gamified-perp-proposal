import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

class TradeResultScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> tradeData;

  const TradeResultScreen({Key? key, required this.tradeData}) : super(key: key);

  @override
  ConsumerState<TradeResultScreen> createState() => _TradeResultScreenState();
}

class _TradeResultScreenState extends ConsumerState<TradeResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _resultController;
  late AnimationController _artController;
  late Animation<double> _resultAnimation;
  late Animation<double> _artAnimation;

  @override
  void initState() {
    super.initState();
    
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _artController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _resultAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );
    
    _artAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _artController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _resultController.forward();
    Future.delayed(Duration(milliseconds: 400), () {
      _artController.forward();
    });
  }

  @override
  void dispose() {
    _resultController.dispose();
    _artController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = widget.tradeData['asset'] as String;
    final direction = widget.tradeData['direction'] as String;
    final leverage = widget.tradeData['leverage'] as double;
    final pnl = widget.tradeData['pnl'] as double;
    final xpGained = widget.tradeData['xpGained'] as int;
    
    final isProfit = pnl > 0;
    final resultColor = isProfit ? Color(0xFF00FF41) : Color(0xFFFF4444);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Rain effect
            Positioned.fill(
              child: CustomPaint(
                painter: RainPainter(),
              ),
            ),
            
            // Trade art visualization
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _artAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TradeArtPainter(
                      progress: _artAnimation.value,
                      direction: direction,
                      leverage: leverage,
                      isProfit: isProfit,
                    ),
                  );
                },
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'TRADE ART COMPLETED',
                      style: TextStyle(
                        color: Color(0xFF00FFFF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  
                  Spacer(),
                  
                  // Result card
                  AnimatedBuilder(
                    animation: _resultAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _resultAnimation.value,
                        child: Container(
                          margin: EdgeInsets.all(20),
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: resultColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: resultColor.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // P&L result
                              Text(
                                isProfit ? '+\$${pnl.toStringAsFixed(2)}' : '-\$${pnl.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: resultColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                      color: resultColor,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 8),
                              
                              Text(
                                isProfit ? 'PROFIT' : 'LOSS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2,
                                ),
                              ),
                              
                              SizedBox(height: 20),
                              
                              // Trade details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDetailItem('ASSET', asset, Color(0xFF00FFFF)),
                                  _buildDetailItem('DIRECTION', direction, 
                                    direction == 'LONG' ? Color(0xFF00FF41) : Color(0xFFFF4444)),
                                  _buildDetailItem('LEVERAGE', '${leverage.toStringAsFixed(1)}x', Color(0xFFFF0080)),
                                ],
                              ),
                              
                              SizedBox(height: 20),
                              
                              // XP gained
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF00FF41).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Color(0xFF00FF41),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Color(0xFF00FF41),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '+$xpGained XP GAINED',
                                      style: TextStyle(
                                        color: Color(0xFF00FF41),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Action button
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        // Return to asset selection
                        context.go('/');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF0080).withOpacity(0.8),
                              Color(0xFFFF0080).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFFF0080), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF0080).withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'SPRAY AGAIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class TradeArtPainter extends CustomPainter {
  final double progress;
  final String direction;
  final double leverage;
  final bool isProfit;

  TradeArtPainter({
    required this.progress,
    required this.direction,
    required this.leverage,
    required this.isProfit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isProfit 
        ? Color(0xFF00FF41).withOpacity(0.3 * progress)
        : Color(0xFFFF4444).withOpacity(0.3 * progress);

    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw spray paint art based on trade
    if (direction == 'LONG') {
      // Upward spray pattern for LONG
      _drawUpwardSpray(canvas, center, paint, size);
    } else {
      // Downward spray pattern for SHORT
      _drawDownwardSpray(canvas, center, paint, size);
    }
    
    // Add leverage-based intensity
    _addLeverageEffects(canvas, center, size);
  }

  void _drawUpwardSpray(Canvas canvas, Offset center, Paint paint, Size size) {
    final random = math.Random(42); // Fixed seed for consistent art
    
    for (int i = 0; i < (leverage * 20).round(); i++) {
      final angle = (random.nextDouble() - 0.5) * math.pi / 3; // Spread upward
      final distance = random.nextDouble() * 150 * progress;
      final radius = random.nextDouble() * 4 + 1;
      
      final x = center.dx + math.sin(angle) * distance;
      final y = center.dy - math.cos(angle) * distance;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawDownwardSpray(Canvas canvas, Offset center, Paint paint, Size size) {
    final random = math.Random(24); // Different seed for SHORT
    
    for (int i = 0; i < (leverage * 20).round(); i++) {
      final angle = (random.nextDouble() - 0.5) * math.pi / 3 + math.pi; // Spread downward
      final distance = random.nextDouble() * 150 * progress;
      final radius = random.nextDouble() * 4 + 1;
      
      final x = center.dx + math.sin(angle) * distance;
      final y = center.dy - math.cos(angle) * distance;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _addLeverageEffects(Canvas canvas, Offset center, Size size) {
    // Add glow effect for high leverage
    if (leverage > 3.0) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Color(0xFFFF0080).withOpacity(0.5 * progress);
      
      canvas.drawCircle(center, leverage * 20 * progress, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FFFF).withOpacity(0.1)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final random = DateTime.now().millisecondsSinceEpoch ~/ 150;
    
    for (int i = 0; i < 20; i++) {
      final seed = random + i;
      final x = (seed * 1234567) % size.width.toInt();
      final y = (seed * 7654321) % size.height.toInt();
      final length = 6 + (seed % 10);
      
      canvas.drawLine(
        Offset(x.toDouble(), y.toDouble()),
        Offset(x + 1.0, y + length.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}