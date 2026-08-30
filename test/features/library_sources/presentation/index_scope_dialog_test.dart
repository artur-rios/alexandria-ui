import 'dart:async';

import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/domain/file_type.dart';
import 'package:alexandria_ui/features/library_sources/presentation/index_scope_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The dialog that asks what a folder is for (UC-05).
void main() {
  /// Opens the dialog and hands back what it eventually resolved to.
  ///
  /// The answers are read through a holder rather than awaited inline,
  /// because the assertions run while the dialog is still on screen.
  Future<List<List<FileType>?>> open(
    WidgetTester tester, {
    Locale? locale,
    Size size = const Size(1024, 640),
  }) async {
    final answers = <List<FileType>?>[];
    late BuildContext captured;

    // NFR-07: the interface must be usable at 1024x640, which is the size
    // this dialog has the least room in.
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
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

    // Deliberately not awaited: the dialog is still on screen while the
    // assertions run, and it resolves only once something answers it.
    unawaited(IndexScopeDialog.show(captured).then(answers.add));
    await tester.pumpAndSettle();

    return answers;
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(IndexScopeDialog)));

  testWidgets('GivenTheDialogOpens_WhenItIsRead_ThenEveryTypeIsOffered', (
    tester,
  ) async {
    await open(tester);
    final l10n = l10nOf(tester);

    // Seven, which is the core's own FileType — not three buckets that
    // cannot express "books but not images".
    for (final type in FileType.values) {
      expect(
        find.text(fileTypeLabel(type, l10n)),
        findsOneWidget,
        reason: '${type.wireName} must be offerable on its own',
      );
    }
  });

  testWidgets(
    'GivenTheDialogOpens_WhenNothingIsChanged_ThenEverythingIsTicked',
    (tester) async {
      await open(tester);

      final boxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(boxes.every((box) => box.value ?? false), isTrue);
    },
  );

  testWidgets('GivenTheDefault_WhenItIsConfirmed_ThenTheScopeIsTheAbsentOne', (
    tester,
  ) async {
    final answers = await open(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.indexScopeConfirm));
    await tester.pumpAndSettle();

    // Empty, not all seven listed: the absence is what the core reads as
    // every type, and one spelling means a folder that covers everything
    // reads the same however the owner got there.
    expect(answers.single, isEmpty);
  });

  testWidgets(
    'GivenOnlyMusicIsTicked_WhenItIsConfirmed_ThenOnlyMusicIsChosen',
    (tester) async {
      final answers = await open(tester);
      final l10n = l10nOf(tester);

      // Clear everything through the "all" row, then tick the one type.
      await tester.tap(find.text(l10n.indexScopeAll));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.fileTypeAudio));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.indexScopeConfirm));
      await tester.pumpAndSettle();

      expect(answers.single, [FileType.audio]);
    },
  );

  testWidgets('GivenNothingIsTicked_WhenItIsRead_ThenItCannotBeConfirmed', (
    tester,
  ) async {
    await open(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.indexScopeAll));
    await tester.pumpAndSettle();

    // A folder scoped to nothing would record nothing, which no owner means
    // to ask for.
    final confirm = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(l10n.indexScopeConfirm),
        matching: find.byType(FilledButton),
      ),
    );
    expect(confirm.onPressed, isNull);
    expect(find.text(l10n.indexScopeEmpty), findsOneWidget);
  });

  testWidgets('GivenTheDialog_WhenItIsCancelled_ThenNoScopeIsChosen', (
    tester,
  ) async {
    final answers = await open(tester);
    final l10n = l10nOf(tester);

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    // Null, not the empty list: cancelling is not "every type".
    expect(answers.single, isNull);
  });

  for (final (name, locale) in [
    ('English', const Locale('en')),
    ('Portuguese', const Locale('pt', 'BR')),
  ]) {
    testWidgets('Given${name}_WhenTheDialogOpens_ThenNoStringRendersAsItsKey', (
      tester,
    ) async {
      await open(tester, locale: locale);

      expect(find.textContaining('indexScope'), findsNothing);
      expect(find.textContaining('fileType'), findsNothing);
    });
  }
}
