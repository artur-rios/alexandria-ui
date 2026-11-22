import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/shell/domain/menu_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// The order the left menu lists the libraries in: the pinned ones A–Z, then
/// the others A–Z.
void main() {
  Library library(String name, {bool pinned = false}) =>
      Library(uuid: name, name: name, rootPath: '/$name', pinned: pinned);

  List<String> namesOf(List<Library> libraries) => [
    for (final library in libraries) library.name,
  ];

  test('GivenPinnedAndUnpinned_WhenOrdered_ThenPinnedComeFirstEachAToZ', () {
    final ordered = menuOrder([
      library('b'),
      library('A', pinned: true),
      library('c'),
      library('B', pinned: true),
    ]);

    expect(namesOf(ordered), ['A', 'B', 'b', 'c']);
  });

  test('GivenNoPinned_WhenOrdered_ThenTheyAreAToZOnly', () {
    final ordered = menuOrder([library('c'), library('a'), library('B')]);

    expect(namesOf(ordered), ['a', 'B', 'c']);
  });

  test('GivenNoLibraries_WhenOrdered_ThenTheOrderIsEmpty', () {
    expect(menuOrder(const []), isEmpty);
  });
}
