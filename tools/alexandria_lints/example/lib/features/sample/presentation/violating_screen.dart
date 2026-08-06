// EXPECT: avoid_data_layer_import
// Presentation reaching into Data. This file exists to be reported; it is
// excluded from the analyzer in analysis_options.yaml and is asserted on by
// test/core/analysis/layering_lint_test.dart.
// ignore_for_file: public_member_api_docs, unused_import
import '../data/sample_gateway.dart';

class ViolatingScreen {
  final gateway = const SampleGateway();
}
