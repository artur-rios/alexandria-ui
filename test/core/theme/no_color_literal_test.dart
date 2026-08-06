import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BR-18 / FR-UX-07 / IR-10: every color comes from the active theme, never from
/// a literal declared in a component.
///
/// The analyzer has no rule for this, so the check is a test. It scans the
/// source rather than the widget tree deliberately: a literal that is only
/// reached in the dark theme's error state would never be caught by rendering.
///
/// `lib/core/theme/` is the one place allowed to name a color — that is what
/// makes it the single source.
void main() {
  /// `Color(0x…)`, `Colors.red`, `Color.fromARGB(…)`, `Color.fromRGBO(…)`.
  final colorLiteral = RegExp(
    r'\bColors?\s*\.\s*(?!of\b|lerp\b)[a-zA-Z]|\bColor\s*\(|\bColor\s*\.\s*from',
  );

  const allowedDirectories = <String>{'lib/core/theme'};

  const generatedSuffixes = <String>[
    '.freezed.dart',
    '.g.dart',
    'alexandria_bindings.dart',
  ];

  bool isExempt(String path) {
    final normalized = path.replaceAll(r'\', '/');
    if (generatedSuffixes.any(normalized.endsWith)) return true;
    if (normalized.contains('/l10n/generated/')) return true;
    return allowedDirectories.any(normalized.contains);
  }

  test('GivenTheSourceTree_WhenItIsScanned_ThenNoWidgetDeclaresAColor', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (isExempt(entity.path)) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        if (!colorLiteral.hasMatch(line)) continue;

        offenders.add(
          '${entity.path.replaceAll(r'\', '/')}:${i + 1}: ${line.trim()}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Colors come from Theme.of(context).colorScheme. Move these into '
          'lib/core/theme/, which is the single source of colors:\n'
          '${offenders.join('\n')}',
    );
  });

  test('GivenTheThemeFolder_WhenItIsScanned_ThenItIsWhereTheSeedLives', () {
    // The complement of the rule above: if nothing in lib/core/theme/ names a
    // color, the exemption has quietly stopped covering anything and the first
    // test above would pass for the wrong reason.
    final themeSources = Directory('lib/core/theme')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    expect(
      themeSources.any(
        (file) => colorLiteral.hasMatch(file.readAsStringSync()),
      ),
      isTrue,
      reason:
          'lib/core/theme/ declares no color at all, so the scan above is '
          'exempting an empty set',
    );
  });
}
