import 'dart:ffi';

import 'package:alexandria_ui/core/bindings/core_strings.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

/// [withNativeString] is what stands between a null `priority` and a native
/// pointer the core can read at the `indexStart`, `indexRefreshStart`, and
/// `indexResume` call sites (`core_isolate.dart`).
///
/// The core reads an absent priority as *keep the run's current width* on
/// resume (or "normal" on a fresh start) — deliberately not the same as a
/// value the client chose — so a null must reach it as `nullptr`, never as
/// the four-character string `"null"` an unguarded `toNativeUtf8()` on
/// `value.toString()` would produce, and never conflated with an empty
/// string: the two are different arguments, even though the core happens to
/// treat both as "unrecognised" today. Relying on that coincidence would let
/// a plain resume silently re-pace a scan the owner had throttled.
void main() {
  test(
    'GivenANullValue_WhenPassedToWithNativeString_ThenTheBodyReceivesNullptr',
    () {
      Pointer<Char>? captured;

      withNativeString(null, (pointer) {
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
    'GivenANonNullValue_WhenPassedToWithNativeString_ThenTheBodyReceivesItAsANativeString',
    () {
      String? readBack;

      withNativeString('low', (pointer) {
        readBack = pointer.cast<Utf8>().toDartString();
        return null;
      });

      expect(readBack, 'low');
    },
  );

  test(
    'GivenAnEmptyString_WhenPassedToWithNativeString_ThenTheBodyReceivesAnEmptyNativeStringNotNullptr',
    () {
      Pointer<Char>? captured;
      String? readBack;

      withNativeString('', (pointer) {
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
            'relying on that coincidence is what would let a plain resume '
            'silently re-pace a throttled scan',
      );
      expect(readBack, '');
    },
  );
}
