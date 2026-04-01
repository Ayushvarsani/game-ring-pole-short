import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../models/theme_type.dart';
import '../services/coin_service.dart';
import 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  static const _bottleTypeKey = 'selectedBottleType';
  static const _unlockedKey = 'unlocked_bottle_types';
  static const _fillTypeKey = 'selectedFillType';
  static const _unlockedFillsKey = 'unlocked_fill_types';
  static const _themeTypeKey = 'selectedThemeType';
  static const _unlockedThemesKey = 'unlocked_theme_types';

  ShopCubit() : super(ShopState.initial()) {
    _load();
  }

  BottleType? _typeByName(String name) {
    for (final t in BottleType.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  FillType? _fillByName(String name) {
    for (final t in FillType.values) {
      if (t.name == name) return t;
    }
    return null;
  }

  ThemeType? _themeByName(String name) {
    for (final t in ThemeType.values) {
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

    final savedFillNames = prefs.getStringList(_unlockedFillsKey);
    final unlockedFills = <FillType>{FillType.liquid};
    if (savedFillNames != null) {
      for (final n in savedFillNames) {
        final t = _fillByName(n);
        if (t != null) unlockedFills.add(t);
      }
    }

    final savedThemeNames = prefs.getStringList(_unlockedThemesKey);
    final unlockedThemes = <ThemeType>{ThemeType.midnight};
    if (savedThemeNames != null) {
      for (final n in savedThemeNames) {
        final t = _themeByName(n);
        if (t != null) unlockedThemes.add(t);
      }
    }

    final saved = prefs.getString(_bottleTypeKey);
    BottleType selected = BottleType.classic;
    if (saved != null) {
      final t = _typeByName(saved);
      if (t != null) selected = t;
    }

    final savedFill = prefs.getString(_fillTypeKey);
    FillType selectedFill = FillType.liquid;
    if (savedFill != null) {
      final t = _fillByName(savedFill);
      if (t != null) selectedFill = t;
    }

    final savedTheme = prefs.getString(_themeTypeKey);
    ThemeType selectedTheme = ThemeType.midnight;
    if (savedTheme != null) {
      final t = _themeByName(savedTheme);
      if (t != null) selectedTheme = t;
    }

    unlocked.add(selected);
    if (!unlocked.contains(selected)) {
      selected = BottleType.classic;
    }

    unlockedFills.add(selectedFill);
    if (!unlockedFills.contains(selectedFill)) {
      selectedFill = FillType.liquid;
    }

    unlockedThemes.add(selectedTheme);
    if (!unlockedThemes.contains(selectedTheme)) {
      selectedTheme = ThemeType.midnight;
    }

    emit(ShopState(
      selectedType: selected,
      selectedFill: selectedFill,
      selectedTheme: selectedTheme,
      coins: coins,
      unlocked: unlocked,
      unlockedFills: unlockedFills,
      unlockedThemes: unlockedThemes,
    ));
  }

  Future<void> _persistSelection(BottleType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bottleTypeKey, type.name);
  }

  Future<void> _persistFillSelection(FillType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fillTypeKey, type.name);
  }

  Future<void> _persistThemeSelection(ThemeType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeTypeKey, type.name);
  }

  Future<void> _persistUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _unlockedKey,
      state.unlocked.map((e) => e.name).toList(),
    );
  }

  Future<void> _persistUnlockedFills() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _unlockedFillsKey,
      state.unlockedFills.map((e) => e.name).toList(),
    );
  }

  Future<void> _persistUnlockedThemes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _unlockedThemesKey,
      state.unlockedThemes.map((e) => e.name).toList(),
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

  /// Select a fill type if unlocked, or purchase if the player has enough coins.
  Future<void> selectOrPurchaseFill(FillType type) async {
    if (state.unlockedFills.contains(type)) {
      emit(state.copyWith(selectedFill: type));
      await _persistFillSelection(type);
      return;
    }

    final price = type.coinPrice;
    if (price <= 0) {
      final next = {...state.unlockedFills, type};
      emit(state.copyWith(selectedFill: type, unlockedFills: next));
      await _persistFillSelection(type);
      await _persistUnlockedFills();
      return;
    }

    if (state.coins < price) return;

    final newCoins = state.coins - price;
    await CoinService.setCoins(newCoins);
    final next = {...state.unlockedFills, type};
    emit(state.copyWith(
      selectedFill: type,
      coins: newCoins,
      unlockedFills: next,
    ));
    await _persistFillSelection(type);
    await _persistUnlockedFills();
  }

  /// Select a theme type if unlocked, or purchase if the player has enough coins.
  Future<void> selectOrPurchaseTheme(ThemeType type) async {
    if (state.unlockedThemes.contains(type)) {
      emit(state.copyWith(selectedTheme: type));
      await _persistThemeSelection(type);
      return;
    }

    final price = type.coinPrice;
    if (price <= 0) {
      final next = {...state.unlockedThemes, type};
      emit(state.copyWith(selectedTheme: type, unlockedThemes: next));
      await _persistThemeSelection(type);
      await _persistUnlockedThemes();
      return;
    }

    if (state.coins < price) return;

    final newCoins = state.coins - price;
    await CoinService.setCoins(newCoins);
    final next = {...state.unlockedThemes, type};
    emit(state.copyWith(
      selectedTheme: type,
      coins: newCoins,
      unlockedThemes: next,
    ));
    await _persistThemeSelection(type);
    await _persistUnlockedThemes();
  }
}
