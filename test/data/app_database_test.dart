import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepstones_flt/data/app_database.dart';

void main() {
  late AppDatabase db;

  // runs before each test to initialize a fresh in-memory database
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  // runs after each test: closes database to free up memory
  tearDown(() async {
    await db.close();
  });

  // helper method to quickly insert fake media item and return its ID
  Future<int> seedMediaItem(String folderPath, String fileName) async {
    return await db.into(db.mediaItems).insert(
      MediaItemsCompanion.insert(
        fileHash: fileName.split(".").first,
        hashedFileName: fileName,
        mediaFolderPath: folderPath,
        originalFileName: fileName,
        fileType: "image",
        width: const Value(100),
        height: const Value(100),
        duration: const Value(0),
      ),
    );
  }

  group("AppDatabase Tagging System Tests", () {
    test("Saving and retrieving tags works correctly", () async {
      final id = await seedMediaItem("C:/photos", "test.jpg");

      // save tags
      await db.updateMediaTags(id, "dog nature outdoor");

      // retrieve tags
      final tagsString = await db.getTagsForMediaItem(id);

      // verify
      expect(tagsString, contains("dog"));
      expect(tagsString, contains("nature"));
      expect(tagsString, contains("outdoor"));
    });

    test("Updating tags replaces old tags instead of adding to them", () async {
      final id = await seedMediaItem("C:/photos", "test.jpg");

      // save initial tags
      await db.updateMediaTags(id, "dog cat");

      // overwrite them
      await db.updateMediaTags(id, "bird");

      final tagsString = await db.getTagsForMediaItem(id);

      // verify old tags are gone and only new one remains
      expect(tagsString, "bird");
    });

    test("Search filtering supports partial matching", () async {
      final folder = "C:/photos";
      final id1 = await seedMediaItem(folder, "1.jpg");
      final id2 = await seedMediaItem(folder, "2.jpg");
      final id3 = await seedMediaItem(folder, "3.jpg");

      await db.updateMediaTags(id1, "apple");
      await db.updateMediaTags(id2, "pineapple");
      await db.updateMediaTags(id3, "banana");

      // search for "apple"
      final count = await db.getCountForFolder(folder, searchQuery: "apple");
      final items = await db.getPagedMediaItems(folder, 10, 0, searchQuery: "apple");

      // verify it found both "apple" and "pineapple" but not "banana"
      expect(count, 2);
      expect(items.length, 2);

      final resultIds = items.map((i) => i.id).toList();
      expect(resultIds, containsAll([id1, id2]));
    });

    test("Multi-tag search filtering works regardless of order", () async {
      final folder = "C:/photos";
      final id1 = await seedMediaItem(folder, "1.jpg");
      final id2 = await seedMediaItem(folder, "2.jpg");

      // item 1 has both, item 2 only has one
      await db.updateMediaTags(id1, "nature dog outdoor");
      await db.updateMediaTags(id2, "dog");

      // user searched for two tags in different order than they were saved
      final query = "dog nature";

      final count = await db.getCountForFolder(folder, searchQuery: query);
      final itemIds = await db.getAllIdsInFolder(folder, searchQuery: query);

      // verify it finds only item 1, because item 2 is missing "nature"
      expect(count, 1);
      expect(itemIds.length, 1);
      expect(itemIds.first, id1);
    });

    test("Empty or null search queries return all items in folder", () async {
      final folder = "C:/photos";
      await seedMediaItem(folder, "1.jpg");
      await seedMediaItem(folder, "2.jpg");

      final countNull = await db.getCountForFolder(folder, searchQuery: null);
      final countEmpty = await db.getCountForFolder(folder, searchQuery: ' ');

      expect(countNull, 2);
      expect(countEmpty, 2);
    });
  });
}