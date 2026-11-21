/// The shell helper that installs a Linux update once the application has
/// exited (update-check design §3 step 4).
///
/// Written beside the downloaded package and run detached, so it outlives
/// the application. It is POSIX `sh`, and its arguments are, in order: the
/// application's process id, the mode (`installer` or `appimage`), the
/// package, the install location (a prefix, or the AppImage's own path),
/// and the executable to start again.
///
/// It waits for the application to exit (at most a minute), installs, starts
/// the application again — the old one if the install failed, which the
/// staged installers and the AppImage's rename both leave in place — and
/// removes its own folder.
const String linuxUpdateHelperScript = r'''#!/bin/sh
# Alexandria's update helper. Written and started by the application; not
# meant to be run by hand.
set -u

pid=$1
mode=$2
package=$3
location=$4
executable=$5
here=$(cd "$(dirname "$0")" && pwd)

# Wait for the application to exit, so nothing it holds open is replaced
# under it.
waited=0
while kill -0 "$pid" 2> /dev/null && [ "$waited" -lt 60 ]; do
  sleep 1
  waited=$((waited + 1))
done

case $mode in
  installer)
    sh "$package" --yes --prefix "$location" > "$here/install.log" 2>&1 \
      || echo "the installer failed" >&2
    target=$executable
    ;;
  appimage)
    # Copied beside the old file first, so the rename that replaces it is on
    # one filesystem and so atomic: the old AppImage is either still there,
    # or replaced whole.
    staged="$location.update.$$"
    if cp "$package" "$staged" && chmod +x "$staged"; then
      mv -f "$staged" "$location" || rm -f "$staged"
    else
      rm -f "$staged"
    fi
    target=$location
    ;;
  *)
    echo "unknown mode: $mode" >&2
    target=$executable
    ;;
esac

# Start the application again, detached from this helper.
nohup "$target" > /dev/null 2>&1 &

rm -rf "$here"
exit 0
''';
