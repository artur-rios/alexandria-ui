import 'dart:io';

import 'package:alexandria_desktop/core/startup/core_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// IR-04 and IR-05: where the shared library and the catalog database come
/// from.
void main() {
  late Directory temporary;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('alexandria_paths_test');
  });

  tearDown(() => temporary.deleteSync(recursive: true));

  CorePaths pathsWith(Map<String, String> environment) => CorePaths(
    environment: environment,
    resolveApplicationSupportDirectory: () async => temporary,
  );

  group('the shared library (IR-04)', () {
    test('GivenNoOverride_WhenThePathsAreListed_ThenTheyStartAtTheExecutable',
        () {
      final candidates = pathsWith(const {}).librarySearchPaths;

      expect(candidates, isNotEmpty);
      expect(
        candidates.first,
        startsWith(p.dirname(Platform.resolvedExecutable)),
        reason:
            'a packaged build resolves the library relative to its own '
            'executable — that is what makes it self-contained',
      );
    });

    test('GivenNoOverride_WhenThePathsAreListed_ThenTheDevCheckoutIsIncluded',
        () {
      expect(
        pathsWith(const {}).librarySearchPaths,
        contains(anyOf(contains('native'), contains('build'))),
        reason: 'a development checkout runs against native/ without a variable',
      );
    });

    test('GivenTheOverride_WhenThePathsAreListed_ThenItIsTheOnlyCandidate', () {
      final candidates = pathsWith({
        CorePaths.libraryPathVariable: '/custom/core.so',
      }).librarySearchPaths;

      expect(candidates, ['/custom/core.so']);
    });

    test('GivenAnEmptyOverride_WhenThePathsAreListed_ThenItIsIgnored', () {
      expect(
        pathsWith({CorePaths.libraryPathVariable: ''}).librarySearchPaths,
        hasLength(greaterThan(1)),
      );
    });

    test('GivenNoLibraryOnDisk_WhenItIsResolved_ThenTheResultIsNull', () {
      expect(
        pathsWith({
          CorePaths.libraryPathVariable: p.join(temporary.path, 'absent.dll'),
        }).resolveLibraryPath(),
        isNull,
        reason:
            'returning null rather than throwing is what lets step 1 report '
            'every path it tried',
      );
    });

    test('GivenALibraryOnDisk_WhenItIsResolved_ThenThatPathIsReturned', () {
      final library = File(p.join(temporary.path, 'present.dll'))
        ..writeAsStringSync('');

      expect(
        pathsWith({
          CorePaths.libraryPathVariable: library.path,
        }).resolveLibraryPath(),
        library.path,
      );
    });

    test('GivenTheRunningPlatform_WhenTheFileNameIsRead_ThenItMatchesTheTarget',
        () {
      expect(
        CorePaths.libraryFileName,
        Platform.isWindows ? 'alexandria_ffi.dll' : 'libalexandria_ffi.so',
      );
    });
  });

  group('the catalog database (IR-05)', () {
    test(
      'GivenNoOverride_WhenTheDatabaseIsResolved_ThenItIsUnderApplicationSupport',
      () async {
        final path = await pathsWith(const {}).resolveDatabasePath();

        expect(path, startsWith(temporary.path));
        expect(path, endsWith('catalog.db'));
      },
    );

    test(
      'GivenNoApplicationFolder_WhenTheDatabaseIsResolved_ThenTheFolderIsCreated',
      () async {
        await pathsWith(const {}).resolveDatabasePath();

        expect(
          Directory(
            p.join(temporary.path, CorePaths.applicationFolderName),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test('GivenTheRuntimeOverride_WhenTheDatabaseIsResolved_ThenItWins',
        () async {
      final path = await pathsWith({
        CorePaths.databasePathVariable: '/scratch/test.db',
      }).resolveDatabasePath();

      expect(
        path,
        '/scratch/test.db',
        reason:
            'this override is what points development and the integration '
            'suite at a scratch database so no run touches a real catalog',
      );
    });

    test('GivenAnEmptyOverride_WhenTheDatabaseIsResolved_ThenItIsIgnored',
        () async {
      final path = await pathsWith({
        CorePaths.databasePathVariable: '',
      }).resolveDatabasePath();

      expect(path, endsWith('catalog.db'));
    });

    test(
      'GivenAnExistingApplicationFolder_WhenItIsResolvedAgain_ThenItIsReused',
      () async {
        final paths = pathsWith(const {});

        final first = await paths.resolveApplicationDirectory();
        final second = await paths.resolveApplicationDirectory();

        expect(first.path, second.path);
        expect(first.existsSync(), isTrue);
      },
    );
  });
}
