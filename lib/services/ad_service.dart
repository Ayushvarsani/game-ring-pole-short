import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'ad_mob_logger.dart';

enum RewardedAdShowResult {
  earned,
  unavailable,
  failedToShow,
  closedWithoutReward,
  rewardHandlerFailed,
}

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

  bool get isRewardedAdReady => _rewardedAd != null;

  AdMobConfig get _adMobConfig => AdMobConfig.current;

  String get _interstitialAdUnitId => _adMobConfig.interstitialAdUnitId;

  String get _rewardedAdUnitId => _adMobConfig.rewardedAdUnitId;

  Future<void> init() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _adMobConfig.testDeviceIds),
      );
      AdMobLogger.requestConfigurationApplied(
        testDeviceModeEnabled: _adMobConfig.testDeviceModeEnabled,
        testDeviceIds: _adMobConfig.testDeviceIds,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ad_service',
          context: ErrorDescription('applying Mobile Ads request config'),
        ),
      );
      _logAdMessage('RequestConfiguration failed: $error');
    }

    var mobileAdsInitialized = false;
    try {
      final initializationStatus = await MobileAds.instance.initialize();
      mobileAdsInitialized = true;
      AdMobLogger.mobileAdsInitialized(initializationStatus);
      _logAdMobStartup();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ad_service',
          context: ErrorDescription('initializing Mobile Ads SDK'),
        ),
      );
      _logAdMessage('Mobile Ads SDK initialization failed: $error');
    }

    // Load persisted local storage
    final prefs = await SharedPreferences.getInstance();

    // if it's a first time user, this will default to 5
    _freeHintsRemaining = prefs.getInt(_kFreeHintsCount) ?? 5;
    _undoClickCount = prefs.getInt(_kUndoClickCount) ?? 0;
    _completedLevelsCount = prefs.getInt(_kCompletedLevelsAdsCount) ?? 0;

    // Preload ads
    if (mobileAdsInitialized) {
      _loadInterstitialAd();
      _loadRewardedAd();
    } else {
      AdMobLogger.skipped('Ad preload skipped because Mobile Ads init failed.');
    }
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

    final result = await showRewardedAd(
      onUserEarnedReward: (_) async {
        _logAdMessage('Rewarded hint ad earned reward.');
        onHintGranted();
      },
    );

    if (result == RewardedAdShowResult.unavailable) {
      _logAdMessage('Rewarded hint ad unavailable; granting hint fallback.');
      onHintGranted();
      return;
    }

    if (result != RewardedAdShowResult.earned) onAdFailed();
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

    final result = await showRewardedAd(
      onUserEarnedReward: (_) async {
        _logAdMessage('Rewarded undo ad earned reward.');
        await commitUndo();
      },
    );

    if (result == RewardedAdShowResult.unavailable) {
      _logAdMessage('Rewarded undo ad unavailable; granting undo fallback.');
      await commitUndo();
      return;
    }

    if (result != RewardedAdShowResult.earned) onAdFailed();
  }

  Future<RewardedAdShowResult> showRewardedAd({
    required Future<void> Function(RewardItem reward) onUserEarnedReward,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      _logAdMessage('Rewarded ad requested but not loaded.');
      _loadRewardedAd();
      return RewardedAdShowResult.unavailable;
    }

    final completer = Completer<RewardedAdShowResult>();
    var rewardEarned = false;
    var disposed = false;
    _rewardedAd = null;

    void disposeAndReload() {
      if (!disposed) {
        ad.dispose();
        disposed = true;
      }
      _loadRewardedAd();
    }

    void complete(RewardedAdShowResult result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
      AdMobLogger.paidEvent(
        format: 'Rewarded',
        ad: ad,
        valueMicros: valueMicros,
        precision: precision,
        currencyCode: currencyCode,
      );
    };

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        AdMobLogger.lifecycle('Rewarded ad showed. adUnitId=${ad.adUnitId}');
      },
      onAdImpression: (_) {
        AdMobLogger.lifecycle(
          'Rewarded ad impression. adUnitId=${ad.adUnitId}',
        );
      },
      onAdClicked: (_) {
        AdMobLogger.lifecycle('Rewarded ad clicked. adUnitId=${ad.adUnitId}');
      },
      onAdWillDismissFullScreenContent: (_) {
        AdMobLogger.lifecycle(
          'Rewarded ad will dismiss. adUnitId=${ad.adUnitId}',
        );
      },
      onAdDismissedFullScreenContent: (_) {
        AdMobLogger.lifecycle('Rewarded ad dismissed. adUnitId=${ad.adUnitId}');
        disposeAndReload();
        if (!rewardEarned) {
          complete(RewardedAdShowResult.closedWithoutReward);
        }
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        AdMobLogger.showFailed(
          format: 'Rewarded',
          adUnitId: ad.adUnitId,
          error: error,
        );
        disposeAndReload();
        complete(RewardedAdShowResult.failedToShow);
      },
    );

    try {
      AdMobLogger.showStarted(format: 'Rewarded', adUnitId: ad.adUnitId);
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          _logAdMessage(
            'Rewarded ad earned reward. amount=${reward.amount}, '
            'type=${reward.type}',
          );
          rewardEarned = true;
          Future<void>.sync(() => onUserEarnedReward(reward))
              .then((_) {
                complete(RewardedAdShowResult.earned);
              })
              .catchError((Object error, StackTrace stackTrace) {
                FlutterError.reportError(
                  FlutterErrorDetails(
                    exception: error,
                    stack: stackTrace,
                    library: 'ad_service',
                    context: ErrorDescription('handling rewarded ad reward'),
                  ),
                );
                complete(RewardedAdShowResult.rewardHandlerFailed);
              });
        },
      );
    } catch (error, stackTrace) {
      disposeAndReload();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ad_service',
          context: ErrorDescription('showing rewarded ad'),
        ),
      );
      complete(RewardedAdShowResult.failedToShow);
    }

    return completer.future;
  }

  /// ---------------------------------------------------------
  /// INTERSTITIAL LOGIC (Level Completion)
  /// ---------------------------------------------------------

  Future<void> handleLevelCompleted({required VoidCallback onContinue}) async {
    _completedLevelsCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCompletedLevelsAdsCount, _completedLevelsCount);

    if (_completedLevelsCount % 2 == 0) {
      final ad = _interstitialAd;
      if (ad != null) {
        _interstitialAd = null;
        ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
          AdMobLogger.paidEvent(
            format: 'Interstitial',
            ad: ad,
            valueMicros: valueMicros,
            precision: precision,
            currencyCode: currencyCode,
          );
        };
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {
            AdMobLogger.lifecycle(
              'Interstitial ad showed. adUnitId=${ad.adUnitId}',
            );
          },
          onAdImpression: (ad) {
            AdMobLogger.lifecycle(
              'Interstitial ad impression. adUnitId=${ad.adUnitId}',
            );
          },
          onAdClicked: (ad) {
            AdMobLogger.lifecycle(
              'Interstitial ad clicked. adUnitId=${ad.adUnitId}',
            );
          },
          onAdWillDismissFullScreenContent: (ad) {
            AdMobLogger.lifecycle(
              'Interstitial ad will dismiss. adUnitId=${ad.adUnitId}',
            );
          },
          onAdDismissedFullScreenContent: (ad) {
            AdMobLogger.lifecycle(
              'Interstitial ad dismissed. adUnitId=${ad.adUnitId}',
            );
            ad.dispose();
            _loadInterstitialAd();
            onContinue();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            AdMobLogger.showFailed(
              format: 'Interstitial',
              adUnitId: ad.adUnitId,
              error: error,
            );
            ad.dispose();
            _loadInterstitialAd();
            onContinue();
          },
        );
        AdMobLogger.showStarted(format: 'Interstitial', adUnitId: ad.adUnitId);
        ad.show();
        return; // the callback handles 'onContinue'
      } else {
        // Fallback
        _logAdMessage('Interstitial ad requested but not loaded.');
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
    if (_interstitialAd != null) {
      AdMobLogger.skipped('Interstitial ad load skipped: ad already loaded.');
      return;
    }
    final adUnitId = _interstitialAdUnitId;
    if (adUnitId.isEmpty) {
      AdMobLogger.skipped(
        'Interstitial ad skipped: ADMOB_INTERSTITIAL_ID is empty.',
      );
      return;
    }
    _isInterstitialAdLoading = true;
    AdMobLogger.loadStarted(format: 'Interstitial', adUnitId: adUnitId);

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            AdMobLogger.paidEvent(
              format: 'Interstitial',
              ad: ad,
              valueMicros: valueMicros,
              precision: precision,
              currencyCode: currencyCode,
            );
          };
          _interstitialAd = ad;
          AdMobLogger.loadSucceeded(format: 'Interstitial', ad: ad);
          _isInterstitialAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          AdMobLogger.loadFailed(
            format: 'Interstitial',
            adUnitId: adUnitId,
            error: error,
          );
          _isInterstitialAdLoading = false;
        },
      ),
    );
  }

  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    if (_rewardedAd != null) {
      AdMobLogger.skipped('Rewarded ad load skipped: ad already loaded.');
      return;
    }
    final adUnitId = _rewardedAdUnitId;
    if (adUnitId.isEmpty) {
      AdMobLogger.skipped('Rewarded ad skipped: ADMOB_REWARDED_ID is empty.');
      return;
    }
    _isRewardedAdLoading = true;
    AdMobLogger.loadStarted(format: 'Rewarded', adUnitId: adUnitId);

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            AdMobLogger.paidEvent(
              format: 'Rewarded',
              ad: ad,
              valueMicros: valueMicros,
              precision: precision,
              currencyCode: currencyCode,
            );
          };
          _rewardedAd = ad;
          AdMobLogger.loadSucceeded(format: 'Rewarded', ad: ad);

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              AdMobLogger.lifecycle(
                'Rewarded ad showed before show handler. '
                'adUnitId=${ad.adUnitId}',
              );
            },
            onAdImpression: (ad) {
              AdMobLogger.lifecycle(
                'Rewarded ad impression before show handler. '
                'adUnitId=${ad.adUnitId}',
              );
            },
            onAdClicked: (ad) {
              AdMobLogger.lifecycle(
                'Rewarded ad clicked before show handler. '
                'adUnitId=${ad.adUnitId}',
              );
            },
            onAdWillDismissFullScreenContent: (ad) {
              AdMobLogger.lifecycle(
                'Rewarded ad will dismiss before show handler. '
                'adUnitId=${ad.adUnitId}',
              );
            },
            onAdDismissedFullScreenContent: (ad) {
              AdMobLogger.lifecycle(
                'Rewarded ad dismissed before show handler. '
                'adUnitId=${ad.adUnitId}',
              );
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AdMobLogger.showFailed(
                format: 'Rewarded',
                adUnitId: ad.adUnitId,
                error: error,
              );
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
          );

          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          AdMobLogger.loadFailed(
            format: 'Rewarded',
            adUnitId: adUnitId,
            error: error,
          );
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  void _logAdMobStartup() {
    _logAdMessage(
      'Initialized. APP_ENV=${_adMobConfig.appEnv}, '
      'testDeviceModeEnabled=${_adMobConfig.testDeviceModeEnabled}',
    );
  }

  void _logAdMessage(String message) {
    debugPrint('[AdService] $message');
  }
}
