import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// IR-11: the build fails when a key is missing from either catalog.
///
/// `flutter gen-l10n` records untranslated messages but does not fail on them,
/// so this test is what turns the record into a build failure. It is deliberately
/// a plain file comparison rather than a check of the generated classes: the
/// generated code falls back to the template silently, which is exactly the
/// behavior that would hide a missing translation.
void main() {
  const catalogDirectory = 'lib/core/l10n';
  const templateFile = 'app_en.arb';

  Map<String, dynamic> readCatalog(String fileName) {
    final file = File('$catalogDirectory/$fileName');
    expect(
      file.existsSync(),
      isTrue,
      reason: '$fileName is missing from $catalogDirectory',
    );
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  // Keys beginning with `@` are metadata — `@@locale` and the per-message
  // descriptions and placeholders — and only the template carries them.
  Set<String> messageKeys(Map<String, dynamic> catalog) =>
      catalog.keys.where((key) => !key.startsWith('@')).toSet();

  late Set<String> templateKeys;
  late List<String> translationFiles;

  setUpAll(() {
    templateKeys = messageKeys(readCatalog(templateFile));
    translationFiles = Directory(catalogDirectory)
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.arb') && name != templateFile)
        .toList()
      ..sort();
  });

  test('GivenTheCatalogFolder_WhenItIsRead_ThenBothLanguagesArePresent', () {
    expect(
      translationFiles,
      contains('app_pt.arb'),
      reason:
          'pt-BR is a supported language; its catalog is the base `pt` file, '
          'because gen_l10n requires a base locale alongside a country-coded one',
    );
    expect(templateKeys, isNotEmpty);
  });

  test('GivenATranslationCatalog_WhenItIsCompared_ThenNoKeyIsMissing', () {
    for (final fileName in translationFiles) {
      final missing = templateKeys.difference(
        messageKeys(readCatalog(fileName)),
      );

      expect(
        missing,
        isEmpty,
        reason:
            '$fileName is missing ${missing.length} key(s) present in '
            '$templateFile: ${missing.join(', ')}',
      );
    }
  });

  test('GivenATranslationCatalog_WhenItIsCompared_ThenNoKeyIsOrphaned', () {
    for (final fileName in translationFiles) {
      final orphaned = messageKeys(
        readCatalog(fileName),
      ).difference(templateKeys);

      expect(
        orphaned,
        isEmpty,
        reason:
            '$fileName defines ${orphaned.length} key(s) absent from '
            '$templateFile: ${orphaned.join(', ')}. A translation with no '
            'template entry is dead weight that reads as coverage',
      );
    }
  });

  test('GivenTheTemplateCatalog_WhenItIsRead_ThenEveryMessageIsDescribed', () {
    final template = readCatalog(templateFile);

    for (final key in messageKeys(template)) {
      final metadata = template['@$key'];

      expect(
        metadata,
        isA<Map<String, dynamic>>(),
        reason: '$key has no @$key metadata block in $templateFile',
      );
      expect(
        (metadata as Map<String, dynamic>)['description'],
        isA<String>().having((it) => it.trim(), 'description', isNotEmpty),
        reason:
            '$key has no description. A translator cannot render a string they '
            'cannot see the context for',
      );
    }
  });

  test(
    'GivenATranslationCatalog_WhenAMessageTakesPlaceholders_ThenTheyAllAppear',
    () {
      final template = readCatalog(templateFile);

      for (final fileName in translationFiles) {
        final translation = readCatalog(fileName);

        for (final key in messageKeys(template)) {
          final metadata =
              template['@$key'] as Map<String, dynamic>? ?? const {};
          final placeholders =
              (metadata['placeholders'] as Map<String, dynamic>?)?.keys ??
              const <String>[];
          final translated = translation[key] as String?;
          if (translated == null) continue;

          for (final placeholder in placeholders) {
            expect(
              translated,
              contains('{$placeholder}'),
              reason:
                  '$fileName: "$key" drops the {$placeholder} placeholder, so '
                  'the message would render without the detail that makes it '
                  'actionable',
            );
          }
        }
      }
    },
  );
}
