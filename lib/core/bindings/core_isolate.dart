import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

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
/// might look: `alexandria_library_register` scans a filesystem and
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
    this._lifecycle,
    this.libraryPath,
  );

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _responses;

  /// Carries the worker's uncaught errors and its exit (IR-09).
  ///
  /// Without it a worker that died took every outstanding call with it: the
  /// completers in [_pending] were settled only by a response, and a dead
  /// isolate sends none. Nothing here times out — a scan of a large folder
  /// legitimately takes minutes, so a deadline short enough to catch a dead
  /// worker would cancel real work — which left the interface waiting on a
  /// future that could never complete, showing a spinner for the rest of the
  /// session.
  final ReceivePort _lifecycle;

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
    final lifecycle = ReceivePort();
    final ready = Completer<SendPort>();

    // The main isolate's snapshot of the environment, taken no later than
    // here — before the first worker exists, and so before anything this
    // application writes to the process environment. A worker's own
    // `Platform.environment` would be taken after a previous worker's writes
    // and read them as an operator's; see `prepareCoreEnvironment`.
    final launchEnvironment = Map<String, String>.of(Platform.environment);

    final isolate = await Isolate.spawn(
      _entryPoint,
      (responses.sendPort, libraryPath, launchEnvironment),
      errorsAreFatal: false,
      debugName: 'alexandria-core',
      // One port for both, told apart by what arrives on it: an uncaught
      // error as `[error, stackTrace]`, the isolate ending as `null`. They
      // are separate events here because `errorsAreFatal: false` makes them
      // separate — a worker that throws where nothing catches it keeps
      // running, so an error is not an exit and must not be treated as one.
      //
      // Registered at spawn rather than afterwards, so there is no window in
      // which the worker can die unobserved.
      onError: lifecycle.sendPort,
      onExit: lifecycle.sendPort,
    );

    late final CoreIsolate client;
    var started = false;

    responses.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
        return;
      }
      // `started` rather than a `late` read: a response arriving before the
      // field is assigned would throw a LateInitializationError inside a
      // listener, where nothing catches it.
      if (started && message is ({int id, Object? value, String? error})) {
        client._settle(message);
      }
    });

    lifecycle.listen((message) {
      // Two different events on one port, and they mean different things.
      //
      // A `List` is `onError`: `[error, stackTrace]`. Because the worker is
      // spawned with `errorsAreFatal: false`, it is still alive and will
      // still serve the next request — what it will not do is answer the one
      // it was on when it threw, and there is no id in the report to say
      // which. So every call in flight is failed and the worker is kept.
      //
      // `null` is `onExit`: the isolate has ended, for any reason. Nothing
      // more will ever arrive on either port, so this one shuts down.
      final failed = message is List;
      final reason = failed && message.isNotEmpty
          ? 'the Alexandria core isolate failed: ${message.first}'
          : 'the Alexandria core isolate stopped';

      if (!started) {
        responses.close();
        lifecycle.close();
        if (!ready.isCompleted) ready.completeError(CoreCallException(reason));
        return;
      }

      failed ? client._failPending(reason) : client._abandon(reason);
    });

    final requests = await ready.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        responses.close();
        lifecycle.close();
        isolate.kill(priority: Isolate.immediate);
        throw const CoreCallException(
          'the core isolate did not start within 10 seconds',
        );
      },
    );

    client = CoreIsolate._(
      isolate,
      requests,
      responses,
      lifecycle,
      libraryPath,
    );
    started = true;

    // The worker reports a load failure as its first response rather than
    // throwing across the port, so the path is available to the caller.
    final loadError = await client.call('__load_status__');
    if (loadError is String) {
      await client.dispose();
      throw CoreCallException(loadError);
    }

    return client;
  }

  /// Fails every call in flight, leaving the worker to carry on.
  ///
  /// For an uncaught error: the worker survives it, but the request it was
  /// serving is never answered and the report does not say which one that
  /// was. Failing all of them is broader than the damage and is the only
  /// honest option — a caller told its call failed can make it again, where a
  /// caller left waiting waits forever.
  ///
  /// A late response for one of these settles nothing: [_settle] drops an id
  /// it no longer holds.
  void _failPending(String reason) {
    if (_closed) return;

    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(CoreCallException(reason));
      }
    }
    _pending.clear();
  }

  /// Fails every outstanding call because the worker is gone for good.
  ///
  /// The same teardown [dispose] performs, reached the other way round: there
  /// the caller shuts the worker down, here the worker went by itself. Either
  /// way nothing more will arrive, so the ports close and no later call is
  /// accepted — a `call` after this throws immediately rather than waiting on
  /// an isolate that is not there.
  void _abandon(String reason) {
    if (_closed) return;

    _failPending(reason);
    _closed = true;

    _responses.close();
    _lifecycle.close();
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
    _lifecycle.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  static void _entryPoint((SendPort, String, Map<String, String>) parameters) {
    final (responses, libraryPath, launchEnvironment) = parameters;
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
          value: _handle(
            bindings,
            request.operation,
            request.arguments,
            launchEnvironment,
          ),
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
    Map<String, String> launchEnvironment,
  ) {
    final strings = CoreStrings(bindings);

    return switch (operation) {
      // A pointer into a static CString in the core — read, never freed. See
      // CoreStrings.readStatic.
      'version' => strings.readStatic(bindings.alexandria_version()),

      'healthStatus' => bindings.alexandria_health_status_code(),

      // The caches are settled here, immediately before the one call that
      // reads the core's settings.
      // Anywhere earlier would be a promise about ordering; anywhere later
      // would be too late for the process.
      'init' => withNativeString(arguments.first! as String, (path) {
        // The cache directory is derived from the path rather than passed as
        // a second argument, because "beside the catalog" is the rule, and a
        // caller free to say otherwise is a caller that can put them
        // somewhere the catalog does not follow.
        prepareCoreEnvironment(
          databaseDirectory: p.dirname(arguments.first! as String),
          launchEnvironment: launchEnvironment,
        );
        return bindings.alexandria_index_init(path);
      }),

      'countFiles' => bindings.alexandria_index_count_files(),

      // An optional priority in, a status and a run id out. No library: a
      // refresh covers every library at once rather than one (FR-LB-06).
      // withNativeString already passes null through as nullptr (see its
      // signature), which is what a null priority needs: the core reads an
      // absent priority as "normal" here, as it does for
      // alexandria_library_index_start.
      'indexRefreshStart' => withNativeString(arguments.first as String?, (
        priority,
      ) {
        final result = bindings.alexandria_index_refresh_start(priority);
        return (status: result.status, runId: _readRunId(result.run_id));
      }),

      // A library's uuid and an optional priority in; the same struct a
      // refresh answers out.
      'libraryIndexStart' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1] as String?, (priority) {
          final result = bindings.alexandria_library_index_start(
            uuid,
            priority,
          );
          return (status: result.status, runId: _readRunId(result.run_id));
        }),
      ),

      'countMissing' => bindings.alexandria_index_count_missing(),

      'indexedFilesJson' => strings.consume(
        bindings.alexandria_index_files_json(),
        (json) => json,
      ),

      // Just a status code out, so nothing to free on the way back — only the
      // string passed in.
      'indexPause' => withNativeString(
        arguments.first! as String,
        bindings.alexandria_index_pause,
      ),

      'indexCancel' => withNativeString(
        arguments.first! as String,
        bindings.alexandria_index_cancel,
      ),

      // The run id and an optional priority in, the same shape
      // libraryIndexStart answers with — the *same* run id, not a fresh one
      // (FR-FC-33).
      //
      // priority goes through withNativeString for the same reason it does
      // in libraryIndexStart, with a sharper stake here: null must reach the
      // core as a null pointer because the core reads an absent priority as
      // *keep the run's current width* — deliberately not the same as
      // "normal". An empty string lands in that same branch today only
      // because the core treats any unrecognised value as absent, which is a
      // coincidence of its parsing, not a contract; relying on it would let
      // a plain resume silently re-pace a scan the owner had throttled.
      'indexResume' => withNativeString(
        arguments.first! as String,
        (runId) => withNativeString(arguments[1] as String?, (priority) {
          final result = bindings.alexandria_index_resume(runId, priority);
          return (status: result.status, runId: _readRunId(result.run_id));
        }),
      ),

      // Nothing in, a JSON array out — freed by consume on the way back, on the
      // failure path too (IR-09, NFR-13).
      'indexRunsActive' => switch (bindings
          .alexandria_index_runs_active_json()) {
        final result => (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        ),
      },

      'indexRunFailures' => withNativeString(arguments.first! as String, (
        runId,
      ) {
        final result = bindings.alexandria_index_run_failures_json(runId);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'indexRunStatus' => withNativeString(arguments.first! as String, (runId) {
        final result = bindings.alexandria_index_run_status_json(runId);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      // Filters in, a JSON array out — freed by consume on the way back, on the
      // failure path too (IR-09, NFR-13).
      'filesList' => withNativeString(arguments.first! as String, (filters) {
        final result = bindings.alexandria_files_list(filters);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileByUuid' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_get_by_uuid(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileEditMetadata' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (patch) {
          final result = bindings.alexandria_file_edit_metadata(uuid, patch);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'filePlaybackSource' => withNativeString(arguments.first! as String, (
        uuid,
      ) {
        final result = bindings.alexandria_file_playback_source(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileThumbnail' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_thumbnail(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'comicPage' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_comic_page(
          uuid,
          arguments[1]! as int,
        );
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileReadContent' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_read_content(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileEditContent' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (body) {
          final result = bindings.alexandria_file_edit_content(uuid, body);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'fileRename' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (name) {
          final result = bindings.alexandria_file_rename(uuid, name);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'filePurge' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_purge(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'filePurgeOnDisk' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_purge_on_disk(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'bookmarkPurge' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_bookmark_purge(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileRestore' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_restore(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'bookmarkRestore' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_bookmark_restore(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'fileSoftDelete' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_file_soft_delete(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'bookmarkSoftDelete' => withNativeString(arguments.first! as String, (
        uuid,
      ) {
        final result = bindings.alexandria_bookmark_soft_delete(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'collectionListItems' => withNativeString(arguments.first! as String, (
        uuid,
      ) {
        final result = bindings.alexandria_collection_list_items(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'collectionAddItems' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (body) {
          final result = bindings.alexandria_collection_add_items(uuid, body);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'collectionRemoveItem' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (item) {
          final result = bindings.alexandria_collection_remove_item(uuid, item);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'settings' => switch (bindings.alexandria_settings_json()) {
        final result => (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        ),
      },

      'collectionsList' => withNativeString(arguments.first! as String, (
        filters,
      ) {
        final result = bindings.alexandria_collections_list(filters);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'collectionCreate' => withNativeString(arguments.first! as String, (
        body,
      ) {
        final result = bindings.alexandria_collection_create(body);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'collectionRename' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (body) {
          final result = bindings.alexandria_collection_rename(uuid, body);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'collectionDelete' => withNativeString(arguments.first! as String, (
        uuid,
      ) {
        final result = bindings.alexandria_collection_delete(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'bookmarkCreate' => withNativeString(arguments.first! as String, (body) {
        final result = bindings.alexandria_bookmark_create(body);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'bookmarkUpdate' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (body) {
          final result = bindings.alexandria_bookmark_update(uuid, body);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'bookmarksList' => withNativeString(arguments.first! as String, (
        filters,
      ) {
        final result = bindings.alexandria_bookmarks_list(filters);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'readingListCreate' => withNativeString(arguments.first! as String, (
        body,
      ) {
        final result = bindings.alexandria_reading_list_create(body);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'readingListDelete' => withNativeString(arguments.first! as String, (
        uuid,
      ) {
        final result = bindings.alexandria_reading_list_delete(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'readingListAddItem' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (body) {
          final result = bindings.alexandria_reading_list_add_item(uuid, body);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'readingListRemoveItem' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (item) {
          final result = bindings.alexandria_reading_list_remove_item(
            uuid,
            item,
          );
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      // Three strings, so three nestings: each pointer stays alive for the whole
      // call and is freed on the way out, in the order it was taken.
      'readingListUpdateProgress' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(
          arguments[1]! as String,
          (item) => withNativeString(arguments[2]! as String, (body) {
            final result = bindings.alexandria_reading_list_update_progress(
              uuid,
              item,
              body,
            );
            return (
              status: result.status,
              json: strings.consume(result.json, (json) => json),
            );
          }),
        ),
      ),

      'readingListsList' => withNativeString(arguments.first! as String, (
        filters,
      ) {
        final result = bindings.alexandria_reading_lists_list(filters);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'watchlistCreate' => withNativeString(arguments.first! as String, (body) {
        final result = bindings.alexandria_watchlist_create(body);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'watchlistDelete' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_watchlist_delete(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'watchlistAddVideo' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (body) {
          final result = bindings.alexandria_watchlist_add_video(uuid, body);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'watchlistRemoveVideo' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (video) {
          final result = bindings.alexandria_watchlist_remove_video(
            uuid,
            video,
          );
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'watchlistUpdateProgress' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(
          arguments[1]! as String,
          (video) => withNativeString(arguments[2]! as String, (body) {
            final result = bindings.alexandria_watchlist_update_progress(
              uuid,
              video,
              body,
            );
            return (
              status: result.status,
              json: strings.consume(result.json, (json) => json),
            );
          }),
        ),
      ),

      // UC-16 AF-03 reads this to find out whether a video's progress is
      // counted per episode; UC-29 and UC-30 are what browse it.
      'watchlistsList' => withNativeString(arguments.first! as String, (
        filters,
      ) {
        final result = bindings.alexandria_watchlists_list(filters);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      // The library calls. `libraryBrowse` and `libraryMove` take two
      // consecutive strings, which is the mapping a transposition breaks
      // silently — the uuid would be read as a folder path and answer nothing.
      'libraryRegister' => withNativeString(arguments.first! as String, (
        jsonBody,
      ) {
        final result = bindings.alexandria_library_register(jsonBody);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

      'librariesList' => switch (bindings.alexandria_libraries_list()) {
        final result => (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        ),
      },

      // The whole catalog's totals (library navigation design §6). Library
      // family codes.
      'catalogStats' => switch (bindings.alexandria_catalog_stats_json()) {
        final result => (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        ),
      },

      'libraryBrowse' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (path) {
          final result = bindings.alexandria_library_browse(uuid, path);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'libraryMove' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (jsonBody) {
          final result = bindings.alexandria_library_move(uuid, jsonBody);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      'libraryRename' => withNativeString(
        arguments.first! as String,
        (uuid) => withNativeString(arguments[1]! as String, (jsonBody) {
          final result = bindings.alexandria_library_rename(uuid, jsonBody);
          return (
            status: result.status,
            json: strings.consume(result.json, (json) => json),
          );
        }),
      ),

      // A library's uuid and a flag in, just a status code out.
      'librarySetPinned' => withNativeString(
        arguments.first! as String,
        (uuid) =>
            bindings.alexandria_library_set_pinned(uuid, arguments[1]! as bool),
      ),

      'librarySetFavorite' => withNativeString(
        arguments.first! as String,
        (uuid) => bindings.alexandria_library_set_favorite(
          uuid,
          arguments[1]! as bool,
        ),
      ),

      'libraryRemove' => withNativeString(arguments.first! as String, (uuid) {
        final result = bindings.alexandria_library_remove(uuid);
        return (
          status: result.status,
          json: strings.consume(result.json, (json) => json),
        );
      }),

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
