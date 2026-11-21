import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_test/flutter_test.dart';

/// The core's file types and the listing each navigation entry shows
/// (FR-CT-01, FR-CT-02).
void main() {
  group('FileType.fromWire', () {
    for (final type in FileType.values) {
      test(
        'GivenTheWireName${type.wireName}_WhenItIsRead_ThenItIsThe${type.name}Type',
        () {
          expect(FileType.fromWire(type.wireName), type);
        },
      );
    }

    test('GivenAnUnknownWireName_WhenItIsRead_ThenTheTypeIsNull', () {
      // A core that grows a type must not have its files guessed into an
      // existing listing.
      expect(FileType.fromWire('hologram'), isNull);
    });

    test('GivenNoWireName_WhenItIsRead_ThenTheTypeIsNull', () {
      expect(FileType.fromWire(null), isNull);
    });

    test('GivenADifferentlyCasedWireName_WhenItIsRead_ThenTheTypeIsNull', () {
      // The core's names are lowercase; matching loosely would accept a
      // value the core never sends.
      expect(FileType.fromWire('Video'), isNull);
    });

    test('GivenEveryType_WhenTheirWireNamesAreListed_ThenNoneRepeats', () {
      final names = [for (final type in FileType.values) type.wireName];

      expect(names.toSet(), hasLength(names.length));
    });
  });

  group('fileTypeFor', () {
    const listings = {
      ShellDestination.videos: FileType.video,
      ShellDestination.books: FileType.document,
      ShellDestination.comicBooks: FileType.comic,
      ShellDestination.notes: FileType.text,
      ShellDestination.pages: FileType.html,
      ShellDestination.images: FileType.image,
    };

    for (final entry in listings.entries) {
      test(
        'GivenThe${entry.key.name}Destination_WhenItsListingIsRead_ThenItIsThe${entry.value.name}Type',
        () {
          expect(fileTypeFor(entry.key), entry.value);
        },
      );
    }

    for (final destination in [
      ShellDestination.home,
      ShellDestination.bookmarks,
      ShellDestination.libraries,
    ]) {
      test(
        'GivenThe${destination.name}Destination_WhenItsListingIsRead_ThenItShowsNoTypeListing',
        () {
          expect(fileTypeFor(destination), isNull);
        },
      );
    }

    test('GivenEveryType_WhenTheDestinationsAreMapped_ThenEachTypeHasOne', () {
      final listed = {
        for (final destination in ShellDestination.values)
          ?fileTypeFor(destination),
      };

      expect(listed, FileType.values.toSet());
    });
  });
}
