#!/bin/sh
# Checks the vendored webview_cef (third_party/webview_cef) against the
# upstream release it was forked from (NFR-12, third_party/webview_cef/FORK.md).
#
# Downloads the upstream archive from pub.dev and checks its sha256. Then it
# fails if:
#   - the files that differ from upstream, or were added, are not exactly the
#     list in FORK.md between the patched-files markers;
#   - any modified or added file lacks the fork notice (Apache-2.0 §4(b)).
#   - LICENSE differs from upstream's.
# A fix to the fork that is not recorded in FORK.md, or an upstream file
# changed by accident, fails here rather than being lost at the next sync.
#
# Writes only to a temporary directory under $TMPDIR. Needs curl, tar and
# sha256sum.
#
# Usage: tools/check-webview-cef-fork.sh

set -eu

UPSTREAM_VERSION=0.6.2
UPSTREAM_SHA256=1e028859e6fe4f52a82349a0acaa6594c1bd8317738df5764fd4365d6aebf6cc
NOTICE="Alexandria fork of webview_cef ${UPSTREAM_VERSION}"

root=$(cd "$(dirname "$0")/.." && pwd)
fork="$root/third_party/webview_cef"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/upstream.tar.gz" \
  "https://pub.dev/api/archives/webview_cef-${UPSTREAM_VERSION}.tar.gz"
echo "$UPSTREAM_SHA256  $work/upstream.tar.gz" | sha256sum -c - > /dev/null || {
  echo "error: the pub.dev archive of webview_cef ${UPSTREAM_VERSION} does not match the recorded sha256" >&2
  exit 1
}
mkdir "$work/upstream"
tar -xzf "$work/upstream.tar.gz" -C "$work/upstream"

# What actually differs. The CEF distribution the build downloads into
# third/cef/ is untracked and not part of the comparison.
(
  cd "$work/upstream"
  find . -type f | sed 's|^\./||' | sort
) > "$work/upstream.list"
(
  cd "$fork"
  git -C "$root" ls-files --cached --others --exclude-standard -- third_party/webview_cef \
    | sed 's|^third_party/webview_cef/||' | sort
) > "$work/fork.list"

: > "$work/actual"
while IFS= read -r file; do
  if ! grep -qxF "$file" "$work/upstream.list"; then
    echo "A $file" >> "$work/actual"
  elif ! cmp -s "$fork/$file" "$work/upstream/$file"; then
    echo "M $file" >> "$work/actual"
  fi
done < "$work/fork.list"
while IFS= read -r file; do
  grep -qxF "$file" "$work/fork.list" || echo "D $file" >> "$work/actual"
done < "$work/upstream.list"
sort -o "$work/actual" "$work/actual"

sed -n '/<!-- patched-files:begin -->/,/<!-- patched-files:end -->/p' "$fork/FORK.md" \
  | grep -E '^[MAD] ' | sort > "$work/recorded"

if ! diff -u "$work/recorded" "$work/actual"; then
  echo "error: third_party/webview_cef differs from upstream ${UPSTREAM_VERSION} in files other than the ones FORK.md lists ('-' recorded, '+' actual)." >&2
  exit 1
fi

status=0
while read -r kind file; do
  [ "$kind" = D ] && continue
  [ "$file" = FORK.md ] && continue
  if ! head -n 3 "$fork/$file" | grep -qF "$NOTICE"; then
    echo "error: third_party/webview_cef/$file is changed from upstream and does not say so in its first lines ('$NOTICE')" >&2
    status=1
  fi
done < "$work/actual"

cmp -s "$fork/LICENSE" "$work/upstream/LICENSE" || {
  echo "error: third_party/webview_cef/LICENSE differs from upstream's" >&2
  status=1
}

[ $status -eq 0 ] && echo "webview_cef fork: $(wc -l < "$work/actual") files differ from upstream ${UPSTREAM_VERSION}, exactly as FORK.md records."
exit $status
