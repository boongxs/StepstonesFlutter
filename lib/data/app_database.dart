import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// database schema
class MediaItems extends Table {
  // primary key
  IntColumn get id => integer().autoIncrement()();

  TextColumn get fileHash => text().withLength(min: 1)();
  TextColumn get hashedFileName => text()();
  TextColumn get mediaFolderPath => text()();
  TextColumn get originalFileName => text()();
  TextColumn get fileType => text()();
  TextColumn get tags => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get duration => integer().nullable()();
  IntColumn get width => integer().withDefault(const Constant(0))();
  IntColumn get height => integer().withDefault(const Constant(0))();

  // helper to prevent duplicate entries: fileHash + mediaFolderPath must be unique
  @override
  List<Set<Column>> get uniqueKeys => [
    {fileHash, mediaFolderPath},
  ];
}

// database class
@DriftDatabase(tables: [MediaItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // insert a new item
  Future<int> insertMediaItem(MediaItemsCompanion item) {
    return into(mediaItems).insert(item);
  }

  // get all items for specific folder currently selected
  Future<List<MediaItem>> getItemsInFolder(String folderPath) {
    return (select(mediaItems)..where((t) => t.mediaFolderPath.equals(folderPath))).get();
  }

  // check if hash already exists in media folder
  Future<MediaItem?> getByHash(String hash, String folderPath) {
    return (select(mediaItems)
      ..where((t) => t.fileHash.equals(hash))
      ..where((t) => t.mediaFolderPath.equals(folderPath))
    ).getSingleOrNull();
  }

  // count items in a specific folder
  Future<int> getCountForFolder(String folderPath) async {
    final countExp = mediaItems.id.count();
    final query = selectOnly(mediaItems)
      ..addColumns([countExp])
      ..where(mediaItems.mediaFolderPath.equals(folderPath));

    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  // get list of all 'hashedFileName' in a folder
  Future<List<String>> getFilenamesInFolder(String folderPath) {
    final query = selectOnly(mediaItems)
      ..addColumns([mediaItems.hashedFileName])
      ..where(mediaItems.mediaFolderPath.equals(folderPath));
    
    return query.map((row) => row.read(mediaItems.hashedFileName)!).get();
  }

  // batch delete items
  Future<int> deleteMediaItems(List<String> filenames, String folderPath) {
    return (delete(mediaItems)
      ..where((t) => t.mediaFolderPath.equals(folderPath))
      ..where((t) => t.hashedFileName.isIn(filenames))
    ).go();
  }
}

// connection helper
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();

    // ensure folder exists
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }

    final file = File(p.join(dbFolder.path, 'stepstones_flt.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}