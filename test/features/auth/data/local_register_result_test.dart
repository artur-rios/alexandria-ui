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
      '"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50"}';

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
  test(
    'GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenTheAddressIsRead',
    () {
      expect(decode(corePayload).email, 'owner@example.com');
    },
  );

  test('GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenSuccessIsRead', () {
    expect(decode(corePayload).success, isTrue);
  });

  // The core has no e-mail confirmation at all, so the field is absent and an
  // account that cannot be confirmed must not be locked out of its own
  // catalog. This is why UC-01's confirmation postcondition does not hold.
  test(
    'GivenAPayloadWithoutTheConfirmationField_WhenItIsDecoded_ThenTheEmailIsTreatedAsConfirmed',
    () {
      expect(decode(corePayload).emailConfirmed, isTrue);
    },
  );

  test(
    'GivenAPayloadReportingAnUnconfirmedEmail_WhenItIsDecoded_ThenThatIsRead',
    () {
      const payload =
          '{"success":true,"email":"owner@example.com",'
          '"sessionId":"6f1c9d02","emailConfirmed":false}';

      expect(decode(payload).emailConfirmed, isFalse);
    },
  );

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
