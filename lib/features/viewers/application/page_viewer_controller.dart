import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/file_type.dart';
import '../domain/file_viewer.dart';
import '../domain/page_content.dart';

/// Where the page viewer is (UC-25).
enum PageStage {
  /// Nothing is open.
  closed,

  /// The file is being read (main flow step 2).
  opening,

  /// It is on screen.
  open,

  /// It could not be read (AF-01).
  failed,
}

/// The page viewer's state (UC-25).
class PageViewerState {
  /// Creates a state.
  const PageViewerState({
    this.target,
    this.stage = PageStage.closed,
    this.content,
    this.failure,
  });

  /// What is being read, or `null` when nothing is.
  final ViewerTarget? target;

  /// Where the viewer is.
  final PageStage stage;

  /// What was read.
  final PageContent? content;

  /// Why it could not be.
  final ViewerFailure? failure;

  /// Whether the owner may switch this file into the editor (main flow
  /// step 4).
  ///
  /// A Markdown file only: an HTML page is not something this application
  /// edits (BR-06 lets it write text content, and UC-18 is where that lives).
  bool get isEditable => content?.isMarkdown ?? false;

  /// A copy with the given changes.
  PageViewerState copyWith({
    ViewerTarget? target,
    PageStage? stage,
    PageContent? content,
    ViewerFailure? failure,
  }) => PageViewerState(
    target: target ?? this.target,
    stage: stage ?? this.stage,
    content: content ?? this.content,
    failure: failure,
  );
}

/// Drives UC-25: reading a saved page, or a Markdown file rendered.
class PageViewerController extends Notifier<PageViewerState> {
  @override
  PageViewerState build() => const PageViewerState();

  /// Opens [target] (main flow steps 1 to 3).
  Future<void> open(ViewerTarget target) async {
    state = PageViewerState(target: target, stage: PageStage.opening);

    final outcome = await ref
        .read(pageGatewayProvider)
        .read(target.path, isMarkdown: target.type == FileType.text);

    switch (outcome) {
      case PageRead(:final content):
        state = state.copyWith(stage: PageStage.open, content: content);

      case PageFailed(:final failure):
        state = state.copyWith(stage: PageStage.failed, failure: failure);
    }
  }

  /// Closes the viewer.
  ///
  /// Nothing is retained: the markup goes with the state (FR-VW-07).
  void close() => state = const PageViewerState();
}
