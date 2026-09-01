import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/failures/core_status.dart';
import 'package:alexandria_ui/core/failures/failure.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
import 'package:alexandria_ui/features/enrichment/presentation/enrich_track_button.dart';
import 'package:alexandria_ui/features/shell/application/preferences_controller.dart';
import 'package:alexandria_ui/features/shell/application/preferences_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_enrichment_gateway.dart';

/// Asking the core to look one track up (music enrichment design).
void main() {
  Future<({FakeEnrichmentGateway gateway, ProviderContainer container})> pumpButton(
    WidgetTester tester, {
    FakeEnrichmentGateway? gateway,
    bool musicLookupEnabled = true,
  }) async {
    final theGateway = gateway ?? FakeEnrichmentGateway();
    final container = ProviderContainer(
      overrides: <Override>[
        enrichmentGatewayProvider.overrideWithValue(theGateway),
        preferencesControllerProvider.overrideWith(
          () => _FixedPreferences(
            PreferencesState(musicLookupEnabled: musicLookupEnabled),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EnrichTrackButton(fileUuid: 'f-1', artistName: 'Miles Davis'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (gateway: theGateway, container: container);
  }

  testWidgets('GivenATrack_WhenTheOwnerAsks_ThenOnlyThatTrackIsScoped', (
    tester,
  ) async {
    // Scoped to one track deliberately: the sweep is hours at MusicBrainz's
    // one-request-per-second limit, and an action that long does not belong
    // on a button with nowhere to report progress.
    final pumped = await pumpButton(tester);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(pumped.gateway.runs, hasLength(1));
    expect(
      (pumped.gateway.runs.single as EnrichmentScopeFile).fileUuid,
      'f-1',
    );
  });

  testWidgets('GivenTheServicesHadNothing_WhenItFinishes_ThenTheOwnerIsTold', (
    tester,
  ) async {
    // A lookup that legitimately found nothing is otherwise
    // indistinguishable from one that never ran.
    await pumpButton(tester);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EnrichTrackButton)),
    );

    expect(find.text(l10n.enrichmentNothingFound), findsOneWidget);
  });

  testWidgets('GivenSomethingWasFound_WhenItFinishes_ThenNothingIsAnnounced', (
    tester,
  ) async {
    // The words and the photograph appearing below are the report.
    final gateway = FakeEnrichmentGateway()
      ..runOutcome = const EnrichmentRunOutcome.done(
        report: EnrichmentReport(considered: 2, found: 2),
      );
    await pumpButton(tester, gateway: gateway);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('GivenEnrichmentIsSwitchedOff_WhenAsked_ThenItSaysSoNotAnError', (
    tester,
  ) async {
    // Not the owner's mistake: the installation has not configured it.
    final gateway = FakeEnrichmentGateway()
      ..runOutcome = const EnrichmentRunOutcome.failed(
        failure: Failure.configuration(
          family: CoreStatusFamily.enrichment,
          code: 5,
        ),
      );
    await pumpButton(tester, gateway: gateway);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(EnrichTrackButton)),
    );

    expect(find.text(l10n.enrichmentUnavailable), findsOneWidget);
  });

  testWidgets(
    'GivenTheOwnerSwitchedLookupOff_WhenTheOwnerAsks_ThenNothingIsRequested',
    (tester) async {
      // FR-UX-13: the application asks for nothing while the preference is
      // off. The core would refuse the call anyway, being configured from
      // the same preference — but a request made and refused is still a
      // request made, and the owner switched it off to stop them.
      final pumped = await pumpButton(tester, musicLookupEnabled: false);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(EnrichTrackButton)),
      );

      expect(pumped.gateway.runs, isEmpty);
      expect(find.text(l10n.enrichmentUnavailable), findsOneWidget);
    },
  );

  testWidgets('GivenARunInFlight_WhenAskedAgain_ThenItIsNotStartedTwice', (
    tester,
  ) async {
    // It reaches the network, so it is not instant — and a second request
    // for the same track would spend the rate limit answering it twice.
    final gateway = _SlowGateway();
    await pumpButton(tester, gateway: gateway);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    // The control is a spinner while it runs, so there is nothing to tap.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);

    await tester.pumpAndSettle();
    expect(gateway.runs, hasLength(1));
  });
}

/// A gateway whose run does not finish until the test pumps past it.
class _SlowGateway extends FakeEnrichmentGateway {
  @override
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return super.run(scope: scope, credential: credential);
  }
}

/// A [PreferencesController] holding a fixed state — the same seam
/// `lyrics_button_test.dart` and `album_visor_test.dart` use.
class _FixedPreferences extends PreferencesController {
  _FixedPreferences(this._state);

  final PreferencesState _state;

  @override
  PreferencesState build() => _state;
}
