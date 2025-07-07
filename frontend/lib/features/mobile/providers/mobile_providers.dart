import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mobile_models.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';
import '../services/shortcut_service.dart';
import '../../trade/state/trade_tracker_provider.dart';
import '../../clan/providers/clan_providers.dart';

// Service providers
final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final shortcutServiceProvider = Provider<ShortcutService>((ref) {
  return ShortcutService();
});

// Widget configuration provider
final widgetConfigurationProvider = StateNotifierProvider<WidgetConfigurationNotifier, AsyncValue<WidgetConfiguration>>((ref) {
  final widgetService = ref.read(widgetServiceProvider);
  return WidgetConfigurationNotifier(widgetService);
});

class WidgetConfigurationNotifier extends StateNotifier<AsyncValue<WidgetConfiguration>> {
  final WidgetService _widgetService;

  WidgetConfigurationNotifier(this._widgetService) : super(const AsyncValue.loading()) {
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await _widgetService.getWidgetConfiguration('current_user');
      state = AsyncValue.data(config);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateWidgetEnabled(String widgetId, bool enabled) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedEnabledWidgets = [...currentConfig.enabledWidgets];
    if (enabled && !updatedEnabledWidgets.contains(widgetId)) {
      updatedEnabledWidgets.add(widgetId);
    } else if (!enabled) {
      updatedEnabledWidgets.remove(widgetId);
    }

    final updatedConfig = currentConfig.copyWith(
      enabledWidgets: updatedEnabledWidgets,
      lastConfigured: DateTime.now(),
    );

    state = AsyncValue.data(updatedConfig);
    await _widgetService.saveWidgetConfiguration(updatedConfig);
  }

  Future<void> updateWidgetSettings(String widgetId, Map<String, dynamic> settings) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedWidgetSettings = Map<String, Map<String, dynamic>>.from(currentConfig.widgetSettings);
    updatedWidgetSettings[widgetId] = settings;

    final updatedConfig = currentConfig.copyWith(
      widgetSettings: updatedWidgetSettings,
      lastConfigured: DateTime.now(),
    );

    state = AsyncValue.data(updatedConfig);
    await _widgetService.saveWidgetConfiguration(updatedConfig);
  }

  Future<void> updateRefreshSettings(bool autoRefresh, Duration refreshInterval) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedConfig = currentConfig.copyWith(
      autoRefreshEnabled: autoRefresh,
      refreshInterval: refreshInterval,
      lastConfigured: DateTime.now(),
    );

    state = AsyncValue.data(updatedConfig);
    await _widgetService.saveWidgetConfiguration(updatedConfig);
  }
}

// Notification settings provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<NotificationSettings>>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<AsyncValue<NotificationSettings>> {
  NotificationSettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // In a real app, this would load from secure storage
      final settings = NotificationSettings(
        userId: 'current_user',
        typeSettings: {
          for (final type in NotificationType.values) type: true,
        },
        lastUpdated: DateTime.now(),
      );
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePushNotificationsEnabled(bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      pushNotificationsEnabled: enabled,
      lastUpdated: DateTime.now(),
    );

    state = AsyncValue.data(updatedSettings);
  }

  Future<void> updateNotificationType(NotificationType type, bool enabled) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final updatedTypeSettings = Map<NotificationType, bool>.from(currentSettings.typeSettings);
    updatedTypeSettings[type] = enabled;

    final updatedSettings = currentSettings.copyWith(
      typeSettings: updatedTypeSettings,
      lastUpdated: DateTime.now(),
    );

    state = AsyncValue.data(updatedSettings);
  }

  Future<void> updateQuietHours(bool enabled, int startHour, int endHour) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      quietHoursEnabled: enabled,
      quietHoursStart: startHour,
      quietHoursEnd: endHour,
      lastUpdated: DateTime.now(),
    );

    state = AsyncValue.data(updatedSettings);
  }

  Future<void> updateSoundSettings(bool vibrateEnabled, bool soundEnabled, String? customSoundPath) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    final updatedSettings = currentSettings.copyWith(
      vibrateEnabled: vibrateEnabled,
      soundEnabled: soundEnabled,
      customSoundPath: customSoundPath,
      lastUpdated: DateTime.now(),
    );

    state = AsyncValue.data(updatedSettings);
  }
}

// Shortcut configuration provider
final shortcutConfigurationProvider = StateNotifierProvider<ShortcutConfigurationNotifier, AsyncValue<ShortcutConfiguration>>((ref) {
  final shortcutService = ref.read(shortcutServiceProvider);
  return ShortcutConfigurationNotifier(shortcutService);
});

class ShortcutConfigurationNotifier extends StateNotifier<AsyncValue<ShortcutConfiguration>> {
  final ShortcutService _shortcutService;

  ShortcutConfigurationNotifier(this._shortcutService) : super(const AsyncValue.loading()) {
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final config = await _shortcutService.getShortcutConfiguration('current_user');
      state = AsyncValue.data(config);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateEnabledShortcuts(List<String> enabledShortcuts) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedConfig = currentConfig.copyWith(
      enabledShortcuts: enabledShortcuts,
      lastConfigured: DateTime.now(),
    );

    state = AsyncValue.data(updatedConfig);
    await _shortcutService.saveShortcutConfiguration(updatedConfig);
    await _shortcutService.updateShortcuts(updatedConfig);
  }

  Future<void> updateShortcutPriority(String shortcutId, int priority) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedPriorities = Map<String, int>.from(currentConfig.shortcutPriorities);
    updatedPriorities[shortcutId] = priority;

    final updatedConfig = currentConfig.copyWith(
      shortcutPriorities: updatedPriorities,
      lastConfigured: DateTime.now(),
    );

    state = AsyncValue.data(updatedConfig);
    await _shortcutService.saveShortcutConfiguration(updatedConfig);
    await _shortcutService.updateShortcuts(updatedConfig);
  }

  Future<void> updateMaxShortcuts(int maxShortcuts) async {
    final currentConfig = state.value;
    if (currentConfig == null) return;

    final updatedConfig = currentConfig.copyWith(
      maxShortcuts: maxShortcuts,
      lastConfigured: DateTime.now(),
    );

    state = AsyncValue.data(updatedConfig);
    await _shortcutService.saveShortcutConfiguration(updatedConfig);
    await _shortcutService.updateShortcuts(updatedConfig);
  }
}

// Widget data providers
final portfolioWidgetDataProvider = Provider<PortfolioWidgetData>((ref) {
  final positions = ref.watch(activePositionsProvider);
  
  return positions.when(
    data: (positionList) {
      final totalValue = positionList.fold<double>(0.0, (sum, pos) => sum + pos.currentValue);
      final dayChange = positionList.fold<double>(0.0, (sum, pos) => sum + pos.pnl);
      final dayChangePercent = totalValue > 0 ? (dayChange / totalValue) * 100 : 0.0;
      
      return PortfolioWidgetData(
        totalValue: totalValue,
        dayChange: dayChange,
        dayChangePercent: dayChangePercent,
        openPositions: positionList.length,
        topPosition: positionList.isNotEmpty ? positionList.first : null,
        lastUpdated: DateTime.now(),
      );
    },
    loading: () => PortfolioWidgetData(
      totalValue: 0.0,
      dayChange: 0.0,
      dayChangePercent: 0.0,
      openPositions: 0,
      lastUpdated: DateTime.now(),
    ),
    error: (_, __) => PortfolioWidgetData(
      totalValue: 0.0,
      dayChange: 0.0,
      dayChangePercent: 0.0,
      openPositions: 0,
      lastUpdated: DateTime.now(),
    ),
  );
});

final priceTickerWidgetDataProvider = Provider.family<PriceTickerWidgetData, String>((ref, symbol) {
  // This would watch real price data from a price provider
  // For now, return mock data
  return PriceTickerWidgetData(
    symbol: symbol,
    currentPrice: 45250.75,
    change24h: 1250.50,
    changePercent24h: 2.84,
    volume24h: 28500000000,
    sparklineData: [44000, 44500, 45000, 45250, 44800, 45100, 45250],
    lastUpdated: DateTime.now(),
  );
});

final clanWidgetDataProvider = Provider<ClanWidgetData?>((ref) {
  final userClan = ref.watch(userClanProvider);
  final activeChallenges = ref.watch(activeChallengesProvider);
  
  if (userClan == null) return null;
  
  final activeChallenge = activeChallenges.whenOrNull(
    data: (challenges) => challenges.where((c) => 
        c.challengingClan.id == userClan.id || 
        c.defendingClan?.id == userClan.id).firstOrNull,
  );
  
  return ClanWidgetData(
    clanName: userClan.name,
    memberCount: userClan.memberCount,
    ranking: userClan.stats.ranking,
    weeklyPoints: userClan.stats.weeklyPoints,
    hasActiveChallenge: activeChallenge != null,
    challengeName: activeChallenge?.name,
    challengeTimeRemaining: activeChallenge?.timeRemaining,
    lastUpdated: DateTime.now(),
  );
});

final territoryWidgetDataProvider = Provider<TerritoryWidgetData>((ref) {
  // This would watch territory data from a territory provider
  // For now, return mock data
  return TerritoryWidgetData(
    controlledTerritories: 3,
    primaryTerritory: 'Central District',
    defensePoints: 850,
    isUnderAttack: false,
    lastUpdated: DateTime.now(),
  );
});

final streakWidgetDataProvider = Provider<StreakWidgetData>((ref) {
  // This would watch streak data from a streak provider
  // For now, return mock data
  return StreakWidgetData(
    currentStreak: 7,
    bestStreak: 12,
    streakType: 0,
    isActive: true,
    multiplier: 1.7,
    lastUpdated: DateTime.now(),
  );
});

// Push notification queue provider
final pendingNotificationsProvider = StateNotifierProvider<PendingNotificationsNotifier, List<PushNotification>>((ref) {
  return PendingNotificationsNotifier();
});

class PendingNotificationsNotifier extends StateNotifier<List<PushNotification>> {
  PendingNotificationsNotifier() : super([]);

  void addNotification(PushNotification notification) {
    state = [...state, notification];
  }

  void removeNotification(String notificationId) {
    state = state.where((n) => n.id != notificationId).toList();
  }

  void markAsDelivered(String notificationId) {
    state = state.map((n) => 
        n.id == notificationId 
            ? n.copyWith(isDelivered: true, deliveredAt: DateTime.now())
            : n
    ).toList();
  }

  void markAsRead(String notificationId) {
    state = state.map((n) => 
        n.id == notificationId 
            ? n.copyWith(isRead: true)
            : n
    ).toList();
  }

  void clearAll() {
    state = [];
  }
}

// Mobile initialization provider
final mobileInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    final widgetService = ref.read(widgetServiceProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final shortcutService = ref.read(shortcutServiceProvider);

    // Initialize all mobile services
    await Future.wait([
      widgetService.initialize(),
      notificationService.initialize(),
      shortcutService.initialize(),
    ]);

    // Request permissions
    await notificationService.requestPermissions();

    // Setup background tasks
    await notificationService.setupBackgroundTasks();

    return true;
  } catch (e) {
    return false;
  }
});

// Auto-refresh provider for widgets
final widgetAutoRefreshProvider = StreamProvider<bool>((ref) {
  return Stream.periodic(const Duration(minutes: 5), (_) => true);
});

// Listen to auto-refresh and update widgets
final widgetRefreshListenerProvider = Provider<void>((ref) {
  ref.listen(widgetAutoRefreshProvider, (previous, next) {
    next.whenData((shouldRefresh) async {
      if (shouldRefresh) {
        final widgetService = ref.read(widgetServiceProvider);
        final config = ref.read(widgetConfigurationProvider).value;
        
        if (config != null && config.autoRefreshEnabled) {
          // Update portfolio widget
          final portfolioData = ref.read(portfolioWidgetDataProvider);
          await widgetService.updatePortfolioWidget(portfolioData);
          
          // Update price ticker widget
          final tickerData = ref.read(priceTickerWidgetDataProvider('BTC/USD'));
          await widgetService.updatePriceTickerWidget(tickerData);
          
          // Update clan widget if user is in a clan
          final clanData = ref.read(clanWidgetDataProvider);
          if (clanData != null) {
            await widgetService.updateClanWidget(clanData);
          }
          
          // Update territory widget
          final territoryData = ref.read(territoryWidgetDataProvider);
          await widgetService.updateTerritoryWidget(territoryData);
          
          // Update streak widget
          final streakData = ref.read(streakWidgetDataProvider);
          await widgetService.updateStreakWidget(streakData);
        }
      }
    });
  });
});