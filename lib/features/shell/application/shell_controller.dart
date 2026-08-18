import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/shell_destination.dart';

/// Which area of the shell the owner is in (UC-38 main flow step 2).
///
/// Deliberately the whole of the shell's navigation state: the content area
/// reads it, the navigation panel writes it, and neither knows about the
/// other. A destination that later needs to carry an argument — a collection
/// the owner opened, say — grows this into a union rather than adding a second
/// source of truth beside it.
class ShellController extends Notifier<ShellDestination> {
  @override
  ShellDestination build() => ShellDestination.initial;

  /// Moves to [destination].
  ///
  /// Selecting the destination already shown is a no-op rather than a rebuild:
  /// clicking the current entry in the panel is something owners do, and it
  /// must not discard whatever the content area is in the middle of.
  void go(ShellDestination destination) {
    if (state == destination) return;
    state = destination;
  }
}
