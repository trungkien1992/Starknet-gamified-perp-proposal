import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/street_cred_theme.dart';
import '../../../app/theme/street_cred_design_system.dart';
import '../../../app/widgets/street_cred_card.dart';
import '../../../app/widgets/street_cred_header.dart';
import '../../../app/widgets/street_cred_button.dart' as scb;
import '../models/mobile_models.dart';
import '../providers/mobile_providers.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';
import '../services/shortcut_service.dart';

class MobileSettingsScreen extends ConsumerStatefulWidget {
  const MobileSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends ConsumerState<MobileSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: StreetCredTheme.neonBlue,
          labelColor: StreetCredTheme.neonBlue,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'WIDGETS', icon: Icon(Icons.widgets)),
            Tab(text: 'NOTIFICATIONS', icon: Icon(Icons.notifications)),
            Tab(text: 'SHORTCUTS', icon: Icon(Icons.launch)),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: StreetCredDesignSystem.backgroundGradient(StreetCredTheme.neonBlue),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              StreetCredHeader(
                title: 'MOBILE FEATURES',
                themeColor: StreetCredTheme.neonBlue,
                showBrandSymbol: false,
                subtitle: 'Customize your mobile experience',
              ),

              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWidgetSettings(),
                    _buildNotificationSettings(),
                    _buildShortcutSettings(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetSettings() {
    final widgetConfigAsync = ref.watch(widgetConfigurationProvider);
    final widgetService = ref.read(widgetServiceProvider);

    return widgetConfigAsync.when(
      data: (config) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOME SCREEN WIDGETS',
              style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonBlue).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Add StreetCred widgets to your home screen for quick access to trading data',
              style: StreetCredDesignSystem.captionStyle().copyWith(
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 20),

            // Available widgets
            ...widgetService.getAvailableWidgets().map((widget) => 
              _buildWidgetToggle(widget, config)
            ),

            const SizedBox(height: 32),

            // Refresh settings
            StreetCredCard(
              themeColor: StreetCredTheme.neonGreen,
              size: CardSize.small,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTO-REFRESH',
                    style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonGreen).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: Text(
                      'Enable Auto-Refresh',
                      style: StreetCredDesignSystem.bodyStyle(),
                    ),
                    subtitle: Text(
                      'Automatically update widget data',
                      style: StreetCredDesignSystem.captionStyle(),
                    ),
                    value: config.autoRefreshEnabled,
                    activeColor: StreetCredTheme.neonGreen,
                    onChanged: (value) {
                      ref.read(widgetConfigurationProvider.notifier)
                          .updateRefreshSettings(value, config.refreshInterval);
                    },
                  ),
                  
                  if (config.autoRefreshEnabled) ...[
                    const SizedBox(height: 12),
                    
                    Text(
                      'Refresh Interval: ${config.refreshInterval.inMinutes} minutes',
                      style: StreetCredDesignSystem.captionStyle(),
                    ),
                    
                    Slider(
                      value: config.refreshInterval.inMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      activeColor: StreetCredTheme.neonGreen,
                      inactiveColor: StreetCredTheme.neonGreen.withOpacity(0.3),
                      onChanged: (value) {
                        ref.read(widgetConfigurationProvider.notifier)
                            .updateRefreshSettings(
                              config.autoRefreshEnabled, 
                              Duration(minutes: value.round())
                            );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            scb.StreetCredButton(
              text: 'REFRESH ALL WIDGETS',
              themeColor: StreetCredTheme.neonBlue,
              style: scb.ButtonStyle.secondary,
              onPressed: () async {
                await widgetService.refreshAllWidgets(config);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📱 All widgets refreshed!'),
                      backgroundColor: StreetCredTheme.neonGreen,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: StreetCredTheme.neonBlue),
      ),
      error: (error, _) => Center(
        child: Text(
          'Failed to load widget settings',
          style: StreetCredDesignSystem.bodyStyle(),
        ),
      ),
    );
  }

  Widget _buildWidgetToggle(AppWidget widget, WidgetConfiguration config) {
    final isEnabled = config.enabledWidgets.contains(widget.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: StreetCredCard(
        themeColor: widget.primaryColor,
        size: CardSize.small,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: widget.primaryColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  Text(
                    widget.description,
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    widget.sizeDisplayName,
                    style: StreetCredDesignSystem.captionStyle().copyWith(
                      color: widget.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            Switch(
              value: isEnabled,
              activeColor: widget.primaryColor,
              onChanged: (value) {
                ref.read(widgetConfigurationProvider.notifier)
                    .updateWidgetEnabled(widget.id, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final notificationSettingsAsync = ref.watch(notificationSettingsProvider);

    return notificationSettingsAsync.when(
      data: (settings) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PUSH NOTIFICATIONS',
              style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonPink).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Get real-time alerts for trading opportunities and game events',
              style: StreetCredDesignSystem.captionStyle().copyWith(
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 20),

            // Main toggle
            StreetCredCard(
              themeColor: StreetCredTheme.neonPink,
              size: CardSize.small,
              child: SwitchListTile(
                title: Text(
                  'Enable Push Notifications',
                  style: StreetCredDesignSystem.bodyStyle().copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Master toggle for all notifications',
                  style: StreetCredDesignSystem.captionStyle(),
                ),
                value: settings.pushNotificationsEnabled,
                activeColor: StreetCredTheme.neonPink,
                onChanged: (value) {
                  ref.read(notificationSettingsProvider.notifier)
                      .updatePushNotificationsEnabled(value);
                },
              ),
            ),

            if (settings.pushNotificationsEnabled) ...[
              const SizedBox(height: 20),

              // Notification types
              Text(
                'NOTIFICATION TYPES',
                style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonYellow).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),

              ...NotificationType.values.map((type) => 
                _buildNotificationTypeToggle(type, settings)
              ),

              const SizedBox(height: 20),

              // Quiet hours
              StreetCredCard(
                themeColor: StreetCredTheme.neonCyan,
                size: CardSize.small,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUIET HOURS',
                      style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonCyan).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      title: Text(
                        'Enable Quiet Hours',
                        style: StreetCredDesignSystem.bodyStyle(),
                      ),
                      subtitle: Text(
                        'Silence notifications during specified hours',
                        style: StreetCredDesignSystem.captionStyle(),
                      ),
                      value: settings.quietHoursEnabled,
                      activeColor: StreetCredTheme.neonCyan,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier)
                            .updateQuietHours(value, settings.quietHoursStart, settings.quietHoursEnd);
                      },
                    ),
                    
                    if (settings.quietHoursEnabled) ...[
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start: ${settings.quietHoursStart}:00',
                                  style: StreetCredDesignSystem.captionStyle(),
                                ),
                                Slider(
                                  value: settings.quietHoursStart.toDouble(),
                                  min: 0,
                                  max: 23,
                                  divisions: 23,
                                  activeColor: StreetCredTheme.neonCyan,
                                  onChanged: (value) {
                                    ref.read(notificationSettingsProvider.notifier)
                                        .updateQuietHours(
                                          settings.quietHoursEnabled,
                                          value.round(),
                                          settings.quietHoursEnd,
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End: ${settings.quietHoursEnd}:00',
                                  style: StreetCredDesignSystem.captionStyle(),
                                ),
                                Slider(
                                  value: settings.quietHoursEnd.toDouble(),
                                  min: 0,
                                  max: 23,
                                  divisions: 23,
                                  activeColor: StreetCredTheme.neonCyan,
                                  onChanged: (value) {
                                    ref.read(notificationSettingsProvider.notifier)
                                        .updateQuietHours(
                                          settings.quietHoursEnabled,
                                          settings.quietHoursStart,
                                          value.round(),
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Sound settings
              StreetCredCard(
                themeColor: StreetCredTheme.neonGreen,
                size: CardSize.small,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOUND & VIBRATION',
                      style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonGreen).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      title: Text('Sound', style: StreetCredDesignSystem.bodyStyle()),
                      value: settings.soundEnabled,
                      activeColor: StreetCredTheme.neonGreen,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier)
                            .updateSoundSettings(
                              settings.vibrateEnabled,
                              value,
                              settings.customSoundPath,
                            );
                      },
                    ),
                    
                    SwitchListTile(
                      title: Text('Vibration', style: StreetCredDesignSystem.bodyStyle()),
                      value: settings.vibrateEnabled,
                      activeColor: StreetCredTheme.neonGreen,
                      onChanged: (value) {
                        ref.read(notificationSettingsProvider.notifier)
                            .updateSoundSettings(
                              value,
                              settings.soundEnabled,
                              settings.customSoundPath,
                            );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: StreetCredTheme.neonPink),
      ),
      error: (error, _) => Center(
        child: Text(
          'Failed to load notification settings',
          style: StreetCredDesignSystem.bodyStyle(),
        ),
      ),
    );
  }

  Widget _buildNotificationTypeToggle(NotificationType type, NotificationSettings settings) {
    final isEnabled = settings.typeSettings[type] ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: StreetCredCard(
        themeColor: type.typeColor,
        size: CardSize.small,
        child: SwitchListTile(
          secondary: Icon(
            type.typeIcon,
            color: type.typeColor,
            size: 20,
          ),
          title: Text(
            type.typeDisplayName,
            style: StreetCredDesignSystem.bodyStyle().copyWith(
              fontSize: 14,
            ),
          ),
          value: isEnabled,
          activeColor: type.typeColor,
          onChanged: (value) {
            ref.read(notificationSettingsProvider.notifier)
                .updateNotificationType(type, value);
          },
        ),
      ),
    );
  }

  Widget _buildShortcutSettings() {
    final shortcutConfigAsync = ref.watch(shortcutConfigurationProvider);
    final shortcutService = ref.read(shortcutServiceProvider);

    return shortcutConfigAsync.when(
      data: (config) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'APP SHORTCUTS',
              style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonYellow).copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Long-press the app icon to access quick shortcuts',
              style: StreetCredDesignSystem.captionStyle().copyWith(
                color: Colors.white70,
              ),
            ),
            
            const SizedBox(height: 20),

            // Max shortcuts setting
            StreetCredCard(
              themeColor: StreetCredTheme.neonYellow,
              size: CardSize.small,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maximum Shortcuts: ${config.maxShortcuts}',
                    style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonYellow).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Slider(
                    value: config.maxShortcuts.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    activeColor: StreetCredTheme.neonYellow,
                    inactiveColor: StreetCredTheme.neonYellow.withOpacity(0.3),
                    onChanged: (value) {
                      ref.read(shortcutConfigurationProvider.notifier)
                          .updateMaxShortcuts(value.round());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'AVAILABLE SHORTCUTS',
              style: StreetCredDesignSystem.subtitleStyle(StreetCredTheme.neonGreen).copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),

            // Available shortcuts
            ...shortcutService.getAvailableShortcuts().map((shortcut) => 
              _buildShortcutToggle(shortcut, config)
            ),

            const SizedBox(height: 20),

            scb.StreetCredButton(
              text: 'UPDATE SHORTCUTS',
              themeColor: StreetCredTheme.neonYellow,
              style: scb.ButtonStyle.secondary,
              onPressed: () async {
                await shortcutService.updateShortcuts(config);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📱 App shortcuts updated!'),
                      backgroundColor: StreetCredTheme.neonGreen,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(color: StreetCredTheme.neonYellow),
      ),
      error: (error, _) => Center(
        child: Text(
          'Failed to load shortcut settings',
          style: StreetCredDesignSystem.bodyStyle(),
        ),
      ),
    );
  }

  Widget _buildShortcutToggle(AppShortcut shortcut, ShortcutConfiguration config) {
    final isEnabled = config.enabledShortcuts.contains(shortcut.id);
    final priority = config.shortcutPriorities[shortcut.id] ?? shortcut.priority;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: StreetCredCard(
        themeColor: shortcut.iconColor,
        size: CardSize.small,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: shortcut.iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    shortcut.icon,
                    color: shortcut.iconColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shortcut.title,
                        style: StreetCredDesignSystem.subtitleStyle(Colors.white).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      Text(
                        shortcut.subtitle,
                        style: StreetCredDesignSystem.captionStyle().copyWith(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      
                      Text(
                        'Priority: $priority',
                        style: StreetCredDesignSystem.captionStyle().copyWith(
                          color: shortcut.iconColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Switch(
                  value: isEnabled && shortcut.isEnabled,
                  activeColor: shortcut.iconColor,
                  onChanged: shortcut.isEnabled ? (value) {
                    final updatedShortcuts = [...config.enabledShortcuts];
                    if (value) {
                      updatedShortcuts.add(shortcut.id);
                    } else {
                      updatedShortcuts.remove(shortcut.id);
                    }
                    ref.read(shortcutConfigurationProvider.notifier)
                        .updateEnabledShortcuts(updatedShortcuts);
                  } : null,
                ),
              ],
            ),
            
            if (isEnabled && shortcut.isEnabled) ...[
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Text(
                    'Priority: $priority',
                    style: StreetCredDesignSystem.captionStyle(),
                  ),
                  
                  Expanded(
                    child: Slider(
                      value: priority.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: shortcut.iconColor,
                      onChanged: (value) {
                        ref.read(shortcutConfigurationProvider.notifier)
                            .updateShortcutPriority(shortcut.id, value.round());
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Extension for notification type properties
extension NotificationTypeExtension on NotificationType {
  Color get typeColor {
    switch (this) {
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

  IconData get typeIcon {
    switch (this) {
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

  String get typeDisplayName {
    switch (this) {
      case NotificationType.tradeAlert:
        return 'Trade Alerts';
      case NotificationType.priceAlert:
        return 'Price Alerts';
      case NotificationType.clanInvite:
        return 'Clan Invitations';
      case NotificationType.questComplete:
        return 'Quest Complete';
      case NotificationType.territoryAttack:
        return 'Territory Attacks';
      case NotificationType.leaderboardUpdate:
        return 'Leaderboard Updates';
      case NotificationType.streakBonus:
        return 'Streak Bonuses';
      case NotificationType.eventStart:
        return 'Event Started';
    }
  }
}