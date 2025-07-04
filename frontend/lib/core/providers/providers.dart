/// Central provider exports for better import management
/// This file provides a single entry point for all providers

// Core providers
export '../state/game_events_state.dart';
export 'starknet_providers.dart';

// Global state providers
export '../../state/xp_provider.dart';

// Feature providers
export '../../features/trade/state/ink_providers.dart';
export '../../features/trade/providers/wallet_provider.dart';
export '../../features/trade/state/trade_tracker_provider.dart';
export '../../features/drip/state/drip_provider.dart';
export '../../features/streak/state/streak_provider.dart';
export '../../features/reward/state/reward_state.dart';

// App providers
export '../../app/di.dart';

/// Provider organization guidelines:
///
/// 1. Core providers: Infrastructure-level providers (API, storage, etc.)
/// 2. Global state: App-wide state that multiple features need
/// 3. Feature providers: Domain-specific state for individual features
/// 4. App providers: Application configuration and dependency injection
///
/// Usage:
/// ```dart
/// import 'package:frontend/core/providers/providers.dart';
///
/// // All providers are now available
/// ref.watch(xpProvider);
/// ref.watch(dripProvider);
/// ```
