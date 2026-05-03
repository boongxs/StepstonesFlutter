import 'package:get_it/get_it.dart';
import 'services/logger_service.dart';
import 'services/folder_picker_service.dart';
import 'services/settings_service.dart';
import 'services/file_picker_service.dart';
import 'services/file_service.dart';
import 'data/app_database.dart';
import 'controllers/export_controller.dart';
import 'services/media_utility_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<LogService>(() => LogService());
  getIt.registerLazySingleton<FolderPickerService>(() => FolderPickerService());
  getIt.registerLazySingleton<SettingsService>(() => SettingsService());
  getIt.registerLazySingleton<FilePickerService>(() => FilePickerService());
  getIt.registerLazySingleton<FileService>(() => FileService());
  getIt.registerLazySingleton<ExportController>(() => ExportController());

  getIt.registerLazySingleton<MediaUtilityService>(() => MediaUtilityService());
}