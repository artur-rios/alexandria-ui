#!/bin/sh
# Builds the Alexandria core, wires it into this checkout, and runs the
# application against it. The Linux counterpart of dev.ps1, with the same steps
# and the same flags in long form.
#
# The whole product is two repositories: this front end and the core it links in
# process over FFI. Running the real thing locally means building the core,
# putting its shared library where IR-04's resolver looks, keeping the generated
# FFI bindings in step with the core's header, and only then starting the app.
#
# Nothing here is needed to package or ship — that is the release workflow's
# job. This is the loop for changing code and seeing the change.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$REPO_ROOT"

CORE=""
SKIP_CORE="no"
PROFILE="release"
REAL_DATA="no"
CLEAN="no"
GENERATE="no"
NO_RUN="no"

step() { printf '\033[36m==> %s\033[0m\n' "$*"; }
note() { printf '\033[90m    %s\033[0m\n' "$*"; }
fail() { printf '\033[31merror: %s\033[0m\n' "$*" >&2; exit 1; }

usage() {
  cat <<USAGE
Usage: tools/dev.sh [options]

  --core DIR    The core checkout to build. Defaults to \$ALEXANDRIA_CORE_REPO,
                then to a sibling directory named alexandria-api.
  --skip-core   Do not rebuild the core. For Dart-only changes: the library
                already in native/linux is reused.
  --debug       Build the core unoptimised. Much faster to compile and
                appreciably slower to run; indexing a large folder will drag.
  --real-data   Run against the real catalog. Off by default so that
                re-indexing, deleting and purging while testing cannot touch a
                catalog you care about.
  --clean       Delete everything previous runs left behind before building, so
                the application starts as a first launch. Runs tools/clean.sh,
                which is also useful on its own. The real catalog is never
                deleted this way, with or without --real-data; run
                tools/clean.sh --real-catalog to ask for that by name.
  --generate    Run build_runner and gen-l10n first. Needed after changing
                anything they generate from.
  --no-run      Do everything except start the application.
  --help        Show this message.
USAGE
}

while [ $# -gt 0 ]; do
  case $1 in
    --core) [ $# -ge 2 ] || fail "--core needs a directory"; CORE=$2; shift 2 ;;
    --core=*) CORE=${1#--core=}; shift ;;
    --skip-core) SKIP_CORE="yes"; shift ;;
    --debug) PROFILE="debug"; shift ;;
    --real-data) REAL_DATA="yes"; shift ;;
    --clean) CLEAN="yes"; shift ;;
    --generate) GENERATE="yes"; shift ;;
    --no-run) NO_RUN="yes"; shift ;;
    --help | -h) usage; exit 0 ;;
    *) printf 'error: unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# ----------------------------------------------------------------------- clean

# Before the preflight, so that asking for a clean environment gets one even on
# a machine where the toolchain is not set up yet.
if [ "$CLEAN" = "yes" ]; then
  # Through sh rather than directly: the shell scripts in this repository are
  # not stored with the executable bit, because the checkout they are written in
  # cannot keep one.
  sh "$REPO_ROOT/tools/clean.sh"

  if [ "$REAL_DATA" = "yes" ]; then
    note "the real catalog was left alone; clean.sh --real-catalog deletes it"
  fi
fi

# ------------------------------------------------------------------- preflight

# Checked here rather than left to a compiler error four minutes in. The Linux
# build gets ffmpeg from pkg-config, so what is missing is a -dev package, and
# the error bindgen gives for that names a header rather than a package.
step "Checking the toolchain"

for tool in cargo flutter; do
  command -v "$tool" > /dev/null 2>&1 \
    || fail "$tool is not on PATH. See the Building from source section of README.md."
done

if [ "$SKIP_CORE" = "no" ] && command -v pkg-config > /dev/null 2>&1; then
  if ! pkg-config --exists libavcodec; then
    fail "ffmpeg's development packages are missing. On Ubuntu:
  sudo apt-get install libavformat-dev libavcodec-dev libavutil-dev \\
    libavfilter-dev libavdevice-dev libswscale-dev libswresample-dev \\
    pkg-config clang"
  fi
fi

# media_kit_video links libmpv at build time, and the failure without it comes
# from CMake's generate step rather than from anything mentioning mpv.
if command -v pkg-config > /dev/null 2>&1 && ! pkg-config --exists mpv; then
  note "libmpv-dev is missing; the Flutter build will fail at the generate step"
  note "  sudo apt-get install libmpv-dev mpv"
fi

# ----------------------------------------------------------------- the core repo

if [ "$SKIP_CORE" = "no" ]; then
  [ -n "$CORE" ] || CORE=${ALEXANDRIA_CORE_REPO:-}
  [ -n "$CORE" ] || CORE="$(dirname "$REPO_ROOT")/alexandria-api"

  [ -f "$CORE/Cargo.toml" ] || fail "No core checkout at: $CORE

Pass --core <path>, set ALEXANDRIA_CORE_REPO, or clone it beside this one:
  git clone https://github.com/artur-rios/alexandria-api.git"

  CORE=$(cd "$CORE" && pwd)
  note "core: $CORE"
fi

# ---------------------------------------------------------------- build the core

if [ "$SKIP_CORE" = "yes" ]; then
  step "Skipping the core build"
else
  step "Building the core ($PROFILE)"
  if [ "$PROFILE" = "release" ]; then
    (cd "$CORE" && cargo build -p alexandria-ffi --release)
  else
    (cd "$CORE" && cargo build -p alexandria-ffi)
  fi

  BUILT="$CORE/target/$PROFILE/libalexandria_ffi.so"
  [ -f "$BUILT" ] || fail "cargo reported success but produced no library at $BUILT"

  # Where IR-04's resolver looks when running from a checkout.
  mkdir -p "$REPO_ROOT/native/linux"
  cp "$BUILT" "$REPO_ROOT/native/linux/libalexandria_ffi.so"
  note "placed $(du -h "$REPO_ROOT/native/linux/libalexandria_ffi.so" | cut -f1) at native/linux/libalexandria_ffi.so"

  # ------------------------------------------------------------------ bindings

  # The header is generated by the core's own build, so it only exists once the
  # core has been built — which is why this follows rather than precedes it.
  #
  # Compared with line endings normalised. A checkout made on Windows stores the
  # vendored copy with CRLF while cbindgen writes LF, and without this the
  # comparison reports drift on every run and quickly teaches everyone to
  # ignore it.
  GENERATED="$CORE/crates/alexandria-ffi/src/header.h"
  VENDORED="$REPO_ROOT/native/include/alexandria_ffi.h"

  if [ ! -f "$GENERATED" ]; then
    note "the core produced no header; leaving the bindings alone"
  else
    WORK=$(mktemp -d)
    tr -d '\r' < "$VENDORED" > "$WORK/vendored.h"
    tr -d '\r' < "$GENERATED" > "$WORK/generated.h"

    if cmp -s "$WORK/vendored.h" "$WORK/generated.h"; then
      step "Bindings are current"
    else
      step "The core's header changed; regenerating the bindings"
      cp "$GENERATED" "$VENDORED"
      dart run ffigen --config ffigen.yaml
      note "native/include/alexandria_ffi.h and lib/core/bindings updated - review and commit them"
    fi

    rm -rf "$WORK"
  fi
fi

# ------------------------------------------------------------------ Dart codegen

step "Resolving Dart dependencies"
flutter pub get > /dev/null

if [ "$GENERATE" = "yes" ]; then
  step "Running the generators"
  dart run build_runner build --delete-conflicting-outputs
  flutter gen-l10n
fi

# -------------------------------------------------------------------- the data

# The core's thumbnail cache defaults to a path relative to the working
# directory, which would drop a thumbnails/ folder wherever the application was
# started from. Kept inside .dev so that everything a run writes outside the
# application-support folder is in one already-ignored place — which is what
# makes tools/clean.sh able to promise it leaves nothing behind.
#
# Set for --real-data too: a real catalog is a reason not to touch the index,
# not a reason to scatter cache files.
export ALEXANDRIA_PLAYBACK_THUMBNAIL_CACHE_DIR="$REPO_ROOT/.dev/thumbnails"

if [ "$REAL_DATA" = "yes" ]; then
  step "Running against the real catalog"
  note "indexing, deleting and purging will affect it"
else
  SCRATCH="$REPO_ROOT/.dev/catalog.db"
  mkdir -p "$(dirname "$SCRATCH")"
  export ALEXANDRIA_DATABASE_PATH="$SCRATCH"
  step "Running against a scratch catalog"
  note "$SCRATCH"
  note "delete that file to start over; --real-data uses the real one"
  # Only the catalog is redirected. Settings and the log still live in the
  # application-support directory, shared with an installed copy — worth
  # knowing before blaming the scratch database for remembered state.
fi

# ----------------------------------------------------------------------- run it

if [ "$NO_RUN" = "yes" ]; then
  step "Built and wired up; not starting the application (--no-run)"
  exit 0
fi

step "Starting Alexandria"
note "r hot-reloads Dart changes, R restarts, q quits"
note "core changes need this script again - the library is loaded once, at startup"
exec flutter run -d linux
