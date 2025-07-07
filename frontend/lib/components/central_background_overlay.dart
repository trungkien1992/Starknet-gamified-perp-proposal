import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../app/theme/street_cred_theme.dart';

class CentralBackgroundOverlay extends StatefulWidget {
  final Widget? child;
  final Color themeColor;
  final bool isRaining;

  const CentralBackgroundOverlay({
    Key? key,
    this.child,
    required this.themeColor,
    this.isRaining = false,
  }) : super(key: key);

  @override
  State<CentralBackgroundOverlay> createState() => _CentralBackgroundOverlayState();
}

class _CentralBackgroundOverlayState extends State<CentralBackgroundOverlay>
    with TickerProviderStateMixin {
  late AnimationController _buildingController;
  late AnimationController _neonController;
  late AnimationController _fogController;

  @override
  void initState() {
    super.initState();
    
    _buildingController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _neonController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fogController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _neonController.dispose();
    _fogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Central District Silhouette Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                StreetCredTheme.darkAlley,
                widget.themeColor.withValues(alpha: 0.1),
                StreetCredTheme.darkGrey,
              ],
            ),
          ),
        ),

        // Building Silhouettes
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _buildingController,
            builder: (context, child) {
              return CustomPaint(
                painter: CentralSkylinePainter(
                  animationValue: _buildingController.value,
                  themeColor: widget.themeColor,
                  isRaining: widget.isRaining,
                ),
              );
            },
          ),
        ),

        // Neon Glow Effects
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _neonController,
            builder: (context, child) {
              return CustomPaint(
                painter: NeonGlowPainter(
                  animationValue: _neonController.value,
                  themeColor: widget.themeColor,
                ),
              );
            },
          ),
        ),

        // Weather-based atmosphere
        if (widget.isRaining)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fogController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.grey.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Child content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class CentralSkylinePainter extends CustomPainter {
  final double animationValue;
  final Color themeColor;
  final bool isRaining;

  CentralSkylinePainter({
    required this.animationValue,
    required this.themeColor,
    required this.isRaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // IFC Tower silhouette (tallest)
    _drawIFCTower(canvas, size, paint);
    
    // Central Plaza silhouette
    _drawCentralPlaza(canvas, size, paint);
    
    // Bank of China Tower silhouette
    _drawBankOfChinaTower(canvas, size, paint);
    
    // Other Central buildings
    _drawCentralBuildings(canvas, size, paint);
    
    // Window lights
    _drawWindowLights(canvas, size);
  }

  void _drawIFCTower(Canvas canvas, Size size, Paint paint) {
    final ifcHeight = size.height * 0.7;
    final ifcWidth = size.width * 0.08;
    final ifcX = size.width * 0.15;
    
    paint.color = themeColor.withValues(alpha: 0.15);
    
    final ifcPath = Path()
      ..moveTo(ifcX, size.height)
      ..lineTo(ifcX, size.height - ifcHeight)
      ..lineTo(ifcX + ifcWidth * 0.3, size.height - ifcHeight - 20)
      ..lineTo(ifcX + ifcWidth * 0.7, size.height - ifcHeight - 20)
      ..lineTo(ifcX + ifcWidth, size.height - ifcHeight)
      ..lineTo(ifcX + ifcWidth, size.height)
      ..close();
    
    canvas.drawPath(ifcPath, paint);
    
    // IFC spire
    paint.color = themeColor.withValues(alpha: 0.3);
    canvas.drawLine(
      Offset(ifcX + ifcWidth / 2, size.height - ifcHeight - 20),
      Offset(ifcX + ifcWidth / 2, size.height - ifcHeight - 40),
      paint..strokeWidth = 2,
    );
  }

  void _drawCentralPlaza(Canvas canvas, Size size, Paint paint) {
    final plazaHeight = size.height * 0.5;
    final plazaWidth = size.width * 0.12;
    final plazaX = size.width * 0.35;
    
    paint.color = themeColor.withValues(alpha: 0.12);
    paint.style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(plazaX, size.height - plazaHeight, plazaWidth, plazaHeight),
      paint,
    );
  }

  void _drawBankOfChinaTower(Canvas canvas, Size size, Paint paint) {
    final bocHeight = size.height * 0.6;
    final bocWidth = size.width * 0.06;
    final bocX = size.width * 0.55;
    
    paint.color = themeColor.withValues(alpha: 0.1);
    
    final bocPath = Path()
      ..moveTo(bocX, size.height)
      ..lineTo(bocX, size.height - bocHeight * 0.6)
      ..lineTo(bocX + bocWidth / 3, size.height - bocHeight * 0.8)
      ..lineTo(bocX + bocWidth * 2/3, size.height - bocHeight * 0.8)
      ..lineTo(bocX + bocWidth, size.height - bocHeight * 0.6)
      ..lineTo(bocX + bocWidth, size.height - bocHeight)
      ..lineTo(bocX + bocWidth / 2, size.height - bocHeight - 15)
      ..lineTo(bocX, size.height - bocHeight)
      ..lineTo(bocX, size.height)
      ..close();
    
    canvas.drawPath(bocPath, paint);
  }

  void _drawCentralBuildings(Canvas canvas, Size size, Paint paint) {
    paint.style = PaintingStyle.fill;
    
    // Array of building configurations
    final buildings = [
      {'x': 0.7, 'width': 0.08, 'height': 0.4},
      {'x': 0.8, 'width': 0.06, 'height': 0.35},
      {'x': 0.88, 'width': 0.05, 'height': 0.3},
      {'x': 0.05, 'width': 0.07, 'height': 0.25},
      {'x': 0.25, 'width': 0.05, 'height': 0.3},
    ];
    
    for (final building in buildings) {
      paint.color = themeColor.withValues(alpha: 0.08 + (building['height'] as double) * 0.1);
      
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * (building['x'] as double),
          size.height - size.height * (building['height'] as double),
          size.width * (building['width'] as double),
          size.height * (building['height'] as double),
        ),
        paint,
      );
    }
  }

  void _drawWindowLights(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    // Generate window lights across buildings
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = size.height * (0.3 + random.nextDouble() * 0.4);
      
      // Flickering effect based on animation
      final flicker = 0.7 + 0.3 * math.sin(animationValue * 2 * math.pi + i);
      
      lightPaint.color = themeColor.withValues(alpha: 0.4 * flicker);
      
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 2,
          height: 3,
        ),
        lightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CentralSkylinePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.themeColor != themeColor ||
           oldDelegate.isRaining != isRaining;
  }
}

class NeonGlowPainter extends CustomPainter {
  final double animationValue;
  final Color themeColor;

  NeonGlowPainter({
    required this.animationValue,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Pulsing neon signs on buildings
    final neonSigns = [
      {'x': 0.2, 'y': 0.4, 'color': StreetCredTheme.neonPink},
      {'x': 0.4, 'y': 0.5, 'color': StreetCredTheme.neonBlue},
      {'x': 0.6, 'y': 0.3, 'color': StreetCredTheme.neonGreen},
      {'x': 0.8, 'y': 0.45, 'color': StreetCredTheme.neonYellow},
    ];

    for (final sign in neonSigns) {
      final intensity = 0.3 + 0.7 * math.sin(animationValue * 2 * math.pi);
      
      glowPaint.color = (sign['color'] as Color).withValues(alpha: 0.6 * intensity);
      
      canvas.drawCircle(
        Offset(
          size.width * (sign['x'] as double),
          size.height * (sign['y'] as double),
        ),
        8 * intensity,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NeonGlowPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.themeColor != themeColor;
  }
}