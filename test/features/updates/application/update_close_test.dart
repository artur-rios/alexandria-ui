import 'dart:io';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/indexing/domain/index_gateway.dart';
import 'package:alexandria_ui/features/indexing/domain/index_run.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/updates/application/update_close.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_index_gateway.dart';
import '../../../support/fake_session_activity.dart';
import '../../../support/fake_updates.dart';
import '../../../support/fake_window_placement.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/shell_harness.dart';

/// Closing the application to install an update (update-check design §3
/// step 3).
void main() {
  late Directory support;
  late File package;

  setUp(() {
    support = Directory.systemTemp.createTempSync('alexandria_uc');
    package = File('${support.path}/alexandria-installer-1.2.0-linux-x64.sh')
      ..writeAsStringSync('#!/bin/sh\n');
  });
  tearDown(() => support.deleteSync(recursive: true));

  Future<
    ({
      WidgetRef ref,
      FakeUpdateInstaller installer,
      List<int> exits,
      FakeSessionActivity activity,
      FakeIndexGateway index,
      ProviderContainer container,
    })
  >
  openShell(
    WidgetTester tester, {
    bool unsaved = false,
    bool scanning = false,
  }) async {
    final installer = FakeUpdateInstaller();
    final exits = <int>[];
    final activity = FakeSessionActivity(holdsUnsavedChanges: unsaved);
    final index = FakeIndexGateway();
    final container = await tester.pumpShell(
      settings: InMemorySettingsStore(rechecksAtStartup: false),
      extraOverrides: <Override>[
        appVersionProvider.overrideWithValue('1.1.0'),
        installKindProbeProvider.overrideWithValue(FakeInstallKindProbe()),
        updateInstallerProvider.overrideWithValue(installer),
        appExitProvider.overrideWithValue(exits.add),
        windowPlacementProvider.overrideWithValue(FakeWindowPlacement()),
        sessionActivitiesProvider.overrideWithValue([activity]),
        pendingUpdateStoreProvider.overrideWith(
          (ref) async => pendingStoreIn(support),
        ),
        indexGatewayProvider.overrideWithValue(index),
      ],
    );

    // Started after signing in: the activity strip animates a running scan,
    // and the sign-in would never settle around it.
    if (scanning) {
      index.activeRunsOutcome = const ActiveRunsOutcome.read(
        runs: [
          IndexRun(
            runId: 'r1',
            root: '/media/movies',
            libraryUuid: 'lib-1',
            status: IndexRunStatus.running,
          ),
        ],
      );
      await container.read(activeRunsControllerProvider.notifier).refresh();
      await tester.pump();
    }

    return (
      ref: tester.element(find.byType(ShellScreen)) as WidgetRef,
      installer: installer,
      exits: exits,
      activity: activity,
      index: index,
      container: container,
    );
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  testWidgets('GivenUnsavedEdits_WhenDeclined_ThenNothingRuns', (tester) async {
    final sut = await openShell(tester, unsaved: true);

    final closing = closeForUpdate(
      tester.element(find.byType(ShellScreen)),
      sut.ref,
      release: aRelease('1.2.0'),
      package: package,
    );
    await tester.pumpAndSettle();
    expect(find.text(messages(tester).updateUnsavedMessage), findsOneWidget);
    await tester.tap(find.text(messages(tester).updateCancel));
    await tester.pumpAndSettle();

    expect(await closing, isFalse);
    expect(sut.installer.launches, isEmpty);
    expect(sut.exits, isEmpty);
    expect(pendingStoreIn(support).read(), isNull);
  });

  testWidgets(
    'GivenARunningScan_WhenConfirmed_ThenTheMarkerIsWrittenAndTheInstallerLaunched',
    (tester) async {
      final sut = await openShell(tester, scanning: true);

      final closing = closeForUpdate(
        tester.element(find.byType(ShellScreen)),
        sut.ref,
        release: aRelease('1.2.0'),
        package: package,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(messages(tester).updateScanMessage), findsOneWidget);
      await tester.tap(find.text(messages(tester).updateScanConfirm));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(await closing, isTrue);
      expect(pendingStoreIn(support).read(), (from: '1.1.0', to: '1.2.0'));
      expect(sut.installer.launches.single.package, package.path);
      expect(
        sut.installer.launches.single.location,
        '/home/me/.local/opt/alexandria',
      );
      expect(sut.exits, [0]);
    },
  );

  testWidgets(
    'GivenNothingPending_WhenClosed_ThenActivitiesEndedAndTheAppExits',
    (tester) async {
      final sut = await openShell(tester);
      final endedBefore = sut.activity.endCount;

      final closing = closeForUpdate(
        tester.element(find.byType(ShellScreen)),
        sut.ref,
        release: aRelease('1.2.0'),
        package: package,
      );
      await tester.pumpAndSettle();

      expect(await closing, isTrue);
      expect(sut.activity.endCount, endedBefore + 1);
      expect(sut.installer.launches, hasLength(1));
      expect(sut.exits, [0]);
    },
  );
}
