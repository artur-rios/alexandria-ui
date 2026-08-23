import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/shell_harness.dart';

/// The rail's two actions — library tools and preferences — and the menu the
/// first of them opens (FR-UX-02, UC-37 main flow step 1).
///
/// The owner's complaint was legibility, not location: two bare icon buttons
/// sat in a column of nine labelled destinations and read as a lesser class
/// of control, and the tools menu hid six unrelated screens behind one
/// unlabelled widgets icon. These tests prove both actions now carry their
/// label at the tiers where the destinations beside them do, that neither
/// drops its name at the minimum window (a tooltip stands in, matching how
/// the destinations themselves collapse), and that the menu's contents are
/// now grouped rather than a single opaque list.
void main() {
  /// Pumps the shell at [width], 900 logical pixels tall.
  Future<void> pumpPanel(WidgetTester tester, {required double width}) =>
      tester.pumpShell(surfaceSize: Size(width, 900));

  testWidgets(
    'GivenTheExtendedBreakpoint_WhenBuilt_ThenBothActionsShowLabels',
    (tester) async {
      await pumpPanel(tester, width: 1400);

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
    },
  );

  // FR-UX-02: no entry is dropped at any breakpoint. At the minimum window the
  // label becomes a tooltip rather than disappearing.
  testWidgets(
    'GivenTheMinimumBreakpoint_WhenBuilt_ThenBothActionsKeepTooltips',
    (tester) async {
      await pumpPanel(tester, width: 640);

      expect(find.byTooltip('Library'), findsOneWidget);
      expect(find.byTooltip('Preferences'), findsOneWidget);
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
