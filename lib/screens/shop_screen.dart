import 'dart:math';

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
import '../theme/app_theme.dart';
import '../widgets/bottle_widget.dart';
import '../widgets/game_ui.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTabIndex = 0;

  static const List<GameTabItem> _tabs = [
    GameTabItem(
      label: 'Bottles',
      tint: AppTheme.accentPrimary,
      icon: Icons.wine_bar_rounded,
    ),
    GameTabItem(
      label: 'Contents',
      tint: AppTheme.accentGold,
      icon: Icons.water_drop_rounded,
    ),
    GameTabItem(
      label: 'Themes',
      tint: AppTheme.accentWarm,
      icon: Icons.palette_rounded,
    ),
  ];

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
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ShopBackdropPainter(
                    accent: _tabs[_selectedTabIndex].tint,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    GameSegmentedTabBar(
                      items: _tabs,
                      selectedIndex: _selectedTabIndex,
                      onChanged: (index) {
                        context.read<SettingsCubit>().playClickSound();
                        context.read<SettingsCubit>().triggerSelectionHaptic();
                        setState(() => _selectedTabIndex = index);
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<ShopCubit, ShopState>(
                        builder: (context, shop) {
                          final cards = _buildCardsForTab(context, shop);
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 560
                                  ? 3
                                  : constraints.maxWidth >= 360
                                  ? 2
                                  : 1;
                              const spacing = 16.0;
                              final cardWidth =
                                  (constraints.maxWidth -
                                      (spacing * (columns - 1))) /
                                  columns;

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.02, 0.03),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: SingleChildScrollView(
                                  key: ValueKey(_selectedTabIndex),
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: cards
                                        .map(
                                          (card) => SizedBox(
                                            width: max(152, cardWidth),
                                            child: card,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              );
                            },
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

  List<Widget> _buildCardsForTab(BuildContext context, ShopState shop) {
    if (_selectedTabIndex == 0) {
      return BottleType.values
          .map((type) => _buildBottleCard(context, type, shop))
          .toList();
    }
    if (_selectedTabIndex == 1) {
      return FillType.values
          .map((type) => _buildFillCard(context, type, shop))
          .toList();
    }
    return ThemeType.values
        .map((type) => _buildThemeCard(context, type, shop))
        .toList();
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<ShopCubit, ShopState>(
      builder: (context, shop) {
        return GlassCard(
          tint: AppTheme.accentWarm,
          radius: 32,
          blurSigma: 22,
          muted: true,
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.24,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Unlock new bottles, fills, and themes',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!compact) _buildCoinChip(shop.coins),
                    ],
                  ),
                  if (compact) ...[
                    const SizedBox(height: 12),
                    _buildCoinChip(shop.coins),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCoinChip(int coins) {
    return GlassCard(
      tint: AppTheme.accentGold,
      highlighted: true,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            '$coins',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.24,
            ),
          ),
        ],
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
      preview: BottleWidget(
        bottle: previewBottle,
        bottleType: type,
        fillType: shop.selectedFill,
        size: const Size(62, 150),
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
      preview: BottleWidget(
        bottle: previewBottle,
        bottleType: shop.selectedType,
        fillType: type,
        size: const Size(62, 150),
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
        width: 94,
        height: 150,
        decoration: BoxDecoration(
          gradient: type.gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: AppTheme.premiumShadows(AppTheme.accentWarm),
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
    final badgeText = isSelected
        ? 'EQUIPPED'
        : locked
        ? 'LOCKED'
        : 'ACTIVE';
    final badgeTint = isSelected
        ? AppTheme.accentGold
        : locked
        ? AppTheme.textMuted
        : AppTheme.accentSuccess;

    return GamePressable(
      onTap: onTap,
      child: GlassCard(
        tint: tint,
        radius: 26,
        highlighted: isSelected,
        muted: !isSelected,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GameBadge(text: badgeText, tint: badgeTint),
                const Spacer(),
                Icon(
                  locked
                      ? Icons.lock_rounded
                      : isSelected
                      ? Icons.check_circle_rounded
                      : Icons.auto_awesome_rounded,
                  color: locked ? AppTheme.textMuted : tint,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            GlassCard(
              tint: tint,
              radius: 22,
              muted: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 168,
                child: Center(child: preview),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.24,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSelected
                  ? 'Currently equipped'
                  : locked
                  ? 'Unlock for your next run'
                  : 'Tap to equip instantly',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.18,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient(
                  locked
                      ? (affordable ? AppTheme.accentGold : AppTheme.textMuted)
                      : tint,
                  intensity: isSelected ? 1.0 : 0.72,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: locked
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          size: 15,
                          color: Colors.white.withValues(
                            alpha: affordable ? 1 : 0.72,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$price',
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: affordable ? 1 : 0.72,
                            ),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.24,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      isSelected ? 'Equipped' : 'Equip Now',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.34,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopBackdropPainter extends CustomPainter {
  const _ShopBackdropPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              accent.withValues(alpha: 0.14),
              AppTheme.accentPrimary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.76, size.height * 0.14),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.14),
      size.width * 0.42,
      topGlow,
    );

    final bottomGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppTheme.accentSecondary.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.18, size.height * 0.82),
              radius: size.width * 0.34,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.82),
      size.width * 0.34,
      bottomGlow,
    );
  }

  @override
  bool shouldRepaint(covariant _ShopBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
