import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/features/shell/domain/shell_destination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which area of the shell the owner is in (UC-38 main flow step 2).
void main() {
  ProviderContainer container() {
    final created = ProviderContainer();
    addTearDown(created.dispose);
    return created;
  }

  test('GivenAFreshShell_WhenItIsBuilt_ThenItOpensOnTheDashboard', () {
    // UC-14 main flow step 1: the application opens the dashboard after login.
    expect(container().read(shellControllerProvider), ShellDestination.home);
  });

  test('GivenTheDashboard_WhenAnotherDestinationIsPicked_ThenItIsShown', () {
    final ref = container();

    ref.read(shellControllerProvider.notifier).go(ShellDestination.comicBooks);

    expect(ref.read(shellControllerProvider), ShellDestination.comicBooks);
  });

  test('GivenADestination_WhenItIsPickedAgain_ThenTheStateIsNotReplaced', () {
    final ref = container();
    var notifications = 0;
    ref.listen(shellControllerProvider, (_, _) => notifications++);

    ref.read(shellControllerProvider.notifier).go(ShellDestination.music);
    ref.read(shellControllerProvider.notifier).go(ShellDestination.music);

    expect(notifications, 1);
  });

  test('GivenEveryDestination_WhenEachIsPicked_ThenEachBecomesCurrent', () {
    final ref = container();

    for (final destination in ShellDestination.values) {
      ref.read(shellControllerProvider.notifier).go(destination);
      expect(ref.read(shellControllerProvider), destination);
    }
  });
}
