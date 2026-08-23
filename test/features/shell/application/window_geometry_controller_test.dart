import 'dart:ui';

import 'package:alexandria_ui/features/shell/application/window_geometry_controller.dart';
import 'package:alexandria_ui/features/shell/domain/window_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_window_placement.dart';
import '../../../support/in_memory_settings_store.dart';

/// Restoring the window at launch and recording it at close
/// (FR-UX-03, UC-38 AF-01, AF-02).
void main() {
  const minimum = Size(1024, 640);
  const defaultSize = Size(1440, 900);
  const stored = WindowGeometry(left: 100, top: 50, width: 1600, height: 1000);

  ({
    WindowGeometryController controller,
    FakeWindowPlacement placement,
    InMemorySettingsStore settings,
  })
  build({String? storedValue, List<Rect>? displays, WindowGeometry? current}) {
    final placement = FakeWindowPlacement(displays: displays, current: current);
    final settings = InMemorySettingsStore(
      values: storedValue == null
          ? null
          : {WindowGeometryController.settingsKey: storedValue},
    );

    return (
      controller: WindowGeometryController(
        placement: placement,
        settings: settings,
      ),
      placement: placement,
      settings: settings,
    );
  }

  group('restore', () {
    test(
      'GivenNoStoredGeometry_WhenTheWindowIsRestored_ThenItOpensAtTheDefault',
      () async {
        final sut = build();

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.defaultSize, defaultSize);
        expect(sut.placement.applied, isNull);
        expect(sut.placement.shown, isTrue);
      },
    );

    test(
      'GivenAStoredGeometry_WhenTheWindowIsRestored_ThenItOpensWhereItWas',
      () async {
        final sut = build(storedValue: stored.encode());

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.applied, stored);
        expect(sut.placement.defaultSize, isNull);
        expect(sut.placement.shown, isTrue);
      },
    );

    test(
      'GivenAnyRestore_WhenItRuns_ThenTheMinimumIsAppliedBeforeAnyGeometry',
      () async {
        // AF-01: a stored size below the floor must be raised rather than
        // honoured, which only holds if the minimum lands first.
        final sut = build(storedValue: stored.encode());

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.minimumSize, minimum);
        expect(
          sut.placement.calls.indexOf('applyMinimumSize'),
          lessThan(sut.placement.calls.indexOf('applyGeometry')),
        );
      },
    );

    test(
      'GivenTheStoredDisplayIsGone_WhenTheWindowIsRestored_ThenItOpensAtTheDefault',
      () async {
        // AF-02: the geometry names a position on a display that no longer
        // exists.
        final sut = build(
          storedValue: const WindowGeometry(
            left: 2400,
            top: 100,
            width: 1440,
            height: 900,
          ).encode(),
          displays: const [Rect.fromLTWH(0, 0, 1920, 1080)],
        );

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.applied, isNull);
        expect(sut.placement.defaultSize, defaultSize);
        expect(sut.placement.shown, isTrue);
      },
    );

    test(
      'GivenTheDisplaysCannotBeRead_WhenTheWindowIsRestored_ThenItOpensAtTheDefault',
      () async {
        final sut = build(storedValue: stored.encode(), displays: const []);

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.applied, isNull);
        expect(sut.placement.defaultSize, defaultSize);
      },
    );

    test(
      'GivenAnUnreadableStoredValue_WhenTheWindowIsRestored_ThenItOpensAtTheDefault',
      () async {
        final sut = build(storedValue: 'hand-edited nonsense');

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.applied, isNull);
        expect(sut.placement.defaultSize, defaultSize);
        expect(sut.placement.shown, isTrue);
      },
    );

    test(
      'GivenNoStoredGeometry_WhenTheWindowIsRestored_ThenTheDisplaysAreNotRead',
      () async {
        final sut = build();

        await sut.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(sut.placement.calls, isNot(contains('visibleDisplayBounds')));
      },
    );
  });

  group('record', () {
    test(
      'GivenAWindowWithBounds_WhenTheOwnerCloses_ThenTheGeometryIsStored',
      () async {
        final sut = build(current: stored);

        await sut.controller.record();

        expect(
          sut.settings.entries[WindowGeometryController.settingsKey],
          stored.encode(),
        );
      },
    );

    test(
      'GivenBoundsThatCannotBeRead_WhenTheOwnerCloses_ThenNothingIsStored',
      () async {
        final sut = build(storedValue: stored.encode());

        await sut.controller.record();

        // The previous value is a better answer than a guess.
        expect(
          sut.settings.entries[WindowGeometryController.settingsKey],
          stored.encode(),
        );
      },
    );

    test(
      'GivenARecordedGeometry_WhenTheNextLaunchRestores_ThenItOpensThere',
      () async {
        final closing = build(current: stored);
        await closing.controller.record();

        final launching = build(
          storedValue:
              closing.settings.entries[WindowGeometryController.settingsKey],
        );
        await launching.controller.restore(
          minimumSize: minimum,
          defaultSize: defaultSize,
        );

        expect(launching.placement.applied, stored);
      },
    );
  });
}
