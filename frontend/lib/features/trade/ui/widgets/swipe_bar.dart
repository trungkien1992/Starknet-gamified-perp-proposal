// File: frontend/lib/features/trade/ui/widgets/swipe_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/di.dart'; // Imports our dependency injection providers
import 'dart:ui' as ui;
import 'package:frontend/state/xp_provider.dart';

// The SwipeBar is now a ConsumerStatefulWidget to access Riverpod providers.
class SwipeBar extends ConsumerStatefulWidget {
  const SwipeBar({super.key});

  @override
  ConsumerState<SwipeBar> createState() => _SwipeBarState();
}

class _SwipeBarState extends ConsumerState<SwipeBar> {
  double _position = 0;
  double _dragTotal = 0;
  int leverage = 1;

  // This is the new, clean way to trigger our action.
  Future<void> _handleMovePlayer(int x, int y) async {
    try {
      // We access the use case provider from Riverpod's `ref`.
      final movePlayerUseCase = ref.read(movePlayerUseCaseProvider);
      await movePlayerUseCase.call(x: x, y: y);

      // Increment XP when a move is made
      ref.read(xpProvider.notifier).addXP(10); // Award 10 XP per move

      // Show a success message to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Move successful! +10 XP'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show an error message if the use case throws an exception.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _position -= details.delta.dy;
          _position = _position.clamp(0, height - 50);
          _dragTotal -= details.delta.dy;
          _dragTotal = _dragTotal.clamp(0, height - 50);
          final t = (_dragTotal / (height - 50)).clamp(0.0, 1.0);

          // This is the updated, platform-agnostic code.
          // It no longer contains the kIsWeb check.
          final mapped = ui.lerpDouble(1, 10, t)!;
          leverage = mapped.round();
        });
      },
      onVerticalDragEnd: (details) {
        // We now call our new handler method with dummy coordinates.
        if (details.velocity.pixelsPerSecond.dy < -100) {
          _handleMovePlayer(10, 20);
        } else if (details.velocity.pixelsPerSecond.dy > 100) {
          _handleMovePlayer(30, 40);
        }
        setState(() {
          _dragTotal = 0;
        });
      },
      child: Container(
        width: 50,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: _position),
          width: 50,
          height: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}
