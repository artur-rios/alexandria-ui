// Alexandria fork of webview_cef 0.6.2: added file (see FORK.md).
//
// Whether Chromium's sandbox can run in this process, asked before CEF is
// initialized.
//
// Upstream ran every page with `--no-sandbox`. This fork never does: the
// engine starts sandboxed or it does not start, and the application draws
// the page without it. That has to be decided here, ahead of CefInitialize,
// because Chromium's own answer to a missing sandbox on Linux is
// `LOG(FATAL) "No usable sandbox!"` in the browser process — which is the
// application's process. So this probe mirrors the checks Chromium makes
// (zygote_host_impl_linux.cc) and is at least as strict: when it says yes,
// Chromium will find a sandbox; when it says no, the page falls back.
//
// Header-only for the same reason as webview_security.h.

#ifndef WEBVIEW_CEF_SANDBOX_H_
#define WEBVIEW_CEF_SANDBOX_H_

#include <string>

#if defined(__linux__)
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <sched.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#endif

namespace webview_cef {
namespace sandbox {

#if defined(__linux__)

namespace internal {

// Writes [text] to [path]. Async-signal-safe: called in a forked child of a
// multi-threaded process, where nothing that allocates or locks may run.
inline bool WriteFileInChild(const char* path, const char* text, size_t length) {
  const int fd = open(path, O_WRONLY | O_CLOEXEC);
  if (fd < 0) return false;
  const ssize_t written = write(fd, text, length);
  close(fd);
  return written == static_cast<ssize_t>(length);
}

}  // namespace internal

// Whether an unprivileged process can build the namespaces Chromium's
// namespace sandbox uses: a new user namespace it can map itself into, new
// PID and network namespaces inside it, and a nested user namespace (the
// check Chromium makes for Debian's `unprivileged_userns_clone`). Fails on
// kernels that disable unprivileged user namespaces, under a seccomp policy
// that forbids them (most container runtimes), and under Ubuntu 23.10+'s
// `kernel.apparmor_restrict_unprivileged_userns`, which lets the namespace be
// created and then denies the capabilities inside it.
inline bool UserNamespacesWork() {
  char uid_map[64];
  char gid_map[64];
  const int uid_length = snprintf(uid_map, sizeof uid_map, "%u %u 1\n",
                                  static_cast<unsigned>(getuid()),
                                  static_cast<unsigned>(getuid()));
  const int gid_length = snprintf(gid_map, sizeof gid_map, "%u %u 1\n",
                                  static_cast<unsigned>(getgid()),
                                  static_cast<unsigned>(getgid()));
  if (uid_length <= 0 || gid_length <= 0) return false;

  const pid_t child = fork();
  if (child < 0) return false;
  if (child == 0) {
    if (unshare(CLONE_NEWUSER) != 0) _exit(1);
    // Absent on kernels older than 3.19, where it is not needed.
    internal::WriteFileInChild("/proc/self/setgroups", "deny", 4);
    if (!internal::WriteFileInChild("/proc/self/uid_map", uid_map, uid_length)) _exit(2);
    if (!internal::WriteFileInChild("/proc/self/gid_map", gid_map, gid_length)) _exit(3);
    if (unshare(CLONE_NEWPID | CLONE_NEWNET) != 0) _exit(4);
    if (unshare(CLONE_NEWUSER) != 0) _exit(5);
    _exit(0);
  }
  int status = 0;
  while (waitpid(child, &status, 0) < 0) {
    if (errno != EINTR) return false;
  }
  return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

// The setuid sandbox helper Chromium falls back to when user namespaces are
// unavailable: `chrome-sandbox` in the directory libcef.so was loaded from,
// owned by root and setuid. Not beside the executable: in a Flutter bundle
// CEF lives in `lib/`, and that is where Chromium looks (observed: "The SUID
// sandbox helper binary was found, but is not configured correctly ... make
// sure that <bundle>/lib/chrome-sandbox is owned by root and has mode 4755").
// Chromium aborts the process if the file is there and not set up that way,
// so "there but wrong" is "unusable" here too.
//
// [libcef_symbol] is the address of any function exported by libcef.so; the
// executable's own directory is used when it is null or cannot be placed.
inline std::string SetuidHelperPath(const void* libcef_symbol) {
  std::string module;
  Dl_info info;
  if (libcef_symbol != nullptr && dladdr(libcef_symbol, &info) != 0 &&
      info.dli_fname != nullptr && info.dli_fname[0] == '/') {
    module = info.dli_fname;
  } else {
    char exe[PATH_MAX];
    const ssize_t length = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (length <= 0) return "";
    exe[length] = '\0';
    module = exe;
  }
  const auto slash = module.rfind('/');
  if (slash == std::string::npos) return "";
  return module.substr(0, slash) + "/chrome-sandbox";
}

inline bool SetuidHelperUsable(const std::string& path) {
  struct stat info;
  if (path.empty() || stat(path.c_str(), &info) != 0) return false;
  return S_ISREG(info.st_mode) && info.st_uid == 0 && (info.st_mode & S_ISUID) &&
         (info.st_mode & S_IXOTH);
}

#endif  // defined(__linux__)

// Why Chromium's sandbox cannot run here, or "" if it can. [libcef_symbol]
// locates the setuid helper (see SetuidHelperPath); unused off Linux.
inline std::string UnavailableReason(const void* libcef_symbol = nullptr) {
  (void)libcef_symbol;
#if defined(_WIN32)
  // CEF 138+ sandboxes Windows sub-processes only when the application is
  // launched through CEF's bootstrap executable, with the application itself
  // built as a DLL that bootstrap loads. A Flutter runner is a plain
  // executable, so sub-processes would run unsandboxed — which is exactly
  // what this fork exists to stop.
  return "Chromium's sandbox is not available on Windows in this build: it "
         "needs the application to be started through CEF's sandbox "
         "bootstrap, and this runner is not. The page is drawn without the "
         "browser engine.";
#elif defined(__APPLE__)
  return "Chromium's sandbox is not set up for macOS in this fork. The page "
         "is drawn without the browser engine.";
#elif defined(__linux__)
  if (getuid() == 0 || geteuid() == 0) {
    return "Chromium's sandbox does not run as root, and the page engine is "
           "never started without it. Run the application as an ordinary "
           "user.";
  }
  if (UserNamespacesWork()) return "";
  const std::string helper = SetuidHelperPath(libcef_symbol);
  if (SetuidHelperUsable(helper)) return "";
  return "Chromium's sandbox is unavailable: this system does not let an "
         "unprivileged process create user namespaces (disabled, blocked by "
         "a container's seccomp policy, or restricted by "
         "kernel.apparmor_restrict_unprivileged_userns on Ubuntu 23.10 and "
         "later), and the setuid helper " +
         (helper.empty() ? std::string("chrome-sandbox") : helper) +
         " is not installed owned by root with mode 4755. The page is drawn "
         "without the browser engine.";
#else
  return "Chromium's sandbox is not supported on this platform by this fork.";
#endif
}

}  // namespace sandbox
}  // namespace webview_cef

#endif  // WEBVIEW_CEF_SANDBOX_H_
