import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shop_cubit.dart';
import '../bloc/shop_state.dart';
import '../bloc/settings_cubit.dart';
import '../models/bottle_type.dart';
import '../models/bottle_model.dart';
import '../models/fill_type.dart';
import '../models/theme_type.dart';
import '../models/game_colors.dart';
import '../painters/liquid_painter.dart';
import '../theme/app_theme.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedTabIndex = 0; // 0 for Bottles, 1 for Contents, 2 for Themes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.watch<ShopCubit>().state.selectedTheme.gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        context.read<SettingsCubit>().playClickSound();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Shop',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for centering
                  ],
                ),
              ),

              const SizedBox(height: 12),
              
              // Coins
              BlocBuilder<ShopCubit, ShopState>(
                builder: (context, shop) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${shop.coins} coins',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Tab control
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16),
                    _buildTabButton('Bottles', 0),
                    const SizedBox(width: 12),
                    _buildTabButton('Contents', 1),
                    const SizedBox(width: 12),
                    _buildTabButton('Themes', 2),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // Content Area
              Expanded(
                child: BlocBuilder<ShopCubit, ShopState>(
                  builder: (context, shop) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: _selectedTabIndex == 0
                            ? BottleType.values.map((type) => _buildBottleCard(context, type, shop)).toList()
                            : _selectedTabIndex == 1
                                ? FillType.values.map((type) => _buildFillCard(context, type, shop)).toList()
                                : ThemeType.values.map((type) => _buildThemeCard(context, type, shop)).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        setState(() => _selectedTabIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentSecondary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.accentSecondary : Colors.transparent,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.accentSecondary : AppTheme.textMuted,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBottleCard(BuildContext context, BottleType type, ShopState shop) {
    final isSelected = type == shop.selectedType;
    final unlocked = shop.isUnlocked(type);
    const previewBottle = BottleModel(
      id: 0,
      colors: [GameColors.blue, GameColors.blue, GameColors.green, GameColors.red],
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
        width: 100,
        decoration: AppTheme.cardDecoration(isSelected: isSelected),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 120,
                      child: CustomPaint(
                        painter: LiquidPainter(
                          bottle: previewBottle,
                          bottleType: type,
                          fillType: shop.selectedFill,
                        ),
                        size: const Size(50, 120),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      type.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentSecondary : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (!unlocked && type.coinPrice > 0)
                      _buildPriceTag(type.coinPrice, shop.coins),
                  ],
                ),
              ),
            ),
            if (!unlocked && type.coinPrice > 0) _buildLockIcon(),
            if (isSelected) _buildCheckIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildFillCard(BuildContext context, FillType type, ShopState shop) {
    final isSelected = type == shop.selectedFill;
    final unlocked = shop.isFillUnlocked(type);
    const previewBottle = BottleModel(
      id: 0,
      colors: [GameColors.purple],
    );

    return GestureDetector(
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        final cubit = context.read<ShopCubit>();
        if (!unlocked && type.coinPrice > 0 && shop.coins < type.coinPrice) {
          return;
        }
        cubit.selectOrPurchaseFill(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        decoration: AppTheme.cardDecoration(isSelected: isSelected),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 120,
                      child: CustomPaint(
                        painter: LiquidPainter(
                          bottle: previewBottle,
                          bottleType: shop.selectedType,
                          fillType: type,
                        ),
                        size: const Size(50, 120),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      type.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentSecondary : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (!unlocked && type.coinPrice > 0)
                      _buildPriceTag(type.coinPrice, shop.coins),
                  ],
                ),
              ),
            ),
            if (!unlocked && type.coinPrice > 0) _buildLockIcon(),
            if (isSelected) _buildCheckIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ThemeType type, ShopState shop) {
    final isSelected = type == shop.selectedTheme;
    final unlocked = shop.isThemeUnlocked(type);

    return GestureDetector(
      onTap: () {
        context.read<SettingsCubit>().playClickSound();
        context.read<SettingsCubit>().triggerSelectionHaptic();
        final cubit = context.read<ShopCubit>();
        if (!unlocked && type.coinPrice > 0 && shop.coins < type.coinPrice) {
          return;
        }
        cubit.selectOrPurchaseTheme(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        decoration: AppTheme.cardDecoration(isSelected: isSelected),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: type.gradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      type.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentSecondary : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (!unlocked && type.coinPrice > 0)
                      _buildPriceTag(type.coinPrice, shop.coins),
                  ],
                ),
              ),
            ),
            if (!unlocked && type.coinPrice > 0) _buildLockIcon(),
            if (isSelected) _buildCheckIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTag(int price, int coins) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on_rounded,
              size: 14,
              color: coins >= price ? AppTheme.accentGold : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              '$price',
              style: TextStyle(
                color: coins >= price ? AppTheme.accentGold : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildLockIcon() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.bgDark.withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: AppTheme.textSecondary,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildCheckIcon() {
    return Positioned(
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
        child: const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.accentSecondary,
          size: 20,
        ),
      ),
    );
  }
}
