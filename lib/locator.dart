import 'package:get_it/get_it.dart';
import 'services/logger_service.dart';
import 'services/folder_picker_service.dart';
import 'services/settings_service.dart';
import 'providers/main_provider.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<LogService>(() => LogService());
  getIt.registerLazySingleton<FolderPickerService>(() => FolderPickerService());
  getIt.registerLazySingleton<SettingsService>(() => SettingsService());

  getIt.registerFactory<MainProvider>(() => MainProvider(
    getIt<FolderPickerService>(),
    getIt<SettingsService>(),
  ));
}