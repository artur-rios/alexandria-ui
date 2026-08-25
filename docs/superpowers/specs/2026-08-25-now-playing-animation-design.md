# The now-playing screen and its animation

**Date:** 2026-08-25
**Status:** approved

## Problem

The brainstorm asked for one thing about music above all others: that playing a
record should look like playing a record. "A CD, Vinyl or Tape being introduced
to the respective device they play, and an animation of a disc or vinyl
spinning on this player, or the tape being played, must be on the screen by the
duration of the songs, and stop on pauses."

What exists is a third of that. `AlbumAnimation` paints a vinyl, a cassette or a
disc and rotates it, inside a 360-pixel `AlertDialog` that also has to hold the
track title and the transport controls. There is no device — the medium turns
in empty space. There is no insertion: the medium is simply there, already
spinning, the first frame the dialog opens. There is no case and no cover. And
the cassette rotates as a whole, which no cassette has ever done: a cassette's
reels turn inside a shell that does not move.

The dialog is also the wrong container. It is 360 pixels wide on a window that
is at least 1024, and the animation has to share that width with everything
else the player needs to say.

## Design

### 1. The player becomes a full-window route

`NowPlayingScreen` replaces `AlbumPlayerScreen`'s dialog. A route pushed over
the shell: the device large and centred, the track title and album beneath it,
the transport controls below that.

A route rather than a dialog because the animation is the point of the screen
and a dialog cannot give it the room. Closing returns the owner exactly where
they were, with the queue and the playback bar untouched — which is what UC-21's
AF-03 already says happens when the owner navigates away, and is unchanged by
this design.

Playback is never modal. The owner browses the library while audio runs and
controls it from the playback bar, and closing the player stops nothing.

### 2. The insertion

About 4.4 seconds, in six beats:

| Beat | What happens |
| ---- | ------------ |
| 1 | The case floats in from the left, its sleeve facing the owner. |
| 2 | The medium slides out of the case. |
| 3 | The case drifts away and fades out. |
| 4 | The medium travels to the device and seats itself. |
| 5 | The device closes on it — the tonearm swings down onto the record, the deck's glass door drops, the CD lid shuts. |
| 6 | The medium begins to turn. |

Nothing is carried by a hand. The case and the medium float, which is what the
brainstorm asked for and is also what keeps the animation from needing a
figure drawn well enough not to be distracting.

Beat 5 is what makes the sequence read as *inserted* rather than *placed
nearby*, and it is the beat the medium's arrival would otherwise leave
unresolved.

### 3. When the insertion plays

- On the first track played in a session.
- Whenever the **album or the artist changes** from what was playing.
- **Never** between tracks of the same album — a record already on the platter
  is not taken off and put back for its next track.

Playback that triggers an insertion **opens the player screen for it**. The
animation is the feature; leaving it behind a screen the owner has to open
first would mean most plays never showed it. The owner can close the screen the
moment it settles and carry on browsing — the bar keeps control.

Playback that does *not* trigger an insertion opens nothing. Skipping through a
record does not throw a screen up on every track.

### 4. The spin

For as long as the track plays, and frozen exactly where it is when paused —
not reset, not faded, stopped.

| Medium | What turns | One turn |
| ------ | ---------- | -------- |
| Vinyl | The record on the platter | 1.5s |
| Compact disc | The disc in the well | 0.9s |
| Cassette | The two reels, inside a shell that does not move | 1.8s |

Three rates rather than one, because a cassette whose reels swept round as fast
as a CD would look wrong to anyone who has held one.

The specular highlight does not turn with the medium. It stays where the light
is while the grooves and the diffraction move underneath it, which is most of
what makes a painted disc read as a spinning object rather than a rotating
picture.

### 5. The visor in the playback bar

The bar gains a small recessed window at its left — dark, glass-lit, inset —
showing the same medium turning at the same rate while the owner browses.

It is the same painting at a smaller size, not a second one, so the device the
owner is listening to follows them around the application and there is only one
drawing to keep right.

### 6. The artwork

Authored vector, painted in Dart, layered so that what moves is separable from
what does not.

Painted rather than shipped as images, having looked at the alternative: a
search of CC0 and public-domain sources returns railway turntables for
"turntable", and cassette decks that are all recognisably branded hardware — a
Revox, a Nakamichi, a Sony. A permissive licence answers copyright and says
nothing about shipping another company's faceplate as furniture in this
application. Those photographs are also opaque-backgrounded, shot at angles,
and lit differently from one another, so the three devices would not look like
they belong in the same product. And the part that most needs to be convincing
— the spinning medium — is the part a photograph serves worst: a photographed
platter rotated in software reads as a rotating photograph.

The finish is the point. Layered gradients, contact and cast shadows,
reflections on the glass and the disc, brushed metal and paper texture, fine
grain, and one coherent lighting model across all three devices. No brand on
any of them.

Its palette lives in `lib/core/theme/` rather than as literals in the painters,
so FR-UX-07 holds. A walnut plinth is brown in both themes; that is a decision
the theme owns, not one a painter should bury.

### 7. The sleeve, and the cover the core does not have

The case carries the album's cover art.

The core has none for audio. `alexandria_file_thumbnail` covers video, image
and comic; `AudioTags` carries title, artist, album, year, genre and track and
no picture. The `lofty` crate the core already reads tags with can read
embedded pictures — the core simply does not extract them. That is an issue to
raise against alexandria-api, and it is deliberately not a dependency of this
work.

Until it lands, the case shows a **designed jacket**: the album title and the
artist typeset on a colour derived deterministically from the album's name, so
the same record always looks the same and the sleeve reads as a design rather
than as a missing image. When the core ships cover art, the jacket is replaced
by the real cover and nothing else about this design changes.

### 8. The setting

One preference, `AlbumAnimationMode`:

| Mode | Behaviour |
| ---- | -------- |
| By release year (default) | Vinyl before 1985, cassette to 1991, CD from 1992 — and CD for an album carrying no year. Today's `mediumForYear`, unchanged. |
| Vinyl / Cassette / Compact disc | Pinned. Every album arrives on that medium whatever its year says. |
| Off | No insertion, no spin, no visor — and the player never opens itself. |

"Off" means off. An owner who turned the animation off should not have a screen
present itself at them, which is why the auto-open is part of what the mode
governs rather than a separate rule.

The mode is stored with the other preferences and read the same way.

### 9. Reduced motion

Honoured independently of the mode, as `AlbumAnimation` already honours it: with
the system's "disable animations" set, the medium is shown **seated in its
device**, and nothing moves. The player still opens on the first play, because
what it shows is a still picture rather than motion.

An owner who wants neither the motion nor the screen has the Off mode.

## Components

| Component | Change |
| --- | --- |
| `playback/presentation/now_playing_screen.dart` | New. The full-window route: the stage, the metadata, the transport controls. Replaces `album_player_screen.dart`. |
| `playback/presentation/album_stage.dart` | New. The device, the case and the medium, and the insertion and spin timelines over them. |
| `playback/presentation/media_painters/` | New. One painter per device and per medium, plus the case and the sleeve — each a file, each with its moving parts separable. |
| `playback/presentation/album_visor.dart` | New. The bar's window, drawing the same medium at a small size. |
| `playback/domain/album_medium.dart` | Gains the mode; `mediumForYear` stays as the by-year rule. |
| `playback/application/album_animation_controller.dart` | New. Whether an insertion is owed — the session's first play, and album or artist changes — and what medium is showing. |
| `shell/presentation/playback_bar.dart` | Gains the visor. |
| `shell/presentation/preferences_dialog.dart` | Gains the mode. |
| `core/theme/album_palette.dart` | New. The artwork's colours, so no painter declares one. |

## Requirements impact

- **FR-PL-07** describes only a medium that "turns while audio plays and stops
  while it is paused". It grows to cover the insertion, when it plays, and the
  visor.
- **FR-PL-11** (new): the system shall let the owner choose the medium the
  animation shows — by the album's release year, pinned to one medium, or off —
  and shall present no animation and open no player when it is off.
- **UC-21** gains the insertion and the auto-open as main-flow steps, and an
  alternative flow for the mode being off.

## Testing

- The insertion plays on the session's first track, on an album change, and on
  an artist change; and does **not** play between tracks of one album.
- Playback that owes an insertion opens the player; playback that does not,
  does not.
- The spin runs while playing, freezes in place on pause — asserted as position
  held, not merely as stopped — and resumes from where it stopped.
- The cassette's shell does not rotate; its reels do.
- Each mode: by-year picks the medium `mediumForYear` picks; a pinned mode
  overrides the year; Off shows no animation, no visor, and opens no player.
- Reduced motion shows the medium seated and still, in every mode but Off.
- The visor shows the same medium as the screen, and disappears with Off.
- The sleeve shows the album and artist, and the same album yields the same
  jacket colour twice running.
- Closing the player leaves the queue and the bar untouched.

## Risks

The artwork is the risk. Everything here is achievable; whether it looks good
is a matter of how far the painting is taken, and a painter that stops at
flat shapes would deliver this design's structure without its point. The
mockups agreed during design are the reference, and "does it look right on a
real window" is a question for a human at the end of implementation, not for a
widget test.

The second risk is cost per frame. Six painters, layered, with gradients and
shadows, drawn every frame at 60Hz in two places at once — the screen and the
visor — is real work. Each painter's inputs are precomputed and its
`shouldRepaint` is exact, the moving layers sit under their own
`RepaintBoundary`, and the still layers do not repaint at all. If a frame
budget is missed on the minimum supported window, the honest answer is to
simplify the painting rather than to drop the frame rate.
