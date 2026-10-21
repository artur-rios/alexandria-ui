import 'library_source.dart';

/// The wire name audio was stored under, before it stopped being a type.
const String _audio = 'audio';

/// Takes audio out of the stored tracked folders (remove-music design,
/// "Stored index scopes").
///
/// A folder whose scope names nothing but audio goes to `removed`: it was a
/// music folder, and there is nothing left in it to track. Emptying its scope
/// instead would be worse than leaving it, because an empty scope means
/// *every* type, and the next scan would start cataloguing the cover art and
/// booklets the owner scoped it to keep out.
///
/// Every other folder goes to `kept`, with audio dropped from its scope and
/// every other name left as stored. A folder that did not name audio is
/// passed through as the same record, so a caller can tell nothing changed.
///
/// Works on the raw wire names, never on [LibrarySource.scopeTypes], which
/// already drops a name this application does not know. Read through it, a
/// stored `["audio", "podcast"]` would look like an audio-only folder and be
/// removed, and a stored `["podcast"]` would read as empty — every type —
/// where [LibrarySource.scopeIsUnreadable] has to see it to refuse it.
///
/// Order is kept on both sides.
({List<LibrarySource> kept, List<LibrarySource> removed}) cleanUpAudioScopes(
  List<LibrarySource> sources,
) {
  final kept = <LibrarySource>[];
  final removed = <LibrarySource>[];

  for (final source in sources) {
    if (!source.scope.contains(_audio)) {
      kept.add(source);
      continue;
    }

    final rest = [
      for (final name in source.scope)
        if (name != _audio) name,
    ];

    if (rest.isEmpty) {
      removed.add(source);
    } else {
      kept.add(source.copyWith(scope: rest));
    }
  }

  return (kept: kept, removed: removed);
}
