# mindcolorpour

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

## Local Notifications

This game uses a fully local notification system. It does not use Firebase,
remote push notifications, or a backend.

Implementation files:

- `lib/notifications/notification_template.dart`
- `lib/notifications/mock_notifications.dart`
- `lib/notifications/notification_storage.dart`
- `lib/notifications/notification_service.dart`
- `lib/main.dart` for startup initialization and payload routing

Packages:

- `flutter_local_notifications`
- `timezone`
- `shared_preferences`

Startup flow:

1. `main()` initializes `NotificationService`.
2. Android/iOS notification permissions are requested locally.
3. Shared notification history is loaded from `shared_preferences`.
4. Pending local notifications are inspected.
5. Outdated or invalid scheduled reminders owned by the game are cancelled.
6. The next fixed reminder slots are scheduled with `zonedSchedule`.

Scheduling rules:

- The game owns three daily reminder IDs.
- Fixed reminder times are 3:00 PM, 7:00 PM, and 9:30 PM in the device's
  local time.
- At startup, the service schedules the remaining fixed times for today.
- If all three times for today have passed, the service schedules tomorrow's
  3:00 PM, 7:00 PM, and 9:30 PM reminders.
- The service only keeps future reminders needed for the next active schedule.
- The same template id is never selected twice in a row.
- The picker avoids the last 5 recently used template ids when possible.
- The reminders scheduled for the same day must use different template ids.
- If the rolling history exhausts eligible templates, reuse is allowed after
  the recent-history preference is relaxed, but same-day duplicates are still
  blocked.
- Payloads are encoded as JSON with `templateId`, `category`, `route`, and
  `scheduledFor`.

Supported payload routes:

- `/home`
- `/game`
- `/shop`
- `/settings`

For scheduled local testing from app code, call:

```dart
await NotificationService.instance.debugScheduleForNextMinute();
```

To test a specific template:

```dart
await NotificationService.instance.debugScheduleForNextMinute(
  templateId: 'daily_puzzle_001',
);
```

For an immediate heads-up notification during development, call:

```dart
await NotificationService.instance.debugShowInstantNotification();
```

Android setup is in `android/app/src/main/AndroidManifest.xml`:

- `POST_NOTIFICATIONS`
- `RECEIVE_BOOT_COMPLETED`
- `ScheduledNotificationReceiver`
- `ScheduledNotificationBootReceiver`

The service uses `AndroidScheduleMode.inexactAllowWhileIdle`, so it does not
request exact alarm permissions.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
