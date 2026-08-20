import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'alexandria_bindings.dart';
import 'core_environment.dart';
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
  CoreIsolate._(
    this._isolate,
    this._requests,
    this._responses,
    this.libraryPath,
  );

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

      // The auth mode is settled here, immediately before the one call that
      // reads the core's settings. Anywhere earlier would be a promise about
      // ordering; anywhere later would be too late for the process.
      'init' => withNativeString(arguments.first! as String, (path) {
        ensureLocalAuthMode();
        return bindings.alexandria_index_init(path);
      }),

      'countFiles' => bindings.alexandria_index_count_files(),

      // The session token in, a status and a run id out. No root: a refresh
      // covers the whole catalog rather than one folder (FR-LB-06).
      'indexRefreshStart' => withNativeString(arguments.first! as String, (
        token,
      ) {
        final result = bindings.alexandria_index_refresh_start(token);
        return (status: result.status, runId: _readRunId(result.run_id));
      }),

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

      // Carries both plaintext entries in, so the same discipline as login
      // applies: freed by withNativeString on the way in, and the result's
      // JSON freed by consume on the way out (IR-09, NFR-13, FR-AU-11).
      'authLocalRegister' => withNativeString(arguments.first! as String, (
        body,
      ) {
        final result = bindings.alexandria_auth_local_register(body);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      // Two strings in, one out. The nesting is what frees both on every
      // path: the inner withNativeString's finally runs before the outer's,
      // and neither depends on the call succeeding. One carries the new
      // plaintext password and the other the session credential, so leaking
      // either would be exactly what FR-AU-11 forbids (IR-09, NFR-13).
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

      // The root and the session token in, a status and a run id out. The run
      // id is a fixed-size array inside the struct rather than an allocation,
      // so it is read straight off and there is nothing to free on the way
      // back — only the two strings passed in, which the nesting handles
      // (IR-09, NFR-13).
      'indexStart' => withNativeString(
        arguments.first! as String,
        (root) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_index_start(root, token);
          return (status: result.status, runId: _readRunId(result.run_id));
        }),
      ),

      'indexRunStatus' => withNativeString(
        arguments.first! as String,
        (runId) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_index_run_status_json(
            runId,
            token,
          );
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      // Filters and the session token in, a JSON array out — freed by consume
      // on the way back, on the failure path too (IR-09, NFR-13).
      'filesList' => withNativeString(
        arguments.first! as String,
        (filters) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_files_list(filters, token);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'fileByUuid' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_file_get_by_uuid(uuid, token);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      // Three strings, so three nestings: each pointer stays alive for the
      // whole call and is freed on the way out, in the order it was taken.
      'fileEditMetadata' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(
          arguments[1]! as String,
          (patch) => withNativeString(arguments[2]! as String, (token) {
            final result = bindings.alexandria_file_edit_metadata(
              uuid,
              patch,
              token,
            );
            return (
              status: result.status,
              json: strings.consume(result.json, (json) => json),
            );
          }),
        ),
      ),

      'fileReadContent' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_file_read_content(uuid, token);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'fileEditContent' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(
          arguments[1]! as String,
          (body) => withNativeString(arguments[2]! as String, (token) {
            final result = bindings.alexandria_file_edit_content(
              uuid,
              body,
              token,
            );
            return (
              status: result.status,
              json: strings.consume(result.json, (json) => json),
            );
          }),
        ),
      ),

      'fileRename' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(
          arguments[1]! as String,
          (name) => withNativeString(arguments[2]! as String, (token) {
            final result = bindings.alexandria_file_rename(uuid, name, token);
            return (
              status: result.status,
              json: strings.consume(result.json, (json) => json),
            );
          }),
        ),
      ),

      // UC-16 AF-03 reads this to find out whether a video's progress is
      // counted per episode; UC-29 and UC-30 are what browse it.
      'watchlistsList' => withNativeString(
        arguments.first! as String,
        (filters) => withNativeString(arguments[1]! as String, (token) {
          final result = bindings.alexandria_watchlists_list(filters, token);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      _ => throw CoreCallException('unknown core operation "$operation"'),
    };
  }

  /// Reads the run id out of the fixed-size array the core filled.
  ///
  /// The array is 37 bytes — a 36-character UUID and its terminator — and is
  /// part of the struct rather than an allocation, so it is copied out here
  /// and never freed. It is empty on failure, which reads as an empty string
  /// and is what the caller checks the status for.
  static String _readRunId(Array<Char> runId) {
    final bytes = <int>[];
    for (var index = 0; index < 37; index++) {
      final byte = runId[index];
      if (byte == 0) break;
      bytes.add(byte);
    }

    return String.fromCharCodes(bytes);
  }
}
