// EXPECT: avoid_domain_outward_import
// Domain reaching outward, which it may never do.
// ignore_for_file: public_member_api_docs, unused_import
import '../data/sample_gateway.dart';

class ViolatingModel {}
