import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/features/auth/application/session_controller.dart';
import 'package:alexandria_desktop/features/auth/application/session_state.dart';
import 'package:alexandria_desktop/features/auth/domain/session.dart';
import 'package:alexandria_desktop/features/shell/domain/session_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_session_activity.dart';
import '../../../support/test_container.dart';

/// UC-03: signing out.
void main() {
  final session = Session(
    credential: 'a-real-looking-session-id',
    establishedAt: DateTime.utc(2026, 8, 19, 10),

    email: 'owner@example.com',
  );

  /// A container holding an active session and [activities].
  ({ProviderContainer container, SessionController session}) signedIn(
    List<SessionActivity> activities,
  ) {
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(),
        sessionActivitiesProvider.overrideWithValue(activities),
      ],
    );

    final controller = container.read(sessionControllerProvider.notifier)
      ..establish(session);

    return (container: container, session: controller);
  }

  group('the main flow', () {
    test(
      'GivenAnActiveSession_WhenTheOwnerSignsOut_ThenTheCredentialIsDiscarded',
      () async {
        final (:container, session: controller) = signedIn([]);

        await container.read(signOutControllerProvider).signOut();

        expect(controller.credential, isNull);
        expect(controller.state, const SessionState.absent());
      },
    );

    test(
      'GivenAnActiveSession_WhenTheOwnerSignsOut_ThenEveryActivityIsEnded',
      () async {
        final playback = FakeSessionActivity();
        final projections = FakeSessionActivity();
        final (:container, :session) = signedIn([playback, projections]);

        // Establishing a session winds down whatever the last one left, so
        // the count that matters here is the one the sign-out adds.
        playback.endCount = 0;
        projections.endCount = 0;

        await container.read(signOutControllerProvider).signOut();

        expect(playback.endCount, 1);
        expect(projections.endCount, 1);
      },
    );

    // Step 2 stops playback and step 3 discards the credential, in that order:
    // an activity being wound down still has the session it was running under.
    test(
      'GivenAnActiveSession_WhenTheOwnerSignsOut_ThenTheActivitiesEndBeforeTheCredentialGoes',
      () async {
        final credentialsWhileEnding = <String?>[];
        // Nullable rather than `late`, because the first end happens while the
        // session is being established — which is inside the very call that
        // produces the container.
        ProviderContainer? container;

        final activity = FakeSessionActivity(
          onEnd: () => credentialsWhileEnding.add(
            container?.read(sessionControllerProvider.notifier).credential,
          ),
        );

        container = signedIn([activity]).container;

        await container.read(signOutControllerProvider).signOut();

        expect(credentialsWhileEnding.last, 'a-real-looking-session-id');
      },
    );

    test('GivenNoSession_WhenSignOutIsCalled_ThenNothingChanges', () async {
      final container = buildTestContainer(
        overrides: [
          ...fakeCoreOverrides(),
          sessionActivitiesProvider.overrideWithValue(const []),
        ],
      );

      await container.read(signOutControllerProvider).signOut();

      expect(
        container.read(sessionControllerProvider),
        const SessionState.absent(),
      );
    });
  });

  // AF-01: an editor holds unsaved changes.
  group('unsaved changes', () {
    test(
      'GivenAnActivityHoldingUnsavedChanges_WhenSignOutIsConsidered_ThenItIsReported',
      () {
        final (:container, :session) = signedIn([
          FakeSessionActivity(),
          FakeSessionActivity(holdsUnsavedChanges: true),
        ]);

        expect(
          container.read(signOutControllerProvider).holdsUnsavedChanges,
          isTrue,
        );
      },
    );

    test(
      'GivenNothingUnsaved_WhenSignOutIsConsidered_ThenNoWarningIsCalledFor',
      () {
        final (:container, :session) = signedIn([FakeSessionActivity()]);

        expect(
          container.read(signOutControllerProvider).holdsUnsavedChanges,
          isFalse,
        );
      },
    );
  });

  // AF-02: an index run is in flight.
  group('work that continues in the core', () {
    test(
      'GivenARunInFlight_WhenTheOwnerSignsOut_ThenTheSessionSaysTheRunContinues',
      () async {
        final (:container, :session) = signedIn([
          FakeSessionActivity(continuesInTheCore: true),
        ]);

        await container.read(signOutControllerProvider).signOut();

        expect(
          container.read(sessionControllerProvider),
          const SessionState.absent(indexRunContinues: true),
        );
      },
    );

    test(
      'GivenARunInFlight_WhenTheOwnerSignsOut_ThenTheSignOutIsNotHeldUp',
      () async {
        final activity = FakeSessionActivity(continuesInTheCore: true);
        final (:container, session: controller) = signedIn([activity]);
        activity.endCount = 0;

        await container.read(signOutControllerProvider).signOut();

        expect(controller.credential, isNull);
        expect(activity.endCount, 1);
      },
    );

    test(
      'GivenNothingRunning_WhenTheOwnerSignsOut_ThenNothingIsClaimedToContinue',
      () async {
        final (:container, :session) = signedIn([FakeSessionActivity()]);

        await container.read(signOutControllerProvider).signOut();

        expect(
          container.read(sessionControllerProvider),
          const SessionState.absent(),
        );
      },
    );

    test(
      'GivenTheNoticeWasRead_WhenItIsAcknowledged_ThenItIsCleared',
      () async {
        final (:container, session: controller) = signedIn([
          FakeSessionActivity(continuesInTheCore: true),
        ]);

        await container.read(signOutControllerProvider).signOut();
        controller.acknowledgeEnding();

        expect(controller.state, const SessionState.absent());
      },
    );
  });
}
