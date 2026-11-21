import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/providers.dart';
import '../application/update_state.dart';
import 'update_dialog.dart';

/// Watches what [MaterialApp]'s routes do, so the update prompt can wait for
/// a dialog the owner has open to close.
final RouteObserver<ModalRoute<void>> updateRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Shows the update prompt over whichever screen is up — the login screen or
/// the shell — once the check answers (update-check design §5).
///
/// Never over another dialog: when one is open, the prompt waits for it to
/// close. It also keeps the update check alive for the life of the
/// application, since it is what watches it.
class UpdatePromptHost extends ConsumerStatefulWidget {
  /// Wraps [child], the application's home.
  const UpdatePromptHost({required this.child, super.key});

  /// What `MaterialApp.home` shows.
  final Widget child;

  @override
  ConsumerState<UpdatePromptHost> createState() => _UpdatePromptHostState();
}

class _UpdatePromptHostState extends ConsumerState<UpdatePromptHost>
    with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && !identical(route, _route)) {
      if (_route != null) updateRouteObserver.unsubscribe(this);
      _route = route;
      updateRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    updateRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => _maybeShow();

  void _maybeShow() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ref.read(updatePromptPresenceProvider)) return;

      final state = ref.read(updateControllerProvider);
      if (state is! UpdateAvailable && state is! UpdatePreviousFailed) return;

      // Something is open above the home screen: wait for it to close.
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;

      UpdateDialog.show(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateControllerProvider, (_, _) => _maybeShow());

    return widget.child;
  }
}
