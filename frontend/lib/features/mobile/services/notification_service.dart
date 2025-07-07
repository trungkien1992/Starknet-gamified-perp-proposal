import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import '../models/mobile_models.dart';
import '../../../app/theme/street_cred_theme.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const String _workmanagerTaskId = 'streetcred_background_update';
  
  // Notification channels
  static const AndroidNotificationChannel _tradeChannel = AndroidNotificationChannel(
    'trade_alerts',
    'Trade Alerts',
    description: 'Price alerts and trade notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _clanChannel = AndroidNotificationChannel(
    'clan_updates',
    'Clan Updates',
    description: 'Clan invites, challenges, and activities',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  static const AndroidNotificationChannel _gameChannel = AndroidNotificationChannel(
    'game_events',
    'Game Events',
    description: 'Quests, streaks, and territory updates',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: true,
  );

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize workmanager for background tasks
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Android initialization
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher'
      );

      // iOS initialization
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels
      await _createNotificationChannels();
      
      debugPrint('📱 Notification service initialized');
    } catch (e) {
      debugPrint('❌ Notification service initialization failed: $e');
    }
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    try {
      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      
      // Request iOS permissions
      final iosPermissions = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Request Android exact alarm permission for scheduled notifications
      if (defaultTargetPlatform == TargetPlatform.android) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        debugPrint('📱 Exact alarm permission: $exactAlarmStatus');
      }

      final granted = notificationStatus.isGranted && (iosPermissions ?? true);
      debugPrint('📱 Notification permissions granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ Permission request failed: $e');
      return false;
    }
  }

  // Create notification channels
  Future<void> _createNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_tradeChannel);
      await androidImplementation.createNotificationChannel(_clanChannel);
      await androidImplementation.createNotificationChannel(_gameChannel);
    }
  }

  // Schedule notification
  Future<void> scheduleNotification(PushNotification notification) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _getChannelId(notification.type),
        _getChannelName(notification.type),
        importance: _getImportance(notification.type),
        priority: Priority.high,
        color: notification.typeColor,
        icon: '@mipmap/ic_launcher',
        largeIcon: notification.imageUrl != null 
            ? FilePathAndroidBitmap(notification.imageUrl!)
            : null,
        actions: notification.actions.map((action) => 
          AndroidNotificationAction(
            action.id,
            action.title,
            titleColor: action.destructive 
                ? StreetCredTheme.shortColor 
                : StreetCredTheme.neonBlue,
          )
        ).toList(),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'streetcred_category',
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      if (notification.isRecurring && notification.recurringInterval != null) {
        // Schedule recurring notification
        await _notifications.periodicallyShow(
          notification.id.hashCode,
          notification.title,
          notification.body,
          _convertToRepeatInterval(notification.recurringInterval!),
          platformDetails,
          payload: _encodePayload(notification.data),
        );
      } else {
        // Schedule one-time notification
        await _notifications.zonedSchedule(
          notification.id.hashCode,
          notification.title,
          notification.body,
          _convertToTZDateTime(notification.scheduledTime),
          platformDetails,
          payload: _encodePayload(notification.data),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      debugPrint('📱 Notification scheduled: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Notification scheduling failed: $e');
    }
  }

  // Show immediate notification
  Future<void> showNotification(PushNotification notification) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _getChannelId(notification.type),
        _getChannelName(notification.type),
        importance: _getImportance(notification.type),
        priority: Priority.high,
        color: notification.typeColor,
        icon: '@mipmap/ic_launcher',
        ticker: notification.title,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: _encodePayload(notification.data),
      );

      debugPrint('📱 Notification shown: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Notification display failed: $e');
    }
  }

  // Cancel notification
  Future<void> cancelNotification(String notificationId) async {
    try {
      await _notifications.cancel(notificationId.hashCode);
      debugPrint('📱 Notification cancelled: $notificationId');
    } catch (e) {
      debugPrint('❌ Notification cancellation failed: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('📱 All notifications cancelled');
    } catch (e) {
      debugPrint('❌ All notifications cancellation failed: $e');
    }
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Getting pending notifications failed: $e');
      return [];
    }
  }

  // Setup background task for price alerts
  Future<void> setupBackgroundTasks() async {
    try {
      await Workmanager().registerPeriodicTask(
        _workmanagerTaskId,
        'price_alert_check',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      debugPrint('📱 Background tasks registered');
    } catch (e) {
      debugPrint('❌ Background task setup failed: $e');
    }
  }

  // Create trade alert notification
  PushNotification createTradeAlertNotification({
    required String assetSymbol,
    required double currentPrice,
    required double alertPrice,
    required bool isAbove,
  }) {
    final direction = isAbove ? 'above' : 'below';
    return PushNotification(
      id: 'trade_alert_${assetSymbol}_${DateTime.now().millisecondsSinceEpoch}',
      title: '🚨 Price Alert: $assetSymbol',
      body: '$assetSymbol is now $direction \$${alertPrice.toStringAsFixed(2)} at \$${currentPrice.toStringAsFixed(2)}',
      type: NotificationType.priceAlert,
      data: {
        'symbol': assetSymbol,
        'currentPrice': currentPrice,
        'alertPrice': alertPrice,
        'direction': direction,
        'action': 'open_trading',
      },
      scheduledTime: DateTime.now(),
      actions: [
        NotificationAction(
          id: 'trade_now',
          title: 'Trade Now',
          actionType: 'open_trading',
          payload: {'symbol': assetSymbol},
        ),
        NotificationAction(
          id: 'dismiss',
          title: 'Dismiss',
          actionType: 'dismiss',
          payload: {},
        ),
      ],
    );
  }

  // Create clan invitation notification
  PushNotification createClanInviteNotification({
    required String clanName,
    required String inviterName,
    required String inviteId,
  }) {
    return PushNotification(
      id: 'clan_invite_$inviteId',
      title: '🏢 Clan Invitation',
      body: '$inviterName invited you to join $clanName',
      type: NotificationType.clanInvite,
      data: {
        'clanName': clanName,
        'inviterName': inviterName,
        'inviteId': inviteId,
        'action': 'view_invite',
      },
      scheduledTime: DateTime.now(),
      actions: [
        NotificationAction(
          id: 'accept_invite',
          title: 'Accept',
          actionType: 'accept_clan_invite',
          payload: {'inviteId': inviteId},
        ),
        NotificationAction(
          id: 'decline_invite',
          title: 'Decline',
          actionType: 'decline_clan_invite',
          payload: {'inviteId': inviteId},
        ),
      ],
    );
  }

  // Create streak bonus notification
  PushNotification createStreakBonusNotification({
    required int streakCount,
    required double multiplier,
    required String streakType,
  }) {
    return PushNotification(
      id: 'streak_bonus_${DateTime.now().millisecondsSinceEpoch}',
      title: '🔥 Streak Bonus!',
      body: '$streakCount $streakType streak! ${multiplier}x multiplier active',
      type: NotificationType.streakBonus,
      data: {
        'streakCount': streakCount,
        'multiplier': multiplier,
        'streakType': streakType,
        'action': 'view_streak',
      },
      scheduledTime: DateTime.now(),
    );
  }

  // Create territory attack notification
  PushNotification createTerritoryAttackNotification({
    required String territoryName,
    required String attackerClan,
    required Duration timeRemaining,
  }) {
    return PushNotification(
      id: 'territory_attack_${DateTime.now().millisecondsSinceEpoch}',
      title: '⚔️ Territory Under Attack!',
      body: '$territoryName is being attacked by $attackerClan. ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m to defend!',
      type: NotificationType.territoryAttack,
      data: {
        'territoryName': territoryName,
        'attackerClan': attackerClan,
        'timeRemaining': timeRemaining.inMinutes,
        'action': 'defend_territory',
      },
      scheduledTime: DateTime.now(),
      actions: [
        NotificationAction(
          id: 'defend_now',
          title: 'Defend Now',
          actionType: 'defend_territory',
          payload: {'territory': territoryName},
        ),
        NotificationAction(
          id: 'view_map',
          title: 'View Map',
          actionType: 'open_territory_map',
          payload: {},
        ),
      ],
    );
  }

  // Helper methods
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.tradeAlert:
      case NotificationType.priceAlert:
        return _tradeChannel.id;
      case NotificationType.clanInvite:
        return _clanChannel.id;
      default:
        return _gameChannel.id;
    }
  }

  String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.tradeAlert:
      case NotificationType.priceAlert:
        return _tradeChannel.name;
      case NotificationType.clanInvite:
        return _clanChannel.name;
      default:
        return _gameChannel.name;
    }
  }

  Importance _getImportance(NotificationType type) {
    switch (type) {
      case NotificationType.tradeAlert:
      case NotificationType.priceAlert:
      case NotificationType.territoryAttack:
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  String _encodePayload(Map<String, dynamic> data) {
    // Simple JSON-like encoding for payload
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  RepeatInterval _convertToRepeatInterval(Duration duration) {
    if (duration.inDays >= 7) return RepeatInterval.weekly;
    if (duration.inDays >= 1) return RepeatInterval.daily;
    if (duration.inHours >= 1) return RepeatInterval.hourly;
    return RepeatInterval.everyMinute;
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // This would need proper timezone handling in a real app
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  // Callback handlers
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to appropriate screen
    final payload = response.payload;
    if (payload != null) {
      final data = _decodePayload(payload);
      _handleNotificationAction(data);
    }
  }

  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('📱 iOS notification received: $title');
  }

  static Map<String, dynamic> _decodePayload(String payload) {
    final Map<String, dynamic> data = {};
    final pairs = payload.split('|');
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    }
    return data;
  }

  static void _handleNotificationAction(Map<String, dynamic> data) {
    final action = data['action'] as String?;
    switch (action) {
      case 'open_trading':
        debugPrint('📱 Open trading screen for ${data['symbol']}');
        break;
      case 'view_invite':
        debugPrint('📱 Open clan invite screen');
        break;
      case 'defend_territory':
        debugPrint('📱 Open territory defense for ${data['territory']}');
        break;
      case 'view_streak':
        debugPrint('📱 Open streak/profile screen');
        break;
    }
  }
}

// Background task callback
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('📱 Background task executed: $task');
      
      // Check price alerts
      if (task == 'price_alert_check') {
        // This would check user's price alerts and trigger notifications
        // For demo purposes, we'll just log
        debugPrint('📱 Checking price alerts...');
      }
      
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Background task failed: $e');
      return Future.value(false);
    }
  });
}

// Import required for timezone handling
import 'package:timezone/timezone.dart' as tz;

