/// Defines the different bottle shapes available in the shop.
enum BottleType {
  classic('Classic', '\u{1F9EA}', 0),
  round('Round Flask', '\u2697\uFE0F', 250),
  square('Square Jar', '\u{1FAD9}', 500),
  tall('Tall Slim', '\u{1F9F4}', 750),
  wide('Wide Bowl', '\u{1F376}', 1000);

  final String displayName;
  final String emoji;
  final int coinPrice;

  const BottleType(this.displayName, this.emoji, this.coinPrice);
}
