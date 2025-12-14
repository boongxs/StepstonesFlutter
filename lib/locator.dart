import 'package:get_it/get_it.dart';
import 'services/logger_service.dart';
import 'services/folder_picker_service.dart';
import 'services/settings_service.dart';
import 'services/file_picker_service.dart';
import 'services/file_service.dart';
import 'providers/main_provider.dart';
import 'providers/upload_status_provider.dart';
import 'data/app_database.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  getIt.registerLazySingleton<LogService>(() => LogService());
  getIt.registerLazySingleton<FolderPickerService>(() => FolderPickerService());
  getIt.registerLazySingleton<SettingsService>(() => SettingsService());
  getIt.registerLazySingleton<FilePickerService>(() => FilePickerService());
  getIt.registerLazySingleton<FileService>(() => FileService());
  getIt.registerLazySingleton<UploadStatusProvider>(() => UploadStatusProvider());

  getIt.registerFactory<MainProvider>(() => MainProvider(
    getIt<FolderPickerService>(),
    getIt<SettingsService>(),
    getIt<FilePickerService>(),
    getIt<FileService>(),
  ));
}