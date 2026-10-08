#!/bin/sh
# Alexandria fork of webview_cef 0.6.2: added file (see FORK.md).
#
# Builds and runs the fork's native policy tests: webview_security.h and
# webview_sandbox.h, without CEF. Linux (and any POSIX host with a C++17
# compiler). Writes only to a temporary directory under $TMPDIR.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
"${CXX:-c++}" -std=c++17 -Wall -Wextra -Werror -I"$here/../../common" \
  "$here/security_test.cc" -o "$out/security_test"
"$out/security_test"
