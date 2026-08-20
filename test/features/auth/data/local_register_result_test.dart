import 'dart:convert';

import 'package:alexandria_desktop/features/auth/data/local_register_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LocalRegisterResult decode(String json) =>
      LocalRegisterResult.fromJson(jsonDecode(json) as Map<String, dynamic>);

  // The payload the core actually returns today, from LocalRegisterResult in
  // crates/alexandria-core/src/auth/local.rs.
  const corePayload =
      '{"success":true,"email":"owner@example.com",'
      '"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50",'
      '"emailConfirmed":false,"confirmationSent":false,'
      '"confirmationError":"mail_not_configured"}';

  test(
    'GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenTheSessionIdIsRead',
    () {
      expect(
        decode(corePayload).sessionId,
        '6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50',
      );
    },
  );

  // Registration echoes the address back, normalized. That is what the session
  // should carry, not the raw text typed.
  test('GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenTheAddressIsRead', () {
    expect(decode(corePayload).email, 'owner@example.com');
  });

  test('GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenSuccessIsRead', () {
    expect(decode(corePayload).success, isTrue);
  });

  // FR-AU-12. The core reports this on every auth response now, and the
  // catalog lock is decided from it, so it is read rather than defaulted:
  // guessing `true` would unlock the catalog and guessing `false` would lock
  // the owner out of their own library.
  test(
    'GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenTheAccountIsUnconfirmed',
    () {
      expect(decode(corePayload).emailConfirmed, isFalse);
    },
  );

  test(
    'GivenAPayloadWithoutTheConfirmationField_WhenItIsDecoded_ThenItThrows',
    () {
      expect(
        () => decode(
          '{"success":true,"email":"owner@example.com",'
          '"sessionId":"6f1c9d02","confirmationSent":true}',
        ),
        throwsA(anything),
      );
    },
  );

  // UC-01 AF-06.
  test('GivenTheConfirmationCouldNotBeSent_WhenItIsDecoded_ThenThatIsRead', () {
    expect(decode(corePayload).confirmationSent, isFalse);
  });

  test(
    'GivenTheConfirmationCouldNotBeSent_WhenItIsDecoded_ThenTheReasonIsRead',
    () {
      expect(decode(corePayload).confirmationError, 'mail_not_configured');
    },
  );

  test('GivenTheConfirmationWasSent_WhenItIsDecoded_ThenThereIsNoReason', () {
    const payload =
        '{"success":true,"email":"owner@example.com",'
        '"sessionId":"6f1c9d02","emailConfirmed":false,'
        '"confirmationSent":true}';

    expect(decode(payload).confirmationError, isNull);
  });

  test('GivenAPayloadMissingTheSessionId_WhenItIsDecoded_ThenItThrows', () {
    expect(
      () => decode('{"success":true,"email":"owner@example.com"}'),
      throwsA(anything),
    );
  });

  test('GivenAPayloadMissingTheEmail_WhenItIsDecoded_ThenItThrows', () {
    expect(
      () => decode('{"success":true,"sessionId":"6f1c9d02"}'),
      throwsA(anything),
    );
  });
}
