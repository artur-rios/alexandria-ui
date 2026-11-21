import 'dart:async';
import 'dart:io';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/auth/presentation/login_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_ui/features/updates/application/update_state.dart';
import 'package:alexandria_ui/features/updates/data/pending_update_store.dart';
import 'package:alexandria_ui/features/updates/domain/install_kind.dart';
import 'package:alexandria_ui/features/updates/presentation/update_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_updates.dart';
import '../../../support/in_memory_settings_store.dart';
import '../../../support/login_harness.dart';
import '../../../support/shell_harness.dart';

/// The update prompt (update-check design §5).
void main() {
  late Directory support;

  setUp(() => support = Directory.systemTemp.createTempSync('alexandria_ud'));
  tearDown(() => support.deleteSync(recursive: true));

  List<Override> updates({
    String latest = '1.2.0',
    InstallKind kind = InstallKind.linuxInstaller,
    FakeDownloader? downloader,
    FakeBrowserLauncher? browser,
    FakeReleaseSource? source,
  }) => [
    appVersionProvider.overrideWithValue('1.1.0'),
    isReleaseBuildProvider.overrideWithValue(true),
    releaseSourceProvider.overrideWithValue(
      source ?? FakeReleaseSource(aRelease(latest)),
    ),
    downloaderProvider.overrideWithValue(downloader ?? FakeDownloader()),
    installKindProbeProvider.overrideWithValue(FakeInstallKindProbe(kind)),
    pendingUpdateStoreProvider.overrideWith(
      (ref) async => PendingUpdateStore(support),
    ),
    browserLauncherProvider.overrideWithValue(browser ?? FakeBrowserLauncher()),
  ];

  /// Signs in with the check offline, then checks again once [latest] is
  /// out: the prompt shows over the login screen otherwise, and signing in
  /// through it is not what these tests are about.
  Future<ProviderContainer> openShellWithOffer(
    WidgetTester tester, {
    String latest = '1.2.0',
    InstallKind kind = InstallKind.linuxInstaller,
    FakeDownloader? downloader,
    FakeBrowserLauncher? browser,
    InMemorySettingsStore? settings,
  }) async {
    final source = FakeReleaseSource();
    final container = await tester.pumpShell(
      settings: settings,
      extraOverrides: updates(
        kind: kind,
        downloader: downloader,
        browser: browser,
        source: source,
      ),
    );
    source.release = aRelease(latest);
    await container.read(updateControllerProvider.notifier).checkNow();
    await tester.pumpAndSettle();
    return container;
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(UpdateDialog)));

  testWidgets(
    'GivenAnAvailableRelease_WhenTheShellShows_ThenTheDialogShowsVersionAndNotes',
    (tester) async {
      await openShellWithOffer(tester);

      final l10n = messages(tester);
      expect(find.text(l10n.updateAvailableTitle('1.2.0')), findsOneWidget);
      expect(find.text(l10n.updateYouHave('1.1.0')), findsOneWidget);
      expect(find.textContaining('Something new in 1.2.0'), findsOneWidget);
      expect(find.text(l10n.updateNow), findsOneWidget);
      expect(find.text(l10n.updateLater), findsOneWidget);
      expect(find.text(l10n.updateSkip), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheLoginScreen_WhenTheCheckAnswers_ThenThePromptShowsThere',
    (tester) async {
      await tester.pumpLoginScreen(extraOverrides: updates());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(UpdateDialog), findsOneWidget);
    },
  );

  testWidgets(
    'GivenAnotherDialogOpen_WhenTheCheckAnswers_ThenThePromptWaitsUntilItCloses',
    (tester) async {
      // Offline at startup, so nothing is offered until the test asks.
      final source = FakeReleaseSource();
      final container = await tester.pumpShell(
        extraOverrides: updates(source: source),
      );
      await tester.pumpAndSettle();
      final shell = tester.element(find.byType(ShellScreen));
      unawaited(
        showDialog<void>(
          context: shell,
          builder: (context) => const AlertDialog(content: Text('busy')),
        ),
      );
      await tester.pumpAndSettle();

      source.release = aRelease('1.2.0');
      await container.read(updateControllerProvider.notifier).checkNow();
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsNothing);

      Navigator.of(tester.element(find.text('busy'))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);
    },
  );

  testWidgets('GivenLater_WhenTapped_ThenTheDialogClosesAndNothingIsStored', (
    tester,
  ) async {
    final settings = InMemorySettingsStore();
    await openShellWithOffer(tester, settings: settings);

    await tester.tap(find.text(messages(tester).updateLater));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateDialog), findsNothing);
    expect(settings.getString('updates.skippedVersion'), isNull);
  });

  testWidgets('GivenSkip_WhenTapped_ThenTheVersionIsStored', (tester) async {
    final settings = InMemorySettingsStore();
    await openShellWithOffer(tester, settings: settings);

    await tester.tap(find.text(messages(tester).updateSkip));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateDialog), findsNothing);
    expect(settings.getString('updates.skippedVersion'), '1.2.0');
  });

  testWidgets('GivenADownloadThatFails_WhenUpdateNow_ThenTheFailureIsSaid', (
    tester,
  ) async {
    await openShellWithOffer(tester);

    await tester.tap(find.text(messages(tester).updateNow));
    await tester.pumpAndSettle();

    expect(find.text(messages(tester).updateDownloadFailed), findsOneWidget);
    expect(find.text(messages(tester).updateOpenPage), findsOneWidget);
  });

  testWidgets('GivenVerifyFailed_ThenTheSentenceAndTheReleasePage', (
    tester,
  ) async {
    final downloader = FakeDownloader()
      ..contents['https://example.test/alexandria-installer-1.2.0-linux-x64.sh'] =
          'abc'
      ..contents['https://example.test/alexandria-1.2.0-linux-SHA256SUMS'] =
          '${'0' * 64}  alexandria-installer-1.2.0-linux-x64.sh\n';
    final browser = FakeBrowserLauncher();
    await openShellWithOffer(tester, downloader: downloader, browser: browser);

    await tester.tap(find.text(messages(tester).updateNow));
    await tester.pumpAndSettle();

    expect(find.text(messages(tester).updateVerifyFailed), findsOneWidget);
    await tester.tap(find.text(messages(tester).updateOpenPage));
    await tester.pumpAndSettle();
    expect(browser.opened, ['https://example.test/releases/v1.2.0']);
  });

  testWidgets('GivenTheManualKind_ThenOpenReleasePageOnly', (tester) async {
    await openShellWithOffer(tester, kind: InstallKind.manual);

    final l10n = messages(tester);
    expect(find.text(l10n.updateManual), findsOneWidget);
    expect(find.text(l10n.updateOpenPage), findsOneWidget);
    expect(find.text(l10n.updateNow), findsNothing);
  });

  testWidgets('GivenAPreviousFailure_WhenTheAppStarts_ThenTheNotice', (
    tester,
  ) async {
    PendingUpdateStore(support).write(from: '1.1.0', to: '1.2.0');

    await tester.pumpLoginScreen(extraOverrides: updates());
    await tester.pumpAndSettle();

    expect(
      find.text(messages(tester).updatePreviousFailed('1.2.0')),
      findsOneWidget,
    );
    expect(find.text(messages(tester).updateNow), findsNothing);
  });

  testWidgets('GivenTheDialog_WhenCheckingStates_ThenUpdateStateIsAvailable', (
    tester,
  ) async {
    final container = await openShellWithOffer(tester);

    expect(container.read(updateControllerProvider), isA<UpdateAvailable>());
  });
}
