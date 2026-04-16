import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'mock_notifications.dart';
import 'notification_storage.dart';
import 'notification_template.dart';

class NotificationService {
  NotificationService._({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationStorage? storage,
    Random? random,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _storage = storage ?? NotificationStorage(),
       _random = random ?? Random();

  static final NotificationService instance = NotificationService._();

  static const int dailyNotificationId = 7401;
  static const Duration minimumNotificationInterval = Duration(hours: 24);

  static const String _androidChannelId = 'daily_puzzle_reminders';
  static const String _androidChannelName = 'Daily puzzle reminders';
  static const String _androidChannelDescription =
      'Local reminders for bottles, colors, coins, styles, and levels.';

  static const Set<String> validPayloadRoutes = <String>{
    '/home',
    '/game',
    '/shop',
    '/settings',
  };

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationStorage _storage;
  final Random _random;

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isInitialized = false;
  bool? _permissionsGranted;
  String? _initialPayloadRoute;
  String? _queuedRoute;

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey ?? _navigatorKey;
    if (_isInitialized) return;

    if (!_canUseLocalNotifications) {
      _log('Local notifications are not supported on this platform.');
      return;
    }

    try {
      tzdata.initializeTimeZones();

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _plugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      await _createAndroidNotificationChannel();
      await _cacheLaunchPayloadRoute();

      _isInitialized = true;
      _log('Local notification plugin initialized.');
    } catch (error, stackTrace) {
      _log(
        'Failed to initialize local notifications.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> requestPermissions() async {
    if (!_canUseLocalNotifications) {
      _permissionsGranted = false;
      return false;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        _permissionsGranted = granted ?? true;
        _log('Android notification permission: $_permissionsGranted');
        return _permissionsGranted!;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        _permissionsGranted = granted ?? false;
        _log('iOS notification permission: $_permissionsGranted');
        return _permissionsGranted!;
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macOS = _plugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >();
        final granted = await macOS?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        _permissionsGranted = granted ?? false;
        _log('macOS notification permission: $_permissionsGranted');
        return _permissionsGranted!;
      }
    } catch (error, stackTrace) {
      _permissionsGranted = false;
      _log(
        'Failed to request notification permissions.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return _permissionsGranted ?? false;
  }

  Future<NotificationHistory> loadNotificationHistory() {
    return _storage.loadNotificationHistory();
  }

  Future<void> saveNotificationHistory(NotificationHistory history) {
    return _storage.saveNotificationHistory(history);
  }

  Future<NotificationTemplate?> scheduleNextDailyNotification() async {
    if (!_canUseLocalNotifications) return null;
    if (!_isInitialized) await init();
    if (_permissionsGranted == false) {
      _log('Schedule skipped because notification permission was denied.');
      return null;
    }

    try {
      await cancelInvalidOrOutdatedPendingNotification();

      final history = await loadNotificationHistory();
      final now = DateTime.now();
      final lastNotificationAt = history.lastNotificationAt;
      if (lastNotificationAt != null &&
          now.difference(lastNotificationAt) < minimumNotificationInterval) {
        _log(
          'Schedule skipped. Last notification was scheduled at '
          '${lastNotificationAt.toIso8601String()}.',
        );
        return null;
      }

      final template = pickRandomNotification(history: history);
      if (template == null) {
        _log('Schedule skipped. No eligible notification template found.');
        return null;
      }

      final scheduledFor = now.add(minimumNotificationInterval);
      final zonedScheduleTime = tz.TZDateTime.from(scheduledFor, tz.local);
      final payload = _encodePayload(
        template: template,
        scheduledFor: scheduledFor,
      );

      await _cancelAllPendingNotifications();
      await _plugin.zonedSchedule(
        id: dailyNotificationId,
        title: template.title,
        body: template.body,
        scheduledDate: zonedScheduleTime,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );

      await saveNotificationHistory(
        history.copyWith(
          lastNotificationAt: now,
          lastNotificationTemplateId: template.id,
          recentNotificationIds: NotificationStorage.appendRecentId(
            history.recentNotificationIds,
            template.id,
          ),
          pendingNotificationTemplateId: template.id,
          pendingNotificationScheduledFor: scheduledFor,
        ),
      );

      _log('Scheduled ${template.id} for ${scheduledFor.toIso8601String()}.');
      return template;
    } catch (error, stackTrace) {
      _log(
        'Failed to schedule next daily notification.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  NotificationTemplate? pickRandomNotification({
    NotificationHistory? history,
    Iterable<NotificationTemplate> templates = mockNotifications,
  }) {
    final notificationHistory = history ?? const NotificationHistory();
    final activeTemplates = templates
        .where(
          (template) =>
              template.isActive &&
              NotificationCategories.all.contains(template.category) &&
              validPayloadRoutes.contains(template.payloadRoute),
        )
        .toList(growable: false);

    if (activeTemplates.isEmpty) return null;

    final lastTemplateId = notificationHistory.lastNotificationTemplateId;
    final recentIds = notificationHistory.recentNotificationIds
        .take(NotificationStorage.recentHistoryLimit)
        .toSet();

    var candidates = activeTemplates
        .where(
          (template) =>
              template.id != lastTemplateId && !recentIds.contains(template.id),
        )
        .toList();

    candidates = candidates.isEmpty
        ? activeTemplates
              .where((template) => template.id != lastTemplateId)
              .toList()
        : candidates;

    if (candidates.isEmpty) return null;
    return candidates[_random.nextInt(candidates.length)];
  }

  Future<void> cancelInvalidOrOutdatedPendingNotification() async {
    if (!_canUseLocalNotifications) return;

    try {
      final pendingRequests = await _plugin.pendingNotificationRequests();
      final history = await loadNotificationHistory();
      final now = DateTime.now();

      if (pendingRequests.isEmpty) {
        if (history.pendingNotificationTemplateId != null ||
            history.pendingNotificationScheduledFor != null) {
          await _storage.clearPendingNotification();
        }
        return;
      }

      final hasUnexpectedPending =
          pendingRequests.length > 1 ||
          pendingRequests.any((request) => request.id != dailyNotificationId);
      if (hasUnexpectedPending) {
        await _cancelAllPendingNotifications();
        await _storage.clearPendingNotification();
        _log('Cancelled unexpected pending notifications.');
        return;
      }

      final pending = pendingRequests.single;
      final pendingTemplateId = _templateIdFromPayload(pending.payload);
      final pendingRoute = routeFromPayload(pending.payload);
      final scheduledFor = history.pendingNotificationScheduledFor;

      final isValidTemplate =
          pendingTemplateId != null &&
          _templateById(pendingTemplateId)?.isActive == true;
      final isValidPending =
          pending.id == dailyNotificationId &&
          isValidTemplate &&
          pendingRoute != null &&
          scheduledFor != null &&
          scheduledFor.isAfter(now);

      if (!isValidPending) {
        await _cancelAllPendingNotifications();
        await _storage.clearPendingNotification();
        _log('Cancelled invalid or outdated pending notification.');
      }
    } catch (error, stackTrace) {
      _log(
        'Failed to inspect pending notifications.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_canUseLocalNotifications) return;

    try {
      await _plugin.cancelAll();
      await _storage.clearPendingNotification();
      _log('Cancelled all local notifications.');
    } catch (error, stackTrace) {
      _log(
        'Failed to cancel local notifications.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<NotificationTemplate?> debugShowInstantNotification({
    String? templateId,
  }) async {
    if (!_canUseLocalNotifications) return null;
    if (!_isInitialized) await init();
    if (_permissionsGranted == false) {
      _log('Debug notification skipped because permission was denied.');
      return null;
    }

    try {
      final history = await loadNotificationHistory();
      final template = templateId == null
          ? pickRandomNotification(history: history)
          : _templateById(templateId);

      if (template == null || !template.isActive) {
        _log('Debug notification skipped. Template not found: $templateId');
        return null;
      }

      final now = DateTime.now();
      await _cancelAllPendingNotifications();
      await _plugin.show(
        id: dailyNotificationId,
        title: template.title,
        body: template.body,
        notificationDetails: _notificationDetails(),
        payload: _encodePayload(template: template, scheduledFor: now),
      );

      await saveNotificationHistory(
        history.copyWith(
          lastNotificationAt: now,
          lastNotificationTemplateId: template.id,
          recentNotificationIds: NotificationStorage.appendRecentId(
            history.recentNotificationIds,
            template.id,
          ),
          clearPendingNotificationTemplateId: true,
          clearPendingNotificationScheduledFor: true,
        ),
      );

      _log('Displayed instant debug notification ${template.id}.');
      return template;
    } catch (error, stackTrace) {
      _log(
        'Failed to show instant debug notification.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String? takeInitialPayloadRoute() {
    final route = _initialPayloadRoute;
    _initialPayloadRoute = null;
    return route;
  }

  void routeQueuedPayloadIfAny() {
    final route = _queuedRoute;
    if (route == null) return;

    _queuedRoute = null;
    navigateToPayloadRoute(route);
  }

  void navigateToPayloadRoute(String route) {
    if (!validPayloadRoutes.contains(route)) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _queuedRoute = route;
      _log('Queued notification route until navigator is ready: $route');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeNavigator = _navigatorKey?.currentState;
      if (activeNavigator == null) {
        _queuedRoute = route;
        return;
      }

      activeNavigator.pushNamedAndRemoveUntil(route, (_) => false);
    });
  }

  String? routeFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    if (validPayloadRoutes.contains(payload)) {
      return payload;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      final route = decoded['route'];
      if (route is String && validPayloadRoutes.contains(route)) {
        return route;
      }
    } on FormatException catch (error, stackTrace) {
      _log(
        'Invalid notification payload JSON.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<void> _createAndroidNotificationChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _cacheLaunchPayloadRoute() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp != true) return;

    _initialPayloadRoute = routeFromPayload(
      launchDetails?.notificationResponse?.payload,
    );
    _log('Cached launch notification route: $_initialPayloadRoute');
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final route = routeFromPayload(response.payload);
    if (route == null) {
      _log('Notification tap ignored because payload route was invalid.');
      return;
    }

    navigateToPayloadRoute(route);
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: false,
      presentBanner: true,
      presentList: true,
      threadIdentifier: 'daily_puzzle_reminders',
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  String _encodePayload({
    required NotificationTemplate template,
    required DateTime scheduledFor,
  }) {
    return jsonEncode(<String, dynamic>{
      'templateId': template.id,
      'category': template.category,
      'route': template.payloadRoute,
      'scheduledFor': scheduledFor.toUtc().toIso8601String(),
    });
  }

  String? _templateIdFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      final templateId = decoded['templateId'];
      return templateId is String ? templateId : null;
    } on FormatException {
      return null;
    }
  }

  NotificationTemplate? _templateById(String templateId) {
    for (final template in mockNotifications) {
      if (template.id == templateId) return template;
    }
    return null;
  }

  Future<void> _cancelAllPendingNotifications() async {
    await _plugin.cancelAllPendingNotifications();
  }

  bool get _canUseLocalNotifications {
    if (kIsWeb) return false;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => false,
    };
  }

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'NotificationService',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
