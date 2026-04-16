import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
const _androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
const _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';

const _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
const _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
const _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

String get _bannerId => switch (defaultTargetPlatform) {
  TargetPlatform.android => _androidBannerId,
  TargetPlatform.iOS => _iosBannerId,
  _ => '',
};

String get _interstitialId => switch (defaultTargetPlatform) {
  TargetPlatform.android => _androidInterstitialId,
  TargetPlatform.iOS => _iosInterstitialId,
  _ => '',
};

String get _rewardedId => switch (defaultTargetPlatform) {
  TargetPlatform.android => _androidRewardedId,
  TargetPlatform.iOS => _iosRewardedId,
  _ => '',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await MobileAds.instance.initialize();
  debugPrint('[AdMobSample] initialized: ${status.adapterStatuses}');
  runApp(const MaterialApp(home: AdMobMinimalExample()));
}

class AdMobMinimalExample extends StatefulWidget {
  const AdMobMinimalExample({super.key});

  @override
  State<AdMobMinimalExample> createState() => _AdMobMinimalExampleState();
}

class _AdMobMinimalExampleState extends State<AdMobMinimalExample> {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadBanner() {
    final adUnitId = _bannerId;
    if (adUnitId.isEmpty) return;

    debugPrint('[AdMobSample] Banner load start: $adUnitId');
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('[AdMobSample] Banner loaded: ${ad.adUnitId}');
          setState(() => _bannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMobSample] Banner failed: $error');
          ad.dispose();
        },
        onAdOpened: (ad) => debugPrint('[AdMobSample] Banner opened'),
        onAdWillDismissScreen: (ad) {
          debugPrint('[AdMobSample] Banner will dismiss');
        },
        onAdClosed: (ad) => debugPrint('[AdMobSample] Banner closed'),
        onAdImpression: (ad) {
          debugPrint('[AdMobSample] Banner impression');
        },
        onAdClicked: (ad) => debugPrint('[AdMobSample] Banner clicked'),
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          debugPrint(
            '[AdMobSample] Banner paid: $valueMicros $currencyCode '
            '${precision.name}',
          );
        },
      ),
    )..load();
  }

  void _loadInterstitial() {
    final adUnitId = _interstitialId;
    if (adUnitId.isEmpty) return;

    debugPrint('[AdMobSample] Interstitial load start: $adUnitId');
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobSample] Interstitial loaded: ${ad.adUnitId}');
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            debugPrint(
              '[AdMobSample] Interstitial paid: $valueMicros '
              '$currencyCode ${precision.name}',
            );
          };
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[AdMobSample] Interstitial showed');
            },
            onAdImpression: (ad) {
              debugPrint('[AdMobSample] Interstitial impression');
            },
            onAdClicked: (ad) {
              debugPrint('[AdMobSample] Interstitial clicked');
            },
            onAdWillDismissFullScreenContent: (ad) {
              debugPrint('[AdMobSample] Interstitial will dismiss');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdMobSample] Interstitial dismissed');
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdMobSample] Interstitial show failed: $error');
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitial();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobSample] Interstitial failed: $error');
        },
      ),
    );
  }

  void _loadRewarded() {
    final adUnitId = _rewardedId;
    if (adUnitId.isEmpty) return;

    debugPrint('[AdMobSample] Rewarded load start: $adUnitId');
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobSample] Rewarded loaded: ${ad.adUnitId}');
          ad.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            debugPrint(
              '[AdMobSample] Rewarded paid: $valueMicros '
              '$currencyCode ${precision.name}',
            );
          };
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              debugPrint('[AdMobSample] Rewarded showed');
            },
            onAdImpression: (ad) {
              debugPrint('[AdMobSample] Rewarded impression');
            },
            onAdClicked: (ad) => debugPrint('[AdMobSample] Rewarded clicked'),
            onAdWillDismissFullScreenContent: (ad) {
              debugPrint('[AdMobSample] Rewarded will dismiss');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdMobSample] Rewarded dismissed');
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdMobSample] Rewarded show failed: $error');
              ad.dispose();
              _rewardedAd = null;
              _loadRewarded();
            },
          );
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobSample] Rewarded failed: $error');
        },
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _bannerAd;
    return Scaffold(
      appBar: AppBar(title: const Text('AdMob minimal sample')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: _interstitialAd == null
                  ? null
                  : () {
                      debugPrint('[AdMobSample] Interstitial show requested');
                      _interstitialAd!.show();
                    },
              child: const Text('Show interstitial'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _rewardedAd == null
                  ? null
                  : () {
                      debugPrint('[AdMobSample] Rewarded show requested');
                      _rewardedAd!.show(
                        onUserEarnedReward: (ad, reward) {
                          debugPrint(
                            '[AdMobSample] Reward earned: '
                            '${reward.amount} ${reward.type}',
                          );
                        },
                      );
                    },
              child: const Text('Show rewarded'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: banner != null && _bannerLoaded
          ? SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            )
          : null,
    );
  }
}
