# Technology Stack — Alexandria UI

## Platform & Language

Flutter with Dart, targeting the desktop embedders. No version is pinned yet; the
exact SDK and package versions are recorded as "latest stable at implementation
time" in the formal
[Technology Stack Document](../requirements/Technology%20Stack%20Document.md)
after selection.

Supported targets:

| Target | Requirement |
| --- | --- |
| **Windows** | Windows 10 and later, x64. |
| **Linux** | Ubuntu LTS is the guaranteed target; other GTK-based distributions are best-effort. |

macOS, web, and mobile are out of scope.

## Application Type

A single-window desktop application. There is no server process and no local HTTP
listener: the app links the Alexandria Rust core's shared library and calls it
in process.

Layering, applied feature-first (one folder per feature, these four layers
inside it):

1. **Presentation** — widgets, screens, and view models. Knows about UI state
   only.
2. **Application** — use-case orchestration and the state holders the
   presentation layer watches.
3. **Domain** — Dart models mirroring the core's entities, plus the abstract
   repository/gateway interfaces the application layer depends on.
4. **Data** — the concrete implementations: the FFI gateway, the on-disk file
   readers, and local settings storage.

SOLID is the baseline. The domain layer depends on nothing; every outward
dependency (the FFI surface, the filesystem, the media players, local storage) is
reached through an interface the domain owns, so a transport or library swap does
not reach into feature code.

## Data Storage

The app owns **no catalog database**. The Alexandria SQLite catalog belongs to the
Rust core, which the app initializes with a database path
(`alexandria_index_init`) and then only reads and writes through the FFI surface.

The app persists a small amount of purely local state on its own: the configured
library folders, the selected theme, the selected language, the chosen view
layout, last playback positions, and window geometry. A lightweight local
key-value store is used for this; the concrete package is selected in Phase 2.

File **bytes** are never stored or copied. Media and document content is read
directly from the on-disk path the core reports for each catalog record.

## Data Access

Dart FFI (`dart:ffi`) against the C ABI published by the `alexandria-ffi` crate
(`header.h`). Every call follows the same shape: pass a bearer/session token,
receive a status code plus a JSON string, then free that string with
`alexandria_free_string`.

The binding layer is generated from the C header rather than hand-written, and it
is wrapped by a gateway that converts status codes into typed Dart failures and
JSON into domain models. Feature code depends on the gateway interface, never on
`dart:ffi` directly.

Because the FFI and HTTP surfaces of the core are documented to return
byte-for-byte identical payloads, that same gateway interface can be implemented
over HTTP later. Only FFI is implemented in this scope.

## Authentication

Local-login mode, matching the Rust core:

1. **Sign-up** — the owner creates the single account with an e-mail and a
   password. The core stores a salted hash and sends a confirmation message; the
   app never persists the plaintext.
2. **Confirmation** — the owner submits the code the core sent. Until then the
   owner can sign in but the library stays locked.
3. **Every later run** — the owner logs in through
   `alexandria_auth_local_login`, and the app holds the returned session
   identifier in memory for the lifetime of the session, presenting it on every
   subsequent call.
4. **Credential change** — through preferences with an active session, reusing
   `alexandria_auth_local_set_credentials`.
5. **Password recovery** — from the login screen the owner requests a reset, then
   completes it with the token the core sent and a new password.

**Pending core support.** Of these, only login and set-credentials exist on the
core's published FFI surface today. Sign-up as a distinct operation, e-mail
confirmation, resending a confirmation, requesting a reset, and completing a
reset are capabilities the core will expose; the front-end specifies them now and
implements each when its call is published. The app never invents a call the core
does not export, and never sends e-mail itself — delivery, token lifetime, and
rate limiting are the core's.

The core's external-JWT mode is not driven by this app in this scope. The session
abstraction is transport-agnostic so that supporting it later does not change
feature code.

## Testing

Flutter's built-in test tooling, in three kinds:

| Kind | Scope |
| --- | --- |
| **Unit** | Domain models, mappers, view-model logic, and the JSON/status-code translation layer, with the FFI gateway faked. |
| **Widget** | Individual screens and components, including layout behavior across window sizes, theming, and localization. |
| **Integration** | Whole flows driven against a real Alexandria core over FFI, on a temporary database and a fixture library folder. |

Test names follow the Given-When-Then pattern
(`GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`). The suite is run with:

```bash
flutter test
```

## External Dependencies

- **The Alexandria Rust core** (`alexandria-ffi` shared library) — bundled with
  the application and loaded in process. It is the only source of catalog data.
- **The local filesystem** — every playback, view, and text edit reads or writes
  the file at the path the core reports.
- **A media playback engine** — `media_kit` (libmpv-backed) drives both audio and
  video, because subtitle selection and audio-track selection on Windows and
  Linux are requirements the simpler embedders do not meet.
- **Document and image renderers** — PDF, e-book, comic-book archive, image, and
  HTML rendering happen client-side from the on-disk bytes. Concrete packages are
  selected in Phase 2.

No network services, no payments, no identity provider, no message broker, and no
object storage are involved. E-mail is involved only indirectly: the core sends
confirmation and recovery messages, and the app never touches a mail transport.

## Deployment

Installable desktop packages, one per platform, each bundling the Flutter
application and the Alexandria core's shared library:

| Platform | Package |
| --- | --- |
| **Windows** | MSIX package, plus a plain installer executable. |
| **Linux** | AppImage, `.deb`, and Flatpak. |

Packages are produced by the project's CI pipeline. The concrete tooling and
signing story are settled in the
[Operations & Infrastructure Document](../requirements/Operations%20%26%20Infrastructure%20Document.md).
