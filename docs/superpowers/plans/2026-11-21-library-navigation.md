# Library Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app starts without a login, and the left menu lists libraries (pinned first). A library opens as its
folders in the main area, libraries can be pinned, favorited and renamed, and home shows favorite libraries and
catalog totals. The docs site matches.

**Architecture:**
- **Bindings first.** Move to core 0.7 (no token anywhere), which forces the auth feature and every `credential`
  parameter out in one task.
- **Library data.** Pins, favorites, rename and stats are added to the library gateway and controller.
- **Shell.** `ShellDestination` becomes a sealed type with a `LibraryDestination(uuid)`, and the library folder view
  becomes that destination's content, reusing the listing's file widgets.
- **Home.** It is rebuilt on favorites and `catalogStats()`.

**Tech Stack:** Flutter 3.50.0, Riverpod, freezed, ffigen bindings over the core's C ABI, `flutter_test`,
`integration_test`, and Hugo + Docsy for alexandria-docs.

**Spec:** `docs/superpowers/specs/2026-11-21-library-navigation-design.md`. The core side is in alexandria-api
`docs/superpowers/specs/2026-11-21-no-authentication-design.md`.

## Global Constraints

- **Precondition:** the alexandria-api no-authentication pull request is merged into its `develop`, and the merge
  commit is on the GitHub mirror. `CORE_REF` pins that commit. It moves to the `v0.7.0` merge commit at release
  time, which is not part of this plan.
- **Branch:** `feature/library-navigation` (already holds the design commits). Open the pull request into
  `develop`. alexandria-docs gets its own `feature/library-navigation` from `main`, with a pull request into `main`.
- **Commits:**
  - lowercase Conventional Commits, a subject of at most 50 characters in the imperative, a body wrapped at 72;
  - no attribution lines.
- **Tests:**
  - write the failing test first;
  - Given-When-Then test names, as the suite already does (`'given …, when …, then …'` descriptions);
  - fakes live in `test/support/`.
- **Running checks:**
  - `flutter analyze` runs locally;
  - tests run through `ci-check test ~/repositories/alexandria-ui` and
    `ci-check integration ~/repositories/alexandria-ui`, because this machine lacks GTK;
  - one heavy suite at a time.
- **Core range:** `CoreVersionRange.minimum = '0.7.0'`, `exclusiveMaximum = '0.8.0'`.
- **New core calls:**
  - `alexandria_library_set_pinned(uuid, bool) -> int`;
  - `alexandria_library_set_favorite(uuid, bool) -> int`;
  - `alexandria_library_rename(uuid, json {"name"}) -> LibraryJsonResult`;
  - `alexandria_catalog_stats_json() -> LibraryJsonResult`, whose body is
    `{"libraries": n, "filesByType": {"audio","video","html","text","document","comic","image": n}}`.
- **Library codes:** 0 ok, 1 invalid input, 3 not initialized, 4 not found, 6 conflict, 9 other. Code 2 is retired.
- **Menu order:**
  1. Home.
  2. Bookmarks.
  3. The pinned libraries, A–Z.
  4. A divider, only if both groups are non-empty.
  5. The others, A–Z.

  A–Z is case-insensitive, with the comparison the listings already use for names.
- Every user-visible string is in both `lib/core/l10n/app_en.arb` and `app_pt.arb`.

## Review Focus

1. **The library being viewed is renamed, or removed from Manage libraries.** A rename updates the header and the
   menu in place. A removal sends the shell to Home, with no error screen. Tasks 3 and 5 pin it.
2. **Pin or favorite clicked twice quickly, or the core refuses it.** The entry ends in the core's state, never
   flickers into a state the core didn't store, and a refusal shows the snackbar. Task 3 pins it.
3. **A library with hundreds of files in one folder, at the narrowest window.** The folder view scrolls with the
   builder listing (no full build), and the toolbar wraps instead of overflowing. Task 4 pins it with an overflow-free
   test at the minimum window size.
4. **Home when stats fail but favorites load, and when there are favorites but zero files.** Each section stands
   alone, and all seven type rows show `0`. Task 6 pins it.
5. **An update started while an edit is unsaved, now that there's no sign-out controller.** The unsaved-changes
   question is still asked. Task 1 pins it.

---

### Task 1: Core 0.7 bindings, and the login out of the app

**Files:**
- Modify:
  - `ci/pins.sh` (`CORE_REF` and its comment);
  - `native/include/alexandria_ffi.h` (vendored from the pinned core's `crates/alexandria-ffi/src/header.h`);
  - `lib/core/bindings/alexandria_bindings.dart` (regenerated with ffigen, the command in CONTRIBUTING);
  - `lib/core/bindings/core_client.dart`, its FFI implementation and `core_isolate.dart` (every `token` parameter
    and every `auth*` method removed);
  - the core version range file (`CoreVersionRange`);
  - `core_status_mapper.dart` (no code-2 arms);
  - `core_environment.dart` (no `ALEXANDRIA_AUTH_MODE`);
  - every gateway under `lib/features/*/data` and `lib/features/*/domain/*_gateway.dart` (the `credential` parameter
    removed; about 69 files reference `credential`, and `rg -l credential lib` lists them);
  - every controller that read `sessionControllerProvider`;
  - `lib/app.dart` (no `SessionRouteGuard`);
  - `lib/core/startup/*` (ends at the shell);
  - `lib/core/di/providers.dart`;
  - `lib/features/shell/presentation/settings_menu.dart` (Preferences only);
  - `lib/features/updates/application/update_close.dart`;
  - `app_en.arb`/`app_pt.arb` (auth strings removed);
  - `integration_test/all_suites.g.dart`.
- Delete:
  - `lib/features/auth/`;
  - `test/features/auth/`;
  - `integration_test/auth/`;
  - `test/support/fake_auth_gateway.dart`.
- Rename:
  - `SessionActivity` → `AppActivity`, `sessionActivitiesProvider` → `appActivitiesProvider`,
    `test/support/fake_session_activity.dart` → `fake_app_activity.dart`;
  - the activity classes keep their names (for example `CatalogSessionActivity`) unless the builder renames them in
    the same commit.
- Test:
  - `test/core/startup/`;
  - `test/features/updates/`;
  - a new `test/core/di/app_activities_test.dart`;
  - every test file touching `credential` or the session.

**Interfaces:**
- Produces:
  - `CoreClient` without tokens, and
    `Future<CoreJsonResponse> libraryRename(String uuid, String jsonBody)`, `Future<int> librarySetPinned(String
    uuid, bool pinned)`, `Future<int> librarySetFavorite(String uuid, bool favorite)` and `Future<CoreJsonResponse>
    catalogStats()`;
  - every gateway method without `credential`, for example `LibraryGateway.browse()` and
    `LibraryGateway.move(uuid:, rootPath:)`;
  - `appActivitiesProvider` (`Provider<List<AppActivity>>`);
  - `bool holdsUnsavedChanges(Ref ref)` or an equivalent on an `AppActivities` helper, read by `closeForUpdate`.

- [ ] **Step 1: Re-pin and regenerate.**
  - Set `CORE_REF` to the core's develop merge commit and vendor the header.
  - Regenerate the bindings, and set the version range.
  - The build now fails, as expected.
- [ ] **Step 2: Write the failing tests.**
  - `test/core/startup`: `given a fresh catalog, when startup finishes, then the shell is the first screen` and
    `given an existing catalog, when startup finishes, then the shell is the first screen` (no sign-up or login
    widget is found).
  - `test/core/di/app_activities_test.dart`: `given startup finished, when the app is ready, then every app activity
    has begun once`.
  - `test/features/updates`: `given an activity holds unsaved changes, when closing for an update, then the
    unsaved-changes question is asked`. This adapts the existing case, which used `SignOutController`.
- [ ] **Step 3: Remove everything listed** under Files, making the tests compile against token-free fakes.
  - `FakeCoreClient` loses its auth methods and gains the four new ones (recording calls, answering configurable
    results).
  - The activities begin where the session used to begin them: when the startup controller reaches ready.
  - They end where the update close and exit already end them.
- [ ] **Step 4: Run** `flutter analyze`, then `ci-check test ~/repositories/alexandria-ui`.
  Expected: no issues, and all tests pass.
  - `rg -n -i 'sign.?up|log.?in|recovery|credential|session' lib --glob '!*.g.dart' --glob '!*.freezed.dart'` shows
    nothing about auth. Playback "session" wording, if any, is unrelated.
- [ ] **Step 5: Commit**: `feat!: start without a login on core 0.7`.

### Task 2: Pins, favorites, rename and stats in the library data

**Files:**
- Modify:
  - `lib/features/libraries/domain/library.dart` (`Library` gains `@Default(false) bool pinned`,
    `@Default(false) bool favorite`; then `build_runner`);
  - `library_gateway.dart`;
  - `lib/features/libraries/data/core_library_gateway.dart`;
  - `lib/features/libraries/application/libraries_controller.dart`;
  - `test/support/fake_library_gateway.dart`.
- Create:
  - `lib/features/libraries/domain/catalog_stats.dart` (`CatalogStats({required int libraries, required
    Map<FileType, int> filesByType})`);
  - `lib/features/libraries/application/catalog_stats_controller.dart`;
  - `lib/features/libraries/presentation/rename_library.dart`.
- Test:
  - `test/features/libraries/data/core_library_gateway_test.dart`;
  - `test/features/libraries/application/libraries_controller_test.dart`;
  - `test/features/libraries/application/catalog_stats_controller_test.dart`;
  - `test/features/libraries/presentation/rename_library_test.dart`.

**Interfaces:**
- Consumes: Task 1's `CoreClient` methods.
- Produces:
  - `LibraryGateway.setPinned({required String uuid, required bool pinned}) -> Future<LibraryWrite>`;
  - `setFavorite({required String uuid, required bool favorite})`;
  - `rename({required String uuid, required String name}) -> Future<LibraryWrite>`;
  - `stats() -> Future<CatalogStats>` (throws the mapped `Failure`, as reads do);
  - `LibrariesController.setPinned(String uuid, bool pinned) -> Future<Failure?>`, `setFavorite(...)` and
    `rename(String uuid, String name) -> Future<Failure?>`, each reloading the list on success;
  - `catalogStatsProvider` (`AsyncNotifierProvider<CatalogStatsController, CatalogStats>`, with `reload()`);
  - `Future<void> renameLibrary(BuildContext context, WidgetRef ref, Library library)`, which opens
    `LibraryNameDialog` prefilled with `library.name`, all selected, and Confirm disabled while blank. On a
    `Failure`, the dialog stays open with the message.

- [ ] **Step 1: Write the failing tests.**
  - **Gateway:**
    - parses `pinned`/`favorite` from list and browse JSON, and their absence defaults to `false`;
    - maps `setPinned` codes `0`, `4` and `1` to success, not found and invalid input;
    - sends `{"name":"New"}` to `libraryRename`;
    - parses stats into all seven `FileType`s.
  - **Controller:**
    - `given a library, when pinned, then the core is called and the list reloads pinned`;
    - `given the core refuses, when favorited, then the failure is returned and the list is unchanged`.
  - **Stats controller:**
    - `given stats, when loaded, then libraries and every type are present`;
    - `given a failure, when loaded, then the state is an error and reload retries`.
  - **Rename dialog:**
    - `given a library, when rename opens, then its name is prefilled and selected`;
    - `given a blank name, then Confirm is disabled`;
    - `given the core refuses, when confirmed, then the dialog stays open showing the message`;
    - `given a run in progress, when renamed, then the rename is sent`.
- [ ] **Step 2: Run** `ci-check test ~/repositories/alexandria-ui`.
  Expected: FAIL (missing members).
- [ ] **Step 3: Implement** with the signatures above.
  - `CatalogStatsController` is watched for invalidation where the type counts were refreshed today: run finished,
    library added or removed.
- [ ] **Step 4: Run** `flutter analyze` and `ci-check test ~/repositories/alexandria-ui`.
  Expected: PASS.
- [ ] **Step 5: Commit**: `feat: pin, favorite and rename libraries`.

### Task 3: Libraries in the left menu

**Files:**
- Modify:
  - `lib/features/shell/domain/shell_destination.dart` (a sealed `ShellDestination` with `HomeDestination`,
    `BookmarksDestination` and `LibraryDestination(String uuid)`; `initial` is Home);
  - `lib/features/shell/application/shell_controller.dart`;
  - `lib/features/shell/presentation/shell_navigation_panel.dart`;
  - `shell_screen.dart` (`ShellContentArea` switches on the sealed type; a missing library goes to Home);
  - `lib/features/catalog/domain/file_type.dart` (drop `fileTypeFor(destination)`).
- Test:
  - `test/features/shell/presentation/shell_navigation_panel_test.dart`;
  - `test/features/shell/application/shell_controller_test.dart`.

**Interfaces:**
- Consumes: `librariesControllerProvider` with flags, and Task 2's `setPinned`, `setFavorite` and `renameLibrary`.
- Produces: `ShellDestination` as above, and
  `List<Library> menuOrder(List<Library> libraries)` (pinned A–Z then others A–Z) in
  `lib/features/shell/domain/menu_order.dart`.

- [ ] **Step 1: Write the failing tests.**
  - **`menuOrder`:**
    - `given b, A (pinned), c, B (pinned), when ordered, then A, B, b, c`;
    - `given no pinned, then A–Z only`.
  - **Panel:**
    - the entries read Home, Bookmarks, pinned, divider, others;
    - no divider with zero pinned, or with all pinned;
    - no file-type entries (`find.text('Videos')` finds nothing);
    - with no libraries, a single "Add library" entry, and tapping it calls `openLibrariesAndAdd`;
    - a context menu on an entry shows Pin, Add to favorites and Rename…;
    - choosing Pin calls `setPinned(uuid, true)`, and the entry moves into the pinned group;
    - a refused pin shows the snackbar and the entry stays put;
    - at the icons-only tier, each library has a tooltip with its name;
    - at the minimum window size with 40 libraries, there's no overflow and the last library is reachable by
      scrolling.
  - **Shell:**
    - `given the selected library is removed, when the list reloads, then the destination is Home`;
    - `given the selected library is renamed, then the header and menu show the new name`.
- [ ] **Step 2: Run** `ci-check test ~/repositories/alexandria-ui`.
  Expected: FAIL.
- [ ] **Step 3: Implement.**
  - The panel keeps its `LayoutBuilder` + `SingleChildScrollView` + `IntrinsicHeight` structure.
  - Library entries use `Icons.folder_outlined`/`Icons.folder`, with a pin badge when pinned.
  - The context menu is a `MenuAnchor` opened on secondary tap and long press.
  - Remove the per-type count badges and `_CountedIcon`.
- [ ] **Step 4: Run** `flutter analyze` and `ci-check test ~/repositories/alexandria-ui`.
  Expected: PASS.
- [ ] **Step 5: Commit**: `feat!: list libraries in the left menu`.

### Task 4: A library's folders in the main area

**Files:**
- Create:
  - `lib/features/libraries/presentation/library_view.dart` (the destination's content: header, breadcrumbs,
    toolbar, folders, files);
  - `lib/features/libraries/application/library_view_controller.dart` (per-library open folder, in memory);
  - `lib/features/libraries/application/library_view_preferences.dart` (layout, type filter, sort and direction,
    stored under settings key `libraryView`);
  - `lib/features/catalog/presentation/file_tiles.dart` (the grid, list and row widgets extracted from
    `catalog_listing.dart`).
- Modify: `catalog_search_view.dart` (uses `file_tiles.dart` if it used listing widgets).
- Delete:
  - `lib/features/catalog/presentation/catalog_listing.dart`;
  - `lib/features/libraries/presentation/library_tree_screen.dart`;
  - `lib/features/catalog/application/listing_view_controller.dart`, plus their tests, if nothing else reads them.
- Test:
  - `test/features/libraries/presentation/library_view_test.dart`;
  - `test/features/libraries/application/library_view_controller_test.dart`.

**Interfaces:**
- Consumes: `LibraryGateway.read(uuid:, path:)` (browse), `sortFiles(files, ListingView)`,
  `AudioPlaybackController.play(file, queue)`, `renameLibrary`, and the existing move/remove/scan flows from
  `libraries_view.dart`.
- Produces: `LibraryView({required String uuid})`, and
  `LibraryViewController.openFolder(String uuid, String path)` and `.folderOf(String uuid) -> String`.

- [ ] **Step 1: Write the failing tests.**
  - **Breadcrumbs and folders:**
    - opening a folder shows its contents and a crumb, and tapping the root crumb returns to the top;
    - folders come before files, A–Z.
  - **Toolbar:**
    - the type filter set to Comic shows only comic files;
    - the sort by name descending reverses the order;
    - grid and list switch the layout;
    - the choices persist through `libraryView`.
  - **Folder memory:**
    - `given folder X open in library 1, when Home then library 1 are selected, then X is still open`.
  - **Files and their actions:**
    - a file row offers the same actions the type listing offered (details, open, rename, delete), using the
      extracted widgets;
    - tapping an audio file calls `play(file, queue)`, where `queue` is the folder's audio files in the shown
      order.
  - **Empty states:**
    - an empty folder shows "Nothing in this folder";
    - with a filter that matches nothing, "No comic books in this folder" and a Clear filter button.
  - **Header:**
    - shows the name and the Pin and Favorite toggles, which call `setPinned` and `setFavorite`;
    - its menu has Rename, Scan again, Move and Remove;
    - it shows the run status.
  - **Size:**
    - at the minimum window, with 500 files in a folder, there's no overflow and only visible rows are built
      (assert `find.byType(<row widget>)` count < 500).
- [ ] **Step 2: Run** `ci-check test ~/repositories/alexandria-ui`.
  Expected: FAIL.
- [ ] **Step 3: Implement.**
  - Extract the tile and row widgets first, with no behaviour change. The existing listing tests are moved onto
    `file_tiles.dart` and must pass unchanged.
  - Then build `LibraryView` and delete the type listing.
- [ ] **Step 4: Run** `flutter analyze` and `ci-check test ~/repositories/alexandria-ui`.
  Expected: PASS.
- [ ] **Step 5: Commit**: `feat: browse a library in the main area`.

### Task 5: Library management in the menu bar

**Files:**
- Modify:
  - `lib/features/shell/presentation/library_menu.dart` (a "Libraries" heading first, with Add library… and Manage
    libraries…);
  - `lib/features/libraries/presentation/libraries_view.dart` (shown as a dialog; a Rename action per row through
    `renameLibrary`).
- Test:
  - `test/features/shell/presentation/library_menu_test.dart`;
  - `test/features/libraries/presentation/libraries_view_test.dart`.

**Interfaces:**
- Consumes: `openLibrariesAndAdd`, `renameLibrary`, `LibrariesController`.
- Produces: `Future<void> openManageLibraries(BuildContext context)`.

- [ ] **Step 1: Write the failing tests.**
  - The menu shows the Libraries heading first. Add library… starts the add flow. Manage libraries… opens the
    dialog.
  - The dialog lists every library with Rename, Scan again, Move and Remove. Rename renames and the row updates.
  - Remove keeps today's confirmation wording, which says the catalog records are deleted.
  - `given library 1 is shown in the main area, when it is removed from Manage libraries, then the shell goes Home`.
- [ ] **Step 2: Run** `ci-check test ~/repositories/alexandria-ui`.
  Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter analyze` and `ci-check test ~/repositories/alexandria-ui`.
  Expected: PASS.
- [ ] **Step 5: Commit**: `feat: manage libraries from the menu bar`.

### Task 6: The home screen

**Files:**
- Modify: `lib/features/catalog/presentation/home_dashboard.dart` (sections `_FavoritesSection` and
  `_StatisticsSection`; `_FirstRun` kept).
- Delete:
  - `_RecentSection`, `_InProgressSection`, `_CountsSection` and `_LastRunSection`;
  - `RecentFilesController`, `mostRecentRun`, `IndexRunSummary`, the in-progress providers and
    `typeCountsControllerProvider`, plus their tests, wherever nothing else reads them (`rg` before each deletion).
- Test: `test/features/catalog/presentation/home_dashboard_test.dart`

**Interfaces:**
- Consumes: `librariesControllerProvider` (favorites), `catalogStatsProvider`, and `shellControllerProvider` to open
  a library.

- [ ] **Step 1: Write the failing tests.**
  - **Favorites:**
    - `given favorites Zeta and alpha, then the cards read alpha, Zeta`;
    - a card shows the name and root path, and tapping it selects `LibraryDestination(uuid)`;
    - with no favorites, "Mark a library as a favorite to see it here".
  - **Statistics:**
    - "3 libraries", plus seven rows (videos, music, books, comic books, notes, pages, images) with their counts,
      zeroes included;
    - `given stats fail and favorites load, then the favorites render and the statistics show an error with
      Retry, and Retry reloads`.
  - **First run:** no libraries shows `_FirstRun` with Add library.
  - **Removed sections:** recent, in progress and last run are not on screen.
- [ ] **Step 2: Run** `ci-check test ~/repositories/alexandria-ui`.
  Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter analyze` and `ci-check test ~/repositories/alexandria-ui`.
  Expected: PASS.
- [ ] **Step 5: Commit**: `feat!: show favorites and totals on home`.

### Task 7: Integration test

**Files:**
- Create: `integration_test/libraries/library_navigation_test.dart`
- Modify: `integration_test/all_suites.g.dart` (however it is regenerated, as CONTRIBUTING says).

- [ ] **Step 1: Write the test.** Against the real core:
  1. Start; the shell shows with no login.
  2. Add a fixture folder as a library and wait for its run.
  3. The library appears in the left menu.
  4. Pin it: it is first among libraries.
  5. Favorite it: home lists it.
  6. Rename it: the menu and home show the new name.
  7. Open it: its folders show.
  8. The home statistics count its files.
- [ ] **Step 2: Run** `ci-check integration ~/repositories/alexandria-ui`.
  Expected: PASS, along with the rest of the integration suites.
- [ ] **Step 3: Commit**: `test: cover library navigation end to end`.

### Task 8: This repository's docs

**Files:**
- Modify:
  - `README.md`;
  - `CHANGELOG.md` (`[Unreleased]`);
  - `docs/requirements/*.md`;
  - `docs/initial/*.md`.

- [ ] **Step 1:** Make the changes listed in the spec §8, "This repository", item by item.
  - The CHANGELOG has Removed, Changed and Added as listed.
  - "The two repositories agree" says `>=0.7.0 <0.8.0`.
- [ ] **Step 2:** `rg -n -i 'sign up|sign-up|log in|login|recovery code|password|per-type|navigation panel' README.md
  docs/requirements docs/initial`.
  Expected: only withdrawn records, or updated text.
- [ ] **Step 3: Commit**: `docs: describe library navigation without login`.

### Task 9: The docs site (alexandria-docs)

**Files:**
- Modify:
  - `content/en/docs/usage/_index.md`;
  - `content/en/docs/architecture/_index.md`;
  - `content/en/docs/installation/_index.md`;
  - `content/en/docs/overview/_index.md`;
  - `content/en/about/_index.md`;
  - `content/en/_index.md`.

- [ ] **Step 1:** In `~/repositories/alexandria-docs`, `git switch -c feature/library-navigation` from an
  up-to-date `main`. Follow its CONTRIBUTING if it has one.
- [ ] **Step 2:** Make the changes in the spec §8, "alexandria-docs", page by page. The architecture diagram keeps
  only the desktop subgraph.
- [ ] **Step 3:** `npm ci`, then `PATH=$PWD/node_modules/.bin:$PATH hugo`.
  Expected: builds with no errors or warnings about broken `relref`s. Also run
  `rg -n -i 'heimdall|log in|login|recovery|REST|alexandria-http|sign up' content`, and expect nothing.
- [ ] **Step 4: Commit**: `docs: describe the app without a login`. Push, and open the pull request into `main`.
  - Its body says the pull request is to be merged when app 3.0.0 is released.

### Task 10: Pull request

- [ ] **Step 1:** Run `flutter analyze`, `ci-check test` and `ci-check integration` on the final branch.
  Expected: all pass.
- [ ] **Step 2:** Push `feature/library-navigation` and open the pull request into `develop`. The body covers:
  - what changes and why;
  - how it was tested;
  - the core commit pinned, and that release needs `v0.7.0`;
  - the docs-site pull request link;
  - that it ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- [ ] **Step 3:** Wait for every Jenkins and GitHub check to be green. Merge only when the owner approves it in the
  conversation.
