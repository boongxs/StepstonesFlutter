import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stepstones_flt/controllers/export_controller.dart';
import 'package:stepstones_flt/providers/status_card_provider.dart';

class MockStatusCardProvider extends Mock implements StatusCardProvider {}

void main() {
  late ExportController exportController;
  late MockStatusCardProvider mockStatus;

  setUp(() {
    mockStatus = MockStatusCardProvider();
    exportController = ExportController();
  });

  group("ExportController", () {
    test("exportBundle returns error if item list is empty", () async {
      final result = await exportController.exportBundle(
        itemsToExport: [],
        status: mockStatus,
      );

      expect(result.status, ExportStatus.error);
      expect(result.errorMessage, "No items selected.");

      verifyNever(() => mockStatus.startJob(any()));
    });
  });
}