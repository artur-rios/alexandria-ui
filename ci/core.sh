# shellcheck shell=bash
# Builds the Alexandria core (alexandria-api's alexandria-ffi library) at the commit ci/pins.sh pins. Sourced by
# ci/integration.sh and ci/release-build.sh, not run. It replaces the workflows' second checkout, dtolnay/rust-toolchain,
# Swatinem/rust-cache and the apt-get of ffmpeg's development libraries.
#
#     build_core            clones the core into $CORE_DIR (default: core) and builds it
#
# Afterwards the library is $CORE_DIR/target/release/libalexandria_ffi.so and the generated header is
# $CORE_DIR/crates/alexandria-ffi/src/header.h. ALEXANDRIA_API_URL overrides where the core is cloned from (default:
# GitHub's read-only mirror). CARGO_HOME and RUSTUP_HOME (default: under $HOME) can be kept between runs to skip the
# toolchain download.
#
# Needs ci/pins.sh and ci/apt-packages.sh sourced first.

build_core() {
  local core_dir=${CORE_DIR:-core}
  local url=${ALEXANDRIA_API_URL:-https://github.com/${CORE_REPOSITORY}.git}

  # ffmpeg-next's ffmpeg-sys-next needs the ffmpeg C development libraries at build time (and clang for bindgen).
  ensure_packages ca-certificates curl git build-essential pkg-config clang \
    libavformat-dev libavcodec-dev libavutil-dev libavfilter-dev libavdevice-dev libswscale-dev libswresample-dev

  export CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
  export RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}
  export PATH="$CARGO_HOME/bin:$PATH"
  if ! command -v rustc >/dev/null 2>&1 || ! rustc --version | grep -q "^rustc $RUST_VERSION "; then
    local work
    work=$(mktemp -d)
    echo "ci/core.sh: installing Rust $RUST_VERSION"
    curl --fail --silent --show-error --location --retry 3 -o "$work/rustup-init" \
      "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init"
    echo "$RUSTUP_SHA256  $work/rustup-init" | sha256sum -c -
    chmod +x "$work/rustup-init"
    "$work/rustup-init" -y --no-modify-path --profile minimal --default-toolchain "$RUST_VERSION"
    rm -rf "$work"
  fi

  # A commit is fetched by its id: it is not necessarily the tip of any branch.
  rm -rf "$core_dir"
  git init --quiet "$core_dir"
  git -C "$core_dir" remote add origin "$url"
  git -C "$core_dir" fetch --quiet --depth 1 origin "$CORE_REF"
  git -C "$core_dir" -c advice.detachedHead=false checkout --quiet FETCH_HEAD

  (cd "$core_dir" && cargo build --release -p alexandria-ffi)
}
