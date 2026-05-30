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

class _DailyNotificationSlot {
  const _DailyNotificationSlot({
    required this.id,
    required this.hour,
    required this.minute,
  });

  final int id;
  final int hour;
  final int minute;

  DateTime scheduledFor(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

class _ScheduleCleanupResult {
  const _ScheduleCleanupResult({
    required this.history,
    required this.keptRecords,
  });

  final NotificationHistory history;
  final List<ScheduledNotificationRecord> keptRecords;
}

class NotificationService {
  NotificationService._({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationStorage? storage,
    Random? random,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _storage = storage ?? NotificationStorage(),
       _random = random ?? Random();

  static final NotificationService instance = NotificationService._();

  static const int afternoonNotificationId = 740301;
  static const int eveningNotificationId = 740302;
  static const int nightNotificationId = 740303;
  static const int debugNotificationId = 740399;
  static const int legacyDailyNotificationId = 7401;

  static const Set<int> dailyNotificationIds = <int>{
    afternoonNotificationId,
    eveningNotificationId,
    nightNotificationId,
  };

  static const Set<int> _ownedScheduledNotificationIds = <int>{
    legacyDailyNotificationId,
    ...dailyNotificationIds,
  };

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

  static const List<_DailyNotificationSlot> _dailySlots =
      <_DailyNotificationSlot>[
        _DailyNotificationSlot(
          id: afternoonNotificationId,
          hour: 15,
          minute: 0,
        ),
        _DailyNotificationSlot(id: eveningNotificationId, hour: 19, minute: 0),
        _DailyNotificationSlot(id: nightNotificationId, hour: 21, minute: 30),
      ];

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

  Future<List<ScheduledNotificationRecord>> scheduleDailyNotifications({
    DateTime? now,
  }) async {
    if (!_canUseLocalNotifications) {
      return const <ScheduledNotificationRecord>[];
    }
    if (!_isInitialized) await init();
    if (_permissionsGranted == false) {
      _log('Schedule skipped because notification permission was denied.');
      return const <ScheduledNotificationRecord>[];
    }

    final nowLocal = now ?? DateTime.now();
    final targetSlots = _targetSlotsFor(nowLocal);
    final targetDate = targetSlots.first.scheduledFor;

    return scheduleNotificationsForDate(targetDate, now: nowLocal);
  }

  Future<List<ScheduledNotificationRecord>> scheduleNotificationsForDate(
    DateTime date, {
    DateTime? now,
  }) async {
    if (!_canUseLocalNotifications) {
      return const <ScheduledNotificationRecord>[];
    }
    if (!_isInitialized) await init();
    if (_permissionsGranted == false) {
      _log('Schedule skipped because notification permission was denied.');
      return const <ScheduledNotificationRecord>[];
    }

    final nowLocal = now ?? DateTime.now();
    final targetSlots = _slotsForDate(date)
        .where((slot) => slot.scheduledFor.isAfter(nowLocal))
        .toList(growable: false);

    if (targetSlots.isEmpty) {
      final history = await loadNotificationHistory();
      final pendingRequests = await _pendingNotificationRequests();
      await _cleanupForTargetSlots(
        history: history,
        pendingRequests: pendingRequests,
        targetSlots: const <ScheduledNotificationRecord>[],
        now: nowLocal,
      );
      return const <ScheduledNotificationRecord>[];
    }

    try {
      final history = await loadNotificationHistory();
      final pendingRequests = await _pendingNotificationRequests();
      final cleanup = await _cleanupForTargetSlots(
        history: history,
        pendingRequests: pendingRequests,
        targetSlots: targetSlots,
        now: nowLocal,
      );

      final keptRecords = cleanup.keptRecords;
      final keptIds = keptRecords.map((record) => record.id).toSet();
      final missingSlots = targetSlots
          .where((slot) => !keptIds.contains(slot.id))
          .toList(growable: false);

      if (missingSlots.isEmpty) {
        _log('Daily reminders already match the next fixed schedule.');
        return keptRecords;
      }

      final keptTemplateIds = keptRecords
          .map((record) => record.templateId)
          .toSet();
      final templates = pickUniqueNotifications(
        count: missingSlots.length,
        history: cleanup.history,
        excludedTemplateIds: keptTemplateIds,
      );

      if (templates.length < missingSlots.length) {
        _log(
          'Only ${templates.length} notification templates were available '
          'for ${missingSlots.length} required slots.',
        );
      }

      final newRecords = <ScheduledNotificationRecord>[];
      for (var index = 0; index < templates.length; index += 1) {
        final slot = missingSlots[index];
        final template = templates[index];
        final record = ScheduledNotificationRecord(
          id: slot.id,
          templateId: template.id,
          scheduledFor: slot.scheduledFor,
          payloadRoute: template.payloadRoute,
        );

        await _scheduleRecord(record, template);
        newRecords.add(record);
      }

      final scheduledRecords = <ScheduledNotificationRecord>[
        ...keptRecords,
        ...newRecords,
      ]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));

      final recentIds = NotificationStorage.appendRecentIds(
        cleanup.history.recentNotificationIds,
        newRecords.map((record) => record.templateId),
      );

      final lastTemplateId = newRecords.isEmpty
          ? cleanup.history.lastNotificationTemplateId
          : newRecords.last.templateId;

      await saveNotificationHistory(
        cleanup.history.copyWith(
          lastScheduledAt: nowLocal,
          lastNotificationTemplateId: lastTemplateId,
          recentNotificationIds: recentIds,
          scheduledNotifications: scheduledRecords,
        ),
      );

      _log(
        'Scheduled ${newRecords.length} local reminder(s). '
        '${scheduledRecords.length} future fixed reminder(s) are active.',
      );
      return scheduledRecords;
    } catch (error, stackTrace) {
      _log(
        'Failed to schedule daily notifications.',
        error: error,
        stackTrace: stackTrace,
      );
      return const <ScheduledNotificationRecord>[];
    }
  }

  List<NotificationTemplate> pickUniqueNotifications({
    required int count,
    NotificationHistory? history,
    Iterable<NotificationTemplate> templates = mockNotifications,
    Set<String> excludedTemplateIds = const <String>{},
  }) {
    if (count <= 0) return const <NotificationTemplate>[];

    final notificationHistory = history ?? const NotificationHistory();
    final activeTemplates = templates
        .where(
          (template) =>
              template.isActive &&
              NotificationCategories.all.contains(template.category) &&
              validPayloadRoutes.contains(template.payloadRoute),
        )
        .toList(growable: false);

    if (activeTemplates.isEmpty) return const <NotificationTemplate>[];

    final picked = <NotificationTemplate>[];
    final recentIds = notificationHistory.recentNotificationIds
        .take(NotificationStorage.recentHistoryLimit)
        .toSet();
    var lastTemplateId =
        notificationHistory.lastNotificationTemplateId ??
        (notificationHistory.recentNotificationIds.isEmpty
            ? null
            : notificationHistory.recentNotificationIds.first);

    while (picked.length < count) {
      final blockedIds = <String>{
        ...excludedTemplateIds,
        ...picked.map((template) => template.id),
      };

      var candidates = activeTemplates
          .where(
            (template) =>
                !blockedIds.contains(template.id) &&
                template.id != lastTemplateId &&
                !recentIds.contains(template.id),
          )
          .toList();

      candidates = candidates.isEmpty
          ? activeTemplates
                .where(
                  (template) =>
                      !blockedIds.contains(template.id) &&
                      template.id != lastTemplateId,
                )
                .toList()
          : candidates;

      if (candidates.isEmpty) break;

      final selected = candidates[_random.nextInt(candidates.length)];
      picked.add(selected);
      lastTemplateId = selected.id;
    }

    return picked;
  }

  NotificationTemplate? pickRandomNotification({
    NotificationHistory? history,
    Iterable<NotificationTemplate> templates = mockNotifications,
  }) {
    final picked = pickUniqueNotifications(
      count: 1,
      history: history,
      templates: templates,
    );
    return picked.isEmpty ? null : picked.single;
  }

  Future<void> cancelInvalidOrOutdatedPendingNotifications({
    DateTime? now,
  }) async {
    if (!_canUseLocalNotifications) return;
    if (!_isInitialized) await init();

    final nowLocal = now ?? DateTime.now();
    final history = await loadNotificationHistory();
    final pendingRequests = await _pendingNotificationRequests();

    await _cleanupForTargetSlots(
      history: history,
      pendingRequests: pendingRequests,
      targetSlots: _targetSlotsFor(nowLocal),
      now: nowLocal,
    );
  }

  Future<void> cancelInvalidOrOutdatedPendingNotification({DateTime? now}) {
    return cancelInvalidOrOutdatedPendingNotifications(now: now);
  }

  Future<void> cancelAllNotifications() async {
    if (!_canUseLocalNotifications) return;

    try {
      await _plugin.cancelAll();
      await _storage.clearScheduledNotifications();
      _log('Cancelled all local notifications.');
    } catch (error, stackTrace) {
      _log(
        'Failed to cancel local notifications.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<NotificationTemplate?> debugScheduleForNextMinute({
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
      final scheduledFor = now.add(const Duration(minutes: 1));
      final record = ScheduledNotificationRecord(
        id: debugNotificationId,
        templateId: template.id,
        scheduledFor: scheduledFor,
        payloadRoute: template.payloadRoute,
      );

      await _plugin.cancel(id: debugNotificationId);
      await _scheduleRecord(record, template);
      await saveNotificationHistory(
        history.copyWith(
          lastScheduledAt: now,
          lastNotificationTemplateId: template.id,
          recentNotificationIds: NotificationStorage.appendRecentId(
            history.recentNotificationIds,
            template.id,
          ),
        ),
      );

      _log(
        'Scheduled debug notification ${template.id} for '
        '${scheduledFor.toIso8601String()}.',
      );
      return template;
    } catch (error, stackTrace) {
      _log(
        'Failed to schedule debug notification.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
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
      await _plugin.show(
        id: debugNotificationId,
        title: template.title,
        body: template.body,
        notificationDetails: _notificationDetails(),
        payload: _encodePayload(template: template, scheduledFor: now),
      );

      await saveNotificationHistory(
        history.copyWith(
          lastScheduledAt: now,
          lastNotificationTemplateId: template.id,
          recentNotificationIds: NotificationStorage.appendRecentId(
            history.recentNotificationIds,
            template.id,
          ),
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

    final decoded = _decodePayload(payload);
    final route = decoded?['route'];
    if (route is String && validPayloadRoutes.contains(route)) {
      return route;
    }

    return null;
  }

  List<ScheduledNotificationRecord> _targetSlotsFor(DateTime now) {
    final todaysSlots = _slotsForDate(
      now,
    ).where((slot) => slot.scheduledFor.isAfter(now)).toList(growable: false);

    if (todaysSlots.isNotEmpty) return todaysSlots;

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return _slotsForDate(tomorrow);
  }

  List<ScheduledNotificationRecord> _slotsForDate(DateTime date) {
    return _dailySlots
        .map(
          (slot) => ScheduledNotificationRecord(
            id: slot.id,
            templateId: '',
            scheduledFor: slot.scheduledFor(date),
            payloadRoute: '',
          ),
        )
        .toList(growable: false);
  }

  Future<_ScheduleCleanupResult> _cleanupForTargetSlots({
    required NotificationHistory history,
    required List<PendingNotificationRequest> pendingRequests,
    required List<ScheduledNotificationRecord> targetSlots,
    required DateTime now,
  }) async {
    final targetById = <int, ScheduledNotificationRecord>{
      for (final slot in targetSlots) slot.id: slot,
    };
    final storedById = <int, ScheduledNotificationRecord>{
      for (final record in history.scheduledNotifications) record.id: record,
    };

    final idsToCancel = <int>{};
    final keptRecords = <ScheduledNotificationRecord>[];

    for (final request in pendingRequests) {
      if (!_ownedScheduledNotificationIds.contains(request.id)) continue;

      final targetSlot = targetById[request.id];
      if (targetSlot == null) {
        idsToCancel.add(request.id);
        continue;
      }

      final hasPayload = request.payload?.trim().isNotEmpty == true;
      final payloadRecord = _recordFromPendingPayload(
        id: request.id,
        payload: request.payload,
      );
      final record =
          payloadRecord ?? (!hasPayload ? storedById[request.id] : null);

      if (record == null || !_recordMatchesSlot(record, targetSlot, now)) {
        idsToCancel.add(request.id);
        continue;
      }

      keptRecords.add(record);
    }

    final keptTemplateIds = <String>{};
    final hasDuplicateTemplate = keptRecords.any(
      (record) => !keptTemplateIds.add(record.templateId),
    );

    if (hasDuplicateTemplate) {
      idsToCancel.addAll(keptRecords.map((record) => record.id));
      keptRecords.clear();
    }

    for (final id in idsToCancel) {
      await _plugin.cancel(id: id);
    }

    keptRecords.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    final cleanedHistory = history.copyWith(
      scheduledNotifications: keptRecords,
    );
    await saveNotificationHistory(cleanedHistory);

    if (idsToCancel.isNotEmpty) {
      _log(
        'Cancelled outdated local reminder id(s): ${idsToCancel.join(', ')}',
      );
    }

    return _ScheduleCleanupResult(
      history: cleanedHistory,
      keptRecords: keptRecords,
    );
  }

  bool _recordMatchesSlot(
    ScheduledNotificationRecord record,
    ScheduledNotificationRecord slot,
    DateTime now,
  ) {
    final template = _templateById(record.templateId);
    return record.id == slot.id &&
        record.scheduledFor.isAfter(now) &&
        _isSameScheduledMinute(record.scheduledFor, slot.scheduledFor) &&
        template?.isActive == true &&
        validPayloadRoutes.contains(record.payloadRoute);
  }

  bool _isSameScheduledMinute(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day &&
        left.hour == right.hour &&
        left.minute == right.minute;
  }

  Future<void> _scheduleRecord(
    ScheduledNotificationRecord record,
    NotificationTemplate template,
  ) async {
    await _plugin.zonedSchedule(
      id: record.id,
      title: template.title,
      body: template.body,
      scheduledDate: tz.TZDateTime.from(record.scheduledFor, tz.local),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _encodePayload(
        template: template,
        scheduledFor: record.scheduledFor,
      ),
    );
  }

  Future<List<PendingNotificationRequest>>
  _pendingNotificationRequests() async {
    try {
      final requests = await _plugin.pendingNotificationRequests();
      final managedCount = requests
          .where(
            (request) => _ownedScheduledNotificationIds.contains(request.id),
          )
          .length;
      _log(
        'Inspected ${requests.length} pending notification(s); '
        '$managedCount are daily puzzle reminders.',
      );
      return requests;
    } on UnimplementedError catch (error, stackTrace) {
      _log(
        'Pending notification inspection is not implemented on this platform.',
        error: error,
        stackTrace: stackTrace,
      );
      return const <PendingNotificationRequest>[];
    }
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

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } on FormatException catch (error, stackTrace) {
      _log(
        'Invalid notification payload JSON.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  ScheduledNotificationRecord? _recordFromPendingPayload({
    required int id,
    required String? payload,
  }) {
    final decoded = _decodePayload(payload);
    if (decoded == null) return null;

    final templateId = decoded['templateId'];
    final route = decoded['route'];
    final rawScheduledFor = decoded['scheduledFor'];

    if (templateId is! String ||
        route is! String ||
        rawScheduledFor is! String) {
      return null;
    }

    try {
      return ScheduledNotificationRecord(
        id: id,
        templateId: templateId,
        scheduledFor: DateTime.parse(rawScheduledFor).toLocal(),
        payloadRoute: route,
      );
    } on FormatException catch (error, stackTrace) {
      _log(
        'Invalid scheduledFor in notification payload.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  NotificationTemplate? _templateById(String templateId) {
    for (final template in mockNotifications) {
      if (template.id == templateId) return template;
    }
    return null;
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
