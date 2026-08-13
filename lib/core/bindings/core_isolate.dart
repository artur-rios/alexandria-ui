import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'alexandria_bindings.dart';
import 'core_strings.dart';

/// A request for the worker isolate.
///
/// Deliberately a name and a positional argument list rather than a sealed
/// hierarchy: everything sent across an isolate port must be sendable, and a
/// closed union of request classes would have to be reconstructed on the far
/// side anyway. The dispatch in [CoreIsolate._handle] is the single place that
/// knows how each name maps onto a binding.
typedef CoreRequest = ({String operation, List<Object?> arguments});

/// Raised when a core call could not be made at all — as distinct from a call
/// that was made and returned a failure status, which is a `Failure`.
class CoreCallException implements Exception {
  /// Creates the exception.
  const CoreCallException(this.message);

  /// What went wrong, already safe to log.
  final String message;

  @override
  String toString() => 'CoreCallException: $message';
}

/// Owns the Alexandria core on a worker isolate (IR-09).
///
/// Every core call runs off the interface thread. This matters more than it
/// might look: `alexandria_index_start` scans a filesystem and
/// `alexandria_files_list` serializes the whole catalog to JSON, and either on
/// the UI isolate is a frozen window.
///
/// One long-lived isolate rather than one per call, because the alternative
/// re-opens the shared library on every operation and gives up the ability to
/// keep the bindings warm.
class CoreIsolate {
  CoreIsolate._(this._isolate, this._requests, this._responses, this.libraryPath);

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _responses;

  /// The shared library this isolate loaded.
  final String libraryPath;

  final _pending = <int, Completer<Object?>>{};
  var _nextId = 0;
  var _closed = false;

  /// Spawns the worker and loads the shared library at [libraryPath].
  ///
  /// Throws [CoreCallException] when the library cannot be loaded, so startup
  /// step 1 can report the path it tried.
  static Future<CoreIsolate> spawn(String libraryPath) async {
    final responses = ReceivePort();
    final ready = Completer<SendPort>();

    final isolate = await Isolate.spawn(
      _entryPoint,
      (responses.sendPort, libraryPath),
      errorsAreFatal: false,
      debugName: 'alexandria-core',
    );

    late final CoreIsolate client;
    responses.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
        return;
      }
      if (message is ({int id, Object? value, String? error})) {
        client._settle(message);
      }
    });

    final requests = await ready.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        responses.close();
        isolate.kill(priority: Isolate.immediate);
        throw CoreCallException(
          'the core isolate did not start within 10 seconds',
        );
      },
    );

    client = CoreIsolate._(isolate, requests, responses, libraryPath);

    // The worker reports a load failure as its first response rather than
    // throwing across the port, so the path is available to the caller.
    final loadError = await client.call('__load_status__');
    if (loadError is String) {
      await client.dispose();
      throw CoreCallException(loadError);
    }

    return client;
  }

  void _settle(({int id, Object? value, String? error}) message) {
    final completer = _pending.remove(message.id);
    if (completer == null) return;

    final error = message.error;
    if (error != null) {
      completer.completeError(CoreCallException(error));
    } else {
      completer.complete(message.value);
    }
  }

  /// Runs [operation] on the worker and returns its result.
  Future<Object?> call(String operation, [List<Object?> arguments = const []]) {
    if (_closed) {
      throw const CoreCallException('the core isolate has been shut down');
    }

    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;

    _requests.send((id: id, operation: operation, arguments: arguments));
    return completer.future;
  }

  /// Shuts the worker down and fails every outstanding call.
  Future<void> dispose() async {
    if (_closed) return;
    _closed = true;

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const CoreCallException('the core isolate was shut down mid-call'),
        );
      }
    }
    _pending.clear();

    _responses.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  static void _entryPoint((SendPort, String) parameters) {
    final (responses, libraryPath) = parameters;
    final requests = ReceivePort();
    responses.send(requests.sendPort);

    AlexandriaBindings? bindings;
    String? loadError;

    try {
      bindings = AlexandriaBindings(DynamicLibrary.open(libraryPath));
    } on Object catch (error) {
      // Deliberately broad: DynamicLibrary.open throws ArgumentError on Windows
      // and a bare Exception on Linux, and either way the caller needs the path
      // rather than the distinction.
      loadError =
          'the Alexandria core could not be loaded from $libraryPath ($error)';
    }

    requests.listen((message) {
      final request =
          message as ({int id, String operation, List<Object?> arguments});

      if (request.operation == '__load_status__') {
        responses.send((id: request.id, value: loadError, error: null));
        return;
      }

      if (bindings == null) {
        responses.send((
          id: request.id,
          value: null,
          error: loadError ?? 'the Alexandria core is not loaded',
        ));
        return;
      }

      try {
        responses.send((
          id: request.id,
          value: _handle(bindings, request.operation, request.arguments),
          error: null,
        ));
      } on Object catch (error) {
        responses.send((id: request.id, value: null, error: error.toString()));
      }
    });
  }

  /// Maps an operation name onto a binding call.
  ///
  /// Every branch that receives a string from the core routes it through
  /// [CoreStrings], and every branch that passes one uses [withNativeString],
  /// so the free happens on the failure path too (IR-09).
  static Object? _handle(
    AlexandriaBindings bindings,
    String operation,
    List<Object?> arguments,
  ) {
    final strings = CoreStrings(bindings);

    return switch (operation) {
      // A pointer into a static CString in the core — read, never freed. See
      // CoreStrings.readStatic.
      'version' => strings.readStatic(bindings.alexandria_version()),

      'healthStatus' => bindings.alexandria_health_status_code(),

      'init' => withNativeString(
        arguments.first! as String,
        bindings.alexandria_index_init,
      ),

      'countFiles' => bindings.alexandria_index_count_files(),

      'countMissing' => bindings.alexandria_index_count_missing(),

      'indexedFilesJson' => strings.consume(
        bindings.alexandria_index_files_json(),
        (json) => json,
      ),

      // The one branch that both passes and receives a string. The body
      // carries the owner's plaintext password, so it is freed by
      // withNativeString on the way in — including if the call throws — and
      // the result's JSON is freed by consume on the way out, on the failure
      // path too (IR-09, NFR-13, FR-AU-11).
      'authLocalLogin' => withNativeString(arguments.first! as String, (body) {
        final result = bindings.alexandria_auth_local_login(body);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      // Two strings in, one out. Nested rather than sequential so each copy is
      // released by its own finally, including if the call throws between them.
      'authLocalSetCredentials' => withNativeString(
        arguments.first! as String,
        (body) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_auth_local_set_credentials(
            body,
            token,
          );
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      _ => throw CoreCallException('unknown core operation "$operation"'),
    };
  }
}
