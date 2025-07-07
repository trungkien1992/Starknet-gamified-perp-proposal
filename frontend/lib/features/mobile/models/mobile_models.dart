import 'package:flutter/material.dart';
import '../../trade/state/trade_tracker_provider.dart';

enum WidgetSize {
  small,
  medium,
  large,
}

enum NotificationType {
  tradeAlert,
  priceAlert,
  clanInvite,
  questComplete,
  territoryAttack,
  leaderboardUpdate,
  streakBonus,
  eventStart,
}

class AppWidget {
  final String id;
  final String name;
  final String description;
  final WidgetSize size;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Map<String, dynamic> configuration;
  final bool isEnabled;
  final DateTime lastUpdated;

  const AppWidget({
    required this.id,
    required this.name,
    required this.description,
    required this.size,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.configuration,
    required this.isEnabled,
    required this.lastUpdated,
  });

  String get sizeDisplayName {
    switch (size) {
      case WidgetSize.small:
        return 'Small (2x1)';
      case WidgetSize.medium:
        return 'Medium (2x2)';
      case WidgetSize.large:
        return 'Large (4x2)';
    }
  }

  Map<String, int> get gridDimensions {
    switch (size) {
      case WidgetSize.small:
        return {'width': 2, 'height': 1};
      case WidgetSize.medium:
        return {'width': 2, 'height': 2};
      case WidgetSize.large:
        return {'width': 4, 'height': 2};
    }
  }

  AppWidget copyWith({
    bool? isEnabled,
    Map<String, dynamic>? configuration,
    DateTime? lastUpdated,
  }) {
    return AppWidget(
      id: id,
      name: name,
      description: description,
      size: size,
      icon: icon,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      configuration: configuration ?? this.configuration,
      isEnabled: isEnabled ?? this.isEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime scheduledTime;
  final bool isRecurring;
  final Duration? recurringInterval;
  final bool isDelivered;
  final bool isRead;
  final DateTime? deliveredAt;
  final String? imageUrl;
  final List<NotificationAction> actions;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.scheduledTime,
    this.isRecurring = false,
    this.recurringInterval,
    this.isDelivered = false,
    this.isRead = false,
    this.deliveredAt,
    this.imageUrl,
    this.actions = const [],
  });

  String get typeDisplayName {
    switch (type) {
      case NotificationType.tradeAlert:
        return 'Trade Alert';
      case NotificationType.priceAlert:
        return 'Price Alert';
      case NotificationType.clanInvite:
        return 'Clan Invitation';
      case NotificationType.questComplete:
        return 'Quest Complete';
      case NotificationType.territoryAttack:
        return 'Territory Attack';
      case NotificationType.leaderboardUpdate:
        return 'Leaderboard Update';
      case NotificationType.streakBonus:
        return 'Streak Bonus';
      case NotificationType.eventStart:
        return 'Event Started';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.tradeAlert:
        return Icons.trending_up;
      case NotificationType.priceAlert:
        return Icons.monetization_on;
      case NotificationType.clanInvite:
        return Icons.group_add;
      case NotificationType.questComplete:
        return Icons.task_alt;
      case NotificationType.territoryAttack:
        return Icons.security;
      case NotificationType.leaderboardUpdate:
        return Icons.leaderboard;
      case NotificationType.streakBonus:
        return Icons.local_fire_department;
      case NotificationType.eventStart:
        return Icons.celebration;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.tradeAlert:
        return const Color(0xFF00FF41);
      case NotificationType.priceAlert:
        return const Color(0xFFFFD700);
      case NotificationType.clanInvite:
        return const Color(0xFF00FFFF);
      case NotificationType.questComplete:
        return const Color(0xFF9D4EDD);
      case NotificationType.territoryAttack:
        return const Color(0xFFFF0080);
      case NotificationType.leaderboardUpdate:
        return const Color(0xFF06FFA5);
      case NotificationType.streakBonus:
        return const Color(0xFFFF6B35);
      case NotificationType.eventStart:
        return const Color(0xFFFEE75C);
    }
  }

  PushNotification copyWith({
    bool? isDelivered,
    bool? isRead,
    DateTime? deliveredAt,
  }) {
    return PushNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      data: data,
      scheduledTime: scheduledTime,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      isDelivered: isDelivered ?? this.isDelivered,
      isRead: isRead ?? this.isRead,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      imageUrl: imageUrl,
      actions: actions,
    );
  }
}

class NotificationAction {
  final String id;
  final String title;
  final String actionType;
  final Map<String, dynamic> payload;
  final bool destructive;

  const NotificationAction({
    required this.id,
    required this.title,
    required this.actionType,
    required this.payload,
    this.destructive = false,
  });
}

class AppShortcut {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Map<String, dynamic> parameters;
  final Color iconColor;
  final bool isEnabled;
  final int priority;

  const AppShortcut({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.parameters,
    required this.iconColor,
    this.isEnabled = true,
    this.priority = 0,
  });

  AppShortcut copyWith({
    bool? isEnabled,
    int? priority,
  }) {
    return AppShortcut(
      id: id,
      title: title,
      subtitle: subtitle,
      icon: icon,
      route: route,
      parameters: parameters,
      iconColor: iconColor,
      isEnabled: isEnabled ?? this.isEnabled,
      priority: priority ?? this.priority,
    );
  }
}

// Widget data structures
class PortfolioWidgetData {
  final double totalValue;
  final double dayChange;
  final double dayChangePercent;
  final int openPositions;
  final TradePosition? topPosition;
  final DateTime lastUpdated;

  const PortfolioWidgetData({
    required this.totalValue,
    required this.dayChange,
    required this.dayChangePercent,
    required this.openPositions,
    this.topPosition,
    required this.lastUpdated,
  });
}

class PriceTickerWidgetData {
  final String symbol;
  final double currentPrice;
  final double change24h;
  final double changePercent24h;
  final double volume24h;
  final List<double> sparklineData;
  final DateTime lastUpdated;

  const PriceTickerWidgetData({
    required this.symbol,
    required this.currentPrice,
    required this.change24h,
    required this.changePercent24h,
    required this.volume24h,
    required this.sparklineData,
    required this.lastUpdated,
  });
}

class ClanWidgetData {
  final String clanName;
  final int memberCount;
  final int ranking;
  final int weeklyPoints;
  final bool hasActiveChallenge;
  final String? challengeName;
  final Duration? challengeTimeRemaining;
  final DateTime lastUpdated;

  const ClanWidgetData({
    required this.clanName,
    required this.memberCount,
    required this.ranking,
    required this.weeklyPoints,
    required this.hasActiveChallenge,
    this.challengeName,
    this.challengeTimeRemaining,
    required this.lastUpdated,
  });
}

class TerritoryWidgetData {
  final int controlledTerritories;
  final String primaryTerritory;
  final int defensePoints;
  final bool isUnderAttack;
  final String? attackingClan;
  final Duration? defenseTimeRemaining;
  final DateTime lastUpdated;

  const TerritoryWidgetData({
    required this.controlledTerritories,
    required this.primaryTerritory,
    required this.defensePoints,
    required this.isUnderAttack,
    this.attackingClan,
    this.defenseTimeRemaining,
    required this.lastUpdated,
  });
}

class StreakWidgetData {
  final int currentStreak;
  final int bestStreak;
  final int streakType; // 0: trading wins, 1: daily login, 2: quest completion
  final bool isActive;
  final Duration? timeToBreak;
  final double multiplier;
  final DateTime lastUpdated;

  const StreakWidgetData({
    required this.currentStreak,
    required this.bestStreak,
    required this.streakType,
    required this.isActive,
    this.timeToBreak,
    required this.multiplier,
    required this.lastUpdated,
  });

  String get streakTypeName {
    switch (streakType) {
      case 0:
        return 'Trading Wins';
      case 1:
        return 'Daily Login';
      case 2:
        return 'Quest Complete';
      default:
        return 'Unknown';
    }
  }
}

// Mobile feature configurations
class WidgetConfiguration {
  final String userId;
  final List<String> enabledWidgets;
  final Map<String, Map<String, dynamic>> widgetSettings;
  final bool autoRefreshEnabled;
  final Duration refreshInterval;
  final DateTime lastConfigured;

  const WidgetConfiguration({
    required this.userId,
    required this.enabledWidgets,
    required this.widgetSettings,
    this.autoRefreshEnabled = true,
    this.refreshInterval = const Duration(minutes: 5),
    required this.lastConfigured,
  });

  WidgetConfiguration copyWith({
    List<String>? enabledWidgets,
    Map<String, Map<String, dynamic>>? widgetSettings,
    bool? autoRefreshEnabled,
    Duration? refreshInterval,
    DateTime? lastConfigured,
  }) {
    return WidgetConfiguration(
      userId: userId,
      enabledWidgets: enabledWidgets ?? this.enabledWidgets,
      widgetSettings: widgetSettings ?? this.widgetSettings,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      lastConfigured: lastConfigured ?? this.lastConfigured,
    );
  }
}

class NotificationSettings {
  final String userId;
  final bool pushNotificationsEnabled;
  final Map<NotificationType, bool> typeSettings;
  final bool quietHoursEnabled;
  final int quietHoursStart; // Hour (0-23)
  final int quietHoursEnd; // Hour (0-23)
  final bool vibrateEnabled;
  final bool soundEnabled;
  final String? customSoundPath;
  final DateTime lastUpdated;

  const NotificationSettings({
    required this.userId,
    this.pushNotificationsEnabled = true,
    required this.typeSettings,
    this.quietHoursEnabled = false,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 8,
    this.vibrateEnabled = true,
    this.soundEnabled = true,
    this.customSoundPath,
    required this.lastUpdated,
  });

  bool isQuietTime() {
    if (!quietHoursEnabled) return false;
    
    final now = DateTime.now();
    final currentHour = now.hour;
    
    if (quietHoursStart < quietHoursEnd) {
      return currentHour >= quietHoursStart && currentHour < quietHoursEnd;
    } else {
      return currentHour >= quietHoursStart || currentHour < quietHoursEnd;
    }
  }

  NotificationSettings copyWith({
    bool? pushNotificationsEnabled,
    Map<NotificationType, bool>? typeSettings,
    bool? quietHoursEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool? vibrateEnabled,
    bool? soundEnabled,
    String? customSoundPath,
    DateTime? lastUpdated,
  }) {
    return NotificationSettings(
      userId: userId,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      typeSettings: typeSettings ?? this.typeSettings,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ShortcutConfiguration {
  final String userId;
  final List<String> enabledShortcuts;
  final Map<String, int> shortcutPriorities;
  final int maxShortcuts;
  final DateTime lastConfigured;

  const ShortcutConfiguration({
    required this.userId,
    required this.enabledShortcuts,
    required this.shortcutPriorities,
    this.maxShortcuts = 4,
    required this.lastConfigured,
  });

  ShortcutConfiguration copyWith({
    List<String>? enabledShortcuts,
    Map<String, int>? shortcutPriorities,
    int? maxShortcuts,
    DateTime? lastConfigured,
  }) {
    return ShortcutConfiguration(
      userId: userId,
      enabledShortcuts: enabledShortcuts ?? this.enabledShortcuts,
      shortcutPriorities: shortcutPriorities ?? this.shortcutPriorities,
      maxShortcuts: maxShortcuts ?? this.maxShortcuts,
      lastConfigured: lastConfigured ?? this.lastConfigured,
    );
  }
}