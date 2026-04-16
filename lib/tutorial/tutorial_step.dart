enum TutorialActionType { tapSourceBottle, performPour, completeLevel }

class TutorialStep {
  const TutorialStep({
    required this.id,
    required this.level,
    required this.message,
    required this.actionType,
    this.allowedSourceBottleIndex,
    this.allowedTargetBottleIndex,
    this.blockOtherInput = true,
  });

  final String id;
  final int level;
  final String message;
  final TutorialActionType actionType;
  final int? allowedSourceBottleIndex;
  final int? allowedTargetBottleIndex;
  final bool blockOtherInput;
}
