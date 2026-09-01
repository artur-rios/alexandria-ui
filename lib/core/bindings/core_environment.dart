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
    shouldSetCoreVariable(environment, coreAuthModeVariable);

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

final int Function(Pointer<Char>, Pointer<Char>, int) _setenv =
    DynamicLibrary.process()
        .lookup<
          NativeFunction<Int32 Function(Pointer<Char>, Pointer<Char>, Int32)>
        >('setenv')
        .asFunction();

/// The core's music-enrichment switch, read at `alexandria_index_init`.
const String coreMetadataEnabledVariable = 'ALEXANDRIA_METADATA_ENABLED';

/// The core's MusicBrainz contact, read at `alexandria_index_init`.
const String coreMetadataContactVariable = 'ALEXANDRIA_METADATA_CONTACT';

/// The contact this application identifies itself to MusicBrainz with when
/// the owner has named none of their own.
///
/// Not politeness and not decoration: MusicBrainz's terms require a
/// `User-Agent` naming the application *and* carrying a way to reach whoever
/// is responsible for the traffic, and they are entitled to block clients
/// that supply neither — the core refuses to start a lookup while it is
/// empty rather than send an anonymous agent string and have this software
/// blocked for everyone using it. This is the address of whoever publishes
/// this application, which is who MusicBrainz would be writing to about a
/// stock installation; an owner who would rather answer for their own
/// traffic replaces it in the preferences dialog.
const String defaultMusicLookupContact = 'arturdev@duck.com';

/// What the core is configured to do about music enrichment: whether it may
/// run at all, and who to name as the contact when it does (music enrichment
/// design).
///
/// A value rather than two loose parameters because the two travel together
/// everywhere — into the isolate, into the settings store, and into the
/// comparison that decides whether an already-initialized core has to be
/// re-initialized to pick a change up.
class MusicLookup {
  /// Creates a configuration.
  const MusicLookup({required this.enabled, required this.contact});

  /// Enrichment switched off, which is what the core itself defaults to.
  static const MusicLookup off = MusicLookup(enabled: false, contact: '');

  /// Whether the core may reach the lookup services at all.
  final bool enabled;

  /// How MusicBrainz can reach whoever runs this installation.
  final String contact;

  /// Whether a lookup would actually be accepted — the core's own rule
  /// (`MetadataSettings::unavailable_reason`), which refuses a switched-on
  /// feature with no contact just as firmly as a switched-off one. Read
  /// here so the interface can offer the lookup exactly when the core would
  /// honour it, rather than offering it and watching every call fail.
  bool get isAvailable => enabled && contact.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is MusicLookup &&
      other.enabled == enabled &&
      other.contact == contact;

  @override
  int get hashCode => Object.hash(enabled, contact);

  @override
  String toString() => 'MusicLookup(enabled: $enabled, contact: $contact)';
}

/// Where the core keeps the artist photographs it fetches.
const String coreImageCacheDirVariable = 'ALEXANDRIA_METADATA_IMAGE_CACHE_DIR';

/// Where the core keeps the thumbnails it renders.
const String coreThumbnailCacheDirVariable =
    'ALEXANDRIA_PLAYBACK_THUMBNAIL_CACHE_DIR';

/// Puts the core's caches inside [applicationDirectory], before it is
/// initialized.
///
/// Both settings default to a **relative** path — `artist-images` and
/// `thumbnails` — which the core resolves against the process's working
/// directory. For a program launched from its own source tree that is
/// harmless and invisible; for an installed application it is wherever the
/// desktop happened to start it, which is a directory this application does
/// not own and often cannot write to. An artist photograph then either fails
/// to be written at all, or is written somewhere nothing will look for it
/// again — and the core answers the path it stored, so the player is handed
/// `artist-images/….jpg` and finds nothing there. That is the whole of "the
/// picture never appears".
///
/// The catalog's own directory is the answer, because it is the one
/// directory this application already owns and already creates (IR-05). The
/// caches sit beside `catalog.db`: they belong to that catalog, they are
/// discarded with it, and an owner who moved their database took its caches
/// along without having to be told they existed.
///
/// A variable already set in the environment is left alone, as everywhere
/// else here.
void ensureCacheDirectories(
  String applicationDirectory, {
  Map<String, String>? environment,
}) {
  final current = environment ?? Platform.environment;

  cacheDirectoriesIn(applicationDirectory).forEach((variable, path) {
    if (!shouldSetCoreVariable(current, variable)) return;

    setProcessEnvironment(variable, path);
  });
}

/// Where each cache goes, given the directory the catalog lives in.
///
/// Separated from the setting so the decision can be read back: writing an
/// environment variable is a platform call that `Platform.environment` — a
/// snapshot taken before it — cannot show, so what is testable here is the
/// path this application chooses, which is where the mistake would be.
///
/// The core's own default names are kept: this moves where the caches are,
/// not what they are called, and an owner who goes looking finds the
/// directories the core's documentation describes.
Map<String, String> cacheDirectoriesIn(String applicationDirectory) {
  final root = _withoutTrailingSeparator(applicationDirectory);

  return {
    coreImageCacheDirVariable: '$root${Platform.pathSeparator}artist-images',
    coreThumbnailCacheDirVariable: '$root${Platform.pathSeparator}thumbnails',
  };
}

/// [directory] without a trailing separator, so joining a name to it cannot
/// produce a doubled one.
String _withoutTrailingSeparator(String directory) =>
    directory.endsWith(Platform.pathSeparator) && directory.length > 1
    ? directory.substring(0, directory.length - 1)
    : directory;

/// Whether the application has to set [name] itself.
///
/// The same rule [shouldSetAuthMode] applies, per variable: an explicit
/// setting always wins, and a variable set to blank counts as unset because
/// that is how the core would read it.
bool shouldSetCoreVariable(Map<String, String> environment, String name) =>
    (environment[name] ?? '').trim().isEmpty;

/// Puts the core's music enrichment into the state [lookup] describes,
/// before it is initialized.
///
/// Configuration through the core's own documented surface, exactly as
/// [ensureLocalAuthMode] is (BR-02): these are the variables the core reads
/// at `alexandria_index_init`, set before it reads them rather than instead
/// of it reading them. The difference from the auth mode is whose choice it
/// is — local auth is the only mode this application can work in, while
/// enrichment is the one feature that reaches the network, so what lands
/// here is the owner's stored preference and nothing else.
///
/// A variable already set in the environment is left alone, so a developer
/// or a packager who configured the core deliberately keeps what they
/// configured.
///
/// Must run before `alexandria_index_init`; afterwards the settings are
/// fixed until the core is initialized again.
void ensureMusicLookup(
  MusicLookup lookup, {
  Map<String, String>? environment,
}) {
  final current = environment ?? Platform.environment;

  if (shouldSetCoreVariable(current, coreMetadataEnabledVariable)) {
    // The core parses `true`/`1`/`yes`/`on` and their opposites; `true` and
    // `false` are the spellings its own config file uses.
    setProcessEnvironment(
      coreMetadataEnabledVariable,
      lookup.enabled ? 'true' : 'false',
    );
  }

  // An empty contact is not written: the core reads a blank one as "no
  // contact" and refuses to run, which is the same outcome as leaving the
  // variable unset, and writing it would overwrite a contact a config file
  // supplied.
  final contact = lookup.contact.trim();
  if (contact.isNotEmpty &&
      shouldSetCoreVariable(current, coreMetadataContactVariable)) {
    setProcessEnvironment(coreMetadataContactVariable, contact);
  }
}
