import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/providers/theme_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'shared/models/trip.dart';
import 'shared/models/vehicle.dart';
import 'shared/models/odometer_log.dart';

late Isar isar;
late SharedPreferences prefs;

void main() async {
  // 1. Capture Flutter framework errors (build, layout, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('\x1B[31m[FLUTTER FRAMEWORK CRASH]\x1B[0m');
    debugPrint('\x1B[33mException: ${details.exception}\x1B[0m');
    debugPrint('\x1B[37mStack Trace: ${details.stack}\x1B[0m');
  };

  // 2. Capture asynchronous errors (not caught by Flutter framework)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('\x1B[31m[ASYNC ERROR / CRASH]\x1B[0m');
    debugPrint('\x1B[33mError: $error\x1B[0m');
    debugPrint('\x1B[37mStack Trace: $stack\x1B[0m');
    return true; // Return true to indicate the error was handled
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Custom Error UI for development (shows red screen with details)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red[900],
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bug_report, color: Colors.white, size: 50),
              const SizedBox(height: 10),
              const Text(
                'Aurora Crashed',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Stack Trace:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                details.stack.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  };
  
  // Initialize SharedPreferences
  prefs = await SharedPreferences.getInstance();
  
  // Initialize Notifications
  await NotificationService.init();
  
  // Initialize Isar
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [TripSchema, VehicleSchema, OdometerLogSchema],
    directory: dir.path,
  );

  runApp(
    const ProviderScope(
      child: AuroraApp(),
    ),
  );
}

class AuroraApp extends ConsumerWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final themeMode = ref.watch(themeProvider);
    
    Widget homeScreen;
    if (!onboardingComplete) {
      homeScreen = const OnboardingScreen();
    } else {
      homeScreen = const DashboardScreen();
    }

    return MaterialApp(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: homeScreen,
    );
  }
}
