import 'package:alexandria_ui/features/library_sources/domain/audio_scope_cleanup.dart';
import 'package:alexandria_ui/features/library_sources/domain/folder_registration.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taking audio out of the stored tracked folders, once audio is no longer a
/// type (remove-music design, "Stored index scopes").
void main() {
  LibrarySource source(
    String path, {
    required List<String> scope,
    String? libraryName,
  }) => LibrarySource(
    path: path,
    label: defaultLabelFor(path),
    registeredAt: DateTime.utc(2026, 10, 21),
    scope: scope,
    libraryName: libraryName,
  );

  test('GivenAMusicOnlyFolder_WhenCleanedUp_ThenItIsRemoved', () {
    final r = cleanUpAudioScopes([
      source('/music', scope: ['audio']),
    ]);
    expect(r.removed.map((s) => s.path), ['/music']);
    expect(r.kept, isEmpty);
  });

  test('GivenAMixedFolder_WhenCleanedUp_ThenAudioIsDroppedAndTheRestKept', () {
    final r = cleanUpAudioScopes([
      source('/mix', scope: ['audio', 'image']),
    ]);
    expect(r.kept.single.scope, ['image']);
    expect(r.removed, isEmpty);
  });

  test('GivenAnEveryTypeFolder_WhenCleanedUp_ThenItIsUnchanged', () {
    final r = cleanUpAudioScopes([source('/all', scope: [])]);
    expect(r.kept.single.scope, isEmpty);
  });

  test('GivenARepeatedAudioScope_WhenCleanedUp_ThenTheFolderIsRemoved', () {
    // Every entry is audio, however many there are: a duplicate is still
    // nothing but music, and keeping the folder with an emptied scope would
    // index every type in it.
    final r = cleanUpAudioScopes([
      source('/music', scope: ['audio', 'audio']),
    ]);
    expect(r.removed.map((s) => s.path), ['/music']);
    expect(r.kept, isEmpty);
  });

  test('GivenAnUnknownName_WhenCleanedUp_ThenItIsKeptAsStored', () {
    // The raw names, not `scopeTypes`: a name this version does not know is
    // left for `scopeIsUnreadable` to refuse, rather than dropped here and
    // turned into "every type".
    final r = cleanUpAudioScopes([
      source('/pods', scope: ['audio', 'podcast']),
    ]);
    expect(r.kept.single.scope, ['podcast']);
    expect(r.removed, isEmpty);
  });

  test('GivenSeveralFolders_WhenCleanedUp_ThenTheirOrderIsKept', () {
    final r = cleanUpAudioScopes([
      source('/a', scope: ['video']),
      source('/music', scope: ['audio']),
      source('/b', scope: ['audio', 'text']),
      source('/c', scope: []),
      source('/songs', scope: ['audio'], libraryName: 'Songs'),
    ]);
    expect(r.kept.map((s) => s.path), ['/a', '/b', '/c']);
    expect(r.kept[1].scope, ['text']);
    expect(r.removed.map((s) => s.path), ['/music', '/songs']);
    expect(r.removed.last.libraryName, 'Songs');
  });

  test('GivenCleanFolders_WhenCleanedUp_ThenTheyAreTheSameRecords', () {
    // Unchanged rather than merely equal, so a caller can tell that nothing
    // needs writing back.
    final clean = [
      source('/a', scope: ['video']),
      source('/b', scope: []),
    ];
    final r = cleanUpAudioScopes(clean);
    expect(r.kept, clean);
    expect(r.removed, isEmpty);
  });
}
