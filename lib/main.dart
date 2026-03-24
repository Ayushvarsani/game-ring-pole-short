import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/settings_cubit.dart';
import 'bloc/shop_cubit.dart';
import 'theme/app_theme.dart';
// import 'services/analytics_service.dart'; // Uncomment when Firebase is configured

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for optimal gameplay
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.systemNavColor,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Firebase initialization ──
  // Uncomment these lines when Firebase is configured:
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // FirebaseAnalyticsService().initialize();

  runApp(const WaterSortApp());
}

class WaterSortApp extends StatelessWidget {
  const WaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => ShopCubit()),
      ],
      child: MaterialApp(
        title: 'Water Sort Puzzle',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppTheme.bgDark,
          fontFamily: 'Roboto',
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accentPrimary,
            secondary: AppTheme.accentSecondary,
            surface: AppTheme.bgLight,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
