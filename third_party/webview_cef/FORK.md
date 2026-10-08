# webview_cef: Alexandria's fork

This directory is a vendored and patched copy of the `webview_cef` Flutter
plugin. The application depends on it by path (`pubspec.yaml`:
`webview_cef: path: third_party/webview_cef`). It renders saved HTML pages in
the page viewer (UC-25, FR-VW-05).

| | |
|---|---|
| Upstream | <https://github.com/hlwhl/webview_cef> (pub.dev: [`webview_cef`](https://pub.dev/packages/webview_cef)) |
| Base version | **0.6.2**, the pub.dev archive `webview_cef-0.6.2.tar.gz`, sha256 `1e028859e6fe4f52a82349a0acaa6594c1bd8317738df5764fd4365d6aebf6cc` (published 2026-08-25) |
| CEF it downloads | 149.0.4+g2f1bfd8+chromium-149.0.7827.156 (`third/download.cmake`, unchanged) |
| Fork version | `0.6.2+alexandria.1` (`pubspec.yaml`) |
| Licence | Apache-2.0, upstream's (`LICENSE`, unchanged). Every file this fork changed or added starts with a line saying so, as Apache-2.0 §4(b) asks. |

The CEF binary distribution (`third/cef/`, about 2 GB) is not committed. The
plugin's build downloads it on first use, and upstream's own
`third/cef/.gitignore` keeps it out of git.

## Why it is forked

Upstream 0.6.2 starts Chromium in a way that a saved page's script can
exploit:

- `common/webview_app.cc` always adds `--disable-web-security`,
  `--allow-running-insecure-content` and `--no-sandbox`. It also adds
  `--ignore-certificate-errors` when a "filter domain" is set.
- `common/webview_plugin.cc` sets `CefSettings.no_sandbox = true`.
- `common/webview_handler.cc` `OnBeforePopup` loads every popup URL into the
  page's own frame. So `window.open('file:///…')` sends the page anywhere on
  the disk.

With web security off, the same-origin policy is off, and a `file:` page may
read every `file:` URL. Before the patch, this hostile page read
`/etc/hostname` with `XMLHttpRequest` (`'read:11'`), and nothing stopped it
from sending the contents anywhere. The page is
`integration_test/viewers/saved_page_engine_test.dart`, run against upstream
0.6.2. This contradicts NFR-12 and FR-VW-05: the page must run "only inside
the embedded browser engine's own sandbox", and "a document loaded that way
cannot read other local files". The application's review recorded it as
finding U6 (critical).

A remote fork on GitHub was not possible when this was done. This directory
is set up so that it can be pushed to one as it is (see *Syncing upstream*).

### Why upstream turned these off, and what this fork does instead

- **`disable-web-security` / `allow-running-insecure-content`.** Upstream's
  comment says "Support cross domain requests". It is a convenience for apps
  that embed remote web apps and want to call other origins. Loading a local
  page does not need it. With web security on, a `file:` page still loads its
  own pictures, stylesheets and scripts from disk, and reaches the network,
  just as when a browser opens it. The only thing the page loses is reading
  files through script (XHR or `fetch` of `file:`), which Chrome does not
  allow a saved page either.
- **`--allow-file-access-from-files` is not used** as a narrower substitute.
  Chromium has no per-folder form of it: it lets a `file:` page read every
  `file:` URL. Folder scoping comes from a request handler instead (below),
  which needs no extra Chromium privilege.
- **`no-sandbox`.** On Linux, Chromium's sandbox needs either unprivileged
  user namespaces or the setuid helper `chrome-sandbox` installed root-owned
  with mode 4755. Without either, Chromium does not run unsandboxed; it
  aborts the whole process (`FATAL: No usable sandbox!`). On Windows, CEF 138
  and later sandboxes only applications started through its `bootstrap.exe`,
  with the application built as a DLL, which a Flutter runner is not. Turning
  the sandbox off made the plugin start everywhere. This fork never turns it
  off. It checks first, and if the sandbox cannot run, it does not start
  Chromium. The application then draws the page with its own markup renderer
  (UC-25 AF-07), which runs no script.

## The patches

1. **No weakening switches** (`common/webview_app.cc`, `webview_app.h`,
   `webview_security.h`).
   - The browser-process switch list is built by
     `security::BrowserSwitches`, which never yields `disable-web-security`,
     `allow-running-insecure-content`, `no-sandbox`, `single-process` or
     `ignore-certificate-errors`.
   - The `SameSiteByDefaultCookies` and `CookiesWithoutSameSiteMustBeSecure`
     cookie protections are no longer disabled.
   - `WebviewApp::SetUnSafelyTreatInsecureOriginAsSecure` (no callers) is
     removed.
   - Kept from upstream: process-per-site with at most 8 renderers, the
     GPU-off switches for software rendering, autoplay without a gesture, and
     `CalculateNativeWinOcclusion` disabled.
2. **Sandbox on, or no engine** (`common/webview_plugin.cc`,
   `webview_plugin.h`, `webview_sandbox.h`).
   - `CefSettings.no_sandbox = false`.
   - Before `CefInitialize`, `startCEF()` refuses, with a reason, when the
     process's own command line carries a forbidden switch
     (`security::ForbiddenSwitches()`). Examples: `--no-sandbox`,
     `--disable-web-security`, `--allow-file-access-from-files`,
     `--remote-debugging-port`. Chromium honours these from the process's
     arguments as well.
   - It also refuses when `sandbox::UnavailableReason()` reports no usable
     sandbox:
     - **Linux, as root.** Chromium's sandbox refuses root.
     - **Linux, no namespace sandbox and no helper.** A forked child cannot
       create a user namespace, map itself into it, and create PID and
       network namespaces plus a nested user namespace. This happens when
       user namespaces are disabled, blocked by a container's seccomp
       policy, or restricted by Ubuntu 23.10+'s
       `kernel.apparmor_restrict_unprivileged_userns`. In addition, the
       setuid helper is not `<directory of libcef.so>/chrome-sandbox`, owned
       by root, with mode 4755. CEF looks for it beside `libcef.so`, which is
       `bundle/lib/` in a Flutter bundle. This was observed: a helper beside
       the executable is ignored, and a wrong one in `lib/` is `FATAL`.
     - **Windows and macOS: always.** See above.
   - The refusal is sticky: CEF may be initialized at most once per process.
     `init` answers with a `PlatformException`:
     - code `sandbox-unavailable` when the sandbox is missing;
     - code `engine-refused` for a forbidden switch, or when `CefInitialize`
       itself fails. Upstream ignored `CefInitialize`'s result.
   - `create` refuses until Chromium is up. `stopCEF()` only shuts down a CEF
     that started.
3. **Every navigation and subresource held to the page's folder**
   (`common/webview_handler.cc`, `webview_handler.h`, `webview_plugin.cc`,
   `webview_security.h`).
   - `create` accepts only a `file:` URL that names a local file inside a
     folder (`security::PageFolderOf`). These are refused: another host or
     UNC share, `..`, encoded NULs or backslashes, a Windows alternate data
     stream, and a page at the root of a drive or filesystem, which would
     open the whole disk. The folder is resolved with `realpath` on POSIX.
   - The browser is created empty, the folder is filed under its identifier,
     and only then is the page loaded. Otherwise the first request could
     arrive before the folder is known.
   - `OnBeforeBrowse` and `OnOpenURLFromTab` apply
     `security::DecideNavigation`:
     - The top-level frame stays inside the folder (plus `about:blank`).
     - A user-clicked `http`, `https` or `mailto` link is cancelled and
       reported as `onOpenLinkRequested`.
     - Any other top-level navigation is cancelled.
     - A subframe may also load `http`, `https`, `data` and `blob`
       (UC-25 AF-05).
   - `OnBeforeResourceLoad` applies `security::MayLoad`:
     - `file:` only inside the folder, after resolving symlinks, so a link
       out of the folder is refused;
     - `http`, `https`, `ws`, `wss`, `data` and `blob`, because NFR-12 lets
       the page reach the network;
     - nothing else.
     A request from a browser with no recorded folder loads nothing from the
     disk.
   - `OnProtocolExecution` never hands a URL to an OS-registered scheme
     handler.
4. **No popups** (`common/webview_handler.cc`). `OnBeforePopup` always
   cancels. A popup the user clicked to an `http`, `https` or `mailto`
   address is reported as `onOpenLinkRequested`. The host decides; the
   application checks the address again with its own rule
   (`isLinkTheViewerMayOpen`) before opening it in the system's browser or
   mail client. A scripted `window.open` is dropped.
5. **No downloads, permissions or DevTools** (`common/webview_handler.cc`,
   `webview_plugin.cc`).
   - `CanDownload` returns false.
   - Camera, microphone and screen requests are cancelled, and permission
     prompts are denied.
   - `openDevTools` is a no-op, and the Ctrl+F12 shortcut that opened
     DevTools is removed. A DevTools window is a second, unrestricted
     browser.
6. **No error page in the page's frame** (`common/webview_handler.cc`).
   Upstream navigated a failed frame to a `data:` URL with the failed URL
   spliced in unescaped. The top-level failure is now reported to the host as
   `onLoadError(url, errorCode, errorText)`, and the frame is left alone.
7. **Dart API** (`lib/src/webview_events_listener.dart`,
   `lib/src/webview_manager.dart`). `WebviewEventsListener` gains
   `onLoadError` and `onOpenLinkRequested`, and the manager routes the two new
   native events to them.
8. **Errors and threads in the platform glue** (`linux/webview_cef_plugin.cc`,
   `windows/webview_cef_plugin.cpp`).
   - A `[code, message]` error result becomes a `PlatformException` with that
     code and message. Upstream sent `"error"`/`"error"`.
   - On Linux, events from CEF's UI thread are posted to the GTK main context
     before they reach the platform channel. Flutter: "sent a message from
     native to Flutter on a non-platform thread … may result in data loss or
     crashes".
9. **Comments and version.**
   - `windows/CMakeLists.txt`: the comment on `USE_SANDBOX OFF` is updated.
   - `pubspec.yaml`: the version is `0.6.2+alexandria.1`.
10. **Tests** (`test/native/`). `security_test.cc` and `run.sh` test every
    rule in `webview_security.h` and the sandbox probe without a browser,
    using only a C++17 compiler.

### Every file that differs from upstream 0.6.2

`tools/check-webview-cef-fork.sh` in the application downloads the upstream
archive, checks its hash, and fails if the files that differ are not exactly
this list. It also fails if any of them lacks the fork notice. CI runs it.

<!-- patched-files:begin -->
```
M common/webview_app.cc
M common/webview_app.h
M common/webview_handler.cc
M common/webview_handler.h
M common/webview_plugin.cc
M common/webview_plugin.h
M lib/src/webview_events_listener.dart
M lib/src/webview_manager.dart
M linux/webview_cef_plugin.cc
M pubspec.yaml
M windows/CMakeLists.txt
M windows/webview_cef_plugin.cpp
A FORK.md
A common/webview_sandbox.h
A common/webview_security.h
A test/native/run.sh
A test/native/security_test.cc
```
<!-- patched-files:end -->

## What this means where the application runs

| Where | Page engine |
|---|---|
| Linux as an ordinary user, with unprivileged user namespaces (Fedora, Arch, Debian 12, and most others by default) | Starts sandboxed. |
| Ubuntu 23.10+ (`kernel.apparmor_restrict_unprivileged_userns=1` by default) | Starts only if `lib/chrome-sandbox` is root-owned with mode 4755, or an AppArmor profile grants the application `userns`. Otherwise the page is drawn as widgets, and the viewer says why. Neither is installed by the packages yet: that is a packaging decision for the owner. |
| Linux as root, Flatpak (no nested user namespaces), containers with the default seccomp policy | Refused; drawn as widgets. |
| Windows | Refused until the runner is started through CEF's sandbox bootstrap; drawn as widgets. |

## Verifying

- `third_party/webview_cef/test/native/run.sh` runs the policy and probe unit
  tests (Linux, a C++17 compiler).
- `integration_test/viewers/saved_page_engine_test.dart` tests the real
  engine.
  - A hostile page tries `XMLHttpRequest` and `fetch` on `/etc/hostname`, an
    XHR and an `<img>` just outside its folder, and two `window.open` calls,
    and then navigates to `file:///etc/`. The test asserts that all of it is
    blocked, that the page's own picture loads, that only the two links the
    test clicks are offered to the application, and that the frame never
    left the folder.
  - Where no sandbox can run (as root, and on Windows), the test instead
    asserts the `sandbox-unavailable` refusal.
- `tools/check-webview-cef-fork.sh` checks the patch list.

## Syncing upstream

1. Download the new release:
   `curl -fsSL -o new.tar.gz https://pub.dev/api/archives/webview_cef-<version>.tar.gz`.
   Check its sha256 against
   `https://pub.dev/api/packages/webview_cef/versions/<version>`
   (`archive_sha256`).
2. Extract it next to this directory. Take the 0.6.2 → new upstream diff for
   every file *not* in the list above as it is. For each listed file, re-apply
   the patch onto the new upstream version. `git diff` of this directory
   against a pristine 0.6.2 extraction shows exactly what the fork changed.
3. Re-check upstream's command-line switches, `CefSettings`, popup handling
   and request handlers for anything new that weakens isolation.
4. Update this file's base version, hash and CEF version. Update
   `UPSTREAM_VERSION` and `UPSTREAM_SHA256` in
   `tools/check-webview-cef-fork.sh`. Bump `pubspec.yaml` to
   `<version>+alexandria.1`.
5. Run `test/native/run.sh`, the tool above, `flutter test`, and the saved-page
   engine integration test on Linux as an ordinary user.

To publish the fork as a GitHub fork, push this directory's contents to a
fork of `hlwhl/webview_cef`, as a commit on the upstream tag that matches the
base version. The application can then use a `git:` dependency at that
commit instead of `path:`.
