import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test in `test/` and installs the golden comparator
/// (Testing Specification §7.1).
///
/// Flutter picks this file up by name; nothing imports it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // The framework installs a LocalFileComparator per suite, whose basedir is
  // the directory of the test file being run. That base is kept — only the
  // comparison is loosened.
  final installed = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = _TolerantGoldenComparator(installed.basedir);

  await testMain();
}

/// A golden comparator that allows a small proportion of pixels to differ.
///
/// Goldens are rendered by the host's graphics stack, and the same widget tree
/// does not rasterize identically everywhere: antialiasing along a rounded
/// corner or a one-pixel border differs between platforms, and this project is
/// developed on Windows while CI runs the suite on Linux. An exact comparison
/// would fail on that difference alone, which trains everyone to regenerate
/// goldens without looking — the one outcome §7.1 says is worse than having no
/// goldens at all.
///
/// The tolerance is deliberately small. A changed color, a moved control, or a
/// resized field moves far more than [_tolerance] of the image; a rounded
/// corner rasterized half a shade differently moves far less.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(Uri basedir)
    // LocalFileComparator derives its basedir from a test file's path, so it
    // is given one inside the directory it should compare against. The name is
    // never read.
    : super(basedir.resolve('flutter_test_config.dart'));

  /// The proportion of pixels allowed to differ, as a fraction.
  ///
  /// 0.5%: enough to absorb edge antialiasing across platforms, far too little
  /// to hide a control that moved or a color that changed.
  static const double _tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed) return true;

    if (result.diffPercent <= _tolerance) {
      // Reported rather than passed silently: a golden drifting just under the
      // threshold on every change is how a real regression eventually slips
      // through, and the log is where that becomes visible.
      debugPrint(
        'golden ${golden.pathSegments.last} differs by '
        '${(result.diffPercent * 100).toStringAsFixed(3)}%, within tolerance',
      );
      return true;
    }

    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

/// Whether goldens are compared on this platform at all.
///
/// Kept beside the comparator so the two are read together, and used by the
/// golden suites rather than duplicated in each.
bool get goldensAreComparable => Platform.isWindows || Platform.isLinux;
