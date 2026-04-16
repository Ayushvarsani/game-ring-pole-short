class NotificationTemplate {
  const NotificationTemplate({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.payloadRoute,
    this.isActive = true,
  });

  final String id;
  final String category;
  final String title;
  final String body;
  final String payloadRoute;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'title': title,
      'body': body,
      'payloadRoute': payloadRoute,
      'isActive': isActive,
    };
  }

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) {
    return NotificationTemplate(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      payloadRoute: json['payloadRoute'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class NotificationCategories {
  const NotificationCategories._();

  static const comeback = 'comeback';
  static const levelProgress = 'level_progress';
  static const hintReminder = 'hint_reminder';
  static const coinReward = 'coin_reward';
  static const shopReminder = 'shop_reminder';
  static const themeUnlock = 'theme_unlock';
  static const bottleStyle = 'bottle_style';
  static const fillStyle = 'fill_style';
  static const challenge = 'challenge';
  static const dailyPuzzle = 'daily_puzzle';
  static const undoBoost = 'undo_boost';
  static const extraMoves = 'extra_moves';

  static const all = <String>{
    comeback,
    levelProgress,
    hintReminder,
    coinReward,
    shopReminder,
    themeUnlock,
    bottleStyle,
    fillStyle,
    challenge,
    dailyPuzzle,
    undoBoost,
    extraMoves,
  };
}
