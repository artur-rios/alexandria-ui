import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/comic_gateway.dart';
import '../domain/file_viewer.dart';

/// How a page is fitted to the window (FR-VW-03).
enum ComicFit {
  /// The whole page, as large as it goes.
  page,

  /// The page's width, so the text is legible and the owner scrolls.
  width,
}

/// Where the comic viewer is (UC-23).
enum ComicStage {
  /// Nothing is open.
  closed,

  /// A page is being read.
  loading,

  /// A page is on screen.
  open,

  /// The archive could not be read at all (AF-01, AF-02, AF-03).
  failed,
}

/// The comic viewer's state (UC-23).
class ComicViewerState {
  /// Creates a state.
  const ComicViewerState({
    this.target,
    this.stage = ComicStage.closed,
    this.page = 1,
    this.pageCount = 0,
    this.bytes,
    this.failure,
    this.skipped = const {},
    this.fit = ComicFit.page,
  });

  /// What is being read, or `null` when nothing is.
  final ViewerTarget? target;

  /// Where the viewer is.
  final ComicStage stage;

  /// Which page the owner is on, counting from one as the core does.
  final int page;

  /// How many pages the archive holds.
  final int pageCount;

  /// The page's image, once it is read.
  final Uint8List? bytes;

  /// Why the archive could not be read.
  final ViewerFailure? failure;

  /// The pages that would not decode (AF-04).
  ///
  /// Kept so the gap can be marked rather than silently jumped: a comic
  /// missing page 14 is something the owner should know about their file.
  final Set<int> skipped;

  /// How the page is fitted.
  final ComicFit fit;

  /// Whether there is a page after this one.
  bool get hasNext => page < pageCount;

  /// Whether there is one before it.
  bool get hasPrevious => page > 1;

  /// Whether the page on screen is one that would not decode (AF-04).
  bool get isOnSkippedPage => skipped.contains(page);

  /// A copy with the given changes.
  ComicViewerState copyWith({
    ViewerTarget? target,
    ComicStage? stage,
    int? page,
    int? pageCount,
    Uint8List? bytes,
    ViewerFailure? failure,
    Set<int>? skipped,
    ComicFit? fit,
  }) => ComicViewerState(
    target: target ?? this.target,
    stage: stage ?? this.stage,
    page: page ?? this.page,
    pageCount: pageCount ?? this.pageCount,
    bytes: bytes,
    failure: failure,
    skipped: skipped ?? this.skipped,
    fit: fit ?? this.fit,
  );
}

/// Drives UC-23: reading a comic book page by page.
class ComicViewerController extends Notifier<ComicViewerState> {
  @override
  ComicViewerState build() => const ComicViewerState();

  /// Opens [target] at the page the owner had reached (main flow steps 1
  /// to 3).
  Future<void> open(ViewerTarget target) async {
    final remembered = ref
        .read(readingPositionsProvider)
        .positionFor(target.uuid);

    state = ComicViewerState(
      target: target,
      stage: ComicStage.loading,
      page: remembered ?? 1,
    );

    await _read(state.page, forward: true);
  }

  /// Moves on a page (main flow step 3).
  Future<void> next() async {
    if (!state.hasNext) return;
    await _read(state.page + 1, forward: true);
  }

  /// Moves back a page.
  Future<void> previous() async {
    if (!state.hasPrevious) return;
    await _read(state.page - 1, forward: false);
  }

  /// Goes to [page].
  Future<void> goTo(int page) async {
    if (page < 1 || (state.pageCount > 0 && page > state.pageCount)) return;
    await _read(page, forward: true);
  }

  /// Switches how the page is fitted (main flow step 3).
  void fit(ComicFit fit) => state = state.copyWith(fit: fit);

  /// Closes the viewer (main flow step 5).
  ///
  /// Nothing was extracted, so there is nothing to clean up — the bytes go
  /// with the state (FR-VW-07).
  void close() => state = const ComicViewerState();

  /// Reads [page], stepping past anything that will not decode (AF-04).
  ///
  /// [forward] is which way to keep stepping. A page that fails while the
  /// owner is paging backwards has to be stepped over backwards, or the
  /// viewer would turn a bad page into a bounce forward.
  Future<void> _read(int page, {required bool forward}) async {
    final target = state.target;
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    // No session, no call (FR-AU-07) — said rather than returned on, which
    // left the viewer showing a spinner over an archive it was never going to
    // read.
    if (target == null || credential == null) {
      state = state.copyWith(
        stage: ComicStage.failed,
        failure: ViewerFailure.unreadable,
      );
      return;
    }

    // The page on screen now, kept because every turn of the loop below
    // replaces it: `copyWith` clears the bytes whenever they are not passed,
    // which is what a loading state wants and what the exhausted-run exit at
    // the bottom does not.
    final heldPage = state.page;
    final heldBytes = state.bytes;

    var wanted = page;
    var skipped = state.skipped;

    while (wanted >= 1 && (state.pageCount == 0 || wanted <= state.pageCount)) {
      state = state.copyWith(
        stage: ComicStage.loading,
        page: wanted,
        skipped: skipped,
      );

      final outcome = await ref
          .read(comicGatewayProvider)
          .readPage(uuid: target.uuid, page: wanted, credential: credential);

      switch (outcome) {
        case ComicPageRead(page: final read):
          state = state.copyWith(
            stage: ComicStage.open,
            page: read.number,
            pageCount: read.pageCount,
            bytes: read.bytes,
            skipped: skipped,
          );
          await ref
              .read(readingPositionsProvider)
              .record(target.uuid, read.number);
          return;

        // AF-01, AF-02 and AF-03 are the archive's, not the page's: there is
        // nothing to read on and nothing to step over.
        case ComicPageFailed(:final failure)
            when failure != ViewerFailure.unreadable || state.pageCount == 0:
          state = state.copyWith(stage: ComicStage.failed, failure: failure);
          return;

        // AF-04: this one page will not decode. The gap is marked and the
        // remaining pages carry on.
        case ComicPageFailed():
          skipped = {...skipped, wanted};
          wanted += forward ? 1 : -1;
      }
    }

    // Every page in the direction of travel was a gap.
    //
    // The last good page goes back on screen, with its own number: this used
    // to leave the stage open with no bytes and the number of a page that
    // never decoded, which the reader renders as an empty frame — a blank
    // window with working controls and nothing to say why.
    if (heldBytes == null) {
      // There was no good page to go back to: this run started from an
      // archive nothing had been read from yet, so every page in it is a gap.
      state = state.copyWith(
        stage: ComicStage.failed,
        failure: ViewerFailure.unreadable,
        skipped: skipped,
      );
      return;
    }

    state = state.copyWith(
      stage: ComicStage.open,
      page: heldPage,
      bytes: heldBytes,
      skipped: skipped,
    );
  }
}
