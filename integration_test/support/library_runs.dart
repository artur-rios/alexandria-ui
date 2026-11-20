import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/features/indexing/data/core_index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/libraries/data/core_library_gateway.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adds [root] as a library called [name] and waits for the run the core
/// starts with it to settle (core 0.6.0).
///
/// The way a folder gets into the catalog at all: the core indexes nothing
/// that is not a library. Waits for the run rather than for a file count,
/// because a library with an unfinished run refuses a move and a second run,
/// and the tests that do either come straight after this.
Future<Library> addLibraryAndSettle(
  CoreClient client,
  String credential, {
  required String root,
  String name = 'Course',
}) async {
  final registered = await CoreLibraryGateway(
    client,
  ).register(name: name, rootPath: root, credential: credential);
  expect(
    registered,
    isA<LibraryRegistered>(),
    reason: 'the core refused to add $root as a library',
  );
  final library = registered as LibraryRegistered;

  final run = await settleRun(client, credential, library.runId);
  expect(run.status, IndexRunStatus.complete, reason: 'the first run failed');

  return library.library;
}

/// Polls [runId] until it is over, and answers how it ended.
Future<IndexRun> settleRun(
  CoreClient client,
  String credential,
  String runId,
) async {
  final gateway = CoreIndexGateway(client);
  final deadline = DateTime.now().add(const Duration(seconds: 30));

  while (true) {
    final outcome = await gateway.readRun(runId: runId, credential: credential);
    if (outcome case IndexRunRead(:final run) when run.status.isTerminal) {
      return run;
    }
    expect(
      DateTime.now().isBefore(deadline),
      isTrue,
      reason: 'run $runId never settled',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}
