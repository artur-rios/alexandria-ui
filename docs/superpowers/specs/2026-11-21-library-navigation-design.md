# No login, libraries in the left menu, pinned and favorite libraries, a new home

**Date:** 2026-11-21
**Status:** approved
**Core:** alexandria-api 0.7.0 (`docs/superpowers/specs/2026-11-21-no-authentication-design.md` there)

## Why

Alexandria is a desktop library manager for local files on Windows and Linux. Nothing connects to it over a
network, so a login protects nothing. The owner wants it gone: "it makes no sense". Core 0.7.0 removes
authentication entirely, including the `token` on every FFI call. The app has to follow.

The owner also wants the app navigated by library, because libraries are folders they chose and the folders are how
they know where things are. Today the left menu has one entry per file type (Videos, Music, Books, Comic books,
Notes, Pages, Images), plus Home, Bookmarks and Libraries, and a library opens in a dialog. The owner wants instead:

- the libraries in the left menu, with no entries by file type;
- libraries that can be pinned to the top of that menu;
- libraries that can be marked as favorites;
- a home screen that shows the favorite libraries A–Z, the number of libraries, and the number of files of each type.

The docs site (alexandria-docs) has to describe the app as it will be.

## Goals

- The app starts straight into the shell. There is no sign-up, login, recovery code, credentials change or sign-out
  anywhere.
- The left menu is, top to bottom:
  1. Home.
  2. Bookmarks.
  3. The pinned libraries, A–Z.
  4. A divider.
  5. The other libraries, A–Z.

  There are no file-type entries.
- Clicking a library opens it in the main area as its folders: breadcrumbs, folders first, then files. It has grid
  and list layouts, a type filter (all, or one type) and the sort choices.
- Every library can be pinned or unpinned and favorited or unfavorited. You do this from its entry in the left menu
  and from its page header. The choice is stored by the core and survives restarts.
- Home shows the favorite libraries, A–Z, and the totals: how many libraries, and how many files of each type.
- A library can be renamed at any time, even while it is being scanned. This is new: today a library's name is set
  only when it is added. Renaming is offered from the library's entry in the left menu, from its page header and from
  Manage libraries.
- Adding, renaming, moving, rescanning and removing libraries moves to the menu bar.
- The app accepts core `0.7.x` only and builds against core 0.7.0.
- The docs describe the new behaviour:
  - this repository's README, CHANGELOG, `docs/requirements` and `docs/initial`;
  - the alexandria-docs site.
- The release is alexandria-ui 3.0.0: removing the login and the type pages is a breaking change for the owner's
  habits, and the core range changes.

## Non-goals

- No other access control (no PIN, no lock screen).
- No custom ordering of libraries (no drag to reorder). Pinned and unpinned libraries are each sorted A–Z.
- No per-library statistics on home, and no file counts on the left-menu entries.
- Recent files, in-progress files and the last scan are no longer on home (the owner's call). Resume positions
  still work: a video still resumes where it stopped.
- No change to search: the menu-bar search still searches every library.
- No change to collections, watchlists, reading lists, deleted items or the missing-files review. They stay in the
  menu bar.

## Anti-goals

- No trace of the login may remain: no screen, menu entry, setting, string, stored value or route.
- Nothing a type page let the owner do to a file may be lost. A file in a library folder can be opened, played,
  read, edited, renamed, deleted and shown in detail, the same as on a type page today.
- At the narrowest window the left menu must not drop a library or clip it. It scrolls, as the rail already does.
- Home must not show a zero it couldn't count. A failed query shows its own failure and retry, as the dashboard
  sections do today.

## Approaches

**What opening a library shows.** The owner picked **A**:

- **A. The library's folders, in the main area.** The folder view that exists today, moved out of its dialog, with
  the type pages' layout, filter and sort controls brought over. It matches how the owner organised the files on disk.
- **B. Every file in the library in one flat listing, with a type filter.** Finding things by type is quicker, but
  the folder structure is lost unless you search.

**The core's HTTP server.** The owner picked removing it with all authentication. See the core design.

The other calls below were proposed and accepted by the owner: fixed Home and Bookmarks entries, library management
in the menu bar, pinned-first then A–Z, flags stored by the core, totals across every library, and home showing only
favorites and totals.

## Design

### 1. Core pin, bindings and version range

- `ci/pins.sh`: `CORE_REF` becomes the alexandria-api commit the app is built against. During development that is
  the core's develop merge commit of the no-authentication change, and the `v0.7.0` merge commit before the app's
  release. It has to be on the GitHub mirror, as the comment there says.
- Vendor `native/include/alexandria_ffi.h` from that core, and regenerate `lib/core/bindings/alexandria_bindings.dart`
  with ffigen.
- `CoreVersionRange`: `minimum = '0.7.0'`, `exclusiveMaximum = '0.8.0'`. The doc comment says why: 0.7 removed
  authentication and the token from every call, so an older core can't be called correctly.
- `CoreClient` and the core isolate:
  - Remove the token parameter from every call.
  - Remove the auth calls.
  - Add `librarySetPinned(uuid, pinned)`, `librarySetFavorite(uuid, favorite)`, `libraryRename(uuid, name)` and
    `catalogStats()`. `catalogStats()`
    reads a `LibraryJsonResult` and maps its status like the other library calls.
- `core_status_mapper.dart`: drop the unauthorized mappings (code 2 is retired in every family). Keep every other
  mapping.
- `core_environment.dart`: stop setting `ALEXANDRIA_AUTH_MODE` and anything else auth-related.

### 2. The login out of the app

- Delete `lib/features/auth/` and its tests.
- Delete everything outside it that only exists for auth:
  - `SessionRouteGuard` around `home`;
  - the session state and the token threaded through controllers and gateways;
  - the Settings menu's "Change credentials" and "Sign out" (the Settings menu keeps Preferences);
  - the auth strings in `app_en.arb` and `app_pt.arb`;
  - any stored setting that remembered an account.
- **Session activities become application activities.** Today they begin when the owner signs in and end when they
  sign out. They now begin once startup finishes (the core is initialized) and end when the app closes for an update
  or exits:
  - catalog, indexing, editing, playback, the update check.
- `closeForUpdate` reads "holds unsaved changes" from the activities directly instead of from
  `SignOutController`. Its behaviour doesn't change.
- Rename `sessionActivitiesProvider` and `SessionActivity` to `appActivitiesProvider` and `AppActivity`. The builder
  can keep the old names if a rename would bury the change in noise.
- Startup: `StartupController` ends at the shell. The step that decided between sign-up and login is gone.

### 3. The left menu

`ShellDestination` stops being an enum of types. It becomes a sealed type:

- `HomeDestination`
- `BookmarksDestination`
- `LibraryDestination(uuid)`

The initial destination is Home.

`ShellNavigationPanel` lists:

1. Home and Bookmarks, with their current icons.
2. The pinned libraries, A–Z by name (case-insensitive, locale-aware as the listings already sort).
3. A divider, only when both groups are non-empty.
4. The other libraries, A–Z.

Each library entry:

- Shows the folder icon, with a small pin badge when pinned, and the library's name as its label. At the
  icons-only tier, the tooltip is the name. A letter avatar instead of the icon is the builder's choice if it reads
  better.
- Has a context menu (right-click, and long-press) with Pin/Unpin, Add to favorites/Remove from favorites, and
  Rename…. The menu shows a star when the library is a favorite.
- When the library being viewed is removed, the shell goes to Home.
- Library data comes from `LibrariesController`, which already lists libraries. It now carries `pinned` and
  `favorite`.
- A pin or favorite change calls the core, then reloads the list. If the core refuses, the change isn't shown, and a
  snackbar says it couldn't be saved.
- The panel keeps its scroll behaviour (FR-UX-02), so a long list scrolls rather than clips.
- With no libraries, the libraries part of the panel shows a single "Add library" entry that starts the add flow.

### 4. A library in the main area

`LibraryTreeScreen` stops being a dialog, and its folder browsing becomes the content of `LibraryDestination`:

- **Header:**
  - the library name, with Pin and Favorite toggle buttons beside it;
  - a menu with Rename, Scan again, Move and Remove (Rename is new, see below; the others are the existing flows
    from `LibrariesView`);
  - the library's run status line, as `LibrariesView` shows it today.
- **Breadcrumbs:** library root ▸ folder ▸ folder. Each crumb opens that level.
- **Toolbar:** the layout switcher (grid and list, from `CatalogListing`'s `_LayoutBar`), a type filter (All plus
  the seven types), and the sort choices from `CatalogListing`'s filter controls. They apply to the files of the open
  folder. Folders always come first, sorted A–Z.
- **Files:** drawn with the same tiles and rows `CatalogListing` uses, so open, play, read, details, edit, rename and
  delete work as they do on a type page today. Extract the shared widgets out of `CatalogListing` rather than
  duplicating them.
- The open folder is kept per library while the app runs. Leaving and coming back returns to the same folder. It
  isn't saved across restarts.
- The layout, filter and sort are one choice for every library, remembered the way the listing's layout is today.
- Playing music: next and previous go through the audio files of the open folder, in the shown order. This replaces
  "the list the track was started from".
- Empty folder: "Nothing in this folder". A folder with files, none of the chosen type: "No <type> in this folder",
  with a button to clear the filter.

`CatalogListing` and the type-specific empty states go if nothing else uses them once the widgets are shared. Search
results keep whatever listing widgets they use.

### 5. Library management in the menu bar

`LibraryMenu` gains a "Libraries" heading, first:

- **Add library…** runs the existing add flow (`openLibrariesAndAdd`).
- **Manage libraries…** opens today's `LibrariesView` as a dialog: every library with its run, rename, scan again,
  move and remove.

Removing a library keeps today's confirmation, which says plainly that its catalog records are deleted.

### 5a. Renaming a library

- **Offered in three places:** the left-menu entry's context menu, the library page header's menu, and its row in
  Manage libraries. It is enabled whatever the library's run is doing.
- **The dialog:** `LibraryNameDialog`, opened with the current name filled in and selected. Confirm is disabled while
  the field is blank, the same rule as when a library is added.
- **Saving:** calls `libraryRename(uuid, name)` (`alexandria_library_rename`), then reloads the libraries. The left
  menu, the page header, the home favorites and Manage libraries all show the new name, and the menu sorts it again.
- **If the core refuses:** the dialog stays open and shows the core's message.

### 6. Home

`HomeDashboard` keeps the AF-03 pattern (each section loads and fails on its own) and has two sections:

- **Favorites:**
  - The favorite libraries, A–Z, as cards: name, root path, run status if one is running. Clicking a card opens the
    library.
  - With none: "Mark a library as a favorite to see it here", and a short hint about where the star is.
- **Statistics:**
  - "N libraries", and a row per type with its count: videos, music, books, comic books, notes, pages, images. All
    seven are shown, zeroes included, because the core answers every type.
  - From `catalogStats()`. On failure, the section shows the error and a retry.
  - It refreshes when a run finishes or a library is added or removed, as the type counts do today.

First run (no libraries) stays a whole-screen guidance with "Add library", as today's `_FirstRun`.

The recent, in-progress, counts and last-run sections, and their controllers, are deleted once nothing else reads
them. `typeCountsControllerProvider` goes too if the panel badges were its last reader.

### 7. Tests

Failing tests first, Given-When-Then names as in the rest of the suite. Widget and unit tests, with a fake core
client:

- **Startup:** the shell is the first screen after initialization, with no login, for a fresh and an existing
  catalog.
- **Left menu:**
  - the order Home, Bookmarks, pinned A–Z, divider, others A–Z;
  - no divider when one group is empty;
  - the empty state;
  - pin and favorite from the context menu calling the core and moving the entry;
  - a refused change staying unchanged with a snackbar;
  - the removed-library-goes-home case.
- **Library view:**
  - breadcrumbs navigate;
  - folders come before files;
  - the type filter, sort and layout apply;
  - a file's actions are present;
  - next and previous within the folder's audio.
- **Rename:**
  - from each of the three places;
  - the current name prefilled;
  - blank disabled;
  - a refusal shown in the dialog;
  - allowed during a run;
  - the menu re-sorting after a rename.
- **Home:**
  - favorites A–Z;
  - the empty favorites hint;
  - all seven type counts including zero;
  - the statistics failure with retry while favorites still render.
- **Update close:** unchanged behaviour with application activities (the existing tests adapted).
- **Integration test:** start, add a library, pin it, favorite it, see it on home.
- Run with `ci-check test` and `ci-check integration` (this machine can't build the native dependency). Run
  `flutter analyze` locally.

### 8. Docs

This repository:

- README: "What it does" (libraries in the menu, pins, favorites, home totals), the roadmap and backlog rows for
  auth, and "the two repositories agree" (`>=0.7.0 <0.8.0`).
- CHANGELOG `[Unreleased]`:
  - Removed: the login (sign-up, login, recovery codes, change credentials, sign out) and the per-type pages.
  - Changed: the left menu lists libraries; a library opens in the main area; home shows favorites and totals;
    library management is in the menu bar; the core is 0.7.
  - Added: pinned and favorite libraries, and renaming a library.
- `docs/requirements`:
  - Mark the auth requirements and use cases, and the per-type navigation (FR-CT-01's per-type entries), withdrawn
    with the reason, as earlier removals were recorded.
  - Add requirements and use cases for library navigation, pin, favorite, rename and the home statistics.
  - Update FR-UX-01 and FR-UX-02 for the new panel.
- `docs/initial`: wherever the login or per-type browsing is described.

alexandria-docs (`content/en`), a pull request into `main`:

- `docs/usage`: remove the sign-up, login and recovery-code sections. Describe the left menu, pinning, favorites,
  renaming a library, browsing a library's folders with layout, filter and sort, home, and library management in the menu bar.
- `docs/architecture`:
  - Remove "Who checks the credentials".
  - "Two ways to deploy it" becomes one: the desktop process with the core through its C ABI. Server mode is gone.
  - Update the diagram.
- `docs/installation`: remove "The HTTP server" section. Mention that there's no account to create.
- `docs/overview`, `about` (the Rust core feature no longer mentions "the REST/JSON server") and the landing page,
  wherever they mention accounts, login, the server or per-type browsing.

## Order of work

1. Core pull request (no authentication, pins, favorites, statistics, its docs). Merged into alexandria-api
   `develop`.
2. App pull request against that core commit. Merged into alexandria-ui `develop`.
3. alexandria-docs pull request into `main`. Merged when the app is ready to release, so the site doesn't describe an
   app nobody can download yet.
4. Releases, when the owner asks: core 0.7.0, then the app 3.0.0 pinned to `v0.7.0`.

## Left to the builder

- Widget structure and the names of new private widgets.
- The icon or letter avatar for library entries, and the pin badge's look.
- Portuguese wording, following the existing Portuguese strings.
- Whether the activity rename happens or the old names stay.
- How the favorites cards lay out at each breakpoint.
