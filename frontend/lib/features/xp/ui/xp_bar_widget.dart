import 'package:flutter/material.dart';

class XPBarWidget extends StatefulWidget {
  final int xp;
  final int maxXp;
  const XPBarWidget({super.key, required this.xp, this.maxXp = 100});

  @override
  State<XPBarWidget> createState() => _XPBarWidgetState();
}

class _XPBarWidgetState extends State<XPBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late int _oldXp;

  @override
  void initState() {
    super.initState();
    _oldXp = widget.xp;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.15,
    );
  }

  @override
  void didUpdateWidget(covariant XPBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.xp > _oldXp) {
      _pulseController.forward(from: 0);
      _oldXp = widget.xp;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.xp / widget.maxXp).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: percent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return ScaleTransition(
          scale: _pulseController.drive(Tween(begin: 1.0, end: 1.15)),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 200 * value,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.yellow, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${widget.xp} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
