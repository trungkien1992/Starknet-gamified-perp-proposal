import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/street_cred_theme.dart';
import 'routing/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/trade/providers/wallet_provider.dart' as legacy;
import 'package:frontend/features/wallet/providers/wallet_providers.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [_WalletRefreshObserver()],
      child: const StreetCredApp(),
    ),
  );
}

class _WalletRefreshObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Refresh router when wallet state changes
    if (provider == legacy.walletProvider || provider == walletAuthProvider) {
      routerRefreshNotifier.value++;
    }
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }
}

class StreetCredApp extends ConsumerWidget {
  const StreetCredApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'StreetCred Clash',
      theme: StreetCredTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
