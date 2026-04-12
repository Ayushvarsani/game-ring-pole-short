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
import '../theme/app_theme_config.dart';
import '../widgets/bottle_widget.dart';
import '../widgets/game_ui.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTabIndex = 0;

  List<ShopTabSpec> _tabs(AppThemeConfig theme) => [
    ShopTabSpec(
      label: 'Bottles',
      tint: theme.primaryAccent,
      icon: Icons.wine_bar_rounded,
    ),
    ShopTabSpec(
      label: 'Contents',
      tint: theme.goldAccent,
      icon: Icons.water_drop_rounded,
    ),
    ShopTabSpec(
      label: 'Themes',
      tint: theme.warmAccent,
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
    final theme = AppTheme.of(context);
    final tabs = _tabs(theme);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: theme.backgroundGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: theme.overlayGradient),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ShopBackdropPainter(
                    accent: tabs[_selectedTabIndex].tint,
                    theme: theme,
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
                          items: tabs,
                          selectedIndex: _selectedTabIndex,
                          compact: metrics.isCompact,
                          onChanged: _handleTabChange,
                        ),
                        SizedBox(height: metrics.sectionSpacing),
                        // Only the catalog list scrolls. Full-width horizontal
                        // cards match the reference more closely and keep the
                        // preview, status, and action readable at compact sizes.
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
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: metrics.listMaxWidth,
                                    ),
                                    child: ListView.separated(
                                      key: ValueKey(_selectedTabIndex),
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.only(
                                        bottom: metrics.bottomPadding,
                                      ),
                                      itemCount: cards.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(height: metrics.listSpacing),
                                      itemBuilder: (context, index) => SizedBox(
                                        height: metrics.cardHeight,
                                        child: cards[index],
                                      ),
                                    ),
                                  ),
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
    final theme = AppTheme.of(context);
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

    return ShopReferenceCard(
      compact: metrics.isCompact,
      title: type.displayName,
      status: isSelected
          ? ShopItemStatus.equipped
          : locked
          ? ShopItemStatus.locked
          : ShopItemStatus.active,
      tint: theme.primaryAccent,
      affordable: affordable,
      buttonLabel: locked
          ? '${type.coinPrice}'
          : isSelected
          ? 'EQUIPPED'
          : 'EQUIP',
      buttonIcon: locked ? Icons.monetization_on_rounded : null,
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
    final theme = AppTheme.of(context);
    final isSelected = type == shop.selectedFill;
    final unlocked = shop.isFillUnlocked(type);
    final locked = !unlocked && type.coinPrice > 0;
    final affordable = shop.coins >= type.coinPrice;
    const previewBottle = BottleModel(id: 0, colors: [GameColors.purple]);

    return ShopReferenceCard(
      compact: metrics.isCompact,
      title: type.displayName,
      status: isSelected
          ? ShopItemStatus.equipped
          : locked
          ? ShopItemStatus.locked
          : ShopItemStatus.active,
      tint: theme.goldAccent,
      affordable: affordable,
      buttonLabel: locked
          ? '${type.coinPrice}'
          : isSelected
          ? 'EQUIPPED'
          : 'EQUIP',
      buttonIcon: locked ? Icons.monetization_on_rounded : null,
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
    final theme = AppTheme.of(context);
    final isSelected = type == shop.selectedTheme;
    final unlocked = shop.isThemeUnlocked(type);
    final locked = !unlocked && type.coinPrice > 0;
    final affordable = shop.coins >= type.coinPrice;

    return ShopReferenceCard(
      compact: metrics.isCompact,
      title: type.displayName,
      status: isSelected
          ? ShopItemStatus.equipped
          : locked
          ? ShopItemStatus.locked
          : ShopItemStatus.active,
      tint: theme.warmAccent,
      affordable: affordable,
      buttonLabel: locked
          ? '${type.coinPrice}'
          : isSelected
          ? 'EQUIPPED'
          : 'EQUIP',
      buttonIcon: locked ? Icons.monetization_on_rounded : null,
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
    required this.listSpacing,
    required this.listMaxWidth,
    required this.cardHeight,
    required this.previewBottleWidth,
    required this.previewBottleHeight,
    required this.bottomPadding,
  });

  final bool isCompact;
  final double sectionSpacing;
  final double listSpacing;
  final double listMaxWidth;
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
      listSpacing: compact ? 10 : 12,
      listMaxWidth: 540,
      cardHeight: compact ? 116 : 124,
      previewBottleWidth: compact ? 28 : 30,
      previewBottleHeight: compact ? 64 : 68,
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
    final theme = AppTheme.of(context);
    // The header only keeps navigation and currency so the catalog starts
    // higher on the screen and feels more like a compact in-game storefront.
    return GlassCard(
      tint: theme.primaryAccent,
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
            tint: theme.primaryAccent,
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
    final theme = AppTheme.of(context);
    return GlassCard(
      tint: theme.goldAccent,
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
            color: theme.goldAccent,
            size: compact ? 15 : 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: theme.textPrimary,
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
    final theme = AppTheme.of(context);
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
                        theme: theme,
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

class ShopReferenceCard extends StatelessWidget {
  const ShopReferenceCard({
    super.key,
    required this.title,
    required this.preview,
    required this.status,
    required this.tint,
    required this.affordable,
    required this.buttonLabel,
    required this.onTap,
    required this.compact,
    this.buttonIcon,
  });

  final String title;
  final Widget preview;
  final ShopItemStatus status;
  final Color tint;
  final bool affordable;
  final String buttonLabel;
  final VoidCallback onTap;
  final bool compact;
  final IconData? buttonIcon;

  bool get _actionEnabled =>
      status == ShopItemStatus.active ||
      (status == ShopItemStatus.locked && affordable);

  Color _cardTint(AppThemeConfig theme) {
    switch (status) {
      case ShopItemStatus.equipped:
        return tint;
      case ShopItemStatus.active:
        return Color.lerp(tint, theme.successAccent, 0.26)!;
      case ShopItemStatus.locked:
        return Color.lerp(theme.surfaceMuted, theme.textMuted, 0.18)!;
    }
  }

  Color _badgeTint(AppThemeConfig theme) {
    switch (status) {
      case ShopItemStatus.equipped:
        return theme.goldAccent;
      case ShopItemStatus.active:
        return theme.successAccent;
      case ShopItemStatus.locked:
        return Color.lerp(theme.surfaceStrong, theme.dangerAccent, 0.35)!;
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
    final theme = AppTheme.of(context);
    return GlassCard(
      tint: _cardTint(theme),
      radius: compact ? 22 : 24,
      blurSigma: 18,
      highlighted: status == ShopItemStatus.equipped,
      muted: status != ShopItemStatus.equipped,
      padding: EdgeInsets.all(compact ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 82 : 90,
            height: compact ? 82 : 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 18 : 20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 16,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: GlassCard(
                tint: status == ShopItemStatus.locked ? theme.textMuted : tint,
                radius: compact ? 16 : 18,
                blurSigma: 12,
                muted: true,
                padding: EdgeInsets.all(compact ? 8 : 10),
                child: SizedBox.expand(child: Center(child: preview)),
              ),
            ),
          ),
          SizedBox(width: compact ? 12 : 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShopBadge(
                      label: _badgeLabel(),
                      tint: _badgeTint(theme),
                      compact: compact,
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 9),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: compact ? 16 : 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.08,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                ShopActionButton(
                  status: status,
                  affordable: affordable,
                  compact: compact,
                  tint: tint,
                  label: buttonLabel,
                  icon: buttonIcon,
                  onTap: _actionEnabled ? onTap : null,
                ),
              ],
            ),
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
    final theme = AppTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient(tint, intensity: 0.84, theme: theme),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: -10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.68,
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
    this.icon,
  });

  final ShopItemStatus status;
  final bool affordable;
  final bool compact;
  final Color tint;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  Color _buttonTint(AppThemeConfig theme) {
    switch (status) {
      case ShopItemStatus.equipped:
        return theme.goldAccent;
      case ShopItemStatus.active:
        return theme.primaryAccent;
      case ShopItemStatus.locked:
        return affordable ? theme.goldAccent : theme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled = onTap != null;
    final buttonTint = _buttonTint(theme);
    final textAlpha = enabled ? 1.0 : 0.7;

    return GamePressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1.0 : 0.86,
        child: Container(
          height: compact ? 32 : 34,
          constraints: BoxConstraints(minWidth: compact ? 110 : 120),
          decoration: BoxDecoration(
            gradient: status == ShopItemStatus.locked
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  )
                : AppTheme.accentGradient(
                    buttonTint,
                    intensity: status == ShopItemStatus.equipped ? 0.92 : 0.88,
                    theme: theme,
                  ),
            borderRadius: BorderRadius.circular(compact ? 12 : 13),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: status == ShopItemStatus.locked ? 0.09 : 0.14,
              ),
            ),
            boxShadow: status == ShopItemStatus.locked
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      spreadRadius: -8,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppTheme.premiumShadows(
                    buttonTint,
                    emphasized: enabled && status != ShopItemStatus.locked,
                    theme: theme,
                  ),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: compact ? 13 : 14,
                    color: Colors.white.withValues(alpha: textAlpha),
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
                      color: Colors.white.withValues(alpha: textAlpha),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.24,
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
    final size = compact ? 54.0 : 58.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            spreadRadius: -10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              width: compact ? 10 : 12,
              height: compact ? 10 : 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 9,
            child: Container(
              width: compact ? 14 : 16,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: GlassCard(
              tint: Colors.white,
              radius: 10,
              blurSigma: 10,
              muted: true,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: const SizedBox(height: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopBackdropPainter extends CustomPainter {
  const _ShopBackdropPainter({required this.accent, required this.theme});

  final Color accent;
  final AppThemeConfig theme;

  @override
  void paint(Canvas canvas, Size size) {
    final topGlow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              accent.withValues(alpha: 0.14),
              theme.ambientGlow.withValues(alpha: 0.08),
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
              theme.ambientGlowSecondary.withValues(alpha: 0.08),
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
    return oldDelegate.accent != accent || oldDelegate.theme != theme;
  }
}
