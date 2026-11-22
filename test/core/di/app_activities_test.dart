import 'package:alexandria_ui/core/di/providers.dart';
import 'package:alexandria_ui/core/startup/startup_state.dart';
import 'package:alexandria_ui/features/shell/domain/app_activity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_app_activity.dart';
import '../../support/test_container.dart';

/// The application's activities begin once, when startup is ready (library
/// navigation design §2).
void main() {
  Future<ProviderContainer> startWith(
    List<AppActivity> activities, {
    String? libraryPath,
  }) async {
    final container = buildTestContainer(
      overrides: [
        ...fakeCoreOverrides(libraryPath: libraryPath),
        appActivitiesProvider.overrideWithValue(activities),
      ],
    );

    await container.read(startupControllerProvider.notifier).start();
    // The activities are begun without being awaited: startup does not wait
    // on a library re-check before showing the shell.
    await pumpEventQueue();

    return container;
  }

  test(
    'GivenStartupFinished_WhenTheAppIsReady_ThenEveryAppActivityHasBegunOnce',
    () async {
      final activities = [FakeAppActivity(), FakeAppActivity()];

      final container = await startWith(activities);

      expect(container.read(startupControllerProvider), isA<StartupReady>());
      expect(activities.map((activity) => activity.beginCount), [1, 1]);
      expect(activities.map((activity) => activity.endCount), [0, 0]);
    },
  );

  test(
    'GivenAnActivityFailsToBegin_WhenTheAppIsReady_ThenTheOthersStillBegin',
    () async {
      final throwing = FakeAppActivity(beginThrows: true);
      final other = FakeAppActivity();

      final container = await startWith([throwing, other]);

      expect(container.read(startupControllerProvider), isA<StartupReady>());
      expect(throwing.beginCount, 1);
      expect(other.beginCount, 1);
    },
  );

  test('GivenStartupFails_WhenItStops_ThenNoAppActivityHasBegun', () async {
    final activity = FakeAppActivity();

    final container = await startWith([
      activity,
    ], libraryPath: 'no/such/library.dll');

    expect(container.read(startupControllerProvider), isA<StartupFailed>());
    expect(activity.beginCount, 0);
  });
}
