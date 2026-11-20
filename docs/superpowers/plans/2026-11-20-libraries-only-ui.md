# Libraries Only, and Audio Back, Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the desktop app work the way core 0.6.0 does. Libraries are the only way in: they are added, scanned,
moved and removed on the Libraries screen. Library files show in every panel. Audio is a playable, editable file type.

**Architecture:**
- The source-folder feature goes. What indexing still needs from it moves to `lib/features/indexing`, keyed by
  library uuid instead of root path.
- Audio becomes one more `FileType` whose tags ride on `CatalogFile`. That one decision gives the Music rows, the
  album sort, the display name everywhere and the player queue what they need.
- A separate `AudioPlaybackController` drives its own `MediaPlayer`, and a player bar sits in the shell.

**Tech Stack:** Flutter 3.50.0, Riverpod 3, freezed, ffigen over the vendored C header, media_kit, gen-l10n (en and
pt). The core is alexandria-api `v0.6.0`.

**Spec:** `docs/superpowers/specs/2026-11-20-libraries-only-ui-design.md`. Read it first; the section numbers below
(§n) are its sections.

## Global Constraints

- Core pin: `CORE_REF=0e4500bf08039e92a63e48f7d51d351529dad85b`, a full SHA (`ci/analyze.sh` refuses anything else).
- Version range: `CoreVersionRange.minimum = '0.6.0'`, `exclusiveMaximum = '0.7.0'`.
- The vendored header (`native/include/alexandria_ffi.h`) is a verbatim copy of the core's generated `header.h`, never
  hand-edited. `lib/core/bindings/alexandria_bindings.dart` is ffigen output, never hand-edited.
- Generated files are committed and must be in sync: freezed and json files (`dart run build_runner build -d`),
  bindings (`dart run ffigen --config ffigen.yaml`), and l10n (`flutter gen-l10n`). `ci/analyze.sh` regenerates them
  and fails on any diff.
- Every new user-visible string goes in both `app_en.arb` and `app_pt.arb`, with a description: the parity test and
  `required-resource-attributes` enforce it.
- Layering: Domain does not import Data or Presentation. The custom lints in `tools/alexandria_lints` enforce it, and
  `analysis_test` proves the lints.
- Tests are named Given-When-Then: `'GivenX_WhenY_ThenZ'` strings. Write each failing test first.
- Commits: lowercase Conventional Commits, a subject of at most 50 characters in the imperative mood, a body wrapped
  at 72 that says why, and no attribution lines.
- The CHANGELOG entry goes under `## [Unreleased]`, in Keep-a-Changelog style, wrapped near 120 columns.
- Copy that the spec fixes:
  - The remove confirmation says that removing the library deletes it from the catalog with its files, reading and
    watching positions, and collection membership, and that nothing on disk is touched.
  - With a paused run, it adds that the paused scan is discarded too.
  - The panel label is "Music" / "Música".
- No new packages. `media_kit_libs_video` already decodes audio.
- One heavy suite at a time (6 CPUs and 8 GB for everything). Never run two test suites or containers in parallel.

## Review Focus

1. **A second "Scan again" while the first run is still starting or running.** The core answers `INDEX_ERR_CONFLICT`.
   The row shows the core's sentence, follows exactly one run, and nothing crashes. Test in Task 4.
2. **Removing a library whose track is playing or queued.** Playback stops if it was playing, and the library's
   tracks leave the queue. Test in Task 9.
3. **Untagged or partly tagged audio** (no title, no artist, no track number). The name falls back to the file name.
   The album sort puts missing values last and stays stable. Test in Task 7.
4. **A paused run from an earlier session whose library still exists, or whose library is gone.** The strip names
   the library by `libraryUuid`, and falls back to the root folder's name when the uuid isn't in the libraries list.
   Test in Task 5.
5. **A 0.5 `librarySources` settings value that is malformed or huge.** The startup clean-up removes the key without
   reading or parsing it, and never throws. Test in Task 5.

---

### Task 0: Dev loop (no commit)

The unit suite builds `nativeapi` against GTK 3, X11 and Xi, which this machine doesn't have. Run tests in one
long-lived container instead, built from CI's image:

- [ ] **Step 1: Start the container.**

  ```bash
  docker run -d --name aui-dev \
    -v /home/dev/repositories/alexandria-ui:/w \
    -v aui-pub:/root/.pub-cache -v aui-flutter:/opt/flutter-cache \
    -w /w ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852 sleep infinity
  ```

  Then, inside it, source `ci/apt-packages.sh` and `ci/flutter-env.sh` as `ci/test.sh` does. Install
  `clang g++ pkg-config libgtk-3-dev libx11-dev libxi-dev`, and run `flutter pub get`.

- [ ] **Step 2: Check the loop works.**

  Run `docker exec aui-dev bash -lc '. ci/flutter-env.sh && flutter test test/core/startup'`. Expected: PASS.

`TEST` below means `docker exec aui-dev bash -lc '. ci/flutter-env.sh && flutter test <paths>'`.

`GEN` means `docker exec aui-dev bash -lc '. ci/flutter-env.sh && dart run build_runner build -d && flutter
gen-l10n'`.

`flutter analyze` runs on the host. Stop and remove the container, and its volumes, after the final verification.

---

### Task 1: Core 0.6 pin, header, bindings, version range, status codes

**Files:**
- Modify: `ci/pins.sh`, `native/include/alexandria_ffi.h`, `lib/core/bindings/alexandria_bindings.dart` (generated),
  `lib/core/startup/core_version.dart`, `lib/core/failures/core_status_mapper.dart`
- Test: `test/core/startup/core_version_test.dart`, `test/core/failures/core_status_mapper_test.dart`

**Interfaces:**
- Produces: the `INDEX_ERR_NOT_FOUND` and `INDEX_ERR_CONFLICT` constants in the bindings, and the bindings for
  `alexandria_library_index_start`. `alexandria_index_start` disappears from the bindings: `core_isolate.dart`'s
  `'indexStart'` case will stop compiling. Task 1 stubs that case to answer `INDEX_ERR_OTHER`, with a
  `// removed in Task 5` comment, so the tree still builds.

- [ ] **Step 1: Write the failing tests.**

  In `core_version_test.dart`:
  - `GivenA060Core_WhenChecked_ThenItIsSupported`: `supports('0.6.0')` and `supports('0.6.3')` are true.
  - `GivenA05Core_WhenChecked_ThenItIsRefused`: `supports('0.5.9')` is false.
  - `GivenA07Core_WhenChecked_ThenItIsRefused`: `supports('0.7.0')` is false.

  Update any existing case that asserts 0.5 is supported.

  In `core_status_mapper_test.dart`:
  - `GivenIndexNotFound_WhenMapped_ThenNotFound`: code 6 in the index family maps to `NotFoundFailure`.
  - `GivenIndexConflict_WhenMapped_ThenConflictCarriesTheCoresMessage`: code 7 with message
    `the library has an unfinished run r1; cancel it first` maps to a `ConflictFailure` whose message is that text.
  - `GivenIndexBusy_WhenMapped_ThenInvalidState`: code 5 maps to `InvalidStateFailure`. The header's doc says it is a
    "not now".

- [ ] **Step 2: Run the tests.** Run `TEST test/core/startup/core_version_test.dart
  test/core/failures/core_status_mapper_test.dart`. Expected: FAIL on the new cases.

- [ ] **Step 3: Implement.**
  - Set `CORE_REF` in `ci/pins.sh`. Rewrite its comment for the 0.6.0 release: the libraries-only core, which
    removed `alexandria_index_start` and the type scope and brought audio back as playable files.
  - Copy the header from `../alexandria-api/crates/alexandria-ffi/src/header.h`. First check that the alexandria-api
    checkout is at `v0.6.0` and that its header was generated from that tree. If unsure, regenerate it with
    `ci-check lint-and-test ../alexandria-api` and take the header the build writes.
  - Regenerate the bindings. If ffigen can't find libclang on the host, run it in `aui-dev` with `libclang-dev`
    installed.
  - Change the range constants, and rewrite the class's doc comment for 0.6.
  - In `_mapIndex`, add codes 5, 6 and 7, using the bindings' constants.

- [ ] **Step 4: Run the tests and analysis.** Run the step 2 tests, then `flutter analyze`. Expected: PASS, and no
  issues.

- [ ] **Step 5: Commit.** `build: pin the libraries-only 0.6.0 core`.

---

### Task 2: Every library, everywhere (§4)

**Files:**
- Modify:
  - `lib/features/catalog/domain/catalog_gateway.dart` (`listFiles`)
  - `lib/features/catalog/data/core_catalog_gateway.dart`
  - `lib/features/catalog/application/listing_controller.dart`
  - `lib/features/catalog/application/search_controller.dart`
  - `lib/features/catalog/application/dashboard_controller.dart`
  - `lib/features/lifecycle/application/deleted_items_controller.dart`
  - `lib/features/lifecycle/application/missing_files_controller.dart`
  - `lib/features/organization/application/collection_candidates_controller.dart`
  - `test/support/fake_catalog_gateway.dart`
- Delete: `test/features/catalog/application/library_reach_test.dart`
- Test: `test/features/catalog/application/listing_controller_test.dart`, `dashboard_controller_test.dart` (create
  either test file if it doesn't exist)

**Interfaces:**
- Produces: `CatalogGateway.listFiles({required String credential, FileType? type, LifecycleFilter lifecycle})`, with
  no `includeLibraries`. The fake gateway returns every file it holds, whatever its `libraryUuid`.

- [ ] **Step 1: Write the failing tests.**
  - `GivenAFileInALibrary_WhenItsTypePanelLists_ThenItIsListed`: the fake holds a video with `libraryUuid: 'l1'`, and
    `listingControllerProvider(FileType.video)` contains it.
  - `GivenAFileInALibrary_WhenTypeCountsAreRead_ThenItIsCounted`.
  - `GivenARecentLibraryFile_WhenTheDashboardLoads_ThenItIsAmongRecentFiles`.

- [ ] **Step 2: Run them.** Expected: FAIL. The fake hides library files unless `includeLibraries` is set, and the
  dashboard drops them.

- [ ] **Step 3: Implement.**
  - Remove the parameter and its doc. Remove the `includeLibraries` key from the filter JSON the core is sent.
  - Remove the dashboard's `libraryUuid != null` filter.
  - Remove `libraryReaches` from the fake.
  - Rewrite the `listFiles` doc comment: it lists files across every library.
  - Fix the callers. The compiler finds them.

- [ ] **Step 4: Run the tests.** Run `TEST test/features/catalog test/features/lifecycle test/features/organization`.
  Expected: PASS.

- [ ] **Step 5: Commit.** `feat: list library files in every panel`.

---

### Task 3: Library and run wire changes (§1, §2)

**Files:**
- Modify:
  - `lib/core/bindings/core_client.dart`, `lib/core/bindings/core_isolate.dart`
  - `lib/features/library_sources/domain/index_run.dart`, `index_gateway.dart`
  - `lib/features/library_sources/data/core_index_gateway.dart`
  - `lib/features/libraries/domain/library_gateway.dart`, `lib/features/libraries/data/core_library_gateway.dart`
  - `test/support/fake_core_client.dart`, `test/support/fake_index_gateway.dart`, the libraries fake gateway (wherever
    `LibraryGateway` is faked)
- Test: `test/features/library_sources/data/core_index_gateway_test.dart`,
  `test/features/libraries/data/core_library_gateway_test.dart` (create either if missing, following the other
  `data/` tests against `FakeCoreClient`)

**Interfaces:**
- Produces:
  - `CoreClient.libraryIndexStart(String uuid, String token, [RunPriority? priority])`, returning `CoreRunStart`.
  - `CoreClient.libraryRegister(String jsonBody, String token)`, returning `CoreJsonResponse` (the body now holds
    `runId`).
  - `CoreClient.fileThumbnail(String uuid, String token)`, returning `Future<Uint8List?>` (null when there is no
    picture). Follow how other byte-returning calls cross the isolate. If none do, return the image's path, or base64
    from the header's out-parameters, whichever the header's `alexandria_file_thumbnail` gives.
  - `IndexRun.libraryUuid` (`String?`).
  - `IndexGateway.startLibraryIndex({required String uuid, RunPriority? priority, required String credential})`,
    returning `Future<IndexStartOutcome>`.
  - `LibraryGateway.register(...)` returns a new `LibraryRegistration` union:
    `LibraryRegistration.registered({required Library library, required String runId})` or
    `LibraryRegistration.failed({required Failure failure})`. It takes `RunPriority? priority`, and the body carries
    `"priority":"low"` only for low.
  - `CatalogGateway`/`PlaybackSourceGateway` are unchanged here. The thumbnail is used in Task 9.

- [ ] **Step 1: Write the failing tests.**
  - `GivenARunJsonWithLibraryUuid_WhenRead_ThenTheRunCarriesIt`, and
    `GivenARefreshRunJson_WhenRead_ThenLibraryUuidIsNull`.
  - `GivenTheCoreStartsALibraryRun_WhenStartLibraryIndex_ThenStartedWithRunId`.
  - `GivenTheCoreAnswersConflict_WhenStartLibraryIndex_ThenFailedWithConflict`.
  - `GivenRegisterSucceeds_WhenRegister_ThenRegisteredCarriesLibraryAndRunId`. The fake core answers
    `{"uuid":"l1","name":"Movies","rootPath":"/m","runId":"r1"}`.
  - `GivenLowPriority_WhenRegister_ThenTheBodyAsksForLow`.
  - `GivenRegisterOverlaps_WhenRegister_ThenFailedWithConflict`.

- [ ] **Step 2: Run them.** Expected: FAIL to compile on the new members.

- [ ] **Step 3: Implement.**
  - Add the isolate cases `'libraryIndexStart'` and `'fileThumbnail'`, modelled on `'indexRefreshStart'` and
    `'libraryRegister'`.
  - Leave `indexStart` and the old `register` callers working: callers of `LibraryGateway.register` adapt to the
    union by treating `registered` as done.

- [ ] **Step 4: Run the tests.** Run `TEST test/features/library_sources test/features/libraries test/core`.
  Expected: PASS.

- [ ] **Step 5: Commit.** `feat: start and follow a library's own run`.

---

### Task 4: Runs keyed by library, and the Libraries screen (§2, §3)

**Files:**
- Modify:
  - `lib/features/library_sources/application/index_runs_controller.dart`, `index_runs_state.dart`
  - `lib/features/libraries/application/libraries_controller.dart`
  - `lib/features/libraries/presentation/library_tree_screen.dart` (`LibrariesView`, `_add`, `_scan`, `_move`,
    `_remove`)
  - `lib/features/library_sources/presentation/run_failures_screen.dart` (only if its `show` needs a library name)
  - `lib/core/l10n/app_en.arb`, `app_pt.arb`
- Test: `test/features/library_sources/application/index_runs_controller_test.dart`,
  `test/features/libraries/presentation/library_add_test.dart`, `library_move_test.dart`,
  `libraries_screen_test.dart`, new `library_remove_test.dart` and `library_scan_test.dart`

**Interfaces:**
- Consumes: Task 3's `startLibraryIndex`, `LibraryRegistration`, and `IndexRun.libraryUuid`.
- Produces:
  - `IndexRunsState.libraryRuns`: `Map<String, IndexRun>`, keyed by library uuid.
  - `IndexRunsState.libraryRefusals`: `Map<String, Failure>`.
  - `IndexRunsController` gains:
    - `Future<void> startLibraryIndex(String uuid)`
    - `void follow(String uuid, String runId)`
    - `Future<void> pauseLibrary(String uuid)`
    - `Future<void> cancelLibrary(String uuid)`
    - `Future<void> resumeLibrary(String uuid)`
    - `void forgetLibrary(String uuid)`
    - `void dismissLibraryRefusal(String uuid)`
  - `LibrariesController.register({required String name, required String rootPath})` returns `Future<Failure?>` and,
    on success, calls `follow(library.uuid, runId)`.
  - `LibrariesController.remove(String uuid)` calls `forgetLibrary(uuid)` and refreshes active runs after a removal.
  - `Library` gains nothing. Status is read from `IndexRunsState` and `ActiveRunsState` by uuid.

- [ ] **Step 1: Write the failing tests.**

  Controller tests:
  - `GivenALibrary_WhenStartLibraryIndex_ThenTheRunIsFollowedUnderItsUuid`.
  - `GivenAnUnfinishedRun_WhenStartLibraryIndexAgain_ThenTheConflictIsRecordedAndOneRunIsFollowed`. This is Review
    Focus 1: the fake index gateway answers conflict on the second call.
  - `GivenAFollowedRun_WhenItCompletes_ThenTheRowOutcomeIsComplete`.
  - `GivenARemovedLibrary_WhenForgotten_ThenItsRunIsNoLongerFollowed`.

  Widget tests (on `LibrariesView`):
  - `GivenAPickedFolderAndName_WhenAdded_ThenRegisteredAndItsRunShows`.
  - `GivenAnOverlappingFolder_WhenAdded_ThenTheCoresSentenceShowsAndNothingIsAdded`.
  - `GivenALibrary_WhenScanAgain_ThenALibraryRunStarts`.
  - `GivenALibrary_WhenRemoveIsConfirmed_ThenTheMessageSaysItsRecordsAreDeleted`. Assert the new
    `libraryRemoveMessage` text: it mentions the catalog, positions and collections, and says files on disk are not
    touched.
  - `GivenAPausedRun_WhenRemoveIsAsked_ThenTheMessageSaysThePausedScanIsDiscarded`.
  - `GivenARunningRun_WhenRemoved_ThenTheCoresRefusalShows`.
  - `GivenAMoveDuringARun_WhenMoved_ThenTheCoresConflictShows`.
  - `GivenFinishedRunWithFailures_WhenViewFailuresTapped_ThenRunFailuresScreenOpens`.
  - `GivenTheLibrariesScreen_WhenRefreshAllTapped_ThenARefreshStarts`.

  Delete the cases in these files that exercise source registration, the scope dialog or `markAsLibrary`.

- [ ] **Step 2: Run them.** Expected: FAIL.

- [ ] **Step 3: Implement.**
  - Write the controller members.
  - Rewrite `_add`: picker, then `askForLibraryName`, then `LibrariesController.register`. It no longer touches the
    sources.
  - `_scan` calls `startLibraryIndex`. `_move` drops `followLibraryMove`, and `_remove` drops `clearLibraryMark`.
  - The header of `LibrariesView` gets "Refresh all" and "Add library".
  - Each row shows its status from §3: the followed run, else an active run with its `libraryUuid`, else the last
    outcome this session.
  - Each row gets a ⋮ menu: Open, Scan again, Moved…, Remove.
  - Port `_RunControls`, `_RunReport` and `_RefreshAction` from `library_sources_screen.dart` into
    `lib/features/libraries/presentation/library_run_status.dart`, re-keyed by uuid.
  - Rewrite `librariesExplanation`, `librariesNone` and `libraryRemoveMessage`, and add `libraryRemovePausedNote`, in
    en and pt.
  - Run `GEN`.

- [ ] **Step 4: Run the tests.** Run `TEST test/features/libraries test/features/library_sources`. Expected: PASS.

- [ ] **Step 5: Commit.** `feat: manage libraries and their runs in one place`.

---

### Task 5: Remove library sources; `indexing` feature; clean start (§2, §3, §5)

**Files:**
- Move (`git mv`): `lib/features/library_sources` → `lib/features/indexing`, `test/features/library_sources` →
  `test/features/indexing`.
- Delete:
  - Domain: `library_source.dart` (and its generated files), `library_source_store.dart`, `folder_registration.dart`,
    `audio_scope_cleanup.dart`
  - Data: `settings_library_source_store.dart`, `disk_folder_probe.dart`
  - Application: `library_sources_controller.dart`, `library_sources_state.dart`, `audio_library_cleanup_activity.dart`
  - Presentation: `index_scope_dialog.dart`, `library_sources_screen.dart`
  - Their tests, `test/support/fake_library_sources.dart` (keep `FakeFolderPicker` by moving it into its own support
    file), `integration_test/catalog/index_scope_test.dart`
  - `startIndex` and its root-keyed state from `IndexGateway`/`CoreIndexGateway`/`IndexRunsController`, including
    `indexUnlessRunning`, `resumeRecordedRuns` and `IndexStartRefusal`
  - `CoreClient.indexStart` and its isolate case
  - The arb keys used only by deleted code (`librarySources*`, `indexScope*`, `librarySourcesOpen`)
- Create: `lib/features/indexing/application/source_list_cleanup_activity.dart`
- Modify:
  - `lib/core/di/providers.dart`
  - `lib/features/shell/presentation/library_menu.dart`, `background_activity_strip.dart`
  - `lib/features/catalog/presentation/home_dashboard.dart`, `catalog_listing.dart`, `catalog_search_view.dart`
  - `lib/features/lifecycle/presentation/missing_files_screen.dart`
  - `lib/features/catalog/application/dashboard_controller.dart`
  - Every import of the moved files
- Test: `test/features/indexing/application/source_list_cleanup_activity_test.dart`,
  `test/features/shell/presentation/background_activity_strip_test.dart`, `library_menu_test.dart` (or wherever the
  menu is tested), `test/features/lifecycle/presentation/missing_files_test.dart`

**Interfaces:**
- Consumes: Task 4's uuid-keyed controller and `LibrariesView`.
- Produces:
  - `SourceListCleanupActivity`, a `SessionActivity` registered in `sessionActivitiesProvider`. Its `begin()` calls
    `settings.remove('librarySources')` when `settings.getString('librarySources') != null`, and swallows and logs any
    error.
  - `openLibrariesAndAdd(BuildContext, WidgetRef)`, in `lib/features/libraries/presentation/`: it selects
    `ShellDestination.libraries` and starts the add flow.
  - The Library menu has "Libraries" and "Add library…" (new keys `libraryMenuLibraries` and `libraryMenuAdd`).

- [ ] **Step 1: Write the failing tests.**
  - `GivenAStoredSourceList_WhenTheSessionBegins_ThenTheKeyIsRemoved`.
  - `GivenAMalformedSourceList_WhenTheSessionBegins_ThenTheKeyIsRemovedWithoutThrowing`. This is Review Focus 5: store
    `'{not json'`.
  - `GivenNoSourceList_WhenTheSessionBegins_ThenNothingIsWritten`.
  - `GivenAnActiveRunOfAKnownLibrary_WhenTheStripShows_ThenItIsNamedByTheLibrary`. This is Review Focus 4.
  - `GivenAnActiveRunOfAnUnknownLibrary_WhenTheStripShows_ThenItIsNamedByItsFolder`.
  - `GivenTheStrip_WhenViewAllTapped_ThenTheLibrariesDestinationIsSelected`.
  - `GivenTheLibraryMenu_WhenAddLibraryChosen_ThenTheAddFlowStarts`.
  - `GivenLibraries_WhenMissingFilesShows_ThenRootsComeFromTheLibraries`.

- [ ] **Step 2: Run them.** Expected: FAIL.

- [ ] **Step 3: Implement.**
  - Do the moves, deletions and rewiring above. The empty-state buttons call `openLibrariesAndAdd`.
  - `mostRecentRun` reads the uuid-keyed runs.
  - Run `GEN`, then `flutter analyze` until it is clean.
  - Search `lib test integration_test` for `LibrarySource`, `library_sources`, `indexStart` and `IndexScope`. Expected:
    no hits.

- [ ] **Step 4: Run the tests.** Run `TEST test` (the whole unit suite: a large deletion is where hidden users
  surface). Expected: PASS, apart from the shell goldens (the Music entry isn't added yet, so they should still
  match).

- [ ] **Step 5: Commit.** `refactor!: remove library sources`. The body says the 0.6 core indexes only libraries, and
  that the stored list is cleared at startup.

---

### Task 6: Integration tests on libraries (§7)

**Files:**
- Modify: `integration_test/catalog/listing_shape_test.dart`, `library_search_flow_test.dart`,
  `integration_test/libraries/library_boundary_test.dart`
- Create: `integration_test/libraries/library_index_test.dart`

**Interfaces:**
- Consumes: `CoreClient.libraryRegister` and `libraryIndexStart`, and the existing run-status polling helpers in
  `integration_test`.

- [ ] **Step 1: Rewrite the tests.**
  - Replace each `client.indexStart(root, …)` with registering a library over `root`, then polling the returned
    `runId`.
  - In `library_boundary_test`:
    - `GivenALibrary_WhenItsTypeIsListed_ThenItsFilesAreListed`.
    - `GivenALibrary_WhenRemoved_ThenItsFilesLeaveTheCatalog`.
  - In `library_index_test`:
    - `GivenAnIndexedLibrary_WhenScannedAgain_ThenANewRunCompletes`.
    - `GivenARunningLibrary_WhenScannedAgain_ThenConflict`.

- [ ] **Step 2: Run them.** Run `ci-check integration` (it builds the pinned core). Expected: PASS. This is the only
  task whose loop is `ci-check`; let it finish before starting anything else.

- [ ] **Step 3: Commit.** `test: index through libraries in integration`.

---

### Task 7: Audio type, tags on `CatalogFile`, names, album sort (§6)

**Files:**
- Modify:
  - `lib/features/catalog/domain/file_type.dart`, `catalog_file.dart`, `listing_view.dart`
  - `lib/features/catalog/data/file_view_parser.dart`
  - `lib/features/shell/domain/shell_destination.dart`, `lib/features/shell/presentation/shell_navigation_panel.dart`
  - `lib/features/catalog/presentation/catalog_search_view.dart` (`FileTypeLabel`), `catalog_listing.dart` (sort
    menu, Music row), `home_dashboard.dart`
  - `lib/features/lifecycle/presentation/delete_record_button.dart`, `missing_files_screen.dart`
  - `lib/features/libraries/presentation/library_tree_screen.dart` (file rows)
  - the arb files
- Create: `lib/features/catalog/domain/audio_tags.dart`, `lib/features/catalog/presentation/music_display_name.dart`
- Test: `test/features/catalog/domain/audio_tags_test.dart`, `listing_view_test.dart`,
  `test/features/catalog/data/file_view_parser_test.dart`, `music_display_name_test.dart`,
  `test/features/catalog/presentation/catalog_listing_test.dart`, the shell goldens

**Interfaces:**
- Produces:
  - `FileType.audio('audio')`, placed after `video`.
  - `ShellDestination.music`, placed after `videos`, with `fileTypeFor(music) == FileType.audio`.
  - `AudioTags` (freezed): `String? title`, `artist`, `album`, `albumArtist`, `genre`, `int? year`, `track`,
    `double? durationSeconds`.
  - `CatalogFile.audio`, an `AudioTags?` field, set by `fileFromFileView` for audio rows. It reads the subtype
    metadata keys `title`, `artist`, `album`, `albumArtist`, `genre`, `year` and `track`, and `durationSeconds`.
    Check the exact key placement against a real `FileView` sample from `alexandria_file_get_by_uuid` in the core's
    `crates/alexandria-ffi/tests/parity.rs`.
  - `SortField.album`, offered only for `FileType.audio`, and the default `ListingView` for audio.
    `ListingView.initialFor(FileType)` returns `album` for audio and `name` otherwise.
  - `String musicTitle(CatalogFile)`: the title, else the file name.
  - `String? musicByline(CatalogFile)`: artist · album, skipping empty parts, or null when both are empty.
  - `String displayName(CatalogFile)`: `musicTitle` for audio, `name` otherwise. Use it everywhere the spec lists:
    search hits, recent files, the delete confirmation, missing files, library tree rows, and the player bar (Task 9).
  - `String formatDuration(double seconds)`: `m:ss`, or `h:mm:ss` past an hour.

- [ ] **Step 1: Write the failing tests.**
  - `GivenAudioFileViewRow_WhenParsed_ThenTagsAndDurationAreRead`.
  - `GivenVideoRow_WhenParsed_ThenAudioIsNull`.
  - `GivenTracksOfTwoAlbums_WhenSortedByAlbum_ThenAlbumArtistAlbumTrackOrder`. Album artist "B" sorts before "a2" and
    "a10" case-insensitively. Track 2 comes before track 10, numerically.
  - `GivenNoAlbumArtist_WhenSortedByAlbum_ThenArtistIsUsed`.
  - `GivenUntaggedTracks_WhenSortedByAlbum_ThenTheySortLastByName`. This is Review Focus 3.
  - `GivenNoTitle_WhenNamed_ThenTheFileNameIsUsed`, and `GivenWhitespaceTitle_WhenNamed_ThenTheFileNameIsUsed`.
  - `GivenArtistOnly_WhenBylined_ThenJustTheArtist`.
  - `GivenTheMusicPanel_WhenListed_ThenRowsShowTitleBylineDuration`.
  - `GivenTheMusicPanel_WhenOpened_ThenItIsSortedByAlbum`.
  - `GivenAudioType_WhenTheViewIsSavedAndRead_ThenAlbumSurvives`.
  - Saved settings for other types still read.

- [ ] **Step 2: Run them.** Expected: FAIL.

- [ ] **Step 3: Implement.**
  - Panel: use the `Icons.library_music` and `Icons.library_music_outlined` icons, with the label key `navMusic`
    ("Music" / "Música").
  - Every exhaustive switch the compiler flags gets an audio case. `openFile` comes in Task 9: until then, audio
    falls back to the file details view.
  - Restore `LibraryFile`'s tags via `CatalogFile.audio` (no separate field).
  - Run `GEN`.
  - Regenerate the shell goldens in `aui-dev` with `flutter test --update-goldens test/features/shell`. Look at the
    images before committing them.

- [ ] **Step 4: Run the tests.** Run `TEST test`. Expected: PASS.

- [ ] **Step 5: Add an integration test for tags.** Create `integration_test/catalog/audio_tags_test.dart` with
  `GivenATaggedAudioFile_WhenItsLibraryIsIndexed_ThenItsTagsAreListed`.
  - It needs a tagged fixture: generate a 1-second FLAC under `integration_test/fixtures/` in `aui-dev`, with ffmpeg
    (`-metadata title=… artist=… album=… track=3`). Keep it under 50 KB, and commit it.
  - It runs in Task 11's `ci-check integration`. Don't run that check here.

- [ ] **Step 6: Commit.** `feat: list music by its tags`.

---

### Task 8: Audio tag editing (§6)

**Files:**
- Restore from `7697589^`, then adapt:
  - `lib/features/catalog/domain/music_metadata.dart`
  - `lib/features/catalog/application/music_metadata_editor.dart`
  - `lib/features/catalog/presentation/music_metadata_form.dart`
  - `test/features/catalog/domain/music_metadata_test.dart`
  - `test/features/catalog/presentation/music_metadata_form_test.dart`
- Modify:
  - `lib/features/catalog/domain/catalog_gateway.dart`, `lib/features/catalog/data/core_catalog_gateway.dart` (restore
    `editMusicMetadata` as it was in `7697589^`)
  - `lib/core/di/providers.dart` (`musicMetadataEditorProvider`)
  - `lib/features/catalog/presentation/file_details_view.dart` (`_metadataFormFor` audio case; the tags and duration
    shown; the Play button for audio)
  - the arb files (restore the `music*` editor keys from `7697589^`)
  - `test/support/fake_catalog_gateway.dart`

**Interfaces:**
- Produces:
  - `CatalogGateway.editMusicMetadata({required String uuid, required MusicMetadata patch, required String
    credential})`, returning `Future<MusicMetadataEditOutcome>`.
  - `MusicMetadata.toPatch()` returns `{'type':'audio', …}`.

- [ ] **Step 1: Restore the tests.** Restore both test files, and rename any old names to Given-When-Then. Add
  `GivenAnEditedTitle_WhenSaved_ThenTheListingAndDetailsShowIt`: after a successful edit, the editor invalidates the
  listing and the details, as the video editor does.

- [ ] **Step 2: Run them.** Expected: FAIL (the code isn't restored yet).

- [ ] **Step 3: Restore and adapt the code.** Match the current `VideoMetadataEditor`: its state, submit flow, and
  error mapping. Run `GEN`.

- [ ] **Step 4: Run the tests.** Run `TEST test/features/catalog`, plus the arb parity test. Expected: PASS.

- [ ] **Step 5: Commit.** `feat: edit a track's tags`.

---

### Task 9: Audio playback and the player bar (§6)

**Files:**
- Create:
  - `lib/features/playback/application/audio_playback_controller.dart`, `audio_playback_state.dart`
  - `lib/features/playback/presentation/player_bar.dart`
- Modify:
  - `lib/core/di/providers.dart`: `audioPlayerProvider` (a second `MediaKitPlayer`) and
    `audioPlaybackControllerProvider`
  - `lib/features/shell/presentation/shell_screen.dart`: the bar sits under the content while a track is loaded
  - `lib/features/catalog/presentation/file_details_view.dart`: `openFile` audio case
  - `lib/features/catalog/presentation/catalog_listing.dart` and `library_tree_screen.dart`: pass the queue
  - `lib/features/playback/application/video_playback_controller.dart`: pause the music on open
  - `lib/features/libraries/application/libraries_controller.dart`: drop the removed library's tracks
  - the arb files
- Test:
  - `test/features/playback/application/audio_playback_controller_test.dart`
  - `test/features/playback/presentation/player_bar_test.dart`
  - `test/support/fake_media_player.dart` (extend it if it needs an end-of-track signal)

**Interfaces:**
- Consumes:
  - `CoreClient.fileThumbnail` (Task 3), through a new `CoverGateway.cover(uuid, credential) → Future<Uint8List?>` in
    `lib/features/playback/domain/`, with a `CorePlaybackSourceGateway`-style data class.
  - `displayName`, `musicByline` and `formatDuration` (Task 7).
- Produces:
  - `AudioPlaybackState`: `List<CatalogFile> queue`, `int index`, `bool playing`, `Duration position`,
    `Duration? duration`, `Uint8List? cover`, `String? skippedName`, `Failure? failure`, and the getter `current`.
  - `AudioPlaybackController`:
    - `Future<void> play(CatalogFile file, List<CatalogFile> queue)`
    - `void togglePlaying()`
    - `Future<void> next()`
    - `Future<void> previous()`: restarts the track when past 3 seconds, else goes to the previous track.
    - `Future<void> seekTo(Duration)`
    - `Future<void> stop()`
    - `void pauseForVideo()`
    - `void dropLibrary(String libraryUuid)`: needs `CatalogFile.libraryUuid`. If `CatalogFile` doesn't carry it, add
      `String? libraryUuid` to `CatalogFile` in this task, parsed by `fileFromFileView`.
  - The queue keeps active audio files only: `play` filters `queue` to `type == audio && !isDeleted`, and
    always keeps `file` itself.

- [ ] **Step 1: Write the failing tests.**

  Controller tests:
  - `GivenAQueue_WhenPlayTheSecond_ThenItPlaysAndIndexIsOne`.
  - `GivenDeletedAndVideoFilesInTheList_WhenPlay_ThenTheQueueHoldsActiveAudioOnly`.
  - `GivenATrackEnds_WhenNotLast_ThenTheNextPlays`.
  - `GivenTheLastTrackEnds_WhenNoMore_ThenPlaybackStopsAtTheEnd`.
  - `GivenATrackFailsToOpen_WhenOthersRemain_ThenItIsSkippedAndNamed`.
  - `GivenEveryRemainingTrackFails_WhenPlay_ThenTheFailureShows`.
  - `GivenPastThreeSeconds_WhenPrevious_ThenTheTrackRestarts`.
  - `GivenAVideoOpens_WhenMusicIsPlaying_ThenMusicPauses`.
  - `GivenThePlayingTracksLibraryIsRemoved_WhenDropped_ThenPlaybackStopsAndItsTracksLeave`. This is Review Focus 2.
  - `GivenAQueuedTracksLibraryIsRemoved_WhenDropped_ThenTheCurrentTrackKeepsPlaying`.

  Bar tests:
  - `GivenATrackLoaded_WhenTheShellShows_ThenTheBarShowsTitleArtistAndCover`.
  - `GivenNothingLoaded_WhenTheShellShows_ThenNoBar`.
  - `GivenTheBar_WhenCloseTapped_ThenPlaybackStops`.
  - `GivenTheBar_WhenTitleTapped_ThenDetailsOpen`.

- [ ] **Step 2: Run them.** Expected: FAIL.

- [ ] **Step 3: Implement.**
  - The controller listens to the player's `status` stream for the position, the duration and completion.
  - It resolves each file through `PlaybackSourceGateway.resolve`, as the video controller does.
  - The cover is fetched per track. A null cover shows the music icon.
  - `openFile` for audio calls `play(file, queue)`, with the queue passed by the caller: the sorted, filtered Music
    listing, the folder's files in tree order, or `[file]` from search and details.
  - Use the existing playback hold (`playback_file_holds.dart`) for the current track if it applies without changing
    video's behaviour. Otherwise, skip it and note that in the commit body.
  - Run `GEN`.

- [ ] **Step 4: Run the tests.** Run `TEST test`. Expected: PASS.

- [ ] **Step 5: Commit.** `feat: play music from the library`.

---

### Task 10: Docs and changelog (§8)

**Files:**
- Modify:
  - `README.md`, `CHANGELOG.md`
  - `docs/requirements/System Requirements Document.md`, `Use Case Specification Document.md`,
    `Vision Document.md`, `Technology Stack Document.md`, `Operations & Infrastructure Document.md`
  - `docs/initial/Project Overview.md`, `Business Rules.md`, `Brainstorm.md`
  - the design's status line (set to `implemented`)

- [ ] **Step 1: Edit each place the spec's §8 and the research map list.**
  - The app is a library manager: add folders as libraries, browse them, open, play, or read.
  - Music is back as playable files with editable tags. There is no music management, which is Orpheus's.
  - The accepted core is `>=0.6.0 <0.7.0`.
  - Requirements and use cases that described library sources are rewritten for libraries. Keep their IDs where the
    meaning carries over, and mark retired ones "Removed (0.6 core)" as the docs already do for music.
  - `[Unreleased]`:
    - Changed: libraries are the only way in; removing a library deletes its records; the core is 0.6; and the
      stored source list is cleared at startup.
    - Added: the Music panel, the album sort, tag editing, and the player bar.
    - Removed: library sources and the index scope.

- [ ] **Step 2: Check for leftovers.** Run `grep -rn -i "library source\|index scope\|includeLibraries\|0\.5\.0
  <0\.6" README.md docs/requirements docs/initial`. Expected: only historical mentions marked as removed.

- [ ] **Step 3: Commit.** `docs: describe the app as a library manager`.

---

### Task 11: Full verification

- [ ] **Step 1: Run the checks, one at a time, in CI's images.** Run `ci-check analyze`, then `ci-check test`, then
  `ci-check integration`. Expected: each passes. Any diff in the generated files fails analyze: regenerate and
  commit.
- [ ] **Step 2: Clean up.** Stop `aui-dev` and remove it and its volumes, and remove any temporary directories.
