# Indexing Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the core's indexing work visible and controllable — live progress with counts and a time estimate, a background activity strip, pause/resume/cancel, auto-index on folder add — and retire the `alexandria_desktop` name.

**Architecture:** A new `ActiveRunsController` polls the core's outstanding-runs query and is the single source of truth for what is running; a `BackgroundActivityStrip` above the persistent playback bar renders it. Time remaining is a pure function over poll samples, tested away from any widget. Per-folder controls live on the library sources screen, which is where a specific run can be addressed once the strip collapses to an aggregate.

**Tech Stack:** Flutter, Riverpod (`Notifier`), Freezed, `ffigen`-generated FFI bindings over the Alexandria Rust core, `flutter_test` including golden tests.

**Spec:** `docs/superpowers/specs/2026-08-23-indexing-experience-design.md`

## Global Constraints

- **Test naming here is `GivenX_WhenY_ThenZ` in PascalCase** — e.g. `GivenAStoredTheme_WhenStartupSettles_ThenItIsApplied`. This differs from the core repository's snake_case; do not import that convention.
- Every user-visible string goes in **both** `lib/core/l10n/app_en.arb` and `lib/core/l10n/app_pt.arb`, then `flutter gen-l10n`. Never hardcode a string in a widget.
- Layering is Domain ← Application ← Presentation. Presentation never touches `CoreClient` directly; it goes through a controller, which goes through a gateway port.
- `FR-UX-02`: no navigation entry may be dropped at any breakpoint. The panel is already nine destinations tall at the 640px minimum.
- An `UnauthorizedFailure` returns the owner to login via `SessionController.invalidate`. Every other failure surfaces through `lib/core/failures/failure_messages.dart`.
- Run `dart format .` and `flutter analyze` before every commit; both must be clean.
- Run `flutter test` for the suite. Golden tests exist — `flutter test --update-goldens` only when a golden change is intended and reviewed.

---

## Prerequisite before Task 2

The FFI bindings in `lib/core/bindings/alexandria_bindings.dart` are generated from the core's header and **do not yet contain the new calls**. Before Task 2, run:

```bash
./tools/dev.ps1 -NoRun
```

This builds the core from the sibling `alexandria-api` checkout (now on `main` with `#114` merged), copies its generated header to `native/include/alexandria_ffi.h`, and re-runs `ffigen`. Confirm `alexandria_index_pause`, `alexandria_index_resume`, `alexandria_index_cancel` and `alexandria_index_runs_active_json` appear in the regenerated bindings before starting.

---

## File Structure

**Create:**

| File | Responsibility |
| --- | --- |
| `lib/features/library_sources/domain/run_priority.dart` | The `normal`/`low` pacing choice and its wire spelling |
| `lib/features/library_sources/domain/run_estimate.dart` | Pure rate and remaining-time calculation over samples |
| `lib/features/library_sources/application/active_runs_controller.dart` | The global picture: outstanding runs, polled while any is running |
| `lib/features/library_sources/application/active_runs_state.dart` | That controller's state |
| `lib/features/shell/presentation/background_activity_strip.dart` | One row above the playback bar |
| `lib/features/shell/presentation/rail_action.dart` | A rail-shaped, non-selectable action |

**Modify:**

| File | Change |
| --- | --- |
| `lib/features/library_sources/domain/index_run.dart` | New statuses, new progress fields |
| `lib/features/library_sources/domain/index_gateway.dart` | Four new operations, priority on the two starts |
| `lib/features/library_sources/data/core_index_gateway.dart` | Implement them |
| `lib/core/bindings/core_client.dart`, `core_isolate.dart` | Four new FFI calls, priority arguments |
| `lib/features/library_sources/application/index_runs_controller.dart` | Stop reconstructing the global picture; add controls |
| `lib/features/library_sources/application/library_sources_controller.dart` | `registerFolder` returns what it registered |
| `lib/features/library_sources/presentation/library_sources_screen.dart` | Auto-index chain, per-folder controls, relabelling |
| `lib/features/shell/presentation/shell_screen.dart` | Insert the strip |
| `lib/features/shell/presentation/shell_navigation_panel.dart` | Rail actions with labels, divider |
| `lib/features/shell/presentation/library_tools_button.dart` | Labelled trigger, section headings |
| `lib/features/catalog/domain/catalog_file.dart` | Gains `sizeBytes`, `mtime`, and a `FileStamp` |
| `lib/features/catalog/data/core_catalog_gateway.dart` | Parse them |
| `lib/features/editing/data/core_text_content_gateway.dart` | Parse them |
| `lib/features/editing/application/text_editor_controller.dart` | Conflict check moves from content hash to stamp |
| `lib/core/l10n/app_en.arb`, `app_pt.arb` | New strings |

---

### Task 1: Teach the model the core's new vocabulary

**This task is also a live bug fix and must come first.** `IndexRunStatus.parse` falls back to `failed` for any word it does not know, and it does not know `paused` or `cancelled`. Against the merged core, **a paused run currently displays as failed**. It still carries `interrupted`, which the core removed.

**Files:**
- Modify: `lib/features/library_sources/domain/index_run.dart`
- Create: `lib/features/library_sources/domain/run_priority.dart`
- Test: `test/features/library_sources/domain/index_run_test.dart`

**Interfaces:**
- Produces: `IndexRunStatus.{running, paused, complete, failed, cancelled}` (no `interrupted`); `IndexRunPhase.{discovering, processing}`; `IndexRun` gains `phase`, `total`, `processed`, `activeMillis`, `pausedAt`, and `alreadyCataloged` on `IndexRunCounts`; `RunPriority.{normal, low}` with `String get wire`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/library_sources/domain/index_run_test.dart` (create if absent, following a neighbouring domain test's setup):

```dart
void main() {
  group('IndexRunStatus.parse', () {
    test('GivenAPausedStatus_WhenParsed_ThenItIsPaused', () {
      expect(IndexRunStatus.parse('paused'), IndexRunStatus.paused);
    });

    test('GivenACancelledStatus_WhenParsed_ThenItIsCancelled', () {
      expect(IndexRunStatus.parse('cancelled'), IndexRunStatus.cancelled);
    });

    // The core removed `interrupted`; a run left by a closed application now
    // comes back `paused`. Falling back to `failed` for a word we do not know
    // stays right, but it must not swallow one we now do.
    test('GivenAnUnknownStatus_WhenParsed_ThenItIsFailed', () {
      expect(IndexRunStatus.parse('elsewhere'), IndexRunStatus.failed);
    });

    test('GivenAPausedRun_WhenAskedIfInFlight_ThenItIsNot', () {
      expect(IndexRunStatus.paused.isInFlight, isFalse);
    });
  });

  group('IndexRunPhase.parse', () {
    test('GivenDiscovering_WhenParsed_ThenItIsDiscovering', () {
      expect(IndexRunPhase.parse('discovering'), IndexRunPhase.discovering);
    });

    test('GivenNoPhase_WhenParsed_ThenItIsNull', () {
      expect(IndexRunPhase.parse(null), isNull);
    });
  });

  group('RunPriority', () {
    test('GivenLowPriority_WhenSpelledForTheWire_ThenItIsLowercase', () {
      expect(RunPriority.low.wire, 'low');
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/library_sources/domain/index_run_test.dart`
Expected: FAIL to compile — `paused` is not defined on `IndexRunStatus`.

- [ ] **Step 3: Replace the status enum**

In `lib/features/library_sources/domain/index_run.dart`, replace `IndexRunStatus` entirely:

```dart
/// Where a run is (System Requirements §4.8).
///
/// The core's own vocabulary. `interrupted` is gone: a run the application
/// was closed on now comes back `paused` and resumable, which is a different
/// fact and deserves a different word.
enum IndexRunStatus {
  /// The core is scanning right now.
  running,

  /// The run stopped and can be picked up where it left off.
  paused,

  /// The run finished.
  complete,

  /// The run stopped on an error, which the run carries.
  failed,

  /// The run was abandoned. Terminal, and not resumable.
  cancelled;

  /// The status [raw] names, or [IndexRunStatus.failed] for one this
  /// application does not know.
  ///
  /// Falling back to failed rather than throwing: a core that grows a status
  /// must not make the screen unreadable, and "something is wrong with this
  /// run" is the safe reading of a word we cannot interpret.
  static IndexRunStatus parse(String? raw) => switch (raw) {
    'running' => IndexRunStatus.running,
    'paused' => IndexRunStatus.paused,
    'complete' => IndexRunStatus.complete,
    'cancelled' => IndexRunStatus.cancelled,
    _ => IndexRunStatus.failed,
  };

  /// Whether the core is working on this run right now.
  ///
  /// A paused run is outstanding but not in flight — nothing is happening
  /// until the owner resumes it, which is why polling follows this rather
  /// than "is the run finished".
  bool get isInFlight => this == IndexRunStatus.running;

  /// Whether the run is over for good.
  bool get isTerminal =>
      this == IndexRunStatus.complete ||
      this == IndexRunStatus.failed ||
      this == IndexRunStatus.cancelled;
}

/// Which half of a run is executing (FR-FC-28).
///
/// `discovering` has no total yet — the walk is still counting what it will
/// have to do — so a percentage during it would be invented.
enum IndexRunPhase {
  discovering,
  processing;

  /// The phase [raw] names, or null for a run carrying none — which is every
  /// terminal run, and any run that never published one.
  static IndexRunPhase? parse(String? raw) => switch (raw) {
    'discovering' => IndexRunPhase.discovering,
    'processing' => IndexRunPhase.processing,
    _ => null,
  };
}
```

- [ ] **Step 4: Add the progress fields**

Add to the `IndexRun` factory, after `status`:

```dart
    /// Which half of the run is executing, or null once it is terminal.
    IndexRunPhase? phase,

    /// How many entries the run has to get through, once discovery has
    /// counted them. Null while discovery is still counting.
    int? total,

    /// How many entries the run has finished with. Null for a run that never
    /// published progress.
    int? processed,

    /// How long the run has spent *working* — elapsed time minus the time it
    /// spent paused. The input to a remaining-time estimate; wall time would
    /// overstate the work done by however long the owner left it paused.
    @Default(0) int activeMillis,

    /// When the run was paused, for a run that is paused right now.
    DateTime? pausedAt,
```

Add to `IndexRunCounts`, after `skipped`:

```dart
    /// Entries already in the catalog when the walk reached them. Distinct
    /// from `skipped`, which is an unsupported file type: a resumed run
    /// re-walks and meets everything an earlier segment indexed, and folding
    /// the two together would report thousands of files as skipped.
    @Default(0) int alreadyCataloged,
```

- [ ] **Step 5: Add the priority enum**

Create `lib/features/library_sources/domain/run_priority.dart`:

```dart
/// How hard a run should push (FR-FC-31).
///
/// Semantic rather than a thread count: the core maps each to a configured
/// concurrency, and this application has no business inventing a number.
enum RunPriority {
  /// The configured default pace.
  normal,

  /// Deliberately slower, so a large scan competes less with browsing and
  /// playback.
  low;

  /// How the core spells this on both its surfaces.
  String get wire => name;
}
```

- [ ] **Step 6: Run build_runner and the tests**

Run: `dart run build_runner build --delete-conflicting-outputs`
Then: `flutter test test/features/library_sources/domain/index_run_test.dart`
Expected: PASS.

- [ ] **Step 7: Fix every reference to the removed status**

Run `flutter analyze`. `IndexRunStatus.interrupted` is gone, so every `switch` and reference over it now fails. Follow the analyzer; expect hits in `library_sources_screen.dart` and its tests. A run that would have read "interrupted" now reads `paused`, and its copy should say so — but keep string changes minimal here; Task 8 rewrites this screen's copy properly.

- [ ] **Step 8: Run the full suite and commit**

Run: `flutter test`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "fix(library-sources): read the core's paused and cancelled runs

IndexRunStatus.parse falls back to failed for any word it does not know,
and it did not know paused or cancelled — so against the current core a
paused run displayed as failed. It also carried interrupted, which the
core removed when a closed application stopped losing its run.

Adds the phase, total, processed, activeMillis and pausedAt a run now
publishes, and the alreadyCataloged counter that keeps a resumed run's
tally honest."
```

---

### Task 2: Extend the FFI client

**Files:**
- Modify: `lib/core/bindings/core_client.dart`
- Modify: `lib/core/bindings/core_isolate.dart`
- Test: `test/core/bindings/core_client_test.dart` (follow whatever fake the existing binding tests use)

**Interfaces:**
- Consumes: regenerated `alexandria_bindings.dart` (see Prerequisite).
- Produces: on `CoreClient` — `Future<int> indexPause(String runId, String token)`, `Future<int> indexCancel(String runId, String token)`, `Future<CoreRunStart> indexResume(String runId, String? priority, String token)`, `Future<CoreJsonResponse> indexRunsActive(String token)`; and `indexStart`/`indexRefreshStart` gain a `String? priority` parameter.

- [ ] **Step 1: Confirm the prerequisite**

Run: `grep -c "alexandria_index_pause\|alexandria_index_resume\|alexandria_index_cancel\|alexandria_index_runs_active_json" lib/core/bindings/alexandria_bindings.dart`
Expected: a non-zero count. If zero, run `./tools/dev.ps1 -NoRun` first — the plan cannot proceed without it.

- [ ] **Step 2: Declare the new methods on the port**

In `lib/core/bindings/core_client.dart`, alongside `indexRunStatus`:

```dart
  /// Pauses a run so it can be resumed later (FR-FC-32).
  ///
  /// Returns the core's status code rather than a payload: there is nothing
  /// to read back, and the interesting outcomes are refusals — a run that is
  /// not running answers `RUN_ERR_INVALID_STATE`.
  Future<int> indexPause(String runId, String token);

  /// Abandons a run (FR-FC-34). Terminal; the run keeps its tally for the
  /// record but cannot be resumed.
  Future<int> indexCancel(String runId, String token);

  /// Resumes a paused run, optionally re-pacing it (FR-FC-33).
  ///
  /// `priority` is `"normal"`, `"low"`, or null meaning *keep the width the
  /// run already has* — which is not the same as `"normal"`, and is what
  /// keeps a plain resume from silently re-pacing a throttled scan.
  ///
  /// Answers with the same run id it was given, not a new one.
  Future<CoreRunStart> indexResume(String runId, String? priority, String token);

  /// Every run that is outstanding — running or paused (FR-FC-35).
  ///
  /// The whole picture in one call, which is what lets a client show
  /// background activity and offer resume at launch without tracking run ids
  /// itself.
  Future<CoreJsonResponse> indexRunsActive(String token);
```

Add `String? priority` as the last parameter of `indexStart` and `indexRefreshStart`, documenting that null means the core's default.

- [ ] **Step 3: Implement them in the isolate**

In `lib/core/bindings/core_isolate.dart`, extend the dispatch switch, following the `indexStart` and `indexRunStatus` arms exactly:

```dart
      'indexPause' => withNativeString(
        arguments.first! as String,
        (runId) => withNativeString(
          arguments[1]! as String,
          (token) => bindings.alexandria_index_pause(runId, token),
        ),
      ),

      'indexCancel' => withNativeString(
        arguments.first! as String,
        (runId) => withNativeString(
          arguments[1]! as String,
          (token) => bindings.alexandria_index_cancel(runId, token),
        ),
      ),
```

`indexResume` follows `indexStart`'s shape — three strings in, a `CoreRunStart` out, reading `run_id` through the same `_readRunId` helper.

**A null priority must reach the core as a null pointer**, not as `"null"` or `""` — the core reads absent as "keep the run's current width" and would read `""` as unrecognised, which happens to mean the same thing today but is relying on a coincidence. `withNativeString` takes a non-null `String`, so add a sibling beside it:

```dart
/// Runs [body] with a native string for [value], or with `nullptr` when it is
/// null — which is how an absent optional argument reaches the core.
///
/// Distinct from [withNativeString] deliberately: an empty string and an
/// absent one are different arguments, and collapsing them would let a
/// resume silently re-pace a run the owner throttled.
T withNullableNativeString<T>(
  String? value,
  T Function(Pointer<Char>) body,
) => value == null ? body(nullptr) : withNativeString(value, body);
```

`indexRunsActive` follows `indexRunStatus` — one string in, a `CoreJsonResponse` out, freeing the returned string with the same helper.

- [ ] **Step 4: Add the priority argument to the two starts**

Thread `String? priority` through both existing arms the same way.

- [ ] **Step 5: Test and commit**

Run: `flutter test test/core/bindings/`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(bindings): expose run pause, resume, cancel, and active runs

A null priority on resume means keep the run's current width, which is
deliberately not the same as normal — a plain resume must not silently
re-pace a scan the owner throttled."
```

---

### Task 3: Extend the gateway

**Files:**
- Modify: `lib/features/library_sources/domain/index_gateway.dart`
- Modify: `lib/features/library_sources/data/core_index_gateway.dart`
- Test: `test/features/library_sources/data/core_index_gateway_test.dart`

**Interfaces:**
- Consumes: Task 2's `CoreClient` methods; Task 1's `IndexRun` and `RunPriority`.
- Produces: on `IndexGateway` — `Future<RunControlOutcome> pauseRun({required String runId, required String credential})`, the same shape for `cancelRun`, `Future<IndexStartOutcome> resumeRun({required String runId, RunPriority? priority, required String credential})`, `Future<ActiveRunsOutcome> listActiveRuns({required String credential})`; `startIndex`/`startRefresh` gain `RunPriority? priority`. New sealed outcomes `RunControlOutcome.{ok, failed}` and `ActiveRunsOutcome.{read(List<IndexRun>), failed}`.

- [ ] **Step 1: Write the failing tests**

```dart
test('GivenARunThatIsNotRunning_WhenPaused_ThenItFailsWithInvalidState', () async {
  final gateway = CoreIndexGateway(FakeCoreClient(pauseStatus: runErrInvalidState));

  final outcome = await gateway.pauseRun(runId: 'r1', credential: 't');

  expect(outcome, isA<RunControlFailed>());
});

test('GivenOutstandingRuns_WhenListed_ThenEachIsParsedWithItsProgress', () async {
  final gateway = CoreIndexGateway(FakeCoreClient(activeRunsJson: '''
    [{"runId":"r1","kind":"index","status":"running","root":"D:/Music",
      "phase":"processing","total":12264,"processed":8412,"activeMillis":90000}]
  '''));

  final outcome = await gateway.listActiveRuns(credential: 't');

  final runs = (outcome as ActiveRunsRead).runs;
  expect(runs.single.processed, 8412);
  expect(runs.single.phase, IndexRunPhase.processing);
});

test('GivenAResume_WhenTheCoreAnswers_ThenTheSameRunIdComesBack', () async {
  final gateway = CoreIndexGateway(FakeCoreClient(resumeRunId: 'r1'));

  final outcome = await gateway.resumeRun(runId: 'r1', credential: 't');

  expect((outcome as IndexStarted).runId, 'r1');
});
```

Extend whatever fake the existing tests in this file use rather than writing a second one.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/library_sources/data/core_index_gateway_test.dart`
Expected: FAIL to compile — `pauseRun` is not defined.

- [ ] **Step 3: Add the outcome types and port methods**

In `index_gateway.dart`, add two sealed unions beside the existing ones:

```dart
/// What a pause or cancel produced.
///
/// No payload on success: the run's new state is read back through the
/// status query like any other, and inventing a return value here would give
/// callers a second, staler source for it.
@freezed
sealed class RunControlOutcome with _$RunControlOutcome {
  const factory RunControlOutcome.ok() = RunControlOk;
  const factory RunControlOutcome.failed({required Failure failure}) =
      RunControlFailed;
}

/// What listing the outstanding runs produced.
@freezed
sealed class ActiveRunsOutcome with _$ActiveRunsOutcome {
  const factory ActiveRunsOutcome.read({required List<IndexRun> runs}) =
      ActiveRunsRead;
  const factory ActiveRunsOutcome.failed({required Failure failure}) =
      ActiveRunsFailed;
}
```

Add the four methods to the `IndexGateway` interface with doc comments, and `RunPriority? priority` to `startIndex` and `startRefresh`.

- [ ] **Step 4: Implement in `CoreIndexGateway`**

Follow `readRun`'s existing shape: try the call, map `CoreCallException` to `Failure.unexpected`, check `CoreStatusFamily.run.isOk`, and map a non-OK status through `mapCoreStatus(CoreStatusFamily.run, status)`.

`listActiveRuns` parses a JSON **array**, mapping each element through the existing `_runFrom`. Extend `_runFrom` to read the new fields:

```dart
      phase: IndexRunPhase.parse(body['phase'] as String?),
      total: body['total'] as int?,
      processed: body['processed'] as int?,
      activeMillis: body['activeMillis'] as int? ?? 0,
      pausedAt: switch (body['pausedAt']) {
        final String raw => DateTime.tryParse(raw),
        _ => null,
      },
```

and add `alreadyCataloged: body['alreadyCataloged'] as int? ?? 0` to the counts, plus `'alreadyCataloged'` to the `countKeys` list that decides whether any tally is present.

- [ ] **Step 5: Run tests and commit**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/library_sources/`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(library-sources): gateway support for run control and progress"
```

---

### Task 4: The time estimate, as a pure function

**Files:**
- Create: `lib/features/library_sources/domain/run_estimate.dart`
- Test: `test/features/library_sources/domain/run_estimate_test.dart`

**Interfaces:**
- Produces: `class RunSample { final int processed; final int activeMillis; }`; `Duration? estimateRemaining(List<RunSample> samples, {required int total})`.

**Why this is its own task:** this is the piece most likely to make the feature feel broken, and testing it through a widget would make its edge cases hard to reach. It has no Flutter dependency at all.

- [ ] **Step 1: Write the failing tests**

```dart
void main() {
  group('estimateRemaining', () {
    test('GivenTooFewSamples_WhenEstimated_ThenThereIsNoEstimate', () {
      final samples = [const RunSample(processed: 100, activeMillis: 1000)];

      expect(estimateRemaining(samples, total: 12264), isNull);
    });

    test('GivenASteadyRate_WhenEstimated_ThenItIsTheRemainingWorkOverThatRate', () {
      // 100 entries per second, 900 left to do.
      final samples = [
        const RunSample(processed: 100, activeMillis: 1000),
        const RunSample(processed: 200, activeMillis: 2000),
        const RunSample(processed: 300, activeMillis: 3000),
      ];

      expect(estimateRemaining(samples, total: 1200), const Duration(seconds: 9));
    });

    test('GivenNoProgressBetweenSamples_WhenEstimated_ThenThereIsNoEstimate', () {
      // A stalled window would divide by zero and report infinity.
      final samples = [
        const RunSample(processed: 300, activeMillis: 1000),
        const RunSample(processed: 300, activeMillis: 2000),
        const RunSample(processed: 300, activeMillis: 3000),
      ];

      expect(estimateRemaining(samples, total: 1200), isNull);
    });

    test('GivenNoActiveTimeBetweenSamples_WhenEstimated_ThenThereIsNoEstimate', () {
      // activeMillis stands still while a run is paused. Dividing by it would
      // be dividing by zero; reporting a figure from it would be reporting
      // progress made during a pause.
      final samples = [
        const RunSample(processed: 100, activeMillis: 5000),
        const RunSample(processed: 200, activeMillis: 5000),
        const RunSample(processed: 300, activeMillis: 5000),
      ];

      expect(estimateRemaining(samples, total: 1200), isNull);
    });

    test('GivenAWildlySwingingRate_WhenEstimated_ThenThereIsNoEstimate', () {
      // The first window says 1000/sec, the last says 10/sec. An estimate
      // from this would swing by two orders of magnitude between polls, and
      // a number that moves like that is worse than no number.
      final samples = [
        const RunSample(processed: 1000, activeMillis: 1000),
        const RunSample(processed: 1010, activeMillis: 2000),
        const RunSample(processed: 1020, activeMillis: 3000),
      ];

      expect(estimateRemaining(samples, total: 12264), isNull);
    });

    test('GivenTheWorkIsDone_WhenEstimated_ThenItIsZero', () {
      final samples = [
        const RunSample(processed: 1198, activeMillis: 1000),
        const RunSample(processed: 1199, activeMillis: 2000),
        const RunSample(processed: 1200, activeMillis: 3000),
      ];

      expect(estimateRemaining(samples, total: 1200), Duration.zero);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/library_sources/domain/run_estimate_test.dart`
Expected: FAIL to compile — `estimateRemaining` is not defined.

- [ ] **Step 3: Implement**

```dart
/// One observation of a run's progress.
///
/// `activeMillis` is time the run spent *working*, which the core reports
/// with paused stretches already subtracted. Using wall time here would
/// overstate the work done by however long the owner left the run paused.
class RunSample {
  const RunSample({required this.processed, required this.activeMillis});

  final int processed;
  final int activeMillis;
}

/// How many samples a window needs before it is worth trusting.
const int _minimumSamples = 3;

/// How far the fastest and slowest observed rates may differ before the
/// window is called unsteady.
///
/// A run's rate genuinely varies — a folder of small text files and a folder
/// of tagged FLACs are different work — so some spread is expected. Beyond
/// this, the estimate would swing far enough between polls to read as broken,
/// and showing nothing is the more honest answer.
const double _maximumRateSpread = 4.0;

/// How long the run has left, or null when no honest estimate can be made.
///
/// Returns null rather than a guess when: there are too few samples, the run
/// made no progress across the window, no active time elapsed (it is paused),
/// or the observed rate is too unsteady to extrapolate from. Each of those
/// would otherwise produce a figure — infinity, or one swinging by orders of
/// magnitude between polls — that is worse than an absent one.
Duration? estimateRemaining(List<RunSample> samples, {required int total}) {
  if (samples.length < _minimumSamples) return null;

  final rates = <double>[];
  for (var i = 1; i < samples.length; i++) {
    final deltaProcessed = samples[i].processed - samples[i - 1].processed;
    final deltaMillis = samples[i].activeMillis - samples[i - 1].activeMillis;
    if (deltaMillis <= 0) return null;
    rates.add(deltaProcessed / deltaMillis);
  }

  final fastest = rates.reduce((a, b) => a > b ? a : b);
  final slowest = rates.reduce((a, b) => a < b ? a : b);
  if (fastest <= 0) return null;
  if (slowest <= 0 || fastest / slowest > _maximumRateSpread) return null;

  final remaining = total - samples.last.processed;
  if (remaining <= 0) return Duration.zero;

  final overall =
      (samples.last.processed - samples.first.processed) /
      (samples.last.activeMillis - samples.first.activeMillis);

  return Duration(milliseconds: (remaining / overall).round());
}
```

- [ ] **Step 4: Run the tests and commit**

Run: `flutter test test/features/library_sources/domain/run_estimate_test.dart`
Expected: PASS.

```bash
dart format . && flutter analyze
git add lib/features/library_sources/domain/run_estimate.dart test/features/library_sources/domain/run_estimate_test.dart
git commit -m "feat(library-sources): estimate a run's remaining time, or decline to

Returns null rather than a figure whenever one would mislead: too few
samples, a stalled window, a paused run whose active time is not moving,
or a rate too unsteady to extrapolate from. A time remaining that swings
between two minutes and forty is worse than none at all."
```

---

### Task 5: The active-runs controller

**Files:**
- Create: `lib/features/library_sources/application/active_runs_controller.dart`
- Create: `lib/features/library_sources/application/active_runs_state.dart`
- Modify: `lib/core/di/providers.dart` (register the provider)
- Test: `test/features/library_sources/application/active_runs_controller_test.dart`

**Interfaces:**
- Consumes: Task 3's `IndexGateway.listActiveRuns`, Task 4's `RunSample`/`estimateRemaining`, `SessionController.credential`.
- Produces: `activeRunsControllerProvider`; `ActiveRunsState` with `List<IndexRun> runs`, `Map<String, List<RunSample>> samples`, `IndexRun? justFinished`, `Failure? failure`; `ActiveRunsController.{refresh, pause, resume, cancel, dismissFinished}`.

- [ ] **Step 1: Write the failing tests**

```dart
test('GivenAPausedRunAtLaunch_WhenRefreshed_ThenItIsReported', () async {
  final container = harness(gateway: FakeGateway(active: [pausedRun]));

  await container.read(activeRunsControllerProvider.notifier).refresh();

  expect(container.read(activeRunsControllerProvider).runs.single.status,
      IndexRunStatus.paused);
});

// A paused run makes no progress, so polling it changes nothing. Its state
// moves only when the owner acts, and the action's own response updates the
// strip.
test('GivenOnlyPausedRuns_WhenRefreshed_ThenPollingStops', () async {
  final container = harness(gateway: FakeGateway(active: [pausedRun]));
  final controller = container.read(activeRunsControllerProvider.notifier);

  await controller.refresh();

  expect(controller.debugIsPolling, isFalse);
});

test('GivenARunningRun_WhenRefreshed_ThenPollingContinues', () async {
  final container = harness(gateway: FakeGateway(active: [runningRun]));
  final controller = container.read(activeRunsControllerProvider.notifier);

  await controller.refresh();

  expect(controller.debugIsPolling, isTrue);
});

// Showing nothing because one read failed would report "no work running" on
// no evidence.
test('GivenAFailedPoll_WhenRefreshed_ThenTheKnownRunsAreKept', () async {
  final gateway = FakeGateway(active: [runningRun]);
  final container = harness(gateway: gateway);
  final controller = container.read(activeRunsControllerProvider.notifier);
  await controller.refresh();

  gateway.failNext = true;
  await controller.refresh();

  expect(container.read(activeRunsControllerProvider).runs, hasLength(1));
});

test('GivenARunThatDisappeared_WhenRefreshed_ThenItIsHeldAsJustFinished', () async {
  final gateway = FakeGateway(active: [runningRun]);
  final container = harness(gateway: gateway);
  final controller = container.read(activeRunsControllerProvider.notifier);
  await controller.refresh();

  gateway.active = [];
  await controller.refresh();

  expect(container.read(activeRunsControllerProvider).justFinished?.runId,
      runningRun.runId);
});

test('GivenAControlCallRefusedForState_WhenPaused_ThenTheRunsAreRereadNotErrored', () async {
  final gateway = FakeGateway(active: [runningRun], pauseFails: true);
  final container = harness(gateway: gateway);
  final controller = container.read(activeRunsControllerProvider.notifier);

  await controller.pause(runningRun.runId);

  expect(container.read(activeRunsControllerProvider).failure, isNull);
  expect(gateway.listCalls, greaterThan(0));
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/library_sources/application/active_runs_controller_test.dart`
Expected: FAIL — `activeRunsControllerProvider` is not defined.

- [ ] **Step 3: Implement the state and controller**

`ActiveRunsState` is a Freezed class with the fields named above plus conveniences: `bool get hasWork => runs.isNotEmpty`, `bool get anyRunning => runs.any((r) => r.isInFlight)`, and `IndexRun? get single => runs.length == 1 ? runs.single : null`.

The controller follows `IndexRunsController`'s existing shape — a `Notifier`, reading `indexGatewayProvider`, `sessionControllerProvider.notifier` and `runPollIntervalProvider` in `build`, with `ref.onDispose(_stopPolling)`.

Behaviour, each point matching a test above:
- `refresh()` calls `listActiveRuns`, replaces `runs`, appends a `RunSample` per running run, and starts or stops the timer on `state.anyRunning`.
- A run present last time and absent now becomes `justFinished`, cleared by `dismissFinished()`.
- A failed poll keeps the previous `runs` and records `failure`.
- An `UnauthorizedFailure` stops polling and calls `_session.invalidate`.
- `pause`, `resume` and `cancel` call the gateway then `refresh()` immediately, so the strip reflects the new state without waiting for the next tick. **A `RunControlFailed` is not surfaced as an error** — the run moved on, and re-reading it is the correct response.
- `resume(runId, priority)` passes the priority through; null means keep the current width.
- Cap `samples` per run at the last 10 entries so the list cannot grow without bound over a long scan.

Expose `bool get debugIsPolling` guarded by a comment saying it exists for the tests.

- [ ] **Step 4: Register the provider**

Add to `lib/core/di/providers.dart` following the neighbouring `indexRunsControllerProvider`.

- [ ] **Step 5: Run tests and commit**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/library_sources/`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(library-sources): track every outstanding run in one place

Polling follows running, not outstanding: a paused run makes no progress,
so polling it changes nothing and its state moves only when the owner
acts. A failed poll keeps the runs it already knew rather than reporting
no work on no evidence."
```

---

### Task 6: The background activity strip

**Files:**
- Create: `lib/features/shell/presentation/background_activity_strip.dart`
- Modify: `lib/features/shell/presentation/shell_screen.dart:30-49`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/shell/presentation/background_activity_strip_test.dart`

**Interfaces:**
- Consumes: Task 5's `activeRunsControllerProvider`, Task 4's `estimateRemaining`.
- Produces: `BackgroundActivityStrip` widget; `static const double collapsedHeight = 0` and `expandedHeight = 40`.

- [ ] **Step 1: Add the strings**

To `app_en.arb` (and translated equivalents in `app_pt.arb`):

```json
  "activityDiscovering": "Scanning folders…",
  "activityProgress": "{processed} of {total}",
  "activityRemaining": "about {duration} left",
  "activityPaused": "Paused — {processed} of {total}",
  "activityAggregate": "Indexing {count} folders — {processed} of {total}",
  "activityComplete": "Finished indexing {folder}",
  "activityFailed": "Indexing {folder} failed",
  "activityRepacing": "Re-checking from the start at low speed",
  "activityPause": "Pause",
  "activityResume": "Resume",
  "activityCancel": "Cancel",
  "activityViewAll": "View",
  "activityPriorityLow": "Low",
  "activityPriorityNormal": "Normal",
```

Run `flutter gen-l10n`.

- [ ] **Step 2: Write the failing tests**

```dart
testWidgets('GivenNoRuns_WhenBuilt_ThenTheStripTakesNoHeight', (tester) async {
  await pumpStrip(tester, runs: []);

  expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);
});

// A run still counting what it will have to do has no total, so a
// percentage would be invented.
testWidgets('GivenADiscoveringRun_WhenBuilt_ThenThereIsNoPercentageAndNoEstimate',
    (tester) async {
  await pumpStrip(tester, runs: [discoveringRun]);

  final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator));
  expect(bar.value, isNull);
  expect(find.textContaining('left'), findsNothing);
});

testWidgets('GivenAProcessingRun_WhenBuilt_ThenCountsAreShown', (tester) async {
  await pumpStrip(tester, runs: [processingRun]);

  expect(find.textContaining('8,412'), findsOneWidget);
  expect(find.textContaining('12,264'), findsOneWidget);
});

testWidgets('GivenAPausedRun_WhenBuilt_ThenResumeIsOffered', (tester) async {
  await pumpStrip(tester, runs: [pausedRun]);

  expect(find.byTooltip('Resume'), findsOneWidget);
  expect(find.byTooltip('Pause'), findsNothing);
});

testWidgets('GivenTwoRuns_WhenBuilt_ThenOneAggregateRowIsShown', (tester) async {
  await pumpStrip(tester, runs: [processingRun, secondRun]);

  expect(find.textContaining('2 folders'), findsOneWidget);
  expect(find.byTooltip('Pause'), findsNothing);
  expect(find.text('View'), findsOneWidget);
});

// A failure that vanishes unseen is worse than a strip that lingers.
testWidgets('GivenAFailedRun_WhenTimePasses_ThenTheStripStays', (tester) async {
  await pumpStrip(tester, justFinished: failedRun);
  await tester.pump(const Duration(seconds: 10));

  expect(find.byType(BackgroundActivityStrip), findsOneWidget);
  expect(find.textContaining('failed'), findsOneWidget);
});

testWidgets('GivenACompletedRun_WhenTimePasses_ThenTheStripDismissesItself',
    (tester) async {
  await pumpStrip(tester, justFinished: completedRun);
  expect(find.textContaining('Finished'), findsOneWidget);

  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();

  expect(tester.getSize(find.byType(BackgroundActivityStrip)).height, 0);
});

// Re-pacing a running run means pause then resume, and resume resets the
// segment — so the bar returns to zero. The strip has to say that, or the
// reset reads as lost work.
testWidgets('GivenARunningRun_WhenRePacedToLow_ThenItPausesResumesAndSaysSo',
    (tester) async {
  final controller = RecordingActiveRunsController();
  await pumpStrip(tester, runs: [processingRun], controller: controller);

  await tester.tap(find.byTooltip('Normal'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Low'));
  await tester.pumpAndSettle();

  expect(controller.calls, ['pause:r1', 'resume:r1:low']);
  expect(find.textContaining('Re-checking from the start'), findsOneWidget);
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/shell/presentation/background_activity_strip_test.dart`
Expected: FAIL — `BackgroundActivityStrip` is not defined.

- [ ] **Step 4: Implement the strip**

A `ConsumerStatefulWidget` — stateful because the auto-dismiss timer and the sample window belong to it.

Structure: an `AnimatedSize` (200ms, `Curves.easeOut`) wrapping either a `SizedBox.shrink()` when there is nothing to show, or a `Material` row of height 40 containing, left to right: a kind icon, the label, an `Expanded` `LinearProgressIndicator`, the counts, the estimate, then the controls.

Rules, each matching a test:
- Nothing to show when `runs.isEmpty && justFinished == null`.
- `phase == discovering` → indeterminate bar (`value: null`), "Scanning folders…", no counts, no estimate.
- `phase == processing` → `value: processed / total`, counts, and the estimate **only when `estimateRemaining` returns non-null**.
- `runs.length > 1` → aggregate row, controls replaced by a single "View" action opening `LibrarySourcesScreen.show(context)`.
- A paused run → resume in place of pause; the row stays visible.
- `justFinished` complete → outcome text, then a 4-second timer dismisses it via `dismissFinished()`. Cancel that timer in `dispose`.
- `justFinished` failed → outcome text with a manual dismiss button and **no timer**.
- The priority control calls `pause` then `resume(priority)` and shows `activityRepacing` while it does, because resume resets the segment and the bar will visibly return to zero.

Wrap the row in `Semantics(container: true, label: …)` as `PlaybackBar` does.

- [ ] **Step 5: Insert it into the shell**

In `shell_screen.dart`, between the `Expanded` content row and the existing `Divider`:

```dart
          const BackgroundActivityStrip(),
          const Divider(height: 1, thickness: 1),
          const PlaybackBar(),
```

- [ ] **Step 6: Run the tests and commit**

Run: `flutter test`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(shell): show background indexing above the playback bar

The strip takes no height when nothing is running, so the shell is
unchanged for anyone not indexing. It refuses to show a percentage while
discovery is still counting, and refuses an estimate until the rate is
steady enough to extrapolate from.

A paused run keeps the strip on screen, which doubles as the resume offer
at launch. A completed run dismisses itself; a failed one waits to be
seen."
```

---

### Task 7: Index a folder when it is registered

**Files:**
- Modify: `lib/features/library_sources/application/library_sources_controller.dart:41-46`
- Modify: `lib/features/library_sources/presentation/library_sources_screen.dart:127-147`
- Test: `test/features/library_sources/presentation/library_sources_screen_test.dart`

**Interfaces:**
- Consumes: `IndexRunsController.startIndex`.
- Produces: `Future<LibrarySource?> registerFolder({required Future<bool> Function(String, LibrarySource) onOverlapConfirmed})` — null when cancelled or refused.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('GivenAFolderIsRegistered_WhenAdded_ThenItIsIndexedWithoutASecondClick',
    (tester) async {
  final gateway = FakeIndexGateway();
  await pumpSourcesScreen(tester, gateway: gateway, picker: PickerReturning('D:/Music'));

  await tester.tap(find.text('Add folder'));
  await tester.pumpAndSettle();

  expect(gateway.startedRoots, ['D:/Music']);
});

// The negative is what catches a naive implementation: chaining on the call
// rather than on its result would index a folder the controller refused.
testWidgets('GivenARefusedFolder_WhenAdded_ThenNothingIsIndexed', (tester) async {
  final gateway = FakeIndexGateway();
  await pumpSourcesScreen(
    tester,
    gateway: gateway,
    picker: PickerReturning('D:/Missing'),
    probe: ProbeSaying(exists: false),
  );

  await tester.tap(find.text('Add folder'));
  await tester.pumpAndSettle();

  expect(gateway.startedRoots, isEmpty);
});

testWidgets('GivenThePickerIsCancelled_WhenAdded_ThenNothingIsIndexed',
    (tester) async {
  final gateway = FakeIndexGateway();
  await pumpSourcesScreen(tester, gateway: gateway, picker: PickerReturning(null));

  await tester.tap(find.text('Add folder'));
  await tester.pumpAndSettle();

  expect(gateway.startedRoots, isEmpty);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/library_sources/presentation/library_sources_screen_test.dart`
Expected: FAIL — no run is started.

- [ ] **Step 3: Return what was registered**

Change `registerFolder`'s signature to `Future<LibrarySource?>`. Return `null` on every path that changes nothing — the picker was cancelled, the verdict refuses, the overlap confirmation was declined — and the newly created `LibrarySource` on success.

Document why: *the caller needs to know what was registered so it can index it, and a void return forced the screen to guess from state.*

- [ ] **Step 4: Chain in the screen**

In `_addFolder`, capture the result and start a run when it is non-null:

```dart
    final registered = await ref
        .read(librarySourcesControllerProvider.notifier)
        .registerFolder(onOverlapConfirmed: …);

    // Registering a folder is a request to have it in the library, and a
    // library folder that is not indexed is not in the library yet. Chained
    // here rather than inside either controller so registration and runs
    // stay separately testable.
    if (registered == null) return;
    await ref
        .read(indexRunsControllerProvider.notifier)
        .startIndex(registered.path);
```

- [ ] **Step 5: Run tests and commit**

Run: `flutter test`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(library-sources): index a folder when it is registered

registerFolder returned void, so the screen had no way to know what it
had registered and adding a folder took a second, separate click to
index. It now returns the source it created, or null on every path that
changed nothing."
```

---

### Task 8: Per-folder controls and honest labels

**Files:**
- Modify: `lib/features/library_sources/presentation/library_sources_screen.dart`
- Modify: `lib/features/library_sources/application/index_runs_controller.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/library_sources/presentation/library_sources_screen_test.dart`

**Interfaces:**
- Consumes: Task 5's controller methods.
- Produces: per-row controls; `IndexRunsController.{pause, resume, cancel}` delegating to the gateway.

- [ ] **Step 1: Rename the actions**

Three operations exist and today's labels blur them. In both ARB files:

- the per-folder action becomes **"Rescan"** (`librarySourcesRescan`) — its job now that first add is automatic
- the catalog-wide action becomes **"Re-check library"** (`librarySourcesRecheck`)

Add `librarySourcesPause`, `librarySourcesResume`, `librarySourcesCancelRun`, and `librarySourcesCancelRunConfirm` for the confirmation body. Run `flutter gen-l10n`.

- [ ] **Step 2: Write the failing tests**

```dart
testWidgets('GivenARowWithARunningRun_WhenBuilt_ThenPauseAndCancelAreOffered',
    (tester) async {
  await pumpSourcesScreen(tester, runs: {'D:/Music': runningRun});

  expect(find.byTooltip('Pause'), findsOneWidget);
  expect(find.byTooltip('Cancel'), findsOneWidget);
  expect(find.text('Rescan'), findsNothing);
});

testWidgets('GivenARowWithAPausedRun_WhenBuilt_ThenResumeIsOffered', (tester) async {
  await pumpSourcesScreen(tester, runs: {'D:/Music': pausedRun});

  expect(find.byTooltip('Resume'), findsOneWidget);
});

testWidgets('GivenARowWithNoRun_WhenBuilt_ThenRescanIsOffered', (tester) async {
  await pumpSourcesScreen(tester, runs: {});

  expect(find.text('Rescan'), findsOneWidget);
});

// Cancel is terminal and not resumable, so it asks first.
testWidgets('GivenARunningRun_WhenCancelIsTapped_ThenItConfirmsFirst',
    (tester) async {
  final gateway = FakeIndexGateway();
  await pumpSourcesScreen(tester, gateway: gateway, runs: {'D:/Music': runningRun});

  await tester.tap(find.byTooltip('Cancel'));
  await tester.pumpAndSettle();

  expect(gateway.cancelledRuns, isEmpty);
  expect(find.byType(AlertDialog), findsOneWidget);
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/library_sources/presentation/library_sources_screen_test.dart`
Expected: FAIL — no pause control exists.

- [ ] **Step 4: Add the controller methods**

`IndexRunsController` gains `pause(String root)`, `resume(String root, {RunPriority? priority})` and `cancel(String root)`, each resolving the row's run id from `state`, calling the gateway, and re-polling that run. Follow the existing `startIndex` shape for credential handling and `UnauthorizedFailure`.

- [ ] **Step 5: Build the row controls**

In `_SourceList`'s row builder, choose controls from the row's run state: running → pause + cancel + priority; paused → resume + cancel; none or terminal → Rescan. Cancel routes through the shell's existing `ConfirmationDialog.show`, as deletion flows already do.

- [ ] **Step 6: Run tests and commit**

Run: `flutter test`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(library-sources): control each folder's run from its own row

Indexing a folder, re-checking the catalog, and rescanning a folder are
three different operations that shared two ambiguous labels. The
per-folder action is now Rescan and the catalog-wide one Re-check
library.

Each row offers what its own state affords, which is what makes a
specific run addressable once the activity strip collapses to an
aggregate."
```

---

### Task 9: The rail

**Files:**
- Create: `lib/features/shell/presentation/rail_action.dart`
- Modify: `lib/features/shell/presentation/shell_navigation_panel.dart:84-95`
- Modify: `lib/features/shell/presentation/library_tools_button.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/shell/presentation/shell_navigation_panel_test.dart` and goldens

**Interfaces:**
- Produces: `RailAction({required IconData icon, required String label, required VoidCallback onPressed, bool showsDisclosure})`.

- [ ] **Step 1: Add the strings**

`libraryToolsLabel` = "Library", `preferencesLabel` = "Preferences", and three menu headings: `libraryToolsGroupLibrary` = "Library", `libraryToolsGroupTracking` = "Tracking", `libraryToolsGroupReview` = "Review". Both ARB files, then `flutter gen-l10n`.

- [ ] **Step 2: Write the failing tests**

```dart
testWidgets('GivenTheExtendedBreakpoint_WhenBuilt_ThenBothActionsShowLabels',
    (tester) async {
  await pumpPanel(tester, width: 1400);

  expect(find.text('Library'), findsOneWidget);
  expect(find.text('Preferences'), findsOneWidget);
});

// FR-UX-02: no entry is dropped at any breakpoint. At the minimum window the
// label becomes a tooltip rather than disappearing.
testWidgets('GivenTheMinimumBreakpoint_WhenBuilt_ThenBothActionsKeepTooltips',
    (tester) async {
  await pumpPanel(tester, width: 640);

  expect(find.byTooltip('Library'), findsOneWidget);
  expect(find.byTooltip('Preferences'), findsOneWidget);
});

testWidgets('GivenTheToolsMenu_WhenOpened_ThenItsSixScreensAreGrouped',
    (tester) async {
  await pumpPanel(tester, width: 1400);
  await tester.tap(find.text('Library'));
  await tester.pumpAndSettle();

  expect(find.text('Tracking'), findsOneWidget);
  expect(find.text('Review'), findsOneWidget);
  expect(find.text('Watchlists'), findsOneWidget);
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/shell/presentation/shell_navigation_panel_test.dart`
Expected: FAIL — no text 'Library' is rendered; the trigger is an unlabelled icon.

- [ ] **Step 4: Build `RailAction`**

A stateless widget that reads `Breakpoint.from(context)` and renders to match `NavigationRailDestination`'s presentation at each tier: icon with a `Tooltip` when `!showsNavigationLabels`; icon above a label when `showsNavigationLabels && !usesExtendedNavigation`; icon beside a label when `usesExtendedNavigation`. A trailing chevron when `showsDisclosure`.

Document that it deliberately mirrors the rail's own presentation without being selectable, so these read as actions rather than a lesser class of control.

- [ ] **Step 5: Use it**

In `shell_navigation_panel.dart`, replace the `trailing` column's two bare buttons with a `Divider` above two `RailAction`s. In `library_tools_button.dart`, replace the `IconButton` builder with a `RailAction` carrying `showsDisclosure: true`, and add the three section headings to `menuChildren` — keeping the existing item order, which the file's comment records as deliberate.

- [ ] **Step 6: Update goldens and commit**

Run: `flutter test --update-goldens test/features/shell/`
Review each changed golden image before staging it — an unreviewed golden update defeats the test.
Then: `flutter test`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "feat(shell): make the rail's two actions look like what they are

They were bare icon buttons sitting in a column of labelled entries, so
they read as a lesser class of control, and the tools menu hid six
unrelated screens behind an unlabelled widgets icon.

Both now render with the rail's own icon-and-label treatment at every
breakpoint, and the menu groups its screens under Library, Tracking and
Review. They are not promoted into the rail: FR-UX-02 forbids dropping an
entry, and the panel is already nine destinations tall at the minimum
window."
```

---

### Task 10: Restore the text editor's concurrent-modification check

**This is a regression the core change introduced here, not a new feature.**
`TextEditorController` implements UC-33 AF-05 — "something else wrote this file
while you had it open" — by holding `_hashWhenLoaded` (`text_editor_controller.dart:138`)
and comparing it in `_changedOnDisk` (`:313`). Indexing no longer computes a
content hash, so `content_hash` is `NULL` for any file the owner has not
already edited, and both gateways coerce that to `''`
(`core_catalog_gateway.dart:317`, `core_text_content_gateway.dart:96`). Both
sides of the comparison are then the empty string, they match, and **no
concurrent modification is detected on a first edit.** After one save the
editor writes a real hash and the check works again — which is what makes this
easy to miss.

The fix is to compare the signal the rest of the system now uses: size and
mtime.

**Files:**
- Modify: `lib/features/catalog/domain/catalog_file.dart:35-41`
- Modify: `lib/features/catalog/data/core_catalog_gateway.dart:317`
- Modify: `lib/features/editing/data/core_text_content_gateway.dart:96`
- Modify: `lib/features/editing/application/text_editor_controller.dart:138,149,225,313-320`
- Modify: `lib/features/editing/presentation/text_editor_screen.dart:38`
- Test: `test/features/editing/application/text_editor_controller_test.dart`

**Interfaces:**
- Produces: `CatalogFile` gains `int? sizeBytes` and `DateTime? mtime`; `TextEditorController.open` takes `{required String uuid, required String name, required FileStamp stamp}` where `FileStamp` is a small value type holding `sizeBytes` and `mtime` with value equality.

- [ ] **Step 1: Write the failing tests**

```dart
// The regression, pinned. Before this task both hashes are '' and the save
// goes through as though nothing had happened.
test('GivenAFileWithNoHash_WhenItChangedOnDisk_ThenTheSaveIsRefused', () async {
  final harness = EditorHarness(
    openedWith: const FileStamp(sizeBytes: 120, mtime: null),
    onDisk: const FileStamp(sizeBytes: 340, mtime: null),
  );

  await harness.controller.save();

  expect(harness.controller.state.stage, EditorStage.conflict);
  expect(harness.gateway.writes, isEmpty);
});

test('GivenAnUnchangedFile_WhenSaved_ThenItIsWritten', () async {
  final harness = EditorHarness(
    openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
    onDisk: FileStamp(sizeBytes: 120, mtime: t(1)),
  );

  await harness.controller.save();

  expect(harness.gateway.writes, hasLength(1));
});

// mtime alone moving is a change even at identical length — that is the
// common shape of an external edit.
test('GivenOnlyTheMtimeMoved_WhenSaved_ThenTheSaveIsRefused', () async {
  final harness = EditorHarness(
    openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
    onDisk: FileStamp(sizeBytes: 120, mtime: t(2)),
  );

  await harness.controller.save();

  expect(harness.controller.state.stage, EditorStage.conflict);
});

test('GivenAWrittenFile_WhenSavedAgain_ThenItComparesAgainstTheNewStamp',
    () async {
  final harness = EditorHarness(
    openedWith: FileStamp(sizeBytes: 120, mtime: t(1)),
    onDisk: FileStamp(sizeBytes: 120, mtime: t(1)),
  );
  await harness.controller.save();
  harness.onDisk = FileStamp(sizeBytes: 200, mtime: t(2));
  harness.writeReturns = FileStamp(sizeBytes: 200, mtime: t(2));

  await harness.controller.save();

  expect(harness.gateway.writes, hasLength(2));
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/editing/application/text_editor_controller_test.dart`
Expected: FAIL to compile — `FileStamp` is not defined. Before writing it, temporarily run the first test against the current `contentHash` comparison to see the regression itself: it passes the save through. Note that observation in your report; it is the evidence this task exists.

- [ ] **Step 3: Add the stamp to the model**

Create `FileStamp` beside `CatalogFile` — a small value type with `sizeBytes` and `mtime`, Freezed for equality, and a doc comment saying it is the change signal the catalog uses now that a content hash is no longer generally computed.

Add `int? sizeBytes` and `DateTime? mtime` to `CatalogFile`, and a `FileStamp get stamp` convenience.

- [ ] **Step 4: Parse them in both gateways**

`core_catalog_gateway.dart:317` and `core_text_content_gateway.dart:96` both build a `CatalogFile` from a row. Add to each:

```dart
          sizeBytes: row['sizeBytes'] as int?,
          mtime: switch (row['mtime']) {
            final String raw => DateTime.tryParse(raw),
            _ => null,
          },
```

- [ ] **Step 5: Compare stamps in the editor**

Replace `_hashWhenLoaded` with `_stampWhenLoaded`, `open`'s `contentHash` parameter with `stamp`, the assignment at `:225` with the written file's stamp, and `_changedOnDisk` with a stamp comparison. Update the caller at `text_editor_screen.dart:38`.

Keep `_changedOnDisk`'s existing tolerance: a catalog read that fails must not make the editor unusable, so an unreadable stamp answers "unchanged" exactly as the hash version did — say so in the comment.

Note the inherited blind spot in the doc comment: an in-place edit to an identical byte length with a preserved mtime reads as unchanged, the same limitation re-index accepts.

- [ ] **Step 6: Run the tests and commit**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test`
Expected: PASS.

```bash
dart format . && flutter analyze
git add -A
git commit -m "fix(editing): detect a file changed under the editor again

UC-33 AF-05 compared the content hash at load against the one at save.
Indexing no longer computes a hash, so content_hash is NULL for any file
never edited, both gateways coerce that to an empty string, and the
comparison became vacuous — a concurrent write went undetected on every
first edit. It started working again only after one save had stored a
real hash, which is what made it easy to miss.

The editor now compares size and mtime, the same change signal indexing
and re-index adopted. It inherits that signal's blind spot: an in-place
edit to identical length with a preserved mtime reads as unchanged."
```

---

### Task 11: Rename the Dart package

**Files:**
- Modify: `pubspec.yaml:1`
- Modify: every file importing `package:alexandria_desktop/` — 125 files, 754 occurrences
- Modify: `alexandria_desktop.iml` (rename), `.idea/modules.xml`

**This is mechanical and lands alone.** Mixed with feature work it would make both unreviewable.

- [ ] **Step 1: Change the package name**

`pubspec.yaml` line 1: `name: alexandria_ui`.

- [ ] **Step 2: Rewrite the imports**

```bash
grep -rl "package:alexandria_desktop/" lib test integration_test \
  | xargs sed -i 's|package:alexandria_desktop/|package:alexandria_ui/|g'
```

- [ ] **Step 3: Rename the IntelliJ module**

```bash
git mv alexandria_desktop.iml alexandria_ui.iml
sed -i 's|alexandria_desktop|alexandria_ui|g' .idea/modules.xml
```

- [ ] **Step 4: Verify nothing survives**

Run: `grep -rn "alexandria_desktop" lib test integration_test pubspec.yaml .idea 2>/dev/null`
Expected: no output.

- [ ] **Step 5: Run the full suite and commit**

Run: `flutter pub get && dart format . && flutter analyze && flutter test`
Expected: PASS. A missed import is a compile error, so the analyzer is the real check here.

```bash
git add -A
git commit -m "refactor: rename the Dart package to alexandria_ui

The product is Alexandria, this application is Alexandria UI, and the
core is Alexandria API. Mechanical: 754 imports across 125 files, plus
the IntelliJ module."
```

---

### Task 12: Rename the application everywhere else

**Files:**
- Modify: `windows/runner/main.cpp:30`, `windows/runner/Runner.rc:93-98`
- Modify: `linux/CMakeLists.txt:7,10`, `linux/runner/my_application.cc:48,52`
- Modify: `packaging/linux/*`, `packaging/windows/installer.iss`
- Modify: `.github/workflows/release.yml`, `distribute_options.yaml`
- Modify: `README.md`, `docs/initial/*`, `docs/requirements/*`

- [ ] **Step 1: The window titles**

`windows/runner/main.cpp:30` → `window.Create(L"Alexandria", origin, size)`.
`linux/runner/my_application.cc:48,52` → `"Alexandria"` in both the header-bar and window-title calls.

- [ ] **Step 2: The executable metadata**

`windows/runner/Runner.rc`: `FileDescription` and `ProductName` → `"Alexandria"`; `InternalName` and `OriginalFilename` → `"alexandria.exe"`.

- [ ] **Step 3: The Linux binary and application id**

`linux/CMakeLists.txt`: `BINARY_NAME "alexandria"`, `APPLICATION_ID "io.github.artur_rios.Alexandria"`.

**This fixes a live defect.** The id was `com.arturrios.alexandria_desktop` while the desktop entry and Flatpak manifest are `io.github.artur_rios.Alexandria`. GNOME matches windows to launchers by application id, so the running window very likely does not associate with its own icon today. Say so in the commit message.

- [ ] **Step 4: Packaging, installer and CI**

Update `packaging/linux/io.github.artur_rios.Alexandria.desktop` (`Exec=alexandria`), `install.sh`, `build-appimage.sh`, `bundle-libraries.sh`, the Flatpak manifest, `packaging/windows/installer.iss`, `.github/workflows/release.yml` and `distribute_options.yaml`.

**Check the Inno Setup `AppId` and report what you find.** Inno keys upgrades off that GUID, so if it is unchanged an existing Windows install should upgrade in place despite the new executable name. On Linux the new binary name and application id mean an existing install becomes a second entry rather than an upgrade — note that in the commit message.

- [ ] **Step 5: Documents**

Apply the rule — *Alexandria* for the product, *Alexandria UI* for this application, *Alexandria API* for the core — across `README.md`, `docs/initial/` and `docs/requirements/`. Read the surrounding sentence before each replacement; which of the three is right depends on what the sentence is about.

- [ ] **Step 6: Verify and commit**

Run: `grep -rn "alexandria_desktop" . --exclude-dir=build --exclude-dir=.dart_tool --exclude-dir=.git`
Expected: no output outside dated design and plan records under `docs/superpowers/`, which are historical and stay as written.

Run: `flutter test && flutter build windows --debug`
Expected: PASS and a successful build. **The Linux changes cannot be built here** — this is a Windows machine, so CMake, GTK, the desktop entry and Flatpak are verified by inspection and by CI. State that in your report rather than implying otherwise.

```bash
dart format . && flutter analyze
git add -A
git commit -m "refactor: retire alexandria_desktop from the application

The window title, the executable metadata, the Linux binary, the
packaging and the documents all now read Alexandria, Alexandria UI or
Alexandria API as the context calls for.

Also fixes a live defect: linux/CMakeLists.txt declared the application
id as com.arturrios.alexandria_desktop while the desktop entry and
Flatpak manifest are io.github.artur_rios.Alexandria. GNOME matches
windows to launchers by application id, so the running window very
likely did not associate with its own icon.

The new Linux binary name and application id mean an existing install
becomes a second entry rather than an upgrade."
```

---

## What this plan does not cover

The core half is already merged (`alexandria-api#114`). Nothing here changes the Rust core; if a gap in its surface appears mid-implementation, stop and report it rather than working around it in this repository.
