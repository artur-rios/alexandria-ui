import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/shell_destination.dart';

/// Which area of the shell the owner is in (UC-38 main flow step 2).
///
/// Deliberately the whole of the shell's navigation state: the content area
/// reads it, the navigation panel writes it, and neither knows about the
/// other.
class ShellController extends Notifier<ShellDestination> {
  @override
  ShellDestination build() {
    // A library shown in the main area can be removed while it is shown —
    // from the libraries page, or by another window on the same catalog. The
    // libraries list reloading without it is what says so, and the area it
    // was is then home rather than a page about nothing (spec §3).
    //
    // Weak, so the shell does not load the libraries itself: the left menu
    // keeps them loaded whenever there is a shell to show one in. A failed
    // or loading list says nothing about which libraries exist, so only a
    // loaded one is read.
    ref.listen(librariesControllerProvider, weak: true, (_, next) {
      if (state case LibraryDestination(:final uuid)) {
        if (next case AsyncData(
          :final value,
        ) when !value.any((library) => library.uuid == uuid)) {
          go(ShellDestination.initial);
        }
      }
    });

    return ShellDestination.initial;
  }

  /// Moves to [destination].
  ///
  /// Selecting the destination already shown is a no-op rather than a rebuild:
  /// clicking the current entry in the panel is something owners do, and it
  /// must not discard whatever the content area is in the middle of.
  ///
  /// Moving somewhere else clears the search (UC-11 AF-02's outcome, reached
  /// by navigating rather than by emptying the field). A search left standing
  /// would leave the panel highlighting one area while the content area shows
  /// results from every other one — the destination would appear not to
  /// change at all.
  void go(ShellDestination destination) {
    if (state == destination) return;

    ref.read(searchTermProvider.notifier).clear();
    state = destination;
  }
}
