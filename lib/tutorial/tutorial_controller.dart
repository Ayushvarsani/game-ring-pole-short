import 'package:flutter/foundation.dart';

import 'tutorial_data.dart';
import 'tutorial_step.dart';
import 'tutorial_storage.dart';

class TutorialService {
  TutorialService({TutorialStorage? storage})
    : _storage = storage ?? TutorialStorage();

  final TutorialStorage _storage;

  Future<TutorialProgress> loadProgress() {
    return _storage.loadProgress();
  }

  Future<bool> shouldShowLevel(int level) async {
    final progress = await _storage.loadProgress();
    return !progress.skipped &&
        !progress.completed &&
        !progress.isLevelComplete(level) &&
        tutorialStepsForLevel(level).isNotEmpty;
  }

  Future<void> completeLevel(int level) {
    return _storage.markLevelComplete(level);
  }

  Future<void> skipAllTutorials() {
    return _storage.setTutorialSkipped();
  }

  Future<void> resetTutorial() {
    return _storage.resetTutorial();
  }
}

class TutorialController extends ChangeNotifier {
  TutorialController({TutorialService? service})
    : _service = service ?? TutorialService();

  final TutorialService _service;

  List<TutorialStep> _steps = const <TutorialStep>[];
  int _currentIndex = 0;
  int? _activeLevel;
  int? _lockedSourceIndex;
  int _startRequestId = 0;
  bool _isActive = false;
  bool _isLoading = false;
  bool _isDisposed = false;
  String? _helperMessage;

  bool get isActive => _isActive;
  bool get isLoading => _isLoading;
  int? get activeLevel => _activeLevel;
  int get currentIndex => _currentIndex;
  int get totalSteps => _steps.length;
  String? get helperMessage => _helperMessage;
  int? get lockedSourceIndex => _lockedSourceIndex;

  TutorialStep? get currentStep {
    if (!_isActive || _steps.isEmpty) return null;
    return _steps[_currentIndex];
  }

  bool get blocksOtherInput {
    return currentStep?.blockOtherInput == true;
  }

  Future<void> startForLevel(int level) {
    return startLevelTutorial(level, tutorialStepsForLevel(level));
  }

  Future<void> startLevelTutorial(int level, List<TutorialStep> steps) async {
    final requestId = ++_startRequestId;
    final nextSteps = List<TutorialStep>.unmodifiable(steps);

    _steps = nextSteps;
    _currentIndex = 0;
    _lockedSourceIndex = null;
    _activeLevel = level;
    _isActive = nextSteps.isNotEmpty;
    _isLoading = true;
    _helperMessage = null;
    _notify();

    final progress = await _service.loadProgress();
    if (_isDisposed || requestId != _startRequestId) return;

    final shouldShow =
        !progress.skipped &&
        !progress.completed &&
        !progress.isLevelComplete(level) &&
        nextSteps.isNotEmpty;

    if (!shouldShow) {
      _clearActiveState();
      _isLoading = false;
      _notify();
      return;
    }

    _steps = nextSteps;
    _currentIndex = 0;
    _lockedSourceIndex = null;
    _activeLevel = level;
    _isActive = _steps.isNotEmpty;
    _helperMessage = null;
    _isLoading = false;
    _notify();
  }

  bool validateSourceTap(int bottleIndex) {
    final step = currentStep;
    if (step == null || !step.blockOtherInput) return true;

    final allowed =
        step.actionType == TutorialActionType.tapSourceBottle &&
        step.allowedSourceBottleIndex == bottleIndex;
    if (!allowed) {
      _showHelper('Tap the highlighted bottle first');
    }
    return allowed;
  }

  bool validatePourAttempt(int sourceBottleIndex, int targetBottleIndex) {
    final step = currentStep;
    if (step == null || !step.blockOtherInput) return true;

    final expectedSource = _lockedSourceIndex ?? step.allowedSourceBottleIndex;
    final allowed =
        step.actionType == TutorialActionType.performPour &&
        expectedSource == sourceBottleIndex &&
        step.allowedTargetBottleIndex == targetBottleIndex;
    if (!allowed) {
      _showHelper('Now pour into the highlighted bottle');
    }
    return allowed;
  }

  bool highlightsBottle(int bottleIndex) {
    final step = currentStep;
    if (step == null) return false;

    return step.allowedSourceBottleIndex == bottleIndex ||
        step.allowedTargetBottleIndex == bottleIndex;
  }

  bool dimsBottle(int bottleIndex) {
    final step = currentStep;
    if (step == null || !step.blockOtherInput) return false;
    if (step.actionType == TutorialActionType.completeLevel) return false;
    return !highlightsBottle(bottleIndex);
  }

  Future<void> recordSourceTapSucceeded(int bottleIndex) async {
    final step = currentStep;
    if (step == null) return;
    if (step.actionType == TutorialActionType.tapSourceBottle &&
        step.allowedSourceBottleIndex == bottleIndex) {
      _lockedSourceIndex = bottleIndex;
      await nextStep();
    }
  }

  Future<void> recordPourSucceeded({
    required int sourceBottleIndex,
    required int targetBottleIndex,
  }) async {
    final step = currentStep;
    if (step == null) return;
    if (step.actionType == TutorialActionType.performPour &&
        (_lockedSourceIndex ?? step.allowedSourceBottleIndex) ==
            sourceBottleIndex &&
        step.allowedTargetBottleIndex == targetBottleIndex) {
      _lockedSourceIndex = null;
      await nextStep();
    }
  }

  Future<void> recordLevelCompleted() async {
    if (currentStep?.actionType == TutorialActionType.completeLevel) {
      await finish();
    }
  }

  Future<void> skip() async {
    return skipTutorial();
  }

  Future<void> skipTutorial() async {
    if (!_isActive && !_isLoading) return;

    _startRequestId += 1;
    await _service.skipAllTutorials();
    if (_isDisposed) return;
    _clearActiveState();
    _notify();
  }

  Future<void> finish() async {
    _startRequestId += 1;
    final level = _activeLevel;
    if (level != null) {
      await _service.completeLevel(level);
    }
    if (_isDisposed) return;

    _clearActiveState();
    _notify();
  }

  Future<void> resetTutorial() async {
    _startRequestId += 1;
    await _service.resetTutorial();
    if (_isDisposed) return;
    _clearActiveState();
    _notify();
  }

  Future<void> nextStep() async {
    if (!_isActive || _steps.isEmpty) return;

    _helperMessage = null;
    if (_currentIndex < _steps.length - 1) {
      _currentIndex += 1;
      _notify();
      return;
    }

    await finish();
  }

  void _showHelper(String message) {
    _helperMessage = message;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _clearActiveState() {
    _steps = const <TutorialStep>[];
    _currentIndex = 0;
    _lockedSourceIndex = null;
    _activeLevel = null;
    _isActive = false;
    _isLoading = false;
    _helperMessage = null;
  }

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
