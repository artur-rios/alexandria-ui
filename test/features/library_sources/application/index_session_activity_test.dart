import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/library_sources/application/index_session_activity.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_gateway.dart';
import 'package:alexandria_ui/features/library_sources/domain/index_run.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_sources.dart';
import '../../../support/test_container.dart';

/// Re-checking the library once a session begins (FR-LB-21).
///
/// `begin()` restates none of `startRefresh`'s own rules — a run already
/// outstanding, an empty catalog, no credential — because one place deciding
/// when a refresh may start is the point. What these tests cover is that
/// `begin()` reaches the core at all, and that it respects the preference
/// that gates it.
void main() {
  const root = '/home/owner/music';
  final now = DateTime.utc(2026, 8, 19, 11);

  Future<({ProviderContainer ref, FakeIndexGateway gateway})> build({
    FakeIndexGateway? gateway,
  }) async {
    final indexGateway = gateway ?? FakeIndexGateway();
    final store = InMemoryLibrarySourceStore([
      LibrarySource(
        path: root,
        label: defaultLabelFor(root),
        registeredAt: now,
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        // `begin()` only reaches for the gateway once the core is loaded
        // (production never establishes a session before that either), so
        // this container runs a real startup over a faked core — the
        // gateway override below is what actually answers every call.
        ...fakeCoreOverrides(),
        indexGatewayProvider.overrideWithValue(indexGateway),
        librarySourceStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => now),
        // Long enough that no timer fires during a test.
        runPollIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(startupControllerProvider.notifier).start();

    // Turned off before the session is established, so `establish`'s own
    // unawaited call to `begin()` — the one every session establishment
    // fires, not the one under test — does not itself start a refresh and
    // race the one each test drives explicitly below.
    await container
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(false);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    return (ref: container, gateway: indexGateway);
  }

  // begin() is reached directly, through the same registration
  // `SessionController.establish` fires it through, rather than through
  // `establish` itself — establish calls it unawaited, so a test driving it
  // that way could not tell "not yet finished" from "never started".
  IndexSessionActivity activityOf(ProviderContainer container) => container
      .read(sessionActivitiesProvider)
      .whereType<IndexSessionActivity>()
      .single;

  test(
    'GivenTheRecheckIsOn_WhenTheSessionBegins_ThenTheLibraryIsRechecked',
    () async {
      // A non-empty catalog: nothing stands between the session starting and
      // the core being asked to re-check once the preference is on.
      final sut = await build();
      await sut.ref
          .read(preferencesControllerProvider.notifier)
          .setRechecksAtStartup(true);

      await activityOf(sut.ref).begin();

      expect(
        sut.gateway.refreshStarts.single,
        FakeAuthGateway.defaultSession.credential,
      );
    },
  );

  test(
    'GivenTheRecheckIsOff_WhenTheSessionBegins_ThenNothingIsStarted',
    () async {
      // The preference build() already turned off.
      //
      // Nothing distinguishes "the preference gate correctly returned early"
      // from "begin() does nothing at all" beyond what's asserted here — an
      // empty `begin()` would pass this test just as well. What makes that
      // acceptable is the pair above it: `...ThenTheLibraryIsRechecked` only
      // passes if `begin()` genuinely reaches the gateway when the preference
      // is on, so between the two, an empty `begin()` fails one of them and a
      // `begin()` that ignores the preference fails this one. Also asserted
      // is that the gateway was never asked *anything at all* — not even the
      // catalog count `startRefresh` checks before deciding — which is a
      // strictly stronger claim than "no refresh started" on its own.
      final sut = await build();

      await activityOf(sut.ref).begin();

      expect(sut.gateway.catalogedFileCountAsked, 0);
      expect(sut.gateway.refreshStarts, isEmpty);
    },
  );

  test(
    'GivenAnEmptyCatalog_WhenTheSessionBegins_ThenNothingIsStarted',
    () async {
      final sut = await build(
        gateway: FakeIndexGateway()..catalogedFileCount = 0,
      );
      await sut.ref
          .read(preferencesControllerProvider.notifier)
          .setRechecksAtStartup(true);

      await activityOf(sut.ref).begin();

      // The catalog *was* asked about — proving `begin()` reached
      // `startRefresh` rather than returning early on its own — but the core
      // was never asked to start a run over it (`startRefresh`'s own AF-02
      // rule).
      expect(sut.gateway.catalogedFileCountAsked, 1);
      expect(sut.gateway.refreshStarts, isEmpty);
    },
  );

  test('GivenARunOutstandingFromThePreviousSession_WhenTheSessionBegins_'
      'ThenNoSecondRunIsStarted', () async {
    // The run this test cares about is invisible to `IndexRunsController`
    // by construction: that controller is built fresh at sign-in, so its
    // own `isRefreshing` cannot know about a scan the core was still doing
    // before this session began (FR-LB-19). Nothing here calls
    // `startRefresh` first — doing so would make this the same case
    // `index_runs_controller_test`'s AF-01 coverage already proves, and
    // would pass even if `begin()` never consulted anything at all. What
    // is outstanding is expressed the only way `begin()` can actually
    // learn of it: through `listActiveRuns`, the same call
    // `ActiveRunsController` polls with.
    final sut = await build(
      gateway: FakeIndexGateway()
        ..activeRunsOutcome = const ActiveRunsOutcome.read(
          runs: [
            IndexRun(
              runId: 'a-run-from-before-this-session',
              root: '',
              kind: IndexRunKind.refresh,
              status: IndexRunStatus.running,
            ),
          ],
        ),
    );
    await sut.ref
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(true);

    await activityOf(sut.ref).begin();

    // `activeRunsControllerProvider` only knows about the outstanding run
    // once something has actually called `listActiveRuns` and applied the
    // read — a no-op `begin()` would leave this empty. This is what rules
    // out a `begin()` that skips starting a refresh for the wrong reason
    // (never reaching the gateway at all) passing this test for free.
    expect(sut.ref.read(activeRunsControllerProvider).runs, hasLength(1));
    // The proof this test exists for: knowing the run is outstanding,
    // `begin()` never reached `startRefresh` — not even far enough to ask
    // the catalog count, and certainly not far enough to start a second run
    // over the one already outstanding.
    expect(sut.gateway.catalogedFileCountAsked, 0);
    expect(sut.gateway.refreshStarts, isEmpty);
    expect(sut.ref.read(indexRunsControllerProvider).refreshRefusal, isNull);
  });

  test('GivenTheGatewayCallIsStillPending_WhenTheOwnerSignsOutMidFlight_'
      'ThenNothingThrows', () async {
    // `begin()`'s own call into `startRefresh` awaits the gateway before it
    // ever assigns `state` again. `IndexSessionActivity.end()` — what a
    // sign-out fires — invalidates `indexRunsControllerProvider`, which is
    // the very notifier `startRefresh` is suspended inside of. Riverpod
    // disposes a notifier's `Ref` on invalidation, and using a disposed
    // `Ref` — assigning `state`, or reading another provider through it,
    // both of which `startRefresh` does after the gateway answers — throws.
    // This is the scenario the review flagged as unverified: does that
    // throw actually happen, and if so, does it escape?
    final gate = Completer<void>();
    final gateway = FakeIndexGateway()..catalogedFileCountGate = gate;
    final sut = await build(gateway: gateway);
    await sut.ref
        .read(preferencesControllerProvider.notifier)
        .setRechecksAtStartup(true);

    final beginFuture = activityOf(sut.ref).begin();

    // Give `begin()` a chance to reach the gateway and suspend on the gate
    // before signing out — otherwise the race this test exists to cover
    // would not yet have started.
    await pumpEventQueue();
    // The proof the race is actually set up: `startRefresh` reached the
    // gateway and is genuinely suspended on the gate, not finished before
    // sign-out ever ran.
    expect(gateway.catalogedFileCountAsked, 1);

    // Signing out while `begin()`'s call is still outstanding.
    await activityOf(sut.ref).end();
    gate.complete();

    // Not `expectLater(beginFuture, completes)`: that only proves the
    // Future resolves, which it would either way — `begin()` is called
    // directly here, outside `SessionController._begin`'s try/catch, so an
    // unhandled throw inside `IndexRunsController.startRefresh` after
    // disposal would surface right here rather than being swallowed
    // upstream. A caught StateError from using a disposed `Ref` would fail
    // this await; it does not, which is the proof nothing throws.
    await beginFuture;
  });
}
