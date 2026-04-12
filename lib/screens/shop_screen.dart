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

  static const LinearGradient _shopBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF081321), Color(0xFF0E1A32), Color(0xFF0A1324)],
  );

  static const List<ShopTabSpec> _tabs = [
    ShopTabSpec(
      label: 'Bottles',
      tint: AppTheme.accentPrimary,
      icon: Icons.wine_bar_rounded,
    ),
    ShopTabSpec(
      label: 'Contents',
      tint: AppTheme.accentGold,
      icon: Icons.water_drop_rounded,
    ),
    ShopTabSpec(
      label: 'Themes',
      tint: AppTheme.accentWarm,
      icon: Icons.palette_rounded,
    ),
  ];

  void _handleBack() {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerLightHaptic();
    Navigator.of(context).pop();
  }

  void _handleTabChange(int index) {
    context.read<SettingsCubit>().playClickSound();
    context.read<SettingsCubit>().triggerSelectionHaptic();
    setState(() => _selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _shopBackground),
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
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final metrics = _ShopLayoutMetrics.resolve(constraints);

                    return Column(
                      children: [
                        BlocBuilder<ShopCubit, ShopState>(
                          builder: (context, shop) {
                            return ShopTopBar(
                              coins: shop.coins,
                              compact: metrics.isCompact,
                              onBack: _handleBack,
                            );
                          },
                        ),
                        SizedBox(height: metrics.sectionSpacing),
                        ShopTabBar(
                          items: _tabs,
                          selectedIndex: _selectedTabIndex,
                          compact: metrics.isCompact,
                          onChanged: _handleTabChange,
                        ),
                        SizedBox(height: metrics.sectionSpacing),
                        // Only the catalog grid scrolls. Tighter gutters and
                        // shorter cards keep more inventory visible above the
                        // fold while the premium top chrome stays fixed.
                        Expanded(
                          child: BlocBuilder<ShopCubit, ShopState>(
                            builder: (context, shop) {
                              final cards = _buildCardsForTab(
                                context,
                                shop,
                                metrics,
                              );

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
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
                                child: GridView.builder(
                                  key: ValueKey(_selectedTabIndex),
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(
                                    bottom: metrics.bottomPadding,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: metrics.columnCount,
                                        mainAxisExtent: metrics.cardHeight,
                                        crossAxisSpacing: metrics.gridSpacing,
                                        mainAxisSpacing: metrics.gridSpacing,
                                      ),
                                  itemCount: cards.length,
                                  itemBuilder: (context, index) => cards[index],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardsForTab(
    BuildContext context,
    ShopState shop,
    _ShopLayoutMetrics metrics,
  ) {
    if (_selectedTabIndex == 0) {
      return BottleType.values
          .map((type) => _buildBottleCard(context, type, shop, metrics))
          .toList();
    }
    if (_selectedTabIndex == 1) {
      return FillType.values
          .map((type) => _buildFillCard(context, type, shop, metrics))
          .toList();
    }
    return ThemeType.values
        .map((type) => _buildThemeCard(context, type, shop, metrics))
        .toList();
  }

  Widget _buildBottleCard(
    BuildContext context,
    BottleType type,
    ShopState shop,
    _ShopLayoutMetrics metrics,
  ) {
    final isSelected = type == shop.selectedType;
    final unlocked = shop.isUnlocked(type);
    final locked = !unlocked && type.coinPrice > 0;
    final affordable = shop.coins >= type.coinPrice;
    const previewBottle = BottleModel(
      id: 0,
      colors: [
        GameColors.blue,
        GameColors.blue,
        GameColors.green,
        GameColors.red,
      ],
    );

    return ShopItemCard(
      compact: metrics.isCompact,
      title: type.displayName,
      subtitle: isSelected
          ? 'Currently equipped'
          : locked
          ? affordable
                ? 'Unlock this bottle style'
                : 'Need more coins'
          : 'Ready to equip',
      status: isSelected
          ? ShopItemStatus.equipped
          : locked
          ? ShopItemStatus.locked
          : ShopItemStatus.active,
      tint: AppTheme.accentPrimary,
      affordable: affordable,
      price: locked ? type.coinPrice : null,
      actionLabel: isSelected ? 'Equipped' : 'Equip',
      preview: SizedBox(
        width: metrics.previewBottleWidth,
        height: metrics.previewBottleHeight,
        child: BottleWidget(
          bottle: previewBottle,
          bottleType: type,
          fillType: shop.selectedFill,
          size: Size(metrics.previewBottleWidth, metrics.previewBottleHeight),
        ),
      ),
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        if (locked && !affordable) {
          return;
        }
        context.read<ShopCubit>().selectOrPurchase(type);
      },
    );
  }

  Widget _buildFillCard(
    BuildContext context,
    FillType type,
    ShopState shop,
    _ShopLayoutMetrics metrics,
  ) {
    final isSelected = type == shop.selectedFill;
    final unlocked = shop.isFillUnlocked(type);
    final locked = !unlocked && type.coinPrice > 0;
    final affordable = shop.coins >= type.coinPrice;
    const previewBottle = BottleModel(id: 0, colors: [GameColors.purple]);

    return ShopItemCard(
      compact: metrics.isCompact,
      title: type.displayName,
      subtitle: isSelected
          ? 'Currently active'
          : locked
          ? affordable
                ? 'Unlock this pour style'
                : 'Need more coins'
          : 'Ready to pour',
      status: isSelected
          ? ShopItemStatus.equipped
          : locked
          ? ShopItemStatus.locked
          : ShopItemStatus.active,
      tint: AppTheme.accentGold,
      affordable: affordable,
      price: locked ? type.coinPrice : null,
      actionLabel: isSelected ? 'Equipped' : 'Use',
      preview: SizedBox(
        width: metrics.previewBottleWidth,
        height: metrics.previewBottleHeight,
        child: BottleWidget(
          bottle: previewBottle,
          bottleType: shop.selectedType,
          fillType: type,
          size: Size(metrics.previewBottleWidth, metrics.previewBottleHeight),
        ),
      ),
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        if (locked && !affordable) {
          return;
        }
        context.read<ShopCubit>().selectOrPurchaseFill(type);
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    ThemeType type,
    ShopState shop,
    _ShopLayoutMetrics metrics,
  ) {
    final isSelected = type == shop.selectedTheme;
    final unlocked = shop.isThemeUnlocked(type);
    final locked = !unlocked && type.coinPrice > 0;
    final affordable = shop.coins >= type.coinPrice;

    return ShopItemCard(
      compact: metrics.isCompact,
      title: type.displayName,
      subtitle: isSelected
          ? 'Currently applied'
          : locked
          ? affordable
                ? 'Unlock this backdrop'
                : 'Need more coins'
          : 'Apply this theme',
      status: isSelected
          ? ShopItemStatus.equipped
          : locked
          ? ShopItemStatus.locked
          : ShopItemStatus.active,
      tint: AppTheme.accentWarm,
      affordable: affordable,
      price: locked ? type.coinPrice : null,
      actionLabel: isSelected ? 'Equipped' : 'Apply',
      preview: _ThemePreview(
        gradient: type.gradient,
        compact: metrics.isCompact,
      ),
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        if (locked && !affordable) {
          return;
        }
        context.read<ShopCubit>().selectOrPurchaseTheme(type);
      },
    );
  }
}

class _ShopLayoutMetrics {
  const _ShopLayoutMetrics({
    required this.isCompact,
    required this.sectionSpacing,
    required this.gridSpacing,
    required this.columnCount,
    required this.cardHeight,
    required this.previewBottleWidth,
    required this.previewBottleHeight,
    required this.bottomPadding,
  });

  final bool isCompact;
  final double sectionSpacing;
  final double gridSpacing;
  final int columnCount;
  final double cardHeight;
  final double previewBottleWidth;
  final double previewBottleHeight;
  final double bottomPadding;

  static _ShopLayoutMetrics resolve(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final compact = height < 760 || width < 390;

    return _ShopLayoutMetrics(
      isCompact: compact,
      sectionSpacing: compact ? 12 : 14,
      gridSpacing: compact ? 12 : 14,
      columnCount: width >= 760
          ? 4
          : width >= 560
          ? 3
          : width >= 330
          ? 2
          : 1,
      cardHeight: compact ? 226 : 238,
      previewBottleWidth: compact ? 36 : 40,
      previewBottleHeight: compact ? 88 : 94,
      bottomPadding: compact ? 18 : 24,
    );
  }
}

class ShopTabSpec {
  const ShopTabSpec({
    required this.label,
    required this.tint,
    required this.icon,
  });

  final String label;
  final Color tint;
  final IconData icon;
}

class ShopTopBar extends StatelessWidget {
  const ShopTopBar({
    super.key,
    required this.coins,
    required this.onBack,
    required this.compact,
  });

  final int coins;
  final VoidCallback onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // The header only keeps navigation and currency so the catalog starts
    // higher on the screen and feels more like a compact in-game storefront.
    return GlassCard(
      tint: AppTheme.accentPrimary,
      radius: 24,
      blurSigma: 20,
      muted: true,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 8 : 9,
      ),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.arrow_back_rounded,
            tint: AppTheme.accentPrimary,
            size: compact ? 18 : 19,
            padding: EdgeInsets.all(compact ? 8 : 9),
            onTap: onBack,
          ),
          const Spacer(),
          _ShopCoinsChip(coins: coins, compact: compact),
        ],
      ),
    );
  }
}

class _ShopCoinsChip extends StatelessWidget {
  const _ShopCoinsChip({required this.coins, required this.compact});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tint: AppTheme.accentGold,
      highlighted: true,
      radius: compact ? 16 : 18,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on_rounded,
            color: AppTheme.accentGold,
            size: compact ? 15 : 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.18,
            ),
          ),
        ],
      ),
    );
  }
}

class ShopTabBar extends StatelessWidget {
  const ShopTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    required this.compact,
  });

  final List<ShopTabSpec> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final currentTint = items[selectedIndex].tint;

    return GlassCard(
      tint: currentTint,
      radius: 22,
      blurSigma: 18,
      muted: true,
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;

          return SizedBox(
            height: compact ? 44 : 48,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  left: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DecoratedBox(
                      decoration: AppTheme.gradientButtonDecoration(
                        accentColor: currentTint,
                        emphasized: true,
                        radius: compact ? 16 : 18,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final selected = index == selectedIndex;

                    return Expanded(
                      child: GamePressable(
                        onTap: () => onChanged(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: selected ? 1.0 : 0.7,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: compact ? 15 : 16,
                                  color: Colors.white.withValues(
                                    alpha: selected ? 1.0 : 0.88,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: selected ? 1.0 : 0.88,
                                      ),
                                      fontSize: compact ? 12 : 13,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      letterSpacing: selected ? 0.22 : 0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum ShopItemStatus { equipped, active, locked }

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.preview,
    required this.status,
    required this.tint,
    required this.affordable,
    required this.actionLabel,
    required this.onTap,
    required this.compact,
    this.price,
  });

  final String title;
  final String subtitle;
  final Widget preview;
  final ShopItemStatus status;
  final Color tint;
  final bool affordable;
  final String actionLabel;
  final VoidCallback onTap;
  final bool compact;
  final int? price;

  bool get _actionEnabled => status != ShopItemStatus.locked || affordable;

  Color _cardTint() {
    switch (status) {
      case ShopItemStatus.equipped:
        return tint;
      case ShopItemStatus.active:
        return Color.lerp(tint, AppTheme.accentSuccess, 0.26)!;
      case ShopItemStatus.locked:
        return Color.lerp(AppTheme.bgMedium, AppTheme.textMuted, 0.18)!;
    }
  }

  Color _badgeTint() {
    switch (status) {
      case ShopItemStatus.equipped:
        return AppTheme.accentGold;
      case ShopItemStatus.active:
        return AppTheme.accentSuccess;
      case ShopItemStatus.locked:
        return const Color(0xFF667085);
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case ShopItemStatus.equipped:
        return Icons.check_circle_rounded;
      case ShopItemStatus.active:
        return Icons.auto_awesome_rounded;
      case ShopItemStatus.locked:
        return Icons.lock_rounded;
    }
  }

  String _badgeLabel() {
    switch (status) {
      case ShopItemStatus.equipped:
        return 'Equipped';
      case ShopItemStatus.active:
        return 'Active';
      case ShopItemStatus.locked:
        return 'Locked';
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = compact ? 84.0 : 90.0;

    return GlassCard(
      tint: _cardTint(),
      radius: compact ? 24 : 26,
      blurSigma: 18,
      highlighted: status == ShopItemStatus.equipped,
      muted: status != ShopItemStatus.equipped,
      padding: EdgeInsets.all(compact ? 12 : 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShopBadge(
                label: _badgeLabel(),
                tint: _badgeTint(),
                compact: compact,
              ),
              const Spacer(),
              Container(
                width: compact ? 28 : 30,
                height: compact ? 28 : 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _statusIcon(),
                  size: compact ? 15 : 16,
                  color: status == ShopItemStatus.locked
                      ? Colors.white.withValues(alpha: 0.64)
                      : _badgeTint(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Fixed preview and button heights keep the cards visually smaller
          // without feeling cramped, so more inventory remains above the fold.
          GlassCard(
            tint: status == ShopItemStatus.locked ? AppTheme.textMuted : tint,
            radius: compact ? 18 : 20,
            blurSigma: 14,
            muted: true,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 8 : 10,
            ),
            child: SizedBox(
              width: double.infinity,
              height: previewHeight,
              child: Center(child: preview),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.12,
            ),
          ),
          const Spacer(),
          ShopActionButton(
            status: status,
            price: price,
            affordable: affordable,
            compact: compact,
            tint: tint,
            label: actionLabel,
            onTap: _actionEnabled ? onTap : null,
          ),
        ],
      ),
    );
  }
}

class ShopBadge extends StatelessWidget {
  const ShopBadge({
    super.key,
    required this.label,
    required this.tint,
    required this.compact,
  });

  final String label;
  final Color tint;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient(tint, intensity: 0.84),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: AppTheme.premiumShadows(tint, emphasized: false),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          height: 1,
        ),
      ),
    );
  }
}

class ShopActionButton extends StatelessWidget {
  const ShopActionButton({
    super.key,
    required this.status,
    required this.affordable,
    required this.compact,
    required this.tint,
    required this.label,
    required this.onTap,
    this.price,
  });

  final ShopItemStatus status;
  final bool affordable;
  final bool compact;
  final Color tint;
  final String label;
  final VoidCallback? onTap;
  final int? price;

  Color _buttonTint() {
    switch (status) {
      case ShopItemStatus.equipped:
        return AppTheme.accentGold;
      case ShopItemStatus.active:
        return AppTheme.accentSuccess;
      case ShopItemStatus.locked:
        return affordable ? AppTheme.accentGold : const Color(0xFF5C667A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final buttonTint = _buttonTint();

    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1.0 : 0.82,
        child: Container(
          height: compact ? 34 : 36,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient(
              buttonTint,
              intensity: status == ShopItemStatus.equipped ? 1.0 : 0.84,
            ),
            borderRadius: BorderRadius.circular(compact ? 15 : 16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: AppTheme.premiumShadows(
              buttonTint,
              emphasized: enabled && status != ShopItemStatus.locked,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
          child: Center(
            child: status == ShopItemStatus.locked
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        size: compact ? 14 : 15,
                        color: Colors.white.withValues(
                          alpha: enabled ? 1.0 : 0.78,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${price ?? 0}',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: enabled ? 1.0 : 0.78,
                          ),
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.18,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == ShopItemStatus.equipped) ...[
                        Icon(
                          Icons.check_rounded,
                          size: compact ? 14 : 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.22,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.gradient, required this.compact});

  final LinearGradient gradient;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 82.0 : 88.0;
    final height = compact ? 70.0 : 76.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              width: compact ? 14 : 16,
              height: compact ? 14 : 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 12,
            child: Container(
              width: compact ? 20 : 22,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: GlassCard(
              tint: Colors.white,
              radius: 14,
              blurSigma: 10,
              muted: true,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: const SizedBox(height: 10),
            ),
          ),
        ],
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
