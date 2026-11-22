import 'dart:async';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_gateway.dart';
import 'package:alexandria_ui/features/libraries/presentation/rename_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_library_gateway.dart';

/// Renaming a library from anywhere that lists one.
void main() {
  const course = Library(uuid: 'lib-1', name: 'Course', rootPath: '/course');

  Future<FakeLibraryGateway> open(
    WidgetTester tester, {
    List<LibraryWrite> writeOutcomes = const [],
    FakeIndexGateway? indexGateway,
  }) async {
    final gateway = FakeLibraryGateway(libraries: const [course])
      ..writeOutcomes.addAll(writeOutcomes);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryGatewayProvider.overrideWithValue(gateway),
          if (indexGateway != null)
            indexGatewayProvider.overrideWithValue(indexGateway),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: const [Locale('en'), Locale('pt', 'BR')],
          home: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => unawaited(renameLibrary(context, ref, course)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return gateway;
  }

  Finder confirm() => find.widgetWithText(FilledButton, 'Rename');

  testWidgets(
    'GivenALibrary_WhenRenameOpens_ThenItsNameIsPrefilledAndSelected',
    (tester) async {
      await open(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Course');
      expect(
        field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 6),
      );
    },
  );

  testWidgets('GivenABlankName_ThenConfirmIsDisabled', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(tester.widget<FilledButton>(confirm()).onPressed, isNull);
  });

  testWidgets(
    'GivenANewName_WhenConfirmed_ThenTheRenameIsSentAndTheDialogCloses',
    (tester) async {
      final gateway = await open(tester);

      await tester.enterText(find.byType(TextField), '  Rust course ');
      await tester.pump();
      await tester.tap(confirm());
      await tester.pumpAndSettle();

      expect(gateway.renamedCalls.single, (uuid: 'lib-1', name: 'Rust course'));
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'GivenTheCoreRefuses_WhenConfirmed_ThenTheDialogStaysOpenShowingTheMessage',
    (tester) async {
      await open(
        tester,
        writeOutcomes: const [
          LibraryWrite.failed(
            failure: Failure.conflict(
              family: CoreStatusFamily.library,
              code: 6,
            ),
          ),
        ],
      );

      await tester.enterText(find.byType(TextField), 'Taken');
      await tester.pump();
      await tester.tap(confirm());
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      );
      expect(find.text(l10n.failureConflict), findsOneWidget);
    },
  );

  testWidgets('GivenARunInProgress_WhenRenamed_ThenTheRenameIsSent', (
    tester,
  ) async {
    // A rename touches the library's name, not its files, so a run walking
    // them is no reason to refuse it.
    final gateway = await open(
      tester,
      indexGateway: FakeIndexGateway()..readOutcomes = [runningRun()],
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AlertDialog)),
    );
    await container
        .read(indexRunsControllerProvider.notifier)
        .follow('lib-1', 'run-1');

    await tester.enterText(find.byType(TextField), 'Renamed');
    await tester.pump();
    await tester.tap(confirm());
    await tester.pumpAndSettle();

    expect(gateway.renamedCalls, [(uuid: 'lib-1', name: 'Renamed')]);

    // Ends the poller the run started, so nothing is left ticking.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
