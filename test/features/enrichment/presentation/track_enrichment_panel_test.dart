import 'dart:io';

import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/enrichment/domain/track_enrichment.dart';
import 'package:alexandria_ui/features/enrichment/presentation/track_enrichment_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_auth_gateway.dart';
import '../../../support/fake_enrichment_gateway.dart';

/// What the now-playing screen shows beside a track (music enrichment
/// design).
void main() {
  Future<FakeEnrichmentGateway> pumpPanel(
    WidgetTester tester, {
    required TrackEnrichment enrichment,
    String? artistName = 'Miles Davis',
  }) async {
    final gateway = FakeEnrichmentGateway(enrichment: enrichment);
    final container = ProviderContainer(
      overrides: <Override>[
        enrichmentGatewayProvider.overrideWithValue(gateway),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(sessionControllerProvider.notifier)
        .establish(FakeAuthGateway.defaultSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TrackEnrichmentPanel(
                fileUuid: 'f-1',
                artistName: artistName,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return gateway;
  }

  testWidgets(
    'GivenNothingStored_WhenTheTrackPlays_ThenThePanelTakesNoSpace',
    (tester) async {
      // Most of a real library. An embellishment does not get to occupy the
      // screen announcing its own absence.
      await pumpPanel(tester, enrichment: TrackEnrichment.none);

      expect(find.byType(SelectableText), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(
        tester.getSize(find.byType(TrackEnrichmentPanel)).height,
        0,
        reason: 'an empty panel reserved height',
      );
    },
  );

  testWidgets('GivenLyrics_WhenTheTrackPlays_ThenTheyAreShownAndCredited', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      enrichment: const TrackEnrichment(
        lyrics: TrackLyrics(
          lines: ['first line', 'second line'],
          source: 'lrclib',
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TrackEnrichmentPanel)),
    );

    expect(find.text('first line\nsecond line'), findsOneWidget);
    // The words are somebody's, not this application's.
    expect(find.text(l10n.enrichmentLyricsSource('lrclib')), findsOneWidget);
  });

  testWidgets('GivenLyrics_WhenShown_ThenTheyCanBeSelected', (tester) async {
    // The obvious thing to do with a line of lyrics is copy it.
    await pumpPanel(
      tester,
      enrichment: const TrackEnrichment(
        lyrics: TrackLyrics(lines: ['first line']),
      ),
    );

    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('GivenAnImage_WhenItsFileIsGone_ThenNoBrokenGlyphIsShown', (
    tester,
  ) async {
    // The bytes are a cache, and a cache can be cleared or moved. Flutter's
    // broken-image glyph would read as a defect in the application rather
    // than as a picture that is simply not there any more.
    await pumpPanel(
      tester,
      enrichment: const TrackEnrichment(
        artistImage: ArtistImage(
          artistName: 'Miles Davis',
          path: '/nowhere/at/all/mb-1.jpg',
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.broken_image), findsNothing);
  });

  testWidgets('GivenAnImageWithASource_WhenShown_ThenItIsCredited', (
    tester,
  ) async {
    // Wikimedia Commons licences require attribution, so the credit travels
    // with the picture rather than being optional decoration.
    final file = File(
      '${Directory.systemTemp.createTempSync('enrichment').path}/portrait.png',
    );
    // A 1x1 PNG, which is all a credit test needs to have decodable bytes.
    file.writeAsBytesSync([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0,
      1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    await pumpPanel(
      tester,
      enrichment: TrackEnrichment(
        artistImage: ArtistImage(
          artistName: 'Miles Davis',
          path: file.path,
          sourceUrl: 'https://commons.example/portrait.jpg',
        ),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(TrackEnrichmentPanel)),
    );

    expect(
      find.text(l10n.enrichmentImageCredit('https://commons.example/portrait.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('GivenATrack_WhenThePanelReads_ThenItAsksUnderTheAlbumArtist', (
    tester,
  ) async {
    // Whose record it is, not who performed the track — a guest appearance
    // must not put the guest's face on the host's album.
    final gateway = await pumpPanel(
      tester,
      enrichment: TrackEnrichment.none,
      artistName: 'Miles Davis',
    );

    expect(gateway.reads, [(fileUuid: 'f-1', artistName: 'Miles Davis')]);
  });
}
