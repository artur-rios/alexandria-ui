# Business Rules — Alexandria UI

The Alexandria Rust core owns the catalog's domain rules. This document does not
restate them; it records the rules **the desktop application itself** is
responsible for — how it mirrors the core's entities, what it owns locally, and
what it must never do on its own authority. Where a rule here refers to a core
rule, it does so by the core's identifier (`BR-xx` in the back-end's
`Business Rules.md`).

## Domain Entities

### Mirrored from the core (read-only projections)

The app holds Dart models mirroring the core's entities. They are projections of
what the FFI surface returns: the app displays and edits them through core calls
and never treats its in-memory copy as authoritative.

| Entity | Represents in the app |
| --- | --- |
| **File** | A cataloged on-disk resource, with its public UUID, name, path, type, and lifecycle state. The unit everything else in the interface is built around. |
| **VideoFile** | A `File` of type video, marked movie or series, playable by the video player and eligible for watchlists. |
| **AudioFile** | A `File` of type audio — a track — named and ordered by its tags (title, artist, album artist, album, year, genre, track number), whose tags are editable, and playable in the player bar. No playlists, play history, or music library around it: that is Orpheus's. |
| **TextFile** | A Markdown or plain-text `File` whose content the app can read from and write back to disk through the core. |
| **Document** | A PDF or e-book `File`. Viewable, metadata-only, eligible for reading lists. |
| **ComicBook** | A comic-book archive `File`. Viewable, metadata-only, eligible for reading lists. |
| **HtmlPage** | A saved HTML page `File`, viewable in a rendered view. |
| **Image** | An image `File`, viewable. |
| **Account** | The owner's credentials and their confirmation state, owned by the core. The application reads the state to decide what is reachable and never stores the credentials themselves. |
| **Bookmark** | A browser bookmark pointing at a URL, organizable into bookmark collections. |
| **Collection** | A named group of files or of bookmarks, discriminated by its kind. |
| **Watchlist** / **WatchProgress** | A tracking list of videos and each item's watch state and progress within it. |
| **ReadingList** / **ReadingProgress** | A tracking list of books and comics and each item's read state and progress within it. |
| **Library** | A folder on disk the owner has added, by name, as a library — the only way its files reach the catalog. Every file belongs to exactly one. The owner may add several. |

### Owned by the app

| Entity | Represents |
| --- | --- |
| **IndexRun** | An in-flight or finished index/refresh run started from the interface, identified by the run identifier the core returns, with its observed progress and result. |
| **Session** | The authenticated owner's session for the current run of the app: the credential material the core returned at login, held in memory only. |
| **AppSettings** | The owner's local preferences: theme, language, default view layout, per-type sort and filter defaults, and window geometry. |
| **PlaybackState** | What is currently playing and its position. Persisted per video as a resume point; a track keeps none. |
| **ViewerRegistration** | The binding from a file type to the viewer or player that can present it, and whether that viewer is currently available. |

## Relationships

| From | Cardinality | To | Notes |
| --- | --- | --- | --- |
| Library | 1 — N | File | A library holds many cataloged files, and every file belongs to exactly one library. The core owns both. |
| Library | 1 — N | IndexRun | Each library can be scanned and re-scanned many times. |
| Session | 1 — N | *every core call* | Each call carries the current session's credential. No session, no call. |
| ViewerRegistration | 1 — 1 | file type | Exactly one viewer or player is responsible for presenting a given file type at a time. |
| PlaybackState | N — 1 | File | Each playable file may carry a resume point; one item plays at a time. |
| AppSettings | 1 — 1 | the installation | A single settings record per machine. There is no per-user split — there is one user. |

Collections are presented as flat today because the core stores them flat, and
the app's collection tree model is shaped so that nesting becomes a data change
rather than a rewrite (see **BR-14**).

## Rules

| ID | Rule | Rationale |
| --- | --- | --- |
| **BR-01** | The app is a client. Catalog state, validation, lifecycle, and retention are the core's; the app renders them, surfaces their errors, and never re-decides them. | One source of truth. A rule enforced in two places drifts. |
| **BR-02** | The app never calls an operation the core's FFI surface does not expose. A capability the core lacks is a back-end change, not a front-end workaround. | Prevents the front-end from silently forking the domain. |
| **BR-03** | Every core call carries the current session's credential. With no active session, the app shows the login screen and issues no catalog calls. | The core rejects unauthenticated callers; the app must not pretend otherwise. |
| **BR-04** | The plaintext password is never persisted, never logged, and never held beyond the call that sends it to the core. | Mirrors the core's credential handling (`BR-18` back-end). |
| **BR-05** | The session credential lives in memory for the run of the app only. Closing the app ends the session. | A local single-user desktop app has no reason to persist a session token to disk. |
| **BR-06** | The app writes to disk in exactly two situations: saving a text file's content through the core, and writing its own settings and local state. Nothing else the app does modifies the filesystem. | The library's bytes belong to the owner, not the app. |
| **BR-07** | Every destructive action — soft delete, purge, purge-on-disk, removing an item from a list, deleting a collection — requires an explicit confirmation, and the confirmation states exactly what will be removed and whether the on-disk file is affected. | Purge-on-disk is irreversible; the interface must never let it happen by momentum. |
| **BR-08** | Purge-on-disk is presented distinctly from every other delete, never as the default action, and never reachable by a single click from a list row. | The one operation that destroys the owner's data deserves friction. |
| **BR-09** | The app performs no media editing: no re-encoding, no transcoding, no image manipulation. Text content, metadata, names, and organization are the only editable things. | Scope guard inherited from the product (`BR-04` back-end). |
| **BR-10** | Indexing is started from the interface and observed asynchronously. The interface stays usable, and browsing, playback, and editing continue while a run is in flight. | The core indexes asynchronously by design (`BR-09` back-end); blocking the UI would waste that. |
| **BR-11** | The owner may add **multiple** libraries, and a folder reaches the catalog only as one. Every library-scoped operation names its library, and the catalog is presented as one merged library across all of them. The app keeps no folder list of its own: the libraries are the core's. | Stated requirement: the app can point at different folders, not only one. Since core 0.6 there is no indexing outside a library, and a second list in the app's settings could only disagree with the core's. |
| **BR-12** | Adding, re-scanning, or moving a library never deletes cataloged records or on-disk files. Removing a library deletes its catalog records — its files with their reading and watching positions and collection membership, and its runs — and never touches the disk; its confirmation says exactly that. | A file is in the catalog only because it is inside a library, so removing the library removes its records; the disk is the owner's either way. |
| **BR-13** | File types are handled through a viewer/player registry, not through conditionals scattered across screens. Adding a type, or a renderer for a type the core later enriches, is a registration. | The core's media capabilities are growing; the interface must absorb that without a rewrite. |
| **BR-14** | Collection navigation is modeled as a tree whose current depth happens to be one. Nesting, when the core supports it, changes the data the tree is fed — not the navigation, the breadcrumbs, or the move/reparent interactions. | Stated requirement: the core will implement nested collections, and the front-end must be ready. |
| **BR-15** | A file's content is read from the path the core reports, at the moment it is opened. The app caches no file bytes across sessions. | The disk is the source of truth; a stale cache would show the owner something that no longer exists. |
| **BR-16** | When a cataloged file is missing on disk, the app shows it as missing with a way to re-scan, and never treats the absence as a reason to delete the record. | The core tracks missing files as a state; deletion is the owner's decision. |
| **BR-17** | Every user-visible string is localized. Both Brazilian Portuguese and English are complete before a use case is done; neither is a fallback for missing translations in the other. | Both languages are first-class, stated scope. |
| **BR-18** | Every screen is usable in light and dark themes, and colors come from the theme, never from literals in a widget. | Theming is scope, and hard-coded colors are how it breaks. |
| **BR-19** | Every screen adapts to window resizing down to the minimum supported window size without clipping or hiding a control behind an unreachable overflow. | Responsiveness without loss of usability is a stated product goal. |
| **BR-20** | Every operation that can take perceptible time shows a loading state, and every failure shows a human-readable message derived from the core's status code — never a raw code, and never a silent no-op. | Stated requirement for loading and modal feedback; silent failure is the worst outcome for a local app. |
| **BR-21** | **Removed (moved out of scope, see Orpheus)** | Music management lives in Orpheus; Alexandria plays tracks in the player bar only, so there is no full-window player for them. The number stays so that other references stay valid. |
| **BR-22** | Only one playback session plays at a time: opening a video pauses the music in the player bar. | Two videos at once, or a video over an album, is never what the owner meant. |
| **BR-23** | SOLID and feature-first layering are the baseline. The domain layer declares the interfaces; the FFI gateway, filesystem access, players, and local storage implement them and are injected. | Mandated design approach, and what makes a later HTTP transport a substitution rather than a rewrite. |
| **BR-24** | The app is single-user. One account exists; there is no sharing, no profile switching, and no per-user data partition. Signing up creates that one account, and it is the only account there will ever be. | Inherited from the core (`BR-01` back-end). |
| **BR-25** | The recovery codes a new account receives are shown once, in place of the catalog, until the owner confirms having stored them. The app keeps none of them and offers no way back to a dismissed set. | They are the only way back into a library that sits on the owner's own disk, and the core keeps only their hashes — so the single moment they exist is the only moment to record them. |
| **BR-26** | Confirmation codes and password-reset tokens are held only for the moment they are submitted. They are never persisted, never logged, and never placed in a URL the app constructs. | They are bearer credentials; anything that stores one turns a transient secret into a durable one. |
| **BR-27** | The app never sends e-mail. It asks the core to send, and reports what the core says about the attempt. Delivery, templating, rate limiting, and token lifetime belong to the core. | The app has no mail transport and no business owning one; duplicating that logic would make two places able to disagree about whether a code is still valid. |
| **BR-28** | A password reset that completes invalidates the current session. The owner logs in again with the new password. | A reset is the response to a credential the owner no longer trusts; leaving the old session alive defeats it. |
| **BR-29** | A request to recover a password reports the same outcome whether or not the e-mail is registered. | The app must not become an oracle for which address owns the library. |

## Validation Constraints

The core validates the catalog. The app validates what it can *before* the call,
to give immediate feedback, and always surfaces the core's verdict as final.

| Field | Owner | Constraint |
| --- | --- | --- |
| **path** | Library | Required, chosen through the native folder picker. Whether it may be a library — a folder, present, inside the core's root, overlapping no other library — is the core's to judge. |
| **email** | Sign-up / login / credential change | Required. Valid e-mail format. |
| **password** | Sign-up / login / credential change | Required. Non-empty. Confirmed by a second entry when being set, changed, or reset. |
| **confirmationCode** | E-mail confirmation | Required. Non-empty after trimming. Validity, format, and expiry are the core's to judge. |
| **resetToken** | Password reset | Required. Non-empty after trimming. Validity and expiry are the core's to judge. |
| **name** | File rename | Required. Non-empty. Rejects the host OS's illegal file-name characters before the call. |
| **name** | Collection, Watchlist, ReadingList | Required. Non-empty after trimming. |
| **url** | Bookmark | Required. Must parse as a valid URL. |
| **title** | Bookmark | Required. Non-empty. |
| **content** | TextFile edit | May be empty. Saved only when it differs from what was loaded. |
| **theme** | AppSettings | One of `system`, `light`, `dark`. |
| **language** | AppSettings | One of `pt-BR`, `en`. |
| **layout** | AppSettings | One of `list`, `detailedList`, `grid`. |

## Permissions

| Role | Operations |
| --- | --- |
| **Owner (authenticated)** | Everything: browse, search, play, view, edit metadata and text content, rename, organize into collections, track watchlists and reading lists, soft-delete, restore, purge, purge-on-disk, manage library folders, run indexing, regenerate the recovery codes, and change credentials, theme, and language. |
| **Owner (authenticated, codes on screen)** | Only acknowledging the recovery codes, signing out, and the theme and language selection. No catalog operation is reachable. |
| **Owner (not yet authenticated)** | Only sign-up, login, recovering access with a recovery code, and the theme and language selection. No catalog operation is reachable. |

There is a single role in three states. No administrative or read-only role
exists.

## Lifecycle

**Account**

1. **Signed up** — no account exists in the core; the app collects an e-mail and
   password and creates it. The core mints ten single-use recovery codes.
2. **Showing codes** — the owner is signed in, but the library waits while the
   codes are on screen (**BR-25**).
3. **Open** — the owner confirms having stored them; the library opens.
4. **Credentials changed** — through preferences with an active session, or by
   spending a recovery code from the login screen.

**Session**

1. **Login** — credentials are verified by the core, which returns the session
   material the app holds in memory.
2. **Showing codes** — authenticated, but the new account's recovery codes are
   still on screen and only acknowledging them is reachable.
3. **Active** — every call carries the session. A call rejected as
   unauthorized returns the owner to the login screen with the reason shown.
4. **End** — the session dies with the app process, on an explicit sign-out, or
   when a password reset completes (**BR-28**).

**Confirmation code and reset token** — issued and delivered by the core, entered
by the owner, submitted once, and never retained by the app (**BR-26**). Their
expiry is the core's to enforce and the app's to explain.

**Library**

1. **Added** — the owner picks a folder and names it; the core records the
   library and starts its first scan.
2. **Indexed** — that scan is observed to completion.
3. **Re-scanned** — scanned again on demand, reporting what was added, updated,
   and found missing. A library can also be moved to the folder it moved to.
4. **Removed** — deleted from the catalog with its records; on-disk files are
   untouched. Refused while a scan of it is running.

**IndexRun** — started, observed while running, and settled as finished or
failed. A finished run's summary stays visible until dismissed; the core refuses a
second run of a library while one is running or paused, and the app shows that
refusal.

**File (as the app sees it)** — appears after an index run, is edited and
organized in place, is hidden when soft-deleted, reappears when restored, and
disappears when purged. Its on-disk file survives everything except an explicit
purge-on-disk.

**PlaybackState** — created when playback starts, updated as the position
advances, persisted as a resume point when playback stops, and cleared when the
file leaves the catalog.

**AppSettings** — created with defaults on first run, updated whenever the owner
changes a preference, and applied immediately without a restart.

## Prohibitions

- Bypassing the core to write catalog data, or reading the core's SQLite database
  directly.
- Persisting the session credential, any plaintext password, any confirmation
  code, or any reset token to disk.
- Sending e-mail from the app, or implementing its own token generation, expiry,
  or rate limiting instead of the core's.
- Revealing whether an e-mail address is registered, in a recovery flow or
  anywhere else.
- Reaching the catalog before a new account's recovery codes are acknowledged.
- Deleting or moving any file on disk except through the core's explicit
  purge-on-disk operation, confirmed by the owner.
- Re-encoding, transcoding, or otherwise rewriting video or image bytes.
- Caching file bytes across sessions, or serving stale content after the file
  changed on disk.
- Shipping a user-visible string that exists in only one of the two supported
  languages.
- Hard-coding a color, size, or font in a widget instead of taking it from the
  theme.
- Reimplementing a core validation rule as the front-end's own authority, or
  suppressing a core error the owner needs to see.
- Assuming collections are permanently flat, or a single library folder, in a way
  that a nested or multi-folder catalog would break.
- Auto-advancing work through workflow stage boundaries without human approval.
