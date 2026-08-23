import 'dart:convert';

import 'package:alexandria_ui/features/auth/data/local_login_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LocalLoginResult decode(String json) =>
      LocalLoginResult.fromJson(jsonDecode(json) as Map<String, dynamic>);

  // The payload the core actually returns today, from LocalLoginResult in
  // crates/alexandria-core/src/auth/local.rs.
  const corePayload =
      '{"success":true,"sessionId":"6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50"}';

  test('GivenTheCoresLoginPayload_WhenItIsDecoded_ThenTheSessionIdIsRead', () {
    expect(
      decode(corePayload).sessionId,
      '6f1c9d02-1f3b-4f3a-9a7e-0b1d2c3e4f50',
    );
  });

  test('GivenTheCoresLoginPayload_WhenItIsDecoded_ThenSuccessIsRead', () {
    expect(decode(corePayload).success, isTrue);
  });

  // The core dropped e-mail confirmation on 2026-08-18, so a field naming it
  // is not one this payload carries. A payload that still had one is a core
  // older than the pinned ref, and reading it would be reading a flag nothing
  // acts on any more.
  test(
    'GivenAPayloadCarryingAnUnknownField_WhenItIsDecoded_ThenItIsIgnored',
    () {
      const payload =
          '{"success":true,"sessionId":"6f1c9d02","emailConfirmed":false}';

      expect(decode(payload).sessionId, '6f1c9d02');
    },
  );

  test('GivenAPayloadMissingTheSessionId_WhenItIsDecoded_ThenItThrows', () {
    expect(() => decode('{"success":true}'), throwsA(anything));
  });

  test(
    'GivenAPayloadWhoseSessionIdIsNotAString_WhenItIsDecoded_ThenItThrows',
    () {
      expect(
        () => decode('{"success":true,"sessionId":42}'),
        throwsA(anything),
      );
    },
  );
}
