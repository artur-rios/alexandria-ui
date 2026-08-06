import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/avoid_data_layer_import.dart';
import 'src/avoid_domain_outward_import.dart';

/// Entry point `custom_lint` looks for.
PluginBase createPlugin() => _AlexandriaLints();

class _AlexandriaLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const AvoidDataLayerImport(),
    const AvoidDomainOutwardImport(),
  ];
}
