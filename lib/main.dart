import 'package:flutter/material.dart';
import 'locator.dart';
import 'services/logger_service.dart';
import 'screens/main_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'services/media_action_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // initialize flutter engine
  MediaKit.ensureInitialized(); // initialize media_kit package

  await LogService.initialize(); // initialize logger

  setupLocator(); // register all singletons (services...)

  LogService.i('Application starting up...');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    LogService.d("Building MyApp widget");

    return MaterialApp(
      scaffoldMessengerKey: MediaActionService.rootMessengerKey,
      title: "Stepstones",
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF282828),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),

        useMaterial3: true,
      ),

      home: const MainScreen(), // start building Main Screen
    );
  }
}
