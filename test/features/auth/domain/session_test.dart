import 'package:alexandria_desktop/features/auth/domain/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final establishedAt = DateTime.utc(2026, 8, 12, 9, 30);

  Session buildSession({String credential = 'a-real-looking-session-id'}) =>
      Session(
        credential: credential,
        establishedAt: establishedAt,
        email: 'owner@example.com',
      );

  // FR-AU-11 and the redaction rule in Operations & Infrastructure §4: the
  // session credential must not reach a log. A Session reaches one whenever it
  // is interpolated into a message, so the redaction lives in toString rather
  // than in every call site that might log it.
  test(
    'GivenASession_WhenItIsConvertedToAString_ThenTheCredentialIsNotInIt',
    () {
      const credential = 'a-real-looking-session-id';

      expect(buildSession().toString(), isNot(contains(credential)));
    },
  );

  test(
    'GivenASession_WhenItIsConvertedToAString_ThenTheEmailIsStillReadable',
    () {
      expect(buildSession().toString(), contains('owner@example.com'));
    },
  );

  test(
    'GivenASessionWithAnEmptyCredential_WhenItIsConvertedToAString_ThenNothingIsLeaked',
    () {
      expect(buildSession(credential: '').toString(), contains('redacted'));
    },
  );

  test(
    'GivenTwoSessionsWithTheSameValues_WhenTheyAreCompared_ThenTheyAreEqual',
    () {
      expect(buildSession(), buildSession());
    },
  );

  test(
    'GivenTwoSessionsWithDifferentCredentials_WhenTheyAreCompared_ThenTheyDiffer',
    () {
      expect(buildSession(), isNot(buildSession(credential: 'another')));
    },
  );
}
