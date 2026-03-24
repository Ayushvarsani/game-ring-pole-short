import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bottle_type.dart';
import '../services/coin_service.dart';
import 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  static const _bottleTypeKey = 'selectedBottleType';
  static const _unlockedKey = 'unlocked_bottle_types';

  ShopCubit() : super(ShopState.initial()) {
    _load();
  }

  BottleType? _typeByName(String name) {
    for (final t in BottleType.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final coins = await CoinService.getCoins();

    final savedNames = prefs.getStringList(_unlockedKey);
    final unlocked = <BottleType>{BottleType.classic};
    if (savedNames != null) {
      for (final n in savedNames) {
        final t = _typeByName(n);
        if (t != null) unlocked.add(t);
      }
    }

    final saved = prefs.getString(_bottleTypeKey);
    BottleType selected = BottleType.classic;
    if (saved != null) {
      final t = _typeByName(saved);
      if (t != null) selected = t;
    }

    // Migration: previously selected style counts as owned
    unlocked.add(selected);

    if (!unlocked.contains(selected)) {
      selected = BottleType.classic;
    }

    emit(ShopState(
      selectedType: selected,
      coins: coins,
      unlocked: unlocked,
    ));
  }

  Future<void> _persistSelection(BottleType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bottleTypeKey, type.name);
  }

  Future<void> _persistUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _unlockedKey,
      state.unlocked.map((e) => e.name).toList(),
    );
  }

  /// Awards coins for completing a level (persists + updates state).
  Future<void> addCoinsFromLevelReward(int level) async {
    final amount = CoinService.rewardForLevel(level);
    final newTotal = await CoinService.addCoins(amount);
    emit(state.copyWith(coins: newTotal));
  }

  /// Select a bottle if unlocked, or purchase if the player has enough coins.
  Future<void> selectOrPurchase(BottleType type) async {
    if (state.unlocked.contains(type)) {
      emit(state.copyWith(selectedType: type));
      await _persistSelection(type);
      return;
    }

    final price = type.coinPrice;
    if (price <= 0) {
      final next = {...state.unlocked, type};
      emit(state.copyWith(selectedType: type, unlocked: next));
      await _persistSelection(type);
      await _persistUnlocked();
      return;
    }

    if (state.coins < price) return;

    final newCoins = state.coins - price;
    await CoinService.setCoins(newCoins);
    final next = {...state.unlocked, type};
    emit(state.copyWith(
      selectedType: type,
      coins: newCoins,
      unlocked: next,
    ));
    await _persistSelection(type);
    await _persistUnlocked();
  }
}
