import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether adding a library was asked for from another screen, for the
/// Libraries screen to run once it is showing.
///
/// A request rather than the flow itself: the screen that asks — the empty
/// dashboard, listing or search — is replaced by the Libraries screen the
/// moment it asks, while the native picker stays open for seconds. A flow run
/// on the asking screen's context would find it gone when the folder came
/// back, and drop the folder.
class LibraryAddRequest extends Notifier<bool> {
  @override
  bool build() => false;

  /// Asks for the add flow to run.
  void ask() => state = true;

  /// Whether it was asked for, clearing the request so it runs once.
  bool take() {
    final asked = state;
    state = false;
    return asked;
  }
}
