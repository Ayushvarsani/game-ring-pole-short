import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistory {
  const NotificationHistory({
    this.lastNotificationAt,
    this.lastNotificationTemplateId,
    this.recentNotificationIds = const <String>[],
    this.pendingNotificationTemplateId,
    this.pendingNotificationScheduledFor,
  });

  final DateTime? lastNotificationAt;
  final String? lastNotificationTemplateId;
  final List<String> recentNotificationIds;
  final String? pendingNotificationTemplateId;
  final DateTime? pendingNotificationScheduledFor;

  NotificationHistory copyWith({
    DateTime? lastNotificationAt,
    bool clearLastNotificationAt = false,
    String? lastNotificationTemplateId,
    bool clearLastNotificationTemplateId = false,
    List<String>? recentNotificationIds,
    String? pendingNotificationTemplateId,
    bool clearPendingNotificationTemplateId = false,
    DateTime? pendingNotificationScheduledFor,
    bool clearPendingNotificationScheduledFor = false,
  }) {
    return NotificationHistory(
      lastNotificationAt: clearLastNotificationAt
          ? null
          : lastNotificationAt ?? this.lastNotificationAt,
      lastNotificationTemplateId: clearLastNotificationTemplateId
          ? null
          : lastNotificationTemplateId ?? this.lastNotificationTemplateId,
      recentNotificationIds:
          recentNotificationIds ?? this.recentNotificationIds,
      pendingNotificationTemplateId: clearPendingNotificationTemplateId
          ? null
          : pendingNotificationTemplateId ?? this.pendingNotificationTemplateId,
      pendingNotificationScheduledFor: clearPendingNotificationScheduledFor
          ? null
          : pendingNotificationScheduledFor ??
                this.pendingNotificationScheduledFor,
    );
  }
}

class NotificationStorage {
  NotificationStorage({SharedPreferences? preferences})
    : _preferences = preferences;

  static const recentHistoryLimit = 5;

  static const _lastNotificationAtKey = 'lastNotificationAt';
  static const _lastNotificationTemplateIdKey = 'lastNotificationTemplateId';
  static const _recentNotificationIdsKey = 'recentNotificationIds';
  static const _pendingNotificationTemplateIdKey =
      'pendingNotificationTemplateId';
  static const _pendingNotificationScheduledForKey =
      'pendingNotificationScheduledFor';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<NotificationHistory> loadNotificationHistory() async {
    final prefs = await _prefs;

    final recentIds =
        prefs.getStringList(_recentNotificationIdsKey) ?? const <String>[];

    return NotificationHistory(
      lastNotificationAt: _readDateTime(prefs, _lastNotificationAtKey),
      lastNotificationTemplateId: prefs.getString(
        _lastNotificationTemplateIdKey,
      ),
      recentNotificationIds: _normalizeRecentIds(recentIds),
      pendingNotificationTemplateId: prefs.getString(
        _pendingNotificationTemplateIdKey,
      ),
      pendingNotificationScheduledFor: _readDateTime(
        prefs,
        _pendingNotificationScheduledForKey,
      ),
    );
  }

  Future<void> saveNotificationHistory(NotificationHistory history) async {
    final prefs = await _prefs;

    await _writeNullableString(
      prefs,
      _lastNotificationAtKey,
      history.lastNotificationAt?.toUtc().toIso8601String(),
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
    await _writeNullableString(
      prefs,
      _pendingNotificationTemplateIdKey,
      history.pendingNotificationTemplateId,
    );
    await _writeNullableString(
      prefs,
      _pendingNotificationScheduledForKey,
      history.pendingNotificationScheduledFor?.toUtc().toIso8601String(),
    );
  }

  Future<void> clearPendingNotification() async {
    final history = await loadNotificationHistory();
    await saveNotificationHistory(
      history.copyWith(
        clearPendingNotificationTemplateId: true,
        clearPendingNotificationScheduledFor: true,
      ),
    );
  }

  Future<void> clearAllNotificationHistory() async {
    final prefs = await _prefs;
    await prefs.remove(_lastNotificationAtKey);
    await prefs.remove(_lastNotificationTemplateIdKey);
    await prefs.remove(_recentNotificationIdsKey);
    await prefs.remove(_pendingNotificationTemplateIdKey);
    await prefs.remove(_pendingNotificationScheduledForKey);
  }

  static List<String> appendRecentId(
    List<String> existingIds,
    String templateId,
  ) {
    final next = <String>[templateId];
    for (final id in existingIds) {
      if (id != templateId && id.trim().isNotEmpty) {
        next.add(id);
      }
      if (next.length == recentHistoryLimit) break;
    }
    return next;
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
      if (id.trim().isEmpty || normalized.contains(id)) continue;
      normalized.add(id);
      if (normalized.length == recentHistoryLimit) break;
    }
    return normalized;
  }
}
