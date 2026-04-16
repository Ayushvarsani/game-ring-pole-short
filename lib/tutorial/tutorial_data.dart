import 'tutorial_step.dart';

const Map<int, List<TutorialStep>> tutorialStepsByLevel =
    <int, List<TutorialStep>>{
      1: <TutorialStep>[
        TutorialStep(
          id: 'level1_tap_source_0',
          level: 1,
          message: 'Tap this bottle.',
          actionType: TutorialActionType.tapSourceBottle,
          allowedSourceBottleIndex: 0,
        ),
        TutorialStep(
          id: 'level1_pour_to_3',
          level: 1,
          message: 'Now pour into this bottle.',
          actionType: TutorialActionType.performPour,
          allowedSourceBottleIndex: 0,
          allowedTargetBottleIndex: 3,
        ),
        TutorialStep(
          id: 'level1_tap_source_1',
          level: 1,
          message: 'Nice. Tap this bottle next.',
          actionType: TutorialActionType.tapSourceBottle,
          allowedSourceBottleIndex: 1,
        ),
        TutorialStep(
          id: 'level1_pour_to_4',
          level: 1,
          message: 'Pour into the empty bottle.',
          actionType: TutorialActionType.performPour,
          allowedSourceBottleIndex: 1,
          allowedTargetBottleIndex: 4,
        ),
        TutorialStep(
          id: 'level1_finish',
          level: 1,
          message: 'Good start. Finish by matching the top colors.',
          actionType: TutorialActionType.completeLevel,
          blockOtherInput: false,
        ),
      ],
      2: <TutorialStep>[
        TutorialStep(
          id: 'level2_tap_source_0',
          level: 2,
          message: 'Tap this bottle first.',
          actionType: TutorialActionType.tapSourceBottle,
          allowedSourceBottleIndex: 0,
        ),
        TutorialStep(
          id: 'level2_pour_to_3',
          level: 2,
          message: 'Pour into this empty bottle.',
          actionType: TutorialActionType.performPour,
          allowedSourceBottleIndex: 0,
          allowedTargetBottleIndex: 3,
        ),
        TutorialStep(
          id: 'level2_tap_source_1',
          level: 2,
          message: 'Good. Tap this bottle now.',
          actionType: TutorialActionType.tapSourceBottle,
          allowedSourceBottleIndex: 1,
        ),
        TutorialStep(
          id: 'level2_pour_to_4',
          level: 2,
          message: 'Pour into this empty bottle.',
          actionType: TutorialActionType.performPour,
          allowedSourceBottleIndex: 1,
          allowedTargetBottleIndex: 4,
        ),
        TutorialStep(
          id: 'level2_finish',
          level: 2,
          message: 'You are ready. Finish the level normally.',
          actionType: TutorialActionType.completeLevel,
          blockOtherInput: false,
        ),
      ],
    };

List<TutorialStep> tutorialStepsForLevel(int level) {
  return tutorialStepsByLevel[level] ?? const <TutorialStep>[];
}
