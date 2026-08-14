import 'dart:convert';

import 'package:alexandria_desktop/features/auth/data/local_login_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LocalLoginResult decode(String json) =>
      LocalLoginResult.fromJson(jsonDecode(json) as Map<String, dynamic>);

  // The payload the core actually returns today, from LocalLoginResult in
  // crates/alexandria-core/src/auth/local.rs.
  const corePayload =
      '{"success":true,"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50",'
      '"emailConfirmed":true}';

  test(
    'GivenTheCoresLoginPayload_WhenItIsDecoded_ThenTheSessionIdIsRead',
    () {
      expect(
        decode(corePayload).sessionId,
        '6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50',
      );
    },
  );

  test(
    'GivenTheCoresLoginPayload_WhenItIsDecoded_ThenSuccessIsRead',
    () {
      expect(decode(corePayload).success, isTrue);
    },
  );

  // FR-AU-12's confirmation state is one of the pending core operations in
  // System Requirements §5.4. Until it lands the field is absent, and an absent
  // field must not lock the catalog against an account that has no way to be
  // confirmed.
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
          '{"success":true,"sessionId":"6f1c9d02","emailConfirmed":false}';

      expect(decode(payload).emailConfirmed, isFalse);
    },
  );

  test(
    'GivenAPayloadMissingTheSessionId_WhenItIsDecoded_ThenItThrows',
    () {
      expect(() => decode('{"success":true}'), throwsA(anything));
    },
  );

  test(
    'GivenAPayloadWhoseSessionIdIsNotAString_WhenItIsDecoded_ThenItThrows',
    () {
      expect(
        () => decode('{"success":true,"sessionId":42,"emailConfirmed":true}'),
        throwsA(anything),
      );
    },
  );
}
