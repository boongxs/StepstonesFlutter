import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';

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

// dictionary of all unique tags
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()(); // enforce that tags are unique
}

// junction table linking media items to tags
class MediaTags extends Table {
  IntColumn get mediaId => integer().references(MediaItems, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  // ensure a media item can't be linked to the same tag twice
  @override
  Set<Column> get primaryKey => {mediaId, tagId};
}

// database class
@DriftDatabase(tables: [MediaItems, Tags, MediaTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async { // creates all three tables on fresh install
        await m.createAll();
      },
      // foreign key enforcement to ensure deleting a media item correctly executes
      beforeOpen: (details) async {
        await customStatement("PRAGMA foreign_keys = ON");
      },
    );
  }

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
  Future<int> getCountForFolder(String folderPath, {String? searchQuery}) async {
    final query = selectOnly(mediaItems)
      ..addColumns([mediaItems.id.count()])
      ..where(_buildSearchPredicate(folderPath, searchQuery));
    return query.map((row) => row.read(mediaItems.id.count())!).getSingle();
  }

  // get list of all 'hashedFileName' in a folder
  Future<List<String>> getFilenamesInFolder(String folderPath) {
    final query = selectOnly(mediaItems)
      ..addColumns([mediaItems.hashedFileName])
      ..where(mediaItems.mediaFolderPath.equals(folderPath));
    
    return query.map((row) => row.read(mediaItems.hashedFileName)!).get();
  }

  // batch delete items by filename
  Future<void> deleteMediaItems(List<String> filenames, String folderPath) {
    return transaction(() async {
      // find IDs of items to be deleted
      final query = selectOnly(mediaItems)
        ..addColumns([mediaItems.id])
        ..where(mediaItems.mediaFolderPath.equals(folderPath))
        ..where(mediaItems.hashedFileName.isIn(filenames));
      
      final ids = await query.map((row) => row.read(mediaItems.id)!).get();

      if (ids.isNotEmpty) {
        // delete all tag links
        await (delete(mediaTags)..where((t) => t.mediaId.isIn(ids))).go();

        // delete media items
        await (delete(mediaItems)..where((t) => t.id.isIn(ids))).go();

        // clean up tags that are no longer linked to any media items
        await customStatement(
          'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM media_tags)'
        );
      }
    });
  }

  // fetch a specific page of items (data virtualization)
  Future<List<MediaItem>> getPagedMediaItems(String folderPath, int limit, int offset, {String? searchQuery}) {
    final query = select(mediaItems)
      ..where((t) => _buildSearchPredicate(folderPath, searchQuery))
      ..limit(limit, offset: offset)
      ..orderBy([(t) => OrderingTerm(expression: t.id)]);
    return query.get();
  }

  Future<void> deleteMediaItem(int id) {
    return transaction(() async {
      // wipe all tag links for this item
      await (delete(mediaTags)..where((t) => t.mediaId.equals(id))).go();
      
      // delete the actual media item
      await (delete(mediaItems)..where((t) => t.id.equals(id))).go();
      
      // clean up tags that are no longer linked to any media items
      await customStatement(
        'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM media_tags)'
      );
    });
  }

  Future<void> updateMediaTags(int mediaId, String newTags) {
    return transaction(() async {
      // wipe all existing tag links for this specific media item
      await (delete(mediaTags)..where((t) => t.mediaId.equals(mediaId))).go();

      // parse the new tags input
      final words = newTags.trim().toLowerCase().split(RegExp(r"\s+"));

      // process each word
      for (final word in words) {
        if (word.isEmpty) continue;

        // check if tag exists in table
        final tagQuery = select(tags)..where((t) => t.name.equals(word));
        var existingTag = await tagQuery.getSingleOrNull();

        int currentTagId;
        if (existingTag == null) {
          // it doesn't exist, create it
          currentTagId = await into(tags).insert(
            TagsCompanion.insert(name: word),
          );
        } else {
          currentTagId = existingTag.id;
        }

        // create link in junction table
        await into(mediaTags).insert(
          MediaTagsCompanion.insert(
            mediaId: mediaId,
            tagId: currentTagId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }

      // delete orphaned tags
      await customStatement(
        'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM media_tags)'
      );
    });
  }

  // get all IDs in the current folder
  Future<List<int>> getAllIdsInFolder(String folderPath, {String? searchQuery}) {
    final query = select(mediaItems)
      ..where((t) => _buildSearchPredicate(folderPath, searchQuery));
    return query.map((row) => row.id).get();
  }

  // get specific MediaItems by ID list
  Future<List<MediaItem>> getMediaItemsByIds(List<int> ids) {
    return (select(mediaItems)
      ..where((t) => t.id.isIn(ids))
    ).get();
  }

  // batch delete from database
  Future<void> deleteMediaItemsById(List<int> ids) {
    return transaction(() async {
      // wipe all tag links for these media items
      await (delete(mediaTags)..where((t) => t.mediaId.isIn(ids))).go();

      // delete actual media items
      await (delete(mediaItems)..where((t) => t.id.isIn(ids))).go();

      // clean up tags that no longer have any media items linked to them
      await customStatement(
        'DELETE FROM tags WHERE id NOT IN (SELECT tag_id FROM media_tags)'
      );
    });
  }

  // fetch full media items by filenames (for ghost cleanup)
  Future<List<MediaItem>> getMediaItemsByFilenames(List<String> filenames, String folderPath) {
    return (select(mediaItems)
      ..where((t) => t.mediaFolderPath.equals(folderPath))
      ..where((t) => t.hashedFileName.isIn(filenames))
    ).get();
  }

  Future<void> updateThumbnail(String hashedFileName, String? newThumbnailPath) {
    return (update(mediaItems)
      ..where((t) => t.hashedFileName.equals(hashedFileName))
    ).write(MediaItemsCompanion(
      thumbnailPath: Value(newThumbnailPath),
    ));
  }

  // reconstructs space-separated string for edit tags dialog and bundler
  Future<String> getTagsForMediaItem(int mediaId) async {
    final query = select(tags).join([
      innerJoin(mediaTags, mediaTags.tagId.equalsExp(tags.id))
    ])..where(mediaTags.mediaId.equals(mediaId));

    final results = await query.get();

    return results.map((row) => row.readTable(tags).name).join(" ");
  }

  Expression<bool> _buildSearchPredicate(String folderPath, String? searchQuery) {
    Expression<bool> predicate = mediaItems.mediaFolderPath.equals(folderPath);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final terms = searchQuery.trim().toLowerCase().split(RegExp(r'\s+'));

      for (final term in terms) {
        if (term.isEmpty) continue;

        final subquery = selectOnly(mediaTags).join([
          innerJoin(tags, tags.id.equalsExp(mediaTags.tagId))
        ])
        ..addColumns([mediaTags.mediaId])
        ..where(mediaTags.mediaId.equalsExp(mediaItems.id) & tags.name.contains(term));

        predicate = predicate & existsQuery(subquery);
      }
    }

    return predicate;
  }
}

// connection helper
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = Directory(AppConstants.appSupportPath);

    // ensure folder exists
    if (!await dbFolder.exists()) {
      await dbFolder.create(recursive: true);
    }

    final file = File(p.join(dbFolder.path, "stepstones_flt.sqlite"));
    return NativeDatabase.createInBackground(file);
  });
}