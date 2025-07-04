import 'package:flutter/material.dart';
import '../../../app/theme/street_cred_theme.dart';

class HandDemoAnimation extends StatefulWidget {
  final VoidCallback? onDemoComplete;
  const HandDemoAnimation({Key? key, this.onDemoComplete}) : super(key: key);

  @override
  State<HandDemoAnimation> createState() => _HandDemoAnimationState();
}

class _HandDemoAnimationState extends State<HandDemoAnimation>
    with TickerProviderStateMixin {
  late AnimationController _gestureController;
  late AnimationController _leverageController;
  late Animation<double> _fingerPosition;
  late Animation<double> _leverageRadius;

  int _currentGesture = 0; // 0: up (LONG), 1: down (SHORT), 2: hold (leverage)

  @override
  void initState() {
    super.initState();

    _gestureController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _leverageController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fingerPosition = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_gestureController);

    _leverageRadius = Tween<double>(begin: 40.0, end: 80.0).animate(
      CurvedAnimation(parent: _leverageController, curve: Curves.easeInOut),
    );

    _gestureController.addListener(() {
      final progress = _gestureController.value;
      if (progress < 0.25) {
        setState(() => _currentGesture = 0); // Swipe up for LONG
      } else if (progress < 0.5) {
        setState(() => _currentGesture = 1); // Swipe down for SHORT
      } else {
        setState(() => _currentGesture = 2); // Hold for leverage
        if (progress > 0.5 && progress < 0.75) {
          _leverageController.forward();
        } else {
          _leverageController.reverse();
        }
      }
    });

    _gestureController.repeat();
  }

  @override
  void dispose() {
    _gestureController.dispose();
    _leverageController.dispose();
    super.dispose();
  }

  Offset _getFingerPosition() {
    final progress = _fingerPosition.value;
    final centerX = 0.0;
    final centerY = 0.0;

    if (_currentGesture == 0) {
      // Swipe up for LONG
      return Offset(centerX, centerY + (0.3 - progress * 0.6));
    } else if (_currentGesture == 1) {
      // Swipe down for SHORT
      return Offset(centerX, centerY - (0.3 - progress * 0.6));
    } else {
      // Hold for leverage
      return Offset(centerX, centerY);
    }
  }

  String _getInstructionText() {
    switch (_currentGesture) {
      case 0:
        return 'Swipe UP to go LONG';
      case 1:
        return 'Swipe DOWN to go SHORT';
      case 2:
        return 'Hold to increase leverage';
      default:
        return '';
    }
  }

  Color _getInstructionColor() {
    switch (_currentGesture) {
      case 0:
        return StreetCredTheme.longColor;
      case 1:
        return StreetCredTheme.shortColor;
      case 2:
        return StreetCredTheme.neonBlue;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_fingerPosition, _leverageRadius]),
        builder: (context, child) {
          final fingerPos = _getFingerPosition();

          return Stack(
            children: [
              // Leverage expanding circle
              if (_currentGesture == 2)
                Center(
                  child: Container(
                    width: _leverageRadius.value * 2,
                    height: _leverageRadius.value * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: StreetCredTheme.neonBlue.withValues(alpha: 0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: StreetCredTheme.neonBlue.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),

              // Finger icon
              Transform.translate(
                offset: Offset(fingerPos.dx * 50, fingerPos.dy * 100),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getInstructionColor().withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.touch_app,
                      size: 30,
                      color: _getInstructionColor(),
                    ),
                  ),
                ),
              ),

              // Instruction text
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getInstructionColor(),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getInstructionText(),
                      style: StreetCredTheme.graffitiBody.copyWith(
                        color: _getInstructionColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
