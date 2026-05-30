import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';
import '../services/ad_mob_logger.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  AdSize? _adSize;
  Orientation? _currentOrientation;
  int? _currentWidth;

  String get _adUnitId => AdMobConfig.current.bannerAdUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_currentOrientation == orientation && _currentWidth == width) return;
    _currentOrientation = orientation;
    _currentWidth = width;
    _loadAd(width);
  }

  Future<void> _loadAd(int width) async {
    await _bannerAd?.dispose();
    if (!mounted) return;
    setState(() {
      _bannerAd = null;
      _isLoaded = false;
      _adSize = null;
    });

    final adUnitId = _adUnitId;
    if (adUnitId.isEmpty) {
      AdMobLogger.skipped('Banner ad skipped: ADMOB_BANNER_ID is empty.');
      return;
    }

    if (width <= 0) {
      AdMobLogger.skipped('Banner ad skipped: available width is $width.');
      return;
    }

    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width) ??
        AdSize.banner;
    if (!mounted) return;

    AdMobLogger.loadStarted(format: 'Banner', adUnitId: adUnitId);

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          final bannerAd = ad as BannerAd;
          AdMobLogger.loadSucceeded(format: 'Banner', ad: bannerAd);
          setState(() {
            _bannerAd = bannerAd;
            _isLoaded = true;
            _adSize = size;
          });
        },
        onAdFailedToLoad: (ad, error) {
          AdMobLogger.loadFailed(
            format: 'Banner',
            adUnitId: adUnitId,
            error: error,
          );
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _adSize = null;
          });
        },
        onAdOpened: (ad) {
          AdMobLogger.lifecycle('Banner ad opened. adUnitId=${ad.adUnitId}');
        },
        onAdWillDismissScreen: (ad) {
          AdMobLogger.lifecycle(
            'Banner ad will dismiss screen. adUnitId=${ad.adUnitId}',
          );
        },
        onAdClosed: (ad) {
          AdMobLogger.lifecycle('Banner ad closed. adUnitId=${ad.adUnitId}');
        },
        onAdImpression: (ad) {
          AdMobLogger.lifecycle(
            'Banner ad impression. adUnitId=${ad.adUnitId}',
          );
        },
        onAdClicked: (ad) {
          AdMobLogger.lifecycle('Banner ad clicked. adUnitId=${ad.adUnitId}');
        },
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          AdMobLogger.paidEvent(
            format: 'Banner',
            ad: ad,
            valueMicros: valueMicros,
            precision: precision,
            currencyCode: currencyCode,
          );
        },
      ),
    );
    return _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded && _adSize != null) {
      return SizedBox(
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox();
  }
}
