// EXPECT: avoid_data_layer_import
// Application reaching into Data, and reaching dart:ffi directly.
// ignore_for_file: public_member_api_docs, unused_import
import 'dart:ffi';

import '../data/sample_gateway.dart';

class ViolatingViewModel {}
