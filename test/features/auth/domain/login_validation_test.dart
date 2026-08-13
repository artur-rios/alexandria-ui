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
}
