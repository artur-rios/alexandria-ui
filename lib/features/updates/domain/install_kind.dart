/// How this copy of the application was installed, which decides what
/// updating it can mean (update-check design §1).
enum InstallKind {
  /// The Windows setup: the application can run the new setup over itself.
  windowsInstaller,

  /// The Linux `.sh` installer, into a prefix this user can write.
  linuxInstaller,

  /// An AppImage in a folder this user can write: the file is replaced.
  appImage,

  /// A Flatpak, which has no network permission and never checks.
  flatpak,

  /// Everything else — a `.deb`, the zip or tarball, the MSIX, an install
  /// this user cannot write to. The owner updates it; the application says
  /// how and opens the release page.
  manual;

  /// Whether the application can install an update for this kind itself.
  bool get updatesItself =>
      this == windowsInstaller || this == linuxInstaller || this == appImage;
}
