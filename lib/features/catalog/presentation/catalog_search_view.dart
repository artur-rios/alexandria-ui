import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../playback/presentation/music_display_name.dart' show tagOr;
import '../../shell/presentation/async_state_view.dart';
import '../application/search_controller.dart';
import '../domain/catalog_search.dart';
import '../domain/file_details.dart';
import '../domain/file_type.dart';
import '../domain/music_metadata.dart';

/// The catalog-wide search field (UC-11 main flow step 1).
///
/// In the shell rather than in a listing, because the search is across every
/// type at once and belongs to none of them.
class CatalogSearchField extends ConsumerStatefulWidget {
  /// Creates the field.
  const CatalogSearchField({super.key});

  @override
  ConsumerState<CatalogSearchField> createState() => _CatalogSearchFieldState();
}

class _CatalogSearchFieldState extends ConsumerState<CatalogSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final term = ref.watch(searchTermProvider);

    // Kept in step with the state so clearing from anywhere empties the field
    // too, without the field fighting what the owner is typing.
    if (term.isEmpty && _controller.text.isNotEmpty) _controller.clear();

    return TextField(
      controller: _controller,
      onChanged: (value) => ref.read(searchTermProvider.notifier).term = value,
      decoration: InputDecoration(
        labelText: l10n.searchLabel,
        prefixIcon: const Icon(Icons.search),
        // AF-02: clearing restores the previous listing, which is what an
        // empty term already means — so this is one call and no state machine.
        suffixIcon: term.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.searchClear,
                onPressed: () => ref.read(searchTermProvider.notifier).clear(),
              ),
      ),
    );
  }
}

/// The matches, grouped by type (UC-11 main flow step 3).
class CatalogSearchResults extends ConsumerWidget {
  /// Creates the results.
  const CatalogSearchResults({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final term = ref.watch(searchTermProvider);
    final index = ref.watch(catalogSearchProvider);

    return AsyncStateView<CatalogSearchIndex>(
      value: index,
      onRetry: () => ref.read(catalogSearchProvider.notifier).reload(),
      isEmpty: (loaded) => loaded.isEmpty,
      // AF-04: nothing is cataloged, so a search cannot help — registering and
      // indexing a folder is what the owner needs.
      emptyBuilder: (context) => const _NothingCatalogued(),
      builder: (context, loaded) => _Matches(index: loaded, term: term),
    );
  }
}

class _Matches extends StatelessWidget {
  const _Matches({required this.index, required this.term});

  final CatalogSearchIndex index;
  final String term;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final matches = searchResults(index.files, term);

    if (matches.isEmpty) {
      return _NoMatches(term: term, isComplete: index.isComplete);
    }

    // Grouped by type, in the panel's own order so the results read the way
    // the library does.
    final byType = <FileType, List<FileDetails>>{};
    for (final details in matches) {
      byType.putIfAbsent(details.file.type, () => []).add(details);
    }
    final types = [
      for (final type in FileType.values)
        if (byType.containsKey(type)) type,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.searchResultsFor(term), style: theme.textTheme.titleSmall),
        // AF-03: what is shown is what could be read, and saying so is the
        // difference between a partial answer and a wrong one.
        if (!index.isComplete)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              l10n.searchPartial,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),

        Expanded(
          child: ListView.builder(
            // One header plus its rows per type, built on demand: a search
            // across a large library is exactly where materializing
            // everything would hurt (FR-CT-10).
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final rows = byType[type]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      type.label(l10n),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  for (final details in rows)
                    _ResultRow(details: details, term: term),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One match (main flow step 3).
///
/// An audio file is named by its metadata title, exactly as it is in the music
/// area (FR-CT-13): the rule follows the file type, and a result list that
/// showed names on disk would put back every file name that area removes.
/// Every other type is named by its file name, which is what it is called.
class _ResultRow extends ConsumerWidget {
  const _ResultRow({required this.details, required this.term});

  final FileDetails details;
  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final file = details.file;
    final isAudio = file.type == FileType.audio;
    // `tagOr` rather than a fallback written out here: that helper is the one
    // place an absent tag becomes a word, and a second copy of the rule here
    // is exactly what would let this screen and the music area disagree. The
    // row's own metadata is read straight off it — the listing carries it
    // already, so there is no per-file provider to ask.
    final metadata = isAudio
        ? MusicMetadata.fromDetails(details.metadata)
        : null;
    final title = isAudio
        ? tagOr(metadata?.title, l10n.musicUnknownTitle)
        : file.name;

    return ListTile(
      leading: Icon(
        isAudio ? Icons.music_note_outlined : Icons.insert_drive_file_outlined,
      ),
      // The term is marked in the name the row shows; marking a name the row
      // does not show would point at nothing.
      title: _Highlighted(text: title, term: term),
      // The artist for audio, so two identically-titled tracks — a remix, a
      // live take, a duplicate rip — read as different rows. Never the path:
      // it ends in the name on disk, which would put the very name FR-CT-13
      // removed from the title back in the subtitle. Every other type is
      // named by its file name already, so its path is no more revealing than
      // the title above it.
      // Says where a hit lives when it lives in a library. Without it the
      // row is a puzzle: the owner finds the file here and then cannot find
      // it in the panel for its type, because a library's files are shown in
      // their folders instead (FR-CT-16).
      trailing: details.libraryUuid == null
          ? null
          : _LibraryTag(uuid: details.libraryUuid!),
      subtitle: isAudio
          ? Text(
              tagOr(metadata?.artist, l10n.musicUnknownArtist),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              file.path,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}

/// Names the library a result belongs to.
///
/// The name is looked up rather than carried on the row: the core answers
/// membership as a uuid, deliberately, so a listing does not go stale the
/// moment a library is renamed. Until the list of libraries has been read
/// this says only that the file is in one, which is the part that explains
/// the panel it is missing from.
class _LibraryTag extends ConsumerWidget {
  const _LibraryTag({required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final libraries = ref.watch(librariesControllerProvider).value ?? const [];
    final named = libraries
        .where((library) => library.uuid == uuid)
        .firstOrNull;

    return Chip(
      avatar: const Icon(Icons.folder_special_outlined, size: 16),
      label: Text(
        named == null
            ? l10n.searchInALibrary
            : l10n.searchInLibrary(named.name),
        style: theme.textTheme.labelSmall,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// A name with the matched term marked (main flow step 3).
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.term});

  final String text;
  final String term;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final range = highlightRange(text, term);

    // Matched on its path rather than its name: there is nothing in the name
    // to mark, and inventing a mark would point at the wrong thing.
    if (range == null) return Text(text);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, range.start)),
          TextSpan(
            text: text.substring(range.start, range.end),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(range.end)),
        ],
      ),
    );
  }
}

/// Nothing matched (AF-01, FR-CT-09).
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.term, required this.isComplete});

  final String term;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.searchNoResults(term),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!isComplete) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.searchPartial,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The catalog holds nothing to search (AF-04).
class _NothingCatalogued extends StatelessWidget {
  const _NothingCatalogued();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.catalogEmptyFirstRun,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => LibrarySourcesScreen.show(context),
              icon: const Icon(Icons.folder_outlined),
              label: Text(l10n.catalogEmptyAddFolder),
            ),
          ],
        ),
      ),
    );
  }
}

/// What each type is called, for the search's group headings.
///
/// The panel's own words, so a result group and its destination read the same.
extension FileTypeLabel on FileType {
  /// The localized name of this type.
  String label(AppLocalizations l10n) => switch (this) {
    FileType.audio => l10n.destinationMusic,
    FileType.video => l10n.destinationVideos,
    FileType.document => l10n.destinationBooks,
    FileType.comic => l10n.destinationComicBooks,
    FileType.text => l10n.destinationNotes,
    FileType.html => l10n.destinationPages,
    FileType.image => l10n.destinationImages,
  };
}
