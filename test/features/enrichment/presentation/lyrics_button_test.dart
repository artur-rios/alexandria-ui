import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/enrichment/domain/enrichment_gateway.dart';
import 'package:alexandria_ui/features/enrichment/domain/synced_lyrics.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
import 'package:alexandria_ui/features/enrichment/presentation/lyrics_button.dart';
import 'package:alexandria_ui/features/enrichment/presentation/synced_lyrics_view.dart';
import 'package:alexandria_ui/features/shell/application/preferences_controller.dart';
import 'package:alexandria_ui/features/shell/application/preferences_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_enrichment_gateway.dart';

/// The lyrics button and the panel it opens (music enrichment design).
///
/// The gap it closes: before it, the only way to see lyrics was the panel
/// beneath the player, which renders nothing until a track has already been
/// looked up — so a library nobody had ever swept showed no lyrics anywhere
/// and no way to ask for any either.
void main() {
  const cachedLyrics = TrackEnrichment(
    lyrics: TrackLyrics(lines: ['a cached line'], source: 'lrclib'),
  );

  /// Pumps the button over a container whose enrichment gateway is [gateway],
  /// then presses it and settles the sheet it opens.
  Future<void> pumpAndOpen(
    WidgetTester tester, {
    required FakeEnrichmentGateway gateway,
    bool musicLookupEnabled = true,
  }) async {
    final container = ProviderContainer(
      overrides: <Override>[
        enrichmentGatewayProvider.overrideWithValue(gateway),
        // The preference itself, without a startup sequence behind it: the
        // rule under test is what the panel does about the switch, not how
        // the switch reaches the settings store.
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
            body: LyricsButton(fileUuid: 'f-1', artistName: 'Miles Davis'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
  }

  testWidgets('GivenATrack_WhenThePlayerIsOpen_ThenALyricsButtonIsOffered', (
    tester,
  ) async {
    final gateway = FakeEnrichmentGateway();
    await pumpAndOpen(tester, gateway: gateway);

    // The tap in the harness already proved it is there and pressable; what
    // this asserts is that it is *named*, since it carries a glyph alone.
    final l10n = AppLocalizations.of(tester.element(find.byType(LyricsPanel)));
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).tooltip,
      l10n.lyricsOpen,
    );
  });

  testWidgets(
    'GivenCachedLyrics_WhenTheButtonIsPressed_ThenTheyAreShownWithoutALookup',
    (tester) async {
      final gateway = FakeEnrichmentGateway(enrichment: cachedLyrics);

      await pumpAndOpen(tester, gateway: gateway);

      expect(find.text('a cached line'), findsOneWidget);
      expect(
        gateway.runs,
        isEmpty,
        reason:
            'the words were already on the machine; reaching the network for '
            'them again would be a request made for nothing',
      );
    },
  );

  testWidgets(
    'GivenNothingCached_WhenTheButtonIsPressed_ThenALookupRunsForThatTrack',
    (tester) async {
      // "Show the lyrics right away" is the whole point: a track nobody has
      // looked up shows its words on the first press, not on the second.
      final gateway = FakeEnrichmentGateway()
        ..runOutcome = const EnrichmentRunOutcome.done(
          report: EnrichmentReport(considered: 1, found: 1),
        );

      await pumpAndOpen(tester, gateway: gateway);

      expect(gateway.runs, hasLength(1));
      expect(gateway.runs.single, isA<EnrichmentScopeFile>());
      expect(
        (gateway.runs.single as EnrichmentScopeFile).fileUuid,
        'f-1',
        reason: 'a sweep of the whole library takes hours; this is one track',
      );
    },
  );

  testWidgets(
    'GivenALookupThatFinds_WhenItFinishes_ThenTheWordsAppearWithoutReopening',
    (tester) async {
      // A core that has the words *after* the run, which is the only order
      // that proves anything here: the panel has to re-read what the lookup
      // stored, not merely have been given it up front.
      final gateway = _FindsOnRun(found: cachedLyrics);

      await pumpAndOpen(tester, gateway: gateway);

      expect(find.text('a cached line'), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTimedLyrics_WhenThePanelOpens_ThenTheyFollowTheMusic',
    (tester) async {
      await pumpAndOpen(
        tester,
        gateway: FakeEnrichmentGateway(
          enrichment: const TrackEnrichment(
            lyrics: TrackLyrics(
              lines: ['a cached line'],
              synced: SyncedLyrics([
                SyncedLyricLine(at: Duration.zero, text: 'the first line'),
                SyncedLyricLine(at: Duration(seconds: 9), text: 'the second'),
              ]),
            ),
          ),
        ),
      );

      // The timed view, not the plain block: a track whose timing somebody
      // contributed is exactly the case the synced view exists for.
      expect(find.byType(SyncedLyricsView), findsOneWidget);
      expect(find.text('the first line'), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheLookupIsSwitchedOff_WhenTheButtonIsPressed_ThenNothingIsFetchedAndTheSwitchIsNamed',
    (tester) async {
      // Off means off. Asking anyway and being refused by the core would
      // make the preference a formality, and would tell the owner the
      // installation is misconfigured when they are the one who configured
      // it.
      final gateway = FakeEnrichmentGateway();

      await pumpAndOpen(
        tester,
        gateway: gateway,
        musicLookupEnabled: false,
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(LyricsPanel)));

      expect(gateway.runs, isEmpty);
      expect(find.text(l10n.lyricsSwitchedOff), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheServicesHaveNothing_WhenTheLookupFinishes_ThenThePanelSaysSo',
    (tester) async {
      // An answer, not a failure — and one worth saying out loud, or a
      // lookup that legitimately found nothing is indistinguishable from one
      // that never ran.
      await pumpAndOpen(tester, gateway: FakeEnrichmentGateway());
      final l10n = AppLocalizations.of(tester.element(find.byType(LyricsPanel)));

      expect(find.text(l10n.lyricsNone), findsOneWidget);
    },
  );
}

/// A gateway that has nothing until a run asks for it, and everything after
/// — the core's own behaviour, in the one ordering that matters.
class _FindsOnRun extends FakeEnrichmentGateway {
  _FindsOnRun({required this.found}) {
    runOutcome = const EnrichmentRunOutcome.done(
      report: EnrichmentReport(considered: 1, found: 1),
    );
  }

  /// What the core holds once the run has finished.
  final TrackEnrichment found;

  @override
  Future<EnrichmentRunOutcome> run({
    required EnrichmentScope scope,
    required String credential,
  }) async {
    enrichment = found;
    return super.run(scope: scope, credential: credential);
  }
}

/// A [PreferencesController] holding a fixed state — the same seam
/// `album_visor_test.dart` uses for playback.
class _FixedPreferences extends PreferencesController {
  _FixedPreferences(this._state);

  final PreferencesState _state;

  @override
  PreferencesState build() => _state;
}
