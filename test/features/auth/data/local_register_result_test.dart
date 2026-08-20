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
      '"recoveryCodes":["aaaa-bbbb","cccc-dddd"]}';

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

  // FR-AU-12: the codes are returned exactly once, so this payload is the
  // only place they exist. Reading them is what makes UC-40 possible at all.
  test(
    'GivenTheCoresRegisterPayload_WhenItIsDecoded_ThenTheRecoveryCodesAreRead',
    () {
      expect(decode(corePayload).recoveryCodes, ['aaaa-bbbb', 'cccc-dddd']);
    },
  );

  // Defaulted rather than required: an account the core created without codes
  // is a state UC-40 AF-03 reports, not a payload this class should refuse.
  test(
    'GivenAPayloadWithoutRecoveryCodes_WhenItIsDecoded_ThenTheyAreEmpty',
    () {
      const payload =
          '{"success":true,"email":"owner@example.com",'
          '"sessionId":"6f1c9d02"}';

      expect(decode(payload).recoveryCodes, isEmpty);
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
