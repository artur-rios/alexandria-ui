import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// IR-02: the dependency rule is enforced by analyzer rules that fail the
/// build.
///
/// This runs the real `custom_lint` over a package built entirely out of
/// layering violations, so what is asserted is the plugin's own output — not a
/// reimplementation of its logic, which would keep passing while the plugin
/// failed to load.
///
/// The fixtures are stored as `.dart.txt` and assembled into a temporary
/// package at run time. Committing them as `.dart` anywhere inside this
/// repository would put them in the path of the project's own
/// `dart run custom_lint`, which walks the whole tree and takes no path
/// argument — the fixtures would then fail the build they exist to verify.
///
/// It lives outside `test/` because it shells out and takes several seconds,
/// the same structural split the Testing Specification uses for
/// `integration_test/`:
///
///     flutter test analysis_test --timeout 5x
void main() {
  final repositoryRoot = Directory.current.path;
  final fixtures = Directory(p.join(repositoryRoot, 'analysis_test/fixtures'));

  late Directory package;
  late String output;
  late int exitCode;

  setUpAll(() async {
    package = Directory.systemTemp.createTempSync('alexandria_layering');

    // The same layout the real source tree uses, because the rules decide from
    // the path: lib/features/<feature>/<layer>/.
    for (final template
        in fixtures.listSync(recursive: true).whereType<File>()) {
      final relative = p.relative(template.path, from: fixtures.path);
      final destination = File(
        p.join(
          package.path,
          'lib/features/sample',
          relative.replaceAll('.dart.txt', '.dart'),
        ),
      );
      destination.parent.createSync(recursive: true);
      destination.writeAsStringSync(template.readAsStringSync());
    }

    File(p.join(package.path, 'pubspec.yaml')).writeAsStringSync('''
name: alexandria_layering_fixture
publish_to: "none"
environment:
  sdk: ^3.12.2
dev_dependencies:
  alexandria_lints:
    path: ${p.join(repositoryRoot, 'tools/alexandria_lints').replaceAll(r'\', '/')}
  custom_lint: ^0.8.1
''');

    // Only the layering rules run here; the project's style rules would bury
    // the diagnostics this test asserts on.
    File(p.join(package.path, 'analysis_options.yaml')).writeAsStringSync('''
analyzer:
  plugins:
    - custom_lint
''');

    final get = await Process.run(
      'dart',
      const ['pub', 'get'],
      workingDirectory: package.path,
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
      workingDirectory: package.path,
      runInShell: true,
    );
    output = '${result.stdout}\n${result.stderr}';
    exitCode = result.exitCode;
  });

  tearDownAll(() {
    if (package.existsSync()) package.deleteSync(recursive: true);
  });

  test('GivenLayeringViolations_WhenAnalyzed_ThenTheBuildFails', () {
    expect(
      exitCode,
      isNot(0),
      reason:
          'IR-02 asks for rules that fail the build, so a non-zero exit is the '
          'requirement, not a side effect:\n$output',
    );
  });

  test('GivenPresentationImportingData_WhenAnalyzed_ThenItIsReported', () {
    expect(output, contains('violating_screen.dart'));
    expect(output, contains('avoid_data_layer_import'));
  });

  test('GivenApplicationImportingData_WhenAnalyzed_ThenItIsReported', () {
    expect(output, contains('violating_view_model.dart'));
  });

  test('GivenApplicationImportingDartFfi_WhenAnalyzed_ThenItIsReported', () {
    // The generated bindings are a Data-layer concern; feature code depends on
    // the gateway interface instead. The fixture imports dart:ffi on its own
    // line, so two diagnostics land in that one file.
    expect(
      'avoid_data_layer_import'.allMatches(output).length,
      greaterThanOrEqualTo(3),
      reason: 'expected the dart:ffi import to be reported as well:\n$output',
    );
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
      isNot(contains('sample_gateway.dart:')),
      reason: 'the Data layer is allowed to be the Data layer',
    );
  });
}
