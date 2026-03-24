import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../bloc/settings_cubit.dart';
import '../models/bottle_type.dart';
import '../models/bottle_model.dart';
import '../models/game_colors.dart';
import '../painters/liquid_painter.dart';
import '../theme/app_theme.dart';

class ShopDialog extends StatelessWidget {
  const ShopDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.dialogDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.textPrimary, AppTheme.accentSecondary],
                      ).createShader(bounds),
                      child: const Text(
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
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints.tightFor(width: 40, height: 40),
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textSecondary, size: 26),
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
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ShopCubit, ShopState>(
              builder: (context, shop) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentGold.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: AppTheme.accentGold.withValues(alpha: 0.95),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${shop.coins} coins',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
        decoration: AppTheme.cardDecoration(isSelected: isSelected),
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
                            ? AppTheme.accentSecondary
                            : AppTheme.textSecondary,
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
                                ? AppTheme.accentGold
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${type.coinPrice}',
                            style: TextStyle(
                              color: shop.coins >= type.coinPrice
                                  ? AppTheme.accentGold
                                  : AppTheme.textMuted,
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
                    color: AppTheme.bgDark.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: AppTheme.textSecondary,
                    size: 14,
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentSecondary.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.accentSecondary,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
