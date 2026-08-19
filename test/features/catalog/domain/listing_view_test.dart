import 'package:alexandria_desktop/features/catalog/domain/listing_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_catalog_gateway.dart';

/// Filtering and ordering a listing (UC-12, FR-CT-07, FR-CT-08).
void main() {
  group('what a listing opens on', () {
    test('GivenAFreshListing_WhenItIsRead_ThenItShowsWhatIsInTheLibrary', () {
      expect(ListingView.initial.lifecycle, LifecycleFilter.active);
      expect(ListingView.initial.sortField, SortField.name);
      expect(ListingView.initial.direction, SortDirection.ascending);
    });

    test('GivenTheDefaultView_WhenItIsChecked_ThenNothingIsFilteredAway', () {
      expect(ListingView.initial.isFiltered, isFalse);
    });

    test('GivenAChangedSort_WhenItIsChecked_ThenNothingIsFilteredAway', () {
      // A sort orders without hiding anything, which is why clearing the
      // filters does not un-order the listing.
      expect(
        ListingView.initial
            .copyWith(sortField: SortField.indexed)
            .isFiltered,
        isFalse,
      );
    });

    test('GivenADeletedFilter_WhenItIsChecked_ThenSomethingIsFilteredAway', () {
      expect(
        ListingView.initial
            .copyWith(lifecycle: LifecycleFilter.deleted)
            .isFiltered,
        isTrue,
      );
    });
  });

  group('remembering it', () {
    test('GivenAView_WhenItIsWrittenAndRead_ThenItSurvivesUnchanged', () {
      const view = ListingView(
        lifecycle: LifecycleFilter.all,
        sortField: SortField.indexed,
        direction: SortDirection.descending,
      );

      expect(ListingView.fromJson(view.toJson()), view);
    });

    test('GivenAPartialDocument_WhenItIsRead_ThenTheKnownFieldsSurvive', () {
      // Written by another version: the fields it knew are still the owner's
      // choices, and the ones it did not fall back individually.
      final view = ListingView.fromJson({'sortField': 'indexed'});

      expect(view.sortField, SortField.indexed);
      expect(view.lifecycle, LifecycleFilter.active);
      expect(view.direction, SortDirection.ascending);
    });

    test('GivenUnknownValues_WhenTheyAreRead_ThenEachFallsBack', () {
      final view = ListingView.fromJson({
        'lifecycle': 'archived',
        'sortField': 'popularity',
        'direction': 'sideways',
      });

      expect(view, ListingView.initial);
    });
  });

  group('ordering (FR-CT-08)', () {
    final files = [
      aFile(uuid: '1', name: 'giant steps.flac', indexedAt: DateTime.utc(2026, 3)),
      aFile(uuid: '2', name: 'Blue Train.flac', indexedAt: DateTime.utc(2026, 1)),
      aFile(uuid: '3', name: 'Kind of Blue.flac', indexedAt: DateTime.utc(2026, 2)),
    ];

    test('GivenNameAscending_WhenSorted_ThenItIgnoresCase', () {
      // A library sorted with every capital first is not sorted the way
      // anyone reads.
      final sorted = sortFiles(files, ListingView.initial);

      expect(sorted.map((file) => file.uuid), ['2', '1', '3']);
    });

    test('GivenNameDescending_WhenSorted_ThenTheOrderReverses', () {
      final sorted = sortFiles(
        files,
        ListingView.initial.copyWith(direction: SortDirection.descending),
      );

      expect(sorted.map((file) => file.uuid), ['3', '1', '2']);
    });

    test('GivenDateAscending_WhenSorted_ThenTheOldestIsFirst', () {
      final sorted = sortFiles(
        files,
        ListingView.initial.copyWith(sortField: SortField.indexed),
      );

      expect(sorted.map((file) => file.uuid), ['2', '3', '1']);
    });

    test('GivenAFileWithNoDate_WhenSortedByDate_ThenItIsTheOldest', () {
      // Missing information, not a reason to refuse to sort.
      final undated = aFile(uuid: '4', name: 'undated.flac');
      final sorted = sortFiles(
        [...files, undated],
        ListingView.initial.copyWith(sortField: SortField.indexed),
      );

      expect(sorted.first.uuid, '4');
    });

    test('GivenAListing_WhenItIsSorted_ThenTheOriginalIsNotDisturbed', () {
      final original = [...files];

      sortFiles(files, ListingView.initial);

      expect(files, original);
    });
  });
}
