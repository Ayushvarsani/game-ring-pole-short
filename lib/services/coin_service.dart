import 'package:shared_preferences/shared_preferences.dart';

/// Persists coin balance and exposes level reward calculation.
class CoinService {
  CoinService._();

  static const String prefsKeyCoins = 'coin_balance';

  /// Coins earned for completing [level] (1-based).
  static int rewardForLevel(int level) => 20 + level.clamp(1, 200);

  static Future<int> getCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefsKeyCoins) ?? 0;
  }

  static Future<int> addCoins(int amount) async {
    if (amount <= 0) return getCoins();
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(prefsKeyCoins) ?? 0) + amount;
    await prefs.setInt(prefsKeyCoins, next);
    return next;
  }

  static Future<void> setCoins(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKeyCoins, value.clamp(0, 999999));
  }
}
