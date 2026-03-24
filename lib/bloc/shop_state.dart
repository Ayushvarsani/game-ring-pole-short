import 'package:equatable/equatable.dart';
import '../models/bottle_type.dart';

class ShopState extends Equatable {
  final BottleType selectedType;
  final int coins;
  final Set<BottleType> unlocked;

  const ShopState({
    required this.selectedType,
    required this.coins,
    required this.unlocked,
  });

  factory ShopState.initial() => ShopState(
        selectedType: BottleType.classic,
        coins: 0,
        unlocked: {BottleType.classic},
      );

  ShopState copyWith({
    BottleType? selectedType,
    int? coins,
    Set<BottleType>? unlocked,
  }) {
    return ShopState(
      selectedType: selectedType ?? this.selectedType,
      coins: coins ?? this.coins,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  bool isUnlocked(BottleType type) => unlocked.contains(type);

  @override
  List<Object?> get props => [selectedType, coins, unlocked];
}
