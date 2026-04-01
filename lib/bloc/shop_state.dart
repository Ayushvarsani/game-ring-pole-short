import 'package:equatable/equatable.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../models/theme_type.dart';

class ShopState extends Equatable {
  final BottleType selectedType;
  final FillType selectedFill;
  final ThemeType selectedTheme;
  final int coins;
  final Set<BottleType> unlocked;
  final Set<FillType> unlockedFills;
  final Set<ThemeType> unlockedThemes;

  const ShopState({
    required this.selectedType,
    required this.selectedFill,
    required this.selectedTheme,
    required this.coins,
    required this.unlocked,
    required this.unlockedFills,
    required this.unlockedThemes,
  });

  factory ShopState.initial() => ShopState(
        selectedType: BottleType.classic,
        selectedFill: FillType.liquid,
        selectedTheme: ThemeType.midnight,
        coins: 0,
        unlocked: {BottleType.classic},
        unlockedFills: {FillType.liquid},
        unlockedThemes: {ThemeType.midnight},
      );

  ShopState copyWith({
    BottleType? selectedType,
    FillType? selectedFill,
    ThemeType? selectedTheme,
    int? coins,
    Set<BottleType>? unlocked,
    Set<FillType>? unlockedFills,
    Set<ThemeType>? unlockedThemes,
  }) {
    return ShopState(
      selectedType: selectedType ?? this.selectedType,
      selectedFill: selectedFill ?? this.selectedFill,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      coins: coins ?? this.coins,
      unlocked: unlocked ?? this.unlocked,
      unlockedFills: unlockedFills ?? this.unlockedFills,
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
    );
  }

  bool isUnlocked(BottleType type) => unlocked.contains(type);
  bool isFillUnlocked(FillType type) => unlockedFills.contains(type);
  bool isThemeUnlocked(ThemeType type) => unlockedThemes.contains(type);

  @override
  List<Object?> get props => [
        selectedType,
        selectedFill,
        selectedTheme,
        coins,
        unlocked,
        unlockedFills,
        unlockedThemes,
      ];
}
