import 'dart:async';

import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/shell/presentation/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The modal every destructive action goes through (FR-UX-10, UC-38 AF-05).
void main() {
  /// Opens the dialog and hands back what it eventually resolved to.
  ///
  /// The result is read through a holder rather than awaited inline, because
  /// the assertions run while the dialog is still on screen.
  Future<({List<bool> answers, BuildContext context})> open(
    WidgetTester tester, {
    String title = 'Delete “Blade Runner”?',
    String message = 'The record for “Blade Runner” will be removed.',
    String confirmLabel = 'Delete',
    String? fileOnDiskNotice,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final answers = <bool>[];
    late BuildContext captured;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('pt', 'BR')],
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    unawaitedConfirmation() async => answers.add(
      await ConfirmationDialog.show(
        captured,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        fileOnDiskNotice: fileOnDiskNotice,
      ),
    );

    // Deliberately not awaited: the dialog is still on screen while the
    // assertions run, and the future completes only once the owner answers.
    unawaited(unawaitedConfirmation());
    await tester.pumpAndSettle();

    return (answers: answers, context: captured);
  }

  testWidgets(
    'GivenADestructiveAction_WhenItIsConfirmed_ThenTheDialogNamesWhatIsRemoved',
    (tester) async {
      await open(tester);

      expect(find.text('Delete “Blade Runner”?'), findsOneWidget);
      expect(
        find.text('The record for “Blade Runner” will be removed.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'GivenAnActionReachingTheDisk_WhenItIsConfirmed_ThenTheDialogSaysSo',
    (tester) async {
      await open(
        tester,
        fileOnDiskNotice: 'The file will be deleted from disk.',
      );

      expect(find.text('The file will be deleted from disk.'), findsOneWidget);
    },
  );

  testWidgets(
    'GivenACatalogOnlyAction_WhenItIsConfirmed_ThenNoDiskNoticeIsShown',
    (tester) async {
      await open(tester);

      expect(find.textContaining('disk'), findsNothing);
    },
  );

  testWidgets('GivenTheDialog_WhenTheOwnerConfirms_ThenItResolvesToTrue', (
    tester,
  ) async {
    final opened = await open(tester);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(opened.answers, [true]);
  });

  testWidgets(
    'GivenTheDialog_WhenTheOwnerCancels_ThenItResolvesToFalseAndNothingChanges',
    (tester) async {
      // AF-05: cancelling changes nothing and leaves the owner where they were.
      final opened = await open(tester);
      final l10n = AppLocalizations.of(opened.context);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(opened.answers, [false]);
      expect(find.byType(ConfirmationDialog), findsNothing);
    },
  );

  testWidgets(
    'GivenTheDialog_WhenItIsDismissedWithEscape_ThenItResolvesToFalse',
    (tester) async {
      // A dismissal must never be mistaken for a confirmation.
      final opened = await open(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(opened.answers, [false]);
    },
  );

  testWidgets(
    'GivenTheDialog_WhenItOpens_ThenTheKeyboardStartsOnTheDecliningAction',
    (tester) async {
      // FR-UX-11 wants the actions reachable; a destructive action firing on a
      // stray return key is the loss the confirmation exists to prevent.
      final opened = await open(tester);
      final l10n = AppLocalizations.of(opened.context);

      final focused = tester.widget<TextButton>(
        find.ancestor(
          of: find.text(l10n.cancel),
          matching: find.byType(TextButton),
        ),
      );
      expect(focused.autofocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(opened.answers, [false]);
    },
  );

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets(
      'Given${name}_WhenTheDialogOpens_ThenItsOwnStringsAreLocalized',
      (tester) async {
        final opened = await open(tester, locale: locale);
        final l10n = AppLocalizations.of(opened.context);

        expect(find.text(l10n.cancel), findsOneWidget);
      },
    );
  }

  for (final (name, mode) in [
    ('Light', ThemeMode.light),
    ('Dark', ThemeMode.dark),
  ]) {
    testWidgets(
      'GivenThe${name}Theme_WhenTheDialogOpens_ThenItRendersInThatBrightness',
      (tester) async {
        await open(tester, themeMode: mode);

        final context = tester.element(find.byType(ConfirmationDialog));
        expect(
          Theme.of(context).brightness,
          mode == ThemeMode.light ? Brightness.light : Brightness.dark,
        );
      },
    );
  }
}
