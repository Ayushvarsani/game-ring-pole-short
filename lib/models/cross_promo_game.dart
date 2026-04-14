class CrossPromoGame {
  final String id;
  final String name;
  final String iconUrl;
  final String playStoreUrl;

  const CrossPromoGame({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.playStoreUrl,
  });
}

// Predefined list of games. Add actual games here.
const List<CrossPromoGame> predefinedCrossPromoGames = [
  CrossPromoGame(
    id: 'flip_fun_blast',
    name: 'Flip Fun Blast',
    iconUrl: 'assets/images/flip_fun_blast.png',
    playStoreUrl: 'https://play.google.com/store/apps/details?id=com.flipfunblast&pcampaignid=web_share',
  ),
];
