import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/document_gateway.dart';
import '../domain/file_viewer.dart';

/// Where the document viewer is (UC-22).
enum DocumentStage {
  /// Nothing is open.
  closed,

  /// The file is being read (main flow step 3).
  opening,

  /// It is on screen.
  open,

  /// It could not be presented (AF-01 … AF-04).
  failed,
}

/// The document viewer's state (UC-22).
class DocumentViewerState {
  /// Creates a state.
  const DocumentViewerState({
    this.target,
    this.stage = DocumentStage.closed,
    this.document,
    this.failure,
    this.position = 0,
  });

  /// What is being presented, or `null` when nothing is.
  final ViewerTarget? target;

  /// Where the viewer is.
  final DocumentStage stage;

  /// What was read, once it was.
  final DocumentOutcome? document;

  /// Why it could not be presented.
  final ViewerFailure? failure;

  /// The page or chapter the owner is on (main flow step 5, FR-VW-02).
  final int position;

  /// The chapters, when the document is an e-book.
  List<DocumentChapter> get chapters => switch (document) {
    DocumentIsBook(:final chapters) => chapters,
    _ => const [],
  };

  /// The chapter the owner is reading, or `null` for anything else.
  DocumentChapter? get currentChapter =>
      position >= 0 && position < chapters.length ? chapters[position] : null;

  /// A copy with the given changes.
  DocumentViewerState copyWith({
    ViewerTarget? target,
    DocumentStage? stage,
    DocumentOutcome? document,
    ViewerFailure? failure,
    int? position,
  }) => DocumentViewerState(
    target: target ?? this.target,
    stage: stage ?? this.stage,
    document: document ?? this.document,
    failure: failure,
    position: position ?? this.position,
  );
}

/// Drives UC-22: reading a PDF or an e-book.
class DocumentViewerController extends Notifier<DocumentViewerState> {
  @override
  DocumentViewerState build() => const DocumentViewerState();

  /// Opens [target] (main flow steps 1 to 4).
  Future<void> open(ViewerTarget target) async {
    state = DocumentViewerState(target: target, stage: DocumentStage.opening);

    final outcome = await ref.read(documentGatewayProvider).open(target.path);

    switch (outcome) {
      case DocumentFailed(:final failure):
        state = state.copyWith(stage: DocumentStage.failed, failure: failure);

      // Step 5: the owner picks up where they left off, which is what makes a
      // long document worth opening twice (FR-VW-02).
      case DocumentIsPdf() || DocumentIsBook():
        state = state.copyWith(
          stage: DocumentStage.open,
          document: outcome,
          position:
              ref.read(readingPositionsProvider).positionFor(target.uuid) ?? 0,
        );
    }
  }

  /// Moves to [position] and remembers it (main flow step 5).
  Future<void> goTo(int position) async {
    final target = state.target;
    if (target == null || state.stage != DocumentStage.open) return;

    final bounded = _bounded(position);
    state = state.copyWith(position: bounded);

    await ref.read(readingPositionsProvider).record(target.uuid, bounded);
  }

  /// Moves on by one page or chapter.
  Future<void> next() => goTo(state.position + 1);

  /// Moves back by one.
  Future<void> previous() => goTo(state.position - 1);

  /// Closes the viewer (main flow step 6).
  ///
  /// Nothing is retained: the state goes, and with it whatever the gateway
  /// read (FR-VW-07).
  void close() => state = const DocumentViewerState();

  /// [position], held inside what the document actually has.
  ///
  /// A PDF's page count is the renderer's, so only a book can be bounded here;
  /// the floor applies to both.
  int _bounded(int position) {
    if (position < 0) return 0;

    final chapters = state.chapters;
    if (chapters.isEmpty) return position;

    return position >= chapters.length ? chapters.length - 1 : position;
  }
}
