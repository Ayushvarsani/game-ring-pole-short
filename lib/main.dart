import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/settings_cubit.dart';
import 'bloc/shop_cubit.dart';
import 'bloc/shop_state.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'theme/app_theme.dart';
// import 'services/analytics_service.dart'; // Uncomment when Firebase is configured

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AdService.instance.init();

  // Lock to portrait mode for optimal gameplay
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle());

  // ── Firebase initialization ──
  // Uncomment these lines when Firebase is configured:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // FirebaseAnalyticsService().initialize();

  runApp(const WaterSortApp());
}

class WaterSortApp extends StatefulWidget {
  const WaterSortApp({super.key});

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
            theme: AppTheme.materialTheme(activeTheme),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
