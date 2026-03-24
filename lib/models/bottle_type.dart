/// Defines the different bottle shapes available in the shop.
enum BottleType {
  classic('Classic', '🧪', 0),
  round('Round Flask', '⚗️', 50),
  square('Square Jar', '🫙', 100),
  tall('Tall Slim', '🧴', 150),
  wide('Wide Bowl', '🍶', 200);

  final String displayName;
  final String emoji;
  final int coinPrice;

  const BottleType(this.displayName, this.emoji, this.coinPrice);
}
