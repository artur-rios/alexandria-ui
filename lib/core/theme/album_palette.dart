import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

/// The colours the now-playing artwork is painted in (BR-18, FR-UX-07).
///
/// A theme extension rather than literals in the painters, because BR-18
/// puts every colour in `lib/core/theme/`, and these genuinely belong here:
/// they are not Material scheme colours, they are the colours of *objects* —
/// walnut, brushed aluminium, vinyl, magnetic tape — which do not change
/// with the theme any more than a real record player does when the room
/// lights dim.
///
/// The same in light and dark on purpose, for the reason [PlaybackColors]
/// records for its own surround: a walnut plinth is brown regardless of
/// which theme is active, because the device is an object on a shelf, not a
/// surface the theme tints.
@immutable
class AlbumPalette extends ThemeExtension<AlbumPalette> {
  /// Creates the palette.
  const AlbumPalette({
    required this.plinthTop,
    required this.plinthBottom,
    required this.plinthEdge,
    required this.deckFaceTop,
    required this.deckFaceBottom,
    required this.chromeLight,
    required this.chromeMid,
    required this.chromeDark,
    required this.wellDark,
    required this.panelDark,
    required this.panelEdge,
    required this.matInner,
    required this.matOuter,
    required this.vinylSheenTop,
    required this.vinylSheenBottom,
    required this.groove,
    required this.labelInk,
    required this.labelPaper,
    required this.discSheenA,
    required this.discSheenB,
    required this.discSheenC,
    required this.discSheenD,
    required this.discSheenE,
    required this.discHub,
    required this.discRing,
    required this.shellTop,
    required this.shellBottom,
    required this.reelHub,
    required this.reelTeeth,
    required this.tapePack,
    required this.tapeLabel,
    required this.tapeLabelInk,
    required this.glassTint,
    required this.glassSheen,
    required this.specular,
    required this.contactShadow,
    required this.displayInk,
    required this.displayGround,
    required this.indicator,
    required this.sleeveHues,
    required this.sleeveInk,
  });

  /// The lit face of the turntable plinth — walnut.
  final Color plinthTop;

  /// The shaded face of the plinth, where the walnut gradient runs darker.
  final Color plinthBottom;

  /// The plinth's chamfered edge, darker again — the shadow a bevel casts
  /// on itself.
  final Color plinthEdge;

  /// The lit part of a device's brushed-aluminium face (turntable, deck,
  /// cassette player body).
  final Color deckFaceTop;

  /// The shaded part of the same brushed-aluminium face.
  final Color deckFaceBottom;

  /// The brightest chrome highlight — trim rings, screws, hinges.
  final Color chromeLight;

  /// Chrome's mid tone, between [chromeLight] and [chromeDark].
  final Color chromeMid;

  /// Chrome in shadow.
  final Color chromeDark;

  /// The recessed well beneath a platter or mechanism — near-black.
  final Color wellDark;

  /// A control panel's dark surface.
  final Color panelDark;

  /// The shadow a panel's bevel casts along its own edge.
  final Color panelEdge;

  /// The inner ring of a turntable's slipmat.
  final Color matInner;

  /// The slipmat's outer ring, darker than [matInner].
  final Color matOuter;

  /// The highlight a record's black vinyl throws — vinyl reads blue-black
  /// under light, not flat grey.
  final Color vinylSheenTop;

  /// The base of the same vinyl, in shadow.
  final Color vinylSheenBottom;

  /// A record's groove lines, one step lighter than the vinyl around them
  /// so concentric rings stay legible.
  final Color groove;

  /// The ink printed on a record label.
  final Color labelInk;

  /// A record label's paper stock.
  final Color labelPaper;

  /// The first band of a compact disc's diffraction sweep.
  final Color discSheenA;

  /// The second band of the sweep.
  final Color discSheenB;

  /// The third band of the sweep.
  final Color discSheenC;

  /// The fourth band of the sweep.
  final Color discSheenD;

  /// The fifth band of the sweep.
  final Color discSheenE;

  /// A compact disc's centre hub.
  final Color discHub;

  /// The ring immediately around the hub.
  final Color discRing;

  /// The lit face of a cassette's shell.
  final Color shellTop;

  /// The shell's shaded face.
  final Color shellBottom;

  /// A cassette reel's centre hub.
  final Color reelHub;

  /// A cassette reel's drive teeth.
  final Color reelTeeth;

  /// The wound pack of magnetic tape, seen edge-on — warm brown, not black.
  final Color tapePack;

  /// A cassette's paper label.
  final Color tapeLabel;

  /// The ink printed on the cassette label.
  final Color tapeLabelInk;

  /// The tint of a cassette's window over the reels.
  final Color glassTint;

  /// The highlight glass throws across that tint.
  final Color glassSheen;

  /// A generic specular highlight, used wherever a curved surface catches
  /// the light regardless of which material it is.
  final Color specular;

  /// The soft shadow a device casts onto the plinth beneath it.
  final Color contactShadow;

  /// The ink a machine's screen is lit in.
  ///
  /// Amber, which is what the three photographed machines have: their screens
  /// are lit in it, and what this application prints over the top of what
  /// they were photographed showing has to be the same colour or the line it
  /// replaces would read as a repair.
  final Color displayInk;

  /// The near-black behind that ink — the glass of the screen with nothing
  /// lit on it, which is what covers the words the photograph was taken
  /// with.
  final Color displayGround;

  /// A device's power/play indicator light.
  final Color indicator;

  /// The hues a jacket sleeve is picked from, indexed by a hash of the
  /// album's name (Task 4). At least six, and chosen to differ in hue
  /// rather than only in lightness, so a library of many sleeves does not
  /// read as one colour repeated. Task 4 typesets the album title and
  /// artist directly over the sleeve in white, so every hue is also kept
  /// dark enough to carry white text — see
  /// `test/core/theme/album_palette_test.dart`.
  final List<Color> sleeveHues;

  /// The ink of the title and artist Task 4 typesets over a case's
  /// [sleeveHues] colour.
  ///
  /// A field of its own rather than `Colors.white` inline, because BR-18
  /// puts every colour in this file — and opaque white is exactly what
  /// `test/core/theme/album_palette_test.dart` already pins every sleeve hue
  /// to carry at a 4.5:1 contrast ratio, so this is that same value given a
  /// name rather than a second, independent choice.
  final Color sleeveInk;

  /// The values both themes use.
  static const AlbumPalette standard = AlbumPalette(
    plinthTop: Color(0xFF6B4A34),
    plinthBottom: Color(0xFF4A3020),
    plinthEdge: Color(0xFF2E1D12),
    deckFaceTop: Color(0xFF4A4E52),
    deckFaceBottom: Color(0xFF2C2F33),
    chromeLight: Color(0xFFE8EAEC),
    chromeMid: Color(0xFFA8ADB3),
    chromeDark: Color(0xFF5A5E63),
    wellDark: Color(0xFF1A1B1D),
    panelDark: Color(0xFF232629),
    panelEdge: Color(0xFF0F1011),
    matInner: Color(0xFF1C1C1E),
    matOuter: Color(0xFF141416),
    vinylSheenTop: Color(0xFF3A4552),
    vinylSheenBottom: Color(0xFF0A0B0D),
    groove: Color(0xFF1E2228),
    labelInk: Color(0xFF1A1410),
    labelPaper: Color(0xFFE8DCC0),
    discSheenA: Color(0xFFFF6B9D),
    discSheenB: Color(0xFFFFC85C),
    discSheenC: Color(0xFF7BE0A0),
    discSheenD: Color(0xFF5CC8E8),
    discSheenE: Color(0xFFB080F0),
    discHub: Color(0xFFC8CCD0),
    discRing: Color(0xFF9A9EA3),
    shellTop: Color(0xFF3C3E42),
    shellBottom: Color(0xFF232528),
    reelHub: Color(0xFFE0DACE),
    reelTeeth: Color(0xFF8A857A),
    tapePack: Color(0xFF3E2A1E),
    tapeLabel: Color(0xFFEDE3CC),
    tapeLabelInk: Color(0xFF2A2016),
    // Lifted from 0xB3 (Finding 9): at full opacity the tape deck's own
    // door washed the cassette's reel hubs out to the point of being barely
    // legible behind it — deferred at Task 3 to be judged in motion, and
    // this is the judgment.
    glassTint: Color(0x80303840),
    glassSheen: Color(0x66FFFFFF),
    specular: Color(0xFFF5F5F0),
    contactShadow: Color(0x66000000),
    displayInk: Color(0xFFFFBF00),
    displayGround: Color(0xFF0B0704),
    indicator: Color(0xFF4CD964),
    sleeveHues: [
      Color(0xFFB5473D),
      Color(0xFF3D6EB5),
      Color(0xFF357A45),
      Color(0xFF8A6D1E),
      Color(0xFF7C4FA0),
      Color(0xFFA6501F),
      Color(0xFF1F6E78),
    ],
    sleeveInk: Color(0xFFFFFFFF),
  );

  @override
  AlbumPalette copyWith({
    Color? plinthTop,
    Color? plinthBottom,
    Color? plinthEdge,
    Color? deckFaceTop,
    Color? deckFaceBottom,
    Color? chromeLight,
    Color? chromeMid,
    Color? chromeDark,
    Color? wellDark,
    Color? panelDark,
    Color? panelEdge,
    Color? matInner,
    Color? matOuter,
    Color? vinylSheenTop,
    Color? vinylSheenBottom,
    Color? groove,
    Color? labelInk,
    Color? labelPaper,
    Color? discSheenA,
    Color? discSheenB,
    Color? discSheenC,
    Color? discSheenD,
    Color? discSheenE,
    Color? discHub,
    Color? discRing,
    Color? shellTop,
    Color? shellBottom,
    Color? reelHub,
    Color? reelTeeth,
    Color? tapePack,
    Color? tapeLabel,
    Color? tapeLabelInk,
    Color? glassTint,
    Color? glassSheen,
    Color? specular,
    Color? contactShadow,
    Color? displayInk,
    Color? displayGround,
    Color? indicator,
    List<Color>? sleeveHues,
    Color? sleeveInk,
  }) => AlbumPalette(
    plinthTop: plinthTop ?? this.plinthTop,
    plinthBottom: plinthBottom ?? this.plinthBottom,
    plinthEdge: plinthEdge ?? this.plinthEdge,
    deckFaceTop: deckFaceTop ?? this.deckFaceTop,
    deckFaceBottom: deckFaceBottom ?? this.deckFaceBottom,
    chromeLight: chromeLight ?? this.chromeLight,
    chromeMid: chromeMid ?? this.chromeMid,
    chromeDark: chromeDark ?? this.chromeDark,
    wellDark: wellDark ?? this.wellDark,
    panelDark: panelDark ?? this.panelDark,
    panelEdge: panelEdge ?? this.panelEdge,
    matInner: matInner ?? this.matInner,
    matOuter: matOuter ?? this.matOuter,
    vinylSheenTop: vinylSheenTop ?? this.vinylSheenTop,
    vinylSheenBottom: vinylSheenBottom ?? this.vinylSheenBottom,
    groove: groove ?? this.groove,
    labelInk: labelInk ?? this.labelInk,
    labelPaper: labelPaper ?? this.labelPaper,
    discSheenA: discSheenA ?? this.discSheenA,
    discSheenB: discSheenB ?? this.discSheenB,
    discSheenC: discSheenC ?? this.discSheenC,
    discSheenD: discSheenD ?? this.discSheenD,
    discSheenE: discSheenE ?? this.discSheenE,
    discHub: discHub ?? this.discHub,
    discRing: discRing ?? this.discRing,
    shellTop: shellTop ?? this.shellTop,
    shellBottom: shellBottom ?? this.shellBottom,
    reelHub: reelHub ?? this.reelHub,
    reelTeeth: reelTeeth ?? this.reelTeeth,
    tapePack: tapePack ?? this.tapePack,
    tapeLabel: tapeLabel ?? this.tapeLabel,
    tapeLabelInk: tapeLabelInk ?? this.tapeLabelInk,
    glassTint: glassTint ?? this.glassTint,
    glassSheen: glassSheen ?? this.glassSheen,
    specular: specular ?? this.specular,
    contactShadow: contactShadow ?? this.contactShadow,
    displayInk: displayInk ?? this.displayInk,
    displayGround: displayGround ?? this.displayGround,
    indicator: indicator ?? this.indicator,
    sleeveHues: sleeveHues ?? this.sleeveHues,
    sleeveInk: sleeveInk ?? this.sleeveInk,
  );

  @override
  AlbumPalette lerp(ThemeExtension<AlbumPalette>? other, double t) {
    if (other is! AlbumPalette) return this;

    List<Color> lerpHues(List<Color> a, List<Color> b, double t) {
      if (a.length != b.length) return t < 0.5 ? a : b;

      return [
        for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t) ?? a[i],
      ];
    }

    return AlbumPalette(
      plinthTop: Color.lerp(plinthTop, other.plinthTop, t) ?? plinthTop,
      plinthBottom:
          Color.lerp(plinthBottom, other.plinthBottom, t) ?? plinthBottom,
      plinthEdge: Color.lerp(plinthEdge, other.plinthEdge, t) ?? plinthEdge,
      deckFaceTop: Color.lerp(deckFaceTop, other.deckFaceTop, t) ?? deckFaceTop,
      deckFaceBottom:
          Color.lerp(deckFaceBottom, other.deckFaceBottom, t) ?? deckFaceBottom,
      chromeLight: Color.lerp(chromeLight, other.chromeLight, t) ?? chromeLight,
      chromeMid: Color.lerp(chromeMid, other.chromeMid, t) ?? chromeMid,
      chromeDark: Color.lerp(chromeDark, other.chromeDark, t) ?? chromeDark,
      wellDark: Color.lerp(wellDark, other.wellDark, t) ?? wellDark,
      panelDark: Color.lerp(panelDark, other.panelDark, t) ?? panelDark,
      panelEdge: Color.lerp(panelEdge, other.panelEdge, t) ?? panelEdge,
      matInner: Color.lerp(matInner, other.matInner, t) ?? matInner,
      matOuter: Color.lerp(matOuter, other.matOuter, t) ?? matOuter,
      vinylSheenTop:
          Color.lerp(vinylSheenTop, other.vinylSheenTop, t) ?? vinylSheenTop,
      vinylSheenBottom:
          Color.lerp(vinylSheenBottom, other.vinylSheenBottom, t) ??
          vinylSheenBottom,
      groove: Color.lerp(groove, other.groove, t) ?? groove,
      labelInk: Color.lerp(labelInk, other.labelInk, t) ?? labelInk,
      labelPaper: Color.lerp(labelPaper, other.labelPaper, t) ?? labelPaper,
      discSheenA: Color.lerp(discSheenA, other.discSheenA, t) ?? discSheenA,
      discSheenB: Color.lerp(discSheenB, other.discSheenB, t) ?? discSheenB,
      discSheenC: Color.lerp(discSheenC, other.discSheenC, t) ?? discSheenC,
      discSheenD: Color.lerp(discSheenD, other.discSheenD, t) ?? discSheenD,
      discSheenE: Color.lerp(discSheenE, other.discSheenE, t) ?? discSheenE,
      discHub: Color.lerp(discHub, other.discHub, t) ?? discHub,
      discRing: Color.lerp(discRing, other.discRing, t) ?? discRing,
      shellTop: Color.lerp(shellTop, other.shellTop, t) ?? shellTop,
      shellBottom: Color.lerp(shellBottom, other.shellBottom, t) ?? shellBottom,
      reelHub: Color.lerp(reelHub, other.reelHub, t) ?? reelHub,
      reelTeeth: Color.lerp(reelTeeth, other.reelTeeth, t) ?? reelTeeth,
      tapePack: Color.lerp(tapePack, other.tapePack, t) ?? tapePack,
      tapeLabel: Color.lerp(tapeLabel, other.tapeLabel, t) ?? tapeLabel,
      tapeLabelInk:
          Color.lerp(tapeLabelInk, other.tapeLabelInk, t) ?? tapeLabelInk,
      glassTint: Color.lerp(glassTint, other.glassTint, t) ?? glassTint,
      glassSheen: Color.lerp(glassSheen, other.glassSheen, t) ?? glassSheen,
      specular: Color.lerp(specular, other.specular, t) ?? specular,
      contactShadow:
          Color.lerp(contactShadow, other.contactShadow, t) ?? contactShadow,
      displayInk: Color.lerp(displayInk, other.displayInk, t) ?? displayInk,
      displayGround:
          Color.lerp(displayGround, other.displayGround, t) ?? displayGround,
      indicator: Color.lerp(indicator, other.indicator, t) ?? indicator,
      sleeveHues: lerpHues(sleeveHues, other.sleeveHues, t),
      sleeveInk: Color.lerp(sleeveInk, other.sleeveInk, t) ?? sleeveInk,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumPalette &&
          runtimeType == other.runtimeType &&
          plinthTop == other.plinthTop &&
          plinthBottom == other.plinthBottom &&
          plinthEdge == other.plinthEdge &&
          deckFaceTop == other.deckFaceTop &&
          deckFaceBottom == other.deckFaceBottom &&
          chromeLight == other.chromeLight &&
          chromeMid == other.chromeMid &&
          chromeDark == other.chromeDark &&
          wellDark == other.wellDark &&
          panelDark == other.panelDark &&
          panelEdge == other.panelEdge &&
          matInner == other.matInner &&
          matOuter == other.matOuter &&
          vinylSheenTop == other.vinylSheenTop &&
          vinylSheenBottom == other.vinylSheenBottom &&
          groove == other.groove &&
          labelInk == other.labelInk &&
          labelPaper == other.labelPaper &&
          discSheenA == other.discSheenA &&
          discSheenB == other.discSheenB &&
          discSheenC == other.discSheenC &&
          discSheenD == other.discSheenD &&
          discSheenE == other.discSheenE &&
          discHub == other.discHub &&
          discRing == other.discRing &&
          shellTop == other.shellTop &&
          shellBottom == other.shellBottom &&
          reelHub == other.reelHub &&
          reelTeeth == other.reelTeeth &&
          tapePack == other.tapePack &&
          tapeLabel == other.tapeLabel &&
          tapeLabelInk == other.tapeLabelInk &&
          glassTint == other.glassTint &&
          glassSheen == other.glassSheen &&
          specular == other.specular &&
          contactShadow == other.contactShadow &&
          displayInk == other.displayInk &&
          displayGround == other.displayGround &&
          indicator == other.indicator &&
          listEquals(sleeveHues, other.sleeveHues) &&
          sleeveInk == other.sleeveInk;

  @override
  int get hashCode => Object.hashAll([
    plinthTop,
    plinthBottom,
    plinthEdge,
    deckFaceTop,
    deckFaceBottom,
    chromeLight,
    chromeMid,
    chromeDark,
    wellDark,
    panelDark,
    panelEdge,
    matInner,
    matOuter,
    vinylSheenTop,
    vinylSheenBottom,
    groove,
    labelInk,
    labelPaper,
    discSheenA,
    discSheenB,
    discSheenC,
    discSheenD,
    discSheenE,
    discHub,
    discRing,
    shellTop,
    shellBottom,
    reelHub,
    reelTeeth,
    tapePack,
    tapeLabel,
    tapeLabelInk,
    glassTint,
    glassSheen,
    specular,
    contactShadow,
    displayInk,
    displayGround,
    indicator,
    Object.hashAll(sleeveHues),
    sleeveInk,
  ]);
}

/// Reads the album palette from [context].
extension AlbumPaletteOf on BuildContext {
  /// The album palette the active theme carries.
  AlbumPalette get albumPalette =>
      Theme.of(this).extension<AlbumPalette>() ?? AlbumPalette.standard;
}
