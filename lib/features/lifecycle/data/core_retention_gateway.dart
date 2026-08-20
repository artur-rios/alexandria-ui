import 'dart:convert';

import '../../../core/bindings/alexandria_bindings.dart';
import '../../../core/bindings/core_client.dart';
import '../../../core/bindings/core_isolate.dart';
import '../../../core/failures/core_status.dart';
import '../../../core/failures/core_status_mapper.dart';
import '../../../core/failures/failure.dart';
import '../domain/retention.dart';

/// [RetentionGateway] over the core's settings read (UC-34, FR-LC-03).
class CoreRetentionGateway implements RetentionGateway {
  /// Wraps [_core].
  const CoreRetentionGateway(this._core);

  final CoreClient _core;

  @override
  Future<RetentionWindow> window({required String credential}) async {
    final CoreJsonResponse response;
    try {
      response = await _core.settings(credential);
    } on CoreCallException {
      return _unreadable();
    }

    if (!CoreStatusFamily.settings.isOk(response.status)) {
      return RetentionWindow.failed(
        failure: mapCoreStatus(CoreStatusFamily.settings, response.status),
      );
    }

    final json = response.json;
    if (json == null) return _unreadable();

    try {
      final body = jsonDecode(json) as Map<String, dynamic>;
      final days =
          (body['deletion'] as Map<String, dynamic>?)?['retentionDays'];

      // A core that answered without the number is a core this version cannot
      // count down from. Reported as unreadable rather than defaulted: an
      // assumed window is exactly what reading this was meant to remove.
      if (days is! num) return _unreadable();

      return RetentionWindow.loaded(days: days.toInt());
    } on Object {
      return _unreadable();
    }
  }

  RetentionWindow _unreadable() => const RetentionWindow.failed(
    failure: Failure.unexpected(
      family: CoreStatusFamily.settings,
      code: SETTINGS_ERR_OTHER,
    ),
  );
}
