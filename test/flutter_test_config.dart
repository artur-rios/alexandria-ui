import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test in `test/` and installs the golden comparator
/// (Testing Specification §7.1).
///
/// Flutter picks this file up by name; nothing imports it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  /// The golden to compare against on this platform.
  ///
  /// A file named `shell_medium_light.windows.png` beside
  /// `shell_medium_light.png` is used in its place when this is Windows. Most
  /// goldens need no such variant — a painted shape rasterizes the same
  /// everywhere within tolerance — so the base file stays the single
  /// reference for all of them, and a variant exists only where two
  /// platforms genuinely disagree.
  ///
  /// Which is text. Two operating systems do not paint identical glyph
  /// outlines identically: hinting, subpixel positioning and antialiasing all
  /// differ, by 3.1-4.7% of the image on the text-heavy goldens this was
  /// first measured on. The shell goldens hold little text and differ by
  /// 0.15-0.26%, inside [_tolerance], so they need none. A variant is how
  /// both platforms get a real check instead of one of them getting none.
  Uri _forThisPlatform(Uri golden) {
    final variant = _platformVariant(golden);
    if (variant == null) return golden;

    return File.fromUri(basedir.resolveUri(variant)).existsSync()
        ? variant
        : golden;
  }

  /// `goldens/shell_medium_light.png` →
  /// `goldens/shell_medium_light.windows.png`, or `null`
  /// on the platform whose renderer the base files hold.
  Uri? _platformVariant(Uri golden) {
    if (Platform.isLinux) return null;

    final path = golden.toString();
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;

    final suffix = Platform.isWindows ? 'windows' : Platform.operatingSystem;

    return Uri.parse('${path.substring(0, dot)}.$suffix${path.substring(dot)}');
  }

  /// Writes a regenerated golden to whichever file this platform is the
  /// reference for.
  ///
  /// Linux writes the base file; anything else writes its own variant, so
  /// `--update-goldens` on Windows cannot overwrite the reference Linux
  /// compares against — which is exactly how one platform's rasterization
  /// would otherwise be committed as everyone's.
  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      super.update(_platformVariant(golden) ?? golden, imageBytes);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    golden = _forThisPlatform(golden);

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
///
/// Windows and Linux. A golden that draws text is a picture of one renderer:
/// two operating systems do not rasterize the same glyphs identically —
/// different hinting, different subpixel positioning, different antialiasing
/// of the same outlines — and a tolerance wide enough to swallow that is wide
/// enough to swallow a moved control, the one thing these exist to catch. So
/// where the two genuinely differ, each holds its own reference (see
/// `_forThisPlatform`) rather than one of them going unchecked. A golden
/// nobody compares on the platform they develop on is a golden that only CI
/// can defend.
bool get goldensAreComparable => Platform.isWindows || Platform.isLinux;
