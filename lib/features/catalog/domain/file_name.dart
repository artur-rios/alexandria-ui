/// The filesystem a name has to be legal on (UC-17 main flow step 2).
///
/// The rule is the *host's*, not a common denominator of both: a name Windows
/// forbids is fine on Linux, and refusing it there would be this application
/// inventing a restriction the owner's computer does not have.
enum HostFileSystem {
  /// NTFS and the Win32 naming rules.
  windows,

  /// Linux, where a name may hold anything but a separator and a NUL.
  posix,
}

/// Why a name cannot be sent to the core (UC-17 AF-01, FR-ME-04).
enum FileNameError {
  /// Nothing was entered, or only whitespace.
  empty,

  /// It holds a character the host forbids in a file name.
  forbiddenCharacter,

  /// Windows reserves a handful of names for devices, whatever the extension.
  reservedName,

  /// It ends in a dot, which Windows silently strips.
  trailingDot,

  /// Longer than a single path component may be.
  tooLong,
}

/// The characters Windows forbids in a file name.
///
/// The separators are here as well as the reserved punctuation: a rename is
/// one path component, so a name carrying a separator is asking to move the
/// file, which is not what UC-17 does.
const String _windowsForbidden = r'<>:"/\|?*';

/// The names Windows reserves for devices, whatever extension follows them.
const Set<String> _windowsReserved = {
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
};

/// The longest single path component either host accepts.
///
/// 255 on both, for different reasons — bytes on ext4, UTF-16 units on NTFS —
/// and the smaller reading is the safe one to hold everybody to.
const int maxFileNameLength = 255;

/// The name that would actually be sent for [name].
///
/// Trimmed, because the surrounding whitespace is a typing artifact and not
/// part of what the owner meant — and on Windows a trailing space would be
/// stripped by the filesystem anyway, leaving the catalog and the disk
/// disagreeing.
String fileNameToSend(String name) => name.trim();

/// What is wrong with [name] on [host], or `null` when it can be sent
/// (AF-01).
///
/// Checked here rather than left to the core because FR-ME-04 asks for it
/// before the call: the core would refuse it too, and a round trip to be told
/// that a name contains a colon is a worse answer than an immediate one.
FileNameError? validateFileName(String name, {required HostFileSystem host}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return FileNameError.empty;

  if (trimmed.length > maxFileNameLength) return FileNameError.tooLong;

  // Control characters are forbidden everywhere: a name with a newline in it
  // is unusable on either host whatever the filesystem technically stores.
  if (trimmed.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
    return FileNameError.forbiddenCharacter;
  }

  switch (host) {
    case HostFileSystem.posix:
      // A separator would make this a move rather than a rename.
      if (trimmed.contains('/')) return FileNameError.forbiddenCharacter;

    case HostFileSystem.windows:
      if (trimmed.split('').any(_windowsForbidden.contains)) {
        return FileNameError.forbiddenCharacter;
      }

      // Windows strips a trailing dot without saying so, which would leave
      // the catalog holding a name the disk does not have. Surrounding
      // whitespace needs no rule: the name sent is the trimmed one.
      if (trimmed.endsWith('.')) return FileNameError.trailingDot;

      // The reservation is on the stem, so `NUL.txt` is refused as well.
      final stem = trimmed.split('.').first.toUpperCase();
      if (_windowsReserved.contains(stem)) return FileNameError.reservedName;
  }

  return null;
}
