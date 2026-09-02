import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/settings_store.dart';
import '../../../core/startup/startup_state.dart';
import '../../catalog/domain/view_layout.dart';

/// How the music area draws its artists and albums (UC-46, FR-CT-03).
///
/// One choice for both, and only for those two: they are the views with a
/// picture per row — a face or a sleeve — and a grid is what a wall of
/// pictures is for. Songs and the tracks of a record stay lists whatever is
/// chosen here, because a track is a line of text and a grid of lines of text
/// is a list with worse density.
///
/// Remembered, the way the catalog's own per-type layouts are (FR-CT-04): an
/// owner who browses their records as a wall of sleeves means it next time
/// too.
class MusicLayoutController extends Notifier<ViewLayout> {
  static final Logger _log = Logger('playback');

  /// The settings key the choice is stored under.
  static const String settingsKey = 'musicLayout';

  /// What the music area shows before anyone chooses.
  ///
  /// The list, because it is the denser of the two and says more per row —
  /// the grid is the deliberate choice, not the one an owner is given
  /// without asking.
  static const ViewLayout fallback = ViewLayout.list;

  /// The two layouts this area offers.
  ///
  /// Not [ViewLayout.detailedList]: it exists to put a file's path beside its
  /// name, and neither an artist nor a record has a path.
  static const List<ViewLayout> offered = [ViewLayout.list, ViewLayout.grid];

  @override
  ViewLayout build() {
    // Watched, not read: the settings store does not exist until startup has
    // finished, and a stored choice has to be picked up when it does.
    final startup = ref.watch(startupControllerProvider);
    if (startup is! StartupReady) return fallback;

    return ViewLayout.byName(_settings?.getString(settingsKey)) ?? fallback;
  }

  SettingsStore? get _settings =>
      ref.read(startupControllerProvider.notifier).settings;

  /// Applies [layout] now and remembers it.
  ///
  /// The state moves whether or not the write lands: a preference that could
  /// not be saved still applies for this session, which is the same rule
  /// every other stored choice here follows (UC-10 AF-02).
  ///
  /// A refused write is logged rather than raised. The catalog's own layout
  /// choice carries an "unsaved" flag its listing renders, and it writes to
  /// this same settings file — an owner whose settings are unwritable is
  /// told so there, so a second notice hung off a music-area icon would
  /// repeat it rather than add to it. What must not happen is the press
  /// throwing out of a button's callback, which is what an unhandled failure
  /// here would be.
  Future<void> choose(ViewLayout layout) async {
    state = layout;

    final settings = _settings;
    if (settings == null) return;

    try {
      await settings.setString(settingsKey, layout.name);
    } on Object catch (error) {
      _log.warning('a music layout applied but could not be saved', error);
    }
  }
}
