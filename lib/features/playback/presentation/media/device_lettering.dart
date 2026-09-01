/// The typeface everything painted onto a device or a sleeve is set in
/// (Testing Specification §7.1).
///
/// Bundled with the application (`pubspec.yaml`'s `fonts:` block) rather than
/// asked of the host, and that is the whole point. A `TextPainter` does not
/// inherit from a `Theme` — it carries the style it is given — so leaving the
/// family null does not fall back to the application's typeface, it falls
/// back to the host's, which is a different face on each platform. That is
/// what made these goldens fail on Linux while passing on the machine that
/// made them, and it is just as true of a nameplate as of a sleeve: the same
/// title at the same size would be cut at a different word on Windows.
///
/// The name is this application's, not the typeface's: the files are Roboto,
/// but a bundled family actually *called* Roboto is what Material's default
/// typography resolves to, so it would restyle every screen in the
/// application rather than this one drawing.
const String deviceFontFamily = 'AlexandriaSleeve';
