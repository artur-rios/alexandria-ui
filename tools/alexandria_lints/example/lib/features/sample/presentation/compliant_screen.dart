// EXPECT: clean
// Presentation depending on the Domain interface, which is allowed.
// ignore_for_file: public_member_api_docs, unused_import
import '../domain/sample_port.dart';

class CompliantScreen {
  const CompliantScreen(this.port);
  final SamplePort port;
}
