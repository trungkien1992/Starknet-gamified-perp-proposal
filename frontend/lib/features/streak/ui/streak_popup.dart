import 'package:flutter/material.dart';

class StreakPopup {
  static void show(BuildContext context, String streakInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Streak Updated!'),
        content: Text(streakInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
