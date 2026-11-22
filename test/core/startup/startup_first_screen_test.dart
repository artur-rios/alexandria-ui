import 'package:alexandria_ui/app.dart';
import 'package:alexandria_ui/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_core_client.dart';
import '../../support/in_memory_settings_store.dart';
import '../../support/test_container.dart';

/// Startup ends at the shell: there is no sign-up and no login in front of it
/// (library navigation design §2).
void main() {
  /// Pumps the whole application over [core] and lets startup settle.
  Future<void> startOver(WidgetTester tester, FakeCoreClient core) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        ...fakeCoreOverrides(
          core: core,
          settings: InMemorySettingsStore(rechecksAtStartup: false),
        ),
        // No Chromium in a test binding (see `pumpShell`).
        pageEngineEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AlexandriaApp(),
      ),
    );
    await container.read(startupControllerProvider.notifier).start();
    await tester.pumpAndSettle();
  }

  /// A password field is what every sign-up and login form had, and nothing
  /// else in the application has one.
  final passwordField = find.byWidgetPredicate(
    (widget) => widget is EditableText && widget.obscureText,
  );

  testWidgets(
    'GivenAFreshCatalog_WhenStartupFinishes_ThenTheShellIsTheFirstScreen',
    (tester) async {
      await startOver(tester, FakeCoreClient(countFilesResult: 0));

      expect(find.byType(ShellScreen), findsOneWidget);
      expect(passwordField, findsNothing);
    },
  );

  testWidgets(
    'GivenAnExistingCatalog_WhenStartupFinishes_ThenTheShellIsTheFirstScreen',
    (tester) async {
      final core = FakeCoreClient()
        ..libraryResponse = (
          status: LIBRARY_OK,
          json: '[{"uuid":"l1","name":"Movies","rootPath":"/m"}]',
        );

      await startOver(tester, core);

      expect(find.byType(ShellScreen), findsOneWidget);
      expect(passwordField, findsNothing);
    },
  );
}
