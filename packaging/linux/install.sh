#!/bin/sh
# IR-16: the Linux install program.
#
# This file is the head of a self-extracting installer. The release workflow
# appends a gzipped tarball of build/linux/x64/release/bundle below the
# __ALEXANDRIA_PAYLOAD__ marker at the end, producing a single
# alexandria-installer-<version>-linux-x64.sh. Run on its own, unappended, it
# reports that it carries no payload rather than half-installing something.
#
# The counterpart to the Windows installer in ../windows/installer.iss, and it
# follows the same replacement policy: remove exactly what a previous install
# wrote, never the directory it was written into. Somebody who points this at a
# folder holding unrelated files must not lose them.
#
# What makes that possible is the manifest — the Linux stand-in for the Windows
# uninstall registry key. Every install records its prefix and every path it
# created; every later install reads that back. Without it the only options
# would be deleting the whole prefix or leaving stale files behind, and a stale
# lib/libalexandria_ffi.so is exactly the kind of leftover that surfaces later
# as an unrelated-looking "core could not be loaded".
#
# Nothing here installs, updates, or launches a service. The core travels
# inside the bundle as a shared library (Operations & Infrastructure Document
# §7.3), and the owner's catalog and settings live in their own data directory,
# which is deliberately never touched — not on replace, not on uninstall.

set -eu

APP_NAME="Alexandria"
APP_ID="io.github.artur_rios.Alexandria"
EXE_NAME="alexandria_desktop"
LAUNCHER_NAME="alexandria"
DESKTOP_FILE="${APP_ID}.desktop"
VERSION="@VERSION@"
PAYLOAD_MARKER="__ALEXANDRIA_PAYLOAD__"

ASSUME_YES="no"
MODE="install"
PREFIX=""

# ---------------------------------------------------------------- reporting

log() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<USAGE
${APP_NAME} ${VERSION} installer

Usage:
  $0 [--prefix DIR] [--yes]
  $0 --uninstall [--yes]
  $0 --help

Options:
  --prefix DIR  Install into DIR instead of asking. Created if missing.
  --yes         Answer yes to every prompt. Required when there is no
                terminal to ask at, such as in a script or a container.
  --uninstall   Remove the installation this installer last recorded, and
                nothing else. Your library, catalog, and settings are left
                in place.
  --help        Show this message.

Default install directory:
  /opt/${LAUNCHER_NAME}                  when run as root
  \$HOME/.local/share/${LAUNCHER_NAME}    otherwise

An existing installation in the chosen directory is replaced. An installation
recorded somewhere else is offered for removal, so that changing the directory
does not leave two copies behind.
USAGE
}

# ------------------------------------------------------------------ prompts

# Asks through /dev/tty rather than stdin: stdin may be a pipe or closed, and a
# prompt that silently read EOF would answer itself.
confirm() {
  _prompt=$1

  if [ "$ASSUME_YES" = "yes" ]; then
    log "${_prompt} yes (--yes)"
    return 0
  fi

  if [ ! -r /dev/tty ]; then
    die "no terminal to ask at. Re-run with --yes to accept: ${_prompt}"
  fi

  while :; do
    printf '%s [y/N] ' "$_prompt" > /dev/tty
    IFS= read -r _answer < /dev/tty || _answer=""
    case $_answer in
      y | Y | yes | YES) return 0 ;;
      "" | n | N | no | NO) return 1 ;;
      *) printf 'Please answer y or n.\n' > /dev/tty ;;
    esac
  done
}

ask_prefix() {
  _default=$1

  if [ "$ASSUME_YES" = "yes" ] || [ ! -r /dev/tty ]; then
    printf '%s' "$_default"
    return 0
  fi

  printf 'Install %s %s into [%s]: ' "$APP_NAME" "$VERSION" "$_default" > /dev/tty
  IFS= read -r _answer < /dev/tty || _answer=""
  [ -n "$_answer" ] || _answer=$_default
  printf '%s' "$_answer"
}

# ----------------------------------------------------------------- location

is_root() { [ "$(id -u)" -eq 0 ]; }

default_prefix() {
  if is_root; then
    printf '/opt/%s' "$LAUNCHER_NAME"
  else
    printf '%s/.local/share/%s' "$HOME" "$LAUNCHER_NAME"
  fi
}

launcher_dir() {
  if is_root; then
    printf '/usr/local/bin'
  else
    printf '%s/.local/bin' "$HOME"
  fi
}

applications_dir() {
  if is_root; then
    printf '/usr/share/applications'
  else
    printf '%s/applications' "${XDG_DATA_HOME:-$HOME/.local/share}"
  fi
}

manifest_path() {
  if is_root; then
    printf '/var/lib/%s/install.manifest' "$LAUNCHER_NAME"
  else
    printf '%s/%s/install.manifest' "${XDG_STATE_HOME:-$HOME/.local/state}" "$LAUNCHER_NAME"
  fi
}

# Turns a possibly relative, possibly ~-prefixed path into an absolute one
# without requiring it to exist yet.
absolute_path() {
  _path=$1
  case $_path in
    "~") _path=$HOME ;;
    "~/"*) _path="$HOME/${_path#\~/}" ;;
  esac
  case $_path in
    /*) ;;
    *) _path="$(pwd)/$_path" ;;
  esac
  # Collapse trailing slashes, so manifest comparisons match.
  while :; do
    case $_path in
      /) break ;;
      */) _path=${_path%/} ;;
      *) break ;;
    esac
  done
  printf '%s' "$_path"
}

# ---------------------------------------------------------------- manifests

# manifest_value KEY FILE
manifest_value() {
  [ -f "$2" ] || return 1
  _line=$(grep -m1 "^$1=" "$2" 2>/dev/null) || return 1
  printf '%s' "${_line#*=}"
}

# An installation is "there" if the thing that matters is there: the
# executable. A prefix holding only leftovers is still worth cleaning, so the
# bundle's own directories count too.
looks_installed() {
  _prefix=$1
  [ -n "$_prefix" ] || return 1
  [ -e "$_prefix/$EXE_NAME" ] && return 0
  [ -d "$_prefix/lib" ] && [ -d "$_prefix/data" ] && return 0
  return 1
}

# Removes exactly the paths a previous install recorded, then the directories
# it left empty. Anything the owner put in the prefix themselves has no file=
# line and is not touched.
remove_recorded_install() {
  _manifest=$1
  _recorded=$(manifest_value prefix "$_manifest" || true)

  while IFS= read -r _line; do
    case $_line in
      file=*) rm -f "${_line#file=}" || true ;;
    esac
  done < "$_manifest"

  if [ -n "$_recorded" ] && [ -d "$_recorded" ]; then
    # -depth so children are considered before their parents; rmdir refuses a
    # directory that still holds anything, which is exactly the check wanted.
    find "$_recorded" -depth -type d -exec rmdir {} + 2> /dev/null || true
  fi

  rm -f "$_manifest" || true
}

# The fallback for a prefix this installer never recorded — an install from the
# portable tarball, say, or one whose manifest was lost. Only the paths this
# payload itself writes are removed.
remove_unrecorded_install() {
  _prefix=$1
  rm -f "$_prefix/$EXE_NAME" || true
  rm -f "$_prefix/$DESKTOP_FILE" || true
  rm -rf "$_prefix/lib" || true
  rm -rf "$_prefix/data" || true
}

# ------------------------------------------------------------------ payload

payload_start_line() {
  # -a so grep does not decide the appended tarball makes this a binary file
  # and print nothing but "binary file matches".
  _line=$(grep -a -n -m1 "^${PAYLOAD_MARKER}\$" "$0" | cut -d: -f1) || return 1
  [ -n "$_line" ] || return 1
  _start=$((_line + 1))
  # The marker is the last line of the unappended head, so finding it proves
  # nothing. Bytes after it are what prove a payload was appended — without
  # this check, running the head on its own reaches tar and fails there
  # instead, halfway through creating the install directory.
  [ -n "$(tail -n "+$_start" "$0" | head -c 1)" ] || return 1
  printf '%s' "$_start"
}

# Extracts into the prefix and writes the list of what it extracted to
# LISTING. That list, not a walk of the prefix afterwards, is what the manifest
# is built from: a walk would adopt whatever the owner happens to keep in the
# directory, and --uninstall would then delete files this installer never
# wrote. tar's own -v names exactly the members it created.
extract_payload() {
  _prefix=$1
  _start=$2
  _listing=$3
  mkdir -p "$_prefix"
  tail -n "+$_start" "$0" | tar xzvf - -C "$_prefix" > "$_listing"
}

# --------------------------------------------------------------------- args

while [ $# -gt 0 ]; do
  case $1 in
    --prefix)
      [ $# -ge 2 ] || die "--prefix needs a directory"
      PREFIX=$2
      shift 2
      ;;
    --prefix=*)
      PREFIX=${1#--prefix=}
      shift
      ;;
    --yes | -y)
      ASSUME_YES="yes"
      shift
      ;;
    --uninstall)
      MODE="uninstall"
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

MANIFEST=$(manifest_path)

# ---------------------------------------------------------------- uninstall

if [ "$MODE" = "uninstall" ]; then
  [ -f "$MANIFEST" ] || die "no ${APP_NAME} installation is recorded at ${MANIFEST}"

  recorded_prefix=$(manifest_value prefix "$MANIFEST" || true)
  recorded_version=$(manifest_value version "$MANIFEST" || printf 'unknown')

  if confirm "Remove ${APP_NAME} ${recorded_version} from ${recorded_prefix}?"; then
    remove_recorded_install "$MANIFEST"
    log "Removed ${APP_NAME} from ${recorded_prefix}."
    log "Your library, catalog, and settings were left in place."
  else
    log "Nothing was removed."
  fi
  exit 0
fi

# ------------------------------------------------------------------ install

payload_start=$(payload_start_line) || die \
  "this script carries no payload. It is the installer's head, not the installer — download alexandria-installer-<version>-linux-x64.sh from the release."

command -v tar > /dev/null 2>&1 || die "tar is needed to unpack the payload and was not found"

recorded_prefix=""
if [ -f "$MANIFEST" ]; then
  recorded_prefix=$(manifest_value prefix "$MANIFEST" || true)
fi

if [ -n "$PREFIX" ]; then
  prefix=$(absolute_path "$PREFIX")
else
  suggested=$(default_prefix)
  # Offer where it already lives, so the ordinary upgrade is one Enter.
  if looks_installed "$recorded_prefix"; then
    suggested=$recorded_prefix
  fi
  prefix=$(absolute_path "$(ask_prefix "$suggested")")
fi

case $prefix in
  / | /usr | /usr/bin | /usr/lib | /bin | /lib | /etc | /home | "$HOME")
    die "refusing to install into ${prefix} — choose a directory of its own"
    ;;
esac

# 1. An installation in the directory the owner actually chose.
if looks_installed "$prefix"; then
  if [ "$recorded_prefix" = "$prefix" ]; then
    existing_version=$(manifest_value version "$MANIFEST" || printf 'unknown')
    confirm "${APP_NAME} ${existing_version} is installed in ${prefix}. Replace it with ${VERSION}?" \
      || die "nothing was changed"
    remove_recorded_install "$MANIFEST"
  else
    confirm "${prefix} already contains ${APP_NAME}, put there by something other than this installer. Replace it?" \
      || die "nothing was changed"
    remove_unrecorded_install "$prefix"
  fi
  log "Removed the previous installation from ${prefix}."

# 2. An installation somewhere else entirely. Offered separately, because
#    leaving it would mean two copies on the machine and a launcher pointing at
#    whichever won.
elif [ "$recorded_prefix" != "$prefix" ] && looks_installed "$recorded_prefix"; then
  if confirm "${APP_NAME} is already installed in ${recorded_prefix}. Remove that one?"; then
    remove_recorded_install "$MANIFEST"
    log "Removed the previous installation from ${recorded_prefix}."
  else
    warn "leaving the installation in ${recorded_prefix} in place — there will be two"
  fi
fi

log "Installing ${APP_NAME} ${VERSION} into ${prefix} ..."
listing=$(mktemp)
trap 'rm -f "$listing"' EXIT INT TERM
extract_payload "$prefix" "$payload_start" "$listing"
chmod 755 "$prefix/$EXE_NAME"

bindir=$(launcher_dir)
appdir=$(applications_dir)
mkdir -p "$bindir" "$appdir"

launcher="$bindir/$LAUNCHER_NAME"
ln -sf "$prefix/$EXE_NAME" "$launcher"

# The entry travels in the bundle with a bare Exec, which only resolves for a
# launcher already on PATH. Rewriting it to the absolute path makes the menu
# entry work whether or not the symlink above is reachable.
desktop_entry="$appdir/$DESKTOP_FILE"
if [ -f "$prefix/$DESKTOP_FILE" ]; then
  sed "s|^Exec=.*|Exec=${prefix}/${EXE_NAME}|" "$prefix/$DESKTOP_FILE" > "$desktop_entry"
else
  warn "the payload carries no ${DESKTOP_FILE}; writing a minimal one"
  cat > "$desktop_entry" <<DESKTOP
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Comment=Your personal library
Exec=${prefix}/${EXE_NAME}
Icon=${APP_ID}
Terminal=false
Categories=AudioVideo;Player;Office;Viewer;
DESKTOP
fi
chmod 644 "$desktop_entry"

# Written last, and only now: a manifest recorded before the install finished
# would claim files that a failure meant were never written.
mkdir -p "$(dirname "$MANIFEST")"
{
  printf 'version=%s\n' "$VERSION"
  printf 'prefix=%s\n' "$prefix"
  # tar names directories with a trailing slash; those are skipped, because
  # remove_recorded_install rmdirs empty directories anyway and a directory
  # listed as a file would only fail to be removed.
  while IFS= read -r _member; do
    _member=${_member#./}
    [ -n "$_member" ] || continue
    case $_member in */) continue ;; esac
    printf 'file=%s/%s\n' "$prefix" "$_member"
  done < "$listing"
  printf 'file=%s\n' "$launcher"
  printf 'file=%s\n' "$desktop_entry"
} > "$MANIFEST"

if command -v update-desktop-database > /dev/null 2>&1; then
  update-desktop-database "$appdir" > /dev/null 2>&1 || true
fi

log ""
log "${APP_NAME} ${VERSION} is installed."
log "  Program:     ${prefix}/${EXE_NAME}"
log "  Launcher:    ${launcher}"
log "  Menu entry:  ${desktop_entry}"
log "  Record:      ${MANIFEST}"
log ""

case ":${PATH}:" in
  *":${bindir}:"*) log "Run it with: ${LAUNCHER_NAME}" ;;
  *)
    log "${bindir} is not on your PATH, so the ${LAUNCHER_NAME} command will not be"
    log "found. Either add it, or run ${prefix}/${EXE_NAME} directly."
    ;;
esac

log "Remove it later with: $0 --uninstall"

# The core links ffmpeg and the Linux bundle does not carry it — the same gap
# the .deb, the AppImage, and the release workflow's header all record. Said
# here, rather than left for a failed first launch to say.
if command -v ldd > /dev/null 2>&1 && [ -f "$prefix/lib/libalexandria_ffi.so" ]; then
  if ldd "$prefix/lib/libalexandria_ffi.so" 2> /dev/null | grep -q "not found"; then
    log ""
    warn "the core has unresolved libraries on this machine:"
    ldd "$prefix/lib/libalexandria_ffi.so" 2> /dev/null | grep "not found" >&2 || true
    warn "install your distribution's ffmpeg runtime libraries before running it"
  fi
fi

# Nothing below this line is shell. The exit keeps the appended tarball from
# ever reaching the interpreter.
exit 0

__ALEXANDRIA_PAYLOAD__
