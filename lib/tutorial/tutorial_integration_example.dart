import 'dart:async';

import 'tutorial_controller.dart';

class TutorialIntegrationExample {
  const TutorialIntegrationExample(this.controller);

  final TutorialController controller;

  bool onBottleTap({
    required int tappedBottleIndex,
    required int selectedBottleIndex,
    required void Function(int bottleIndex) applyBottleTap,
  }) {
    if (selectedBottleIndex == -1) {
      final allowed = controller.validateSourceTap(tappedBottleIndex);
      if (!allowed) return false;

      applyBottleTap(tappedBottleIndex);
      unawaited(controller.recordSourceTapSucceeded(tappedBottleIndex));
      return true;
    }

    final allowed = controller.validatePourAttempt(
      selectedBottleIndex,
      tappedBottleIndex,
    );
    if (!allowed) return false;

    applyBottleTap(tappedBottleIndex);
    unawaited(
      controller.recordPourSucceeded(
        sourceBottleIndex: selectedBottleIndex,
        targetBottleIndex: tappedBottleIndex,
      ),
    );
    return true;
  }
}
