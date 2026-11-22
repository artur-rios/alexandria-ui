import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/settings_store.dart';
import '../../../core/startup/startup_state.dart';
import '../../catalog/domain/file_type.dart';
import '../../catalog/domain/listing_view.dart';
import '../../catalog/domain/view_layout.dart';

/// How a library's folder is drawn: the layout, the type filter and the order
/// of its files (library navigation design §4).
///
/// One choice for every library, not one per library: the owner reads their
/// libraries one way, and a grid chosen in one folder that vanished in the
/// next would look like the choice had not been kept.
class LibraryViewPreferences {
  /// Creates the preferences.
  const LibraryViewPreferences({
    this.layout = ViewLayout.list,
    this.type,
    this.sortField = SortField.name,
    this.direction = SortDirection.ascending,
    this.lastChangeUnsaved = false,
  });

  /// How the files are drawn. The plain list by default: it is the one layout
  /// that fits every supported window, so the default is never itself a
  /// substitution (UC-10 AF-01).
  final ViewLayout layout;

  /// The one type of file shown, or `null` for every type.
  final FileType? type;

  /// What the files are ordered by.
  final SortField sortField;

  /// Which way the order runs.
  final SortDirection direction;

  /// Whether the last choice applied but could not be stored (UC-10 AF-02).
  ///
  /// Not stored itself: it is about this session's last write.
  final bool lastChangeUnsaved;

  /// The order, as [sortFiles] takes it.
  ListingView get order =>
      ListingView(sortField: sortField, direction: direction);

  /// Whether the type filter hides anything.
  bool get isFiltered => type != null;

  /// A copy with the given changes.
  ///
  /// [type] is replaced only when [filter] is true, because `null` is a
  /// choice of its own (every type) rather than "unchanged".
  LibraryViewPreferences copyWith({
    ViewLayout? layout,
    bool filter = false,
    FileType? type,
    SortField? sortField,
    SortDirection? direction,
    bool? lastChangeUnsaved,
  }) => LibraryViewPreferences(
    layout: layout ?? this.layout,
    type: filter ? type : this.type,
    sortField: sortField ?? this.sortField,
    direction: direction ?? this.direction,
    lastChangeUnsaved: lastChangeUnsaved ?? this.lastChangeUnsaved,
  );

  /// These preferences as the map the settings store holds.
  Map<String, String> toJson() => {
    'layout': layout.name,
    'type': type?.wireName ?? 'all',
    'sortField': sortField.name,
    'direction': direction.name,
  };

  /// The preferences [json] describes, falling back per field.
  ///
  /// Per field rather than all-or-nothing: a document written by another
  /// version may know one of these and not the others, and the ones it does
  /// know are still the owner's choices.
  static LibraryViewPreferences fromJson(Map<String, dynamic> json) =>
      LibraryViewPreferences(
        layout: ViewLayout.byName(json['layout'] as String?) ?? ViewLayout.list,
        type: FileType.fromWire(json['type'] as String?),
        sortField:
            SortField.byName(json['sortField'] as String?) ?? SortField.name,
        direction:
            SortDirection.byName(json['direction'] as String?) ??
            SortDirection.ascending,
      );
}

/// The owner's [LibraryViewPreferences], remembered across runs (UC-10,
/// UC-12).
class LibraryViewPreferencesController
    extends Notifier<LibraryViewPreferences> {
  static final Logger _log = Logger('libraries');

  /// The settings key the preferences are stored under.
  static const String settingsKey = 'libraryView';

  @override
  LibraryViewPreferences build() {
    // Watched, not read: the settings store does not exist until startup
    // finishes, and the stored choice has to be picked up when it does.
    final startup = ref.watch(startupControllerProvider);
    if (startup is! StartupReady) return const LibraryViewPreferences();

    return _read();
  }

  SettingsStore? get _settings =>
      ref.read(startupControllerProvider.notifier).settings;

  LibraryViewPreferences _read() {
    final stored = _settings?.getString(settingsKey);
    if (stored == null) return const LibraryViewPreferences();

    try {
      return LibraryViewPreferences.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on Object catch (error) {
      // Broad by intent: a hand-edited settings file must not stop a library
      // rendering, and the defaults are a perfectly good answer.
      _log.warning('the stored library view could not be read', error);
      return const LibraryViewPreferences();
    }
  }

  /// Draws the files in [layout].
  Future<void> chooseLayout(ViewLayout layout) =>
      _apply(state.copyWith(layout: layout));

  /// Shows only the files of [type], or every type when it is `null`.
  Future<void> filterTo(FileType? type) =>
      _apply(state.copyWith(filter: true, type: type));

  /// Orders the files by [field].
  Future<void> sortBy(SortField field) =>
      _apply(state.copyWith(sortField: field));

  /// Runs the order in [direction].
  Future<void> orderIn(SortDirection direction) =>
      _apply(state.copyWith(direction: direction));

  /// Applies [next] for this session, then stores it.
  ///
  /// AF-02: a write the store refuses still applies; what must not happen is
  /// the owner believing it will be there next time.
  Future<void> _apply(LibraryViewPreferences next) async {
    state = next.copyWith(lastChangeUnsaved: false);

    final settings = _settings;
    if (settings == null) {
      state = state.copyWith(lastChangeUnsaved: true);
      return;
    }

    try {
      await settings.setString(settingsKey, jsonEncode(state.toJson()));
    } on Object catch (error) {
      _log.warning('a library view choice applied but was not saved', error);
      state = state.copyWith(lastChangeUnsaved: true);
    }
  }
}
