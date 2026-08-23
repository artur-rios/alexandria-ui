import 'dart:ffi';

import 'package:alexandria_desktop/core/bindings/core_strings.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

/// [withNullableNativeString] is what stands between a null `priority` and a
/// native pointer the core can read (task-2-brief.md, "what matters most").
///
/// The core reads an absent priority as *keep the run's current width* on
/// resume, deliberately not the same as `"normal"` — so a null must reach it
/// as `nullptr`, never as the four-character string `"null"` an unguarded
/// `toNativeUtf8()` on `value.toString()` would produce, and never silently
/// coerced to `""` by a helper that cannot tell "absent" from "empty".
void main() {
  test(
    'GivenANullValue_WhenPassedToWithNullableNativeString_ThenTheBodyReceivesNullptr',
    () {
      Pointer<Char>? captured;

      withNullableNativeString(null, (pointer) {
        captured = pointer;
        return null;
      });

      expect(
        captured,
        nullptr,
        reason:
            'an absent priority must reach the core as a null pointer, not as '
            'the string "null" or as an empty string',
      );
    },
  );

  test(
    'GivenANonNullValue_WhenPassedToWithNullableNativeString_ThenTheBodyReceivesItAsANativeString',
    () {
      String? readBack;

      withNullableNativeString('low', (pointer) {
        readBack = pointer.cast<Utf8>().toDartString();
        return null;
      });

      expect(readBack, 'low');
    },
  );

  test(
    'GivenAnEmptyString_WhenPassedToWithNullableNativeString_ThenTheBodyReceivesAnEmptyNativeStringNotNullptr',
    () {
      Pointer<Char>? captured;
      String? readBack;

      withNullableNativeString('', (pointer) {
        captured = pointer;
        readBack = pointer.cast<Utf8>().toDartString();
        return null;
      });

      expect(
        captured,
        isNot(nullptr),
        reason:
            'an empty string is a different argument from an absent one, even '
            'though the core happens to treat both as "unrecognised" today — '
            'relying on that coincidence is exactly what this helper exists to '
            'avoid',
      );
      expect(readBack, '');
    },
  );
}
