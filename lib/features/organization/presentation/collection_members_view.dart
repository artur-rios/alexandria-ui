import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/failures/failure_messages.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../shell/presentation/async_state_view.dart';
import '../domain/collection.dart';
import '../domain/collection_gateway.dart';

/// One collection's members (UC-27, FR-OG-04 … FR-OG-07).
///
/// Shown in place of the collections list once a collection is open, with
/// breadcrumbs above it. `FR-OG-07` fixes the present depth of the hierarchy
/// at one, so the trail is `Collections › <name>` — built against a
/// hierarchical model rather than around it, so nesting becomes a change of
/// data rather than of interface.
class CollectionMembersView extends ConsumerWidget {
  /// Creates the view for [collection].
  const CollectionMembersView({required this.collection, super.key});

  /// The open collection.
  final Collection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final members = ref.watch(collectionMembersControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Breadcrumbs(collection: collection),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => unawaited(_AddItemsDialog.show(context)),
            icon: const Icon(Icons.add),
            label: Text(l10n.collectionAddItems),
          ),
        ),
        const _Report(),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AsyncStateView(
            value: members,
            onRetry: ref
                .read(collectionMembersControllerProvider.notifier)
                .reload,
            isEmpty: (members) => members.isEmpty,
            emptyBuilder: (context) =>
                Center(child: Text(l10n.collectionEmpty)),
            builder: (context, members) => ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) =>
                  _MemberTile(member: members[index], kind: collection.kind),
            ),
          ),
        ),
      ],
    );
  }
}

/// Where the owner is (main flow step 2, FR-OG-07).
class _Breadcrumbs extends ConsumerWidget {
  const _Breadcrumbs({required this.collection});

  final Collection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        TextButton(
          onPressed: ref.read(openCollectionProvider.notifier).close,
          child: Text(l10n.collectionsTitle),
        ),
        Icon(
          Icons.chevron_right,
          size: AppSpacing.md,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(collection.name, style: theme.textTheme.titleMedium),
        ),
      ],
    );
  }
}

/// AF-02, AF-03, and AF-04 — what became of the last change.
class _Report extends ConsumerWidget {
  const _Report();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final report = ref.watch(collectionMembershipFormProvider);
    if (report.isEmpty) return const SizedBox.shrink();

    final added = [
      for (final addition in report.additions)
        if (addition.added) addition.name,
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AF-04: exactly which landed, named.
                if (added.isNotEmpty)
                  Text(
                    l10n.collectionItemsAdded(added.join(', ')),
                    style: theme.textTheme.bodySmall,
                  ),

                // AF-02: already a member, and nothing was sent for it.
                if (report.alreadyPresent.isNotEmpty)
                  Text(
                    l10n.collectionItemsAlreadyPresent(
                      report.alreadyPresent.join(', '),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),

                // AF-04's other half: exactly which did not, and why.
                for (final failure in report.failed)
                  Text(
                    l10n.collectionItemNotAdded(
                      failure.name,
                      // The core's own reason, named per item. A rejection it
                      // gave a code this version does not know still reads as
                      // "not added", generically.
                      switch (failure.reason) {
                        ItemRejection.wrongKind => l10n.collectionItemWrongKind,
                        ItemRejection.notFound => l10n.collectionItemGone,
                        null => l10n.failureInvalidInput,
                      },
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),

                // AF-03, and a request the core refused outright.
                if (report.requestFailure case final failure?)
                  Text(
                    failure.localizedMessage(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                if (report.notFound)
                  Text(
                    l10n.collectionNotFound,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: ref
                .read(collectionMembershipFormProvider.notifier)
                .acknowledge,
            child: Text(l10n.editorDismiss),
          ),
        ],
      ),
    );
  }
}

/// One member, and the way out of the collection (steps 5 and 6).
class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member, required this.kind});

  final CollectionMember member;
  final CollectionKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      dense: true,
      leading: Icon(
        kind == CollectionKind.bookmark
            ? Icons.bookmark_outline
            : Icons.insert_drive_file_outlined,
      ),
      title: Text(member.name),
      trailing: IconButton(
        tooltip: l10n.collectionRemoveItem,
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: () => unawaited(
          ref.read(collectionMembershipFormProvider.notifier).remove(member),
        ),
      ),
    );
  }
}

/// Choosing what to add (main flow step 3).
class _AddItemsDialog extends ConsumerStatefulWidget {
  const _AddItemsDialog();

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const _AddItemsDialog(),
  );

  @override
  ConsumerState<_AddItemsDialog> createState() => _AddItemsDialogState();
}

class _AddItemsDialogState extends ConsumerState<_AddItemsDialog> {
  final Set<String> _chosen = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidates = ref.watch(collectionCandidatesControllerProvider);

    return AlertDialog(
      title: Text(l10n.collectionAddItems),
      content: SizedBox(
        width: 420,
        height: 420,
        child: AsyncStateView(
          value: candidates,
          onRetry: () => ref.invalidate(collectionCandidatesControllerProvider),
          isEmpty: (candidates) => candidates.isEmpty,
          // AF-01 seen from the other side: nothing of the matching kind
          // exists to offer, which is a state and not a failure.
          emptyBuilder: (context) =>
              Center(child: Text(l10n.collectionNoCandidates)),
          builder: (context, candidates) => ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];

              return CheckboxListTile(
                value: _chosen.contains(candidate.uuid),
                title: Text(candidate.name),
                onChanged: (checked) => setState(
                  () => checked ?? false
                      ? _chosen.add(candidate.uuid)
                      : _chosen.remove(candidate.uuid),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _chosen.isEmpty ? null : () => unawaited(_add(context)),
          child: Text(l10n.collectionAddChosen),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final navigator = Navigator.of(context);
    final chosen = [
      for (final candidate
          in ref.read(collectionCandidatesControllerProvider).value ??
              const <CollectionMember>[])
        if (_chosen.contains(candidate.uuid)) candidate,
    ];

    navigator.pop();
    await ref.read(collectionMembershipFormProvider.notifier).add(chosen);
  }
}
