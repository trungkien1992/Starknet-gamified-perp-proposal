import 'package:flutter/material.dart';

class BadgeEarnedWidget extends StatefulWidget {
  final String badge;
  final int streak;
  final String? message;
  const BadgeEarnedWidget({
    super.key,
    required this.badge,
    required this.streak,
    this.message,
  });

  @override
  State<BadgeEarnedWidget> createState() => _BadgeEarnedWidgetState();
}

class _BadgeEarnedWidgetState extends State<BadgeEarnedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
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
      child: Center(
        child: Card(
          color: Colors.orange[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[800], size: 64),
                Text(
                  '${widget.streak}-Day Streak!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.badge} Badge',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.deepOrange,
                  ),
                ),
                if (widget.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.message!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
