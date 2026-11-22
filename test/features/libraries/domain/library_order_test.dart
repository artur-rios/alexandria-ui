import 'package:alexandria_ui/features/libraries/domain/library.dart';
import 'package:alexandria_ui/features/libraries/domain/library_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one A–Z the left menu, home and Manage libraries all list libraries
/// in.
void main() {
  Library library(String name, {String? uuid}) =>
      Library(uuid: uuid ?? name, name: name, rootPath: '/$name');

  test('GivenMixedCase_WhenSortedByName_ThenCaseIsIgnored', () {
    // The core sorts byte by byte, which puts "alpha" after "Zeta".
    final sorted = [library('Zeta'), library('alpha'), library('Beta')]
      ..sort(byLibraryName);

    expect([for (final l in sorted) l.name], ['alpha', 'Beta', 'Zeta']);
  });

  test('GivenTheSameName_WhenSortedByName_ThenTheUuidDecides', () {
    final sorted = [
      library('Course', uuid: 'lib-2'),
      library('course', uuid: 'lib-1'),
    ]..sort(byLibraryName);

    expect([for (final l in sorted) l.uuid], ['lib-1', 'lib-2']);
  });
}
