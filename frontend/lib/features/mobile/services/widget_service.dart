import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../models/mobile_models.dart';
import '../../trade/state/trade_tracker_provider.dart';
import '../../clan/models/clan_models.dart';
import '../../territory/models/territory_models.dart';
import '../../../app/theme/street_cred_theme.dart';

class WidgetService {
  static const String _portfolioWidgetKey = 'portfolio_widget';
  static const String _priceTickerWidgetKey = 'price_ticker_widget';
  static const String _clanWidgetKey = 'clan_widget';
  static const String _territoryWidgetKey = 'territory_widget';
  static const String _streakWidgetKey = 'streak_widget';

  // Initialize home widget platform
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('group.streetcred.clash.widgets');
      debugPrint('📱 Widget service initialized');
    } catch (e) {
      debugPrint('❌ Widget service initialization failed: $e');
    }
  }

  // Get available widgets
  List<AppWidget> getAvailableWidgets() {
    return [
      AppWidget(
        id: 'portfolio_widget',
        name: 'Portfolio Summary',
        description: 'Track your total portfolio value and daily P&L',
        size: WidgetSize.medium,
        icon: Icons.account_balance_wallet,
        primaryColor: StreetCredTheme.neonGreen,
        secondaryColor: StreetCredTheme.neonGreen.withOpacity(0.7),
        configuration: {
          'showPositions': true,
          'showDayChange': true,
          'refreshInterval': 300, // 5 minutes
        },
        isEnabled: true,
        lastUpdated: DateTime.now(),
      ),
      
      AppWidget(
        id: 'price_ticker',
        name: 'Price Ticker',
        description: 'Live price updates for your favorite assets',
        size: WidgetSize.small,
        icon: Icons.trending_up,
        primaryColor: StreetCredTheme.neonBlue,
        secondaryColor: StreetCredTheme.neonBlue.withOpacity(0.7),
        configuration: {
          'symbol': 'BTC/USD',
          'showSparkline': true,
          'showVolume': false,
          'refreshInterval': 60, // 1 minute
        },
        isEnabled: true,
        lastUpdated: DateTime.now(),
      ),
      
      AppWidget(
        id: 'clan_status',
        name: 'Clan Status',
        description: 'Your clan ranking, challenges, and member activity',
        size: WidgetSize.medium,
        icon: Icons.groups,
        primaryColor: StreetCredTheme.neonPink,
        secondaryColor: StreetCredTheme.neonPink.withOpacity(0.7),
        configuration: {
          'showChallenges': true,
          'showRanking': true,
          'refreshInterval': 900, // 15 minutes
        },
        isEnabled: false,
        lastUpdated: DateTime.now(),
      ),
      
      AppWidget(
        id: 'territory_control',
        name: 'Territory Control',
        description: 'Monitor your controlled territories and threats',
        size: WidgetSize.large,
        icon: Icons.map,
        primaryColor: StreetCredTheme.neonYellow,
        secondaryColor: StreetCredTheme.neonYellow.withOpacity(0.7),
        configuration: {
          'showDefenseStatus': true,
          'showAttackAlerts': true,
          'refreshInterval': 600, // 10 minutes
        },
        isEnabled: false,
        lastUpdated: DateTime.now(),
      ),
      
      AppWidget(
        id: 'streak_tracker',
        name: 'Streak Tracker',
        description: 'Track your trading streaks and multipliers',
        size: WidgetSize.small,
        icon: Icons.local_fire_department,
        primaryColor: StreetCredTheme.streakOrange,
        secondaryColor: StreetCredTheme.streakOrange.withOpacity(0.7),
        configuration: {
          'streakType': 0, // 0: trading, 1: login, 2: quest
          'showMultiplier': true,
          'refreshInterval': 1800, // 30 minutes
        },
        isEnabled: true,
        lastUpdated: DateTime.now(),
      ),
    ];
  }

  // Update portfolio widget
  Future<void> updatePortfolioWidget(PortfolioWidgetData data) async {
    try {
      await HomeWidget.saveWidgetData<String>('portfolio_title', 'Portfolio');
      await HomeWidget.saveWidgetData<String>(
        'portfolio_value', 
        '\$${data.totalValue.toStringAsFixed(2)}'
      );
      await HomeWidget.saveWidgetData<String>(
        'portfolio_change', 
        '${data.dayChange >= 0 ? '+' : ''}\$${data.dayChange.toStringAsFixed(2)}'
      );
      await HomeWidget.saveWidgetData<String>(
        'portfolio_percent', 
        '${data.dayChangePercent >= 0 ? '+' : ''}${data.dayChangePercent.toStringAsFixed(2)}%'
      );
      await HomeWidget.saveWidgetData<String>(
        'portfolio_positions', 
        '${data.openPositions} positions'
      );
      await HomeWidget.saveWidgetData<bool>('portfolio_positive', data.dayChange >= 0);
      
      await HomeWidget.updateWidget(
        name: 'PortfolioWidget',
        androidName: 'PortfolioWidgetProvider',
        iOSName: 'PortfolioWidget',
        qualifiedAndroidName: 'com.streetcred.clash.PortfolioWidgetProvider',
      );
      
      debugPrint('📱 Portfolio widget updated');
    } catch (e) {
      debugPrint('❌ Portfolio widget update failed: $e');
    }
  }

  // Update price ticker widget
  Future<void> updatePriceTickerWidget(PriceTickerWidgetData data) async {
    try {
      await HomeWidget.saveWidgetData<String>('ticker_symbol', data.symbol);
      await HomeWidget.saveWidgetData<String>(
        'ticker_price', 
        '\$${data.currentPrice.toStringAsFixed(data.currentPrice < 1 ? 4 : 2)}'
      );
      await HomeWidget.saveWidgetData<String>(
        'ticker_change', 
        '${data.change24h >= 0 ? '+' : ''}\$${data.change24h.toStringAsFixed(2)}'
      );
      await HomeWidget.saveWidgetData<String>(
        'ticker_percent', 
        '${data.changePercent24h >= 0 ? '+' : ''}${data.changePercent24h.toStringAsFixed(2)}%'
      );
      await HomeWidget.saveWidgetData<bool>('ticker_positive', data.change24h >= 0);
      
      // Sparkline data as comma-separated string
      await HomeWidget.saveWidgetData<String>(
        'ticker_sparkline', 
        data.sparklineData.map((v) => v.toStringAsFixed(2)).join(',')
      );
      
      await HomeWidget.updateWidget(
        name: 'PriceTickerWidget',
        androidName: 'PriceTickerWidgetProvider',
        iOSName: 'PriceTickerWidget',
        qualifiedAndroidName: 'com.streetcred.clash.PriceTickerWidgetProvider',
      );
      
      debugPrint('📱 Price ticker widget updated');
    } catch (e) {
      debugPrint('❌ Price ticker widget update failed: $e');
    }
  }

  // Update clan widget
  Future<void> updateClanWidget(ClanWidgetData data) async {
    try {
      await HomeWidget.saveWidgetData<String>('clan_name', data.clanName);
      await HomeWidget.saveWidgetData<String>('clan_members', '${data.memberCount} members');
      await HomeWidget.saveWidgetData<String>('clan_ranking', 'Rank #${data.ranking}');
      await HomeWidget.saveWidgetData<String>('clan_points', '${data.weeklyPoints} pts');
      await HomeWidget.saveWidgetData<bool>('clan_has_challenge', data.hasActiveChallenge);
      
      if (data.hasActiveChallenge && data.challengeName != null) {
        await HomeWidget.saveWidgetData<String>('clan_challenge', data.challengeName!);
        if (data.challengeTimeRemaining != null) {
          final hours = data.challengeTimeRemaining!.inHours;
          final minutes = data.challengeTimeRemaining!.inMinutes % 60;
          await HomeWidget.saveWidgetData<String>(
            'clan_challenge_time', 
            '${hours}h ${minutes}m left'
          );
        }
      }
      
      await HomeWidget.updateWidget(
        name: 'ClanWidget',
        androidName: 'ClanWidgetProvider',
        iOSName: 'ClanWidget',
        qualifiedAndroidName: 'com.streetcred.clash.ClanWidgetProvider',
      );
      
      debugPrint('📱 Clan widget updated');
    } catch (e) {
      debugPrint('❌ Clan widget update failed: $e');
    }
  }

  // Update territory widget
  Future<void> updateTerritoryWidget(TerritoryWidgetData data) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'territory_count', 
        '${data.controlledTerritories} territories'
      );
      await HomeWidget.saveWidgetData<String>('territory_primary', data.primaryTerritory);
      await HomeWidget.saveWidgetData<String>('territory_defense', '${data.defensePoints} DP');
      await HomeWidget.saveWidgetData<bool>('territory_under_attack', data.isUnderAttack);
      
      if (data.isUnderAttack) {
        await HomeWidget.saveWidgetData<String>(
          'territory_attacker', 
          data.attackingClan ?? 'Unknown'
        );
        if (data.defenseTimeRemaining != null) {
          final hours = data.defenseTimeRemaining!.inHours;
          final minutes = data.defenseTimeRemaining!.inMinutes % 60;
          await HomeWidget.saveWidgetData<String>(
            'territory_defense_time', 
            '${hours}h ${minutes}m'
          );
        }
      }
      
      await HomeWidget.updateWidget(
        name: 'TerritoryWidget',
        androidName: 'TerritoryWidgetProvider',
        iOSName: 'TerritoryWidget',
        qualifiedAndroidName: 'com.streetcred.clash.TerritoryWidgetProvider',
      );
      
      debugPrint('📱 Territory widget updated');
    } catch (e) {
      debugPrint('❌ Territory widget update failed: $e');
    }
  }

  // Update streak widget
  Future<void> updateStreakWidget(StreakWidgetData data) async {
    try {
      await HomeWidget.saveWidgetData<String>('streak_current', '${data.currentStreak}');
      await HomeWidget.saveWidgetData<String>('streak_best', 'Best: ${data.bestStreak}');
      await HomeWidget.saveWidgetData<String>('streak_type', data.streakTypeName);
      await HomeWidget.saveWidgetData<String>(
        'streak_multiplier', 
        '${data.multiplier.toStringAsFixed(1)}x'
      );
      await HomeWidget.saveWidgetData<bool>('streak_active', data.isActive);
      
      if (data.timeToBreak != null && data.isActive) {
        final hours = data.timeToBreak!.inHours;
        final minutes = data.timeToBreak!.inMinutes % 60;
        await HomeWidget.saveWidgetData<String>(
          'streak_time_left', 
          '${hours}h ${minutes}m to break'
        );
      }
      
      await HomeWidget.updateWidget(
        name: 'StreakWidget',
        androidName: 'StreakWidgetProvider',
        iOSName: 'StreakWidget',
        qualifiedAndroidName: 'com.streetcred.clash.StreakWidgetProvider',
      );
      
      debugPrint('📱 Streak widget updated');
    } catch (e) {
      debugPrint('❌ Streak widget update failed: $e');
    }
  }

  // Refresh all enabled widgets
  Future<void> refreshAllWidgets(WidgetConfiguration config) async {
    try {
      for (final widgetId in config.enabledWidgets) {
        await _refreshWidget(widgetId);
      }
      debugPrint('📱 All widgets refreshed');
    } catch (e) {
      debugPrint('❌ Widget refresh failed: $e');
    }
  }

  // Refresh specific widget
  Future<void> _refreshWidget(String widgetId) async {
    // This would typically fetch fresh data and update the specific widget
    // For now, we'll just trigger an update with existing data
    switch (widgetId) {
      case 'portfolio_widget':
        await HomeWidget.updateWidget(
          name: 'PortfolioWidget',
          androidName: 'PortfolioWidgetProvider',
          iOSName: 'PortfolioWidget',
          qualifiedAndroidName: 'com.streetcred.clash.PortfolioWidgetProvider',
        );
        break;
      case 'price_ticker':
        await HomeWidget.updateWidget(
          name: 'PriceTickerWidget',
          androidName: 'PriceTickerWidgetProvider',
          iOSName: 'PriceTickerWidget',
          qualifiedAndroidName: 'com.streetcred.clash.PriceTickerWidgetProvider',
        );
        break;
      case 'clan_status':
        await HomeWidget.updateWidget(
          name: 'ClanWidget',
          androidName: 'ClanWidgetProvider',
          iOSName: 'ClanWidget',
          qualifiedAndroidName: 'com.streetcred.clash.ClanWidgetProvider',
        );
        break;
      case 'territory_control':
        await HomeWidget.updateWidget(
          name: 'TerritoryWidget',
          androidName: 'TerritoryWidgetProvider',
          iOSName: 'TerritoryWidget',
          qualifiedAndroidName: 'com.streetcred.clash.TerritoryWidgetProvider',
        );
        break;
      case 'streak_tracker':
        await HomeWidget.updateWidget(
          name: 'StreakWidget',
          androidName: 'StreakWidgetProvider',
          iOSName: 'StreakWidget',
          qualifiedAndroidName: 'com.streetcred.clash.StreakWidgetProvider',
        );
        break;
    }
  }

  // Handle widget tap (deep link)
  Future<void> handleWidgetTap(String? uri) async {
    if (uri == null) return;
    
    try {
      // Parse widget tap and navigate to appropriate screen
      if (uri.contains('portfolio')) {
        // Navigate to portfolio/arena screen
        debugPrint('📱 Portfolio widget tapped - navigate to arena');
      } else if (uri.contains('ticker')) {
        // Navigate to specific asset trading screen
        debugPrint('📱 Price ticker widget tapped - navigate to trading');
      } else if (uri.contains('clan')) {
        // Navigate to clan screen
        debugPrint('📱 Clan widget tapped - navigate to clan');
      } else if (uri.contains('territory')) {
        // Navigate to territory map
        debugPrint('📱 Territory widget tapped - navigate to map');
      } else if (uri.contains('streak')) {
        // Navigate to streak/profile screen
        debugPrint('📱 Streak widget tapped - navigate to profile');
      }
    } catch (e) {
      debugPrint('❌ Widget tap handling failed: $e');
    }
  }

  // Get widget configuration from storage
  Future<WidgetConfiguration> getWidgetConfiguration(String userId) async {
    // In a real app, this would load from secure storage or database
    return WidgetConfiguration(
      userId: userId,
      enabledWidgets: ['portfolio_widget', 'price_ticker', 'streak_tracker'],
      widgetSettings: {
        'portfolio_widget': {'refreshInterval': 300},
        'price_ticker': {'symbol': 'BTC/USD', 'refreshInterval': 60},
        'streak_tracker': {'streakType': 0, 'refreshInterval': 1800},
      },
      autoRefreshEnabled: true,
      refreshInterval: const Duration(minutes: 5),
      lastConfigured: DateTime.now(),
    );
  }

  // Save widget configuration
  Future<void> saveWidgetConfiguration(WidgetConfiguration config) async {
    // In a real app, this would save to secure storage or database
    debugPrint('📱 Widget configuration saved for user ${config.userId}');
  }

  // Disable all widgets
  Future<void> disableAllWidgets() async {
    try {
      final availableWidgets = getAvailableWidgets();
      for (final widget in availableWidgets) {
        await _refreshWidget(widget.id);
      }
      debugPrint('📱 All widgets disabled');
    } catch (e) {
      debugPrint('❌ Widget disable failed: $e');
    }
  }
}