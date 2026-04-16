# color_short

A new Flutter project.

## Environment Configuration

This app loads runtime configuration with `flutter_dotenv`.

1. Copy `.env.example` to `.env`.
2. Keep `APP_ENV=dev` while validating test ads. Set `APP_ENV=prod` only when
   using live IDs in a release-style build.
3. Run the app with the default `.env` file:

```sh
flutter run
```

4. Select another env file with a Dart define when needed:

```sh
flutter run --dart-define=ENV=.env.dev
flutter run --dart-define=ENV=.env.prod
flutter build apk --dart-define=ENV=.env.prod
```

When `APP_ENV=dev`, keep Google test ad unit IDs in the selected env file.
When `APP_ENV=prod`, use only live values for the target platform:

- `ADMOB_APP_ID_ANDROID`
- `ADMOB_APP_ID_IOS`
- `ADMOB_BANNER_ID_ANDROID`
- `ADMOB_INTERSTITIAL_ID_ANDROID`
- `ADMOB_REWARDED_ID_ANDROID`
- `ADMOB_BANNER_ID_IOS`
- `ADMOB_INTERSTITIAL_ID_IOS`
- `ADMOB_REWARDED_ID_IOS`

The legacy generic keys `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`, and
`ADMOB_REWARDED_ID` are still accepted as fallbacks, but Android and iOS ad
unit IDs are not interchangeable.

Android reads the same selected env file when filling the AdMob manifest
placeholder. If you build the Android project directly with Gradle, pass the
same env file:

```sh
./gradlew assembleRelease -PENV=.env.prod
```

iOS reads `GADApplicationIdentifier` from `ios/Runner/Info.plist`, which is
filled by `ios/Flutter/Debug.xcconfig` or `ios/Flutter/Release.xcconfig`.
Before a real iOS run or build, set `ADMOB_APP_ID_IOS` in the active xcconfig
to the iOS AdMob app ID from AdMob. The Dart env file still controls the iOS
banner, interstitial, and rewarded ad unit IDs.

The real `.env*` files are gitignored. Keep `.env.example` as the safe template
and do not commit production values.

If `APP_ENV=prod` logs live ad unit IDs but ads still do not fill, check AdMob
readiness before changing app code: app approval/review status, ad unit age,
policy or serving limits, app-ads.txt setup, account readiness, and testing on a
real physical device with a production build.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
