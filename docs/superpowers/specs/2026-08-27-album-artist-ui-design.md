# Browsing by the album's artist

**Date:** 2026-08-27
**Status:** approved

## Problem

The Artists list is built from each track's `artist` tag, which names who
performed *that track*. On a record with guests, or on any compilation, that
is not who the record is by. The owner's report: the list shows the
participants rather than the artists.

The same tag is the album key, so a compilation of twelve different performers
is currently not one album with twelve tracks but **twelve albums of one
track** — the same defect, showing up somewhere else.

The core now extracts `albumArtist` (issue #120) and carries it in the
listing. Nothing in this application reads it.

## Design

### 1. One getter, and everything groups by it

`MusicEntry` gains:

```dart
String? get albumArtist => trimmedOrNull(metadata.albumArtist) ?? artist;
```

The fallback is what makes this safe on a real library. Most files carry no
`ALBUMARTIST` frame at all, and a grouping keyed on the raw field would empty
the Artists list for everyone whose collection predates the tag. Falling back
to the performer means a library with no album-artist tags groups exactly as it
does today, and every file that *has* the tag is grouped better.

Grouping and queue-building then read `albumArtist` throughout:

| Function | Was keyed by | Now |
| --- | --- | --- |
| `artistsIn` | `artist` | `albumArtist` |
| `albumsIn` | `(album, artist)` | `(album, albumArtist)` |
| `albumsOfArtist` | `artist` | `albumArtist` |
| `tracksOfAlbum` | `artist` | `albumArtist` |
| `albumOf` | `artist` | `albumArtist` |
| `artistOf` | `artist` | `albumArtist` |

`albumsIn` is where the compilation stops fragmenting: keyed by the record's
own artist, twelve performers under one `ALBUMARTIST` are one album again.

`albumOf` and `artistOf` change with them, because a queue built from a group
has to contain what the group showed. Leaving them on `artist` would mean
pressing play on an album queued a subset of the tracks listed under it.

### 2. A row still shows who played it, where that is worth saying

`MusicEntry.artist` is untouched and stays the performer of that track. The
two are different facts — who made the record, and who played the track — and
the value of having both is precisely that a guest appearance shows the guest.

Where a row says it depends on what the list around it has already said. The
Songs list spans the library, so every row names its performer, as it always
did. Inside a record, a row names its performer only where it differs from the
record's own artist: on a compilation that is the whole point — twelve
performers under one album artist, now correctly one album, and their names
are what the list is for — while on an ordinary single-artist record the same
name under all twelve rows is noise. A track whose tags name no performer says
nothing rather than "Unknown artist".

The record's own artist is named once, in the breadcrumb above the list, on
both paths into a record — from Artists, where it is the crumb already drilled
through, and from Albums, where it is a plain name because no artist's list
was ever visited to go back to.

*(Amended after implementation: the original §2 said the change was to how
tracks are gathered and not to what any row says. That was true only while an
album could hold one artist's tracks; once a compilation is correctly one
album, a row that named nobody hid its performers in the one view this feature
exists for.)*

### 3. The editor has to send it, or it erases it

A metadata patch is a **full replace** of the editable subtype columns: a
field the body omits is written as NULL. The core's `SubtypeMetadata::Audio`
already carries `album_artist`, and the form does not.

Editing any track's title today would therefore clear its album artist and
move it to a different group in the Artists list — a data loss with a visible
symptom and no visible cause.

`MusicField` gains an album-artist entry, which is all it takes: the form, the
validation, the draft and the patch are all built from that enum, so the field
appears in the form and in the body from the one addition. It is a free-text
field beside `artist`, validated as `artist` is.

## Components

| Component | Change |
| --- | --- |
| `catalog/domain/music_metadata.dart` | The field, in the record, in `fromDetails`, in `toPatch`, in `metadataFrom`, and a `MusicField` entry. |
| `playback/domain/music_grouping.dart` | The `albumArtist` getter; `albumOf` and `artistOf` key on it. |
| `playback/domain/music_browse.dart` | The four browse functions key on it. |
| `playback/application/album_animation_controller.dart` | The record's identity and its case show the album artist — the case is the record's sleeve, not the track's. |
| l10n | A label for the new field, in every supported locale. |

## Requirements impact

- **UC-46** describes browsing by artist and gains which artist that is.
- **FR-CT-13** is unaffected: this is still metadata, never a file name.

## Testing

- A record whose tracks name different performers under one album artist is
  one artist group and one album.
- A track's row in Songs shows its own performer, not the album artist; a row
  inside a record shows it where it differs from the record's artist and stays
  quiet where it does not, and an album opened from either path names its
  artist in the breadcrumb.
- A library with no album-artist tags groups exactly as before — the
  fallback, which is what most files will take.
- A blank album-artist tag falls back too, rather than making a group of one.
- Playing an album queues every track the album listed, including the tracks
  whose performer differs.
- The editor shows the field, saves it, and clears it when blanked.
- Editing only the title leaves the album artist intact — the erasure §3
  describes, pinned so it cannot come back.

## Risks

Regrouping is invisible until a re-index, because extraction runs at first
index only (FR-FC-25) so existing rows carry no album artist and every one of
them takes the fallback. That is correct behaviour and a confusing first
impression; it is worth telling the owner to re-index rather than letting them
conclude the change did nothing.
