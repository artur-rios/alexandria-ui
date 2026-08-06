import 'package:alexandria_desktop/app.dart';
import 'package:alexandria_desktop/core/bindings/core_isolate.dart';
import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/settings/settings_store.dart';
import 'package:alexandria_desktop/core/startup/core_unavailable_screen.dart';
import 'package:alexandria_desktop/core/theme/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_core_client.dart';
import '../../support/in_memory_settings_store.dart';
import '../../support/test_container.dart';

/// The `CoreUnavailable` state (IR-06, UC-38 AF-04).
void main() {
  Future<void> pumpFailedStartup(
    WidgetTester tester, {
    Size surfaceSize = const Size(1280, 800),
    SettingsStore? settings,
  }) async {
    final container = await tester.pumpAlexandria(
      surfaceSize: surfaceSize,
      overrides: fakeCoreOverrides(
        core: FakeCoreClient(healthResult: 503),
        settings: settings,
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GivenAnUnhealthyCore_WhenStartupSettles_ThenTheUnavailableStateIsShown',
    (tester) async {
      await pumpFailedStartup(tester);

      expect(find.byType(CoreUnavailableScreen), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason:
            'the loading state is replaced by the failure, never left spinning '
            '(UC-38 AF-03)',
      );
    },
  );

  testWidgets(
    'GivenTheUnavailableState_WhenItIsRead_ThenNoRawStatusCodeIsOnScreen',
    (tester) async {
      await pumpFailedStartup(tester);

      // The core reported 503. It belongs in the log, not on the screen
      // (FR-UX-09).
      expect(find.textContaining('503'), findsNothing);
      expect(find.textContaining('CoreUnhealthy'), findsNothing);
    },
  );

  testWidgets(
    'GivenTheUnavailableState_WhenItIsRead_ThenTheMessageIsReadableAndNotAKey',
    (tester) async {
      await pumpFailedStartup(tester);

      final message = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>();

      expect(message, isNotEmpty);
      expect(
        message.every((line) => !line.startsWith('failure')),
        isTrue,
        reason: 'a key rendering as its identifier is a missing translation',
      );
      expect(message.any((line) => line.contains('healthy')), isTrue);
    },
  );

  testWidgets('GivenTheUnavailableState_WhenTheRetryIsPressed_ThenStartupReruns',
      (tester) async {
    var attempts = 0;
    final container = await tester.pumpAlexandria(
      overrides: fakeCoreOverrides(
        loadCore: (_) async {
          attempts++;
          throw const CoreCallException('still unavailable');
        },
      ),
    );

    await container.read(startupControllerProvider.notifier).start();
    await tester.pumpAndSettle();
    expect(attempts, 1);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(attempts, 2, reason: 'the retry re-runs the sequence from step 1');
    expect(find.byType(CoreUnavailableScreen), findsOneWidget);
  });

  testWidgets('GivenTheUnavailableState_WhenItIsBuilt_ThenTheRetryHasFocus',
      (tester) async {
    await pumpFailedStartup(tester);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));

    expect(
      button.autofocus,
      isTrue,
      reason:
          'the primary action of every screen is reachable from the keyboard '
          '(FR-UX-11)',
    );
  });

  group('the minimum supported window size', () {
    testWidgets(
      'GivenTheMinimumWindow_WhenTheUnavailableStateIsShown_ThenNothingOverflows',
      (tester) async {
        await pumpFailedStartup(
          tester,
          surfaceSize: Breakpoint.minimumWindowSize,
        );

        expect(find.byType(CoreUnavailableScreen), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        // tester.takeException() surfaces the RenderFlex overflow that would
        // otherwise only be a red stripe in a screenshot nobody looks at.
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('both themes', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${mode.name}Theme_WhenTheUnavailableStateIsShown_ThenItRenders',
        (tester) async {
          await pumpFailedStartup(
            tester,
            settings: InMemorySettingsStore(themeMode: mode),
          );

          expect(find.byType(CoreUnavailableScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('both languages', () {
    for (final locale in AlexandriaApp.supportedLocales) {
      testWidgets(
        'Given${locale.languageCode}_WhenTheUnavailableStateIsShown_ThenNoKeyRendersAsItsIdentifier',
        (tester) async {
          await pumpFailedStartup(
            tester,
            settings: InMemorySettingsStore(locale: locale),
          );

          final lines = tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data)
              .whereType<String>()
              .toList();

          expect(lines, isNotEmpty);
          for (final line in lines) {
            expect(
              line,
              isNot(startsWith('failure')),
              reason: '$locale renders "$line" as a key rather than a message',
            );
          }
        },
      );
    }
  });
}
