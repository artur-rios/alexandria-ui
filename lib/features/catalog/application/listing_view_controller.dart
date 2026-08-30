import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure.dart';
import '../../../core/settings/settings_store.dart';
import '../../../core/startup/startup_state.dart';
import '../domain/file_type.dart';
import '../domain/listing_view.dart';

/// The filters and sort chosen for each file type (UC-12, FR-CT-07, FR-CT-08).
///
/// Per type and remembered, the same way the layout is: an owner who sorts
/// their notes by date and their music by name is expressing two preferences.
class ListingViewController extends Notifier<ListingViewState> {
  static final Logger _log = Logger('catalog');

  /// The settings key the choices are stored under.
  ///
  /// One key for both, where System Requirements §4.11 names two —
  /// `sortByType` and `filtersByType`. They are chosen together, stored
  /// together, and cleared together, and splitting them would mean two writes
  /// that have to agree.
  static const String settingsKey = 'listingViewByType';

  @override
  ListingViewState build() {
    final startup = ref.watch(startupControllerProvider);
    if (startup is! StartupReady) return const ListingViewState();

    return ListingViewState(byType: _read());
  }

  SettingsStore? get _settings =>
      ref.read(startupControllerProvider.notifier).settings;

  Map<FileType, ListingView> _read() {
    final stored = _settings?.getString(settingsKey);
    if (stored == null) return const {};

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final byType = <FileType, ListingView>{};

      for (final entry in decoded.entries) {
        final type = FileType.fromWire(entry.key);
        if (type == null) continue;

        byType[type] = ListingView.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      return byType;
    } on Object catch (error) {
      _log.warning('the stored listing views could not be read', error);
      return const {};
    }
  }

  /// Applies [view] to [type] and records it (main flow step 5).
  Future<void> apply(FileType type, ListingView view) async {
    final previous = state.forType(type);
    state = state.copyWith(
      byType: {...state.byType, type: view},
      rejection: null,
    );

    await _persist();
    // Kept so AF-04 can revert to what was showing before, which the state no
    // longer holds once the new view has been applied.
    _previousByType[type] = previous;
  }

  /// Restores the unfiltered listing and forgets the stored filters (AF-02).
  ///
  /// The sort is deliberately left alone: it orders without hiding anything,
  /// so clearing the filters is not a reason to also un-order the listing.
  Future<void> clearFilters(FileType type) async {
    final view = state.forType(type);
    state = state.copyWith(
      byType: {
        ...state.byType,
        type: view.copyWith(lifecycle: LifecycleFilter.active),
      },
      rejection: null,
    );

    await _persist();
  }

  /// Reverts [type] to the view that was showing before the last change, and
  /// reports why (AF-04).
  Future<void> revert(FileType type, Failure reason) async {
    final previous = _previousByType[type] ?? ListingView.initial;

    // Already reverted and already reported: doing it again would change the
    // state the listing watches, which would reload, which would fail the same
    // way, which would revert again. The listing calls this from inside its
    // own build, so the loop is real rather than theoretical — a test found it
    // by hanging.
    if (state.forType(type) == previous && state.rejection != null) return;

    state = state.copyWith(
      byType: {...state.byType, type: previous},
      rejection: reason,
    );

    await _persist();
  }

  /// Clears the rejection notice once the owner has read it.
  void acknowledgeRejection() {
    if (state.rejection == null) return;
    state = state.copyWith(rejection: null);
  }

  final Map<FileType, ListingView> _previousByType = {};

  Future<void> _persist() async {
    final settings = _settings;
    if (settings == null) return;

    try {
      await settings.setString(
        settingsKey,
        jsonEncode({
          for (final entry in state.byType.entries)
            entry.key.wireName: entry.value.toJson(),
        }),
      );
    } on Object catch (error) {
      // The choice still applies for this session, as everywhere else the
      // settings store is written.
      _log.warning('a listing view applied but could not be saved', error);
    }
  }
}

/// The view each type is listed with, and the last refusal.
class ListingViewState {
  /// Creates a state.
  const ListingViewState({this.byType = const {}, this.rejection});

  /// The view chosen per type. A type with no entry uses [ListingView.initial].
  final Map<FileType, ListingView> byType;

  /// Why the core refused the last filter, or `null` (AF-04).
  final Failure? rejection;

  /// The view [type] is listed with.
  ListingView forType(FileType type) => byType[type] ?? ListingView.initial;

  /// A copy with the given changes.
  ///
  /// [rejection] is cleared by passing `null` explicitly, which a plain
  /// `??` would make impossible.
  ListingViewState copyWith({
    Map<FileType, ListingView>? byType,
    Failure? rejection,
  }) => ListingViewState(byType: byType ?? this.byType, rejection: rejection);
}
