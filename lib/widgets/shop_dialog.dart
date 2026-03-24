import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../bloc/settings_cubit.dart';
import '../models/bottle_type.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';
import '../painters/liquid_painter.dart';

class ShopDialog extends StatelessWidget {
  const ShopDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F3A), Color(0xFF0A0E21)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Bottle Shop',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 40, height: 40),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 26),
                    onPressed: () {
                      context.read<SettingsCubit>().playClickSound();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your bottle style',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ShopCubit, ShopState>(
              builder: (context, shop) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color:
                          const Color(0xFFFFD700).withValues(alpha: 0.95),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${shop.coins} coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            BlocBuilder<ShopCubit, ShopState>(
              builder: (context, shop) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: BottleType.values.map((type) {
                    return _buildBottleCard(context, type, shop);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleCard(
      BuildContext context, BottleType type, ShopState shop) {
    final isSelected = type == shop.selectedType;
    final unlocked = shop.isUnlocked(type);
    const previewBottle = BottleModel(
      id: 0,
      colors: [
        GameColors.blue,
        GameColors.blue,
        GameColors.green,
        GameColors.red,
      ],
    );

    return GestureDetector(
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        final cubit = context.read<ShopCubit>();
        if (!unlocked && type.coinPrice > 0 && shop.coins < type.coinPrice) {
          return;
        }
        cubit.selectOrPurchase(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4FC3F7)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 45,
                      height: 110,
                      child: CustomPaint(
                        painter: LiquidPainter(
                          bottle: previewBottle,
                          bottleType: type,
                        ),
                        size: const Size(45, 110),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF4FC3F7)
                            : Colors.white70,
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (!unlocked && type.coinPrice > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            size: 12,
                            color: shop.coins >= type.coinPrice
                                ? const Color(0xFFFFD700)
                                : Colors.white38,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${type.coinPrice}',
                            style: TextStyle(
                              color: shop.coins >= type.coinPrice
                                  ? const Color(0xFFFFD700)
                                  : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!unlocked && type.coinPrice > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: const Color(0xFF4FC3F7),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
