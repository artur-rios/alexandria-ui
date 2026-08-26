import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_ui/features/catalog/domain/file_details.dart';
import 'package:alexandria_ui/features/catalog/domain/file_stamp.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/editing/application/text_editor_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_text_content_gateway.dart';

/// A file that changed under the editor (UC-33 AF-05).
///
/// Its own test rather than another case in the screen's: the question is
/// which change signal the controller compares, and the screen has nothing to
/// say about that.
void main() {
  const uuid = '4c2b9e10-7d3a-4b62-8e15-2f6a9c0d3b41';

  /// A modification time [hour] hours into the day, for a test that only cares
  /// that two of them differ.
  DateTime t(int hour) => DateTime.utc(2026, 8, 23, hour);

  /// The editor open on one file, dirty, and ready to save.
  ///
  /// Asynchronous because opening reads the content through the gateway, and a
  /// save arriving before that read landed is not what any of these tests is
  /// about. Dirty because AF-01 answers a clean save before AF-05 ever runs.
  Future<EditorHarness> openEditor({
    required FileStamp openedWith,
    required FileStamp onDisk,
  }) => EditorHarness.open(uuid: uuid, openedWith: openedWith, onDisk: onDisk);

  // The regression, pinned. Before this task both content hashes were the
  // empty string — indexing computes none — so the comparison was vacuous and
  // the save went through as though nothing had happened.
  test(
    'GivenAFileWithNoHash_WhenItChangedOnDisk_ThenTheSaveIsRefused',
    () async {
      final harness = await openEditor(
        openedWith: const FileStamp(sizeBytes: 120),
        onDisk: const FileStamp(sizeBytes: 340),
      );

      await harness.controller.save();

      expect(harness.controller.state.question, EditorQuestion.changedOnDisk);
      expect(harness.gateway.writes, isEmpty);
    },
  );

  test('GivenAnUnchangedFile_WhenSaved_ThenItIsWritten', () async {
    final harness = await openEditor(
      openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
      onDisk: FileStamp(sizeBytes: 120, mtime: t(1)),
    );

    await harness.controller.save();

    expect(harness.gateway.writes, hasLength(1));
    expect(harness.controller.state.question, EditorQuestion.none);
  });

  // mtime alone moving is a change even at identical length — that is the
  // common shape of an external edit.
  test('GivenOnlyTheMtimeMoved_WhenSaved_ThenTheSaveIsRefused', () async {
    final harness = await openEditor(
      openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
      onDisk: FileStamp(sizeBytes: 120, mtime: t(2)),
    );

    await harness.controller.save();

    expect(harness.controller.state.question, EditorQuestion.changedOnDisk);
    expect(harness.gateway.writes, isEmpty);
  });

  test(
    'GivenAWrittenFile_WhenSavedAgain_ThenItComparesAgainstTheNewStamp',
    () async {
      // The editor's own write moves the file: its size and mtime are not the
      // ones it was opened with any more. If the baseline did not move with
      // it, the second save would read its own work as somebody else's.
      final harness = await openEditor(
        openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
        onDisk: FileStamp(sizeBytes: 120, mtime: t(1)),
      );
      harness.writeReturns = FileStamp(sizeBytes: 200, mtime: t(2));

      await harness.controller.save();
      harness.onDisk = FileStamp(sizeBytes: 200, mtime: t(2));
      harness.edit('# Again');
      await harness.controller.save();

      expect(harness.gateway.writes, hasLength(2));
      expect(harness.controller.state.question, EditorQuestion.none);
    },
  );

  // The tolerance the hash comparison had, kept: the core is the authority on
  // what is on disk, and a reading nobody could take is not a conflict.
  test('GivenAnUnreadableStamp_WhenSaved_ThenTheSaveIsNotBlocked', () async {
    final harness = await openEditor(
      openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
      onDisk: const FileStamp(),
    );

    await harness.controller.save();

    expect(harness.gateway.writes, hasLength(1));
  });

  test(
    'GivenTheCatalogRefusesTheRead_WhenSaved_ThenTheSaveIsNotBlocked',
    () async {
      final harness = await openEditor(
        openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
        onDisk: FileStamp(sizeBytes: 999, mtime: t(9)),
      );
      harness.catalog.details[uuid] = const FileDetailsOutcome.failed(
        failure: Failure.disk(
          family: CoreStatusFamily.file,
          code: FILE_ERR_DISK,
        ),
      );

      await harness.controller.save();

      expect(harness.gateway.writes, hasLength(1));
    },
  );
}

/// An open, dirty editor over fake gateways.
class EditorHarness {
  EditorHarness._({
    required this.container,
    required this.gateway,
    required this.catalog,
    required this.uuid,
  });

  /// Opens the editor on a file whose record carries [openedWith], with
  /// [onDisk] as what the catalog reports for it now.
  static Future<EditorHarness> open({
    required String uuid,
    required FileStamp openedWith,
    required FileStamp onDisk,
  }) async {
    final catalog = FakeCatalogGateway();
    final gateway = FakeTextContentGateway();

    final container = ProviderContainer(
      overrides: [
        catalogGatewayProvider.overrideWithValue(catalog),
        textContentGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    final harness = EditorHarness._(
      container: container,
      gateway: gateway,
      catalog: catalog,
      uuid: uuid,
    )..onDisk = onDisk;

    await harness.controller.open(
      uuid: uuid,
      name: 'Notes.md',
      stamp: openedWith,
    );
    harness.edit('# Mine');

    return harness;
  }

  /// The container the controller lives in.
  final ProviderContainer container;

  /// The gateway the writes go through.
  final FakeTextContentGateway gateway;

  /// The catalog the save asks what is on disk now.
  final FakeCatalogGateway catalog;

  /// The file the editor is open on.
  final String uuid;

  /// The controller under test.
  TextEditorController get controller =>
      container.read(textEditorControllerProvider.notifier);

  /// What the catalog reports for the file now.
  set onDisk(FileStamp stamp) =>
      catalog.details[uuid] = FileDetailsOutcome.read(
        details: FileDetails(
          file: aFile(
            uuid: uuid,
            name: 'Notes.md',
            type: LibraryType.text,
            contentHash: '',
            sizeBytes: stamp.sizeBytes,
            mtime: stamp.mtime,
          ),
        ),
      );

  /// The stamp the refreshed record carries after a write.
  set writeReturns(FileStamp stamp) => gateway.writtenStamp = stamp;

  /// Types [content], which is what leaves the editor with something to save.
  void edit(String content) => controller.edit(content);
}
