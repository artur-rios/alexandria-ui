import 'package:alexandria_ui/core/bindings/core_client.dart';
import 'package:alexandria_ui/core/bindings/core_environment.dart';
import 'package:alexandria_ui/core/bindings/core_isolate.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [CoreIsolate] that never spawns a worker or loads the native library.
///
/// [core_isolate.dart]'s own dispatch (`_handle`) cannot be exercised without
/// a real shared library — nothing in this repository unit-tests it directly,
/// reading list and watchlist included. What *is* testable without FFI is the
/// boundary this task actually owns: that [FfiCoreClient] hands the isolate
/// the right operation name and the right arguments in the right order. A
/// transposed pair of `String` parameters compiles cleanly and would
/// otherwise misbehave silently only once a real core is involved.
class _RecordingIsolate implements CoreIsolate {
  /// Every call made through this isolate, in order.
  final List<({String operation, List<Object?> arguments})> calls = [];

  /// What [call] answers, regardless of the operation.
  Object? reply;

  @override
  Future<Object?> call(
    String operation, [
    List<Object?> arguments = const [],
  ]) async {
    calls.add((operation: operation, arguments: arguments));
    return reply;
  }

  @override
  Future<void> dispose() async {}

  @override
  String get libraryPath => 'unused-in-this-test';
}

void main() {
  late _RecordingIsolate isolate;
  late FfiCoreClient client;

  setUp(() {
    isolate = _RecordingIsolate()..reply = (status: 0, json: '{}');
    client = FfiCoreClient(isolate);
  });

  test(
    'GivenAPathAndLookup_WhenInitializeIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      // The music-lookup configuration rides along with the path because the
      // core reads its settings at this one call and nowhere else: the
      // isolate applies it to the environment immediately before it, so the
      // order of these three arguments is load-bearing.
      isolate.reply = 0;

      await client.initialize(
        'catalog.db',
        musicLookup: const MusicLookup(
          enabled: true,
          contact: 'owner@example.com',
        ),
      );

      expect(isolate.calls.single.operation, 'init');
      expect(isolate.calls.single.arguments, [
        'catalog.db',
        true,
        'owner@example.com',
      ]);
    },
  );

  test(
    'GivenABodyAndToken_WhenPlaylistCreateIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistCreate('body-value', 'token-value');

      expect(isolate.calls.single.operation, 'playlistCreate');
      expect(isolate.calls.single.arguments, ['body-value', 'token-value']);
    },
  );

  test(
    'GivenAUuidBodyAndToken_WhenPlaylistRenameIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistRename('uuid-value', 'body-value', 'token-value');

      expect(isolate.calls.single.operation, 'playlistRename');
      expect(isolate.calls.single.arguments, [
        'uuid-value',
        'body-value',
        'token-value',
      ]);
    },
  );

  test(
    'GivenAUuidAndToken_WhenPlaylistDeleteIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistDelete('uuid-value', 'token-value');

      expect(isolate.calls.single.operation, 'playlistDelete');
      expect(isolate.calls.single.arguments, ['uuid-value', 'token-value']);
    },
  );

  test(
    'GivenAToken_WhenPlaylistsListIsCalled_ThenTheIsolateReceivesIt',
    () async {
      await client.playlistsList('token-value');

      expect(isolate.calls.single.operation, 'playlistsList');
      expect(isolate.calls.single.arguments, ['token-value']);
    },
  );

  test(
    'GivenAUuidAndToken_WhenPlaylistReadIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistRead('uuid-value', 'token-value');

      expect(isolate.calls.single.operation, 'playlistRead');
      expect(isolate.calls.single.arguments, ['uuid-value', 'token-value']);
    },
  );

  test(
    'GivenAUuidBodyAndToken_WhenPlaylistAddEntriesIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistAddEntries(
        'uuid-value',
        'body-value',
        'token-value',
      );

      expect(isolate.calls.single.operation, 'playlistAddEntries');
      expect(isolate.calls.single.arguments, [
        'uuid-value',
        'body-value',
        'token-value',
      ]);
    },
  );

  // entryUuid and uuid are the two arguments most at risk of transposition:
  // both are UUIDs, so a swap would not even fail obviously in a manual
  // smoke test. The fixture values are distinguishable by name to catch it.
  test(
    'GivenAPlaylistUuidEntryUuidAndToken_WhenPlaylistRemoveEntryIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistRemoveEntry(
        'playlist-uuid-value',
        'entry-uuid-value',
        'token-value',
      );

      expect(isolate.calls.single.operation, 'playlistRemoveEntry');
      expect(isolate.calls.single.arguments, [
        'playlist-uuid-value',
        'entry-uuid-value',
        'token-value',
      ]);
    },
  );

  // Four consecutive String parameters, three of which are easy to confuse
  // for one another — this is exactly the shape the brief calls out as the
  // one that compiles cleanly when transposed.
  test(
    'GivenAPlaylistUuidEntryUuidBodyAndToken_WhenPlaylistMoveEntryIsCalled_ThenTheIsolateReceivesThemInOrder',
    () async {
      await client.playlistMoveEntry(
        'playlist-uuid-value',
        'entry-uuid-value',
        'body-value',
        'token-value',
      );

      expect(isolate.calls.single.operation, 'playlistMoveEntry');
      expect(isolate.calls.single.arguments, [
        'playlist-uuid-value',
        'entry-uuid-value',
        'body-value',
        'token-value',
      ]);
    },
  );
}
