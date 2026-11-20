import 'dart:convert';

import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/features/libraries/data/core_library_gateway.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/run_priority.dart';
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
      ).register(name: 'Movies', rootPath: '/m', credential: 't');

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

    await CoreLibraryGateway(
      fake,
    ).register(name: 'Movies', rootPath: '/m', credential: 't');

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

    await CoreLibraryGateway(fake).register(
      name: 'Movies',
      rootPath: '/m',
      priority: RunPriority.low,
      credential: 't',
    );

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
    ).register(name: 'Movies', rootPath: '/m', credential: 't');

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
    ).register(name: 'Movies', rootPath: '/m', credential: 't');

    expect(outcome, isA<LibraryRegistrationFailed>());
  });
}
