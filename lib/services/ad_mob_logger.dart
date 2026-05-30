import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobLogger {
  const AdMobLogger._();

  static void mobileAdsInitialized(InitializationStatus status) {
    _log('Mobile Ads SDK initialized successfully.');

    if (status.adapterStatuses.isEmpty) {
      _log('Initialization adapterStatuses is empty.');
      return;
    }

    for (final entry in status.adapterStatuses.entries) {
      final adapter = entry.value;
      _log(
        'Adapter ${entry.key}: state=${adapter.state.name}, '
        'latency=${adapter.latency}s, description=${adapter.description}',
      );
    }
  }

  static void requestConfigurationApplied({
    required bool testDeviceModeEnabled,
    required List<String> testDeviceIds,
  }) {
    _log(
      'RequestConfiguration applied. '
      'testDeviceModeEnabled=$testDeviceModeEnabled, '
      'testDeviceIds=${testDeviceIds.join(',')}',
    );
  }

  static void loadStarted({required String format, required String adUnitId}) {
    _log('$format load started. adUnitId=$adUnitId');
  }

  static void loadSucceeded({required String format, required Ad ad}) {
    _log('$format load succeeded. adUnitId=${ad.adUnitId}');
    _logResponseInfo(format, ad.responseInfo);
  }

  static void loadFailed({
    required String format,
    required String adUnitId,
    required LoadAdError error,
  }) {
    _log(
      '$format load failed. adUnitId=$adUnitId, '
      'code=${error.code}, domain=${error.domain}, message=${error.message}',
    );
    _logResponseInfo(format, error.responseInfo);
  }

  static void showStarted({required String format, required String adUnitId}) {
    _log('$format show requested. adUnitId=$adUnitId');
  }

  static void showFailed({
    required String format,
    required String adUnitId,
    required AdError error,
  }) {
    _log(
      '$format show failed. adUnitId=$adUnitId, '
      'code=${error.code}, domain=${error.domain}, message=${error.message}',
    );
  }

  static void paidEvent({
    required String format,
    required Ad ad,
    required double valueMicros,
    required PrecisionType precision,
    required String currencyCode,
  }) {
    _log(
      '$format paid event. adUnitId=${ad.adUnitId}, '
      'valueMicros=$valueMicros, precision=${precision.name}, '
      'currencyCode=$currencyCode',
    );
  }

  static void skipped(String message) {
    _log(message);
  }

  static void lifecycle(String message) {
    _log(message);
  }

  static void _logResponseInfo(String format, ResponseInfo? responseInfo) {
    if (responseInfo == null) {
      _log('$format responseInfo=null');
      return;
    }

    _log(
      '$format responseInfo: responseId=${responseInfo.responseId}, '
      'mediationAdapter=${responseInfo.mediationAdapterClassName}, '
      'loadedAdapter=${responseInfo.loadedAdapterResponseInfo?.adapterClassName}, '
      'responseExtras=${responseInfo.responseExtras}',
    );

    final adapterResponses = responseInfo.adapterResponses;
    if (adapterResponses == null || adapterResponses.isEmpty) return;

    for (final adapter in adapterResponses) {
      _log(
        '$format adapterResponse: adapter=${adapter.adapterClassName}, '
        'latency=${adapter.latencyMillis}ms, '
        'source=${adapter.adSourceName}, '
        'error=${adapter.adError}',
      );
    }
  }

  static void _log(String message) {
    debugPrint('[AdMob] $message');
  }
}
