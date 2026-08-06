import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// IR-02: the dependency rule is enforced by analyzer rules that fail the
/// build.
///
/// This runs the real `custom_lint` over the fixture package in
/// `tools/alexandria_lints/example/`, so what is asserted is what CI runs — not
/// a reimplementation of the rule's logic, which would pass happily while the
/// plugin failed to load.
///
/// It lives outside `test/` because it shells out and takes several seconds,
/// and the same structural split the Testing Specification uses for
/// `integration_test/` applies: `test/` is everything that runs on every
/// change, and this runs as its own step.
///
///     flutter test analysis_test
void main() {
  const fixturePackage = 'tools/alexandria_lints/example';

  late String output;

  setUpAll(() async {
    final get = await Process.run(
      'dart',
      const ['pub', 'get'],
      workingDirectory: fixturePackage,
      runInShell: true,
    );
    expect(
      get.exitCode,
      0,
      reason: 'could not resolve the fixture package: ${get.stderr}',
    );

    final result = await Process.run(
      'dart',
      const ['run', 'custom_lint'],
      workingDirectory: fixturePackage,
      runInShell: true,
    );
    output = '${result.stdout}\n${result.stderr}';

    expect(
      result.exitCode,
      isNot(0),
      reason:
          'custom_lint reported nothing on a package built entirely out of '
          'layering violations, which means the plugin did not run:\n$output',
    );
  });

  test('GivenPresentationImportingData_WhenAnalyzed_ThenItIsReported', () {
    expect(output, contains('violating_screen.dart'));
    expect(output, contains('avoid_data_layer_import'));
  });

  test('GivenApplicationImportingData_WhenAnalyzed_ThenItIsReported', () {
    expect(output, contains('violating_view_model.dart'));
  });

  test('GivenDomainImportingOutward_WhenAnalyzed_ThenItIsReported', () {
    expect(output, contains('violating_model.dart'));
    expect(output, contains('avoid_domain_outward_import'));
  });

  test('GivenPresentationImportingDomain_WhenAnalyzed_ThenItIsNotReported', () {
    expect(
      output,
      isNot(contains('compliant_screen.dart')),
      reason:
          'depending on the Domain interface is the pattern the rule exists to '
          'push people towards; flagging it would make the rule unusable',
    );
  });

  test('GivenTheDataLayerItself_WhenAnalyzed_ThenItIsNotReported', () {
    expect(
      output,
      isNot(contains('sample_gateway.dart')),
      reason: 'the Data layer is allowed to be the Data layer',
    );
  });
}
