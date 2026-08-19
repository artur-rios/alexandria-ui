import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/folder_registration.dart';
import '../domain/library_source.dart';

part 'library_sources_state.freezed.dart';

/// The library-sources screen's state (UC-05).
///
/// One state rather than a list plus a scattering of flags: the notice about
/// the last attempt belongs with the list it was attempted against, and
/// separating them lets a stale refusal outlive the folder it was about.
@freezed
abstract class LibrarySourcesState with _$LibrarySourcesState {
  /// Creates a state.
  const factory LibrarySourcesState({
    /// The registered folders, in registration order.
    @Default(<LibrarySource>[]) List<LibrarySource> sources,

    /// Whether a registration attempt is in flight (FR-UX-08).
    ///
    /// Covers the probe as well as the write: checking a folder on a slow or
    /// disconnected drive is exactly the perceptible operation that needs to
    /// say it is working.
    @Default(false) bool registering,

    /// Why the last attempt was refused, or `null` when there was none
    /// (AF-02, AF-03).
    FolderRegistrationVerdict? refusal,

    /// The path the last refusal was about, so the message can name it.
    String? refusedPath,

    /// The folder whose unregistration was refused because a run is in flight
    /// (UC-08 AF-02), or `null`.
    String? unregisterRefusedFor,

    /// The already-registered folder the last attempt conflicted with.
    ///
    /// AF-03 highlights this entry in the list, which is why the source is
    /// carried rather than only the verdict.
    LibrarySource? conflictingSource,
  }) = _LibrarySourcesState;

  const LibrarySourcesState._();

  /// Whether first-run guidance is presented (FR-LB-11, main flow step 1).
  bool get isEmpty => sources.isEmpty;
}
