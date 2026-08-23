import 'package:alexandria_ui/features/auth/data/core_error_body.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading the error envelope the core sends on a failed call.
///
/// Every branch that returns `null` matters as much as the one that succeeds:
/// the caller then falls back to the status code, so a core that answers
/// without a code degrades to the previous behaviour instead of failing.
void main() {
  test('GivenAnEnvelopeWithACode_WhenItIsRead_ThenTheCodeIsReturned', () {
    final rejection = readCoreRejection(
      '{"error":"password must be at least 12 characters",'
      '"code":"password_too_short","params":{"min":"12"}}',
    );

    expect(rejection?.code, 'password_too_short');
  });

  // The bound comes from the core because the core owns the policy. A message
  // that hardcoded 12 would be wrong the day the rule changes.
  test('GivenAnEnvelopeWithParams_WhenItIsRead_ThenTheParamsAreReturned', () {
    final rejection = readCoreRejection(
      '{"error":"…","code":"password_too_short","params":{"min":"12"}}',
    );

    expect(rejection?.params, {'min': '12'});
  });

  test('GivenAnEnvelopeWithNoParams_WhenItIsRead_ThenTheParamsAreEmpty', () {
    final rejection = readCoreRejection(
      '{"error":"…","code":"password_too_common"}',
    );

    expect(rejection?.params, isEmpty);
  });

  test(
    'GivenAnEnvelope_WhenItIsRead_ThenTheCoresOwnMessageIsKeptForTheLog',
    () {
      final rejection = readCoreRejection(
        '{"error":"password is too common","code":"password_too_common"}',
      );

      expect(rejection?.message, 'password is too common');
    },
  );

  group('what falls back to the status code', () {
    test('GivenNoBody_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection(null), isNull);
    });

    test('GivenAnEmptyBody_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection(''), isNull);
    });

    test('GivenAMalformedBody_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection('not json at all'), isNull);
    });

    test('GivenABodyThatIsNotAnObject_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection('["not","an","object"]'), isNull);
    });

    // An older core, or a path that has no code to give.
    test('GivenAnEnvelopeWithNoCode_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection('{"error":"something went wrong"}'), isNull);
    });

    test('GivenAnEmptyCode_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection('{"error":"…","code":""}'), isNull);
    });

    test('GivenACodeThatIsNotAString_WhenItIsRead_ThenThereIsNoRejection', () {
      expect(readCoreRejection('{"error":"…","code":42}'), isNull);
    });
  });

  // A failure path is the worst place to throw, so a param of the wrong type
  // drops that param rather than the whole rejection.
  test(
    'GivenAParamThatIsNotAString_WhenItIsRead_ThenTheRejectionSurvivesWithoutIt',
    () {
      final rejection = readCoreRejection(
        '{"error":"…","code":"password_too_short","params":{"min":12}}',
      );

      expect(rejection?.code, 'password_too_short');
      expect(rejection?.params, isEmpty);
    },
  );

  test(
    'GivenParamsThatAreNotAnObject_WhenItIsRead_ThenTheRejectionSurvives',
    () {
      final rejection = readCoreRejection(
        '{"error":"…","code":"password_too_short","params":"twelve"}',
      );

      expect(rejection?.code, 'password_too_short');
      expect(rejection?.params, isEmpty);
    },
  );
}
