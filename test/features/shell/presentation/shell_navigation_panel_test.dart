import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/shell_harness.dart';

/// The bar's two menus — library tools and settings — and the menu the
/// first of them opens (FR-UX-02, UC-37 main flow step 1).
///
/// The owner's complaint was legibility, not location: two bare icon buttons
/// used to sit in a column of nine labelled destinations and read as a lesser
/// class of control, and the tools menu hid six unrelated screens behind one
/// unlabelled widgets icon. Both moved to the menu bar, where these tests
/// prove both triggers carry their label at the tiers where the rail's
/// destinations do, that neither drops its name at the minimum window (a
/// tooltip stands in, matching how the destinations themselves collapse), and
/// that the tools menu's contents are grouped rather than a single opaque
/// list.
void main() {
  /// Pumps the shell at [width], 900 logical pixels tall.
  Future<void> pumpPanel(WidgetTester tester, {required double width}) =>
      tester.pumpShell(surfaceSize: Size(width, 900));

  testWidgets(
    'GivenTheExtendedBreakpoint_WhenBuilt_ThenBothTriggersShowLabels',
    (tester) async {
      await pumpPanel(tester, width: Breakpoint.expandedMinWidth);

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  // FR-UX-02: no entry is dropped at any breakpoint. At the minimum window the
  // label becomes a tooltip rather than disappearing — and "becomes" has to
  // mean the tooltip can actually be revealed, not merely that a Tooltip
  // widget is present somewhere in the tree, so this measures the rendered
  // size of the region a pointer would have to hover to see it.
  testWidgets(
    'GivenTheMinimumWindow_WhenBuilt_ThenBothTriggersKeepReachableTooltips',
    (tester) async {
      await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);

      for (final message in ['Library', 'Open settings']) {
        final size = tester.getSize(find.byTooltip(message));
        expect(size.width, greaterThan(0), reason: message);
        expect(size.height, greaterThan(0), reason: message);
      }
    },
  );

  testWidgets('GivenTheToolsMenu_WhenOpened_ThenItsSixScreensAreGrouped', (
    tester,
  ) async {
    await pumpPanel(tester, width: 1400);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Tracking'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Watchlists'), findsOneWidget);
  });
}
