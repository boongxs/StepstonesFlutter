import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:stepstones_flt/controllers/selection_controller.dart';
import 'package:stepstones_flt/controllers/session_controller.dart';
import 'package:stepstones_flt/controllers/gallery_controller.dart';
import 'package:stepstones_flt/data/app_database.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockSessionController extends Mock implements SessionController {}
class MockGalleryController extends Mock implements GalleryController {}

void main() {
  late SelectionController selectionController;
  late MockAppDatabase mockDb;
  late MockSessionController mockSession;
  late MockGalleryController mockGallery;

  setUp(() {
    mockDb = MockAppDatabase();
    mockSession = MockSessionController();
    mockGallery = MockGalleryController();

    // whenever controller asks for total item count, pretend there are 10 media items
    when(() => mockGallery.totalItemCount).thenReturn(10);

    selectionController = SelectionController(
      mockDb,
      mockSession,
      mockGallery,
    );
  });

  group("SelectionController - Core Logic", () {
    test("Initial state should have selection mode disabled", () {
      expect(selectionController.isSelectionMode, false);
      expect(selectionController.selectedCount, 0);
    });

    test("toggleSelectionMode should flip state and notify UI", () {
      bool wasNotified = false;
      selectionController.addListener(() {
        wasNotified = true;
      });

      selectionController.toggleSelectionMode();

      expect(selectionController.isSelectionMode, true);
      expect(wasNotified, true, reason: "UI was not notified of state change");
    });

    test("toggleItem should add item to selection list", () {
      selectionController.toggleItem(123);

      expect(selectionController.isItemSelected(123), true);
      expect(selectionController.selectedCount, 1);
    });

    test("toggleItem should remove item if already selected", () {
      selectionController.toggleItem(123); // select it once

      selectionController.toggleItem(123); // select again to unselect

      expect(selectionController.isItemSelected(123), false);
      expect(selectionController.selectedCount, 0);
    });
  });
}