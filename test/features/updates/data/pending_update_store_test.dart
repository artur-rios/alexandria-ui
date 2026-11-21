import 'dart:io';

import 'package:alexandria_ui/features/updates/data/pending_update_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// The record an update leaves for the next start to check
/// (update-check design §3 step 5).
void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('alexandria_pu'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('GivenAWrittenMarker_WhenRead_ThenFromAndTo', () async {
    final store = PendingUpdateStore(folder);

    await store.write(from: '1.1.0', to: '1.2.0');

    expect(await store.read(), (from: '1.1.0', to: '1.2.0'));
    expect(File('${folder.path}/update-pending.json').existsSync(), isTrue);
  });

  test('GivenNoMarker_WhenRead_ThenNull', () async {
    expect(await PendingUpdateStore(folder).read(), isNull);
  });

  test('GivenAGarbledMarker_WhenRead_ThenNullAndDeleted', () async {
    final file = File('${folder.path}/update-pending.json')
      ..writeAsStringSync('{not json');

    expect(await PendingUpdateStore(folder).read(), isNull);
    expect(file.existsSync(), isFalse);
  });

  test('GivenAMarker_WhenCleared_ThenGone', () async {
    final store = PendingUpdateStore(folder);
    await store.write(from: '1.1.0', to: '1.2.0');

    await store.clear();

    expect(await store.read(), isNull);
  });
}
