import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'layer.dart';

/// IR-02: **Domain imports nothing outward at all.**
///
/// The Domain layer owns the models, the gateway interfaces, and the failure
/// model. It may see Flutter's foundation types and other Domain code, and
/// nothing else — that is what lets the whole application be tested without a
/// native library present.
class AvoidDomainOutwardImport extends DartLintRule {
  const AvoidDomainOutwardImport() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_domain_outward_import',
    problemMessage:
        'The Domain layer must not import from the {0} layer. Domain depends '
        'on nothing outward.',
    correctionMessage:
        'Invert the dependency: declare an interface here and implement it in '
        'the outer layer.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (layerOf(resolver.path) != Layer.domain) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      final target = importedLayer(uri);
      if (target == null || target == Layer.domain) return;

      reporter.atNode(node, _code, arguments: [target.name]);
    });
  }
}
