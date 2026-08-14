import 'package:alexandria_desktop/features/auth/domain/login_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test(
      'GivenAWellFormedAddress_WhenItIsValidated_ThenThereIsNoError',
      () {
        expect(validateEmail('owner@example.com'), isNull);
      },
    );

    test(
      'GivenAnAddressWithASubdomainAndPlusTag_WhenItIsValidated_ThenThereIsNoError',
      () {
        expect(validateEmail('owner+library@mail.example.co.uk'), isNull);
      },
    );

    test(
      'GivenAnEmptyAddress_WhenItIsValidated_ThenItIsReportedAsMissing',
      () {
        expect(validateEmail(''), LoginFieldError.missing);
      },
    );

    test(
      'GivenAnAddressOfOnlyWhitespace_WhenItIsValidated_ThenItIsReportedAsMissing',
      () {
        expect(validateEmail('   '), LoginFieldError.missing);
      },
    );

    test(
      'GivenAnAddressWithNoAtSign_WhenItIsValidated_ThenItIsReportedAsMalformed',
      () {
        expect(validateEmail('owner.example.com'), LoginFieldError.malformed);
      },
    );

    test(
      'GivenAnAddressWithNoDomain_WhenItIsValidated_ThenItIsReportedAsMalformed',
      () {
        expect(validateEmail('owner@'), LoginFieldError.malformed);
      },
    );

    test(
      'GivenAnAddressWithNoLocalPart_WhenItIsValidated_ThenItIsReportedAsMalformed',
      () {
        expect(validateEmail('@example.com'), LoginFieldError.malformed);
      },
    );

    test(
      'GivenAnAddressWithNoDotInTheDomain_WhenItIsValidated_ThenItIsReportedAsMalformed',
      () {
        expect(validateEmail('owner@example'), LoginFieldError.malformed);
      },
    );

    test(
      'GivenAnAddressContainingASpace_WhenItIsValidated_ThenItIsReportedAsMalformed',
      () {
        expect(validateEmail('own er@example.com'), LoginFieldError.malformed);
      },
    );

    // Surrounding whitespace is the owner's typing, not their intent: it is
    // trimmed rather than turned into a malformed-address complaint.
    test(
      'GivenAValidAddressPaddedWithSpaces_WhenItIsValidated_ThenThereIsNoError',
      () {
        expect(validateEmail('  owner@example.com  '), isNull);
      },
    );
  });

  group('validatePassword', () {
    test(
      'GivenANonEmptyPassword_WhenItIsValidated_ThenThereIsNoError',
      () {
        expect(validatePassword('correct horse'), isNull);
      },
    );

    test(
      'GivenAnEmptyPassword_WhenItIsValidated_ThenItIsReportedAsMissing',
      () {
        expect(validatePassword(''), LoginFieldError.missing);
      },
    );

    // A password of spaces is a password. Only emptiness is rejected here, and
    // the core's verdict on anything else is final (FR-AU-03).
    test(
      'GivenAPasswordOfOnlySpaces_WhenItIsValidated_ThenThereIsNoError',
      () {
        expect(validatePassword('   '), isNull);
      },
    );

    test(
      'GivenASingleCharacterPassword_WhenItIsValidated_ThenThereIsNoError',
      () {
        expect(validatePassword('x'), isNull);
      },
    );
  });

  // UC-01 step 4 and AF-02.
  group('validatePasswordConfirmation', () {
    test(
      'GivenTwoIdenticalEntries_WhenTheyAreValidated_ThenThereIsNoError',
      () {
        expect(
          validatePasswordConfirmation('correct horse', 'correct horse'),
          isNull,
        );
      },
    );

    test(
      'GivenEntriesThatDiffer_WhenTheyAreValidated_ThenTheyAreReportedAsMismatched',
      () {
        expect(
          validatePasswordConfirmation('correct horse', 'correct hors'),
          LoginFieldError.mismatched,
        );
      },
    );

    test(
      'GivenEntriesDifferingOnlyInCase_WhenTheyAreValidated_ThenTheyAreReportedAsMismatched',
      () {
        expect(
          validatePasswordConfirmation('Correct Horse', 'correct horse'),
          LoginFieldError.mismatched,
        );
      },
    );

    // Trailing whitespace is part of a password, so it is a real mismatch
    // rather than something to trim away.
    test(
      'GivenEntriesDifferingOnlyByTrailingSpace_WhenTheyAreValidated_ThenTheyAreReportedAsMismatched',
      () {
        expect(
          validatePasswordConfirmation('correct horse', 'correct horse '),
          LoginFieldError.mismatched,
        );
      },
    );

    // The owner has not made a mistake yet — they have not finished.
    test(
      'GivenAnEmptyRepeat_WhenItIsValidated_ThenItIsReportedAsMissing',
      () {
        expect(
          validatePasswordConfirmation('correct horse', ''),
          LoginFieldError.missing,
        );
      },
    );

    test(
      'GivenBothEntriesEmpty_WhenTheyAreValidated_ThenTheRepeatIsReportedAsMissing',
      () {
        expect(validatePasswordConfirmation('', ''), LoginFieldError.missing);
      },
    );
  });
}
