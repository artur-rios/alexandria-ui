# Music Browsing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the music area its own presentation — artists, albums, and songs drilled into with a breadcrumb, every row named from its metadata and never from a file name, with each file's actions on a context menu.

**Architecture:** The groupings are pure functions over the in-memory music library, in the playback feature's domain layer. `MusicLibraryController` becomes an incremental loader that publishes entries as its per-file metadata calls land. A new `MusicBrowseController` holds which view is selected and how far the owner has drilled in, and `MusicLibraryView` renders one list at a time from those two. No core gateway changes: every value shown is already on the records the core returns.

**Tech Stack:** Flutter 3.47.1, Material 3, Riverpod (`AsyncNotifier`, `Notifier`, `FutureProvider.family`), `freezed`, `gen_l10n`.

## Global Constraints

- **Design document:** `docs/superpowers/specs/2026-08-25-music-browsing-design.md`. It is the authority; this plan implements it.
- **Never a file name.** No view in the music area, and no audio row in the search results, may render `CatalogFile.name`. The one place the file name appears is the details dialog, under a label saying that is what it is.
- **Test naming:** every test is one identifier in Given-When-Then form — `GivenSomeCondition_WhenSomeAction_ThenSomeOutcome` (Testing Specification §5). A test that cannot fail for the reason its name claims is a defect, not coverage.
- **Test location:** the test tree mirrors `lib/` exactly, with `_test` appended (Testing Specification §4).
- **Localization:** every user-visible string comes from `AppLocalizations`. A new string goes into **both** `lib/core/l10n/app_en.arb` (with an `@key` description block — `required-resource-attributes: true` makes an undescribed message a generation failure) and `lib/core/l10n/app_pt.arb` (no description blocks). `test/core/l10n/arb_parity_test.dart` fails on any key present in one catalog and absent from the other. Regenerate with `flutter gen-l10n`; generated files under `lib/core/l10n/generated/` are committed.
- **`@key` descriptions are doc comments for strings.** A change that moves or repurposes a string must leave its description true.
- **No colour literals** anywhere under `lib/` outside `lib/core/theme/` (BR-18, enforced by `test/core/theme/no_color_literal_test.dart`). `Colors.transparent` counts as one.
- **Doc comments explain WHY**, not what. Match the surrounding density: this codebase's comments carry the reasoning behind a choice, and a change must leave every comment it touches true.
- **BR-02:** the core owns domain decisions. This work adds no core call and invents no classification.
- **`SubmenuButton`/`MenuAnchor`:** write `menuChildren:` before `child:` (`sort_child_properties_last`).
- **Verification:** run `flutter analyze` and `flutter test` and read the output. Never claim done on an unrun test.
- **Commits:** conventional commit subject in lowercase, ≤50 characters, imperative; body wrapped at 72. End every commit message with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/features/playback/domain/music_grouping.dart` | Existing. Gains `MusicEntry.title`; keeps the queue-building `albumOf`/`artistOf` untouched. |
| `lib/features/playback/domain/music_browse.dart` | **New.** The browsing groupings: artists, albums, an artist's albums, an album's tracks, and every song — pure functions over `List<MusicEntry>`, with untagged groups ordered last. |
| `lib/features/playback/application/music_library_controller.dart` | Existing. Becomes an incremental loader publishing `MusicLibrary` (entries so far + progress). |
| `lib/features/playback/application/music_browse_controller.dart` | **New.** Which view is selected, and the drill path. |
| `lib/features/playback/presentation/music_library_view.dart` | **New.** The segmented control, the breadcrumb, the progress line, and which list is drawn. |
| `lib/features/playback/presentation/music_rows.dart` | **New.** The artist, album, and track rows, and the per-file context menu. |
| `lib/features/shell/presentation/shell_screen.dart` | Modified. Routes the music destination to `MusicLibraryView`. |
| `lib/features/catalog/presentation/file_details_view.dart` | Modified. Gains the file-facts section. |
| `lib/features/catalog/domain/file_size.dart` | **New.** Formats a byte count for display. |
| `lib/features/catalog/presentation/catalog_search_view.dart` | Modified. An audio result shows its metadata title. |
| `lib/core/di/providers.dart` | Modified. Binds the browse controller and the per-file audio-name provider. |

---

### Task 1: The browsing groupings

**Files:**
- Create: `lib/features/playback/domain/music_browse.dart`
- Modify: `lib/features/playback/domain/music_grouping.dart`
- Test: `test/features/playback/domain/music_browse_test.dart`

**Interfaces:**
- Consumes: `MusicEntry` (with `file`, `metadata`, `album`, `artist`), `CatalogFile`, `MusicMetadata`.
- Produces:
  - `String? get MusicEntry.title` — the trimmed title tag, `null` when it names none.
  - `class MusicGroup { final String? name; final List<MusicEntry> entries; }` — `name` is `null` for the untagged group.
  - `List<MusicGroup> artistsIn(List<MusicEntry> library)`
  - `List<MusicGroup> albumsIn(List<MusicEntry> library)`
  - `List<MusicGroup> albumsOfArtist(String? artist, List<MusicEntry> library)`
  - `List<MusicEntry> tracksOfAlbum(String? album, String? artist, List<MusicEntry> library)`
  - `List<MusicEntry> songsIn(List<MusicEntry> library)`

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/domain/music_browse_test.dart`:

```dart
import 'package:alexandria_ui/features/catalog/domain/catalog_file.dart';
import 'package:alexandria_ui/features/catalog/domain/library_type.dart';
import 'package:alexandria_ui/features/catalog/domain/music_metadata.dart';
import 'package:alexandria_ui/features/playback/domain/music_browse.dart';
import 'package:alexandria_ui/features/playback/domain/music_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

/// The groupings the music area browses by (UC-46, FR-CT-13).
void main() {
  /// An entry whose file name is deliberately unlike its title: a grouping
  /// that fell back to the file name would be visible in the assertions.
  MusicEntry entry({
    required String uuid,
    String? title,
    String? artist,
    String? album,
    int? track,
  }) => MusicEntry(
    file: CatalogFile(
      uuid: uuid,
      name: 'zzz-$uuid.flac',
      path: 'C:/library/zzz-$uuid.flac',
      type: LibraryType.audio,
    ),
    metadata: MusicMetadata(
      title: title,
      artist: artist,
      album: album,
      track: track,
    ),
  );

  final tagged = [
    entry(uuid: '1', title: 'Airbag', artist: 'Radiohead', album: 'OK', track: 1),
    entry(uuid: '2', title: 'Karma', artist: 'Radiohead', album: 'OK', track: 2),
    entry(uuid: '3', title: 'Roads', artist: 'Portishead', album: 'Dummy', track: 1),
  ];

  group('artists', () {
    test(
      'GivenATaggedLibrary_WhenArtistsAreListed_ThenEachAppearsOnceAlphabetically',
      () {
        final artists = artistsIn(tagged);

        expect([for (final group in artists) group.name], [
          'Portishead',
          'Radiohead',
        ]);
      },
    );

    test('GivenAnArtist_WhenItIsListed_ThenItCarriesItsOwnTracks', () {
      final artists = artistsIn(tagged);

      expect(artists.first.entries.map((e) => e.title), ['Roads']);
    });

    test(
      'GivenAFileWithNoArtist_WhenArtistsAreListed_ThenItGroupsUnderNoNameLast',
      () {
        // The untagged files are the ones that need tagging: gathered, and out
        // of the way of a library that is mostly tagged.
        final artists = artistsIn([...tagged, entry(uuid: '4', title: 'Loose')]);

        expect(artists.last.name, isNull);
        expect(artists.last.entries.single.file.uuid, '4');
      },
    );

    test('GivenMixedCaseArtists_WhenTheyAreListed_ThenTheOrderIgnoresCase', () {
      // A library sorted with every capital first is not sorted the way
      // anyone reads.
      final artists = artistsIn([
        entry(uuid: '5', artist: 'aphex twin'),
        entry(uuid: '6', artist: 'Boards of Canada'),
      ]);

      expect([for (final group in artists) group.name], [
        'aphex twin',
        'Boards of Canada',
      ]);
    });
  });

  group('albums', () {
    test('GivenALibrary_WhenAlbumsAreListed_ThenEachAppearsOnce', () {
      expect([for (final group in albumsIn(tagged)) group.name], ['Dummy', 'OK']);
    });

    test(
      'GivenTwoArtistsSharingAnAlbumName_WhenAlbumsAreListed_ThenTheyStayApart',
      () {
        // Two different artists can name a record the same thing, and merging
        // them would put one artist's tracks inside another's album.
        final albums = albumsIn([
          entry(uuid: '7', artist: 'A', album: 'Home'),
          entry(uuid: '8', artist: 'B', album: 'Home'),
        ]);

        expect(albums.length, 2);
      },
    );

    test('GivenAnArtist_WhenTheirAlbumsAreListed_ThenOnlyTheirsAreReturned', () {
      final albums = albumsOfArtist('Radiohead', tagged);

      expect([for (final group in albums) group.name], ['OK']);
    });
  });

  group('tracks', () {
    test('GivenAnAlbum_WhenItsTracksAreListed_ThenTheyComeInTrackOrder', () {
      final tracks = tracksOfAlbum('OK', 'Radiohead', [
        entry(uuid: '9', title: 'Karma', artist: 'Radiohead', album: 'OK', track: 2),
        entry(uuid: '10', title: 'Airbag', artist: 'Radiohead', album: 'OK', track: 1),
      ]);

      expect(tracks.map((e) => e.title), ['Airbag', 'Karma']);
    });

    test(
      'GivenTracksWithNoNumber_WhenTheAlbumIsListed_ThenNumberedOnesComeFirst',
      () {
        final tracks = tracksOfAlbum('OK', 'Radiohead', [
          entry(uuid: '11', title: 'Bonus', artist: 'Radiohead', album: 'OK'),
          entry(uuid: '12', title: 'Airbag', artist: 'Radiohead', album: 'OK', track: 1),
        ]);

        expect(tracks.map((e) => e.title), ['Airbag', 'Bonus']);
      },
    );

    test('GivenALibrary_WhenSongsAreListed_ThenTheyAreAlphabeticalByTitle', () {
      expect(songsIn(tagged).map((e) => e.title), ['Airbag', 'Karma', 'Roads']);
    });

    test(
      'GivenAFileWithNoTitle_WhenSongsAreListed_ThenItSortsAfterTheTitledOnes',
      () {
        final songs = songsIn([...tagged, entry(uuid: '13')]);

        expect(songs.last.file.uuid, '13');
      },
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/playback/domain/music_browse_test.dart`
Expected: FAIL — `music_browse.dart` does not exist and `MusicEntry.title` is undefined, so the file does not compile.

- [ ] **Step 3: Add the title getter**

In `lib/features/playback/domain/music_grouping.dart`, beside the existing `album` and `artist` getters:

```dart
  /// The track's title, or `null` when it names none.
  ///
  /// What a row shows. A file whose tags carry no title has no name in this
  /// application's terms — its name on disk is not one (FR-CT-13).
  String? get title => _trimmed(metadata.title);
```

- [ ] **Step 4: Write the groupings**

Create `lib/features/playback/domain/music_browse.dart`:

```dart
import 'music_grouping.dart';

/// One artist, or one album, and the tracks under it (UC-46, FR-CT-13).
///
/// [name] is `null` for the group of files whose tags name none. A null name
/// rather than a translated "Unknown artist" string, because this is the
/// domain: what the catalog knows is that the tag is absent, and what to call
/// that is the presentation's decision and the translator's.
class MusicGroup {
  /// Creates a group.
  const MusicGroup({required this.name, required this.entries});

  /// What the group is called, or `null` when its files name nothing.
  final String? name;

  /// The tracks in it.
  final List<MusicEntry> entries;

  /// Whether this is the group of files that carry no tag.
  bool get isUntagged => name == null;
}

/// Every artist in [library], alphabetically, with the untagged files last.
List<MusicGroup> artistsIn(List<MusicEntry> library) =>
    _groupedBy(library, (entry) => entry.artist);

/// Every album in [library], alphabetically, with the untagged files last.
///
/// Keyed by album *and* artist: two different artists can name a record the
/// same thing, and merging them would show one artist's tracks inside
/// another's album — the same rule `albumOf` applies when it builds a queue.
List<MusicGroup> albumsIn(List<MusicEntry> library) {
  final byKey = <(String?, String?), List<MusicEntry>>{};
  for (final entry in library) {
    byKey.putIfAbsent((entry.album, entry.artist), () => []).add(entry);
  }

  final groups = [
    for (final key in byKey.keys)
      MusicGroup(name: key.$1, entries: _inTrackOrder(byKey[key]!)),
  ];

  return _sortedByName(groups);
}

/// [artist]'s albums, alphabetically.
///
/// `null` selects the files that name no artist, which is what drilling into
/// the untagged group does.
List<MusicGroup> albumsOfArtist(String? artist, List<MusicEntry> library) =>
    albumsIn([
      for (final entry in library)
        if (entry.artist == artist) entry,
    ]);

/// The tracks of [artist]'s [album], in track order.
List<MusicEntry> tracksOfAlbum(
  String? album,
  String? artist,
  List<MusicEntry> library,
) => _inTrackOrder([
  for (final entry in library)
    if (entry.album == album && entry.artist == artist) entry,
]);

/// Every track in [library], by title, with the untitled ones last.
List<MusicEntry> songsIn(List<MusicEntry> library) {
  final sorted = [...library]
    ..sort((a, b) => _byName(a.title, b.title));

  return sorted;
}

List<MusicGroup> _groupedBy(
  List<MusicEntry> library,
  String? Function(MusicEntry entry) key,
) {
  final byName = <String?, List<MusicEntry>>{};
  for (final entry in library) {
    byName.putIfAbsent(key(entry), () => []).add(entry);
  }

  return _sortedByName([
    for (final name in byName.keys)
      MusicGroup(name: name, entries: _inTrackOrder(byName[name]!)),
  ]);
}

List<MusicGroup> _sortedByName(List<MusicGroup> groups) =>
    [...groups]..sort((a, b) => _byName(a.name, b.name));

/// Case-insensitively by name, with an absent name last.
///
/// Absent last rather than first: the untagged files are a chore to work
/// through, not the first thing an owner came to see.
int _byName(String? left, String? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;

  return left.toLowerCase().compareTo(right.toLowerCase());
}

/// Track number first, then title — the order a record is listened to.
///
/// A track with no number sorts after the numbered ones rather than at the
/// front, which is where a missing number would otherwise put it.
List<MusicEntry> _inTrackOrder(List<MusicEntry> entries) =>
    [...entries]..sort((a, b) {
      final left = a.metadata.track;
      final right = b.metadata.track;

      if (left != null && right != null && left != right) {
        return left.compareTo(right);
      }
      if (left != null && right == null) return -1;
      if (left == null && right != null) return 1;

      return _byName(a.title, b.title);
    });
```

- [ ] **Step 5: Run the tests**

Run: `flutter test test/features/playback/domain/music_browse_test.dart`
Expected: PASS, all eleven.

- [ ] **Step 6: Run the whole suite and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!". Nothing else consumes these functions yet, so nothing else may change.

- [ ] **Step 7: Commit**

```bash
git add lib/features/playback/domain test/features/playback/domain
git commit -m "feat: group the music library for browsing"
```

---

### Task 2: The incremental library

**Files:**
- Modify: `lib/features/playback/application/music_library_controller.dart`
- Modify: `lib/features/playback/application/audio_playback_controller.dart` (its one read of the library)
- Modify: `lib/core/di/providers.dart` (the provider's type argument)
- Test: `test/features/playback/application/music_library_controller_test.dart`

**Interfaces:**
- Consumes: `catalogGatewayProvider`, `sessionControllerProvider`, `CatalogListingLoaded`/`CatalogListingFailed`, `FileDetailsRead`/`FileDetailsFailed`, `MusicEntry`.
- Produces:
  - `class MusicLibrary { final List<MusicEntry> entries; final int total; bool get isComplete; }` — `total` is how many audio files the listing returned; `isComplete` is `entries.length >= total`.
  - `musicLibraryProvider` becomes `AsyncNotifierProvider<MusicLibraryController, MusicLibrary>`.

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/application/music_library_controller_test.dart`:

```dart
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/music_library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/test_container.dart';

/// Reading the library's metadata (UC-46 main flow step 1).
///
/// The core answers file records with no metadata and publishes no listing
/// that carries it, so the album a track belongs to is only knowable by
/// reading each file. These tests are about what the area can show while that
/// is still happening.
void main() {
  test(
    'GivenAudioFiles_WhenTheLibraryLoads_ThenItReportsHowManyAreExpected',
    () async {
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead');
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.total, 2);
      expect(library.entries.length, 2);
      expect(library.isComplete, isTrue);
    },
  );

  test(
    'GivenMetadataStillArriving_WhenTheLibraryIsRead_ThenTheEntriesSoFarAreShown',
    () async {
      // The point of loading incrementally: the area shows artists while the
      // rest of the calls are still running, rather than sitting blank.
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..addAudio(uuid: '2', title: 'Karma', artist: 'Radiohead')
        ..holdDetailsAfter(1);
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries.length, 1);
      expect(library.total, 2);
      expect(library.isComplete, isFalse);
    },
  );

  test(
    'GivenAFileWhoseDetailsFail_WhenTheLibraryLoads_ThenItJoinsWithNoMetadata',
    () async {
      // A file the catalog cannot describe is still a file the owner has.
      // It lands in the untagged group rather than vanishing.
      final gateway = FakeCatalogGateway()
        ..addAudio(uuid: '1', title: 'Airbag', artist: 'Radiohead')
        ..failDetailsFor('1');
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries.single.artist, isNull);
      expect(library.isComplete, isTrue);
    },
  );

  test(
    'GivenAListingThatFails_WhenTheLibraryLoads_ThenItIsEmptyAndComplete',
    () async {
      final gateway = FakeCatalogGateway()..failListing();
      final container = testContainer(gateway: gateway);

      final library = await container.read(musicLibraryProvider.future);

      expect(library.entries, isEmpty);
      expect(library.total, 0);
      expect(library.isComplete, isTrue);
    },
  );
}
```

Read `test/support/fake_catalog_gateway.dart` and `test/support/test_container.dart` first: use whatever helpers they already offer for adding files, failing a listing, and failing a details read, and name the new ones (`addAudio`, `holdDetailsAfter`, `failDetailsFor`) to match that file's existing conventions rather than these exact names if it already has equivalents. Add only the helpers that are missing.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/playback/application/music_library_controller_test.dart`
Expected: FAIL — `MusicLibrary` does not exist and `musicLibraryProvider` still resolves to `List<MusicEntry>`.

- [ ] **Step 3: Write the incremental controller**

Replace the body of `lib/features/playback/application/music_library_controller.dart`:

```dart
/// The library as far as it has been read (UC-46 main flow step 1).
///
/// Entries and a total rather than a bare list, because the area draws itself
/// from a partial answer: what it has, and how much is still coming.
class MusicLibrary {
  /// Creates a library.
  const MusicLibrary({required this.entries, required this.total});

  /// Nothing read yet.
  static const MusicLibrary empty = MusicLibrary(entries: [], total: 0);

  /// The tracks whose metadata has arrived.
  final List<MusicEntry> entries;

  /// How many audio files the listing found.
  final int total;

  /// Whether every file's metadata has been read.
  bool get isComplete => entries.length >= total;
}

/// Every audio file with its metadata (UC-20 main flow step 3, UC-46,
/// FR-PL-06, FR-CT-13).
///
/// The core's listing answers `File` records and no metadata, and it publishes
/// no "files by album" query — so the album a track belongs to is only
/// knowable by reading each file. This does exactly that, once, and holds the
/// result for the run.
///
/// It publishes the entries as they arrive rather than one all-or-nothing
/// future: browsing needs this data to draw its first screen, and a library of
/// a few thousand tracks is a few thousand sequential calls. An area that
/// fills in is the difference between a wait and a hang. The cost itself is
/// the core's shape rather than a choice made here — BR-02 forbids inventing
/// the narrower call this would rather have.
class MusicLibraryController extends AsyncNotifier<MusicLibrary> {
  @override
  Future<MusicLibrary> build() async {
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return MusicLibrary.empty;

    final gateway = ref.read(catalogGatewayProvider);
    final listing = await gateway.listFiles(
      type: LibraryType.audio,
      credential: credential,
    );

    final List<CatalogFile> files = switch (listing) {
      CatalogListingLoaded(:final files) => files,
      // A listing that failed groups nothing. The player reports the failure
      // it gets from playing, and the queue is a single track.
      CatalogListingFailed() => const [],
    };

    final entries = <MusicEntry>[];
    for (final file in files) {
      final details = await gateway.fileDetails(
        uuid: file.uuid,
        credential: credential,
      );

      // A file whose details will not come back is still a file that can be
      // played: it joins the library with no album and no artist, which makes
      // it an album of one rather than absent from its own queue, and puts it
      // in the untagged group where browsing can find it.
      entries.add(
        MusicEntry(
          file: file,
          metadata: switch (details) {
            FileDetailsRead(:final details) => MusicMetadata.fromDetails(
              details.metadata,
            ),
            FileDetailsFailed() => const MusicMetadata(),
          },
        ),
      );

      // Published per file rather than at the end: this is what lets the area
      // show the artists it already knows while the rest are still being read.
      state = AsyncData(
        MusicLibrary(entries: [...entries], total: files.length),
      );
    }

    return MusicLibrary(entries: entries, total: files.length);
  }
}
```

- [ ] **Step 4: Retype the provider and its one other reader**

In `lib/core/di/providers.dart`, change the provider's type argument:

```dart
final musicLibraryProvider =
    AsyncNotifierProvider<MusicLibraryController, MusicLibrary>(
      MusicLibraryController.new,
    );
```

In `lib/features/playback/application/audio_playback_controller.dart` around line 225, the read becomes `.entries`:

```dart
    final library = (await ref.read(musicLibraryProvider.future)).entries;
```

- [ ] **Step 5: Run the tests**

Run: `flutter test test/features/playback test/features/catalog`
Expected: PASS. A failure in the audio playback tests means step 4's read was missed somewhere — search for `musicLibraryProvider` and fix every reader.

- [ ] **Step 6: Run the whole suite and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: read the music library incrementally"
```

---

### Task 3: The browse controller

**Files:**
- Create: `lib/features/playback/application/music_browse_controller.dart`
- Modify: `lib/core/di/providers.dart`
- Test: `test/features/playback/application/music_browse_controller_test.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `enum MusicView { artists, albums, songs }`
  - `class MusicBrowseState { final MusicView view; final String? artist; final String? album; final bool inArtist; final bool inAlbum; }` — `inArtist`/`inAlbum` say whether the owner has drilled in, because `null` is a legitimate artist (the untagged group) and cannot double as "no selection".
  - `class MusicBrowseController extends Notifier<MusicBrowseState>` with `void show(MusicView view)`, `void openArtist(String? artist)`, `void openAlbum(String? album, String? artist)`, `void upToArtists()`, `void upToArtist()`.
  - `musicBrowseControllerProvider`.

- [ ] **Step 1: Write the failing test**

Create `test/features/playback/application/music_browse_controller_test.dart`:

```dart
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/playback/application/music_browse_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_container.dart';

/// Where the owner is in the music area (UC-46 main flow steps 2 and 3).
void main() {
  test('GivenAFreshArea_WhenItOpens_ThenItShowsArtistsAtTheTop', () {
    final container = testContainer();

    final state = container.read(musicBrowseControllerProvider);

    expect(state.view, MusicView.artists);
    expect(state.inArtist, isFalse);
  });

  test('GivenTheArtistsView_WhenAnArtistIsOpened_ThenTheirAlbumsAreShown', () {
    final container = testContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist('Radiohead');

    final state = container.read(musicBrowseControllerProvider);
    expect(state.inArtist, isTrue);
    expect(state.artist, 'Radiohead');
    expect(state.inAlbum, isFalse);
  });

  test('GivenTheUntaggedGroup_WhenItIsOpened_ThenItIsADrillNotADeselection', () {
    // A null artist is a real group — the files that name none — so it cannot
    // double as "nothing selected".
    final container = testContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist(null);

    final state = container.read(musicBrowseControllerProvider);
    expect(state.inArtist, isTrue);
    expect(state.artist, isNull);
  });

  test('GivenAnAlbumIsOpen_WhenTheOwnerGoesUp_ThenTheArtistRemains', () {
    final container = testContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist('Radiohead');
    controller.openAlbum('OK', 'Radiohead');
    controller.upToArtist();

    final state = container.read(musicBrowseControllerProvider);
    expect(state.inAlbum, isFalse);
    expect(state.artist, 'Radiohead');
  });

  test('GivenADrilledInOwner_WhenTheViewChanges_ThenTheDrillIsForgotten', () {
    // Switching to Albums from inside an artist's record should land on the
    // albums list, not inside whatever was open in the other view.
    final container = testContainer();
    final controller = container.read(musicBrowseControllerProvider.notifier);

    controller.openArtist('Radiohead');
    controller.openAlbum('OK', 'Radiohead');
    controller.show(MusicView.albums);

    final state = container.read(musicBrowseControllerProvider);
    expect(state.view, MusicView.albums);
    expect(state.inArtist, isFalse);
    expect(state.inAlbum, isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/playback/application/music_browse_controller_test.dart`
Expected: FAIL — the controller does not exist.

- [ ] **Step 3: Write the controller**

Create `lib/features/playback/application/music_browse_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the music area's three views is shown (UC-46 main flow step 2).
enum MusicView {
  /// Every artist, drilled into for their albums.
  artists,

  /// Every album, drilled into for its tracks.
  albums,

  /// Every track in the library.
  songs,
}

/// Where in the music area the owner is (UC-46 main flow steps 2 and 3).
///
/// [inArtist] and [inAlbum] say whether a drill has happened, rather than
/// letting a null [artist] mean it has not: the files that name no artist are
/// a real group an owner can open, and a state that could not tell that group
/// from "nothing selected" would make it unreachable.
class MusicBrowseState {
  /// Creates a state.
  const MusicBrowseState({
    this.view = MusicView.artists,
    this.artist,
    this.album,
    this.inArtist = false,
    this.inAlbum = false,
  });

  /// The view the segmented control shows.
  final MusicView view;

  /// The artist drilled into, which is `null` for the untagged group.
  final String? artist;

  /// The album drilled into, which is `null` for the untitled group.
  final String? album;

  /// Whether an artist has been opened.
  final bool inArtist;

  /// Whether an album has been opened.
  final bool inAlbum;
}

/// The music area's navigation (UC-46).
class MusicBrowseController extends Notifier<MusicBrowseState> {
  @override
  MusicBrowseState build() => const MusicBrowseState();

  /// Shows [view], from the top.
  ///
  /// The drill is dropped rather than carried across: an owner switching to
  /// Albums asked for the albums list, not for whatever record happened to be
  /// open in the view they left.
  void show(MusicView view) => state = MusicBrowseState(view: view);

  /// Opens [artist]'s albums.
  void openArtist(String? artist) =>
      state = MusicBrowseState(view: state.view, artist: artist, inArtist: true);

  /// Opens [album]'s tracks. [artist] is the album's, which is what tells two
  /// records that share a title apart.
  void openAlbum(String? album, String? artist) => state = MusicBrowseState(
    view: state.view,
    artist: artist,
    album: album,
    inArtist: state.view == MusicView.artists,
    inAlbum: true,
  );

  /// Goes back to the top of the current view.
  void upToArtists() => state = MusicBrowseState(view: state.view);

  /// Goes back to the open artist's albums.
  void upToArtist() => state = MusicBrowseState(
    view: state.view,
    artist: state.artist,
    inArtist: true,
  );
}
```

- [ ] **Step 4: Bind the provider**

In `lib/core/di/providers.dart`, beside `musicLibraryProvider`:

```dart
/// Where the owner is in the music area (UC-46).
final musicBrowseControllerProvider =
    NotifierProvider<MusicBrowseController, MusicBrowseState>(
      MusicBrowseController.new,
    );
```

- [ ] **Step 5: Run the tests, then the suite**

Run: `flutter test test/features/playback/application/music_browse_controller_test.dart`
Expected: PASS.

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: track where the owner is in the music area"
```

---

### Task 4: The music area

**Files:**
- Create: `lib/features/playback/presentation/music_library_view.dart`
- Modify: `lib/features/shell/presentation/shell_screen.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/playback/presentation/music_library_view_test.dart`

**Interfaces:**
- Consumes: `MusicView`, `MusicBrowseState`, `musicBrowseControllerProvider`, `MusicLibrary`, `musicLibraryProvider`, `artistsIn`, `albumsIn`, `albumsOfArtist`, `tracksOfAlbum`, `songsIn`, `MusicGroup`.
- Produces:
  - `class MusicLibraryView extends ConsumerWidget` — `const MusicLibraryView({super.key})`.
  - The localization keys `musicViewArtists`, `musicViewAlbums`, `musicViewSongs`, `musicBreadcrumbRoot`, `musicUnknownTitle`, `musicUnknownArtist`, `musicUnknownAlbum`, `musicLoading`, `musicEmpty`.
  - `String musicTitleOf(MusicEntry, AppLocalizations)`, `String musicArtistOf(MusicEntry, AppLocalizations)`, `String musicGroupName(MusicGroup, AppLocalizations, {required bool isArtist})` — the one place a null tag becomes a word, exported for Task 7's use in the search results.

Task 5 adds the context menu to the rows; this task's rows carry text and a tap.

- [ ] **Step 1: Add the localization keys**

In `lib/core/l10n/app_en.arb`:

```json
  "musicViewArtists": "Artists",
  "@musicViewArtists": {
    "description": "The music area's artists view, in its view switcher."
  },
  "musicViewAlbums": "Albums",
  "@musicViewAlbums": {
    "description": "The music area's albums view, in its view switcher."
  },
  "musicViewSongs": "Songs",
  "@musicViewSongs": {
    "description": "The music area's songs view, listing every track."
  },
  "musicBreadcrumbRoot": "Music",
  "@musicBreadcrumbRoot": {
    "description": "The first crumb of the music area's breadcrumb, leading back to the top of the current view."
  },
  "musicUnknownTitle": "Unknown title",
  "@musicUnknownTitle": {
    "description": "Shown in place of a track's name when its metadata carries no title. The file's name on disk is never shown here."
  },
  "musicUnknownArtist": "Unknown artist",
  "@musicUnknownArtist": {
    "description": "Names the group of audio files whose metadata carries no artist."
  },
  "musicUnknownAlbum": "Unknown album",
  "@musicUnknownAlbum": {
    "description": "Names the group of audio files whose metadata carries no album."
  },
  "musicLoading": "Reading metadata: {read} of {total}",
  "@musicLoading": {
    "description": "Progress while the music area reads each audio file's metadata, which the core answers one file at a time.",
    "placeholders": {
      "read": { "type": "int" },
      "total": { "type": "int" }
    }
  },
  "musicEmpty": "No audio files are catalogued yet.",
  "@musicEmpty": {
    "description": "The music area with nothing in it."
  },
```

In `lib/core/l10n/app_pt.arb`:

```json
  "musicViewArtists": "Artistas",
  "musicViewAlbums": "Álbuns",
  "musicViewSongs": "Músicas",
  "musicBreadcrumbRoot": "Músicas",
  "musicUnknownTitle": "Título desconhecido",
  "musicUnknownArtist": "Artista desconhecido",
  "musicUnknownAlbum": "Álbum desconhecido",
  "musicLoading": "Lendo metadados: {read} de {total}",
  "musicEmpty": "Nenhum arquivo de áudio catalogado ainda.",
```

Run: `flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

Create `test/features/playback/presentation/music_library_view_test.dart`:

```dart
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/playback/presentation/music_library_view.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/shell_harness.dart';

/// Browsing the music library (UC-46, FR-CT-13).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Signs in, lands on the shell, and opens the music area over [gateway].
  Future<void> openMusic(
    WidgetTester tester, {
    required FakeCatalogGateway gateway,
  }) async {
    final container = await tester.pumpShell(
      extraOverrides: [catalogGatewayProvider.overrideWithValue(gateway)],
    );

    container
        .read(shellControllerProvider.notifier)
        .go(ShellDestination.music);
    await tester.pumpAndSettle();
  }

  /// Two artists, three tracks, and file names that would be unmistakable if
  /// any of them ever reached the screen.
  FakeCatalogGateway libraryOfThree() => FakeCatalogGateway()
    ..addAudio(
      uuid: '1',
      name: 'DISKNAME-01.flac',
      title: 'Airbag',
      artist: 'Radiohead',
      album: 'OK',
      track: 1,
    )
    ..addAudio(
      uuid: '2',
      name: 'DISKNAME-02.flac',
      title: 'Karma',
      artist: 'Radiohead',
      album: 'OK',
      track: 2,
    )
    ..addAudio(
      uuid: '3',
      name: 'DISKNAME-03.flac',
      title: 'Roads',
      artist: 'Portishead',
      album: 'Dummy',
      track: 1,
    );

  group('the views (main flow step 2)', () {
    testWidgets(
      'GivenTheMusicArea_WhenItOpens_ThenItListsTheArtists',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());

        expect(find.text('Radiohead'), findsOneWidget);
        expect(find.text('Portishead'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheMusicArea_WhenItOpens_ThenNoFileNameIsShown',
      (tester) async {
        // FR-CT-13, asserted the only way that means anything: a name that
        // would be unmistakable if the view ever fell back to it.
        await openMusic(tester, gateway: libraryOfThree());

        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );

    testWidgets(
      'GivenTheArtistsView_WhenAlbumsAreChosen_ThenTheAlbumsAreListed',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewAlbums));
        await tester.pumpAndSettle();

        expect(find.textContaining('Dummy'), findsOneWidget);
        expect(find.textContaining('OK'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheArtistsView_WhenSongsAreChosen_ThenEveryTrackIsListed',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewSongs));
        await tester.pumpAndSettle();

        for (final title in ['Airbag', 'Karma', 'Roads']) {
          expect(find.textContaining(title), findsOneWidget, reason: title);
        }
      },
    );
  });

  group('drilling in (main flow step 3)', () {
    testWidgets(
      'GivenTheArtists_WhenOneIsOpened_ThenOnlyTheirAlbumsAreShown',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();

        expect(find.textContaining('OK'), findsOneWidget);
        expect(find.textContaining('Dummy'), findsNothing);
      },
    );

    testWidgets(
      'GivenAnArtistsAlbums_WhenOneIsOpened_ThenItsTracksComeInTrackOrder',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('OK'));
        await tester.pumpAndSettle();

        final airbag = tester.getTopLeft(find.textContaining('Airbag')).dy;
        final karma = tester.getTopLeft(find.textContaining('Karma')).dy;
        expect(airbag, lessThan(karma));
      },
    );

    testWidgets(
      'GivenAnOpenAlbum_WhenTheRootCrumbIsTapped_ThenTheArtistsReturn',
      (tester) async {
        await openMusic(tester, gateway: libraryOfThree());
        final l10n = localizations(tester);

        await tester.tap(find.text('Radiohead'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.musicBreadcrumbRoot));
        await tester.pumpAndSettle();

        expect(find.text('Portishead'), findsOneWidget);
      },
    );
  });

  group('what carries no tags (AF-01)', () {
    testWidgets(
      'GivenAnUntaggedFile_WhenTheArtistsAreListed_ThenItIsUnderUnknownArtistLast',
      (tester) async {
        final gateway = libraryOfThree()
          ..addAudio(uuid: '4', name: 'DISKNAME-04.flac');
        await openMusic(tester, gateway: gateway);
        final l10n = localizations(tester);

        final unknown = tester
            .getTopLeft(find.text(l10n.musicUnknownArtist))
            .dy;
        expect(unknown, greaterThan(tester.getTopLeft(find.text('Radiohead')).dy));
      },
    );

    testWidgets(
      'GivenAnUntitledTrack_WhenTheSongsAreListed_ThenItReadsUnknownTitle',
      (tester) async {
        final gateway = libraryOfThree()
          ..addAudio(uuid: '4', name: 'DISKNAME-04.flac');
        await openMusic(tester, gateway: gateway);
        final l10n = localizations(tester);

        await tester.tap(find.text(l10n.musicViewSongs));
        await tester.pumpAndSettle();

        expect(find.textContaining(l10n.musicUnknownTitle), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );
  });

  group('loading and emptiness', () {
    testWidgets(
      'GivenMetadataStillArriving_WhenTheAreaIsShown_ThenItSaysHowFarItHasGot',
      (tester) async {
        final gateway = libraryOfThree()..holdDetailsAfter(1);
        await openMusic(tester, gateway: gateway);
        final l10n = localizations(tester);

        expect(find.text(l10n.musicLoading(1, 3)), findsOneWidget);
      },
    );

    testWidgets(
      'GivenNoAudioFiles_WhenTheAreaIsShown_ThenItSaysTheLibraryIsEmpty',
      (tester) async {
        await openMusic(tester, gateway: FakeCatalogGateway());
        final l10n = localizations(tester);

        expect(find.text(l10n.musicEmpty), findsOneWidget);
      },
    );
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/playback/presentation/music_library_view_test.dart`
Expected: FAIL — `music_library_view.dart` does not exist.

- [ ] **Step 4: Write the view**

Create `lib/features/playback/presentation/music_library_view.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../application/music_browse_controller.dart';
import '../application/music_library_controller.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';
import 'music_rows.dart';

/// The music area (UC-46, FR-CT-13).
///
/// Audio does not use the catalog listing. A listing shows one row per file
/// named by its name on disk, and for music that is the one thing an owner
/// never wants to read: the catalog holds the title, the artist and the album
/// for every one of these files. This area shows those instead, and the file
/// name appears nowhere in it.
class MusicLibraryView extends ConsumerWidget {
  /// Creates the area.
  const MusicLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(musicLibraryProvider);
    final browse = ref.watch(musicBrowseControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ViewSwitcher(selected: browse.view),
        const SizedBox(height: AppSpacing.sm),
        _Breadcrumb(state: browse),
        Expanded(
          child: AsyncStateView<MusicLibrary>(
            value: library,
            onRetry: () => ref.invalidate(musicLibraryProvider),
            isEmpty: (loaded) => loaded.total == 0,
            emptyBuilder: (context) => _Empty(),
            builder: (context, loaded) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Named rather than shown as a bar: the owner wants to know
                // this will end and roughly when, which a count says and a
                // spinner does not.
                if (!loaded.isComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _Progress(library: loaded),
                  ),
                Expanded(child: _List(state: browse, library: loaded.entries)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Which list the area is showing, given where the owner has drilled to.
class _List extends ConsumerWidget {
  const _List({required this.state, required this.library});

  final MusicBrowseState state;
  final List<MusicEntry> library;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (state) {
    MusicBrowseState(inAlbum: true) => MusicTrackList(
      entries: tracksOfAlbum(state.album, state.artist, library),
      numbered: true,
    ),
    MusicBrowseState(view: MusicView.artists, inArtist: true) => MusicGroupList(
      groups: albumsOfArtist(state.artist, library),
      kind: MusicGroupKind.album,
    ),
    MusicBrowseState(view: MusicView.artists) => MusicGroupList(
      groups: artistsIn(library),
      kind: MusicGroupKind.artist,
    ),
    MusicBrowseState(view: MusicView.albums) => MusicGroupList(
      groups: albumsIn(library),
      kind: MusicGroupKind.album,
    ),
    MusicBrowseState(view: MusicView.songs) => MusicTrackList(
      entries: songsIn(library),
      numbered: false,
    ),
  };
}

/// The three views (main flow step 2).
class _ViewSwitcher extends ConsumerWidget {
  const _ViewSwitcher({required this.selected});

  final MusicView selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<MusicView>(
        segments: [
          for (final view in MusicView.values)
            ButtonSegment(value: view, label: Text(view.label(l10n))),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (chosen) => ref
            .read(musicBrowseControllerProvider.notifier)
            .show(chosen.single),
      ),
    );
  }
}

/// How far in the owner is, and the way back out (main flow step 3).
class _Breadcrumb extends ConsumerWidget {
  const _Breadcrumb({required this.state});

  final MusicBrowseState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = ref.read(musicBrowseControllerProvider.notifier);

    final crumbs = <(String, VoidCallback?)>[
      (l10n.musicBreadcrumbRoot, state.inArtist || state.inAlbum
          ? controller.upToArtists
          : null),
      if (state.inArtist)
        (
          state.artist ?? l10n.musicUnknownArtist,
          state.inAlbum ? controller.upToArtist : null,
        ),
      if (state.inAlbum) (state.album ?? l10n.musicUnknownAlbum, null),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          for (final (index, (label, onTap)) in crumbs.indexed) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Text('›', style: theme.textTheme.bodySmall),
              ),
            // The last crumb is where the owner already is, so it is text
            // rather than a control that would do nothing.
            if (onTap == null)
              Text(label, style: theme.textTheme.bodySmall)
            else
              TextButton(onPressed: onTap, child: Text(label)),
          ],
        ],
      ),
    );
  }
}

/// How far the metadata read has got (main flow step 1).
class _Progress extends StatelessWidget {
  const _Progress({required this.library});

  final MusicLibrary library;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Text(
      l10n.musicLoading(library.entries.length, library.total),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Nothing is catalogued (AF-03).
class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Text(
        l10n.musicEmpty,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// How each view names itself.
extension on MusicView {
  String label(AppLocalizations l10n) => switch (this) {
    MusicView.artists => l10n.musicViewArtists,
    MusicView.albums => l10n.musicViewAlbums,
    MusicView.songs => l10n.musicViewSongs,
  };
}
```

- [ ] **Step 5: Write the rows**

Create `lib/features/playback/presentation/music_rows.dart`. This task's version carries text and a tap; Task 5 adds the context menu:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../application/music_browse_controller.dart';
import '../domain/music_browse.dart';
import '../domain/music_grouping.dart';

/// What a group of tracks is (UC-46 main flow step 2).
enum MusicGroupKind {
  /// An artist, which drills into their albums.
  artist,

  /// An album, which drills into its tracks.
  album,
}

/// A track's title, or the word for a file whose tags carry none.
///
/// The one place an absent tag becomes a word, so the area and the search
/// results cannot disagree about what a file with no title is called — and so
/// that "never the file name" (FR-CT-13) is enforced in one function rather
/// than remembered at every call site.
String musicTitleOf(MusicEntry entry, AppLocalizations l10n) =>
    entry.title ?? l10n.musicUnknownTitle;

/// A track's artist, or the word for a file whose tags carry none.
String musicArtistOf(MusicEntry entry, AppLocalizations l10n) =>
    entry.artist ?? l10n.musicUnknownArtist;

/// A group's name, or the word for the files that name none.
String musicGroupName(
  MusicGroup group,
  AppLocalizations l10n, {
  required MusicGroupKind kind,
}) =>
    group.name ??
    switch (kind) {
      MusicGroupKind.artist => l10n.musicUnknownArtist,
      MusicGroupKind.album => l10n.musicUnknownAlbum,
    };

/// The artists, or the albums (UC-46 main flow step 2).
///
/// A builder rather than a column: FR-CT-10 asks that scrolling cost not grow
/// with the size of the library, and that applies to a list of albums exactly
/// as it applies to a list of files.
class MusicGroupList extends ConsumerWidget {
  /// Creates the list.
  const MusicGroupList({required this.groups, required this.kind, super.key});

  /// What to show.
  final List<MusicGroup> groups;

  /// Whether these are artists or albums.
  final MusicGroupKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(musicBrowseControllerProvider.notifier);

    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final artist = group.entries.first.artist;

        return ListTile(
          leading: Icon(
            kind == MusicGroupKind.artist
                ? Icons.person_outline
                : Icons.album_outlined,
          ),
          title: Text(musicGroupName(group, l10n, kind: kind)),
          // An album says whose it is; an artist is already the answer to
          // that question.
          subtitle: kind == MusicGroupKind.album
              ? Text(artist ?? l10n.musicUnknownArtist)
              : null,
          // Drilling in rather than playing: playing a whole artist or record
          // is on the submenu, where it is a decision rather than something a
          // mis-aimed click does.
          onTap: () => kind == MusicGroupKind.artist
              ? controller.openArtist(group.name)
              : controller.openAlbum(group.name, artist),
        );
      },
    );
  }
}

/// The tracks (UC-46 main flow step 3).
class MusicTrackList extends ConsumerWidget {
  /// Creates the list.
  const MusicTrackList({
    required this.entries,
    required this.numbered,
    super.key,
  });

  /// The tracks to show, already in the order they belong in.
  final List<MusicEntry> entries;

  /// Whether each row leads with its track number.
  ///
  /// True inside an album, where the number is what orders the record; false
  /// in Songs, where the list spans the library and a number belonging to some
  /// other record would say nothing.
  final bool numbered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];

        return ListTile(
          leading: numbered
              ? SizedBox(
                  width: 32,
                  child: Text(
                    entry.metadata.track?.toString() ?? '',
                    textAlign: TextAlign.end,
                  ),
                )
              : const Icon(Icons.music_note_outlined),
          title: Text(musicTitleOf(entry, l10n)),
          subtitle: numbered ? null : Text(musicArtistOf(entry, l10n)),
          // Inside a record, a track plays the record from there; in Songs it
          // plays alone, because there is no record around it to continue.
          onTap: () {
            final player = ref.read(audioPlaybackControllerProvider.notifier);

            unawaited(
              numbered
                  ? player.playAlbum(entry.file)
                  : player.playTrack(entry.file),
            );
          },
        );
      },
    );
  }
}
```

Add `import 'dart:async';` for `unawaited`.

- [ ] **Step 6: Route the music destination to it**

In `lib/features/shell/presentation/shell_screen.dart`, in `ShellContentArea`'s switch, add a case above the catch-all:

```dart
              // UC-46: audio has its own area. A listing of file names is the
              // one thing a music library should never be.
              ShellDestination.music => const MusicLibraryView(),
```

- [ ] **Step 7: Run the tests**

Run: `flutter test test/features/playback test/features/shell`
Expected: PASS. A shell test that expected a `CatalogListing` on the music destination is updated to the new area rather than deleted, unless what it asserted was specifically about the generic listing.

- [ ] **Step 8: Run the whole suite and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "feat: browse music by artist, album, and song"
```

---

### Task 5: The per-file context menu

**Files:**
- Modify: `lib/features/playback/presentation/music_rows.dart`
- Modify: `lib/features/catalog/presentation/music_metadata_form.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/playback/presentation/music_context_menu_test.dart`

**Interfaces:**
- Consumes: `audioPlaybackControllerProvider` (`playTrack`, `playAlbum`, `playArtist`), `FileDetailsView.show(BuildContext, WidgetRef, String uuid)`, `MusicEntry`.
- Produces:
  - `class MusicRowMenu extends ConsumerWidget` — `const MusicRowMenu({required MusicEntry entry, required Widget child, super.key})`, wrapping a row so right-click opens the menu, and exposing the same menu from a trailing button.
  - `static Future<void> MusicMetadataForm.showFor(BuildContext context, WidgetRef ref, String uuid, MusicMetadata metadata)` — opens the editor on metadata already in hand, without a second details read.
  - The localization key `musicRowActions`.

- [ ] **Step 1: Add the localization key**

`lib/core/l10n/app_en.arb`:

```json
  "musicRowActions": "Actions for this track",
  "@musicRowActions": {
    "description": "Tooltip on the button that opens a track row's context menu, which right-clicking the row also opens."
  },
```

`lib/core/l10n/app_pt.arb`:

```json
  "musicRowActions": "Ações desta faixa",
```

Run: `flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

Create `test/features/playback/presentation/music_context_menu_test.dart`:

```dart
import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/features/catalog/presentation/file_details_view.dart';
import 'package:alexandria_ui/features/catalog/presentation/music_metadata_form.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';
import '../../../support/fake_playback.dart';
import '../../../support/shell_harness.dart';

/// A track's own actions (UC-46, FR-CT-14).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the songs view over a one-track library.
  Future<void> openSongs(WidgetTester tester) async {
    final gateway = FakeCatalogGateway()
      ..addAudio(
        uuid: '1',
        name: 'DISKNAME-01.flac',
        title: 'Airbag',
        artist: 'Radiohead',
        album: 'OK',
      );

    final container = await tester.pumpShell(
      extraOverrides: [catalogGatewayProvider.overrideWithValue(gateway)],
    );
    container
        .read(shellControllerProvider.notifier)
        .go(ShellDestination.music);
    await tester.pumpAndSettle();

    await tester.tap(find.text(localizations(tester).musicViewSongs));
    await tester.pumpAndSettle();
  }

  /// Opens the row's menu by right-clicking it.
  Future<void> rightClickRow(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.text('Airbag')),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'GivenATrackRow_WhenItIsRightClicked_ThenTheMenuOffersItsFiveActions',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);

      for (final label in [
        l10n.audioPlay,
        l10n.audioPlayAlbum,
        l10n.audioPlayArtist,
        l10n.detailsTitle,
        l10n.detailsEditMetadata,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    },
  );

  testWidgets(
    'GivenATrackRow_WhenItsActionsButtonIsTapped_ThenTheSameMenuOpens',
    (tester) async {
      // The right mouse button is not the only way in: the button is what
      // makes the menu reachable from the keyboard.
      await openSongs(tester);
      final l10n = localizations(tester);

      await tester.tap(find.byTooltip(l10n.musicRowActions));
      await tester.pumpAndSettle();

      expect(find.text(l10n.detailsTitle), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheMenu_WhenDetailsAreChosen_ThenTheDetailsDialogOpens',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.detailsTitle));
      await tester.pumpAndSettle();

      expect(find.byType(FileDetailsView), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheMenu_WhenEditingMetadataIsChosen_ThenTheFormOpens',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.detailsEditMetadata));
      await tester.pumpAndSettle();

      expect(find.byType(MusicMetadataForm), findsOneWidget);
    },
  );

  testWidgets(
    'GivenTheMenu_WhenPlayAlbumIsChosen_ThenTheAlbumIsQueued',
    (tester) async {
      await openSongs(tester);
      final l10n = localizations(tester);

      await rightClickRow(tester);
      await tester.tap(find.text(l10n.audioPlayAlbum));
      await tester.pumpAndSettle();

      expect(find.byType(ShellScreen), findsOneWidget);
    },
  );
}
```

The last test asserts only that choosing the entry leaves the shell standing; assert the queue itself the way `test/features/playback/presentation/audio_player_test.dart` already does — read that file first and follow its approach with `FakeMediaPlayer`, rather than inventing a second one.

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/playback/presentation/music_context_menu_test.dart`
Expected: FAIL — there is no menu on the row.

- [ ] **Step 4: Add the metadata form's second entry point**

In `lib/features/catalog/presentation/music_metadata_form.dart`, beside `show`:

```dart
  /// Presents the form for [uuid], on metadata already read.
  ///
  /// The music area holds every track's metadata already — it is what the
  /// rows are named from — so opening the editor from a row should not cost a
  /// second read of the same file.
  static Future<void> showFor(
    BuildContext context,
    WidgetRef ref,
    String uuid,
    MusicMetadata metadata,
  ) {
    ref.read(musicMetadataEditorProvider.notifier).open(uuid, metadata);

    return showDialog<void>(
      context: context,
      builder: (context) => const MusicMetadataForm(),
    );
  }
```

- [ ] **Step 5: Write the menu**

In `lib/features/playback/presentation/music_rows.dart`, add:

```dart
/// A track's own actions (UC-46, FR-CT-14).
///
/// Right-click is what a desktop owner reaches for, and the button beside the
/// row is what makes the same five actions reachable without a right mouse
/// button and from the keyboard. Both open the one menu, so there is no second
/// list of actions to keep in step.
class MusicRowMenu extends ConsumerWidget {
  /// Creates the wrapper.
  const MusicRowMenu({required this.entry, required this.child, super.key});

  /// The track the menu acts on.
  final MusicEntry entry;

  /// The row itself.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.play_arrow),
          onPressed: () => _play(ref, (player) => player.playTrack(entry.file)),
          child: Text(l10n.audioPlay),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.album_outlined),
          onPressed: () => _play(ref, (player) => player.playAlbum(entry.file)),
          child: Text(l10n.audioPlayAlbum),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.person_outline),
          onPressed: () =>
              _play(ref, (player) => player.playArtist(entry.file)),
          child: Text(l10n.audioPlayArtist),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.info_outline),
          onPressed: () =>
              FileDetailsView.show(context, ref, entry.file.uuid),
          child: Text(l10n.detailsTitle),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => MusicMetadataForm.showFor(
            context,
            ref,
            entry.file.uuid,
            entry.metadata,
          ),
          child: Text(l10n.detailsEditMetadata),
        ),
      ],
      builder: (context, controller, _) => GestureDetector(
        onSecondaryTapDown: (details) =>
            controller.open(position: details.localPosition),
        child: Row(
          children: [
            Expanded(child: child),
            IconButton(
              tooltip: l10n.musicRowActions,
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ],
        ),
      ),
    );
  }

  void _play(
    WidgetRef ref,
    Future<void> Function(AudioPlaybackController player) play,
  ) => unawaited(play(ref.read(audioPlaybackControllerProvider.notifier)));
}
```

Add the imports it needs: `file_details_view.dart`, `music_metadata_form.dart`, and `audio_playback_controller.dart`.

- [ ] **Step 6: Wrap the track rows in it**

In `MusicTrackList`'s `itemBuilder`, wrap the `ListTile` in the menu:

```dart
        return MusicRowMenu(entry: entry, child: ListTile(...));
```

Leave `MusicGroupList` alone: the menu acts on a file, and an artist is not one.

- [ ] **Step 7: Run the tests**

Run: `flutter test test/features/playback`
Expected: PASS.

- [ ] **Step 8: Run the whole suite and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "feat: give each track its own actions menu"
```

---

### Task 6: The file's own facts in the details dialog

**Files:**
- Create: `lib/features/catalog/domain/file_size.dart`
- Modify: `lib/features/catalog/presentation/file_details_view.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/catalog/domain/file_size_test.dart`
- Test: `test/features/catalog/presentation/file_details_view_test.dart` (added group)

**Interfaces:**
- Consumes: `FileDetails` (whose `file` carries `name`, `path`, `sizeBytes`, `mtime`).
- Produces: `String formatFileSize(int bytes)` — `formatFileSize(4922880) == '4.7 MB'`, `formatFileSize(512) == '512 B'`, `formatFileSize(0) == '0 B'`.
- Produces the localization keys `detailsFileSection`, `detailsFileName`, `detailsFileSize`, `detailsFileFormat`, `detailsFileModified`.

- [ ] **Step 1: Write the failing size test**

Create `test/features/catalog/domain/file_size_test.dart`:

```dart
import 'package:alexandria_ui/features/catalog/domain/file_size.dart';
import 'package:flutter_test/flutter_test.dart';

/// A byte count as an owner reads it (UC-13, FR-CT-05).
void main() {
  test('GivenAByteCount_WhenItIsUnderAKilobyte_ThenItIsShownInBytes', () {
    expect(formatFileSize(512), '512 B');
  });

  test('GivenAByteCount_WhenItIsLarger_ThenItUsesTheLargestUnitThatFits', () {
    expect(formatFileSize(4922880), '4.7 MB');
  });

  test('GivenAByteCount_WhenItIsExactlyAUnit_ThenNoFractionIsShown', () {
    expect(formatFileSize(1024), '1 KB');
  });

  test('GivenNoBytes_WhenItIsFormatted_ThenItReadsZero', () {
    // A zero-byte file is a real thing on disk, and "0 B" is the truth about
    // it — not an absent value.
    expect(formatFileSize(0), '0 B');
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/catalog/domain/file_size_test.dart`
Expected: FAIL — `file_size.dart` does not exist.

- [ ] **Step 3: Write the formatter**

Create `lib/features/catalog/domain/file_size.dart`:

```dart
/// [bytes] as an owner reads a file size (UC-13, FR-CT-05).
///
/// Not localized: the unit symbols are the same in both supported languages,
/// and a size is read the same way in each — the same reasoning the details
/// view already applies to a duration.
///
/// Binary units, because that is what a file manager on either supported
/// platform shows for the same file, and a size that disagrees with the one
/// beside it in Explorer reads as a bug.
String formatFileSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];

  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }

  // One decimal, and none when it would be a trailing zero: "4.7 MB" is the
  // detail worth having, "4.0 MB" is noise.
  final rounded = size.toStringAsFixed(size < 10 && unit > 0 ? 1 : 0);
  final trimmed = rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;

  return '$trimmed ${units[unit]}';
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `flutter test test/features/catalog/domain/file_size_test.dart`
Expected: PASS, all four.

- [ ] **Step 5: Add the localization keys**

`lib/core/l10n/app_en.arb`:

```json
  "detailsFileSection": "The file",
  "@detailsFileSection": {
    "description": "Heading over the section of the details dialog describing the file on disk, as opposed to what it holds."
  },
  "detailsFileName": "File name",
  "@detailsFileName": {
    "description": "Label for the file's name on disk in the details dialog."
  },
  "detailsFileSize": "Size on disk",
  "@detailsFileSize": {
    "description": "Label for the file's size in the details dialog."
  },
  "detailsFileFormat": "Format",
  "@detailsFileFormat": {
    "description": "Label for the file's format, taken from its extension, in the details dialog."
  },
  "detailsFileModified": "Last modified",
  "@detailsFileModified": {
    "description": "Label for when the file was last changed on disk, in the details dialog."
  },
```

`lib/core/l10n/app_pt.arb`:

```json
  "detailsFileSection": "O arquivo",
  "detailsFileName": "Nome do arquivo",
  "detailsFileSize": "Tamanho em disco",
  "detailsFileFormat": "Formato",
  "detailsFileModified": "Última modificação",
```

Run: `flutter gen-l10n`

- [ ] **Step 6: Write the failing dialog test**

Add to `test/features/catalog/presentation/file_details_view_test.dart` — read the file first and follow how it already opens the dialog:

```dart
  group('the file itself (FR-CT-05)', () {
    testWidgets(
      'GivenAFile_WhenItsDetailsOpen_ThenItsNameSizeAndFormatAreShown',
      (tester) async {
        // The one place the name on disk belongs, under a label saying that is
        // what it is — FR-CT-13 keeps it out of the music area, not out of the
        // record of what the file is.
        await openDetailsFor(tester, name: 'DISKNAME-01.flac', sizeBytes: 4922880);
        final l10n = localizations(tester);

        expect(find.text(l10n.detailsFileName), findsOneWidget);
        expect(find.text('DISKNAME-01.flac'), findsWidgets);
        expect(find.text('4.7 MB'), findsOneWidget);
        expect(find.text('FLAC'), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAFileWithNoRecordedSize_WhenItsDetailsOpen_ThenNoSizeRowIsShown',
      (tester) async {
        // A core that answered without a size has not told us the file is
        // empty, and a row reading "0 B" would say it had.
        await openDetailsFor(tester, name: 'DISKNAME-01.flac', sizeBytes: null);
        final l10n = localizations(tester);

        expect(find.text(l10n.detailsFileSize), findsNothing);
      },
    );
  });
```

Write `openDetailsFor` and `localizations` to match the helpers the file already has; if it has equivalents, use those and pass the extra fixture values through them.

- [ ] **Step 7: Add the section to the dialog**

In `lib/features/catalog/presentation/file_details_view.dart`, inside `_Details`'s column, after the path section:

```dart
          const SizedBox(height: AppSpacing.md),
          _Section(l10n.detailsFileSection),
          _FileFacts(file: details.file),
```

and add the widget beside `_Metadata`:

```dart
/// What the file is, as opposed to what it holds (UC-13, FR-CT-05).
///
/// The name, the size and the modification time come off the record the core
/// already returned with the listing, so this section costs no extra call.
/// A value the core did not answer is absent rather than shown as a zero,
/// which would be this application inventing a fact.
class _FileFacts extends StatelessWidget {
  const _FileFacts({required this.file});

  final CatalogFile file;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final extension = p.extension(file.name).replaceFirst('.', '');
    final rows = <(String, String)>[
      (l10n.detailsFileName, file.name),
      if (file.sizeBytes case final bytes?)
        (l10n.detailsFileSize, formatFileSize(bytes)),
      if (extension.isNotEmpty)
        (l10n.detailsFileFormat, extension.toUpperCase()),
      if (file.mtime case final modified?)
        (l10n.detailsFileModified, _formatMoment(modified)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label, style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: Text(value, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
```

Use whatever this file already uses to render a date for `_formatMoment` — search it for an existing date formatting helper and reuse it rather than adding a second one. If there is none, format with `MaterialLocalizations.of(context).formatFullDate` and say in a comment why that rather than a raw `toString`.

Add the imports: `package:path/path.dart as p`, `../domain/file_size.dart`, and `../domain/catalog_file.dart` if not already there.

- [ ] **Step 8: Run the tests, the suite, and analyze**

Run: `flutter test test/features/catalog && flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "feat: show what a file is in its details"
```

---

### Task 7: Audio results carry their titles

**Files:**
- Modify: `lib/features/catalog/presentation/catalog_search_view.dart`
- Modify: `lib/core/di/providers.dart`
- Test: `test/features/catalog/presentation/catalog_search_test.dart` (added group)

**Interfaces:**
- Consumes: `musicTitleOf`, `MusicEntry`, `musicLibraryProvider`, `catalogGatewayProvider`, `sessionControllerProvider`.
- Produces: `audioTitleProvider` — `FutureProvider.family<String?, CatalogFile>`, answering the metadata title of an audio file, `null` while it is not known. It reads the cached music library first and falls back to one details call for that file, so a search does not pay for the whole library.

- [ ] **Step 1: Write the failing test**

Add to `test/features/catalog/presentation/catalog_search_test.dart` — read the file first and reuse its harness:

```dart
  group('audio results (FR-CT-13)', () {
    testWidgets(
      'GivenAnAudioMatch_WhenTheResultsAreShown_ThenItReadsItsMetadataTitle',
      (tester) async {
        // The rule follows the file type, not the screen: if the results
        // showed names on disk, every file name the music area removes would
        // come back the moment anyone searched.
        await searchFor(
          tester,
          term: 'air',
          gateway: FakeCatalogGateway()
            ..addAudio(
              uuid: '1',
              name: 'DISKNAME-01.flac',
              title: 'Airbag',
              artist: 'Radiohead',
            ),
        );

        expect(find.textContaining('Airbag'), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );

    testWidgets(
      'GivenAnUntaggedAudioMatch_WhenTheResultsAreShown_ThenItReadsUnknownTitle',
      (tester) async {
        await searchFor(
          tester,
          term: 'disk',
          gateway: FakeCatalogGateway()
            ..addAudio(uuid: '1', name: 'DISKNAME-01.flac'),
        );
        final l10n = localizations(tester);

        expect(find.textContaining(l10n.musicUnknownTitle), findsOneWidget);
        expect(find.textContaining('DISKNAME'), findsNothing);
      },
    );

    testWidgets(
      'GivenANonAudioMatch_WhenTheResultsAreShown_ThenItStillReadsItsFileName',
      (tester) async {
        // Only audio has a metadata name to show instead. A document's name
        // on disk is what it is called.
        await searchFor(
          tester,
          term: 'notes',
          gateway: FakeCatalogGateway()..addDocument(uuid: '2', name: 'notes.pdf'),
        );

        expect(find.textContaining('notes.pdf'), findsOneWidget);
      },
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/catalog/presentation/catalog_search_test.dart`
Expected: FAIL — the audio row shows `DISKNAME-01.flac`.

- [ ] **Step 3: Add the provider**

In `lib/core/di/providers.dart`:

```dart
/// The metadata title of an audio file, or `null` while it is not known
/// (UC-11, FR-CT-13).
///
/// Per file rather than over the whole library: a search shows a screenful of
/// results, and reading every audio file in the catalog to name three of them
/// would make searching cost what browsing costs. The cached library is
/// consulted first, so a search after a visit to the music area costs nothing
/// at all.
final audioTitleProvider = FutureProvider.family<String?, CatalogFile>((
  ref,
  file,
) async {
  if (file.type != LibraryType.audio) return null;

  final cached = ref.watch(musicLibraryProvider).valueOrNull;
  for (final entry in cached?.entries ?? const <MusicEntry>[]) {
    if (entry.file.uuid == file.uuid) return entry.title;
  }

  final credential = ref.read(sessionControllerProvider.notifier).credential;
  if (credential == null) return null;

  final details = await ref
      .read(catalogGatewayProvider)
      .fileDetails(uuid: file.uuid, credential: credential);

  return switch (details) {
    FileDetailsRead(:final details) =>
      MusicMetadata.fromDetails(details.metadata).title?.trim(),
    // A file whose details will not come back is a file with no title we can
    // show, which the row already has a word for.
    FileDetailsFailed() => null,
  };
});
```

- [ ] **Step 4: Use it in the results**

In `lib/features/catalog/presentation/catalog_search_view.dart`, replace the `ListTile` inside the results loop with a row widget that resolves an audio file's name:

```dart
                  for (final file in files) _ResultRow(file: file, term: term),
```

and add:

```dart
/// One match (main flow step 3).
///
/// An audio file is named by its metadata title, exactly as it is in the music
/// area (FR-CT-13): the rule follows the file type, and a result list that
/// showed names on disk would put back every file name that area removes.
/// Every other type is named by its file name, which is what it is called.
class _ResultRow extends ConsumerWidget {
  const _ResultRow({required this.file, required this.term});

  final CatalogFile file;
  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final isAudio = file.type == LibraryType.audio;
    final title = isAudio
        ? ref.watch(audioTitleProvider(file)).valueOrNull ?? l10n.musicUnknownTitle
        : file.name;

    return ListTile(
      leading: Icon(
        isAudio ? Icons.music_note_outlined : Icons.insert_drive_file_outlined,
      ),
      // The term is marked in the name the row shows; marking a name the row
      // does not show would point at nothing.
      title: _Highlighted(text: title, term: term),
      subtitle: Text(
        file.path,
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
```

Add the imports it needs: `flutter_riverpod`, `providers.dart`, `library_type.dart`.

- [ ] **Step 5: Run the tests, the suite, and analyze**

Run: `flutter test test/features/catalog && flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: name audio search results by their metadata"
```

---

### Task 8: The requirements, and the whole suite

**Files:**
- Modify: `docs/requirements/System Requirements Document.md`
- Modify: `docs/requirements/Use Case Specification Document.md`
- Modify: `test/features/shell/presentation/goldens/*.png` (only if the suite says they moved)

**Interfaces:**
- Consumes: everything the previous seven tasks built.
- Produces: nothing new.

- [ ] **Step 1: Add the two requirements**

In `docs/requirements/System Requirements Document.md`, after FR-CT-12:

```md
| FR-CT-13 | The system shall present audio files by their metadata — artist, album, or title — and shall not present an audio file by its file name in any listing, grouping, or search result. |
| FR-CT-14 | The system shall offer, for each file in the music area, a context menu carrying the file's playback actions, its details, and its metadata editor. |
```

Then add both to the traceability tables the same way FR-CT-11 and FR-CT-12 appear in them — find every table that lists FR-CT-12 and give the two new requirements the same treatment.

- [ ] **Step 2: Amend the two requirements the music area departs from**

FR-CT-03 and FR-CT-07 describe the layout switcher and the lifecycle filter. Amend each to exclude audio, in the register the surrounding text uses — audio has its own presentation (FR-CT-13), and its deleted records are reached through the deleted-items review (UC-34) like every other type's.

- [ ] **Step 3: Add UC-46**

In `docs/requirements/Use Case Specification Document.md`, after UC-45, add a use case in the exact format the surrounding ones use — read UC-45 and match its table, its section headings, and its level of detail:

- **ID:** UC-46. **Name:** Browse the music library.
- **Actor:** the owner. **Trigger:** opening the music area.
- **Preconditions:** a session is active; the catalog holds audio files.
- **Main flow:** (1) the application reads each audio file's metadata, showing what it has while the rest arrives; (2) the owner chooses artists, albums, or songs; (3) the owner drills into an artist and then an album, or straight into an album, returning by the breadcrumb; (4) the owner plays a track, an album, or an artist.
- **Alternative flows:** AF-01, a file whose metadata names no title, artist, or album — it is shown under the unknown names and grouped last, never under its file name. AF-02, a file whose metadata cannot be read — it joins the library untagged rather than disappearing. AF-03, no audio files are catalogued — the area says so.
- **Postconditions:** unchanged catalog; a queue when the owner played something.

- [ ] **Step 4: Run the whole suite**

Run: `flutter test`
Expected: PASS. The shell goldens are captured on the bookmarks destination and should be untouched by this work; if they fail, regenerate them with `flutter test test/features/shell/presentation/shell_screen_golden_test.dart --update-goldens`, then LOOK at the six images and confirm what changed is what should have.

- [ ] **Step 5: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 6: Commit**

```bash
git add docs test
git commit -m "docs: specify browsing the music library"
```

- [ ] **Step 7: Run the application and look at it**

Run: `flutter run -d windows`

Open Music with a real library indexed. Check: artists appear while the metadata is still loading and the progress line counts up; the three views and the breadcrumb work; no file name appears anywhere; right-click and the `⋮` both open the menu; Details shows the file name, size, format and modified time. A layout that passes its tests and reads badly on screen is a finding to report, not a task to tick.

---

## Self-Review

**Spec coverage**

| Spec section | Task |
| --- | --- |
| §1 The music area — three views, drill-down, breadcrumb | 3, 4 |
| §1 Track order inside an album; alphabetical elsewhere | 1 |
| §2 Never a file name; Unknown fallbacks; untagged last | 1, 4 |
| §2 The rule reaches the search results | 7 |
| §3 What a row does — album from a track, track alone in Songs | 4 |
| §4 The per-file submenu, on right-click and on `⋮` | 5 |
| §5 The details dialog's file facts | 6 |
| §6 Incremental loading, progress, session cache, failed details | 2, 4 |
| §7 What the music area gives up | 8 (the requirement amendments) |
| §8 No duration shown | Nothing to build; no task renders one |
| Requirements impact | 8 |
| Testing | 1–7, with the manual look in 8 |

**Placeholders:** none. Every code step carries its code; every test step carries its test. Three steps deliberately delegate a detail to the existing file's conventions rather than inventing a second way — the fake gateway's helper names (Task 2), the audio-queue assertion style (Task 5), and the date formatting already in the details view (Task 6) — and each names the file to read and what to match.

**Type consistency:** `MusicEntry.title` (Task 1) is used in Tasks 4, 5 and 7. `MusicGroup{name, entries}` (Task 1) is consumed by `MusicGroupList` (Task 4). `MusicLibrary{entries, total, isComplete}` (Task 2) is read in Task 4 and Task 7. `MusicBrowseState{view, artist, album, inArtist, inAlbum}` and the controller's five methods (Task 3) are used by `_List`, `_Breadcrumb`, and `MusicGroupList` (Tasks 4 and 5). `musicTitleOf`/`musicArtistOf`/`musicGroupName` are defined in Task 4's `music_rows.dart` and reused in Task 7. `MusicMetadataForm.showFor(context, ref, uuid, metadata)` is defined and called in Task 5. `formatFileSize(int)` is defined and used in Task 6.
