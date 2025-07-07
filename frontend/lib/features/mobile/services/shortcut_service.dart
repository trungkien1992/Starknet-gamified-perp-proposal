import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import '../models/mobile_models.dart';
import '../../../app/theme/street_cred_theme.dart';

class ShortcutService {
  static const QuickActions _quickActions = QuickActions();
  static const String _shortcutChannel = 'com.streetcred.clash/shortcuts';
  static const MethodChannel _platform = MethodChannel(_shortcutChannel);

  // Initialize shortcut service
  Future<void> initialize() async {
    try {
      _quickActions.initialize((shortcutType) {
        _handleShortcutTap(shortcutType);
      });
      
      debugPrint('📱 Shortcut service initialized');
    } catch (e) {
      debugPrint('❌ Shortcut service initialization failed: $e');
    }
  }

  // Get available shortcuts
  List<AppShortcut> getAvailableShortcuts() {
    return [
      AppShortcut(
        id: 'quick_trade',
        title: 'Quick Trade',
        subtitle: 'Jump into trading arena',
        icon: Icons.trending_up,
        route: '/arena',
        parameters: {'quickEntry': true},
        iconColor: StreetCredTheme.neonGreen,
        priority: 1,
      ),
      
      AppShortcut(
        id: 'portfolio_view',
        title: 'Portfolio',
        subtitle: 'View your positions',
        icon: Icons.account_balance_wallet,
        route: '/arena',
        parameters: {'tab': 'portfolio'},
        iconColor: StreetCredTheme.neonBlue,
        priority: 2,
      ),
      
      AppShortcut(
        id: 'clan_hub',
        title: 'Clan Hub',
        subtitle: 'Check clan status',
        icon: Icons.groups,
        route: '/clan',
        parameters: {},
        iconColor: StreetCredTheme.neonPink,
        priority: 3,
      ),
      
      AppShortcut(
        id: 'territory_map',
        title: 'Territory Map',
        subtitle: 'View controlled areas',
        icon: Icons.map,
        route: '/territory',
        parameters: {},
        iconColor: StreetCredTheme.neonYellow,
        priority: 4,
      ),
      
      AppShortcut(
        id: 'price_alerts',
        title: 'Price Alerts',
        subtitle: 'Manage your alerts',
        icon: Icons.notifications_active,
        route: '/settings',
        parameters: {'section': 'alerts'},
        iconColor: StreetCredTheme.streakOrange,
        priority: 5,
      ),
      
      AppShortcut(
        id: 'leaderboard',
        title: 'Leaderboard',
        subtitle: 'See top traders',
        icon: Icons.leaderboard,
        route: '/leaderboard',
        parameters: {},
        iconColor: StreetCredTheme.longColor,
        priority: 6,
      ),
      
      AppShortcut(
        id: 'street_art',
        title: 'Street Art',
        subtitle: 'Create and browse art',
        icon: Icons.palette,
        route: '/street-art',
        parameters: {},
        iconColor: StreetCredTheme.neonCyan,
        priority: 7,
      ),
      
      AppShortcut(
        id: 'tutorial',
        title: 'Tutorial',
        subtitle: 'Learn the ropes',
        icon: Icons.school,
        route: '/tutorial',
        parameters: {'restart': true},
        iconColor: StreetCredTheme.neonPurple,
        priority: 8,
        isEnabled: false, // Disabled by default for experienced users
      ),
    ];
  }

  // Update app shortcuts based on configuration
  Future<void> updateShortcuts(ShortcutConfiguration config) async {
    try {
      final availableShortcuts = getAvailableShortcuts();
      final enabledShortcuts = availableShortcuts
          .where((shortcut) => 
              config.enabledShortcuts.contains(shortcut.id) && 
              shortcut.isEnabled)
          .toList();

      // Sort by priority
      enabledShortcuts.sort((a, b) {
        final priorityA = config.shortcutPriorities[a.id] ?? a.priority;
        final priorityB = config.shortcutPriorities[b.id] ?? b.priority;
        return priorityA.compareTo(priorityB);
      });

      // Take only the configured maximum
      final finalShortcuts = enabledShortcuts.take(config.maxShortcuts).toList();

      // Convert to QuickAction items
      final quickActions = finalShortcuts.map((shortcut) => ShortcutItem(
        type: shortcut.id,
        localizedTitle: shortcut.title,
        icon: _getIconName(shortcut.icon),
      )).toList();

      await _quickActions.setShortcutItems(quickActions);
      
      debugPrint('📱 App shortcuts updated: ${finalShortcuts.map((s) => s.title).join(', ')}');
    } catch (e) {
      debugPrint('❌ Shortcut update failed: $e');
    }
  }

  // Clear all shortcuts
  Future<void> clearShortcuts() async {
    try {
      await _quickActions.clearShortcutItems();
      debugPrint('📱 All shortcuts cleared');
    } catch (e) {
      debugPrint('❌ Shortcut clearing failed: $e');
    }
  }

  // Add dynamic shortcut (Android)
  Future<void> addDynamicShortcut({
    required String id,
    required String title,
    required String subtitle,
    required String route,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _platform.invokeMethod('addDynamicShortcut', {
          'id': id,
          'title': title,
          'subtitle': subtitle,
          'route': route,
          'parameters': parameters ?? {},
        });
        debugPrint('📱 Dynamic shortcut added: $title');
      }
    } catch (e) {
      debugPrint('❌ Dynamic shortcut addition failed: $e');
    }
  }

  // Remove dynamic shortcut (Android)
  Future<void> removeDynamicShortcut(String id) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _platform.invokeMethod('removeDynamicShortcut', {'id': id});
        debugPrint('📱 Dynamic shortcut removed: $id');
      }
    } catch (e) {
      debugPrint('❌ Dynamic shortcut removal failed: $e');
    }
  }

  // Pin shortcut to home screen (Android)
  Future<bool> pinShortcut({
    required String id,
    required String title,
    required String subtitle,
    required String route,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final result = await _platform.invokeMethod<bool>('pinShortcut', {
          'id': id,
          'title': title,
          'subtitle': subtitle,
          'route': route,
          'parameters': parameters ?? {},
        });
        debugPrint('📱 Shortcut pinned: $title (success: $result)');
        return result ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Shortcut pinning failed: $e');
      return false;
    }
  }

  // Create contextual shortcuts based on user activity
  Future<void> updateContextualShortcuts({
    String? mostTradedAsset,
    String? activeClan,
    String? controlledTerritory,
    bool hasActiveQuest = false,
  }) async {
    try {
      final contextualShortcuts = <ShortcutItem>[];

      // Most traded asset shortcut
      if (mostTradedAsset != null) {
        contextualShortcuts.add(ShortcutItem(
          type: 'trade_$mostTradedAsset',
          localizedTitle: 'Trade $mostTradedAsset',
          icon: 'trending_up',
        ));
      }

      // Active clan shortcut
      if (activeClan != null) {
        contextualShortcuts.add(ShortcutItem(
          type: 'clan_$activeClan',
          localizedTitle: 'View $activeClan',
          icon: 'groups',
        ));
      }

      // Controlled territory shortcut
      if (controlledTerritory != null) {
        contextualShortcuts.add(ShortcutItem(
          type: 'territory_$controlledTerritory',
          localizedTitle: 'Defend $controlledTerritory',
          icon: 'security',
        ));
      }

      // Active quest shortcut
      if (hasActiveQuest) {
        contextualShortcuts.add(ShortcutItem(
          type: 'active_quest',
          localizedTitle: 'Continue Quest',
          icon: 'task_alt',
        ));
      }

      // Update with contextual shortcuts (limit to 4 total)
      final currentShortcuts = await _quickActions.getShortcutItems();
      final allShortcuts = [...currentShortcuts, ...contextualShortcuts];
      final limitedShortcuts = allShortcuts.take(4).toList();

      await _quickActions.setShortcutItems(limitedShortcuts);
      
      debugPrint('📱 Contextual shortcuts updated');
    } catch (e) {
      debugPrint('❌ Contextual shortcut update failed: $e');
    }
  }

  // Handle shortcut tap
  void _handleShortcutTap(String shortcutType) {
    debugPrint('📱 Shortcut tapped: $shortcutType');
    
    // Route to appropriate screen based on shortcut type
    if (shortcutType.startsWith('trade_')) {
      final asset = shortcutType.substring(6);
      _navigateToTrading(asset);
    } else if (shortcutType.startsWith('clan_')) {
      final clanId = shortcutType.substring(5);
      _navigateToClan(clanId);
    } else if (shortcutType.startsWith('territory_')) {
      final territory = shortcutType.substring(10);
      _navigateToTerritory(territory);
    } else {
      _navigateToRoute(shortcutType);
    }
  }

  // Navigation helpers
  void _navigateToTrading(String asset) {
    debugPrint('📱 Navigate to trading: $asset');
    // This would trigger navigation to trading screen with specific asset
  }

  void _navigateToClan(String clanId) {
    debugPrint('📱 Navigate to clan: $clanId');
    // This would trigger navigation to specific clan screen
  }

  void _navigateToTerritory(String territory) {
    debugPrint('📱 Navigate to territory: $territory');
    // This would trigger navigation to territory defense screen
  }

  void _navigateToRoute(String shortcutType) {
    final shortcuts = getAvailableShortcuts();
    final shortcut = shortcuts.where((s) => s.id == shortcutType).firstOrNull;
    
    if (shortcut != null) {
      debugPrint('📱 Navigate to: ${shortcut.route} with ${shortcut.parameters}');
      // This would trigger navigation using go_router
    }
  }

  // Get icon name for platform
  String _getIconName(IconData icon) {
    // Map common icons to platform-specific names
    if (icon == Icons.trending_up) return 'trending_up';
    if (icon == Icons.account_balance_wallet) return 'account_balance_wallet';
    if (icon == Icons.groups) return 'groups';
    if (icon == Icons.map) return 'map';
    if (icon == Icons.notifications_active) return 'notifications';
    if (icon == Icons.leaderboard) return 'leaderboard';
    if (icon == Icons.palette) return 'palette';
    if (icon == Icons.school) return 'school';
    return 'star'; // Default icon
  }

  // Get shortcut configuration from storage
  Future<ShortcutConfiguration> getShortcutConfiguration(String userId) async {
    // In a real app, this would load from secure storage or database
    return ShortcutConfiguration(
      userId: userId,
      enabledShortcuts: ['quick_trade', 'portfolio_view', 'clan_hub', 'territory_map'],
      shortcutPriorities: {
        'quick_trade': 1,
        'portfolio_view': 2,
        'clan_hub': 3,
        'territory_map': 4,
      },
      maxShortcuts: 4,
      lastConfigured: DateTime.now(),
    );
  }

  // Save shortcut configuration
  Future<void> saveShortcutConfiguration(ShortcutConfiguration config) async {
    // In a real app, this would save to secure storage or database
    debugPrint('📱 Shortcut configuration saved for user ${config.userId}');
  }

  // Adaptive shortcuts based on time of day
  Future<void> updateTimeBasedShortcuts() async {
    try {
      final hour = DateTime.now().hour;
      final shortcuts = <ShortcutItem>[];

      if (hour >= 6 && hour < 12) {
        // Morning: Portfolio, News, Quick Trade
        shortcuts.addAll([
          const ShortcutItem(type: 'portfolio_view', localizedTitle: 'Portfolio', icon: 'account_balance_wallet'),
          const ShortcutItem(type: 'quick_trade', localizedTitle: 'Quick Trade', icon: 'trending_up'),
        ]);
      } else if (hour >= 12 && hour < 18) {
        // Afternoon: Trading, Clan, Territory
        shortcuts.addAll([
          const ShortcutItem(type: 'quick_trade', localizedTitle: 'Trade Now', icon: 'trending_up'),
          const ShortcutItem(type: 'clan_hub', localizedTitle: 'Clan Hub', icon: 'groups'),
          const ShortcutItem(type: 'territory_map', localizedTitle: 'Territory', icon: 'map'),
        ]);
      } else {
        // Evening/Night: Portfolio, Leaderboard, Street Art
        shortcuts.addAll([
          const ShortcutItem(type: 'portfolio_view', localizedTitle: 'Portfolio', icon: 'account_balance_wallet'),
          const ShortcutItem(type: 'leaderboard', localizedTitle: 'Leaderboard', icon: 'leaderboard'),
          const ShortcutItem(type: 'street_art', localizedTitle: 'Street Art', icon: 'palette'),
        ]);
      }

      await _quickActions.setShortcutItems(shortcuts);
      debugPrint('📱 Time-based shortcuts updated for hour $hour');
    } catch (e) {
      debugPrint('❌ Time-based shortcut update failed: $e');
    }
  }
}