import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/library_sources/application/index_session_activity.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
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

  test(
    'GivenARunAlreadyInFlight_WhenTheSessionBegins_ThenItIsNotDisturbed',
    () async {
      final sut = await build(
        gateway: FakeIndexGateway()..readOutcomes = [runningRun()],
      );
      await sut.ref.read(indexRunsControllerProvider.notifier).startRefresh();
      final runningId = sut.ref
          .read(indexRunsControllerProvider)
          .refreshRun
          ?.runId;
      expect(sut.gateway.refreshStarts, hasLength(1));
      await sut.ref
          .read(preferencesControllerProvider.notifier)
          .setRechecksAtStartup(true);

      await activityOf(sut.ref).begin();

      // The catalog *was* asked about — proving `begin()` reached
      // `startRefresh` rather than returning early on its own, the same
      // proof the empty-catalog test above relies on. Without this, a
      // `begin()` that does nothing at all would pass every assertion below
      // just as well as a correct one.
      expect(sut.gateway.catalogedFileCountAsked, 1);
      // AF-01's own rule: a second refresh is refused while one is running.
      // "Not disturbed" is measured, not assumed: the gateway was not asked
      // again, the run already in flight is still the very same run, and no
      // refusal was left on state — `begin()` asks `startRefresh` for
      // `reportRefusals: false`, so AF-01's own refusal notice never reaches
      // the screen for a re-check nobody asked for.
      expect(sut.gateway.refreshStarts, hasLength(1));
      final state = sut.ref.read(indexRunsControllerProvider);
      expect(state.refreshRun?.runId, runningId);
      expect(state.refreshRefusal, isNull);
    },
  );
}
