import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../domain/catalog_gateway.dart';
import '../domain/file_details.dart';

/// Which file's details are open, or `null` for none (UC-13).
///
/// The uuid rather than the file, because the detail view asks the core for
/// the record afresh (main flow step 2) — a listing's copy is what the owner
/// clicked, not what the core currently holds.
class OpenFileController extends Notifier<String?> {
  @override
  String? build() => null;

  /// Opens [uuid]'s details (main flow step 1).
  void open(String uuid) => state = uuid;

  /// Closes the details, returning to the listing.
  void close() => state = null;
}

/// The open file's details (UC-13, FR-CT-05).
class FileDetailsController extends AsyncNotifier<FileDetails?> {
  @override
  Future<FileDetails?> build() async {
    final uuid = ref.watch(openFileProvider);
    if (uuid == null) return null;

    final session = ref.read(sessionControllerProvider.notifier);
    final credential = session.credential;
    if (credential == null) return null;

    final outcome = await ref
        .read(catalogGatewayProvider)
        .fileDetails(uuid: uuid, credential: credential);

    switch (outcome) {
      case FileDetailsRead(:final details):
        return details;

      // AF-05: the core rejected the session, which returns the owner to
      // login. The failure is still thrown so the detail view does not read
      // as a file with nothing in it.
      case FileDetailsFailed(failure: final UnauthorizedFailure failure):
        session.invalidate(failure);
        throw failure;

      // AF-01 arrives as a not-found failure. The screen is what says the
      // file is gone and sends the owner back with the listing refreshed —
      // this layer's job is to report which failure it was.
      case FileDetailsFailed(:final failure):
        throw failure;
    }
  }

  /// Reads the record again.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}
