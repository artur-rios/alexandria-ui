import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/library.dart';
import 'library_name_dialog.dart';

/// Asks what to call [library], and renames it when confirmed.
///
/// Available from every place that lists a library, and at any time — a run
/// in progress included. The dialog stays open with the core's message when
/// the core refuses, so the name typed is not lost.
Future<String?> renameLibrary(
  BuildContext context,
  WidgetRef ref,
  Library library,
) => showDialog<String>(
  context: context,
  builder: (context) => LibraryNameDialog(
    title: AppLocalizations.of(context).libraryRename,
    confirmLabel: AppLocalizations.of(context).renameSubmit,
    initialName: library.name,
    onConfirm: (name) => ref
        .read(librariesControllerProvider.notifier)
        .rename(library.uuid, name),
  ),
);
