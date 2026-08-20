import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/features/auth/application/session_controller.dart';
import 'package:alexandria_desktop/features/auth/application/session_state.dart';
import 'package:alexandria_desktop/features/auth/domain/session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_container.dart';

void main() {
  final session = Session(
    credential: 'a-real-looking-session-id',
    establishedAt: DateTime.utc(2026, 8, 12, 9, 30),
    emailConfirmed: true,
    email: 'owner@example.com',
  );

  const rejection = Failure.unauthorized(
    family: CoreStatusFamily.file,
    code: 2,
  );

  SessionController controller() =>
      buildTestContainer().read(sessionControllerProvider.notifier);

  test('GivenAFreshApplication_WhenTheSessionIsRead_ThenThereIsNone', () {
    expect(controller().state, const SessionState.absent());
  });

  test('GivenNoSession_WhenOneIsEstablished_ThenItIsActive', () {
    final sut = controller()..establish(session);

    expect(sut.state, SessionState.active(session: session));
  });

  test(
    'GivenAnActiveSession_WhenTheCredentialIsRead_ThenItIsTheCoresSessionId',
    () {
      final sut = controller()..establish(session);

      expect(sut.credential, 'a-real-looking-session-id');
    },
  );

  test('GivenNoSession_WhenTheCredentialIsRead_ThenThereIsNone', () {
    expect(controller().credential, isNull);
  });

  // UC-02 AF-04 / FR-AU-08.
  group('a call rejected as unauthorized', () {
    test(
      'GivenAnActiveSession_WhenACallIsRejected_ThenTheSessionIsDiscarded',
      () {
        final sut = controller()
          ..establish(session)
          ..invalidate(rejection);

        expect(sut.state, isA<SessionAbsent>());
      },
    );

    test(
      'GivenAnActiveSession_WhenACallIsRejected_ThenTheReasonIsKeptForTheOwner',
      () {
        final sut = controller()
          ..establish(session)
          ..invalidate(rejection);

        expect((sut.state as SessionAbsent).endedBecause, rejection);
      },
    );

    // Two rejected calls arriving together must not produce two explanations,
    // and the second must not overwrite the one the owner has not read.
    test('GivenNoSession_WhenACallIsRejected_ThenNothingChanges', () {
      final sut = controller()..invalidate(rejection);

      expect(sut.state, const SessionState.absent());
    });

    test(
      'GivenAnAlreadyDiscardedSession_WhenASecondCallIsRejected_ThenTheFirstReasonStands',
      () {
        const second = Failure.unauthorized(
          family: CoreStatusFamily.collection,
          code: 2,
        );

        final sut = controller()
          ..establish(session)
          ..invalidate(rejection)
          ..invalidate(second);

        expect((sut.state as SessionAbsent).endedBecause, rejection);
      },
    );

    test(
      'GivenAReasonTheOwnerHasSeen_WhenItIsAcknowledged_ThenItIsCleared',
      () {
        final sut = controller()
          ..establish(session)
          ..invalidate(rejection)
          ..acknowledgeEnding();

        expect(sut.state, const SessionState.absent());
      },
    );

    test(
      'GivenAnActiveSession_WhenAnEndingIsAcknowledged_ThenTheSessionSurvives',
      () {
        final sut = controller()
          ..establish(session)
          ..acknowledgeEnding();

        expect(sut.state, SessionState.active(session: session));
      },
    );
  });
}
