import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// The core's auth-mode setting, read at `alexandria_index_init`.
const String coreAuthModeVariable = 'ALEXANDRIA_AUTH_MODE';

/// The only mode this application can work in.
const String localAuthMode = 'local';

/// Whether the application has to set the core's auth mode itself.
///
/// An explicit setting always wins — including one this application would have
/// chosen anyway. A developer or a build pipeline that named a mode has said
/// something deliberate, and silently overriding it would make a configured
/// run behave like an unconfigured one.
///
/// A variable set to blank counts as unset: the core would fail to parse it and
/// fall back to its own default, which is the state this exists to avoid.
bool shouldSetAuthMode(Map<String, String> environment) =>
    (environment[coreAuthModeVariable] ?? '').trim().isEmpty;

/// Puts the core into local auth mode before it is initialized.
///
/// The core loads its settings at `alexandria_index_init` from `config.toml`
/// and `ALEXANDRIA_*` environment overrides, and **its auth mode defaults to
/// `external`**. In that mode it refuses every local-auth call before checking
/// anything: `alexandria_auth_local_login` and `alexandria_auth_local_register`
/// both fail, so the owner cannot sign in or sign up at all. Nothing in the
/// application set the variable, so a real launch refused every attempt with a
/// message about credentials — which was true of nothing.
///
/// Local is not a preference here, it is the only mode that can work. This
/// application links the core in process and talks to no server, and external
/// mode authenticates against a JWKS endpoint that a serverless single-user
/// product has no reason to have. The application is the embedder, so choosing
/// the mode it embeds the core in is its call.
///
/// This is configuration through the core's own documented surface, not a way
/// around it (BR-02): the variable is the one the core reads, and it is set
/// before the core reads it rather than instead of the core reading it.
///
/// Must run before `alexandria_index_init`, which is the call that loads the
/// settings; afterwards the mode is fixed for the process.
void ensureLocalAuthMode({Map<String, String>? environment}) {
  if (!shouldSetAuthMode(environment ?? Platform.environment)) return;

  setProcessEnvironment(coreAuthModeVariable, localAuthMode);
}

/// Sets [name] to [value] in this process's environment.
///
/// Dart offers no way to do this — `Platform.environment` is a read-only
/// snapshot — so it goes through the platform's own call. Rust's `std::env`
/// reads the same store on both platforms: the Win32 environment block on
/// Windows, and `environ` on Linux.
///
/// Windows deliberately uses `SetEnvironmentVariableW` rather than the C
/// runtime's `_putenv`. They are separate stores, and Rust reads the Win32 one,
/// so the C runtime call would appear to work and change nothing.
void setProcessEnvironment(String name, String value) {
  if (Platform.isWindows) {
    final nativeName = name.toNativeUtf16();
    final nativeValue = value.toNativeUtf16();
    try {
      _setEnvironmentVariableW(nativeName, nativeValue);
    } finally {
      calloc
        ..free(nativeName)
        ..free(nativeValue);
    }
    return;
  }

  final nativeName = name.toNativeUtf8();
  final nativeValue = value.toNativeUtf8();
  try {
    // overwrite: 1 — the caller has already decided this should be set, and
    // this function's job is to do what it was told.
    _setenv(nativeName.cast(), nativeValue.cast(), 1);
  } finally {
    calloc
      ..free(nativeName)
      ..free(nativeValue);
  }
}

final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

final int Function(Pointer<Utf16>, Pointer<Utf16>) _setEnvironmentVariableW =
    _kernel32
        .lookup<NativeFunction<Int32 Function(Pointer<Utf16>, Pointer<Utf16>)>>(
          'SetEnvironmentVariableW',
        )
        .asFunction();

final int Function(Pointer<Char>, Pointer<Char>, int) _setenv = DynamicLibrary
    .process()
    .lookup<NativeFunction<Int32 Function(Pointer<Char>, Pointer<Char>, Int32)>>(
      'setenv',
    )
    .asFunction();
