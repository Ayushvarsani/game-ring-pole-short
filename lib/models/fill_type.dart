/// Defines the different fill types (contents) available in the shop.
enum FillType {
  liquid('Liquid', '💧', 0),
  balls('Balls', '🎾', 50),
  blocks('Blocks', '🧊', 100),
  stars('Stars', '⭐', 150),
  diamonds('Diamonds', '💎', 200);

  final String displayName;
  final String emoji;
  final int coinPrice;

  const FillType(this.displayName, this.emoji, this.coinPrice);
}
