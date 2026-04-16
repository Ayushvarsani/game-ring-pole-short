import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class ScheduledNotificationRecord {
  const ScheduledNotificationRecord({
    required this.id,
    required this.templateId,
    required this.scheduledFor,
    required this.payloadRoute,
  });

  final int id;
  final String templateId;
  final DateTime scheduledFor;
  final String payloadRoute;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'templateId': templateId,
      'scheduledFor': scheduledFor.toUtc().toIso8601String(),
      'payloadRoute': payloadRoute,
    };
  }

  factory ScheduledNotificationRecord.fromJson(Map<String, dynamic> json) {
    final scheduledFor = _readDateTime(json['scheduledFor']);
    if (scheduledFor == null) {
      throw const FormatException('Missing scheduledFor');
    }

    return ScheduledNotificationRecord(
      id: json['id'] as int,
      templateId: json['templateId'] as String,
      scheduledFor: scheduledFor,
      payloadRoute: json['payloadRoute'] as String,
    );
  }

  static DateTime? _readDateTime(Object? rawValue) {
    if (rawValue is! String || rawValue.isEmpty) return null;
    return DateTime.parse(rawValue).toLocal();
  }
}

class NotificationHistory {
  const NotificationHistory({
    this.lastScheduledAt,
    this.lastNotificationTemplateId,
    this.recentNotificationIds = const <String>[],
    this.scheduledNotifications = const <ScheduledNotificationRecord>[],
  });

  final DateTime? lastScheduledAt;
  final String? lastNotificationTemplateId;
  final List<String> recentNotificationIds;
  final List<ScheduledNotificationRecord> scheduledNotifications;

  NotificationHistory copyWith({
    DateTime? lastScheduledAt,
    bool clearLastScheduledAt = false,
    String? lastNotificationTemplateId,
    bool clearLastNotificationTemplateId = false,
    List<String>? recentNotificationIds,
    List<ScheduledNotificationRecord>? scheduledNotifications,
  }) {
    return NotificationHistory(
      lastScheduledAt: clearLastScheduledAt
          ? null
          : lastScheduledAt ?? this.lastScheduledAt,
      lastNotificationTemplateId: clearLastNotificationTemplateId
          ? null
          : lastNotificationTemplateId ?? this.lastNotificationTemplateId,
      recentNotificationIds:
          recentNotificationIds ?? this.recentNotificationIds,
      scheduledNotifications:
          scheduledNotifications ?? this.scheduledNotifications,
    );
  }
}

class NotificationStorage {
  NotificationStorage({SharedPreferences? preferences})
    : _preferences = preferences;

  static const recentHistoryLimit = 5;

  static const _lastScheduledAtKey = 'notificationLastScheduledAt';
  static const _lastNotificationTemplateIdKey = 'lastNotificationTemplateId';
  static const _recentNotificationIdsKey = 'recentNotificationIds';
  static const _scheduledNotificationsKey = 'scheduledNotifications';

  static const _legacyLastNotificationAtKey = 'lastNotificationAt';
  static const _legacyPendingNotificationTemplateIdKey =
      'pendingNotificationTemplateId';
  static const _legacyPendingNotificationScheduledForKey =
      'pendingNotificationScheduledFor';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<NotificationHistory> loadNotificationHistory() async {
    final prefs = await _prefs;

    final recentIds =
        prefs.getStringList(_recentNotificationIdsKey) ?? const <String>[];
    final scheduledRecords = prefs
        .getStringList(_scheduledNotificationsKey)
        ?.map(_decodeScheduledNotificationRecord)
        .whereType<ScheduledNotificationRecord>()
        .toList();

    return NotificationHistory(
      lastScheduledAt:
          _readDateTime(prefs, _lastScheduledAtKey) ??
          _readDateTime(prefs, _legacyLastNotificationAtKey),
      lastNotificationTemplateId: prefs.getString(
        _lastNotificationTemplateIdKey,
      ),
      recentNotificationIds: _normalizeRecentIds(recentIds),
      scheduledNotifications: _normalizeScheduledRecords(
        scheduledRecords ?? const <ScheduledNotificationRecord>[],
      ),
    );
  }

  Future<void> saveNotificationHistory(NotificationHistory history) async {
    final prefs = await _prefs;

    await _writeNullableString(
      prefs,
      _lastScheduledAtKey,
      history.lastScheduledAt?.toUtc().toIso8601String(),
    );
    await _writeNullableString(
      prefs,
      _lastNotificationTemplateIdKey,
      history.lastNotificationTemplateId,
    );
    await prefs.setStringList(
      _recentNotificationIdsKey,
      _normalizeRecentIds(history.recentNotificationIds),
    );
    await prefs.setStringList(
      _scheduledNotificationsKey,
      _normalizeScheduledRecords(
        history.scheduledNotifications,
      ).map((record) => jsonEncode(record.toJson())).toList(),
    );

    await prefs.remove(_legacyPendingNotificationTemplateIdKey);
    await prefs.remove(_legacyPendingNotificationScheduledForKey);
  }

  Future<void> saveScheduledNotifications(
    List<ScheduledNotificationRecord> records,
  ) async {
    final history = await loadNotificationHistory();
    await saveNotificationHistory(
      history.copyWith(scheduledNotifications: records),
    );
  }

  Future<void> clearScheduledNotifications() async {
    final history = await loadNotificationHistory();
    await saveNotificationHistory(
      history.copyWith(scheduledNotifications: const []),
    );
  }

  Future<void> clearAllNotificationHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_lastScheduledAtKey);
    await prefs.remove(_lastNotificationTemplateIdKey);
    await prefs.remove(_recentNotificationIdsKey);
    await prefs.remove(_scheduledNotificationsKey);
    await prefs.remove(_legacyLastNotificationAtKey);
    await prefs.remove(_legacyPendingNotificationTemplateIdKey);
    await prefs.remove(_legacyPendingNotificationScheduledForKey);
  }

  static List<String> appendRecentId(
    List<String> existingIds,
    String templateId,
  ) {
    return appendRecentIds(existingIds, <String>[templateId]);
  }

  static List<String> appendRecentIds(
    List<String> existingIds,
    Iterable<String> templateIds,
  ) {
    final next = <String>[..._normalizeRecentIds(existingIds)];

    for (final templateId in templateIds) {
      final normalizedId = templateId.trim();
      if (normalizedId.isEmpty) continue;

      next.remove(normalizedId);
      next.insert(0, normalizedId);

      if (next.length > recentHistoryLimit) {
        next.removeRange(recentHistoryLimit, next.length);
      }
    }

    return next;
  }

  static ScheduledNotificationRecord? _decodeScheduledNotificationRecord(
    String rawValue,
  ) {
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) return null;
      return ScheduledNotificationRecord.fromJson(decoded);
    } on Object catch (error, stackTrace) {
      developer.log(
        'Invalid scheduled notification record in SharedPreferences.',
        name: 'NotificationStorage',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static DateTime? _readDateTime(SharedPreferences prefs, String key) {
    final rawValue = prefs.getString(key);
    if (rawValue == null || rawValue.isEmpty) return null;

    try {
      return DateTime.parse(rawValue).toLocal();
    } on FormatException catch (error, stackTrace) {
      developer.log(
        'Invalid notification date in SharedPreferences for $key',
        name: 'NotificationStorage',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static Future<void> _writeNullableString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) {
    if (value == null || value.isEmpty) {
      return prefs.remove(key);
    }
    return prefs.setString(key, value);
  }

  static List<String> _normalizeRecentIds(List<String> ids) {
    final normalized = <String>[];
    for (final id in ids) {
      final normalizedId = id.trim();
      if (normalizedId.isEmpty || normalized.contains(normalizedId)) {
        continue;
      }
      normalized.add(normalizedId);
      if (normalized.length == recentHistoryLimit) break;
    }
    return normalized;
  }

  static List<ScheduledNotificationRecord> _normalizeScheduledRecords(
    List<ScheduledNotificationRecord> records,
  ) {
    final byId = <int, ScheduledNotificationRecord>{};

    for (final record in records) {
      if (record.templateId.trim().isEmpty ||
          record.payloadRoute.trim().isEmpty) {
        continue;
      }
      byId[record.id] = record;
    }

    final normalized = byId.values.toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return normalized;
  }
}
