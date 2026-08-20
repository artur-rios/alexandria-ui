# Technology Stack Document — Alexandria Desktop

## 1. Purpose

This document is the **single source of truth for the technologies used to build
Alexandria Desktop** — the runtime platform, language, libraries, local storage,
cross-cutting concerns, and testing tools, together with the version each is
pinned to and the role it plays.

Every other document in this folder **references this document** for technical
choices instead of restating them, so that:

- The domain documents ([Vision](Vision%20Document.md),
  [System Requirements](System%20Requirements%20Document.md),
  [Use Case Specification](Use%20Case%20Specification%20Document.md)) stay focused
  on *what* the application does.
- The [Operations & Infrastructure Document](Operations%20%26%20Infrastructure%20Document.md)
  stays focused on the platform's structure and operations.
- The [Testing Specification Document](Testing%20Specification%20Document.md)
  stays focused on *how* to test.
- Technology versions and roles are maintained in exactly **one** place.

> **Rule:** when a technology choice changes, it changes here first. Other
> documents link to this one rather than duplicating the detail.

### 1.1 Version policy

No version is pinned to a number in this document. Every entry reads
**latest stable at implementation time**, which is a recorded policy rather than
an unfilled value: at the moment a dependency is first added, the then-current
stable release is selected, written into the lockfile, and that lockfile becomes
the pin. This document records *what* is used and *why*; the lockfile records
*which build*.

Two consequences follow, and both are binding:

1. The lockfile is committed, so every machine and the CI pipeline resolve the
   same builds.
2. Upgrades are a deliberate change to the lockfile, reviewed like any other
   change — never a side effect of a fresh checkout.

---

## 2. Platform & Language

| Concern | Choice | Notes |
| --- | --- | --- |
| Runtime / framework | **Flutter** | Desktop embedders only. The Windows and Linux targets are enabled; macOS, web, iOS, and Android are not part of this project. |
| Language | **Dart** | Version tracks the Flutter SDK rather than being pinned independently. |
| Language features | Sound null safety, enabled project-wide | Non-negotiable: the FFI boundary returns nullable pointers, and the type system is what keeps that from reaching feature code. |
| Analysis | **flutter_lints**, with project-specific rules layered on top via **custom_lint** | Enforces the layering rules in [Operations & Infrastructure §2.4](Operations%20%26%20Infrastructure%20Document.md); the analyzer runs in CI and a warning fails the build. No analyzer rule can express "Presentation may not import Data", so the two rules that do — `avoid_data_layer_import` and `avoid_domain_outward_import` — live in the in-repo plugin `tools/alexandria_lints` and run as an analyzer plugin. |
| Windows target | Windows 10 (x64) and later | The MSVC toolchain builds the embedder; the Alexandria core ships alongside as a DLL. |
| Linux target | Ubuntu LTS (x64), GTK embedder | Other GTK-based distributions are best-effort; the core ships alongside as a shared object. |

---

## 3. Libraries

### 3.1 Application architecture

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **flutter_riverpod** | latest stable at implementation time | Application layer | State management and dependency injection. Providers are the composition root: every domain interface is bound to its implementation there, and tests override the binding rather than reaching into the widget tree. |
| **freezed** | latest stable at implementation time | Domain layer | Immutable domain models, unions for the typed failure model, and generated equality — which is what makes state comparison cheap enough for the rebuild budget in [System Requirements §6](System%20Requirements%20Document.md). |
| **json_serializable** | latest stable at implementation time | Data layer | Deserializes the JSON payloads the Alexandria core returns across the FFI boundary into domain models. |
| **build_runner** | latest stable at implementation time | Build | Runs the `freezed`, `json_serializable`, and `ffigen` generators. |

### 3.2 The Alexandria core boundary

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **ffi** | latest stable at implementation time | Data layer | Typed pointer and native-string handling over the C ABI. |
| **ffigen** | latest stable at implementation time | Build | Generates the Dart bindings from the `alexandria-ffi` crate's `header.h`. The bindings are generated, never hand-edited, so a change to the core's header surfaces as a compile error rather than as a runtime crash. |
| **alexandria_ffi** (native) | latest stable at implementation time | Data layer | The Alexandria Rust core, consumed as a bundled shared library (`.dll` on Windows, `.so` on Linux) and loaded in process at startup. It is the **only** source of catalog data. |

The generated bindings are wrapped by a gateway that owns three obligations the
rest of the application never sees: passing the session credential on every call,
translating status codes into typed failures, and freeing every string the core
returns with `alexandria_free_string`. Feature code depends on the gateway
interface declared in the domain layer, never on `dart:ffi`.

Because the core documents its FFI and HTTP surfaces as returning identical
payloads, that same interface admits an HTTP implementation later. Only the FFI
implementation is built in this scope.

### 3.3 Media playback

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **media_kit** | latest stable at implementation time | Playback | Audio and video playback engine, libmpv-backed. Chosen over the simpler embedders because subtitle-track and audio-track selection on both Windows and Linux are hard requirements, and it plays the container and codec range a real personal library contains without transcoding. |
| **media_kit_video** | latest stable at implementation time | Playback | The video render surface. |
| **media_kit_libs_video / media_kit_libs_audio** | latest stable at implementation time | Playback | The bundled native libmpv libraries for each target platform. |

### 3.4 Document, image, and page viewing

Every viewer reads bytes directly from the on-disk path the core reports. None of
them writes, re-encodes, or converts a file.

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **pdfrx** | latest stable at implementation time | Viewers | PDF rendering, with desktop-native performance on both targets. |
| **xml** | latest stable at implementation time | Viewers | Reads an EPUB's container and package documents. See *EPUB is read directly* below. |
| **archive** | latest stable at implementation time | Viewers | Reads CBZ comic archives and EPUB containers — both are zip — entry by entry, without extracting them to disk. |
| **flutter_widget_from_html** | latest stable at implementation time | Viewers | Renders saved HTML pages as widgets. Deliberately not a browser engine: no script execution, which is both a lighter dependency and a smaller trust surface for arbitrary saved pages. |
| **flutter_markdown** | latest stable at implementation time | Viewers, Editor | Renders Markdown for reading and for the editor's live preview pane. Discontinued upstream — see *flutter_markdown is discontinued* below. |
| **markdown** | latest stable at implementation time | Viewers | Parses Markdown to HTML where the page renderer draws it. |

Flutter's built-in `Image` decoders cover the image viewer; no additional package
is required for it.

**EPUB is read directly, not through an EPUB package.** The stack originally
named `epub_view`. It is unusable: it pins a pre-null-safety SDK, and every
maintained alternative pins `image` 3 against the 4 that `media_kit` requires —
so adopting one would mean giving up video playback. An EPUB is a zip carrying a
container document, a package document, a spine, and XHTML; `archive` opens the
zip and `xml` reads the two documents, which is the whole of what a reader needs.
The chapters come out as markup and are drawn by the same renderer a saved HTML
page uses, so the two viewers share one rendering path rather than each carrying
its own.

**flutter_markdown is discontinued.** It was marked discontinued upstream after
this stack was chosen. It is kept because it works, it is pure Dart, and nothing
about a discontinued package stops rendering Markdown correctly — but it will
not receive fixes, so it is a replacement waiting to be scheduled rather than a
choice to defend. `flutter_widget_from_html` already renders the saved-page
viewer and the EPUB chapters; routing Markdown through `markdown` to HTML and
then through it would collapse three renderers into one, and is the obvious
candidate when the time comes.

**Deferred decision — CBR.** CBZ archives are zip and are supported at launch by
`archive`. CBR archives are RAR, which has no maintained pure-Dart decoder; that
support requires binding a native decoder, and the selection is deliberately
deferred until comic viewing ships. The choice is recorded here when made.

### 3.5 Desktop shell and local state

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **window_manager** | latest stable at implementation time | Shell | Enforces the minimum window size and persists and restores window geometry across runs. |
| **file_selector** | latest stable at implementation time | Library sources | The native folder picker used to register a library folder. |
| **shared_preferences** | latest stable at implementation time | Data layer | The local key-value store for settings, registered library folders, and playback resume points. It holds **no catalog data and no credential**. |
| **path** / **path_provider** | latest stable at implementation time | Data layer | Resolves the per-platform application-support directory that holds the settings store, the log file, and the core's SQLite database. |

### 3.6 Cross-cutting

| Package | Version | Used by | Role |
| --- | --- | --- | --- |
| **flutter_localizations** + **intl** | latest stable at implementation time | Presentation | Localization for `pt-BR` and `en`, backed by ARB message files. |
| **logging** | latest stable at implementation time | All layers | Structured application logging, routed to console in development and to a rolling local file in release builds. |

---

## 4. Local Storage

| Concern | Choice |
| --- | --- |
| Catalog database | **None owned by this application.** The catalog is a SQLite database owned by the Alexandria core. The application supplies its path at startup via `alexandria_index_init` and thereafter reads and writes it *only* through the core's FFI surface. Opening that file directly is prohibited by [Business Rules BR-01 and its prohibitions](../initial/Business%20Rules.md). |
| Database location | The per-platform application-support directory resolved by `path_provider`, overridable by configuration for development and tests. |
| Application settings | **shared_preferences** — theme, language, view layout, registered library folders, per-type sort and filter defaults, playback resume points, and window geometry. |
| Credentials | **Never stored by this application.** The salted hash lives in the core; the session credential lives in process memory for the run of the application only. |
| File bytes | **Never stored or copied.** Media and document content is read from the on-disk path on each open. |

The same storage mechanisms are used in every environment. Tests differ only in
pointing at a temporary directory rather than the real application-support path,
so no test can reach the developer's own library or settings.

---

## 5. Data Access

| Concern | Choice | Version |
| --- | --- | --- |
| Native binding generation | **ffigen**, from the core's `header.h` | latest stable at implementation time |
| Call surface | The C ABI exported by **alexandria_ffi** | latest stable at implementation time |
| Payload format | JSON strings returned by the core, deserialized by **json_serializable** | latest stable at implementation time |
| Concurrency | Dart isolates — every core call runs off the UI isolate | — |
| Memory ownership | Every string the core returns is freed with `alexandria_free_string` in a `finally` block | — |
| Naming convention | Dart models use `lowerCamelCase` fields matching the core's JSON keys; the C symbol names are untouched in the generated bindings | — |

The access pattern is a **gateway per domain area** — files, collections,
bookmarks, watchlists, reading lists, indexing, auth — each declared as an
abstract interface in the domain layer and implemented once in the data layer
over the generated bindings. That indirection is what makes the whole application
testable without a native library present: unit and widget tests bind a fake
implementation of the interface, and only the integration suite loads the real
core. It is also what makes the future HTTP transport a substitution rather than
a rewrite.

---

## 6. Cross-Cutting Technologies

| Concern | Technology | Version | How it is used |
| --- | --- | --- | --- |
| Input validation | Dart validators in the domain layer | — | Validates before the call for immediate feedback; the core's verdict is always final and always surfaced. |
| Logging | **logging** | latest stable at implementation time | Structured records to console in development and to a rolling file in release. Credentials, session material, and file contents are never logged. |
| Authentication | The core's local-login surface (`alexandria_auth_local_login`, `alexandria_auth_local_set_credentials`) | latest stable at implementation time | The application collects the credentials, forwards them, and holds the returned session in memory only. |
| Error / result model | A `freezed` union of typed failures | latest stable at implementation time | Every core status code maps to exactly one failure variant, and every variant maps to a localized message. A raw status code never reaches the screen. |
| Configuration | Dart compile-time environment values plus the local settings store | — | See [Operations & Infrastructure §3](Operations%20%26%20Infrastructure%20Document.md). |
| Dependency injection | **flutter_riverpod** providers | latest stable at implementation time | The provider graph is the composition root; tests override providers rather than patching globals. |
| Localization | **flutter_localizations** + **intl** with ARB files | latest stable at implementation time | Both locales are complete before a use case is done; a missing key fails the analyzer, not the user. |
| Theming | Flutter `ThemeData` (Material 3), light and dark | — | Colors, spacing, and typography come from the theme; literals in widgets are prohibited by [BR-18](../initial/Business%20Rules.md). |

---

## 7. Testing Technologies

These are the technologies mandated for tests. **How** they are applied (naming,
structure, coverage, the per-use-case workflow) is defined in the
[Testing Specification Document](Testing%20Specification%20Document.md); this
section is the canonical list of the tools and versions.

| Concern | Technology | Version | How it is used |
| --- | --- | --- | --- |
| Test framework | **flutter_test** | latest stable at implementation time | Unit and widget tests. |
| Integration driver | **integration_test** | latest stable at implementation time | Whole-flow tests driving the real Alexandria core over FFI on a desktop target. |
| Test doubles | **mocktail** | latest stable at implementation time | Fakes and stubs for the gateway interfaces. It is the only mocking library in the project; a second one is not introduced. |
| Provider overrides | **flutter_riverpod** `ProviderContainer` / `ProviderScope` overrides | latest stable at implementation time | The mechanism by which a test substitutes a fake gateway. |
| Golden images | **flutter_test** golden files | latest stable at implementation time | Theme and layout regressions on key screens, in both themes. |
| Coverage | `flutter test --coverage` with **lcov** | latest stable at implementation time | Produces the coverage report the CI pipeline publishes. |
| Integration dependencies | A temporary SQLite database and a fixture library folder created per test run | — | The real core, never a fake, over a throwaway database. No test touches a real library. |

---

## 8. Version Summary

| Category | Package / Tool | Version |
| --- | --- | --- |
| Platform | Flutter (Windows + Linux desktop) | latest stable at implementation time |
| Language | Dart | tracks the Flutter SDK |
| Analysis | flutter_lints | latest stable at implementation time |
| Analysis | custom_lint (+ `custom_lint_builder`, `analyzer_plugin`, for `tools/alexandria_lints`) | latest stable at implementation time |
| Architecture | flutter_riverpod | latest stable at implementation time |
| Architecture | freezed | latest stable at implementation time |
| Architecture | json_serializable | latest stable at implementation time |
| Build | build_runner | latest stable at implementation time |
| Core boundary | ffi | latest stable at implementation time |
| Core boundary | ffigen | latest stable at implementation time |
| Core boundary | alexandria_ffi (native shared library) | latest stable at implementation time |
| Playback | media_kit | latest stable at implementation time |
| Playback | media_kit_video | latest stable at implementation time |
| Playback | media_kit_libs_video / media_kit_libs_audio | latest stable at implementation time |
| Viewers | pdfrx | latest stable at implementation time |
| Viewers | xml | latest stable at implementation time |
| Viewers | archive | latest stable at implementation time |
| Viewers | flutter_widget_from_html | latest stable at implementation time |
| Viewers | flutter_markdown | latest stable at implementation time |
| Viewers | markdown | latest stable at implementation time |
| Shell | window_manager | latest stable at implementation time |
| Shell | file_selector | latest stable at implementation time |
| Storage | shared_preferences | latest stable at implementation time |
| Storage | path / path_provider | latest stable at implementation time |
| Cross-cutting | flutter_localizations + intl | latest stable at implementation time |
| Cross-cutting | logging | latest stable at implementation time |
| Testing | flutter_test | latest stable at implementation time |
| Testing | integration_test | latest stable at implementation time |
| Testing | mocktail | latest stable at implementation time |
| Testing | lcov | latest stable at implementation time |
| Packaging | msix | latest stable at implementation time |
| Packaging | flutter_distributor | latest stable at implementation time |
| CI | GitHub Actions (Windows and Ubuntu runners) | latest stable at implementation time |

A comic-book RAR (CBR) decoder is deliberately absent from this table; see
[§3.4](#34-document-image-and-page-viewing).
