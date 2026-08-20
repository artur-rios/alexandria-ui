import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_file.dart';
import '../domain/file_viewer.dart';

/// Where the image viewer is (UC-24).
enum ImageStage {
  /// Nothing is open.
  closed,

  /// An image is on screen.
  open,

  /// It could not be decoded, or is not there (AF-01, AF-02).
  failed,
}

/// The image viewer's state (UC-24).
class ImageViewerState {
  /// Creates a state.
  const ImageViewerState({
    this.files = const [],
    this.index = 0,
    this.stage = ImageStage.closed,
    this.failure,
  });

  /// The listing the owner opened this image from (main flow step 5).
  ///
  /// The whole listing rather than one file, because moving to the next image
  /// is what the flow asks for and "the current listing" is what it means by
  /// next.
  final List<CatalogFile> files;

  /// Which of them is on screen.
  final int index;

  /// Where the viewer is.
  final ImageStage stage;

  /// Why the image could not be presented.
  final ViewerFailure? failure;

  /// The image on screen, or `null` when there is none.
  CatalogFile? get current =>
      index >= 0 && index < files.length ? files[index] : null;

  /// Whether there is an image after this one in the listing.
  bool get hasNext => index + 1 < files.length;

  /// Whether there is one before it.
  bool get hasPrevious => index > 0;

  /// A copy with the given changes.
  ImageViewerState copyWith({
    List<CatalogFile>? files,
    int? index,
    ImageStage? stage,
    ViewerFailure? failure,
  }) => ImageViewerState(
    files: files ?? this.files,
    index: index ?? this.index,
    stage: stage ?? this.stage,
    failure: failure,
  );
}

/// Drives UC-24: looking at an image.
///
/// Thinner than the other viewers, and deliberately: Flutter's own decoders
/// cover the formats (Technology Stack Document §3.4), so there is no gateway
/// to read bytes through — the widget reads the path. What is here is which
/// image, out of which listing, and whether it could be read at all.
class ImageViewerController extends Notifier<ImageViewerState> {
  @override
  ImageViewerState build() => const ImageViewerState();

  /// Opens [file] out of [listing] (main flow steps 1 to 3).
  void open(CatalogFile file, List<CatalogFile> listing) {
    final index = listing.indexWhere(
      (candidate) => candidate.uuid == file.uuid,
    );

    state = ImageViewerState(
      // A file the listing does not hold is a listing of one: the owner asked
      // for this image, and there is nothing to move to.
      files: index < 0 ? [file] : listing,
      index: index < 0 ? 0 : index,
      stage: ImageStage.open,
    );

    _checkPresence();
  }

  /// Moves to the next image in the listing (main flow step 5).
  void next() {
    if (!state.hasNext) return;
    _goTo(state.index + 1);
  }

  /// Moves to the previous one.
  void previous() {
    if (!state.hasPrevious) return;
    _goTo(state.index - 1);
  }

  /// Reports that the decoder refused this image (AF-02).
  ///
  /// Raised by the widget rather than found here, because the decoding is
  /// Flutter's: the error arrives from the image itself, and this is what the
  /// viewer does with it.
  void reportUndecodable() => state = state.copyWith(
    stage: ImageStage.failed,
    failure: ViewerFailure.unreadable,
  );

  /// Closes the viewer.
  void close() => state = const ImageViewerState();

  void _goTo(int index) {
    state = state.copyWith(index: index, stage: ImageStage.open);
    _checkPresence();
  }

  /// AF-01: the record is there and the file is not.
  ///
  /// Checked here rather than left to the decoder, because a file that is
  /// absent and a file that is damaged are different problems with different
  /// answers — only the first is worth a re-scan.
  void _checkPresence() {
    final file = state.current;
    if (file == null) return;

    if (!ref.read(fileProbeProvider)(file.path)) {
      state = state.copyWith(
        stage: ImageStage.failed,
        failure: ViewerFailure.missingOnDisk,
      );
    }
  }
}

/// Whether a file exists at [path].
///
/// A function rather than an interface: it answers one question, and binding
/// it is how a widget test puts an image somewhere without a disk.
bool fileExists(String path) => File(path).existsSync();
