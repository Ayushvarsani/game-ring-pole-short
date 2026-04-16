import 'package:flutter_test/flutter_test.dart';
import 'package:mind_color_pour/tutorial/tutorial_controller.dart';
import 'package:mind_color_pour/tutorial/tutorial_data.dart';
import 'package:mind_color_pour/tutorial/tutorial_step.dart';
import 'package:mind_color_pour/tutorial/tutorial_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TutorialController> createController() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    return TutorialController(
      service: TutorialService(storage: TutorialStorage(preferences: prefs)),
    );
  }

  test(
    'startLevelTutorial resets current step and locked source per level',
    () async {
      final controller = await createController();
      addTearDown(controller.dispose);

      await controller.startLevelTutorial(1, tutorialStepsForLevel(1));
      await controller.recordSourceTapSucceeded(0);

      expect(controller.activeLevel, 1);
      expect(controller.currentIndex, 1);
      expect(controller.lockedSourceIndex, 0);
      expect(
        controller.currentStep?.actionType,
        TutorialActionType.performPour,
      );

      await controller.startLevelTutorial(2, tutorialStepsForLevel(2));

      expect(controller.isActive, true);
      expect(controller.activeLevel, 2);
      expect(controller.currentIndex, 0);
      expect(controller.lockedSourceIndex, isNull);
      expect(controller.currentStep?.id, 'level2_tap_source_0');
      expect(controller.highlightsBottle(0), true);
      expect(controller.highlightsBottle(3), false);
    },
  );

  test('wrong input is blocked and correct successful pour advances', () async {
    final controller = await createController();
    addTearDown(controller.dispose);

    await controller.startLevelTutorial(1, tutorialStepsForLevel(1));

    expect(controller.validateSourceTap(1), false);
    expect(controller.currentIndex, 0);
    expect(controller.helperMessage, 'Tap the highlighted bottle first');

    expect(controller.validateSourceTap(0), true);
    await controller.recordSourceTapSucceeded(0);

    expect(controller.currentStep?.actionType, TutorialActionType.performPour);
    expect(controller.highlightsBottle(0), true);
    expect(controller.highlightsBottle(3), true);

    expect(controller.validatePourAttempt(0, 4), false);
    expect(controller.currentIndex, 1);
    expect(controller.helperMessage, 'Now pour into the highlighted bottle');

    expect(controller.validatePourAttempt(0, 3), true);
    await controller.recordPourSucceeded(
      sourceBottleIndex: 0,
      targetBottleIndex: 3,
    );

    expect(controller.currentStep?.id, 'level1_tap_source_1');
    expect(controller.lockedSourceIndex, isNull);
  });
}
