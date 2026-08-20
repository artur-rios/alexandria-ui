import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_metadata.freezed.dart';

/// Whether a video is a standalone film or an episode of something
/// (FR-ME-02, FR-TR-07).
///
/// The core's own `mediaKind`, and the reason UC-16 exists as its own use case
/// rather than as UC-15 with different labels: this one field decides whether
/// watch progress is counted per episode or for the item as a whole, which is
/// what AF-03 has to warn about before it changes.
enum MediaKind {
  /// One film, tracked as a single item.
  movie('movie'),

  /// Episodes, tracked one at a time.
  series('series');

  const MediaKind(this.wireName);

  /// The string the core uses.
  final String wireName;

  /// The kind [wireName] names, or `null` when the core answers one this
  /// application does not know.
  static MediaKind? fromWireName(String? wireName) {
    for (final kind in MediaKind.values) {
      if (kind.wireName == wireName) return kind;
    }
    return null;
  }
}

/// A video file's editable metadata (UC-16, FR-ME-02).
///
/// Four fields, which is the core's `SubtypeMetadata::Video` and not a
/// reinterpretation of it. As with music, every field is nullable because the
/// core's patch is a full replace: a field left out is written as NULL, which
/// is exactly what clearing it means.
@freezed
abstract class VideoMetadata with _$VideoMetadata {
  /// Creates a metadata record.
  const factory VideoMetadata({
    String? title,
    int? year,
    String? resolution,
    MediaKind? mediaKind,
  }) = _VideoMetadata;

  const VideoMetadata._();

  /// The metadata the core reported for a file, read out of its detail view.
  factory VideoMetadata.fromDetails(Map<String, String> metadata) =>
      VideoMetadata(
        title: metadata[VideoField.title.wireName],
        year: int.tryParse(metadata[VideoField.year.wireName] ?? ''),
        resolution: metadata[VideoField.resolution.wireName],
        mediaKind: MediaKind.fromWireName(
          metadata[VideoField.mediaKind.wireName],
        ),
      );

  /// The body the core takes, tagged by type and without the empty fields.
  Map<String, Object?> toPatch() => {
    'type': 'video',
    if (title != null) 'title': title,
    if (year != null) 'year': year,
    if (resolution != null) 'resolution': resolution,
    if (mediaKind != null) 'mediaKind': mediaKind!.wireName,
  };
}

/// One editable field of a video file's metadata.
enum VideoField {
  /// The video's title.
  title('title'),

  /// The year it was released.
  year('year'),

  /// Its resolution, as the core recorded or the owner corrects it.
  resolution('resolution'),

  /// Movie or series (FR-ME-02).
  mediaKind('mediaKind');

  const VideoField(this.wireName);

  /// The name the core knows this field by.
  final String wireName;

  /// Whether this field holds a number rather than free text.
  bool get isNumeric => this == VideoField.year;

  /// Whether the owner picks this field's value rather than typing it.
  ///
  /// The marking is a choice between two, so it is a pair of options and not
  /// a text field the owner could misspell — which also removes an entire
  /// class of AF-01 from it.
  bool get isChoice => this == VideoField.mediaKind;
}

/// Why a field could not be accepted before the call (AF-01, FR-ME-03).
enum VideoFieldError {
  /// The value is not a whole number, where the field holds one.
  notANumber,

  /// A year outside the range a film can plausibly carry.
  yearOutOfRange,

  /// Text longer than the core's column holds.
  tooLong,
}

/// The earliest year the form accepts.
///
/// Moving pictures begin in the eighteen-nineties, so the bound catches a typo
/// rather than judging a catalog.
const int earliestVideoYear = 1888;

/// How long a text field may be.
const int maxVideoFieldLength = 255;

/// What the owner has typed or picked, before it is known to be valid.
///
/// Raw strings for every field, the marking included — it carries its own
/// wire name, so the draft stays one uniform map rather than a record with a
/// special case in it.
typedef VideoDraft = Map<VideoField, String>;

/// The draft that [metadata] reads as, for a form to open on.
VideoDraft draftFromVideo(VideoMetadata metadata) => {
  VideoField.title: metadata.title ?? '',
  VideoField.year: metadata.year?.toString() ?? '',
  VideoField.resolution: metadata.resolution ?? '',
  VideoField.mediaKind: metadata.mediaKind?.wireName ?? '',
};

/// What is wrong with [draft], by field (AF-01).
///
/// An empty map means it can be sent. Every field is checked rather than
/// stopping at the first, so the owner sees everything to fix at once.
Map<VideoField, VideoFieldError> validateVideoDraft(VideoDraft draft) {
  final errors = <VideoField, VideoFieldError>{};

  for (final field in VideoField.values) {
    final value = (draft[field] ?? '').trim();
    // An empty field is not an error: it is how a value is cleared, and the
    // core stores NULL for it.
    if (value.isEmpty) continue;

    // The marking comes from a fixed pair of options, so there is nothing to
    // validate that picking one has not already decided.
    if (field.isChoice) continue;

    if (!field.isNumeric) {
      if (value.length > maxVideoFieldLength) {
        errors[field] = VideoFieldError.tooLong;
      }
      continue;
    }

    final number = int.tryParse(value);
    if (number == null) {
      errors[field] = VideoFieldError.notANumber;
      continue;
    }

    if (number < earliestVideoYear) {
      errors[field] = VideoFieldError.yearOutOfRange;
    }
  }

  return errors;
}

/// The metadata [draft] describes, once [validateVideoDraft] has accepted it.
VideoMetadata videoMetadataFrom(VideoDraft draft) {
  String? text(VideoField field) {
    final value = (draft[field] ?? '').trim();
    return value.isEmpty ? null : value;
  }

  return VideoMetadata(
    title: text(VideoField.title),
    year: int.tryParse(text(VideoField.year) ?? ''),
    resolution: text(VideoField.resolution),
    mediaKind: MediaKind.fromWireName(text(VideoField.mediaKind)),
  );
}
