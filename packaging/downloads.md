Every package below carries the Alexandria core, and every one that
cannot ask a package manager for ffmpeg carries that too. There is
nothing else to install.

## Windows

- **`alexandria-setup-@VERSION@.exe`** —
  the installer. Asks where to install, and replaces an existing
  installation found there or in the place a previous install
  recorded. Only the program's own files are removed; your library,
  catalog, and settings are left alone.
- **`alexandria-@VERSION@-windows-x64.zip`**
  — the application itself. Unpack it and run
  `alexandria.exe`; nothing is registered, and deleting the
  folder removes it.
- **`alexandria.msix`** — published unsigned. Windows will not
  install an unsigned MSIX without a trusted certificate, so use
  the installer unless you have your own signing set up.

## Linux

- **`alexandria-installer-@VERSION@-linux-x64.sh`**
  — the installer. `chmod +x` it and run it. Defaults to
  `~/.local/opt/alexandria`, or `/opt/alexandria` as root, and
  replaces an existing installation the same way the Windows one
  does. `--prefix DIR` and `--yes` skip the questions;
  `--uninstall` removes what it installed and nothing else.
- **`alexandria-@VERSION@-linux-x64.tar.gz`**
  — the application itself. Unpack it and run
  `./alexandria`.
- **`.deb`** — for Ubuntu 24.04, which is the release it is built
  on. Pulls ffmpeg, libmpv, and GTK in through apt.
- **`.AppImage`** — carries everything it needs.
- **`.flatpak`** — its codecs come from the
  `org.freedesktop.Platform.ffmpeg-full` runtime extension.

The installer, the tarball, and the AppImage carry everything the
program needs — ffmpeg, libmpv, and the libraries those depend on.
Only the graphics, sound, and C libraries any desktop application
already has come from your system.

Packages are unsigned — code signing needs a certificate the
project does not hold yet.

## Licence

Alexandria's source code is free and open source under the
[Artur Rios Attribution License](https://github.com/artur-rios/alexandria-ui/blob/main/LICENSE).
The source is [alexandria-ui](https://github.com/artur-rios/alexandria-ui)
and [alexandria-api](https://github.com/artur-rios/alexandria-api);
this release was built from the tag of the same name.

The Linux packages carry third-party copyleft libraries, each under
its own licence: libmpv plays the video, and ffmpeg links the x264,
x265, xvid and postproc encoders whether or not anything ever
encodes with them. A Linux package that bundles them is distributed
as a combined work subject to those libraries' terms (GPL-3.0). The
Windows packages carry an LGPL build of ffmpeg and no mpv.

Every bundled library's licence travels inside the package in
`lib/licenses`, the full list of packages is in
`lib/licenses/PACKAGES.txt`, and the ones known to be copyleft are
named in `lib/licenses/COPYLEFT.tsv`.

For the Linux packages, the GPL entitles you to the complete
corresponding source. For Alexandria that is the two repositories above.
For the bundled libraries, they are unmodified Ubuntu 24.04
packages, and their sources are the matching `apt-get source`
packages for the versions named in `PACKAGES.txt`; ask through the
repository if you would rather have them directly.
