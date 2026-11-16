import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// A registered source folder and the scope it is indexed with (FR-LB-03).
void main() {
  final registeredAt = DateTime.utc(2026, 8, 30, 9);

  LibrarySource source({List<String> scope = const [], String? libraryName}) =>
      LibrarySource(
        path: '/media/courses',
        label: 'courses',
        registeredAt: registeredAt,
        scope: scope,
        libraryName: libraryName,
      );

  group('isLibrary', () {
    test('GivenALibraryName_WhenItIsAsked_ThenTheFolderIsALibrary', () {
      expect(source(libraryName: 'Courses').isLibrary, isTrue);
    });

    test('GivenNoLibraryName_WhenItIsAsked_ThenTheFolderIsNotALibrary', () {
      expect(source().isLibrary, isFalse);
    });
  });

  group('the scope', () {
    test('GivenNoScope_WhenItIsRead_ThenItIsEmptyAndReadable', () {
      // An empty scope is "every type", which is a choice, not a failure.
      final folder = source();

      expect(folder.scopeTypes, isEmpty);
      expect(folder.scopeIsUnreadable, isFalse);
    });

    test(
      'GivenKnownTypeNames_WhenTheScopeIsRead_ThenTheyAreTheTypesInOrder',
      () {
        final folder = source(scope: const ['image', 'video']);

        expect(folder.scopeTypes, [FileType.image, FileType.video]);
        expect(folder.scopeIsUnreadable, isFalse);
      },
    );

    test(
      'GivenAnUnknownNameAmongKnownOnes_WhenTheScopeIsRead_ThenOnlyTheKnownRemain',
      () {
        final folder = source(scope: const ['video', 'audio', 'comic']);

        expect(folder.scopeTypes, [FileType.video, FileType.comic]);
        expect(folder.scopeIsUnreadable, isFalse);
      },
    );

    test('GivenOnlyUnknownNames_WhenTheScopeIsRead_ThenItIsUnreadable', () {
      // Read on its own this would be "every type"; it is not.
      final folder = source(scope: const ['audio', 'music']);

      expect(folder.scopeTypes, isEmpty);
      expect(folder.scopeIsUnreadable, isTrue);
    });
  });

  group('JSON', () {
    test('GivenAFullSource_WhenItRoundTrips_ThenEveryFieldSurvives', () {
      final folder = LibrarySource(
        path: '/media/courses',
        label: 'courses',
        registeredAt: registeredAt,
        lastRunId: 'run-1',
        lastRunOutcome: 'complete',
        lastRunAt: registeredAt.add(const Duration(hours: 1)),
        scope: const ['video'],
        libraryName: 'Courses',
      );

      expect(LibrarySource.fromJson(folder.toJson()), folder);
    });

    test('GivenAStoredSourceWithNoScope_WhenItIsRead_ThenTheScopeIsEmpty', () {
      // Folders registered before scopes existed carry no scope key at all.
      final folder = LibrarySource.fromJson({
        'path': '/media/courses',
        'label': 'courses',
        'registeredAt': registeredAt.toIso8601String(),
      });

      expect(folder.scope, isEmpty);
      expect(folder.isLibrary, isFalse);
    });
  });
}
