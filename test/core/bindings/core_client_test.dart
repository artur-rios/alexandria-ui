import 'package:alexandria_ui/core/bindings/core_client.dart';
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

  test('GivenAPath_WhenInitializeIsCalled_ThenTheIsolateReceivesIt', () async {
    isolate.reply = 0;

    await client.initialize('catalog.db');

    expect(isolate.calls.single.operation, 'init');
    expect(isolate.calls.single.arguments, ['catalog.db']);
  });
}
