import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../catalog/domain/catalog_gateway.dart';

/// The tracked books' and comics' names, by uuid (UC-32 main flow step 2).
///
/// A reading list carries the uuid the core tracks an item by and nothing else,
/// so the name is read per item. That is a call each, once, held for the run —
/// the same shape and the same cost as the tracked videos, and for the same
/// reason: the core publishes no call that answers several files at once.
class TrackedReadingItemsController extends AsyncNotifier<Map<String, String>> {
  @override
  Future<Map<String, String>> build() async {
    final readingLists = await ref.watch(readingListsControllerProvider.future);
    final credential = ref.read(sessionControllerProvider.notifier).credential;
    if (credential == null) return const {};

    final uuids = {
      for (final readingList in readingLists)
        for (final item in readingList.items) item.itemUuid,
    };

    final gateway = ref.read(catalogGatewayProvider);
    final names = <String, String>{};

    for (final uuid in uuids) {
      final details = await gateway.fileDetails(
        uuid: uuid,
        credential: credential,
      );

      names[uuid] = switch (details) {
        FileDetailsRead(:final details) => details.file.name,
        // An item the catalog will not describe is still tracked, and the
        // reading list still has to show it. Its uuid is the only name there
        // is.
        FileDetailsFailed() => uuid,
      };
    }

    return names;
  }
}
