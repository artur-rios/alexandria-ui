import 'dart:convert';
import 'dart:io';

/// The record an update writes before it closes the application, for the
/// next start to check (update-check design §3 step 5).
///
/// If the next start is running `to`, the update worked and the record goes.
/// If it is still running `from`, it did not, and the owner is told — on
/// either platform, whichever way the install failed.
class PendingUpdateStore {
  /// Creates the store in [supportDirectory].
  PendingUpdateStore(this.supportDirectory);

  /// The application support folder.
  final Directory supportDirectory;

  File get _file => File('${supportDirectory.path}/update-pending.json');

  /// Records an update from [from] to [to], about to start.
  Future<void> write({required String from, required String to}) async {
    await supportDirectory.create(recursive: true);
    await _file.writeAsString(
      jsonEncode({
        'from': from,
        'to': to,
        'at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  /// The pending update, or null when there is none. An unreadable record
  /// is deleted and answers null: it can only have been cut short.
  Future<({String from, String to})?> read() async {
    final file = _file;
    if (!file.existsSync()) return null;

    try {
      final json = jsonDecode(await file.readAsString());
      if (json case {'from': final String from, 'to': final String to}) {
        return (from: from, to: to);
      }
    } on FormatException {
      // Fall through to deleting it.
    }
    await clear();
    return null;
  }

  /// Forgets the pending update.
  Future<void> clear() async {
    if (_file.existsSync()) await _file.delete();
  }
}
