import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'dart:async';
import '../app/theme/street_cred_theme.dart';
import '../providers/ink_provider.dart';
import '../providers/xp_provider.dart';

class TradingScreen extends ConsumerStatefulWidget {
  final String assetPair;

  const TradingScreen({Key? key, required this.assetPair}) : super(key: key);

  @override
  ConsumerState<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends ConsumerState<TradingScreen>
    with TickerProviderStateMixin {
  late AnimationController _sprayController;
  late AnimationController _leverageController;
  late Animation<double> _sprayAnimation;
  late Animation<double> _leverageAnimation;
  
  double _currentLeverage = 1.0;
  bool _isTrading = false;
  bool _isHolding = false;
  List<SprayParticle> _particles = [];
  
  // Hold-for-leverage state
  DateTime? _holdStartTime;
  Offset? _holdPosition;
  Timer? _leverageTimer;
  
  @override
  void initState() {
    super.initState();
    
    _sprayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _leverageController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _sprayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sprayController, curve: Curves.easeOut),
    );
    
    _leverageAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _leverageController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sprayController.dispose();
    _leverageController.dispose();
    _leverageTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isTrading) return;
    
    setState(() {
      _isHolding = true;
      _holdStartTime = DateTime.now();
      _holdPosition = details.localPosition;
      _currentLeverage = 1.0;
    });
    
    // Start leverage timer
    _leverageTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_isHolding) {
        timer.cancel();
        return;
      }
      
      final holdDuration = DateTime.now().difference(_holdStartTime!).inMilliseconds;
      final newLeverage = (1.0 + (holdDuration / 1000.0) * 2.0).clamp(1.0, 3.0);
      
      setState(() {
        _currentLeverage = newLeverage;
        
        // Add spray particles at hold position with enhanced effects
        if (_holdPosition != null) {
          final random = math.Random();
          final leverageIntensity = _currentLeverage;
          
          // Generate multiple particles per frame for more spray effect
          final particleCount = (2 + leverageIntensity * 2).round();
          
          for (int i = 0; i < particleCount; i++) {
            // Spray pattern spreads out more with higher leverage
            final spreadRadius = 20.0 + (leverageIntensity - 1.0) * 15.0;
            final angle = random.nextDouble() * 2 * math.pi;
            final distance = random.nextDouble() * spreadRadius;
            
            final particlePos = Offset(
              _holdPosition!.dx + math.cos(angle) * distance,
              _holdPosition!.dy + math.sin(angle) * distance,
            );
            
            // Color transitions based on leverage
            final leverageProgress = (_currentLeverage - 1.0) / 2.0;
            final particleColor = Color.lerp(
              Color(0xFFFF0080), // Pink at 1x
              Color(0xFFFFFF00), // Yellow at 3x
              leverageProgress,
            )!;
            
            _particles.add(SprayParticle(
              position: particlePos,
              color: particleColor,
              size: random.nextDouble() * 4 + 1,
              velocity: Offset(
                (random.nextDouble() - 0.5) * 25,
                random.nextDouble() * -30 - 10,
              ),
              opacity: 0.7 + random.nextDouble() * 0.3,
            ));
          }
          
          // Keep particles manageable but allow more for higher leverage
          final maxParticles = (50 + leverageIntensity * 20).round();
          while (_particles.length > maxParticles) {
            _particles.removeAt(0);
          }
        }
      });
      
      // Animate leverage controller
      _leverageController.forward(from: 0.0);
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isTrading || !_isHolding) return;
    
    _leverageTimer?.cancel();
    
    setState(() {
      _isHolding = false;
    });
    
    // Determine direction based on hold position
    if (_holdPosition != null) {
      final screenHeight = MediaQuery.of(context).size.height;
      final centerY = screenHeight / 2;
      final direction = _holdPosition!.dy < centerY ? 'LONG' : 'SHORT';
      
      _executeTrade(direction);
    }
  }

  void _handlePanCancel() {
    _leverageTimer?.cancel();
    setState(() {
      _isHolding = false;
      _currentLeverage = 1.0;
    });
  }

  void _executeTrade(String direction) async {
    if (_isTrading) return;
    
    final inkCost = (_currentLeverage * 10).round();
    final currentInk = ref.read(inkProvider);
    
    if (currentInk < inkCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough ink! Need $inkCost, have $currentInk'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isTrading = true);
    _sprayController.forward();
    
    // Consume ink
    ref.read(inkProvider.notifier).spendInk(inkCost);
    
    // Simulate trade result
    await Future.delayed(Duration(milliseconds: 1500));
    
    final random = math.Random();
    final pnl = (random.nextDouble() - 0.5) * 200 * _currentLeverage;
    final xpGained = 10 + (_currentLeverage * 2).round();
    
    // Gain XP
    ref.read(xpProvider.notifier).gainXP(xpGained);
    
    // Navigate to result screen
    if (mounted) {
      context.push('/trade-result', extra: {
        'asset': widget.assetPair,
        'direction': direction,
        'leverage': _currentLeverage,
        'pnl': pnl,
        'xpGained': xpGained,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInk = ref.watch(inkProvider);
    final inkCost = (_currentLeverage * 10).round();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.assetPair,
          style: TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
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
            
            // Spray particles
            Positioned.fill(
              child: CustomPaint(
                painter: SprayParticlesPainter(_particles),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 60), // Account for app bar
                  
                  // Status info
                  Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF00FFFF).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusItem('INK', '$currentInk', Color(0xFFFFFF00)),
                        _buildStatusItem('LEVERAGE', '${_currentLeverage.toStringAsFixed(1)}x', Color(0xFFFF0080)),
                        _buildStatusItem('COST', '$inkCost', Color(0xFF00FF41)),
                      ],
                    ),
                  ),
                  
                  // Trading canvas
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFF00FF41).withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: GestureDetector(
                        onTapDown: _handleTapDown,
                        onTapUp: _handleTapUp,
                        onTapCancel: _handlePanCancel,
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: Stack(
                            children: [
                              // Main spray paint area
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Spray can icon with leverage animation
                                    AnimatedBuilder(
                                      animation: _leverageAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _isHolding 
                                            ? 1.0 + (_currentLeverage - 1.0) * 0.3 
                                            : 1.0,
                                          child: Icon(
                                            Icons.format_paint,
                                            size: 80,
                                            color: _isHolding 
                                              ? Color.lerp(Color(0xFFFF0080), Color(0xFFFFFF00), (_currentLeverage - 1.0) / 2.0)
                                              : Color(0xFFFF0080),
                                          ),
                                        );
                                      },
                                    ),
                                    
                                    SizedBox(height: 20),
                                    
                                    if (!_isTrading) ...[
                                      Text(
                                        'HOLD TO SPRAY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'TOP HALF = LONG • BOTTOM HALF = SHORT\nHold longer for more leverage',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ] else ...[
                                      Text(
                                        'EXECUTING TRADE...',
                                        style: TextStyle(
                                          color: Color(0xFF00FFFF),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Expanding circle indicator for leverage
                              if (_isHolding && _holdPosition != null)
                                Positioned(
                                  left: _holdPosition!.dx - (25 + (_currentLeverage - 1.0) * 25),
                                  top: _holdPosition!.dy - (25 + (_currentLeverage - 1.0) * 25),
                                  child: AnimatedBuilder(
                                    animation: _leverageAnimation,
                                    builder: (context, child) {
                                      final radius = 25 + (_currentLeverage - 1.0) * 25;
                                      return Container(
                                        width: radius * 2,
                                        height: radius * 2,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Color.lerp(
                                              Color(0xFFFF0080), 
                                              Color(0xFFFFFF00), 
                                              (_currentLeverage - 1.0) / 2.0
                                            )!.withOpacity(0.8),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color.lerp(
                                                Color(0xFFFF0080), 
                                                Color(0xFFFFFF00), 
                                                (_currentLeverage - 1.0) / 2.0
                                              )!.withOpacity(0.4),
                                              blurRadius: 15,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${_currentLeverage.toStringAsFixed(1)}x',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              
                              // Direction indicator line
                              if (_isHolding)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: DirectionIndicatorPainter(
                                      holdPosition: _holdPosition,
                                      screenSize: MediaQuery.of(context).size,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Instructions footer
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInstructionItem('TOP HALF', 'LONG', Color(0xFF00FF41)),
                        _buildInstructionItem('BOTTOM HALF', 'SHORT', Color(0xFFFF4444)),
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

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
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
    );
  }

  Widget _buildInstructionItem(String area, String direction, Color color) {
    return Column(
      children: [
        Text(
          area,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            direction,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class SprayParticle {
  Offset position;
  final Color color;
  final double size;
  Offset velocity;
  double life = 1.0;
  final double opacity;

  SprayParticle({
    required this.position,
    required this.color,
    required this.size,
    required this.velocity,
    this.opacity = 1.0,
  });

  void update() {
    position += velocity;
    velocity += Offset(0, 0.5); // Gravity
    life -= 0.02;
  }
}

class SprayParticlesPainter extends CustomPainter {
  final List<SprayParticle> particles;

  SprayParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      if (particle.life > 0) {
        final paint = Paint()
          ..color = particle.color.withOpacity(particle.life * particle.opacity)
          ..style = PaintingStyle.fill;
        
        // Draw main particle
        canvas.drawCircle(
          particle.position,
          particle.size * particle.life,
          paint,
        );
        
        // Add glow effect for larger particles
        if (particle.size > 2.0) {
          final glowPaint = Paint()
            ..color = particle.color.withOpacity(particle.life * particle.opacity * 0.3)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(
            particle.position,
            particle.size * particle.life * 2.0,
            glowPaint,
          );
        }
        
        particle.update();
      }
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

    final random = DateTime.now().millisecondsSinceEpoch ~/ 100;
    
    for (int i = 0; i < 30; i++) {
      final seed = random + i;
      final x = (seed * 1234567) % size.width.toInt();
      final y = (seed * 7654321) % size.height.toInt();
      final length = 8 + (seed % 12);
      
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

class DirectionIndicatorPainter extends CustomPainter {
  final Offset? holdPosition;
  final Size screenSize;

  DirectionIndicatorPainter({
    required this.holdPosition,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (holdPosition == null) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    final isLong = holdPosition!.dy < centerY;
    
    // Set color based on direction
    paint.color = isLong 
      ? Color(0xFF00FF41).withOpacity(0.6)
      : Color(0xFFFF4444).withOpacity(0.6);

    // Draw horizontal line across screen at center
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint..strokeWidth = 1..color = Colors.white.withOpacity(0.3),
    );

    // Draw direction arrow
    final arrowStart = holdPosition!;
    final arrowEnd = Offset(
      holdPosition!.dx,
      isLong ? holdPosition!.dy - 40 : holdPosition!.dy + 40,
    );

    // Arrow line
    canvas.drawLine(arrowStart, arrowEnd, paint..strokeWidth = 3);

    // Arrow head
    final arrowHeadSize = 15.0;
    final arrowHeadAngle = isLong ? math.pi / 2 : -math.pi / 2;
    
    final arrowHead1 = Offset(
      arrowEnd.dx + arrowHeadSize * math.cos(arrowHeadAngle - 0.5),
      arrowEnd.dy + arrowHeadSize * math.sin(arrowHeadAngle - 0.5),
    );
    
    final arrowHead2 = Offset(
      arrowEnd.dx + arrowHeadSize * math.cos(arrowHeadAngle + 0.5),
      arrowEnd.dy + arrowHeadSize * math.sin(arrowHeadAngle + 0.5),
    );

    canvas.drawLine(arrowEnd, arrowHead1, paint);
    canvas.drawLine(arrowEnd, arrowHead2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}