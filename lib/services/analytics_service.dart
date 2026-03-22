/// Wrapper service for Firebase Analytics.
///
/// Logs custom game events for tracking user behavior and engagement.
/// Currently a stub implementation - when Firebase is configured,
/// uncomment the firebase_analytics import and the real implementation.
///
/// To enable Firebase Analytics:
/// 1. Add firebase_core and firebase_analytics to pubspec.yaml
/// 2. Run `flutterfire configure`
/// 3. Uncomment Firebase.initializeApp() in main.dart
/// 4. Replace the stub methods below with real analytics calls
class FirebaseAnalyticsService {
  bool _isInitialized = false;

  /// Singleton pattern for global access.
  static final FirebaseAnalyticsService _instance =
      FirebaseAnalyticsService._internal();

  factory FirebaseAnalyticsService() => _instance;

  FirebaseAnalyticsService._internal();

  /// Initialize the analytics service.
  /// Should be called after Firebase.initializeApp().
  void initialize() {
    _isInitialized = true;
    // When Firebase is configured:
    // _analytics = FirebaseAnalytics.instance;
  }

  /// Log when a level is started.
  Future<void> logLevelStarted({
    required int level,
    required int numColors,
  }) async {
    if (!_isInitialized) return;
    _log('level_started', {'level': level, 'num_colors': numColors});
  }

  /// Log when a level is completed.
  Future<void> logLevelCompleted({
    required int level,
    required int moves,
    required int undosUsed,
    required int durationSeconds,
  }) async {
    if (!_isInitialized) return;
    _log('level_completed', {
      'level': level,
      'moves': moves,
      'undos_used': undosUsed,
      'duration_seconds': durationSeconds,
    });
  }

  /// Log when a pour action is performed.
  Future<void> logBottlePoured({
    required int sourceBottle,
    required int destBottle,
    required int colorCount,
  }) async {
    if (!_isInitialized) return;
    _log('bottle_poured', {
      'source_bottle': sourceBottle,
      'dest_bottle': destBottle,
      'color_count': colorCount,
    });
  }

  /// Log when undo is used.
  Future<void> logUndoUsed({
    required int level,
    required int moveNumber,
  }) async {
    if (!_isInitialized) return;
    _log('undo_used', {'level': level, 'move_number': moveNumber});
  }

  /// Stub logging - replace with real Firebase calls when configured.
  void _log(String name, Map<String, Object> params) {
    // When Firebase is configured, replace with:
    // _analytics.logEvent(name: name, parameters: params);

    // Debug print for development
    // print('Analytics: $name -> $params');
  }
}
