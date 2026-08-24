#!/bin/sh
# Deletes everything previous runs of Alexandria left behind, so the next one
# starts as a first launch. The Linux counterpart of clean.ps1, with the same
# behaviour and the same flags in long form.
#
# State outlives a run in three places: the scratch catalog under .dev, the
# application-support folder holding the preferences, the real catalog and the
# log, and the core's thumbnail cache. Testing what an owner sees the first time
# they open the application means removing all three, and nothing else writes
# down where they are.
#
# Runtime state only. build/, .dart_tool/, native/linux/*.so and the core's
# target/ are left alone: this is a fresh install, not a fresh clone, and a
# clean run should not cost a full rebuild.
#
# Nothing here can reach a library source folder. The paths are fixed and none
# of them is derived from the catalog, so no indexed music, video or image is
# reachable from this script.
#
# tools/dev.sh --clean runs this first and then builds and starts as usual.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

REAL_CATALOG="no"
DRY_RUN="no"

step() { printf '\033[36m==> %s\033[0m\n' "$*"; }
note() { printf '\033[90m    %s\033[0m\n' "$*"; }
fail() { printf '\033[31merror: %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  cat <<USAGE
Usage: tools/clean.sh [options]

  --real-catalog  Also delete the real catalog — the one --real-data runs
                  against. Off by default: without it the application-support
                  folder is emptied around the catalog, preferences and logs
                  included, and the catalog is left where it is.
  --dry-run       List what would be removed and touch nothing.
  --help          Show this message.
USAGE
}

while [ $# -gt 0 ]; do
  case $1 in
    --real-catalog) REAL_CATALOG="yes"; shift ;;
    --dry-run) DRY_RUN="yes"; shift ;;
    --help | -h) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# -------------------------------------------------------------------- the paths

# Linux resolves the application-support directory as the GTK application id
# under the XDG data home. This constant must agree with APPLICATION_ID in
# linux/CMakeLists.txt.
APPLICATION_ID="io.github.artur_rios.Alexandria"

# The folder the application itself creates inside that one; must agree with
# CorePaths.applicationFolderName in lib/core/startup/core_paths.dart.
APPLICATION_FOLDER="Alexandria"

DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

SUPPORT_FOLDER="$DATA_HOME/$APPLICATION_ID"
SCRATCH="$REPO_ROOT/.dev"
THUMBNAILS="$REPO_ROOT/thumbnails"

# Folders left by earlier versions. The first two are the application id and
# the binary name from before commit d86b493 renamed the application; the third
# is the binary name now. All three matter rather than merely being clutter:
# path_provider_linux reads an executable-name folder in preference to the
# application-id one when it exists, so a stale folder is state the application
# would still load.
LEGACY_FOLDERS="$DATA_HOME/com.arturrios.alexandria_desktop
$DATA_HOME/alexandria_desktop
$DATA_HOME/alexandria"

# ---------------------------------------------------------------------- removal

remove_target() {
  path=$1
  what=$2

  if [ ! -e "$path" ]; then
    note "absent: $path"
    return 0
  fi

  if [ "$DRY_RUN" = "yes" ]; then
    note "would remove the $what: $path"
    return 0
  fi

  rm -rf "$path" || fail "could not remove $path

Alexandria is most likely still running, or the file belongs to another user.
Quit it and run this again."

  note "removed the $what: $path"
}

# Empties the application-support folder while leaving the catalog where it is.
#
# The -wal and -shm files stay with it rather than being deleted around it:
# they are part of the database, and removing a write-ahead log from under a
# catalog is how a catalog stops opening.
clear_around_catalog() {
  inner="$SUPPORT_FOLDER/$APPLICATION_FOLDER"

  for child in "$SUPPORT_FOLDER"/* "$SUPPORT_FOLDER"/.[!.]*; do
    [ -e "$child" ] || continue
    if [ "$child" = "$inner" ]; then continue; fi
    remove_target "$child" "application state"
  done

  for child in "$inner"/* "$inner"/.[!.]*; do
    [ -e "$child" ] || continue
    case ${child##*/} in
      catalog.db | catalog.db-wal | catalog.db-shm) continue ;;
    esac
    remove_target "$child" "application state"
  done

  note "preserved the real catalog: $inner/catalog.db"
  note "pass --real-catalog to delete it as well"
}

# -------------------------------------------------------------------- the sweep

if [ "$DRY_RUN" = "yes" ]; then
  step "Listing what a clean would remove; nothing will be touched"
else
  step "Removing what previous runs left behind"
fi

remove_target "$SCRATCH" "scratch catalog"

if [ "$REAL_CATALOG" = "no" ] && [ -e "$SUPPORT_FOLDER/$APPLICATION_FOLDER/catalog.db" ]; then
  clear_around_catalog
else
  remove_target "$SUPPORT_FOLDER" "application-support folder"
fi

remove_target "$THUMBNAILS" "thumbnail cache"

# Read through a here-document rather than a pipe: a pipe would run the loop in
# a subshell, where a failure to remove something exits that subshell and the
# sweep carries on as though it had succeeded.
while IFS= read -r folder; do
  [ -n "$folder" ] || continue
  remove_target "$folder" "folder left by an earlier version"
done <<LEGACY
$LEGACY_FOLDERS
LEGACY

if [ "$DRY_RUN" = "yes" ]; then
  step "Nothing was removed (--dry-run)"
else
  step "Clean"
  note "the next run starts as a first launch"
fi
