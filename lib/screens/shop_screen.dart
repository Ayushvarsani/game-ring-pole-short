import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../models/bottle_model.dart';
import '../models/bottle_type.dart';
import '../models/fill_type.dart';
import '../models/game_colors.dart';
import '../models/theme_type.dart';
import '../painters/liquid_painter.dart';
import '../theme/app_theme.dart';
import '../widgets/game_ui.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeGradient = context
        .watch<ShopCubit>()
        .state
        .selectedTheme
        .gradient;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: themeGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppTheme.overlayGradient,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 12),
                    _buildTabBar(context),
                    const SizedBox(height: 14),
                    Expanded(
                      child: BlocBuilder<ShopCubit, ShopState>(
                        builder: (context, shop) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 14,
                              runSpacing: 14,
                              children: _selectedTabIndex == 0
                                  ? BottleType.values
                                        .map(
                                          (type) => _buildBottleCard(
                                            context,
                                            type,
                                            shop,
                                          ),
                                        )
                                        .toList()
                                  : _selectedTabIndex == 1
                                  ? FillType.values
                                        .map(
                                          (type) => _buildFillCard(
                                            context,
                                            type,
                                            shop,
                                          ),
                                        )
                                        .toList()
                                  : ThemeType.values
                                        .map(
                                          (type) => _buildThemeCard(
                                            context,
                                            type,
                                            shop,
                                          ),
                                        )
                                        .toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, shop) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.surfaceDecoration(
            tint: AppTheme.accentWarm,
            radius: 30,
            muted: true,
          ),
          child: Row(
            children: [
              GameIconButton(
                icon: Icons.arrow_back_rounded,
                tint: AppTheme.accentPrimary,
                onTap: () {
                  context.read<SettingsCubit>().playClickSound();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Style Shop',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Unlock new bottles, fills, and themes',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
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
                      '${shop.coins}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: AppTheme.surfaceDecoration(
        tint: AppTheme.accentSecondary,
        radius: 24,
        muted: true,
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(context, 'Bottles', 0)),
          Expanded(child: _buildTabButton(context, 'Contents', 1)),
          Expanded(child: _buildTabButton(context, 'Themes', 2)),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String label, int index) {
    final selected = _selectedTabIndex == index;
    final tint = index == 0
        ? AppTheme.accentPrimary
        : index == 1
        ? AppTheme.accentGold
        : AppTheme.accentWarm;

    return GamePressable(
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        setState(() => _selectedTabIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
            fontSize: 14,
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

    return _buildShopCard(
      context: context,
      label: type.displayName,
      isSelected: isSelected,
      unlocked: unlocked,
      affordable: shop.coins >= type.coinPrice,
      price: type.coinPrice,
      tint: AppTheme.accentPrimary,
      preview: SizedBox(
        width: 58,
        height: 144,
        child: CustomPaint(
          painter: LiquidPainter(
            bottle: previewBottle,
            bottleType: type,
            fillType: shop.selectedFill,
          ),
          size: const Size(58, 144),
        ),
      ),
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

    return _buildShopCard(
      context: context,
      label: type.displayName,
      isSelected: isSelected,
      unlocked: unlocked,
      affordable: shop.coins >= type.coinPrice,
      price: type.coinPrice,
      tint: AppTheme.accentGold,
      preview: SizedBox(
        width: 58,
        height: 144,
        child: CustomPaint(
          painter: LiquidPainter(
            bottle: previewBottle,
            bottleType: shop.selectedType,
            fillType: type,
          ),
          size: const Size(58, 144),
        ),
      ),
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

  Widget _buildThemeCard(BuildContext context, ThemeType type, ShopState shop) {
    final isSelected = type == shop.selectedTheme;
    final unlocked = shop.isThemeUnlocked(type);

    return _buildShopCard(
      context: context,
      label: type.displayName,
      isSelected: isSelected,
      unlocked: unlocked,
      affordable: shop.coins >= type.coinPrice,
      price: type.coinPrice,
      tint: AppTheme.accentWarm,
      preview: Container(
        width: 82,
        height: 144,
        decoration: BoxDecoration(
          gradient: type.gradient,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
      ),
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        if (!unlocked && type.coinPrice > 0 && shop.coins < type.coinPrice) {
          return;
        }
        context.read<ShopCubit>().selectOrPurchaseTheme(type);
      },
    );
  }

  Widget _buildShopCard({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool unlocked,
    required bool affordable,
    required int price,
    required Color tint,
    required Widget preview,
    required VoidCallback onTap,
  }) {
    final locked = !unlocked && price > 0;
    final actionLabel = isSelected
        ? 'Equipped'
        : unlocked
        ? 'Tap to use'
        : 'Buy';

    return SizedBox(
      width: 118,
      child: GamePressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.cardDecoration(
            isSelected: isSelected,
            isLocked: locked,
            glowColor: tint,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatusBadge(
                    text: isSelected
                        ? 'Active'
                        : unlocked
                        ? 'Owned'
                        : 'Locked',
                    tint: isSelected
                        ? tint
                        : unlocked
                        ? AppTheme.accentSuccess
                        : AppTheme.textMuted,
                  ),
                  const Spacer(),
                  if (locked)
                    Icon(
                      Icons.lock_rounded,
                      color: AppTheme.textMuted.withValues(alpha: 0.85),
                      size: 15,
                    )
                  else if (isSelected)
                    Icon(Icons.check_circle_rounded, color: tint, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 156,
                decoration: AppTheme.surfaceDecoration(
                  tint: tint,
                  radius: 20,
                  muted: true,
                ),
                alignment: Alignment.center,
                child: preview,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: isSelected ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: locked
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            size: 14,
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
                    : Text(
                        actionLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? tint : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required String text, required Color tint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tint,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
