# Changelog

All notable changes to Alexandria UI are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Making a folder that is already registered into a library indexes it straight away, from either screen that does
  it, instead of leaving the library empty until Scan is pressed.
- A play is counted only for music that was heard: resuming a track past its middle, or dragging the slider there, no
  longer records one.
- The missing-files review and the collection picker reach the files a library holds.
- Dates are shown in local time rather than UTC, so a file saved late in the evening no longer shows the next day.
- Artist photographs that could not be fetched — for example while offline — are offered again instead of being given
  up on until a restart.
- Changing the music lookup settings while a scan runs is saved and takes effect when the scan finishes.
- A core of an unsupported version is refused before it opens the catalog, so it can no longer migrate the database
  past what the supported core reads, and an older core reports its version instead of a generic start-up failure.
- Signing in after "Retry" on the sign-in or sign-up screen works; every call used to go to the core that had just been
  shut down.
- Music lookup changes made after a start-up retry reach the core instead of being reported as applied and ignored.
- Pausing or resuming a scan that has already moved on reports that the run is in a different state, not an unexpected
  error.
- Playing a track that cannot be opened stops the one that was playing, instead of leaving it audible behind "nothing
  could be played".
- The resume offer for a track no longer disappears when another track was playing, and Resume starts where it said.
- Signing out stops the music and any video that is playing.
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

[Unreleased]: https://github.com/artur-rios/alexandria-ui/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/artur-rios/alexandria-ui/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/artur-rios/alexandria-ui/compare/v0.0.2...v0.1.0
[0.0.2]: https://github.com/artur-rios/alexandria-ui/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/artur-rios/alexandria-ui/releases/tag/v0.0.1
