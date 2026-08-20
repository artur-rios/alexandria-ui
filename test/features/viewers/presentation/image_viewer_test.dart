import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/file_details.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/shell/domain/shell_destination.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:alexandria_desktop/features/viewers/presentation/image_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Looking at an image (UC-24, FR-VW-04, FR-VW-07).
void main() {
  final first = aFile(
    uuid: 'img-1',
    name: 'Beach.jpg',
    path: '/home/owner/images/Beach.jpg',
    type: LibraryType.image,
  );
  final second = aFile(
    uuid: 'img-2',
    name: 'Forest.jpg',
    path: '/home/owner/images/Forest.jpg',
    type: LibraryType.image,
  );

  /// Signs in, opens the image listing, and opens [file].
  Future<ProviderContainer> open(
    WidgetTester tester, {
    CatalogFile? file,
    List<CatalogFile>? listing,
    Set<String> missing = const {},
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    bool openIt = true,
  }) async {
    final files = listing ?? [first, second];
    final target = file ?? first;

    final catalog = FakeCatalogGateway(
      listings: {LibraryType.image: CatalogListing.loaded(files: files)},
    );
    for (final entry in files) {
      catalog.details[entry.uuid] = FileDetailsOutcome.read(
        details: FileDetails(file: entry, metadata: const {}),
      );
    }

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        catalogGatewayProvider.overrideWithValue(catalog),
        // A file "on disk" is whatever this says it is, so AF-01 is reachable
        // without a disk.
        fileProbeProvider.overrideWithValue((path) => !missing.contains(path)),
      ],
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ShellNavigationPanel),
        matching: find.byIcon(ShellDestination.images.icon),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(target.name).first);
    await tester.pumpAndSettle();

    if (openIt) {
      final l10n = AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      );
      await tester.tap(find.text(l10n.viewerOpen));
      await tester.pumpAndSettle();
    }

    return container;
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  group('the main flow', () {
    testWidgets('GivenAnImage_WhenItsDetailsOpen_ThenViewingIsOffered', (
      tester,
    ) async {
      await open(tester, openIt: false);

      expect(find.text(messages(tester).viewerOpen), findsOneWidget);
    });

    // Step 3: fitted to the window, zoomable from there (FR-VW-04).
    testWidgets('GivenAnImage_WhenItIsOpened_ThenItIsFittedAndZoomable', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(ImageViewerScreen), findsOneWidget);
    });

    // Step 5: the listing is what "next" means.
    testWidgets('GivenAListing_WhenTheOwnerMovesOn_ThenTheNextImageIsShown', (
      tester,
    ) async {
      final container = await open(tester);

      await tester.tap(
        find.descendant(
          of: find.byType(ImageViewerScreen),
          matching: find.byIcon(Icons.chevron_right),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(imageViewerControllerProvider).current?.uuid,
        'img-2',
      );
      expect(find.text(messages(tester).imageOf(2, 2)), findsOneWidget);
    });

    testWidgets('GivenTheFirstImage_WhenItIsShown_ThenBackIsNotOffered', (
      tester,
    ) async {
      await open(tester);

      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: find.byType(ImageViewerScreen),
                matching: find.widgetWithIcon(IconButton, Icons.chevron_left),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('GivenTheLastImage_WhenItIsShown_ThenOnwardIsNotOffered', (
      tester,
    ) async {
      await open(tester, file: second);

      expect(
        tester
            .widget<IconButton>(
              find.descendant(
                of: find.byType(ImageViewerScreen),
                matching: find.widgetWithIcon(IconButton, Icons.chevron_right),
              ),
            )
            .onPressed,
        isNull,
      );
    });

    // Step 4's "returns to fit".
    testWidgets('GivenAZoomedImage_WhenFitIsPressed_ThenItIsFittedAgain', (
      tester,
    ) async {
      await open(tester);

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      viewer.transformationController!.value = Matrix4.identity()
        ..scaleByDouble(3, 3, 3, 1);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.fit_screen_outlined));
      await tester.pumpAndSettle();

      expect(viewer.transformationController!.value, Matrix4.identity());
    });

    // A zoom does not follow the owner to the next picture.
    testWidgets('GivenAZoomedImage_WhenTheOwnerMovesOn_ThenTheNextIsFitted', (
      tester,
    ) async {
      await open(tester);

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      viewer.transformationController!.value = Matrix4.identity()
        ..scaleByDouble(3, 3, 3, 1);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(ImageViewerScreen),
          matching: find.byIcon(Icons.chevron_right),
        ),
      );
      await tester.pumpAndSettle();

      expect(viewer.transformationController!.value, Matrix4.identity());
    });
  });

  // AF-01: the file is absent from disk.
  group('an image that is not there', () {
    testWidgets('GivenTheFileIsGone_WhenItIsOpened_ThenItIsReportedAsMissing', (
      tester,
    ) async {
      await open(tester, missing: {first.path});

      expect(find.text(messages(tester).viewerFileMissing), findsOneWidget);
      expect(find.text(messages(tester).detailsRescan), findsOneWidget);
    });

    // The listing is still there, so the owner is not stuck on the gap.
    testWidgets('GivenTheFileIsGone_WhenReported_ThenTheOwnerCanMoveOn', (
      tester,
    ) async {
      final container = await open(tester, missing: {first.path});

      await tester.tap(
        find.descendant(
          of: find.byType(ImageViewerScreen),
          matching: find.byIcon(Icons.chevron_right),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(imageViewerControllerProvider).current?.uuid,
        'img-2',
      );
    });

    testWidgets('GivenAPresentFile_WhenItIsOpened_ThenNothingIsReported', (
      tester,
    ) async {
      await open(tester);

      expect(find.text(messages(tester).viewerFileMissing), findsNothing);
    });
  });

  // AF-02: the image cannot be decoded.
  group('an image that will not decode', () {
    testWidgets('GivenADecodeFailure_WhenItIsReported_ThenTheOwnerIsTold', (
      tester,
    ) async {
      final container = await open(tester);

      // The decoder is Flutter's, so the failure is raised the way the widget
      // raises it.
      container
          .read(imageViewerControllerProvider.notifier)
          .reportUndecodable();
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).viewerUnreadable), findsOneWidget);
    });

    // The one answer a viewer with a listing behind it can offer.
    testWidgets('GivenADecodeFailure_WhenItIsReported_ThenTheNextIsOffered', (
      tester,
    ) async {
      final container = await open(tester);

      container
          .read(imageViewerControllerProvider.notifier)
          .reportUndecodable();
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, messages(tester).imageNext),
        findsOneWidget,
      );
    });

    testWidgets('GivenTheOffer_WhenItIsTaken_ThenTheNextImageIsShown', (
      tester,
    ) async {
      final container = await open(tester);

      container
          .read(imageViewerControllerProvider.notifier)
          .reportUndecodable();
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, messages(tester).imageNext),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(imageViewerControllerProvider).current?.uuid,
        'img-2',
      );
    });
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenTheViewerOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await open(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(ImageViewerScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenTheViewerOpens_ThenNoStringRendersAsItsKey',
        (tester) async {
          await open(tester, locale: locale, missing: {first.path});

          expect(
            find.textContaining(RegExp('image[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
