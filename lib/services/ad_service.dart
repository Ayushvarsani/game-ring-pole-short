import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService instance = AdService._internal();

  AdService._internal();

  static const String _kFreeHintsCount = 'free_hints_count';
  static const String _kUndoClickCount = 'undo_click_count';
  static const String _kCompletedLevelsAdsCount = 'completed_levels_ads_count';

  int _freeHintsRemaining = 5;
  int _undoClickCount = 0;
  int _completedLevelsCount = 0;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInterstitialAdLoading = false;
  bool _isRewardedAdLoading = false;

  int get freeHintsRemaining => _freeHintsRemaining;

  // Interstitial Ad Unit ID
  String get _interstitialAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    return '';
  }

  // Rewarded Ad Unit ID
  String get _rewardedAdUnitId {
    if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
    if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
    return '';
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
    
    // Load persisted local storage
    final prefs = await SharedPreferences.getInstance();
    
    // if it's a first time user, this will default to 5
    _freeHintsRemaining = prefs.getInt(_kFreeHintsCount) ?? 5;
    _undoClickCount = prefs.getInt(_kUndoClickCount) ?? 0;
    _completedLevelsCount = prefs.getInt(_kCompletedLevelsAdsCount) ?? 0;

    // Preload ads
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  /// ---------------------------------------------------------
  /// HINT LOGIC
  /// ---------------------------------------------------------

  bool get requiresAdForHint {
    return _freeHintsRemaining <= 0;
  }

  Future<void> handleHintClick({
    required VoidCallback onHintGranted,
    required VoidCallback onAdFailed,
  }) async {
    if (!requiresAdForHint) {
      // Consume a free hint
      _freeHintsRemaining--;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kFreeHintsCount, _freeHintsRemaining);
      
      onHintGranted();
      return;
    }

    // Require Ad
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onHintGranted(); // Granted
      });
      _rewardedAd = null;
      _loadRewardedAd(); // Load next
    } else {
      // Ad not ready or failed to load.
      // Gracefully just give the hint without blocking.
      onHintGranted();
      _loadRewardedAd();
    }
  }

  /// ---------------------------------------------------------
  /// UNDO LOGIC
  /// ---------------------------------------------------------

  bool get requiresAdForUndo {
    // pattern: click 1->free, click 2->free, click 3->required ad.
    // _undoClickCount keeps track of previous clicks. 
    // If previous clicks % 3 == 2, the current (next) click is the 3rd one.
    return (_undoClickCount % 3) == 2;
  }

  Future<void> handleUndoClick({
    required VoidCallback onUndoGranted,
    required VoidCallback onAdFailed,
  }) async {
    final needsAd = requiresAdForUndo;

    // Helper to commit the click
    Future<void> commitUndo() async {
      _undoClickCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kUndoClickCount, _undoClickCount);
      onUndoGranted();
    }

    if (!needsAd) {
      await commitUndo();
      return;
    }

    // Needs Ad
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        commitUndo();
      });
      _rewardedAd = null;
      _loadRewardedAd();
    } else {
      // Graceful fallback
      commitUndo();
      _loadRewardedAd();
    }
  }

  /// ---------------------------------------------------------
  /// INTERSTITIAL LOGIC (Level Completion)
  /// ---------------------------------------------------------

  Future<void> handleLevelCompleted({
    required VoidCallback onContinue,
  }) async {
    _completedLevelsCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCompletedLevelsAdsCount, _completedLevelsCount);

    if (_completedLevelsCount % 2 == 0) {
      if (_interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _loadInterstitialAd();
            onContinue();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            _loadInterstitialAd();
            onContinue();
          },
        );
        _interstitialAd!.show();
        return; // the callback handles 'onContinue'
      } else {
        // Fallback
        _loadInterstitialAd();
      }
    }
    
    // Not a multiple of 2 or ad not loaded
    onContinue();
  }

  /// ---------------------------------------------------------
  /// AD METHDOS (Preloading)
  /// ---------------------------------------------------------

  void _loadInterstitialAd() {
    if (_isInterstitialAdLoading) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
          );
          
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
        },
      ),
    );
  }
}
