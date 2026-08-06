import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'layer.dart';

/// IR-02: **Presentation and Application may not import from Data.**
///
/// They reach it only through the interfaces the Domain layer owns, bound in
/// the provider graph. Reaching `dart:ffi` or `package:ffi` counts as reaching
/// Data: the generated bindings are a Data-layer concern, and feature code
/// depends on the gateway interface instead (Technology Stack Document §3.2).
class AvoidDataLayerImport extends DartLintRule {
  const AvoidDataLayerImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_data_layer_import',
    problemMessage:
        'The {0} layer must not import from the Data layer. Depend on the '
        'gateway interface in the Domain layer and bind the implementation in '
        'the provider graph instead.',
    correctionMessage:
        'Move the type behind a Domain-layer interface, or move this file into '
        'the Data layer.',
  );

  static const _forbidden = {Layer.presentation, Layer.application};

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final from = layerOf(resolver.path);
    if (!_forbidden.contains(from)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      final reachesData =
          importedLayer(uri) == Layer.data ||
          uri == 'dart:ffi' ||
          uri.startsWith('package:ffi/');
      if (!reachesData) return;

      reporter.atNode(node, _code, arguments: [from!.name]);
    });
  }
}
