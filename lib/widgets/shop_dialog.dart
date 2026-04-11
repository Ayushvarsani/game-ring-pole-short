import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../models/game_colors.dart';
import '../painters/liquid_painter.dart';
import '../theme/app_theme.dart';
import 'game_ui.dart';

class ShopDialog extends StatefulWidget {
  const ShopDialog({super.key});

  @override
  State<ShopDialog> createState() => _ShopDialogState();
}

class _ShopDialogState extends State<ShopDialog> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: GameDialogFrame(
        title: 'Quick Shop',
        subtitle: 'Swap bottles and fill styles without leaving the board.',
        tint: AppTheme.accentWarm,
        trailing: GameIconButton(
          icon: Icons.close_rounded,
          tint: AppTheme.accentWarm,
          onTap: () {
            context.read<SettingsCubit>().playClickSound();
            Navigator.of(context).pop();
          },
        ),
        child: BlocBuilder<ShopCubit, ShopState>(
          builder: (context, shop) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildTabButton(context, 'Bottles', 0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTabButton(context, 'Contents', 1)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: AppTheme.chipDecoration(
                    tint: AppTheme.accentGold,
                    emphasized: true,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        color: AppTheme.accentGold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${shop.coins} coins',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: _selectedTabIndex == 0
                        ? BottleType.values
                              .map(
                                (type) => _buildBottleCard(context, type, shop),
                              )
                              .toList()
                        : FillType.values
                              .map(
                                (type) => _buildFillCard(context, type, shop),
                              )
                              .toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label, int index) {
    final selected = _selectedTabIndex == index;
    final tint = index == 0 ? AppTheme.accentPrimary : AppTheme.accentGold;
    return GamePressable(
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        setState(() => _selectedTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: selected
            ? AppTheme.surfaceDecoration(
                tint: tint,
                radius: 18,
                highlighted: true,
              )
            : BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottleCard(
    BuildContext context,
    BottleType type,
    ShopState shop,
  ) {
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

    return _buildCard(
      context: context,
      label: type.displayName,
      preview: SizedBox(
        width: 48,
        height: 120,
        child: CustomPaint(
          painter: LiquidPainter(
            bottle: previewBottle,
            bottleType: type,
            fillType: shop.selectedFill,
          ),
          size: const Size(48, 120),
        ),
      ),
      isSelected: isSelected,
      unlocked: unlocked,
      price: type.coinPrice,
      affordable: shop.coins >= type.coinPrice,
      tint: AppTheme.accentPrimary,
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        if (!unlocked && type.coinPrice > 0 && shop.coins < type.coinPrice) {
          return;
        }
        context.read<ShopCubit>().selectOrPurchase(type);
      },
    );
  }

  Widget _buildFillCard(BuildContext context, FillType type, ShopState shop) {
    final isSelected = type == shop.selectedFill;
    final unlocked = shop.isFillUnlocked(type);
    const previewBottle = BottleModel(id: 0, colors: [GameColors.purple]);

    return _buildCard(
      context: context,
      label: type.displayName,
      preview: SizedBox(
        width: 48,
        height: 120,
        child: CustomPaint(
          painter: LiquidPainter(
            bottle: previewBottle,
            bottleType: shop.selectedType,
            fillType: type,
          ),
          size: const Size(48, 120),
        ),
      ),
      isSelected: isSelected,
      unlocked: unlocked,
      price: type.coinPrice,
      affordable: shop.coins >= type.coinPrice,
      tint: AppTheme.accentGold,
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        if (!unlocked && type.coinPrice > 0 && shop.coins < type.coinPrice) {
          return;
        }
        context.read<ShopCubit>().selectOrPurchaseFill(type);
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String label,
    required Widget preview,
    required bool isSelected,
    required bool unlocked,
    required int price,
    required bool affordable,
    required Color tint,
    required VoidCallback onTap,
  }) {
    final locked = !unlocked && price > 0;
    return SizedBox(
      width: 104,
      child: GamePressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.cardDecoration(
            isSelected: isSelected,
            isLocked: locked,
            glowColor: tint,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 134,
                decoration: AppTheme.surfaceDecoration(
                  tint: tint,
                  radius: 18,
                  muted: true,
                ),
                alignment: Alignment.center,
                child: preview,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (locked)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 13,
                      color: affordable
                          ? AppTheme.accentGold
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$price',
                      style: TextStyle(
                        color: affordable
                            ? AppTheme.accentGold
                            : AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  isSelected ? 'Equipped' : 'Tap to use',
                  style: TextStyle(
                    color: isSelected ? tint : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
