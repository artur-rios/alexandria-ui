import 'dart:convert';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/libraries/data/core_library_gateway.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/run_priority.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_core_client.dart';

/// [CoreLibraryGateway.register] on the 0.6.0 core, which starts the
/// library's first run and answers its id beside the library.
void main() {
  test(
    'GivenRegisterSucceeds_WhenRegister_ThenRegisteredCarriesLibraryAndRunId',
    () async {
      final fake = FakeCoreClient()
        ..libraryResponse = (
          status: LIBRARY_OK,
          json: '{"uuid":"l1","name":"Movies","rootPath":"/m","runId":"r1"}',
        );

      final outcome = await CoreLibraryGateway(
        fake,
      ).register(name: 'Movies', rootPath: '/m');

      expect(
        outcome,
        const LibraryRegistration.registered(
          library: Library(uuid: 'l1', name: 'Movies', rootPath: '/m'),
          runId: 'r1',
        ),
      );
    },
  );

  test('GivenNoPriority_WhenRegister_ThenTheBodyNamesNone', () async {
    final fake = FakeCoreClient()
      ..libraryResponse = (
        status: LIBRARY_OK,
        json: '{"uuid":"l1","name":"Movies","rootPath":"/m","runId":"r1"}',
      );

    await CoreLibraryGateway(fake).register(name: 'Movies', rootPath: '/m');

    expect(jsonDecode(fake.libraryRegisterCalls.single.jsonBody), {
      'name': 'Movies',
      'rootPath': '/m',
    });
  });

  test('GivenLowPriority_WhenRegister_ThenTheBodyAsksForLow', () async {
    final fake = FakeCoreClient()
      ..libraryResponse = (
        status: LIBRARY_OK,
        json: '{"uuid":"l1","name":"Movies","rootPath":"/m","runId":"r1"}',
      );

    await CoreLibraryGateway(
      fake,
    ).register(name: 'Movies', rootPath: '/m', priority: RunPriority.low);

    expect(
      (jsonDecode(fake.libraryRegisterCalls.single.jsonBody)
          as Map)['priority'],
      'low',
    );
  });

  test('GivenRegisterOverlaps_WhenRegister_ThenFailedWithConflict', () async {
    final fake = FakeCoreClient()
      ..libraryResponse = (status: LIBRARY_ERR_CONFLICT, json: null);

    final outcome = await CoreLibraryGateway(
      fake,
    ).register(name: 'Movies', rootPath: '/m');

    expect(
      (outcome as LibraryRegistrationFailed).failure,
      isA<ConflictFailure>(),
    );
  });

  test('GivenASuccessWithNoRunId_WhenRegister_ThenItFails', () async {
    final fake = FakeCoreClient()
      ..libraryResponse = (
        status: LIBRARY_OK,
        json: '{"uuid":"l1","name":"Movies","rootPath":"/m"}',
      );

    final outcome = await CoreLibraryGateway(
      fake,
    ).register(name: 'Movies', rootPath: '/m');

    expect(outcome, isA<LibraryRegistrationFailed>());
  });

  group('pins, favorites, rename and stats (core 0.7)', () {
    test(
      'GivenPinnedAndFavoriteInTheList_WhenBrowse_ThenTheyAreRead',
      () async {
        final fake = FakeCoreClient()
          ..libraryResponse = (
            status: LIBRARY_OK,
            json:
                '[{"uuid":"l1","name":"A","rootPath":"/a","pinned":true,'
                '"favorite":true},{"uuid":"l2","name":"B","rootPath":"/b"}]',
          );

        final outcome = await CoreLibraryGateway(fake).browse();

        expect((outcome as LibraryBrowseLoaded).libraries, const [
          Library(
            uuid: 'l1',
            name: 'A',
            rootPath: '/a',
            pinned: true,
            favorite: true,
          ),
          Library(uuid: 'l2', name: 'B', rootPath: '/b'),
        ]);
      },
    );

    test('GivenPinnedAndFavoriteInBrowse_WhenRead_ThenTheyAreRead', () async {
      final fake = FakeCoreClient()
        ..libraryResponse = (
          status: LIBRARY_OK,
          json:
              '{"library":{"uuid":"l1","name":"A","rootPath":"/a",'
              '"pinned":true,"favorite":false},"path":"","folders":[],'
              '"files":[]}',
        );

      final outcome = await CoreLibraryGateway(fake).read(uuid: 'l1', path: '');

      final library = (outcome as LibraryReadLoaded).listing.library;
      expect(library.pinned, isTrue);
      expect(library.favorite, isFalse);
    });

    test('GivenCodes_WhenSetPinned_ThenTheyMapToTheirOutcome', () async {
      final fake = FakeCoreClient();
      final gateway = CoreLibraryGateway(fake);

      fake.librarySetPinnedResult = LIBRARY_OK;
      expect(
        await gateway.setPinned(uuid: 'l1', pinned: true),
        const LibraryWrite.done(),
      );
      expect(fake.librarySetPinnedCalls.single, (uuid: 'l1', pinned: true));

      fake.librarySetPinnedResult = LIBRARY_ERR_NOT_FOUND;
      expect(
        (await gateway.setPinned(uuid: 'l1', pinned: false)
                as LibraryWriteFailed)
            .failure,
        isA<NotFoundFailure>(),
      );

      fake.librarySetPinnedResult = LIBRARY_ERR_INVALID_INPUT;
      expect(
        (await gateway.setPinned(uuid: 'l1', pinned: false)
                as LibraryWriteFailed)
            .failure,
        isA<InvalidInputFailure>(),
      );
    });

    test('GivenCodes_WhenSetFavorite_ThenTheyMapToTheirOutcome', () async {
      final fake = FakeCoreClient();
      final gateway = CoreLibraryGateway(fake);

      expect(
        await gateway.setFavorite(uuid: 'l1', favorite: true),
        const LibraryWrite.done(),
      );
      expect(fake.librarySetFavoriteCalls.single, (uuid: 'l1', favorite: true));

      fake.librarySetFavoriteResult = LIBRARY_ERR_NOT_FOUND;
      expect(
        (await gateway.setFavorite(uuid: 'l1', favorite: false)
                as LibraryWriteFailed)
            .failure,
        isA<NotFoundFailure>(),
      );
    });

    test('GivenAName_WhenRename_ThenTheBodyCarriesIt', () async {
      final fake = FakeCoreClient();

      final outcome = await CoreLibraryGateway(
        fake,
      ).rename(uuid: 'l1', name: 'New');

      expect(outcome, const LibraryWrite.done());
      expect(fake.libraryRenameCalls.single.uuid, 'l1');
      expect(fake.libraryRenameCalls.single.jsonBody, '{"name":"New"}');
    });

    test('GivenTheCoreRefuses_WhenRename_ThenItFailsMapped', () async {
      final fake = FakeCoreClient()
        ..libraryRenameResponse = (status: LIBRARY_ERR_CONFLICT, json: null);

      final outcome = await CoreLibraryGateway(
        fake,
      ).rename(uuid: 'l1', name: 'New');

      expect((outcome as LibraryWriteFailed).failure, isA<ConflictFailure>());
    });

    test('GivenStats_WhenRead_ThenEverySevenTypesIsParsed', () async {
      final fake = FakeCoreClient()
        ..catalogStatsResponse = (
          status: LIBRARY_OK,
          json:
              '{"libraries":3,"filesByType":{"audio":1,"video":2,"html":3,'
              '"text":4,"document":5,"comic":6,"image":7}}',
        );

      final stats = await CoreLibraryGateway(fake).stats();

      expect(stats.libraries, 3);
      expect(stats.filesByType, {
        FileType.audio: 1,
        FileType.video: 2,
        FileType.html: 3,
        FileType.text: 4,
        FileType.document: 5,
        FileType.comic: 6,
        FileType.image: 7,
      });
    });

    test('GivenTheCoreFails_WhenStatsAreRead_ThenTheFailureIsThrown', () async {
      final fake = FakeCoreClient()
        ..catalogStatsResponse = (
          status: LIBRARY_ERR_NOT_INITIALIZED,
          json: null,
        );

      await expectLater(
        CoreLibraryGateway(fake).stats(),
        throwsA(isA<NotInitializedFailure>()),
      );
    });

    test('GivenAnUnreadableBody_WhenStatsAreRead_ThenItIsUnexpected', () async {
      final fake = FakeCoreClient()
        ..catalogStatsResponse = (status: LIBRARY_OK, json: 'nope');

      await expectLater(
        CoreLibraryGateway(fake).stats(),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}
