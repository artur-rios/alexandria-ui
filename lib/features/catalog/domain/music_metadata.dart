import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_metadata.freezed.dart';

/// An audio file's editable metadata (UC-15, FR-ME-01).
///
/// Every field is nullable because the core's own shape is: a metadata patch
/// is a full replace, so a field left out is written as NULL. That is not an
/// omission this application has to work around — it is exactly what clearing
/// a field means, and it is why the form always sends every one of them —
/// including the album artist, which the form did not carry until the music
/// area began grouping by it: a patch that left it out would clear it on every
/// unrelated edit.
@freezed
abstract class MusicMetadata with _$MusicMetadata {
  /// Creates a metadata record.
  const factory MusicMetadata({
    String? title,
    String? artist,
    String? albumArtist,
    String? album,
    int? year,
    String? genre,
    int? track,
  }) = _MusicMetadata;

  const MusicMetadata._();

  /// The metadata the core reported for a file, read out of its detail view.
  ///
  /// The detail view holds the metadata object as labelled strings, and the
  /// labels are the core's own field names, so the form opens on what the core
  /// actually holds rather than on a second reading of the same file.
  factory MusicMetadata.fromDetails(Map<String, String> metadata) =>
      MusicMetadata(
        title: metadata[MusicField.title.wireName],
        artist: metadata[MusicField.artist.wireName],
        albumArtist: metadata[MusicField.albumArtist.wireName],
        album: metadata[MusicField.album.wireName],
        year: int.tryParse(metadata[MusicField.year.wireName] ?? ''),
        genre: metadata[MusicField.genre.wireName],
        track: int.tryParse(metadata[MusicField.track.wireName] ?? ''),
      );

  /// The body the core takes, tagged by type and without the empty fields.
  ///
  /// The tag is what the core checks the file's own type against, so a music
  /// patch aimed at something that is not audio is refused there rather than
  /// silently writing the wrong shape.
  Map<String, Object?> toPatch() => {
    'type': 'audio',
    if (title != null) 'title': title,
    if (artist != null) 'artist': artist,
    if (albumArtist != null) 'albumArtist': albumArtist,
    if (album != null) 'album': album,
    if (year != null) 'year': year,
    if (genre != null) 'genre': genre,
    if (track != null) 'track': track,
  };
}

/// One editable field of an audio file's metadata.
///
/// An enum rather than loose strings because the form, the validation and the
/// patch all have to agree on the same names, and the core rejects a body that
/// invents one. Adding a field here is what puts it in the form, in the draft
/// and in the patch at once.
enum MusicField {
  /// The track's title.
  title('title'),

  /// Who performed it.
  artist('artist'),

  /// Who the record itself is by, which is not always who played the track:
  /// a guest appearance names the guest, and a compilation names twelve
  /// performers under one record. What the music area groups by.
  albumArtist('albumArtist'),

  /// The album it belongs to.
  album('album'),

  /// The year it was released.
  year('year'),

  /// Its genre.
  genre('genre'),

  /// Its position on the album.
  track('track');

  const MusicField(this.wireName);

  /// The name the core knows this field by.
  final String wireName;

  /// Whether this field holds a number rather than free text.
  bool get isNumeric => this == MusicField.year || this == MusicField.track;
}

/// Why a field could not be accepted before the call (AF-01, FR-ME-03).
enum MusicFieldError {
  /// The value is not a whole number, where the field holds one.
  notANumber,

  /// A year outside the range a recording can plausibly carry.
  yearOutOfRange,

  /// A track number of zero or less.
  trackNotPositive,

  /// Text longer than the core's column holds.
  tooLong,
}

/// The earliest year the form accepts.
///
/// Recorded sound begins in the nineteenth century, so the bound is there to
/// catch a typo rather than to judge a catalog — a four-digit year that is not
/// a year at all is the mistake this finds.
const int earliestMusicYear = 1860;

/// How long a text field may be.
const int maxMusicFieldLength = 255;

/// What the owner has typed, before it is known to be valid (UC-15 step 3).
///
/// Raw strings rather than parsed values: a half-typed year is a string and
/// nothing else, and turning it into a number is precisely the validation
/// step 4 describes. Keeping the draft as text is also what lets the field
/// keep showing what was typed while it is marked as wrong.
typedef MusicDraft = Map<MusicField, String>;

/// The draft that [metadata] reads as, for a form to open on.
MusicDraft draftFrom(MusicMetadata metadata) => {
  MusicField.title: metadata.title ?? '',
  MusicField.artist: metadata.artist ?? '',
  MusicField.albumArtist: metadata.albumArtist ?? '',
  MusicField.album: metadata.album ?? '',
  MusicField.year: metadata.year?.toString() ?? '',
  MusicField.genre: metadata.genre ?? '',
  MusicField.track: metadata.track?.toString() ?? '',
};

/// What is wrong with [draft], by field (AF-01).
///
/// An empty map means it can be sent. Every field is checked rather than
/// stopping at the first, so the owner sees everything to fix at once instead
/// of finding the next problem after correcting this one.
Map<MusicField, MusicFieldError> validateDraft(MusicDraft draft) {
  final errors = <MusicField, MusicFieldError>{};

  for (final field in MusicField.values) {
    final value = (draft[field] ?? '').trim();
    // An empty field is not an error: it is how a value is cleared, and the
    // core stores NULL for it.
    if (value.isEmpty) continue;

    if (!field.isNumeric) {
      if (value.length > maxMusicFieldLength) {
        errors[field] = MusicFieldError.tooLong;
      }
      continue;
    }

    final number = int.tryParse(value);
    if (number == null) {
      errors[field] = MusicFieldError.notANumber;
      continue;
    }

    if (field == MusicField.year && number < earliestMusicYear) {
      errors[field] = MusicFieldError.yearOutOfRange;
    }
    if (field == MusicField.track && number < 1) {
      errors[field] = MusicFieldError.trackNotPositive;
    }
  }

  return errors;
}

/// The metadata [draft] describes, once [validateDraft] has accepted it.
///
/// Blank fields become null, which the patch leaves out, which the core writes
/// as NULL — the three steps of clearing a field.
MusicMetadata metadataFrom(MusicDraft draft) {
  String? text(MusicField field) {
    final value = (draft[field] ?? '').trim();
    return value.isEmpty ? null : value;
  }

  int? number(MusicField field) => int.tryParse(text(field) ?? '');

  return MusicMetadata(
    title: text(MusicField.title),
    artist: text(MusicField.artist),
    albumArtist: text(MusicField.albumArtist),
    album: text(MusicField.album),
    year: number(MusicField.year),
    genre: text(MusicField.genre),
    track: number(MusicField.track),
  );
}
