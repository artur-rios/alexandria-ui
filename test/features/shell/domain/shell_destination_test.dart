import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_test/flutter_test.dart';

/// The areas of the shell (FR-UX-01, spec §3).
void main() {
  test('GivenNothingPicked_WhenTheShellOpens_ThenItIsHome', () {
    expect(ShellDestination.initial, const HomeDestination());
  });

  group('equality', () {
    test('GivenTwoDestinationsForOneLibrary_WhenCompared_ThenTheyAreEqual', () {
      final uuid = ['lib', '1'].join('-');

      expect(LibraryDestination(uuid), const LibraryDestination('lib-1'));
      expect(
        LibraryDestination(uuid).hashCode,
        const LibraryDestination('lib-1').hashCode,
      );
    });

    test('GivenTwoLibraries_WhenCompared_ThenTheyDiffer', () {
      expect(
        const LibraryDestination('lib-1'),
        isNot(const LibraryDestination('lib-2')),
      );
    });

    test('GivenTwoTypes_WhenCompared_ThenTheyDiffer', () {
      expect(
        const TypeDestination(FileType.video),
        isNot(const TypeDestination(FileType.image)),
      );
    });
  });

  group('listedType', () {
    for (final type in FileType.values) {
      test(
        'GivenThe${type.name}Listing_WhenItsTypeIsRead_ThenItIs${type.name}',
        () {
          expect(TypeDestination(type).listedType, type);
        },
      );
    }

    for (final destination in const <ShellDestination>[
      HomeDestination(),
      BookmarksDestination(),
      LibraryDestination('lib-1'),
      LibrariesDestination(),
    ]) {
      test(
        'Given${destination.runtimeType}_WhenItsTypeIsRead_ThenItListsNoType',
        () {
          expect(destination.listedType, isNull);
        },
      );
    }
  });
}
