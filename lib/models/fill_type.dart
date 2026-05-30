/// Defines the different fill types (contents) available in the shop.
enum FillType {
  liquid('Liquid', '\u{1F4A7}', 0),
  balls('Balls', '\u{1F3BE}', 250),
  blocks('Blocks', '\u{1F9CA}', 500),
  stars('Stars', '\u2B50', 750),
  diamonds('Diamonds', '\u{1F48E}', 1000);

  final String displayName;
  final String emoji;
  final int coinPrice;

  const FillType(this.displayName, this.emoji, this.coinPrice);
}
