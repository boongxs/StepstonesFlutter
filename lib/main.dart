import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stepstones_flt/controllers/gallery_controller.dart';
import 'package:stepstones_flt/controllers/selection_controller.dart';
import 'package:stepstones_flt/controllers/session_controller.dart';
import 'package:stepstones_flt/controllers/sync_controller.dart';
import 'package:stepstones_flt/data/app_database.dart';
import 'package:stepstones_flt/providers/status_card_provider.dart';
import 'providers/logs_view_provider.dart';
import 'locator.dart';
import 'services/logger_service.dart';
import 'screens/main_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'services/media_action_service.dart';
import 'package:path_provider/path_provider.dart';
import 'constants.dart';
import 'package:stepstones_flt/controllers/settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // initialize flutter engine
  MediaKit.ensureInitialized(); // initialize media_kit package

  final dir = await getApplicationSupportDirectory();
  AppConstants.appSupportPath = dir.path;

  await LogService.initialize(); // initialize logger

  setupLocator(); // register all singletons (services...)

  LogService.i('Application starting up...');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),

        ChangeNotifierProvider(
          create: (_) => SessionController(),
          lazy: false
        ),

        ChangeNotifierProvider(create: (_) => StatusCardProvider()),
        ChangeNotifierProvider(create: (_) => LogsViewProvider()),

        ChangeNotifierProvider(create: (context) => GalleryController(
          getIt<AppDatabase>(),
          context.read<SessionController>(),
        )),

        ChangeNotifierProvider(create: (context) => SelectionController(
          getIt<AppDatabase>(), 
          context.read<SessionController>(), 
          context.read<GalleryController>(),
        )),

        ChangeNotifierProvider(
          create: (context) => SyncController(
            getIt<AppDatabase>(), 
            context.read<SessionController>(), 
            context.read<GalleryController>(), 
            context.read<StatusCardProvider>(),
          ),
          lazy: false,
        ),
      ],
      child: const MainApp(),
    )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    LogService.d("Building MyApp widget");

    final settings = context.watch<SettingsController>();

    return MaterialApp(
      scaffoldMessengerKey: MediaActionService.rootMessengerKey,
      title: "Stepstones",
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF282828),
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.themeColor,
          brightness: Brightness.dark,
        ),

        useMaterial3: true,
      ),

      home: const MainScreen(), // start building Main Screen
    );
  }
}
