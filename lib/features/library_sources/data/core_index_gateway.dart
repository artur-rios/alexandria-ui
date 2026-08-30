import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../../catalog/domain/file_type.dart';
import '../domain/index_gateway.dart';
import '../domain/index_run.dart';
import '../domain/run_priority.dart';

/// [IndexGateway] over the generated bindings (IR-03, UC-06).
class CoreIndexGateway implements IndexGateway {
  /// Creates a gateway over [core].
  const CoreIndexGateway(this._core);

  /// The code a call that threw is reported as.
  ///
  /// The core answered nothing at all, so there is no status to map; this is
  /// the family's "other", which reads as an unexpected failure.
  static const int callFailedCode = INDEX_ERR_OTHER;

  final CoreClient _core;

  @override
  Future<IndexStartOutcome> startIndex({
    required String root,
    RunPriority? priority,
    List<FileType> types = const [],
    required String credential,
  }) async {
    final CoreRunStart result;
    try {
      result = await _core.indexStart(
        root,
        credential,
        priority?.wire,
        // Null, never `''`: an absent scope is what the core reads as every
        // type, and this is the one place the empty list is turned into the
        // absence rather than into an empty argument.
        types.isEmpty ? null : types.map((type) => type.wireName).join(','),
      );
    } on CoreCallException {
      return const IndexStartOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.indexing,
          code: callFailedCode,
        ),
      );
    }

    // The INDEX_ family here, deliberately: starting a run is an
    // `alexandria_index_*` call, and only reading a run's status uses RUN_.
    if (!CoreStatusFamily.indexing.isOk(result.status)) {
      return IndexStartOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.indexing, result.status),
      );
    }

    if (result.runId.isEmpty) {
      // A success with no id is a core that cannot be followed up: there is
      // nothing to poll, so it is reported rather than recorded as started.
      return const IndexStartOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.indexing,
          code: callFailedCode,
        ),
      );
    }

    return IndexStartOutcome.started(runId: result.runId);
  }

  @override
  Future<IndexStartOutcome> startRefresh({
    RunPriority? priority,
    required String credential,
  }) async {
    final CoreRunStart result;
    try {
      result = await _core.indexRefreshStart(credential, priority?.wire);
    } on CoreCallException {
      return const IndexStartOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.indexing,
          code: callFailedCode,
        ),
      );
    }

    if (!CoreStatusFamily.indexing.isOk(result.status)) {
      return IndexStartOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.indexing, result.status),
      );
    }

    if (result.runId.isEmpty) {
      return const IndexStartOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.indexing,
          code: callFailedCode,
        ),
      );
    }

    return IndexStartOutcome.started(runId: result.runId);
  }

  @override
  Future<int> countCatalogedFiles() async {
    try {
      return await _core.indexCountFiles();
    } on CoreCallException {
      // Unknown rather than empty: offering to register a folder because the
      // count could not be read would be answering AF-02 on a guess.
      return -1;
    }
  }

  @override
  Future<IndexRunOutcome> readRun({
    required String runId,
    required String credential,
  }) async {
    final CoreJsonResponse response;
    try {
      response = await _core.indexRunStatus(runId, credential);
    } on CoreCallException {
      return const IndexRunOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.run,
          code: RUN_ERR_OTHER,
        ),
      );
    }

    // The RUN_ family, which is not the INDEX_ one: they disagree on what 4
    // means, and reading this through the other would report a run the core
    // does not know as an unexpected failure rather than as not found.
    if (!CoreStatusFamily.run.isOk(response.status)) {
      return IndexRunOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.run, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      return IndexRunOutcome.read(run: _runFrom(body, fallbackId: runId));
    } on Object {
      // Broad by intent, as on every payload path: a malformed document
      // surfaces as FormatException and a wrongly-typed field as TypeError,
      // and the owner needs a readable failure either way.
      return _unreadable();
    }
  }

  @override
  Future<RunControlOutcome> pauseRun({
    required String runId,
    required String credential,
  }) async {
    final int status;
    try {
      status = await _core.indexPause(runId, credential);
    } on CoreCallException {
      return const RunControlOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.run,
          code: RUN_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.run.isOk(status)) {
      return RunControlOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.run, status),
      );
    }

    return const RunControlOutcome.ok();
  }

  @override
  Future<RunControlOutcome> cancelRun({
    required String runId,
    required String credential,
  }) async {
    final int status;
    try {
      status = await _core.indexCancel(runId, credential);
    } on CoreCallException {
      return const RunControlOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.run,
          code: RUN_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.run.isOk(status)) {
      return RunControlOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.run, status),
      );
    }

    return const RunControlOutcome.ok();
  }

  @override
  Future<IndexStartOutcome> resumeRun({
    required String runId,
    RunPriority? priority,
    required String credential,
  }) async {
    final CoreRunStart result;
    try {
      result = await _core.indexResume(runId, priority?.wire, credential);
    } on CoreCallException {
      return const IndexStartOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.run,
          code: RUN_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.run.isOk(result.status)) {
      return IndexStartOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.run, result.status),
      );
    }

    if (result.runId.isEmpty) {
      return const IndexStartOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.run,
          code: RUN_ERR_OTHER,
        ),
      );
    }

    return IndexStartOutcome.started(runId: result.runId);
  }

  @override
  Future<ActiveRunsOutcome> listActiveRuns({required String credential}) async {
    final CoreJsonResponse response;
    try {
      response = await _core.indexRunsActive(credential);
    } on CoreCallException {
      return const ActiveRunsOutcome.failed(
        failure: Failure.unexpected(
          family: CoreStatusFamily.run,
          code: RUN_ERR_OTHER,
        ),
      );
    }

    if (!CoreStatusFamily.run.isOk(response.status)) {
      return ActiveRunsOutcome.failed(
        failure: mapCoreStatus(CoreStatusFamily.run, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadableActiveRuns();

    try {
      final body = jsonDecode(json) as List<dynamic>;
      final runs = body
          .cast<Map<String, dynamic>>()
          .map((entry) => _runFrom(entry, fallbackId: ''))
          .toList();
      return ActiveRunsOutcome.read(runs: runs);
    } on Object {
      // Broad by intent, as on every payload path: a malformed document
      // surfaces as FormatException and a wrongly-typed field as TypeError,
      // and the owner needs a readable failure either way.
      return _unreadableActiveRuns();
    }
  }

  /// The run [body] describes.
  ///
  /// The counts are flattened into the body rather than nested — the core's
  /// `kind` already says which shape to expect — so they are read from the
  /// top level. A running run carries none at all, which is why every count
  /// defaults rather than being required.
  IndexRun _runFrom(Map<String, dynamic> body, {required String fallbackId}) {
    final status = IndexRunStatus.parse(body['status'] as String?);
    // A running run carries no counts at all, and the two kinds carry
    // different ones — so the presence of any of them is what decides whether
    // there is a tally to read.
    const countKeys = [
      'scanned',
      'indexed',
      'refreshed',
      'markedMissing',
      'alreadyCataloged',
    ];
    final hasCounts = countKeys.any(body.containsKey);

    return IndexRun(
      runId: body['runId'] as String? ?? fallbackId,
      root: body['root'] as String? ?? '',
      kind: IndexRunKind.parse(body['kind'] as String?),
      status: status,
      phase: IndexRunPhase.parse(body['phase'] as String?),
      total: body['total'] as int?,
      processed: body['processed'] as int?,
      activeMillis: body['activeMillis'] as int? ?? 0,
      pausedAt: switch (body['pausedAt']) {
        final String raw => DateTime.tryParse(raw),
        _ => null,
      },
      counts: hasCounts
          ? IndexRunCounts(
              scanned: body['scanned'] as int? ?? 0,
              indexed: body['indexed'] as int? ?? 0,
              skipped: body['skipped'] as int? ?? 0,
              alreadyCataloged: body['alreadyCataloged'] as int? ?? 0,
              refreshed: body['refreshed'] as int? ?? 0,
              markedMissing: body['markedMissing'] as int? ?? 0,
              unchanged: body['unchanged'] as int? ?? 0,
              failed: body['failed'] as int? ?? 0,
            )
          : null,
      error: body['error'] as String?,
    );
  }

  IndexRunOutcome _unreadable() => const IndexRunOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.run,
      code: RUN_ERR_OTHER,
    ),
  );

  ActiveRunsOutcome _unreadableActiveRuns() => const ActiveRunsOutcome.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.run,
      code: RUN_ERR_OTHER,
    ),
  );
}
