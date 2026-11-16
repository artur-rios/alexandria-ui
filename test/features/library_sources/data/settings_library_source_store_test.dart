import 'dart:convert';

import 'package:alexandria_ui/features/library_sources/data/settings_library_source_store.dart';
import 'package:alexandria_ui/features/library_sources/domain/library_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/in_memory_settings_store.dart';

/// The registered source folders, kept in the settings store (FR-LB-03).
void main() {
  const key = SettingsLibrarySourceStore.settingsKey;

  final registeredAt = DateTime.utc(2026, 8, 30, 9);

  LibrarySource source(String path, {String? libraryName}) => LibrarySource(
    path: path,
    label: path.split('/').last,
    registeredAt: registeredAt,
    libraryName: libraryName,
    scope: const ['video', 'image'],
  );

  test('GivenNothingStored_WhenTheFoldersAreRead_ThenThereAreNone', () {
    final store = SettingsLibrarySourceStore(InMemorySettingsStore());

    expect(store.read(), isEmpty);
  });

  test('GivenWrittenFolders_WhenTheyAreRead_ThenTheyComeBackInOrder', () async {
    final settings = InMemorySettingsStore();
    final store = SettingsLibrarySourceStore(settings);
    final written = [
      source('/media/videos'),
      source('/media/courses', libraryName: 'Courses'),
    ];

    await store.write(written);

    expect(SettingsLibrarySourceStore(settings).read(), written);
  });

  test(
    'GivenWrittenFolders_WhenTheStoreIsInspected_ThenTheyShareOneKey',
    () async {
      final settings = InMemorySettingsStore();

      await SettingsLibrarySourceStore(
        settings,
      ).write([source('/media/videos'), source('/media/books')]);

      expect(settings.entries.keys, [key]);
      expect(jsonDecode(settings.entries[key]!), hasLength(2));
    },
  );

  test('GivenAnEmptyList_WhenItIsWritten_ThenReadingAnswersNone', () async {
    final settings = InMemorySettingsStore();
    final store = SettingsLibrarySourceStore(settings);
    await store.write([source('/media/videos')]);

    await store.write(const []);

    expect(store.read(), isEmpty);
  });

  group('a stored value it cannot read', () {
    for (final entry in {
      'MalformedJson': '[{',
      'AnObjectInsteadOfAList': '{"path": "/media"}',
      'AnEntryThatIsNotAnObject': '["/media/videos"]',
      'AnEntryMissingItsPath': '[{"label": "videos"}]',
    }.entries) {
      test(
        'GivenAStoredValueOf${entry.key}_WhenTheFoldersAreRead_ThenThereAreNone',
        () {
          // A hand-edited settings file must not stop the application starting.
          final store = SettingsLibrarySourceStore(
            InMemorySettingsStore(values: {key: entry.value}),
          );

          expect(store.read(), isEmpty);
        },
      );
    }
  });
}
