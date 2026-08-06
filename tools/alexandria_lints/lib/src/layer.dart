/// The four layers of the architecture in
/// docs/requirements/Operations & Infrastructure Document.md §2.2.
enum Layer { domain, application, data, presentation }

/// The layer a path belongs to, or `null` when it sits outside the layered
/// tree.
///
/// `lib/main.dart` and `lib/core/di/` are deliberately unlayered: the
/// composition root is the one place allowed to see every layer, which is what
/// IR-07 asks of it.
Layer? layerOf(String path) {
  final segments = path.replaceAll(r'\', '/').split('/');
  for (final layer in Layer.values) {
    if (segments.contains(layer.name)) return layer;
  }
  return null;
}

/// Whether an import URI points inside this package.
///
/// `package:flutter/...` and `dart:async` are outside it and are never
/// restricted by a layering rule; a relative URI is always inside.
bool isInternal(String uri) =>
    !uri.startsWith('dart:') &&
    (!uri.startsWith('package:') || uri.startsWith('package:alexandria_desktop/'));

/// The layer an import URI points at, as written in the directive.
///
/// Resolves `package:alexandria_desktop/features/auth/data/x.dart` and
/// `../data/x.dart` alike: both carry the layer as a path segment.
Layer? importedLayer(String uri) => isInternal(uri) ? layerOf(uri) : null;
