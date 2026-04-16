import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/game_cubit.dart';
import 'bloc/settings_cubit.dart';
import 'bloc/shop_cubit.dart';
import 'bloc/shop_state.dart';
import 'config/app_config.dart';
import 'notifications/notification_service.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/level_progress_service.dart';
import 'theme/app_theme.dart';
// import 'services/analytics_service.dart'; // Uncomment when Firebase is configured

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appNavigatorKey = GlobalKey<NavigatorState>();

  await AppConfig.load();
  await AdService.instance.init();
  await NotificationService.instance.init(navigatorKey: appNavigatorKey);
  await NotificationService.instance.requestPermissions();
  await NotificationService.instance.loadNotificationHistory();
  await NotificationService.instance
      .cancelInvalidOrOutdatedPendingNotification();
  await NotificationService.instance.scheduleNextDailyNotification();
  final initialNotificationRoute = NotificationService.instance
      .takeInitialPayloadRoute();

  // Lock to portrait mode for optimal gameplay
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle());

  // Firebase initialization
  // Uncomment these lines when Firebase is configured:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // FirebaseAnalyticsService().initialize();

  runApp(
    WaterSortApp(
      navigatorKey: appNavigatorKey,
      initialNotificationRoute: initialNotificationRoute,
    ),
  );
}

class WaterSortApp extends StatefulWidget {
  const WaterSortApp({
    super.key,
    required this.navigatorKey,
    this.initialNotificationRoute,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String? initialNotificationRoute;

  @override
  State<WaterSortApp> createState() => _WaterSortAppState();
}

class _WaterSortAppState extends State<WaterSortApp>
    with WidgetsBindingObserver {
  // We keep the cubit at the top level so lifecycle callbacks reach it.
  late final SettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _settingsCubit = SettingsCubit();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.routeQueuedPayloadIfAny();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _settingsCubit.onAppPaused();
      case AppLifecycleState.resumed:
        _settingsCubit.onAppResumed();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _settingsCubit),
        BlocProvider(create: (_) => ShopCubit()),
      ],
      child: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          final activeTheme = state.selectedTheme.config;
          SystemChrome.setSystemUIOverlayStyle(
            AppTheme.overlayStyle(activeTheme),
          );

          return MaterialApp(
            title: 'Water Sort Puzzle',
            debugShowCheckedModeBanner: false,
            navigatorKey: widget.navigatorKey,
            theme: AppTheme.materialTheme(activeTheme),
            home: SplashScreen(initialRoute: widget.initialNotificationRoute),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      '/home' => _materialRoute(settings, const HomeScreen()),
      '/game' => _materialRoute(settings, const _GameRouteLoader()),
      '/shop' => _materialRoute(settings, const ShopScreen()),
      '/settings' => _materialRoute(settings, const SettingsScreen()),
      _ => null,
    };
  }

  MaterialPageRoute<dynamic> _materialRoute(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => child,
    );
  }
}

class _GameRouteLoader extends StatelessWidget {
  const _GameRouteLoader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: LevelProgressService.getNextLevelToPlay(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          create: (_) => GameCubit(initialLevel: snapshot.data!),
          child: const GameScreen(),
        );
      },
    );
  }
}
