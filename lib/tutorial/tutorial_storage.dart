import 'package:shared_preferences/shared_preferences.dart';

class TutorialProgress {
  const TutorialProgress({
    this.level1Completed = false,
    this.level2Completed = false,
    this.skipped = false,
    this.completed = false,
  });

  final bool level1Completed;
  final bool level2Completed;
  final bool skipped;
  final bool completed;

  bool isLevelComplete(int level) {
    return switch (level) {
      1 => level1Completed,
      2 => level2Completed,
      _ => true,
    };
  }
}

class TutorialStorage {
  TutorialStorage({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _tutorialSkippedKey = 'tutorialSkipped';
  static const _tutorialLevel1CompletedKey = 'tutorialLevel1Completed';
  static const _tutorialLevel2CompletedKey = 'tutorialLevel2Completed';
  static const _tutorialCompletedKey = 'tutorialCompleted';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<TutorialProgress> loadProgress() async {
    final prefs = await _prefs;
    return TutorialProgress(
      level1Completed: prefs.getBool(_tutorialLevel1CompletedKey) ?? false,
      level2Completed: prefs.getBool(_tutorialLevel2CompletedKey) ?? false,
      skipped: prefs.getBool(_tutorialSkippedKey) ?? false,
      completed: prefs.getBool(_tutorialCompletedKey) ?? false,
    );
  }

  Future<void> markLevelComplete(int level) async {
    final prefs = await _prefs;
    switch (level) {
      case 1:
        await prefs.setBool(_tutorialLevel1CompletedKey, true);
      case 2:
        await prefs.setBool(_tutorialLevel1CompletedKey, true);
        await prefs.setBool(_tutorialLevel2CompletedKey, true);
        await prefs.setBool(_tutorialCompletedKey, true);
      default:
        break;
    }
  }

  Future<void> setTutorialSkipped() async {
    final prefs = await _prefs;
    await prefs.setBool(_tutorialSkippedKey, true);
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  Future<void> resetTutorial() async {
    final prefs = await _prefs;
    await prefs.remove(_tutorialSkippedKey);
    await prefs.remove(_tutorialLevel1CompletedKey);
    await prefs.remove(_tutorialLevel2CompletedKey);
    await prefs.remove(_tutorialCompletedKey);
  }
}
