import 'package:alexandria_desktop/core/bindings/alexandria_bindings.dart';
import 'package:alexandria_desktop/core/di/providers.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';
import 'package:alexandria_desktop/core/failures/failure.dart';
import 'package:alexandria_desktop/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_desktop/features/auth/application/session_state.dart';
import 'package:alexandria_desktop/features/catalog/domain/catalog_gateway.dart';
import 'package:alexandria_desktop/features/catalog/domain/library_type.dart';
import 'package:alexandria_desktop/features/organization/domain/bookmark.dart';
import 'package:alexandria_desktop/features/organization/domain/collection.dart';
import 'package:alexandria_desktop/features/organization/domain/collection_gateway.dart';
import 'package:alexandria_desktop/features/organization/presentation/collections_screen.dart';
import 'package:alexandria_desktop/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../support/fake_bookmarks.dart';
import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_collection_gateway.dart';
import '../../../support/shell_harness.dart';

/// Organizing items into collections (UC-27, FR-OG-04 … FR-OG-07).
void main() {
  const films = Collection(
    uuid: 'c-1',
    name: 'Films',
    kind: CollectionKind.file,
  );

  const reading = Collection(
    uuid: 'c-2',
    name: 'Reading',
    kind: CollectionKind.bookmark,
  );

  const fileUuid = '6a1f8c30-5b2e-4d71-9f03-1c2b3a4d5e6f';

  /// Signs in, opens the collections screen, and opens [collection].
  Future<({ProviderContainer container, FakeCollectionGateway gateway})>
  openCollection(
    WidgetTester tester, {
    Collection collection = films,
    List<CollectionMember> membership = const [],
    List<CollectionWrite> writeOutcomes = const [],
    CollectionMembers? membersOutcome,
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final gateway = FakeCollectionGateway(collections: [collection])
      ..membersOutcome = membersOutcome
      ..writeOutcomes.addAll(writeOutcomes);
    gateway.membership[collection.uuid] = [...membership];

    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      surfaceSize: const Size(1440, 1000),
      extraOverrides: <Override>[
        collectionGatewayProvider.overrideWithValue(gateway),
        catalogGatewayProvider.overrideWithValue(
          FakeCatalogGateway(
            listings: {
              LibraryType.audio: CatalogListing.loaded(files: [aFile()]),
            },
          ),
        ),
        bookmarkGatewayProvider.overrideWithValue(
          FakeBookmarkGateway(
            bookmarks: const [
              Bookmark(
                uuid: 'bm-1',
                url: 'https://example.org/a',
                title: 'A saved page',
              ),
            ],
          ),
        ),
      ],
    );

    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    await tester.tap(find.text(l10n.collectionsOpen));
    await tester.pumpAndSettle();
    await tester.tap(find.text(collection.name));
    await tester.pumpAndSettle();

    return (container: container, gateway: gateway);
  }

  AppLocalizations messages(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  Finder inScreen(Finder finder) =>
      find.descendant(of: find.byType(CollectionsScreen), matching: finder);

  /// The breadcrumb's root link.
  ///
  /// Targeted through its button rather than by text: the app bar carries the
  /// same word, and both saying "Collections" is the point of a trail.
  Finder breadcrumbRoot(WidgetTester tester) => inScreen(
    find.widgetWithText(TextButton, messages(tester).collectionsTitle),
  );

  /// [finder], but only inside the item picker.
  ///
  /// The dashboard behind the screen lists recent files by the same names, so
  /// an unscoped finder matches twice.
  Finder inPicker(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  /// Opens the picker, chooses [names], and confirms.
  Future<void> addItems(WidgetTester tester, List<String> names) async {
    await tester.tap(find.text(messages(tester).collectionAddItems));
    await tester.pumpAndSettle();

    for (final name in names) {
      await tester.tap(inPicker(find.text(name)));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text(messages(tester).collectionAddChosen));
    await tester.pumpAndSettle();
  }

  group('the main flow', () {
    // Steps 1 and 2, with the breadcrumbs FR-OG-07 asks for.
    testWidgets(
      'GivenACollection_WhenItIsOpened_ThenTheTrailShowsWhereYouAre',
      (tester) async {
        await openCollection(tester);

        expect(breadcrumbRoot(tester), findsOneWidget);
        expect(inScreen(find.text('Films')), findsOneWidget);
      },
    );

    testWidgets('GivenTheTrail_WhenTheRootIsTapped_ThenTheListReturns', (
      tester,
    ) async {
      await openCollection(tester);

      await tester.tap(breadcrumbRoot(tester));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).collectionAddItems), findsNothing);
      expect(find.text(messages(tester).collectionCreate), findsOneWidget);
    });

    testWidgets('GivenMembers_WhenTheCollectionOpens_ThenTheyAreListed', (
      tester,
    ) async {
      await openCollection(
        tester,
        membership: const [CollectionMember(uuid: 'f-1', name: 'Solaris.epub')],
      );

      expect(inScreen(find.text('Solaris.epub')), findsOneWidget);
    });

    testWidgets('GivenNoMembers_WhenTheCollectionOpens_ThenItSaysSo', (
      tester,
    ) async {
      await openCollection(tester);

      expect(find.text(messages(tester).collectionEmpty), findsOneWidget);
    });

    // Steps 3 and 4.
    testWidgets('GivenAnItemIsChosen_WhenAddIsAsked_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openCollection(tester);

      await addItems(tester, ['Kind of Blue.flac']);

      // One call carrying the batch, not one call per item: the core links
      // what it can and reports each, so there is nothing left to recover by
      // splitting the request up.
      //
      // Compared field by field: a record holding a List compares that field
      // by identity, so two equal-but-distinct batches would never match.
      expect(opened.gateway.added, hasLength(1));
      expect(opened.gateway.added.single.uuid, 'c-1');
      expect(opened.gateway.added.single.itemUuids, [fileUuid]);
    });

    testWidgets('GivenAnItemWasAdded_WhenItSettles_ThenTheReportNamesIt', (
      tester,
    ) async {
      await openCollection(tester);

      await addItems(tester, ['Kind of Blue.flac']);

      expect(
        find.text(messages(tester).collectionItemsAdded('Kind of Blue.flac')),
        findsOneWidget,
      );
    });

    // Steps 5 and 6.
    testWidgets('GivenAMember_WhenItIsRemoved_ThenTheCoreIsCalled', (
      tester,
    ) async {
      final opened = await openCollection(
        tester,
        membership: const [CollectionMember(uuid: 'f-1', name: 'Solaris.epub')],
      );

      await tester.tap(inScreen(find.byIcon(Icons.remove_circle_outline)));
      await tester.pumpAndSettle();

      expect(opened.gateway.removed, [(uuid: 'c-1', itemUuid: 'f-1')]);
      expect(inScreen(find.text('Solaris.epub')), findsNothing);
    });
  });

  // AF-01: a collection accepts one kind, and nothing else is offered.
  group('items of the wrong kind', () {
    testWidgets('GivenAFileCollection_WhenAddingIsOffered_ThenFilesAreListed', (
      tester,
    ) async {
      await openCollection(tester);

      await tester.tap(find.text(messages(tester).collectionAddItems));
      await tester.pumpAndSettle();

      expect(inPicker(find.text('Kind of Blue.flac')), findsOneWidget);
      expect(inPicker(find.text('A saved page')), findsNothing);
    });

    testWidgets(
      'GivenABookmarkCollection_WhenAddingIsOffered_ThenBookmarksAreListed',
      (tester) async {
        await openCollection(tester, collection: reading);

        await tester.tap(find.text(messages(tester).collectionAddItems));
        await tester.pumpAndSettle();

        expect(inPicker(find.text('A saved page')), findsOneWidget);
        expect(inPicker(find.text('Kind of Blue.flac')), findsNothing);
      },
    );
  });

  // AF-02: already a member, and the core is not asked.
  group('an item already in the collection', () {
    testWidgets('GivenItIsAlreadyThere_WhenAddedAgain_ThenNothingIsSent', (
      tester,
    ) async {
      final opened = await openCollection(
        tester,
        membership: const [
          CollectionMember(uuid: fileUuid, name: 'Kind of Blue.flac'),
        ],
      );

      await addItems(tester, ['Kind of Blue.flac']);

      expect(opened.gateway.added, isEmpty);
      expect(
        find.text(
          messages(tester).collectionItemsAlreadyPresent('Kind of Blue.flac'),
        ),
        findsOneWidget,
      );
    });
  });

  // AF-03: the core reports the collection or the item as not found.
  group('a collection the core no longer has', () {
    testWidgets('GivenItIsGone_WhenAnItemIsRemoved_ThenTheOwnerIsTold', (
      tester,
    ) async {
      await openCollection(
        tester,
        membership: const [CollectionMember(uuid: 'f-1', name: 'Solaris.epub')],
        writeOutcomes: const [
          CollectionWrite.failed(
            failure: Failure.notFound(
              family: CoreStatusFamily.collection,
              code: COLLECTION_ERR_NOT_FOUND,
            ),
          ),
        ],
      );

      await tester.tap(inScreen(find.byIcon(Icons.remove_circle_outline)));
      await tester.pumpAndSettle();

      expect(find.text(messages(tester).collectionNotFound), findsOneWidget);
    });
  });

  // AF-04: exactly which succeeded and which did not.
  group('an addition the core partly refuses', () {
    testWidgets('GivenAWrongKindItem_WhenItAnswers_ThenTheReportSaysWhich', (
      tester,
    ) async {
      final opened = await openCollection(tester);
      opened.gateway.rejections[fileUuid] = ItemRejection.wrongKind;

      await addItems(tester, ['Kind of Blue.flac']);

      expect(
        find.text(
          messages(tester).collectionItemNotAdded(
            'Kind of Blue.flac',
            messages(tester).collectionItemWrongKind,
          ),
        ),
        findsOneWidget,
      );
    });

    // AF-04's other reason, told apart from the one above — which is the whole
    // point of the core reporting per item rather than per request.
    testWidgets('GivenAnItemThatIsGone_WhenItAnswers_ThenTheReasonDiffers', (
      tester,
    ) async {
      final opened = await openCollection(tester);
      opened.gateway.rejections[fileUuid] = ItemRejection.notFound;

      await addItems(tester, ['Kind of Blue.flac']);

      expect(
        find.text(
          messages(tester).collectionItemNotAdded(
            'Kind of Blue.flac',
            messages(tester).collectionItemGone,
          ),
        ),
        findsOneWidget,
      );
    });
  });

  // AF-05: the core rejects the call as unauthorized.
  group('a session the core rejects', () {
    testWidgets(
      'GivenTheCoreRejectsTheSession_WhenAnItemIsAdded_ThenTheOwnerSignsOut',
      (tester) async {
        final opened = await openCollection(tester);
        // The refusal is the request's, not an item's: an unauthorized call
        // never gets far enough to report on anything.
        opened.gateway.additionsOutcome = const CollectionAdditions.failed(
          failure: Failure.unauthorized(
            family: CoreStatusFamily.collection,
            code: COLLECTION_ERR_UNAUTHORIZED,
          ),
        );

        await addItems(tester, ['Kind of Blue.flac']);

        expect(
          opened.container.read(sessionControllerProvider),
          isA<SessionAbsent>(),
        );
      },
    );
  });

  group('themes and languages', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'GivenThe${themeMode == ThemeMode.light ? 'Light' : 'Dark'}Theme_WhenACollectionOpens_ThenItRendersInThatBrightness',
        (tester) async {
          await openCollection(tester, themeMode: themeMode);

          expect(
            Theme.of(tester.element(find.byType(CollectionsScreen))).brightness,
            themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
          );
        },
      );
    }

    for (final locale in [const Locale('en'), const Locale('pt', 'BR')]) {
      testWidgets(
        'Given${locale.languageCode == 'en' ? 'English' : 'Portuguese'}_WhenAnItemIsAdded_ThenNoStringRendersAsItsKey',
        (tester) async {
          await openCollection(tester, locale: locale);

          await addItems(tester, ['Kind of Blue.flac']);

          expect(
            find.textContaining(RegExp('collection[A-Z]'), findRichText: true),
            findsNothing,
          );
        },
      );
    }
  });
}
