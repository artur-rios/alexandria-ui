# Project Overview — Alexandria UI

## What This Is

Alexandria UI is the cross-platform desktop front-end for
[Alexandria](https://github.com/artur-rios/alexandria-api), a personal library
system that indexes, organizes, and surfaces a single person's on-disk media and
documents. The desktop app is where the owner actually *sees* and *uses* that
library: it browses the catalog, plays audio and video, reads documents and
comics, edits Markdown and text in place, and organizes everything into
collections, watchlists, and reading lists. It links the Alexandria Rust core in
process over FFI rather than talking to a server, so the whole product runs as a
single local application with no network hop between the interface and its data.

## The Problem

A personal media and document library that lives on disk is unusable through a
file manager. Folders cannot tell a movie from a series, cannot remember which
episode was watched last, cannot show album art while a song plays, cannot rank a
reading list, and cannot search across bookmarks and PDFs and notes at once. The
existing alternatives each solve one slice — a music player, a video player, an
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

- **Browses the catalog** by file type — music, movies, series, HTML pages,
  Markdown and text notes, PDFs and e-books, comic books, images, and browser
  bookmarks — in list, detailed-list, and grid layouts.
- **Manages the library sources**: the owner points the app at one or more
  library folders, and triggers indexing and re-scanning from the interface.
- **Plays audio** with a persistent player, including an album/artist playback
  animation of a disc, vinyl, or tape spinning on its device for the duration of
  the music, pausing with the audio.
- **Plays video** with the basics — full screen, pause, seek forward and
  backward, subtitle selection, and audio-track selection.
- **Views documents and images**: PDFs, e-books, comic books, images, HTML pages,
  and rendered Markdown.
- **Edits Markdown and text files** in place, writing content back to disk.
- **Edits metadata** for music and video, and renames any file.
- **Organizes** files and bookmarks into collections, tracks movies and series in
  watchlists with per-episode progress, and tracks books and comics in reading
  lists with per-issue progress.
- **Searches and filters** the catalog across types and lifecycle states.
- **Deletes safely** through the core's two-phase model: soft delete, restore,
  and an explicit purge that is the only thing that ever touches a file on disk.
- **Authenticates the owner**: sign-up, recovery codes, login, credential
  change, and password recovery, gating the library behind the core's local-auth
  mode.
- **Adapts** to window size and screen size, in light and dark themes, in
  Brazilian Portuguese and English.

## What It Doesn't Do

- **No media editing.** No audio re-encoding, no video re-encoding, no image
  manipulation, no transcoding. Text content, metadata, names, and organization
  are the only things the app changes.
- **No file management beyond the catalog.** The app does not move, copy, or
  duplicate files. It never writes a file byte outside of a Markdown/text content
  edit, and never deletes from disk except through the core's explicit
  purge-on-disk operation.
- **No domain logic of its own.** Validation, lifecycle, retention, and every
  business rule belong to the Rust core. The app presents and enforces them in
  the interface; it does not reimplement or override them.
- **No multi-user features.** One account, belonging to the single owner. No
  second account, no sharing, no profile switching, no roles.
- **No mail transport.** The app never sends e-mail. Confirmation and recovery
  messages are the core's to send; the app asks and reports the outcome.
- **No server, no cloud, no sync.** Everything is local to the machine, apart
  from whatever the core does to deliver a confirmation or recovery message.
- **No mobile or web build.** Windows and Linux desktop only.
- **No library server administration.** The app configures where its own database
  and library folders live; it is not an administration console for a remote
  Alexandria deployment.

## How Success Is Measured

| Outcome | How you would know |
| --- | --- |
| The library is usable end to end | The owner indexes a real library folder, finds a file, plays or reads it, edits its metadata, and organizes it — without leaving the app or touching a file manager. |
| It replaces the five-app workflow | Music, video, documents, notes, and bookmarks are all reachable from one window with one search. |
| It feels light | The app starts, opens a large library, and scrolls it without perceptible stutter on ordinary desktop hardware. |
| It respects the disk | No file is ever modified or removed except by an explicit, confirmed action the owner initiated. |
| It fits the screen | Every screen remains usable from a small window to a maximized 4K display, with no clipped or unreachable controls. |
| It speaks the owner's language | The full interface reads correctly in both Brazilian Portuguese and English, in light and dark themes. |
| Both platforms are real | The same feature set works on Windows and on Ubuntu from the produced installers. |
