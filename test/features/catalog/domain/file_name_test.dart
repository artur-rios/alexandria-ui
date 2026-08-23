import 'package:alexandria_ui/features/catalog/domain/file_name.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a name can be sent to the core (UC-17 AF-01, FR-ME-04).
void main() {
  FileNameError? onWindows(String name) =>
      validateFileName(name, host: HostFileSystem.windows);

  FileNameError? onPosix(String name) =>
      validateFileName(name, host: HostFileSystem.posix);

  group('names either host accepts', () {
    for (final name in [
      'Stalker.mkv',
      'Kind of Blue.flac',
      'a',
      'notes-2026.md',
      'já lido.pdf',
    ]) {
      test('Given"$name"_WhenItIsValidated_ThenItIsAccepted', () {
        expect(onWindows(name), isNull);
        expect(onPosix(name), isNull);
      });
    }
  });

  group('an empty name', () {
    test('GivenNothing_WhenItIsValidated_ThenItIsRefused', () {
      expect(onPosix(''), FileNameError.empty);
    });

    // Whitespace alone is nothing once it is trimmed, which is what would be
    // sent.
    test('GivenOnlyWhitespace_WhenItIsValidated_ThenItIsRefused', () {
      expect(onPosix('   '), FileNameError.empty);
    });
  });

  group('characters the host forbids', () {
    for (final name in [
      'why:not.txt',
      'a<b.txt',
      'a>b.txt',
      'a"b.txt',
      r'a\b.txt',
      'a|b.txt',
      'a?b.txt',
      'a*b.txt',
    ]) {
      test('Given"$name"_WhenItIsValidatedOnWindows_ThenItIsRefused', () {
        expect(onWindows(name), FileNameError.forbiddenCharacter);
      });
    }

    // The rule is the host's. Refusing a name Linux accepts because Windows
    // would not is this application inventing a restriction.
    test('GivenAColon_WhenItIsValidatedOnLinux_ThenItIsAccepted', () {
      expect(onPosix('why:not.txt'), isNull);
    });

    test('GivenASeparator_WhenItIsValidatedOnLinux_ThenItIsRefused', () {
      // A separator would make this a move rather than a rename.
      expect(onPosix('folder/file.txt'), FileNameError.forbiddenCharacter);
    });

    test('GivenANewline_WhenItIsValidated_ThenItIsRefusedOnEitherHost', () {
      expect(onPosix('two\nlines.txt'), FileNameError.forbiddenCharacter);
      expect(onWindows('two\nlines.txt'), FileNameError.forbiddenCharacter);
    });
  });

  group('names Windows reserves', () {
    test('GivenADeviceName_WhenItIsValidatedOnWindows_ThenItIsRefused', () {
      expect(onWindows('NUL'), FileNameError.reservedName);
      expect(onWindows('com1'), FileNameError.reservedName);
    });

    // The reservation is on the stem, so an extension does not rescue it.
    test(
      'GivenADeviceNameWithAnExtension_WhenItIsValidated_ThenItIsRefused',
      () {
        expect(onWindows('CON.txt'), FileNameError.reservedName);
      },
    );

    test('GivenADeviceName_WhenItIsValidatedOnLinux_ThenItIsAccepted', () {
      expect(onPosix('NUL'), isNull);
    });

    // A name that merely starts with one is not one.
    test(
      'GivenANameThatOnlyLooksReserved_WhenItIsValidated_ThenItIsAccepted',
      () {
        expect(onWindows('CONTACT.txt'), isNull);
      },
    );
  });

  group('a trailing dot', () {
    test('GivenATrailingDot_WhenItIsValidatedOnWindows_ThenItIsRefused', () {
      // Windows strips it silently, which would leave the catalog holding a
      // name the disk does not have.
      expect(onWindows('report.'), FileNameError.trailingDot);
    });

    test('GivenATrailingDot_WhenItIsValidatedOnLinux_ThenItIsAccepted', () {
      expect(onPosix('report.'), isNull);
    });
  });

  group('length', () {
    test('GivenTheLongestAllowedName_WhenItIsValidated_ThenItIsAccepted', () {
      expect(onPosix('x' * maxFileNameLength), isNull);
    });

    test('GivenALongerName_WhenItIsValidated_ThenItIsRefused', () {
      expect(onPosix('x' * (maxFileNameLength + 1)), FileNameError.tooLong);
    });
  });

  group('the name that is sent', () {
    test('GivenSurroundingWhitespace_WhenItIsSent_ThenItIsTrimmed', () {
      expect(fileNameToSend('  Stalker.mkv  '), 'Stalker.mkv');
    });

    test('GivenAPlainName_WhenItIsSent_ThenItIsUnchanged', () {
      expect(fileNameToSend('Stalker.mkv'), 'Stalker.mkv');
    });
  });
}
