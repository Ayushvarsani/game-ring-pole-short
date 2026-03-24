import 'package:shared_preferences/shared_preferences.dart';

/// Persists which level the player should start when tapping Play.
class LevelProgressService {
  LevelProgressService._();

  static const _keyNextLevel = 'next_level_to_play';
  static const int maxLevel = 200;

  static Future<int> getNextLevelToPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_keyNextLevel);
    if (raw == null) return 1;
    return raw.clamp(1, maxLevel);
  }

  /// Call when the player completes a level (won). Unlocks the next level for Play.
  static Future<void> saveAfterLevelCompleted(int completedLevel) async {
    final next = (completedLevel + 1).clamp(1, maxLevel);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNextLevel, next);
  }
}
