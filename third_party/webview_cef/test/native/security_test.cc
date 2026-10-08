// Alexandria fork of webview_cef 0.6.2: added file (see FORK.md).
//
// The fork's security rules, without a browser: webview_security.h and
// webview_sandbox.h are plain C++ for exactly this reason. Built and run by
// run.sh (and by CI), with nothing but a C++17 compiler.

#include <sys/stat.h>
#include <unistd.h>

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <string>
#include <vector>

#include "webview_sandbox.h"
#include "webview_security.h"

namespace security = webview_cef::security;

namespace {

int failures = 0;
int checks = 0;

void Check(bool condition, const std::string& what) {
  ++checks;
  if (!condition) {
    ++failures;
    std::fprintf(stderr, "FAIL: %s\n", what.c_str());
  }
}

security::PageFolder Folder(const std::string& path,
                            security::PathStyle style = security::PathStyle::kPosix) {
  security::PageFolder folder;
  folder.path = path;
  folder.style = style;
  return folder;
}

bool HasSwitch(const std::vector<security::Switch>& switches, const std::string& name) {
  for (const auto& entry : switches) {
    if (entry.name == name) return true;
  }
  return false;
}

std::string ValueOf(const std::vector<security::Switch>& switches, const std::string& name) {
  for (const auto& entry : switches) {
    if (entry.name == name) return entry.value;
  }
  return "";
}

void Switches() {
  for (int mode : {1, 2, 3}) {
    for (bool gpu_off : {false, true}) {
      const auto switches = security::BrowserSwitches(mode, gpu_off, "");
      for (const auto& entry : switches) {
        Check(!security::IsForbiddenSwitch(entry.name),
              "the browser process is never given --" + entry.name);
      }
      Check(!HasSwitch(switches, "no-sandbox"), "no --no-sandbox");
      Check(!HasSwitch(switches, "disable-web-security"), "no --disable-web-security");
      Check(!HasSwitch(switches, "allow-running-insecure-content"),
            "no --allow-running-insecure-content");
      Check(!HasSwitch(switches, "single-process"), "mode 3 does not run single-process");
      Check(!HasSwitch(switches, "ignore-certificate-errors"), "no --ignore-certificate-errors");
      const std::string features = ValueOf(switches, "disable-features");
      Check(features.find("SameSiteByDefaultCookies") == std::string::npos,
            "SameSite-by-default cookies stay on");
      Check(features.find("CookiesWithoutSameSiteMustBeSecure") == std::string::npos,
            "insecure SameSite=None cookies stay refused");
    }
  }
  Check(security::IsForbiddenSwitch("no-sandbox"), "--no-sandbox is forbidden");
  Check(security::IsForbiddenSwitch("disable-web-security"), "--disable-web-security is forbidden");
  Check(security::IsForbiddenSwitch("allow-file-access-from-files"),
        "--allow-file-access-from-files is forbidden");
  Check(security::IsForbiddenSwitch("remote-debugging-port"), "--remote-debugging-port is forbidden");

  const auto kept = security::BrowserSwitches(1, true, "Foo");
  Check(ValueOf(kept, "disable-features") == "Foo,CalculateNativeWinOcclusion",
        "features already disabled on the line are kept");

  Check(security::FirstForbiddenSwitch([](const std::string& name) {
          return name == "no-sandbox";
        }) == "no-sandbox",
        "a --no-sandbox on the command line is found");
  Check(security::FirstForbiddenSwitch([](const std::string&) { return false; }).empty(),
        "a clean command line passes");
}

void LocalPaths() {
  std::string path;
  Check(security::LocalPathOf("file:///home/u/saved/page.html", security::PathStyle::kPosix, &path) &&
            path == "/home/u/saved/page.html",
        "a plain file URL");
  Check(security::LocalPathOf("file:///home/u/my%20pages/p%C3%A1gina.html",
                              security::PathStyle::kPosix, &path) &&
            path == "/home/u/my pages/p\xC3\xA1gina.html",
        "percent-encoding is decoded");
  Check(security::LocalPathOf("file://localhost/home/u/a.html", security::PathStyle::kPosix, &path) &&
            path == "/home/u/a.html",
        "localhost is this machine");
  Check(security::LocalPathOf("file:///home/u/a.html?x=1#top", security::PathStyle::kPosix, &path) &&
            path == "/home/u/a.html",
        "query and fragment are not part of the path");
  Check(!security::LocalPathOf("file://server/share/a.html", security::PathStyle::kPosix, &path),
        "another host (a UNC share) is refused");
  Check(!security::LocalPathOf("file:///home/u/saved/%2e%2e/secret", security::PathStyle::kPosix, &path),
        "an encoded .. is refused");
  Check(!security::LocalPathOf("file:///home/u/saved/../secret", security::PathStyle::kPosix, &path),
        "a literal .. is refused");
  Check(!security::LocalPathOf("file:///home/u/a%00.html", security::PathStyle::kPosix, &path),
        "an encoded NUL is refused");
  Check(!security::LocalPathOf("file:///home/u/a%5C..%5Csecret", security::PathStyle::kPosix, &path),
        "an encoded backslash is refused");
  Check(!security::LocalPathOf("file:///home/u/a%2", security::PathStyle::kPosix, &path),
        "a truncated escape is refused");
  Check(!security::LocalPathOf("https://example.com/a.html", security::PathStyle::kPosix, &path),
        "a web URL is not a local path");
  Check(security::LocalPathOf("file:///C:/Users/u/a.html", security::PathStyle::kWindows, &path) &&
            path == "/C:/Users/u/a.html",
        "a Windows drive path");
  Check(!security::LocalPathOf("file:///C:/Users/u/a.html:secret", security::PathStyle::kWindows, &path),
        "an alternate data stream is refused on Windows");
  Check(!security::LocalPathOf("file:///Users/u/a.html", security::PathStyle::kWindows, &path),
        "a drive-less path is refused on Windows");
  Check(!security::LocalPathOf("file://server/share/a.html", security::PathStyle::kWindows, &path),
        "a UNC share is refused on Windows");
}

void PageFolders() {
  security::PageFolder folder;
  Check(security::PageFolderOf("file:///home/u/saved/page.html", &folder,
                               security::PathStyle::kPosix) &&
            folder.path == "/home/u/saved",
        "a page's folder is the directory holding it");
  Check(!security::PageFolderOf("file:///page.html", &folder, security::PathStyle::kPosix),
        "a page at the filesystem root would open the whole disk");
  Check(!security::PageFolderOf("file:///C:/page.html", &folder, security::PathStyle::kWindows),
        "a page at a drive root would open the whole drive");
  Check(security::PageFolderOf("file:///C:/Users/u/page.html", &folder, security::PathStyle::kWindows) &&
            folder.path == "/C:/Users/u",
        "a Windows page's folder");
  Check(!security::PageFolderOf("file:///home/u/saved/", &folder, security::PathStyle::kPosix),
        "a directory is not a page");
  Check(!security::PageFolderOf("https://example.com/page.html", &folder, security::PathStyle::kPosix),
        "a web page is not opened");
  Check(!security::PageFolderOf("", &folder, security::PathStyle::kPosix), "nothing is not a page");
}

void Containment() {
  const auto posix = Folder("/home/u/saved");
  Check(security::IsInsideFolder(posix, "file:///home/u/saved/page.html"), "the page itself");
  Check(security::IsInsideFolder(posix, "file:///home/u/saved/page_files/a.png"),
        "the page's _files folder");
  Check(security::IsInsideFolder(posix, "file:///home/u/saved/"), "the folder itself");
  Check(!security::IsInsideFolder(posix, "file:///home/u/secret.txt"), "the folder's parent");
  Check(!security::IsInsideFolder(posix, "file:///home/u/saved2/a.png"),
        "a sibling sharing the folder's name as a prefix");
  Check(!security::IsInsideFolder(posix, "file:///etc/hostname"), "a system file");
  Check(!security::IsInsideFolder(posix, "file:///home/u/Saved/a.png"), "POSIX paths are case-sensitive");
  Check(!security::IsInsideFolder(security::PageFolder(), "file:///home/u/saved/a.png"),
        "no folder, no files");

  const auto windows = Folder("/C:/Users/u/saved", security::PathStyle::kWindows);
  Check(security::IsInsideFolder(windows, "file:///c:/users/U/SAVED/a.png"),
        "Windows paths compare without case");
  Check(!security::IsInsideFolder(windows, "file:///C:/Users/u/secret.txt"), "the parent on Windows");

  // A symlink in the folder that points out of it.
  const security::PathResolver link = [](const std::string& path, std::string* resolved) {
    *resolved = path == "/home/u/saved/innocent.png" ? "/etc/shadow" : path;
    return true;
  };
  Check(!security::IsInsideFolder(posix, "file:///home/u/saved/innocent.png", link),
        "a link out of the folder is followed, and refused");
  const security::PathResolver missing = [](const std::string&, std::string*) { return false; };
  Check(!security::IsInsideFolder(posix, "file:///home/u/saved/nothing.png", missing),
        "a path that cannot be resolved is refused");
}

void RealSymlinks() {
  const char* tmp = std::getenv("TMPDIR");
  std::string root_template = std::string(tmp != nullptr && *tmp ? tmp : "/tmp") +
                              "/webview_cef_policy_XXXXXX";
  std::vector<char> buffer(root_template.begin(), root_template.end());
  buffer.push_back('\0');
  char* made = mkdtemp(buffer.data());
  Check(made != nullptr, "a scratch folder");
  if (made == nullptr) return;
  const std::string base(made);
  const std::string saved = base + "/saved";
  mkdir(saved.c_str(), 0700);
  std::ofstream(base + "/secret.txt") << "secret";
  std::ofstream(saved + "/page.html") << "<p>page</p>";
  std::ofstream(saved + "/inside.png") << "png";
  const bool linked = symlink((base + "/secret.txt").c_str(), (saved + "/link.png").c_str()) == 0;

  security::PageFolder folder;
  Check(security::PageFolderOf("file://" + saved + "/page.html", &folder, security::PathStyle::kPosix,
                               security::RealPathResolver),
        "the real page's folder");
  Check(security::MayLoad(folder, "file://" + saved + "/inside.png", security::RealPathResolver),
        "a real file inside the folder loads");
  if (linked) {
    Check(!security::MayLoad(folder, "file://" + saved + "/link.png", security::RealPathResolver),
          "a real symlink out of the folder does not");
  }
  Check(!security::MayLoad(folder, "file://" + base + "/secret.txt", security::RealPathResolver),
        "the real file beside the folder does not");
  Check(!security::MayLoad(folder, "file://" + saved + "/absent.png", security::RealPathResolver),
        "an absent file is refused like an outside one");

  std::string cleanup = "rm -rf '" + base + "'";
  if (std::system(cleanup.c_str()) != 0) std::fprintf(stderr, "could not remove %s\n", base.c_str());
}

void Navigations() {
  using security::Navigation;
  const auto folder = Folder("/home/u/saved");
  auto decide = [&](const std::string& url, bool main, bool gesture) {
    return security::DecideNavigation(folder, url, main, gesture);
  };
  Check(decide("file:///home/u/saved/page.html", true, false) == Navigation::kAllow,
        "the page loads");
  Check(decide("file:///home/u/saved/other.html", true, true) == Navigation::kAllow,
        "another page in the folder");
  Check(decide("file:///etc/", true, false) == Navigation::kBlock,
        "a script cannot send the page to /etc/");
  Check(decide("file:///etc/hostname", true, true) == Navigation::kBlock,
        "nor can a click, to a local file outside");
  Check(decide("https://example.com/", true, true) == Navigation::kOpenExternally,
        "a clicked web link goes to the application");
  Check(decide("mailto:someone@example.com", true, true) == Navigation::kOpenExternally,
        "a clicked mail link goes to the application");
  Check(decide("https://example.com/", true, false) == Navigation::kBlock,
        "a script-driven redirect to the web is dropped");
  Check(decide("data:text/html,<script>1</script>", true, true) == Navigation::kBlock,
        "the top frame never becomes a data: page");
  Check(decide("ms-msdt:/id", true, true) == Navigation::kBlock,
        "a registered scheme is never followed");
  Check(decide("about:blank", true, false) == Navigation::kAllow, "about:blank");
  Check(decide("https://www.youtube.com/embed/x", false, false) == Navigation::kAllow,
        "an embedded frame loads from the web (UC-25 AF-05)");
  Check(decide("about:srcdoc", false, false) == Navigation::kAllow, "an srcdoc frame");
  Check(decide("file:///etc/passwd", false, false) == Navigation::kBlock,
        "a frame cannot show a file outside the folder");
  Check(decide("chrome://settings", false, false) == Navigation::kBlock,
        "a frame cannot load the browser's own pages");
  Check(security::DecideNavigation(security::PageFolder(), "file:///home/u/saved/page.html", true, true) ==
            Navigation::kBlock,
        "a browser with no folder navigates nowhere on the disk");
}

void Loads() {
  const auto folder = Folder("/home/u/saved");
  Check(security::MayLoad(folder, "file:///home/u/saved/page_files/style.css"), "the page's stylesheet");
  Check(!security::MayLoad(folder, "file:///etc/hostname"), "a system file");
  Check(!security::MayLoad(folder, "file:///home/u/secret.txt"), "a file beside the folder");
  Check(!security::MayLoad(folder, "file://attacker.example/share/x.png"),
        "a picture on a file share (Windows sends credentials)");
  Check(security::MayLoad(folder, "https://cdn.example.com/x.js"), "the network (NFR-12)");
  Check(security::MayLoad(folder, "wss://example.com/socket"), "a web socket");
  Check(security::MayLoad(folder, "data:image/png;base64,AA=="), "a data: picture");
  Check(security::MayLoad(folder, "blob:null/1234"), "a blob the page made");
  Check(!security::MayLoad(folder, "ftp://example.com/x"), "a legacy scheme");
  Check(!security::MayLoad(folder, "chrome://version"), "the browser's own pages");
  Check(!security::MayLoad(folder, "filesystem:file:///x"), "the sandboxed filesystem scheme");
}

void ExternalLinks() {
  Check(security::MayOpenExternally("https://example.com"), "https");
  Check(security::MayOpenExternally("HTTP://EXAMPLE.COM/a?b#c"), "http, any case");
  Check(security::MayOpenExternally("mailto:a@example.com"), "mailto");
  Check(!security::MayOpenExternally("https://"), "a web URL with no host");
  Check(!security::MayOpenExternally("http:///path"), "an empty authority");
  Check(!security::MayOpenExternally("https://user@:443/"), "credentials and no host");
  Check(!security::MayOpenExternally("file:///etc/hostname"), "a local file");
  Check(!security::MayOpenExternally("javascript:alert(1)"), "script");
  Check(!security::MayOpenExternally("search-ms:query=x"), "a registered scheme");
  Check(!security::MayOpenExternally(""), "nothing");
}

void Sandbox() {
  const std::string reason = webview_cef::sandbox::UnavailableReason();
  std::printf("sandbox on this machine: %s\n",
              reason.empty() ? "available" : reason.c_str());
#if defined(__linux__)
  if (getuid() == 0) {
    Check(reason.find("root") != std::string::npos,
          "running as root, the engine is refused with a reason that says so");
  }
  Check(!webview_cef::sandbox::SetuidHelperUsable("/nonexistent/chrome-sandbox"),
        "an absent setuid helper is not usable");
  Check(!webview_cef::sandbox::SetuidHelperUsable("/proc/self/exe"),
        "a helper that is not setuid root is not usable");
#endif
}

}  // namespace

int main() {
  Switches();
  LocalPaths();
  PageFolders();
  Containment();
  RealSymlinks();
  Navigations();
  Loads();
  ExternalLinks();
  Sandbox();
  std::printf("%d checks, %d failed\n", checks, failures);
  return failures == 0 ? 0 : 1;
}
