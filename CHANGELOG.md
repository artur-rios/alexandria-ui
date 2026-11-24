# Changelog

All notable changes to Alexandria UI are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.0.1] - 2026-11-24

### Fixed

- On Linux with an NVIDIA graphics card, the window shows the whole application again, under Wayland and X11
  alike. Since 1.0.1 it showed only the application's top-right quarter, drawn into the window's bottom-left
  quarter, with the rest black: a Flutter 3.50.0 bug, fixed in 3.50.1.
- On Linux under Wayland, the window's contents are drawn at the right size after the window's display scale
  changes, as when it moves between monitors of different scales. Since 1.0.1 they came out twice their size,
  showing only their top-left quarter, or shrunk into that quarter: a Flutter 3.50 bug that the Linux runner
  now works around.

### Changed

- Built with Flutter 3.50.1.

## [3.0.0] - 2026-11-22

### Added

- Libraries can be pinned to the top of the left menu, and marked as favorites to see them on home, from a library's
  entry in the left menu (right-click or long-press) and from its page header. The core stores both, so they survive
  restarts; a change the core refuses leaves the library as it was and says so.
- A library can be renamed at any time, even while it is being scanned: from its entry in the left menu, its page
  header, or Manage libraries. The name opens selected, and Confirm is disabled while it is blank.

### Changed

- The left menu lists Home, Bookmarks, the pinned libraries A–Z, a divider, and the other libraries A–Z, in place of an
  entry per file type. It scrolls rather than dropping a library, at every window width. With no library it offers
  "Add a library", and when the libraries could not be read it says so and tries again when pressed.
- A library opens in the main area rather than in a dialog: a header with its name, Pin and Favorite toggles, a menu
  with Rename, Scan again, Move… and Remove, and its scan; breadcrumbs; and a toolbar with the layout (list, detailed
  list, grid), a type filter and the sort (name, date, album). Folders come first, A–Z, then the files, with everything
  a type page let you do to one. The layout, filter and sort are one choice for every library, and the folder you were
  in is kept while Alexandria runs; the choices made per type before are not carried over. A track plays on through
  the folder's music in the order shown. Deleted files are reached through Deleted items.
- Home shows the favorite libraries A–Z, as cards, and the statistics: how many libraries, and how many files of each
  type, zeroes included. Recent files, files in progress and the last scan are no longer on home; videos still resume
  where they stopped.
- Adding and managing libraries moved to the menu bar. The Library menu starts with "Add library…" and "Manage
  libraries…", a dialog listing every library with Rename, Scan again, Move and Remove, beside "Re-check all
  libraries". The add buttons on home, in search and in the left menu add a library where you are, and the activity
  strip's "View all" opens Manage libraries.
- In Portuguese a favorite library is "preferida"; "Favoritos" still means the bookmarks.
- The application needs Alexandria core 0.7 (`>=0.7.0 <0.8.0`), which has no authentication; an older core is refused
  at startup.

### Removed

- The login: signing up, logging in, the recovery codes, changing the credentials, and signing out. Alexandria opens
  straight into the library once the core is ready, and the Settings menu keeps Preferences.
- The per-type pages — Videos, Music, Books, Comic books, Notes, Pages and Images — and their counts in the left menu.
  A library's files are filtered by type inside it, and home counts each type.
- The Libraries page, which Manage libraries replaces.

### Fixed

- A search result opens its file when clicked, the way a file in a library does; a track plays on through the tracks
  the search found. Before, clicking a result did nothing.

## [2.0.1] - 2026-11-21

### Fixed

- A release build whose download of the page viewer's browser engine (CEF) is cut off or fails now tries again, and
  stops with the reason if it cannot get it. It checks the archive against the SHA-1 the CEF builds site publishes
  before unpacking it; a cut-off download used to fail later, on a missing CEF.

## [2.0.0] - 2026-11-21

### Added

- Music, as files to play rather than a music library to manage, which stays Orpheus's. A Music panel after Videos
  lists tracks by their tags: the title, then artist · album, and the duration. A track is named by its title, or its
  file name when it has none, everywhere it appears: search, the dashboard, a library's folders (with the file name
  beneath), the delete and missing-files reviews, and the player bar.
- An "Album" sort for Music, and its default: by album artist (or artist), album, track number and title, with untagged
  tracks last.
- A track's tags — title, artist, album artist, album, year, genre and track number — are edited from its details.
- A player bar docked at the bottom of the window plays a track while you browse: its cover, title and artist,
  previous, play and pause, next, a seek bar, and close. It plays on through the list the track was started from (the
  Music panel in its order, a library folder in tree order, or the track alone from search, details or the
  dashboard), skips a track that cannot be opened and says which, and stops after the last. Opening a video pauses
  it, and signing out stops it. There are no playlists, play history, shuffle or repeat, and a track does not
  remember where it stopped.
- A check for updates at startup. A release build asks GitHub, once per start, for the latest release, and when it is
  newer than the running one and not a version you skipped, offers it over whatever screen is up: the version, its
  release notes, and Update now, Later, or Skip this version. Later asks again at the next start; a skipped version
  is not offered again, but a newer one is. Preferences has the switch, "Check for updates at startup" (on by
  default), and "Check now", which also offers a skipped version. The Flatpak never checks, and hides both.
- Update now, for the Windows installer, the Linux installer in a folder you can write to, and an AppImage in a
  writable folder. The package is downloaded with its progress and a Cancel, and verified against the SHA-256 the
  release publishes; one that does not match, or has no checksum, is deleted and never run. Alexandria then asks
  about unsaved edits, says a running scan will pause (it can be resumed afterwards), closes, installs the update
  and starts again. If the update did not take, the next start says so and links to the release page.
- Other installs — the `.deb`, the zip and tarball, MSIX, and an installation you cannot write to — and releases
  that publish no checksums are offered the release page instead. Updating in place needs a release that publishes
  checksums, so the first one that does is installed by hand, once.

### Changed

- Alexandria makes one network call of its own: the update check at startup, a request to GitHub's public releases
  API that carries the application's version in its User-Agent and nothing else. It sends no telemetry, and it can
  be turned off in Preferences.
- Libraries are the only way files get into Alexandria. A folder is added as a library on the Libraries screen, now
  a destination of its own, and its first scan starts straight away and is followed under its row. Each library can
  be scanned again, moved, or removed from its row, and "Re-check all libraries" is there too. The Library menu has
  "Libraries" and "Add library…", the buttons on an empty catalog open the Libraries screen and start adding one, and
  the activity strip names a scan by its library.
- A library's files are listed everywhere: the type panels, the dashboard's recent files, search, the deleted and
  missing-files reviews, and the collection picker. They used to be kept out of the type panels.
- Removing a library deletes it from the catalog with its files, their reading and watching positions, their place in
  collections, and its scans, a paused one included; nothing on disk is touched, and the confirmation says so. A
  library cannot be removed while it is being scanned, and it cannot be moved or scanned again while a scan of it is
  running or paused. Its tracks leave the player's queue.
- The application needs Alexandria core 0.6 (`>=0.6.0 <0.7.0`); a 0.5 core is refused at startup.
- Signing in clears the folder list 0.5 kept in the application's settings. The 0.6 core has already deleted those
  folders' records, so add them again as libraries.

### Removed

- The Library sources screen and the folder list the application kept for it.
- The question of which file types a folder's index records.
- Indexing a folder that is not a library.

### Fixed

- Replacing an installation no longer removes it first. Both installers unpack the new version beside the old one and
  move it in only once all of it is there, so a setup that fails part-way, runs out of disk, or is cancelled leaves
  the previous version as it was; files in the folder that the installer did not write are kept. The Windows setup
  waits for a running Alexandria to close, or asks you to close it, and removing the copy you moved away from no
  longer takes the new copy's Start menu entry with it.
- Each release publishes the SHA-256 of its packages, `alexandria-<version>-linux-SHA256SUMS` and
  `alexandria-<version>-windows-SHA256SUMS`, which the application's updater checks a download against.

## [1.0.1] - 2026-11-14

### Changed

- Built with Flutter 3.50. The window is sized, placed, restored and recorded on close through window_manager 0.7 and
  screen_retriever 0.4, which talk to the system directly; where it opens and what it remembers are unchanged.
- The `.deb` also depends on `libx11-6` and `libxi6`, which the new window code links against.

## [1.0.0] - 2026-10-30

### Changed

- The application needs Alexandria core 0.5 (`>=0.5.0 <0.6.0`), which no longer knows audio files.
- Each sign-in takes music out of the registered folders. A folder set to index music only is unregistered, and if it
  was a library, that library is removed first; a library the core will not remove keeps its folder, and the next
  sign-in tries again. A folder that mixed music with other types stays and drops music from what it indexes. Once no
  folder names music, a sign-in changes nothing. Files on disk are never touched.
- Video keeps its sound and its audio-track selection; the audio-only playback libraries are no longer bundled.
- On Ubuntu 23.10 and later, saved pages open in the browser engine again when Alexandria is installed from the `.deb`
  or by the installer run as root. Both now install an AppArmor profile that lets the engine create the user
  namespaces its sandbox needs, as Ubuntu does for Chrome, and remove it on uninstall. Other installs on those Ubuntu
  releases still draw saved pages without the engine.

### Removed

- Music, which has moved to Orpheus, the owner's separate project for it. Alexandria is now a library for what you read
  and watch: text and Markdown, HTML pages, PDFs and e-books, comics, images, and video.
- Music playback, the persistent player bar and queue, and the full-window music player.
- The music library browsed by album artist, album, and song, and the sleeves and covers drawn for it.
- Playlists.
- Play history and the music statistics screen.
- Lyrics and artist photographs, and the music lookup settings.
- The "Open the player when a track starts" preference.
- The music metadata editor.
- The audio file type: audio files in a registered folder are skipped when it is scanned, like any other file the
  application does not recognise.

### Fixed

- Making a folder that is already registered into a library indexes it straight away, from either screen that does
  it, instead of leaving the library empty until Scan is pressed.
- The missing-files review and the collection picker reach the files a library holds.
- Dates are shown in local time rather than UTC, so a file saved late in the evening no longer shows the next day.
- A core of an unsupported version is refused before it opens the catalog, so it can no longer migrate the database
  past what the supported core reads, and an older core reports its version instead of a generic start-up failure.
- Signing in after "Retry" on the sign-in or sign-up screen works; every call used to go to the core that had just been
  shut down.
- Pausing or resuming a scan that has already moved on reports that the run is in a different state, not an unexpected
  error.
- Signing out stops any video that is playing.
- E-books whose package document is at the root of the archive, or whose chapter names are URL-encoded, open with their
  chapters.
- The Linux installer installs into `~/.local/opt/alexandria` by default rather than `~/.local/share/alexandria`, the
  folder the application's own data falls back to, and uninstalling removes only the directories it created.
- The licence notice in the Linux packages says correctly that the bundled ffmpeg is a GPL-enabled build.

### Security

- Links in pages, e-books and Markdown drawn without Chromium open only when they are web or mail addresses; a `file:`
  link to a program, or another application's URL scheme, is no longer handed to the system to run.
- Opening a bookmark checks again that it is a web address, whichever client created it.
- A saved page's stylesheets and missing-asset check only look inside the page's own folder, so a page can no longer
  make the application read any file on the disk, or connect to another computer's file share on Windows, just by
  being opened.
- A saved page shown by the browser engine can no longer read files on the computer. Before, its script could read any
  file and send it over the network. The engine (a patched copy of `webview_cef`, kept in
  `third_party/webview_cef`) now runs Chromium with web security and its sandbox on. It loads files only from the
  page's own folder and never leaves that folder. It opens no windows and downloads nothing. A web or mail link the
  owner clicks opens in the system's browser or mail client.
- Where Chromium's sandbox cannot run, the engine does not start, and the page is drawn without it with a notice
  saying why. This is the case as root, on Ubuntu 23.10 and later unless the sandbox helper is installed, in the
  Flatpak, and on Windows for now.

## [0.1.1] - 2026-09-04

### Changed

- The application has its own icon on every package, replacing Flutter's logo on Windows and the placeholder
  lettermark on Linux.

## [0.1.0] - 2026-09-04

### Added

- Libraries: a folder browsed as its own tree, whose files are shown there rather than in the type panels. A library
  can be added from the Libraries screen or marked where its folder is registered, followed to a folder it moved to,
  and scanned from the library itself.
- When registering a folder, the owner says what it is for, and every later index of it uses that answer.
- The music library browsed by album artist, album, and song, with each record's own cover, a grid layout beside the
  list, and shuffle.
- Music lookup: a track's lyrics, following the music as it plays, and its artist's photograph, looked up for one
  track or the whole library, and switched on from the application.
- Playlists: create, arrange, add tracks to, and play them.
- A full-window music player with bars drawn from the sound of the track and a position line that can be dragged.
- Play history, and a music statistics screen ranking the most played tracks, artists, albums, and genres.
- Indexing progress shown wherever the owner is, each folder's run paused, resumed, or cancelled from its own row, an
  estimate of the time remaining, and a report of the files a scan could not read.
- A newly registered folder indexes itself, and an optional re-check of the library when a session begins.
- A menu bar with the library and settings menus, sign out in the settings menu, and catalog search.
- Every form submits on Return, and the theme and language can be chosen before signing in.

### Changed

- Saved HTML pages are drawn by Chromium, so a page looks as it did in the browser it was saved from. Its script now
  runs, inside Chromium's sandbox, and it can reach the network as it would in a browser; opened over `file:`, it
  cannot reach other local files. When Chromium will not start, the previous renderer draws the page without script.
- Clicking a row opens its file in its viewer or player; the details are a button on the row.
- Audio is named by its title and artist, not its file name, in search results, the queue, and the playback bar.
- The album playback animation and its preference were removed in favour of the new player.
- The executable is now `alexandria` (`alexandria.exe` on Windows) instead of `alexandria_desktop`. On Linux the
  application id changed too, so an existing installation becomes a second entry rather than being upgraded.

### Fixed

- Playing an album no longer skips a track at the boundary between tracks.
- Listings refresh when an index run finishes.
- What the owner had open is closed when their session ends.
- Calls to a core that has stopped responding fail instead of waiting forever.

## [0.0.2] - 2026-08-21

### Changed

- Alexandria is licensed under GPL-3.0-or-later. Every bundled library's licence travels in `lib/licenses`.
- The Linux installer, portable tarball, and AppImage carry ffmpeg, libmpv, and what those depend on, so nothing else
  needs installing. The `.deb` (for Ubuntu 24.04) pulls ffmpeg, libmpv, and GTK in through apt, and the Flatpak gets
  its codecs from the `org.freedesktop.Platform.ffmpeg-full` runtime extension.

### Fixed

- The `.deb`, AppImage, and Flatpak contain the Alexandria core and start. The ones published with 0.0.1 did not and
  were withdrawn from that release.
- A release links the core commit CI tested against, rather than whatever the core's `main` was when it was built.

## [0.0.1] - 2026-08-21

First tagged release, published as a prerelease to exercise the release pipeline and the install programs.

### Added

- Sign up, log in, and sign out, with ten single-use recovery codes to get back in, shown once and regenerated on
  request.
- Library folders registered, indexed, refreshed, and unregistered from the application.
- The catalog browsed by file type in list, detailed-list, and grid layouts, with search, filters, sorting, file
  details, and a home dashboard.
- Video playback with subtitle and audio tracks, and audio playback in a persistent player with an album animation.
- Viewers for PDFs, e-books, comic books, images, and saved HTML pages.
- Editing of music and video metadata, file names, and Markdown and text files, with a live preview.
- Collections, bookmarks, watchlists with per-episode progress, and reading lists with per-issue progress.
- The deletion lifecycle: delete, restore, purge, purge on disk, and a review of missing files.
- Light and dark themes, in Brazilian Portuguese and English.
- Windows packages — an installer, an MSIX, and a portable zip — and Linux packages — a self-extracting installer and a
  portable tarball, which need the distribution's ffmpeg libraries installed.

[Unreleased]: https://github.com/artur-rios/alexandria-ui/compare/v3.0.1...HEAD
[3.0.1]: https://github.com/artur-rios/alexandria-ui/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/artur-rios/alexandria-ui/compare/v2.0.1...v3.0.0
[2.0.1]: https://github.com/artur-rios/alexandria-ui/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/artur-rios/alexandria-ui/compare/v1.0.1...v2.0.0
[1.0.1]: https://github.com/artur-rios/alexandria-ui/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/artur-rios/alexandria-ui/compare/v0.1.1...v1.0.0
[0.1.1]: https://github.com/artur-rios/alexandria-ui/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/artur-rios/alexandria-ui/compare/v0.0.2...v0.1.0
[0.0.2]: https://github.com/artur-rios/alexandria-ui/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/artur-rios/alexandria-ui/releases/tag/v0.0.1
