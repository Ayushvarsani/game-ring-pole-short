import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { dev, prod }

class AppConfig {
  const AppConfig._();

  static const String activeEnvFile = String.fromEnvironment(
    'ENV',
    defaultValue: '.env',
  );

  static Future<void> load() async {
    await dotenv.load(fileName: activeEnvFile, isOptional: false);
    AdMobConfig.loadFromEnv();
  }

  static Map<String, String> get values => dotenv.env;

  static String get appEnvValue =>
      _value('APP_ENV', fallback: 'dev').toLowerCase();

  static AppEnvironment get environment {
    return switch (appEnvValue) {
      'prod' || 'production' => AppEnvironment.prod,
      _ => AppEnvironment.dev,
    };
  }

  static bool get isProduction => environment == AppEnvironment.prod;

  static String get apiBaseUrl => _value('API_BASE_URL');

  static String env(String key, {String fallback = ''}) {
    return _value(key, fallback: fallback);
  }

  static String _value(String key, {String fallback = ''}) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }
}

class AdMobConfig {
  const AdMobConfig._({
    required this.appEnv,
    required this.isProduction,
    required this.targetPlatformName,
    required this.adMobAppIdAndroid,
    required this.adMobAppIdIos,
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.rewardedAdUnitId,
    required this.testDeviceModeEnabled,
    required this.testDeviceIds,
  });

  static late AdMobConfig _current;

  final String appEnv;
  final bool isProduction;
  final String targetPlatformName;
  final String adMobAppIdAndroid;
  final String adMobAppIdIos;
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String rewardedAdUnitId;
  final bool testDeviceModeEnabled;
  final List<String> testDeviceIds;

  static AdMobConfig get current => _current;

  static void loadFromEnv() {
    final isProduction = AppConfig.isProduction;
    final testDeviceIds = _splitCsv(AppConfig.env('ADMOB_TEST_DEVICE_IDS'));
    final config = AdMobConfig._(
      appEnv: AppConfig.appEnvValue,
      isProduction: isProduction,
      targetPlatformName: _targetPlatformName,
      adMobAppIdAndroid: AppConfig.env('ADMOB_APP_ID_ANDROID'),
      adMobAppIdIos: AppConfig.env('ADMOB_APP_ID_IOS'),
      bannerAdUnitId: _platformAdUnitId('ADMOB_BANNER_ID'),
      interstitialAdUnitId: _platformAdUnitId('ADMOB_INTERSTITIAL_ID'),
      rewardedAdUnitId: _platformAdUnitId('ADMOB_REWARDED_ID'),
      testDeviceModeEnabled: testDeviceIds.isNotEmpty,
      testDeviceIds: testDeviceIds,
    );

    _current = config;
    config.logSelectedConfig();
  }

  bool get hasBannerAdUnitId => bannerAdUnitId.isNotEmpty;

  bool get hasInterstitialAdUnitId => interstitialAdUnitId.isNotEmpty;

  bool get hasRewardedAdUnitId => rewardedAdUnitId.isNotEmpty;

  void logSelectedConfig() {
    debugPrint('[AdMobConfig] envFile=${AppConfig.activeEnvFile}');
    debugPrint('[AdMobConfig] APP_ENV=$appEnv');
    debugPrint('[AdMobConfig] production=$isProduction');
    debugPrint('[AdMobConfig] targetPlatform=$targetPlatformName');
    debugPrint('[AdMobConfig] testDeviceModeEnabled=$testDeviceModeEnabled');
    debugPrint('[AdMobConfig] testDeviceIds=${testDeviceIds.join(',')}');
    debugPrint('[AdMobConfig] admobAppIdAndroid=$adMobAppIdAndroid');
    debugPrint('[AdMobConfig] admobAppIdIos=$adMobAppIdIos');
    debugPrint('[AdMobConfig] bannerAdUnitId=$bannerAdUnitId');
    debugPrint('[AdMobConfig] interstitialAdUnitId=$interstitialAdUnitId');
    debugPrint('[AdMobConfig] rewardedAdUnitId=$rewardedAdUnitId');

    _logNativeAppId(
      'ADMOB_APP_ID_ANDROID',
      adMobAppIdAndroid,
      requiredForCurrentPlatform: targetPlatformName == 'android',
    );
    _logNativeAppId(
      'ADMOB_APP_ID_IOS',
      adMobAppIdIos,
      requiredForCurrentPlatform: targetPlatformName == 'ios',
    );
    _logAdUnitId('ADMOB_BANNER_ID', bannerAdUnitId);
    _logAdUnitId('ADMOB_INTERSTITIAL_ID', interstitialAdUnitId);
    _logAdUnitId('ADMOB_REWARDED_ID', rewardedAdUnitId);
  }

  static List<String> _splitCsv(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static String get _targetPlatformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  static String _platformAdUnitId(String baseKey) {
    final platformKey = _platformKey(baseKey);
    if (platformKey != baseKey) {
      final platformValue = AppConfig.env(platformKey);
      if (platformValue.isNotEmpty) return platformValue;
    }
    return AppConfig.env(baseKey);
  }

  static String _platformKey(String baseKey) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => '${baseKey}_ANDROID',
      TargetPlatform.iOS => '${baseKey}_IOS',
      _ => baseKey,
    };
  }

  void _logNativeAppId(
    String key,
    String value, {
    required bool requiredForCurrentPlatform,
  }) {
    if (value.isEmpty) {
      if (requiredForCurrentPlatform) {
        debugPrint(
          '[AdMobConfig] Missing $key while APP_ENV=$appEnv. '
          'Native Mobile Ads initialization can fail on $targetPlatformName.',
        );
      }
      return;
    }

    if (_looksLikePlaceholder(value)) {
      debugPrint(
        '[AdMobConfig] $key still looks like a placeholder. '
        'Replace it with the platform AdMob app ID.',
      );
      return;
    }

    if (!_looksLikeAdMobAppId(value)) {
      debugPrint(
        '[AdMobConfig] $key does not match ca-app-pub-################~##########.',
      );
    }
  }

  void _logAdUnitId(String baseKey, String value) {
    final platformKey = _platformKey(baseKey);
    final platformValue = AppConfig.env(platformKey);
    final fallbackValue = AppConfig.env(baseKey);

    if (platformKey != baseKey &&
        platformValue.isEmpty &&
        fallbackValue.isNotEmpty) {
      debugPrint(
        '[AdMobConfig] $platformKey is empty; using fallback $baseKey for '
        '$targetPlatformName. Android and iOS ad unit IDs are not '
        'interchangeable.',
      );
    }

    if (value.isEmpty) {
      debugPrint(
        '[AdMobConfig] Missing $platformKey while APP_ENV=$appEnv. '
        'This ad format will not load.',
      );
      return;
    }

    if (_looksLikePlaceholder(value)) {
      debugPrint(
        '[AdMobConfig] $platformKey/$baseKey still looks like a placeholder. '
        'This request will fail before it can fill.',
      );
      return;
    }

    if (!_looksLikeAdMobAdUnitId(value)) {
      debugPrint(
        '[AdMobConfig] $platformKey/$baseKey does not match '
        'ca-app-pub-################/##########.',
      );
    }
  }

  static bool _looksLikePlaceholder(String value) {
    final lower = value.toLowerCase();
    return lower.contains('xxxx') ||
        lower.contains('yyyy') ||
        lower.contains('####') ||
        lower == '_adunitid';
  }

  static bool _looksLikeAdMobAppId(String value) {
    return RegExp(r'^ca-app-pub-\d{16}~\d{10}$').hasMatch(value);
  }

  static bool _looksLikeAdMobAdUnitId(String value) {
    return RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(value);
  }
}
