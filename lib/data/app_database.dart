import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';
import '../models/media_sort_option.dart';

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
  TextColumn get perceptualHash => text().nullable()();
  TextColumn get date => text().nullable()();
  TextColumn get time => text().nullable()();

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

// pending near-duplicate review pairs
class PendingReviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('uploadedItemReviews')
  IntColumn get uploadedItemId => integer().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('matchedItemReviews')
  IntColumn get matchedItemId  => integer().references(MediaItems, #id, onDelete: KeyAction.cascade)();
  RealColumn get similarityPercent => real()();
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
@DriftDatabase(tables: [MediaItems, Tags, MediaTags, PendingReviews])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async { // creates all tables on fresh install
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 3) {
          final columns = await customSelect('PRAGMA table_info("media_items")').get();
          final hasColumn = columns.any((r) => r.read<String>('name') == 'perceptual_hash');
          if (!hasColumn) {
            await m.addColumn(mediaItems, mediaItems.perceptualHash);
          }
          await m.createTable(pendingReviews);
        }
        if (from < 4) {
          final cols = await customSelect('PRAGMA table_info("media_items")').get();
          final names = cols.map((r) => r.read<String>('name')).toSet();
          if (!names.contains('date')) await m.addColumn(mediaItems, mediaItems.date);
          if (!names.contains('time')) await m.addColumn(mediaItems, mediaItems.time);
        }
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
  Future<List<MediaItem>> getPagedMediaItems(
    String folderPath,
    int limit,
    int offset, {
    String? searchQuery,
    SortField sortField = SortField.dateAdded,
    SortDirection sortDirection = SortDirection.asc,
  }) {
    final query = select(mediaItems)
      ..where((t) => _buildSearchPredicate(folderPath, searchQuery))
      ..limit(limit, offset: offset)
      ..orderBy(_buildOrderBy(sortField, sortDirection));
    return query.get();
  }

  List<OrderingTerm Function(MediaItems)> _buildOrderBy(SortField field, SortDirection direction) {
    final mode = direction == SortDirection.asc ? OrderingMode.asc : OrderingMode.desc;
    switch (field) {
      case SortField.dateAdded:
        return [(t) => OrderingTerm(expression: t.id, mode: mode)];
      case SortField.mediaDate:
        return [
          (t) => OrderingTerm(expression: CustomExpression<int>('CASE WHEN date IS NULL THEN 1 ELSE 0 END')),
          (t) => OrderingTerm(expression: t.date, mode: mode),
        ];
      case SortField.fileType:
        return [(t) => OrderingTerm(
          expression: CustomExpression<int>(
            "CASE file_type WHEN 'image' THEN 0 WHEN 'gif' THEN 1 WHEN 'video' THEN 2 WHEN 'audio' THEN 3 ELSE 4 END"
          ),
        )];
    }
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

  // get all distinct tag names with item counts for the folder (for autocomplete)
  Future<List<({String name, int count})>> getTagNamesInFolder(String folderPath) {
    final countExpr = countAll();
    final query = selectOnly(tags)
      ..addColumns([tags.name, countExpr])
      ..join([
        innerJoin(mediaTags, mediaTags.tagId.equalsExp(tags.id)),
        innerJoin(mediaItems, mediaItems.id.equalsExp(mediaTags.mediaId)),
      ])
      ..where(mediaItems.mediaFolderPath.equals(folderPath))
      ..groupBy([tags.id])
      ..orderBy([OrderingTerm(expression: tags.name)]);
    return query.map((row) => (
      name: row.read(tags.name)!,
      count: row.read(countExpr)!,
    )).get();
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

  // reconstructs space-separated string for tags panel and bundler
  Future<String> getTagsForMediaItem(int mediaId) async {
    final query = select(tags).join([
      innerJoin(mediaTags, mediaTags.tagId.equalsExp(tags.id))
    ])..where(mediaTags.mediaId.equals(mediaId));

    final results = await query.get();

    return results.map((row) => row.readTable(tags).name).join(" ");
  }

  // --- Perceptual hash methods ---

  Future<void> updateMediaDateTime(int id, String? date, String? time) {
    return (update(mediaItems)..where((t) => t.id.equals(id)))
        .write(MediaItemsCompanion(
          date: Value(date),
          time: Value(time),
        ));
  }

  Future<void> updatePerceptualHash(int id, String hash) {
    return (update(mediaItems)..where((t) => t.id.equals(id))).write(
      MediaItemsCompanion(perceptualHash: Value(hash)),
    );
  }

  // image items in folder missing a perceptual hash (for backfill)
  Future<List<MediaItem>> getItemsNeedingPhash(String folderPath) {
    return (select(mediaItems)
      ..where((t) => t.mediaFolderPath.equals(folderPath))
      ..where((t) => t.fileType.equals('image'))
      ..where((t) => t.perceptualHash.isNull())
    ).get();
  }

  // all image items in folder that have a perceptual hash (for similarity comparison)
  Future<List<MediaItem>> getItemsWithPhash(String folderPath) {
    return (select(mediaItems)
      ..where((t) => t.mediaFolderPath.equals(folderPath))
      ..where((t) => t.fileType.equals('image'))
      ..where((t) => t.perceptualHash.isNotNull())
    ).get();
  }

  // --- PendingReviews methods ---

  Future<void> insertPendingReview(int uploadedItemId, int matchedItemId, double similarity) {
    return into(pendingReviews).insert(
      PendingReviewsCompanion.insert(
        uploadedItemId: uploadedItemId,
        matchedItemId: matchedItemId,
        similarityPercent: similarity,
      ),
    );
  }

  Future<List<PendingReview>> getPendingReviews() {
    return (select(pendingReviews)
      ..orderBy([
        (t) => OrderingTerm(expression: t.similarityPercent, mode: OrderingMode.desc),
      ])
    ).get();
  }

  Stream<List<PendingReview>> watchPendingReviews() {
    return (select(pendingReviews)
      ..orderBy([
        (t) => OrderingTerm(expression: t.similarityPercent, mode: OrderingMode.desc),
      ])
    ).watch();
  }

  Future<int> getPendingReviewCount() async {
    final query = selectOnly(pendingReviews)
      ..addColumns([pendingReviews.id.count()]);
    return query.map((row) => row.read(pendingReviews.id.count())!).getSingle();
  }

  Future<void> deletePendingReview(int id) {
    return (delete(pendingReviews)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deletePendingReviewsForUploadedItem(int uploadedItemId) {
    return (delete(pendingReviews)
      ..where((t) => t.uploadedItemId.equals(uploadedItemId))
    ).go();
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
        ..where(mediaTags.mediaId.equalsExp(mediaItems.id) & tags.name.equals(term));

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