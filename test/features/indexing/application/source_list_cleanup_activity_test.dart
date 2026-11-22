import 'dart:io';

import 'package:alexandria_ui/features/indexing/application/source_list_cleanup_activity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/in_memory_settings_store.dart';

/// The 0.5 app kept its own list of folders to index under
/// `librarySources`. The 0.6.0 core indexes only libraries and deleted those
/// folders' records on upgrade, so the list is dropped once, unread.
void main() {
  test(
    'GivenAStoredSourceList_WhenTheActivityBegins_ThenTheKeyIsRemoved',
    () async {
      final settings = InMemorySettingsStore(
        values: {'librarySources': '[{"path":"/media/movies"}]'},
      );

      await SourceListCleanupActivity(() => settings).begin();

      expect(settings.getString('librarySources'), isNull);
    },
  );

  test(
    'GivenAMalformedSourceList_WhenTheActivityBegins_ThenTheKeyIsRemovedWithoutThrowing',
    () async {
      final settings = InMemorySettingsStore(
        values: {'librarySources': '{not json'},
      );

      await SourceListCleanupActivity(() => settings).begin();

      expect(settings.getString('librarySources'), isNull);
    },
  );

  test(
    'GivenNoSourceList_WhenTheActivityBegins_ThenNothingIsWritten',
    () async {
      final settings = _RecordingSettingsStore();

      await SourceListCleanupActivity(() => settings).begin();

      expect(settings.removed, isEmpty);
    },
  );

  test(
    'GivenTheStoreRefusesTheRemoval_WhenTheActivityBegins_ThenItDoesNotThrow',
    () async {
      final settings = _ThrowingSettingsStore(values: {'librarySources': '[]'});

      await expectLater(
        SourceListCleanupActivity(() => settings).begin(),
        completes,
      );
    },
  );

  test(
    'GivenNoLoadedSettings_WhenTheActivityBegins_ThenItDoesNothing',
    () async {
      await expectLater(
        SourceListCleanupActivity(() => null).begin(),
        completes,
      );
    },
  );
}

class _RecordingSettingsStore extends InMemorySettingsStore {
  final List<String> removed = [];

  @override
  Future<void> remove(String key) async {
    removed.add(key);
    await super.remove(key);
  }
}

class _ThrowingSettingsStore extends InMemorySettingsStore {
  _ThrowingSettingsStore({super.values});

  @override
  Future<void> remove(String key) async =>
      throw const FileSystemException('the settings file is read-only');
}
