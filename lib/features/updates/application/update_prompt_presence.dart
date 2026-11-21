import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the update prompt is on screen, so a second one is never stacked
/// on it — by the startup prompt and "Check now" alike.
class UpdatePromptPresence extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks the prompt shown or closed.
  void mark({required bool open}) => state = open;
}
