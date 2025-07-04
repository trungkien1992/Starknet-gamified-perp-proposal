import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/di.dart';
import 'app/app_mode.dart';
import 'features/drip/state/drip_provider.dart';
import 'data/datasources/mock_starknet_client.dart';
import 'app/main.dart'; // Import the real app entry point

void main() {
  runApp(
    ProviderScope(
      overrides: [
        if (getAppMode() == AppMode.mock)
          dripProvider.overrideWith((ref) => DripNotifier(ref)),
        // Add other overrides as needed
      ],
      child: const StreetCredApp(), // Launch the real app
    ),
  );
}

// Define a minimal MyApp widget if not already defined
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Hello, Starknet Gamified Perp!')),
      ),
    );
  }
}
