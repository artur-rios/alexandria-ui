import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'alexandria_bindings.dart';

/// The memory discipline for every string crossing the FFI boundary (IR-09).
///
/// Two directions, two owners, and they are not symmetric — which is the whole
/// reason this file exists rather than each gateway doing it inline.
extension type CoreStrings._(AlexandriaBindings _bindings) {
  /// Wraps the generated bindings.
  CoreStrings(AlexandriaBindings bindings) : this._(bindings);

  /// Reads a string the core returned and frees it, including when [read]
  /// throws.
  ///
  /// The `finally` is the point: a failure path that returns early is exactly
  /// where a leak hides, because the success path is the one anybody tests.
  T? consume<T>(Pointer<Char> pointer, T Function(String value) read) {
    if (pointer == nullptr) return null;

    try {
      return read(pointer.cast<Utf8>().toDartString());
    } finally {
      _bindings.alexandria_free_string(pointer);
    }
  }

  /// Reads a string the core owns for the life of the process, without freeing
  /// it.
  ///
  /// `alexandria_version` returns a pointer into a static `CString` in the Rust
  /// core, not an allocation the caller took ownership of. Passing it to
  /// `alexandria_free_string` would be a free of memory this library did not
  /// allocate — undefined behaviour, and a crash that would look like a core
  /// fault rather than a front-end one. It is called out here so nobody
  /// "fixes" the missing free.
  String? readStatic(Pointer<Char> pointer) =>
      pointer == nullptr ? null : pointer.cast<Utf8>().toDartString();
}

/// Passes a Dart string to the core and frees the copy afterwards, including
/// when [use] throws (IR-09).
///
/// The core never takes ownership of what it is passed; every `toNativeUtf8`
/// is the caller's to release.
T withNativeString<T>(String? value, T Function(Pointer<Char>) use) {
  if (value == null) return use(nullptr);

  final native = value.toNativeUtf8();
  try {
    return use(native.cast<Char>());
  } finally {
    calloc.free(native);
  }
}

/// Runs [body] with a native string for [value], or with `nullptr` when it is
/// null — which is how an absent optional argument reaches the core.
///
/// Distinct from [withNativeString] deliberately, at every call site that
/// passes an *optional* argument such as `priority`: an empty string and an
/// absent one are different arguments to the core, and collapsing them would
/// let a resume silently re-pace a run the owner throttled (FR-FC-33). Naming
/// the null case at the call site — `withNullableNativeString(priority, ...)`
/// rather than a bare `withNativeString(priority, ...)` that happens to accept
/// null too — is what keeps that distinction visible to a reader instead of
/// resting on an implementation detail of the non-nullable-looking helper.
T withNullableNativeString<T>(String? value, T Function(Pointer<Char>) body) =>
    value == null ? body(nullptr) : withNativeString(value, body);
