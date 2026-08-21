import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/failures/failure_messages.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/core/theme/app_theme.dart';
import 'package:alexandria_desktop/features/shell/presentation/async_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell's loading, failure, and loaded states
/// (FR-UX-08, FR-UX-09, UC-38 AF-03).
void main() {
  const failure = Failure.disk(family: CoreStatusFamily.file, code: 42);

  Future<int> pump(
    WidgetTester tester,
    AsyncValue<List<String>> value, {
    VoidCallback? onRetry,
    bool withEmptyState = false,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('pt', 'BR')],
        home: Scaffold(
          body: AsyncStateView<List<String>>(
            value: value,
            onRetry: () {
              retries++;
              onRetry?.call();
            },
            isEmpty: withEmptyState ? (data) => data.isEmpty : null,
            emptyBuilder: withEmptyState
                ? (context) => const Text('nothing here')
                : null,
            builder: (context, data) => Text(data.join(', ')),
          ),
        ),
      ),
    );
    await tester.pump();

    return retries;
  }

  testWidgets(
    'GivenAnOperationInFlight_WhenItIsPresented_ThenTheLoadingStateIsShown',
    (tester) async {
      await pump(tester, const AsyncValue.loading());

      expect(find.byType(ShellLoadingView), findsOneWidget);
      expect(find.byType(ShellFailureView), findsNothing);
    },
  );

  testWidgets('GivenALoadedOperation_WhenItIsPresented_ThenItsContentIsShown', (
    tester,
  ) async {
    await pump(tester, const AsyncValue.data(['one', 'two']));

    expect(find.text('one, two'), findsOneWidget);
    expect(find.byType(ShellLoadingView), findsNothing);
  });

  testWidgets(
    'GivenAFailure_WhenItArrivesDuringLoading_ThenTheSpinnerIsReplacedByIt',
    (tester) async {
      // AF-03: never left spinning, and never dismissed silently.
      await pump(tester, const AsyncValue.loading());
      expect(find.byType(ShellLoadingView), findsOneWidget);

      await pump(tester, const AsyncValue.error(failure, StackTrace.empty));

      expect(find.byType(ShellLoadingView), findsNothing);
      expect(find.byType(ShellFailureView), findsOneWidget);
    },
  );

  testWidgets(
    'GivenAFailure_WhenItIsPresented_ThenItReadsAsAMessageNotAStatusCode',
    (tester) async {
      await pump(tester, const AsyncValue.error(failure, StackTrace.empty));

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellFailureView)),
      );
      expect(find.text(failure.localizedMessage(l10n)), findsOneWidget);
      expect(find.textContaining('42'), findsNothing);
    },
  );

  testWidgets('GivenAFailure_WhenTheOwnerRetries_ThenTheOperationIsRunAgain', (
    tester,
  ) async {
    var retried = 0;
    await pump(
      tester,
      const AsyncValue.error(failure, StackTrace.empty),
      onRetry: () => retried++,
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ShellFailureView)),
    );
    await tester.tap(find.widgetWithText(FilledButton, l10n.retry));
    await tester.pump();

    expect(retried, 1);
  });

  testWidgets(
    'GivenAFailure_WhenTheOwnerPressesEnter_ThenTheRetryIsReachable',
    (tester) async {
      // FR-UX-11: on a failure state the retry is the screen's primary action.
      var retried = 0;
      await pump(
        tester,
        const AsyncValue.error(failure, StackTrace.empty),
        onRetry: () => retried++,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(retried, 1);
    },
  );

  testWidgets(
    'GivenAnErrorOutsideTheFailureModel_WhenItIsPresented_ThenItStillReads',
    (tester) async {
      await pump(
        tester,
        AsyncValue.error(
          StateError('a bug, not a condition'),
          StackTrace.empty,
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellFailureView)),
      );
      expect(find.text(l10n.failureUnexpected), findsOneWidget);
      expect(find.textContaining('StateError'), findsNothing);
    },
  );

  testWidgets(
    'GivenAnEmptyResult_WhenItIsPresented_ThenTheEmptyStateIsNotLoadingOrError',
    (tester) async {
      await pump(tester, const AsyncValue.data([]), withEmptyState: true);

      expect(find.text('nothing here'), findsOneWidget);
      expect(find.byType(ShellLoadingView), findsNothing);
      expect(find.byType(ShellFailureView), findsNothing);
    },
  );

  testWidgets(
    'GivenAScreenWithNoEmptyState_WhenTheResultIsEmpty_ThenItBuildsAsLoaded',
    (tester) async {
      await pump(tester, const AsyncValue.data([]));

      expect(find.text(''), findsOneWidget);
      expect(find.byType(ShellFailureView), findsNothing);
    },
  );

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets(
      'Given${name}_WhenAFailureIsPresented_ThenItsStringsAreLocalized',
      (tester) async {
        await pump(
          tester,
          const AsyncValue.error(failure, StackTrace.empty),
          locale: locale,
        );

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ShellFailureView)),
        );
        expect(find.text(l10n.retry), findsOneWidget);
        expect(find.text(failure.localizedMessage(l10n)), findsOneWidget);
      },
    );
  }
  // Testing Specification 7.1: both themes. This component draws the failure
  // state's icon and text from the scheme, so it is the one place a colour
  // that only works in light would show up on every screen at once.
  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenAFailureIsShown_ThenItRendersInThatBrightness',
        (tester) async {
          await pump(
            tester,
            const AsyncValue<List<String>>.error(failure, StackTrace.empty),
            themeMode: mode,
          );

          expect(
            Theme.of(tester.element(find.byType(ShellFailureView))).brightness,
            mode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }
  });
}
