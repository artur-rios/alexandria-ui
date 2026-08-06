import 'package:alexandria_desktop/core/theme/breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Breakpoint.of', () {
    test(
      'GivenTheMinimumSupportedWidth_WhenTheTierIsResolved_ThenItIsCompact',
      () => expect(
        Breakpoint.of(Breakpoint.minimumWindowSize.width),
        Breakpoint.compact,
      ),
    );

    test(
      'GivenAWidthBelowTheMinimum_WhenTheTierIsResolved_ThenItIsStillCompact',
      () => expect(
        Breakpoint.of(320),
        Breakpoint.compact,
        reason:
            'the window manager holds the window at the minimum (UC-38 AF-01); '
            'a layout that fell through here would turn a resize into a crash',
      ),
    );

    test(
      'GivenTheWidthJustBelowMedium_WhenTheTierIsResolved_ThenItIsCompact',
      () => expect(
        Breakpoint.of(Breakpoint.mediumMinWidth - 1),
        Breakpoint.compact,
      ),
    );

    test(
      'GivenExactlyTheMediumWidth_WhenTheTierIsResolved_ThenItIsMedium',
      () =>
          expect(Breakpoint.of(Breakpoint.mediumMinWidth), Breakpoint.medium),
    );

    test(
      'GivenTheWidthJustBelowExpanded_WhenTheTierIsResolved_ThenItIsMedium',
      () => expect(
        Breakpoint.of(Breakpoint.expandedMinWidth - 1),
        Breakpoint.medium,
      ),
    );

    test(
      'GivenExactlyTheExpandedWidth_WhenTheTierIsResolved_ThenItIsExpanded',
      () => expect(
        Breakpoint.of(Breakpoint.expandedMinWidth),
        Breakpoint.expanded,
      ),
    );

    test(
      'GivenAVeryWideWindow_WhenTheTierIsResolved_ThenItIsExpanded',
      () => expect(Breakpoint.of(3840), Breakpoint.expanded),
    );
  });

  group('the navigation panel', () {
    test(
      'GivenTheCompactTier_WhenThePanelIsBuilt_ThenItCollapsesToIconsOnly',
      () => expect(Breakpoint.compact.showsNavigationLabels, isFalse),
    );

    test(
      'GivenTheWiderTiers_WhenThePanelIsBuilt_ThenItShowsLabels',
      () => expect(
        [Breakpoint.medium, Breakpoint.expanded]
            .map((tier) => tier.showsNavigationLabels),
        everyElement(isTrue),
      ),
    );
  });

  test('GivenTheMinimumWindowSize_WhenItIsRead_ThenItMatchesNFR07', () {
    expect(Breakpoint.minimumWindowSize.width, 1024);
    expect(Breakpoint.minimumWindowSize.height, 640);
  });
}
