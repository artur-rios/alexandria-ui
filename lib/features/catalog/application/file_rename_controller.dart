import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_name.dart';

/// Where the rename is (UC-17).
enum RenameStage {
  /// Open, with the owner typing.
  editing,

  /// The call is in flight (main flow step 3).
  saving,

  /// The core renamed it, so the dialog is finished (main flow step 5).
  renamed,

  /// The core has no such file, so the dialog closes (AF-03).
  gone,
}

/// The rename dialog's state (UC-17).
class RenameState {
  /// Creates a state.
  const RenameState({
    required this.name,
    this.error,
    this.failure,
    this.stage = RenameStage.editing,
  });

  /// What the owner has typed.
  final String name;

  /// What local validation refused (AF-01).
  final FileNameError? error;

  /// What the core refused, if it did (AF-02).
  final Failure? failure;

  /// Where the rename is.
  final RenameStage stage;

  /// Whether the call is in flight.
  bool get isSaving => stage == RenameStage.saving;

  /// A copy with the given changes.
  ///
  /// [error] and [failure] are both cleared rather than carried whenever a new
  /// one is not given: each transition either raises a fresh reason or moves
  /// past the old one.
  RenameState copyWith({
    String? name,
    FileNameError? error,
    Failure? failure,
    RenameStage? stage,
  }) => RenameState(
    name: name ?? this.name,
    error: error,
    failure: failure,
    stage: stage ?? this.stage,
  );
}

/// Renaming one file (UC-17, FR-ME-04, FR-ME-05).
///
/// The rename reaches the disk as well as the catalog, and both are the
/// core's to do — this owns what the owner typed, whether it is a legal name
/// on this computer, and what the core's answer means.
class FileRenameController extends Notifier<RenameState> {
  /// The name the file had when the dialog opened, for AF-04.
  String _original = '';

  /// The file being renamed.
  String _uuid = '';

  @override
  RenameState build() => const RenameState(name: '');

  /// Opens the dialog on [name] for the file [uuid] (main flow step 1).
  void open(String uuid, String name) {
    _uuid = uuid;
    _original = name;
    state = RenameState(name: name);
  }

  /// Records what the owner typed.
  ///
  /// The mark is dropped as they type: it said the value was wrong, and this
  /// is no longer that value.
  void edit(String name) => state = state.copyWith(name: name);

  /// Validates and sends (main flow steps 2 to 5).
  Future<void> submit() async {
    if (state.isSaving) return;

    final name = fileNameToSend(state.name);

    // AF-01: marked, and the core is not called. Step 2 happens here rather
    // than in the core precisely so that this answer is immediate.
    final error = validateFileName(
      state.name,
      host: ref.read(hostFileSystemProvider),
    );
    if (error != null) {
      state = state.copyWith(error: error);
      return;
    }

    // AF-04: the name did not change, so there is nothing to ask the core.
    if (name == _original) {
      state = state.copyWith(stage: RenameStage.renamed);
      return;
    }

    state = state.copyWith(stage: RenameStage.saving);

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) {
      state = state.copyWith(stage: RenameStage.editing);
      return;
    }

    final outcome = await ref
        .read(catalogGatewayProvider)
        .renameFile(uuid: _uuid, name: name, credential: credential);

    switch (outcome) {
      case FileRenamed(:final file):
        _original = file.name;
        // FR-ME-05: the detail view and every open listing read the core
        // again, so the new name shows up without a manual refresh.
        ref.invalidate(fileDetailsControllerProvider);
        ref.invalidate(listingControllerProvider);
        ref.invalidate(catalogSearchProvider);
        state = RenameState(name: file.name, stage: RenameStage.renamed);

      // AF-05: the session is discarded, which returns the owner to login.
      case FileRenameFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        state = state.copyWith(stage: RenameStage.editing);

      // AF-03: the record is gone. The screen closes the dialog and refreshes
      // the listing it came from.
      case FileRenameFailed(failure: NotFoundFailure()):
        state = state.copyWith(stage: RenameStage.gone);

      // AF-02 and anything else the core refused. The dialog stays open with
      // what was typed, and says that nothing changed — which the core
      // guarantees for a disk failure.
      case FileRenameFailed(:final failure):
        state = state.copyWith(failure: failure, stage: RenameStage.editing);
    }
  }
}
