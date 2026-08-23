import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/core_status_mapper.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapCoreStatus — the index family', () {
    test(
      'GivenTheInvalidInputCode_WhenItIsMapped_ThenTheFailureIsInvalidInput',
      () {
        final failure = mapCoreStatus(
          CoreStatusFamily.indexing,
          INDEX_ERR_INVALID_INPUT,
        );

        expect(failure, isA<InvalidInputFailure>());
        expect(failure.coreStatusCode, INDEX_ERR_INVALID_INPUT);
      },
    );

    test(
      'GivenTheUnauthorizedCode_WhenItIsMapped_ThenTheFailureIsUnauthorized',
      () {
        expect(
          mapCoreStatus(CoreStatusFamily.indexing, INDEX_ERR_UNAUTHORIZED),
          isA<UnauthorizedFailure>(),
        );
      },
    );

    test(
      'GivenTheNotInitializedCode_WhenItIsMapped_ThenTheFailureIsNotInitialized',
      () {
        expect(
          mapCoreStatus(CoreStatusFamily.indexing, INDEX_ERR_NOT_INITIALIZED),
          isA<NotInitializedFailure>(),
        );
      },
    );

    // The index family predates the others and uses 4 for "other" where every
    // later family uses 4 for "not found". This is the test that would fail if
    // the mapper ever collapsed the families into one table.
    test(
      'GivenTheCodeFour_WhenItIsMappedAsIndex_ThenTheFailureIsUnexpected',
      () {
        expect(
          mapCoreStatus(CoreStatusFamily.indexing, 4),
          isA<UnexpectedFailure>(),
        );
      },
    );

    test('GivenTheCodeFour_WhenItIsMappedAsFile_ThenTheFailureIsNotFound', () {
      expect(mapCoreStatus(CoreStatusFamily.file, 4), isA<NotFoundFailure>());
    });
  });

  group('mapCoreStatus — the file family', () {
    const cases = <int, Type>{
      FILE_ERR_INVALID_INPUT: InvalidInputFailure,
      FILE_ERR_UNAUTHORIZED: UnauthorizedFailure,
      FILE_ERR_NOT_INITIALIZED: NotInitializedFailure,
      FILE_ERR_NOT_FOUND: NotFoundFailure,
      FILE_ERR_INVALID_STATE: InvalidStateFailure,
      FILE_ERR_DISK: DiskFailure,
      FILE_ERR_INTEGRITY: IntegrityFailure,
      FILE_ERR_OTHER: UnexpectedFailure,
    };

    cases.forEach((code, expected) {
      test(
        'GivenTheFileCode${code}_WhenItIsMapped_ThenTheFailureIs$expected',
        () {
          final failure = mapCoreStatus(CoreStatusFamily.file, code);

          expect(failure.runtimeType, expected);
          expect(failure.coreStatusCode, code);
        },
      );
    });
  });

  group('mapCoreStatus — the auth family', () {
    const cases = <int, Type>{
      AUTH_ERR_INVALID_INPUT: InvalidInputFailure,
      AUTH_ERR_UNAUTHORIZED: UnauthorizedFailure,
      AUTH_ERR_NOT_INITIALIZED: NotInitializedFailure,
      AUTH_ERR_INVALID_STATE: InvalidStateFailure,
      AUTH_ERR_CONFIG: ConfigurationFailure,
      // The account already exists (UC-01 AF-04). Its own variant rather than
      // an invalid-input one, because the owner is not being told to correct
      // what they typed — they are being sent to the login screen.
      AUTH_ERR_CONFLICT: ConflictFailure,
      AUTH_ERR_OTHER: UnexpectedFailure,
    };

    cases.forEach((code, expected) {
      test(
        'GivenTheAuthCode${code}_WhenItIsMapped_ThenTheFailureIs$expected',
        () => expect(
          mapCoreStatus(CoreStatusFamily.auth, code).runtimeType,
          expected,
        ),
      );
    });

    // The auth family has no disk code, so 6 is not a code it can return.
    test(
      'GivenACodeTheAuthFamilyDoesNotDefine_WhenItIsMapped_ThenTheFailureIsUnexpected',
      () => expect(
        mapCoreStatus(CoreStatusFamily.auth, FILE_ERR_DISK),
        isA<UnexpectedFailure>(),
      ),
    );
  });

  group('mapCoreStatus — totality', () {
    // IR-08: every status code the core can return maps to exactly one failure.
    // "Every" includes codes no family defines today: the mapping is total, so
    // a core that grows a code still produces a readable failure.
    for (final family in CoreStatusFamily.values) {
      test(
        'Given${family.name}AndAnyNonSuccessCode_WhenItIsMapped_ThenAFailureIsAlwaysProduced',
        () {
          for (var code = 1; code <= 32; code++) {
            final failure = mapCoreStatus(family, code);

            expect(
              failure.coreStatusCode,
              code,
              reason: 'the ${family.name} family lost the code $code',
            );
          }
        },
      );

      test(
        'Given${family.name}AndItsSuccessCode_WhenItIsMapped_ThenTheFailureIsUnexpected',
        () => expect(
          mapCoreStatus(family, family.okCode),
          isA<UnexpectedFailure>(),
          reason:
              'a success code reaching the mapper is a caller bug, and must not '
              'be dressed up as a real failure',
        ),
      );
    }
  });

  group('Failure.isCoreUnavailable', () {
    test(
      'GivenAnUnloadableLibrary_WhenTheFailureIsInspected_ThenTheCoreIsUnavailable',
      () => expect(
        const Failure.coreLibraryNotLoaded(
          path: r'C:\nowhere\alexandria_ffi.dll',
        ).isCoreUnavailable,
        isTrue,
      ),
    );

    test(
      'GivenAnUnsupportedVersion_WhenTheFailureIsInspected_ThenTheCoreIsUnavailable',
      () => expect(
        const Failure.coreVersionUnsupported(
          found: '0.9.0',
          required: '>=0.1.0 <0.2.0',
        ).isCoreUnavailable,
        isTrue,
      ),
    );

    test(
      'GivenANotFoundFailure_WhenTheFailureIsInspected_ThenTheCoreIsAvailable',
      () => expect(
        mapCoreStatus(
          CoreStatusFamily.file,
          FILE_ERR_NOT_FOUND,
        ).isCoreUnavailable,
        isFalse,
      ),
    );

    test(
      'GivenUnreadablePreferences_WhenTheFailureIsInspected_ThenTheCoreIsAvailable',
      () => expect(
        const Failure.preferencesUnreadable().isCoreUnavailable,
        isFalse,
        reason:
            'startup step 5 falls back to the system theme and language rather '
            'than blocking on the core-unavailable screen',
      ),
    );
  });

  group('the health contract', () {
    test('GivenTheCoresHealthyCode_WhenItIsRead_ThenItIsTwoHundredNotZero', () {
      expect(
        coreHealthyStatusCode,
        200,
        reason:
            'alexandria_health_status_code is HTTP-shaped; assuming the *_OK '
            'convention here would read every healthy core as unhealthy',
      );
    });
  });
}
