import 'package:flutter/material.dart';

class XPBurstAnimation extends StatefulWidget {
  final int xp;
  final VoidCallback? onComplete;
  const XPBurstAnimation({super.key, required this.xp, this.onComplete});

  @override
  State<XPBurstAnimation> createState() => _XPBurstAnimationState();
}

class _XPBurstAnimationState extends State<XPBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnim,
      child: AnimatedBuilder(
        animation: _opacityAnim,
        builder: (context, child) =>
            Opacity(opacity: _opacityAnim.value, child: child),
        child: Text(
          '+${widget.xp} XP',
          style: const TextStyle(
            fontSize: 32,
            color: Colors.yellow,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 8, color: Colors.orange)],
          ),
        ),
      ),
    );
  }
}
