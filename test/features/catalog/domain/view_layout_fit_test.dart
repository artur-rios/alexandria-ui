import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/catalog/domain/view_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether a layout fits where it is drawn (UC-10 AF-01, FR-CT-03).
void main() {
  group('the listing is too narrow (AF-01)', () {
    // Listing widths, not window widths: the panel, the divider, and the
    // screen padding come off the window before the rows are laid out, and
    // measuring the window is what made this decision wrong.
    //
    // At the minimum supported window (1024, NFR-07) the listing is about 820
    // wide; a comfortably wide window leaves it well past the floor.
    const atTheMinimumWindow = 820.0;
    const roomy = 1237.5;

    test('GivenTheList_WhenTheListingIsAtItsNarrowest_ThenItFits', () {
      expect(ViewLayout.list.fitsIn(atTheMinimumWindow), isTrue);
      expect(ViewLayout.grid.fitsIn(atTheMinimumWindow), isTrue);
    });

    test('GivenTheDetailedList_WhenTheListingIsNarrow_ThenItDoesNotFit', () {
      expect(ViewLayout.detailedList.fitsIn(atTheMinimumWindow), isFalse);
      expect(ViewLayout.detailedList.fitsIn(roomy), isTrue);
    });

    test('GivenTheFloor_WhenItIsRead_ThenItIsTheListingsAndNotTheWindows', () {
      // The regression this guards: borrowing the medium *window* breakpoint
      // as a listing floor refused the layout on a 1440 window, where the
      // listing is 1237.5 and the columns fit comfortably.
      expect(
        ViewLayout.detailedList.minimumListingWidth,
        lessThan(Breakpoint.mediumMinWidth),
      );
    });

    test('GivenTheDetailedList_WhenItDoesNotFit_ThenTheListIsDrawn', () {
      // The closest that fits: the same layout without the column that
      // stopped fitting, not a grid, which reads entirely differently.
      expect(
        ViewLayout.detailedList.resolvedFor(atTheMinimumWindow),
        ViewLayout.list,
      );
      expect(
        ViewLayout.detailedList.isSubstitutedAt(atTheMinimumWindow),
        isTrue,
      );
    });

    test('GivenALayoutThatFits_WhenItIsResolved_ThenItIsUnchanged', () {
      for (final layout in ViewLayout.values) {
        expect(layout.resolvedFor(roomy), layout);
        expect(layout.isSubstitutedAt(roomy), isFalse);
      }
    });

    test('GivenTheChoiceIsSubstituted_WhenTheWindowWidens_ThenItReturns', () {
      // The substitution is a drawing decision, not a change to the choice.
      expect(
        ViewLayout.detailedList.resolvedFor(roomy),
        ViewLayout.detailedList,
      );
    });
  });
}
