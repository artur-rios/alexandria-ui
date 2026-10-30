// Alexandria fork of webview_cef 0.6.2: added file (see FORK.md).
//
// The rules the engine applies to a saved page: which command-line switches
// may never reach Chromium, which URLs a page may load or navigate to, and
// which links are handed to the host application to open.
//
// Pure C++17 with no CEF types, so that test/native/security_test.cc can
// exercise every rule without a browser. Header-only so that every platform's
// build (CMake, the macOS podspec's single translation unit) picks it up
// without a source-list change.

#ifndef WEBVIEW_CEF_SECURITY_H_
#define WEBVIEW_CEF_SECURITY_H_

#include <algorithm>
#include <cctype>
#include <climits>
#include <cstdlib>
#include <functional>
#include <string>
#include <utility>
#include <vector>

namespace webview_cef {
namespace security {

// ---------------------------------------------------------------------------
// Command-line switches
// ---------------------------------------------------------------------------

// Switches that weaken the page's isolation. Upstream appended the first three
// unconditionally; the rest are refused when they arrive on the process's own
// command line, because Chromium honours them from there too and a
// `--no-sandbox` in a launcher would otherwise switch the sandbox off without
// anything in the application noticing.
inline const std::vector<std::string>& ForbiddenSwitches() {
  static const std::vector<std::string> kSwitches = {
      "disable-web-security",
      "allow-running-insecure-content",
      "no-sandbox",
      "allow-file-access-from-files",
      "disable-site-isolation-trials",
      "single-process",
      "no-zygote",
      "disable-setuid-sandbox",
      "disable-namespace-sandbox",
      "disable-seccomp-filter-sandbox",
      "remote-debugging-port",
      "remote-debugging-pipe",
      "ignore-certificate-errors",
      "unsafely-treat-insecure-origin-as-secure",
      "user-data-dir",
  };
  return kSwitches;
}

inline bool IsForbiddenSwitch(const std::string& name) {
  const auto& all = ForbiddenSwitches();
  return std::find(all.begin(), all.end(), name) != all.end();
}

// The first forbidden switch present on a command line, or "" if none is.
// [has_switch] answers whether the line carries a given switch.
inline std::string FirstForbiddenSwitch(
    const std::function<bool(const std::string&)>& has_switch) {
  for (const auto& name : ForbiddenSwitches()) {
    if (has_switch(name)) return name;
  }
  return "";
}

// One switch the browser process is started with: a name, and a value when
// the switch takes one.
struct Switch {
  std::string name;
  std::string value;
  bool has_value;
};

// The switches the browser process adds to its own command line.
//
// [process_mode] is upstream's: 1 process-per-site (the default), 2
// process-per-tab. Upstream's mode 3, "single-process", is not offered: it
// runs the page's renderer inside the application's own process, which is no
// sandbox at all. [disable_gpu] drops the GPU process for builds that render
// in software. [disabled_features] is whatever the line already disables,
// which is extended rather than replaced.
inline std::vector<Switch> BrowserSwitches(int process_mode,
                                           bool disable_gpu,
                                           const std::string& disabled_features) {
  std::vector<Switch> switches;
  if (disable_gpu) {
    switches.push_back({"disable-gpu", "", false});
    switches.push_back({"disable-gpu-compositing", "", false});
  }
  // Don't create a "GPUCache" directory when cache-path is unspecified.
  switches.push_back({"disable-gpu-shader-disk-cache", "", false});
  if (process_mode == 2) {
    switches.push_back({"process-per-tab", "", false});
  } else {
    switches.push_back({"process-per-site", "", false});
    switches.push_back({"renderer-process-limit", "8", true});
  }
  switches.push_back({"autoplay-policy", "no-user-gesture-required", true});

  // Upstream also disabled SameSiteByDefaultCookies and
  // CookiesWithoutSameSiteMustBeSecure here, "to support cross domain
  // requests". Both are cookie protections, and a saved page has no business
  // with either relaxed.
  std::string features = disabled_features;
  if (features.find("CalculateNativeWinOcclusion") == std::string::npos) {
    if (!features.empty()) features += ",";
    features += "CalculateNativeWinOcclusion";
  }
  switches.push_back({"disable-features", features, true});
  return switches;
}

// ---------------------------------------------------------------------------
// URLs
// ---------------------------------------------------------------------------

// How a path is compared: case-sensitively with `/` separators on POSIX;
// case-insensitively with a drive letter and no `:` elsewhere on Windows.
enum class PathStyle { kPosix, kWindows };

inline PathStyle NativePathStyle() {
#if defined(_WIN32)
  return PathStyle::kWindows;
#else
  return PathStyle::kPosix;
#endif
}

// Resolves a decoded absolute path to the file it really names (following
// symlinks), or returns false if it cannot. The identity on platforms that
// do not resolve.
using PathResolver = std::function<bool(const std::string&, std::string*)>;

inline bool IdentityResolver(const std::string& path, std::string* resolved) {
  *resolved = path;
  return true;
}

// The resolver the engine uses: the real file a path names, following
// symlinks, so that a link inside the page's folder cannot reach outside it.
// Fails for a path that does not exist, which is then refused like one
// outside the folder — the page cannot tell the two apart, so it cannot use
// the answer to probe for files. POSIX only; on Windows the lexical check is
// what applies (junctions and symlinks there need administrator rights or
// developer mode to create, and are not resolved).
inline bool RealPathResolver(const std::string& path, std::string* resolved) {
#if defined(_WIN32)
  *resolved = path;
  return true;
#else
  char buffer[PATH_MAX];
  if (realpath(path.c_str(), buffer) == nullptr) return false;
  *resolved = buffer;
  return true;
#endif
}

inline std::string ToLower(std::string text) {
  std::transform(text.begin(), text.end(), text.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return text;
}

// The scheme of [url], lower-cased, or "" if it has none.
inline std::string SchemeOf(const std::string& url) {
  const auto colon = url.find(':');
  if (colon == std::string::npos || colon == 0) return "";
  for (size_t i = 0; i < colon; ++i) {
    const unsigned char c = static_cast<unsigned char>(url[i]);
    const bool ok = std::isalpha(c) ||
                    (i > 0 && (std::isdigit(c) || c == '+' || c == '-' || c == '.'));
    if (!ok) return "";
  }
  return ToLower(url.substr(0, colon));
}

inline int HexValue(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

// Percent-decodes [encoded]. False on a malformed escape or an encoded NUL.
inline bool PercentDecode(const std::string& encoded, std::string* decoded) {
  decoded->clear();
  for (size_t i = 0; i < encoded.size(); ++i) {
    if (encoded[i] != '%') {
      decoded->push_back(encoded[i]);
      continue;
    }
    if (i + 2 >= encoded.size()) return false;
    const int high = HexValue(encoded[i + 1]);
    const int low = HexValue(encoded[i + 2]);
    if (high < 0 || low < 0) return false;
    const char c = static_cast<char>(high * 16 + low);
    if (c == '\0') return false;
    decoded->push_back(c);
    i += 2;
  }
  return true;
}

// The decoded, absolute local path a `file:` URL names, in URL form (`/`
// separators; `/C:/…` on Windows). False for anything that is not a plain
// local path: another host (a UNC share — on Windows, opening one sends the
// user's credentials to it), a relative or dot segment, a backslash, an
// encoded NUL, or — on Windows — a `:` anywhere but the drive letter (an
// alternate data stream).
inline bool LocalPathOf(const std::string& url, PathStyle style, std::string* path) {
  if (SchemeOf(url) != "file") return false;
  const std::string prefix = "file://";
  if (url.size() < prefix.size() || ToLower(url.substr(0, prefix.size())) != prefix) {
    return false;
  }
  std::string rest = url.substr(prefix.size());
  const auto slash = rest.find('/');
  if (slash == std::string::npos) return false;
  const std::string host = ToLower(rest.substr(0, slash));
  if (!host.empty() && host != "localhost") return false;
  std::string encoded = rest.substr(slash);
  const auto end = encoded.find_first_of("?#");
  if (end != std::string::npos) encoded = encoded.substr(0, end);

  std::string decoded;
  if (!PercentDecode(encoded, &decoded)) return false;
  if (decoded.empty() || decoded[0] != '/') return false;
  if (decoded.find('\\') != std::string::npos) return false;

  // Every segment after the leading slash: no `.` or `..` survives URL
  // canonicalization, so one that is here was put here to climb out.
  size_t start = 1;
  int index = 0;
  while (start <= decoded.size()) {
    const auto next = decoded.find('/', start);
    const std::string segment = decoded.substr(
        start, next == std::string::npos ? std::string::npos : next - start);
    if (segment == "." || segment == "..") return false;
    if (style == PathStyle::kWindows) {
      const auto colon = segment.find(':');
      if (colon != std::string::npos) {
        const bool drive = index == 0 && segment.size() == 2 && colon == 1 &&
                           std::isalpha(static_cast<unsigned char>(segment[0]));
        if (!drive) return false;
      }
    }
    if (next == std::string::npos) break;
    start = next + 1;
    ++index;
  }
  if (style == PathStyle::kWindows) {
    // `/C:/…` and nothing else: a Windows path without a drive is relative
    // to whatever drive is current.
    if (decoded.size() < 4 || decoded[2] != ':' || decoded[3] != '/' ||
        !std::isalpha(static_cast<unsigned char>(decoded[1]))) {
      return false;
    }
  }
  *path = decoded;
  return true;
}

// The folder a page's own files may come from: the directory holding the
// page. Empty when the engine must not open [page_url] at all.
struct PageFolder {
  std::string path;  // decoded, resolved, without a trailing slash
  PathStyle style = NativePathStyle();

  bool empty() const { return path.empty(); }
};

// The folder of the page at [page_url], which must be a `file:` URL naming a
// file. False for anything else, and for a page at the root of a drive or of
// the filesystem: its "folder" would be the whole disk.
inline bool PageFolderOf(const std::string& page_url,
                         PageFolder* folder,
                         PathStyle style = NativePathStyle(),
                         const PathResolver& resolve = IdentityResolver) {
  std::string path;
  if (!LocalPathOf(page_url, style, &path)) return false;
  if (path.back() == '/') return false;
  std::string resolved;
  if (!resolve(path, &resolved) || resolved.empty() || resolved[0] != '/') {
    return false;
  }
  const auto slash = resolved.rfind('/');
  std::string directory = resolved.substr(0, slash);
  // "" is POSIX's root, "/C:" a Windows drive's.
  if (directory.empty()) return false;
  if (style == PathStyle::kWindows && directory.size() <= 3) return false;
  folder->path = directory;
  folder->style = style;
  return true;
}

// Whether the `file:` URL [url] names something inside [folder].
inline bool IsInsideFolder(const PageFolder& folder,
                           const std::string& url,
                           const PathResolver& resolve = IdentityResolver) {
  if (folder.empty()) return false;
  std::string path;
  if (!LocalPathOf(url, folder.style, &path)) return false;
  // A directory URL ends in a slash; the folder itself is inside itself.
  while (path.size() > 1 && path.back() == '/') path.pop_back();
  std::string resolved;
  if (!resolve(path, &resolved)) return false;
  std::string base = folder.path;
  if (folder.style == PathStyle::kWindows) {
    resolved = ToLower(resolved);
    base = ToLower(base);
  }
  if (resolved == base) return true;
  return resolved.size() > base.size() + 1 &&
         resolved.compare(0, base.size(), base) == 0 &&
         resolved[base.size()] == '/';
}

// Whether [url] is a link the host application may be asked to open: a web
// address with a host, or a mail address. The same rule as the application's
// own `isLinkTheViewerMayOpen`, which checks it again on its side.
inline bool MayOpenExternally(const std::string& url) {
  const std::string scheme = SchemeOf(url);
  if (scheme == "mailto") return true;
  if (scheme != "http" && scheme != "https") return false;
  const std::string rest = url.substr(scheme.size() + 1);
  if (rest.size() < 3 || rest.compare(0, 2, "//") != 0) return false;
  const auto end = rest.find_first_of("/?#", 2);
  std::string authority = rest.substr(2, end == std::string::npos ? std::string::npos : end - 2);
  const auto at = authority.rfind('@');
  if (at != std::string::npos) authority = authority.substr(at + 1);
  return !authority.empty() && authority[0] != ':';
}

inline bool IsAboutBlankOrSrcdoc(const std::string& url) {
  const std::string lower = ToLower(url);
  auto is = [&](const std::string& target) {
    return lower == target || lower.rfind(target + "#", 0) == 0 ||
           lower.rfind(target + "?", 0) == 0;
  };
  return is("about:blank") || is("about:srcdoc");
}

enum class Navigation {
  kAllow,           // let the frame navigate
  kBlock,           // cancel it
  kOpenExternally,  // cancel it, and ask the application to open the link
};

// What happens when a frame of a page in [folder] navigates to [url].
//
// The page's top-level frame stays in its folder: the owner opened a page,
// not a browser, and a script that sends it to `file:///etc/` or to a
// look-alike sign-in page is not reading. A link the owner clicked to a web
// or mail address is handed to the application, which opens it in the
// system's browser or mail client. A frame embedded in the page may load from
// the network as it would in a browser (UC-25 AF-05), or from the page's
// folder, and nowhere else on the disk.
inline Navigation DecideNavigation(const PageFolder& folder,
                                   const std::string& url,
                                   bool is_main_frame,
                                   bool user_gesture,
                                   const PathResolver& resolve = IdentityResolver) {
  const std::string scheme = SchemeOf(url);
  if (scheme == "file") {
    return IsInsideFolder(folder, url, resolve) ? Navigation::kAllow : Navigation::kBlock;
  }
  if (IsAboutBlankOrSrcdoc(url)) return Navigation::kAllow;
  if (is_main_frame) {
    return user_gesture && MayOpenExternally(url) ? Navigation::kOpenExternally
                                                  : Navigation::kBlock;
  }
  if (scheme == "http" || scheme == "https" || scheme == "data" || scheme == "blob") {
    return Navigation::kAllow;
  }
  return Navigation::kBlock;
}

// Whether a page in [folder] may load [url] as a subresource (a picture, a
// stylesheet, a script, a request its script makes).
//
// The network as a browser would (NFR-12: "a page opened this way can reach
// the network exactly as it would in a browser"); `file:` only inside the
// page's folder, so that a page can neither show nor probe the files around
// it; and none of the browser's internal or legacy schemes.
inline bool MayLoad(const PageFolder& folder,
                    const std::string& url,
                    const PathResolver& resolve = IdentityResolver) {
  const std::string scheme = SchemeOf(url);
  if (scheme == "file") return IsInsideFolder(folder, url, resolve);
  return scheme == "http" || scheme == "https" || scheme == "ws" || scheme == "wss" ||
         scheme == "data" || scheme == "blob" || IsAboutBlankOrSrcdoc(url);
}

}  // namespace security
}  // namespace webview_cef

#endif  // WEBVIEW_CEF_SECURITY_H_
