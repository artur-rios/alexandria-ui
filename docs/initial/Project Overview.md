# Project Overview — Alexandria UI

## What This Is

Alexandria UI is the cross-platform desktop front-end for
[Alexandria](https://github.com/artur-rios/alexandria-api), a personal library
system that indexes, organizes, and surfaces a single person's on-disk media and
documents. It plays music files, but managing a music collection — playlists,
play history, browsing by artist and album — is not part of it; that lives in
Orpheus, a separate project. The desktop app is where the owner actually *sees*
and *uses* that library: it browses the catalog, plays video and music, reads
documents and comics, edits Markdown and text in place, and
organizes everything into collections, watchlists, and reading lists. It links
the Alexandria Rust core in process over FFI rather than talking to a server, so
the whole product runs as a single local application with no network hop between
the interface and its data.

## The Problem

A personal media and document library that lives on disk is unusable through a
file manager. Folders cannot tell a movie from a series, cannot remember which
episode was watched last, cannot rank a
reading list, and cannot search across bookmarks and PDFs and notes at once. The
existing alternatives each solve one slice — a video player, an
e-book reader, a bookmark manager — leaving the owner to run five applications
over the same directory tree and keep the organization in their head.

Alexandria's Rust core already solves the cataloging half of that problem. What
hurts today is that the core has no face: every capability it exposes is
reachable only from a C ABI or an HTTP client. The owner cannot use their own
library.

## Who It's For

| Audience | Relationship to the app |
| --- | --- |
| **The library owner** | The single human user. Runs the app on their own machine, over their own files. There is no second user, no sharing, no roles. |
| **The Alexandria Rust core** | The in-process dependency the app drives over FFI. It owns the catalog, the database, and every domain rule; the app owns presentation and playback. |
| **The local filesystem** | The real source of truth for bytes. The app reads media and document content directly from the paths the core reports. |

## What It Does

- **Navigates by library**: the left menu lists Home, the bookmarks, and the
  owner's libraries — the pinned ones first, then the others, each A–Z — and a
  library opens as its folders, with its files in list, detailed-list, or grid
  layout, filtered to one type — movies and series, music, HTML pages, Markdown
  and text notes, PDFs and e-books, comic books, images — and sorted.
- **Manages libraries**: the owner adds one or more folders as libraries —
  the only way files reach the catalog — which indexes them, and pins,
  favorites, renames, scans again, moves, or removes them, from the left menu,
  a library's own header, and the menu bar's Library menu.
- **Shows home**: the favorite libraries, and how many libraries and how many
  files of each type the catalog holds.
- **Plays music** in a player bar that stays while the owner browses, through
  the folder a track was started from.
- **Plays video** with the basics — full screen, pause, seek forward and
  backward, subtitle selection, and audio-track selection.
- **Views documents and images**: PDFs, e-books, comic books, images, HTML pages,
  and rendered Markdown.
- **Edits Markdown and text files** in place, writing content back to disk.
- **Edits metadata** for video, and tags for music, and renames any file.
- **Organizes** files and bookmarks into collections, tracks movies and series in
  watchlists with per-episode progress, and tracks books and comics in reading
  lists with per-issue progress.
- **Searches** the catalog across every library and type.
- **Deletes safely** through the core's two-phase model: soft delete, restore,
  and an explicit purge that is the only thing that ever touches a file on disk.
- **Adapts** to window size and screen size, in light and dark themes, in
  Brazilian Portuguese and English.

## What It Doesn't Do

- **No media editing.** No video re-encoding, no image
  manipulation, no transcoding. Text content, metadata, names, and organization
  are the only things the app changes.
- **No file management beyond the catalog.** The app does not move, copy, or
  duplicate files. It never writes a file byte outside of a Markdown/text content
  edit, and never deletes from disk except through the core's explicit
  purge-on-disk operation.
- **No domain logic of its own.** Validation, lifecycle, retention, and every
  business rule belong to the Rust core. The app presents and enforces them in
  the interface; it does not reimplement or override them.
- **No multi-user features, and no login.** The single owner runs it on their
  own machine: there is no account to create or sign in to, no sharing, no
  profile switching, no roles.
- **No mail transport.** Nothing sends e-mail.
- **No server, no cloud, no sync.** Everything is local to the machine, apart
  from the update check, which asks GitHub for the latest release and can be
  turned off.
- **No mobile or web build.** Windows and Linux desktop only.
- **No library server administration.** The app configures where its own database
  lives, and the owner chooses which folders are libraries; it is not an administration console for a remote
  Alexandria deployment.

## How Success Is Measured

| Outcome | How you would know |
| --- | --- |
| The library is usable end to end | The owner adds a real folder as a library, finds a file, plays or reads it, edits its metadata, and organizes it — without leaving the app or touching a file manager. |
| It replaces the five-app workflow | Video, documents, notes, and bookmarks are all reachable from one window with one search. |
| It feels light | The app starts, opens a large library, and scrolls it without perceptible stutter on ordinary desktop hardware. |
| It respects the disk | No file is ever modified or removed except by an explicit, confirmed action the owner initiated. |
| It fits the screen | Every screen remains usable from a small window to a maximized 4K display, with no clipped or unreachable controls. |
| It speaks the owner's language | The full interface reads correctly in both Brazilian Portuguese and English, in light and dark themes. |
| Both platforms are real | The same feature set works on Windows and on Ubuntu from the produced installers. |
