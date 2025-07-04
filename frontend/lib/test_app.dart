import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core providers
import 'state/xp_provider.dart';
import 'features/trade/state/ink_providers.dart';
import 'features/drip/state/drip_provider.dart';
import 'features/reward/state/reward_state.dart';

// UI Screens
import 'features/trade/ui/trade_arena_screen.dart';
import 'features/profile/ui/profile_screen.dart';

// Widgets
import 'features/reward/ui/game_event_listener.dart';

class StreetCredTestApp extends ConsumerWidget {
  const StreetCredTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'StreetCred Clash - Test',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/trade',
  routes: [
    GoRoute(
      path: '/trade',
      name: 'trade',
      builder: (context, state) => const TradeArenaScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

void main() {
  runApp(ProviderScope(child: const StreetCredTestApp()));
}
