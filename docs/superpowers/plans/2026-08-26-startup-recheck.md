# Startup Library Re-check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-check the library once when a session is established, unless the owner turned it off, the catalog is empty, or a run is already outstanding — reported by the activity strip that already exists.

**Architecture:** `SessionActivity` gains a `begin()` to mirror its `end()`, and `IndexSessionActivity` implements it by starting a refresh. `IndexRunsController.startRefresh` already refuses in all three cases; the only new refusal behaviour is that a re-check nobody asked for must not leave a refusal message on the Sources screen. A preference in the settings store gates the whole thing.

**Tech Stack:** Flutter 3.47.1, Riverpod, `freezed`, `gen_l10n`, `shared_preferences`.

## Global Constraints

- **Design document:** `docs/superpowers/specs/2026-08-26-startup-recheck-design.md`. It is the authority; this plan implements it.
- **Test naming:** every test is one identifier in Given-When-Then form — `GivenSomeCondition_WhenSomeAction_ThenSomeOutcome`. A test that cannot fail for the reason its name claims is a defect, not coverage.
- **Test location:** the test tree mirrors `lib/` exactly, with `_test` appended.
- **Localization:** every user-visible string comes from `AppLocalizations`, in BOTH `lib/core/l10n/app_en.arb` (with an `@key` description block — an undescribed message is a generation failure) and `lib/core/l10n/app_pt.arb` (without). Regenerate with `flutter gen-l10n`; generated files under `lib/core/l10n/generated/` are committed. `test/core/l10n/arb_parity_test.dart` fails on any key present in one catalog and absent from the other.
- **No colour literals** under `lib/` outside `lib/core/theme/` (BR-18).
- **Doc comments explain WHY** a choice was made and must be true of the code they sit on.
- **Verification:** run `flutter analyze` and `flutter test` and read the output. Never claim done on an unrun test.
- **Commits:** conventional commit subject in lowercase, ≤50 characters, imperative; body wrapped at 72. End every commit message with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

## What already exists, and must not be rebuilt

Read these before writing anything — three of the four rules this feature needs are already implemented.

`IndexRunsController.startRefresh` (`lib/features/library_sources/application/index_runs_controller.dart:203`) already:

- refuses when a refresh is running, recording `RefreshRefusal.alreadyRunning`;
- refuses when `countCatalogedFiles()` answers 0, recording `RefreshRefusal.catalogEmpty`, and deliberately does **not** treat a count it could not read as empty;
- returns silently when there is no credential;
- on success, records the run and calls `activeRunsControllerProvider.notifier.refresh()`, which is what makes the strip pick a run up that it could not otherwise discover.

`BackgroundActivityStrip` needs no change at all. A run started here is a run like any other.

So this feature is: a preference, a `begin()` hook, and one behavioural change to `startRefresh` — that a re-check nobody asked for does not leave a refusal message behind.

## The trap that will cost you an afternoon if you miss it

`SessionController.establish` (`lib/features/auth/application/session_controller.dart:38`) runs every activity's `end()` **before** it assigns `state = SessionState.active(...)`.

`startRefresh` reads `_session.credential` and returns silently when it is null. So a `begin()` called in the same place as `end()` would run before the session exists, read a null credential, and do nothing — silently, and in a way no unit test of `begin()` alone would catch.

`begin()` must be called **after** the session is recorded. Task 2 says so again where it matters.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/core/settings/settings_store.dart` + `shared_preferences_settings_store.dart` | Read and write the preference. |
| `test/support/in_memory_settings_store.dart`, `failing_settings_store.dart` | The same, for tests. |
| `lib/features/shell/application/preferences_state.dart` + `preferences_controller.dart` | Carry and set it. |
| `lib/features/shell/presentation/preferences_dialog.dart` | Offers it. |
| `lib/features/shell/domain/session_activity.dart` | Gains `begin()`. |
| `lib/features/catalog/…/catalog_session_activity.dart`, `editing/…`, `playback/…` | No-op `begin()`. |
| `lib/features/auth/application/session_controller.dart` | Runs `begin()` after the session is recorded. |
| `lib/features/library_sources/application/index_runs_controller.dart` | `startRefresh` learns whether to report its refusals. |
| `lib/features/library_sources/application/index_session_activity.dart` | `begin()` starts the re-check. |

---

### Task 1: The preference, end to end

**Files:**
- Modify: `lib/core/settings/settings_store.dart`, `lib/core/settings/shared_preferences_settings_store.dart`
- Modify: `test/support/in_memory_settings_store.dart`, `test/support/failing_settings_store.dart`
- Modify: `lib/features/shell/application/preferences_state.dart`, `preferences_controller.dart`
- Modify: `lib/features/shell/presentation/preferences_dialog.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Test: `test/features/shell/presentation/preferences_dialog_test.dart` (added group)

**Interfaces:**
- Produces:
  - `bool get SettingsStore.rechecksAtStartup` and `Future<void> setRechecksAtStartup(bool value)`.
  - `PreferencesState.rechecksAtStartup` (default `true`).
  - `PreferencesController.setRechecksAtStartup(bool value)`.
  - The localization keys `startupRecheckLabel` and `startupRecheckDescription`.

- [ ] **Step 1: Add the store's pair**

In `lib/core/settings/settings_store.dart`, beside `albumAnimationMode`:

```dart
  /// Whether the library is re-checked when a session is established, or
  /// `true` when the owner has not said (FR-LB-21).
  bool get rechecksAtStartup;

  /// Records [value] for the next launch.
  Future<void> setRechecksAtStartup(bool value);
```

In `lib/core/settings/shared_preferences_settings_store.dart`, following exactly how `_albumAnimationKey` is declared, read and written. The store's backing API is string-keyed, so the value is stored as one:

```dart
  static const _rechecksAtStartupKey = 'settings.rechecksAtStartup';

  /// Absent reads as on, which is the default the preference ships with: an
  /// owner who has never opened the dialog gets the re-check.
  @override
  bool get rechecksAtStartup =>
      _preferences.getString(_rechecksAtStartupKey) != 'false';

  @override
  Future<void> setRechecksAtStartup(bool value) =>
      _preferences.setString(_rechecksAtStartupKey, value.toString());
```

Then fix every other `SettingsStore` implementation the analyzer names. `test/support/failing_settings_store.dart` exists so UC-39 AF-02 stays testable — its new setter must **fail** the way its existing ones do, not succeed quietly.

- [ ] **Step 2: Carry it in preferences**

In `lib/features/shell/application/preferences_state.dart`, add to the `@freezed` factory:

```dart
    @Default(true) bool rechecksAtStartup,
```

Run: `dart run build_runner build --delete-conflicting-outputs`

In `preferences_controller.dart`, read it in `build` beside the others:

```dart
      rechecksAtStartup: settings?.rechecksAtStartup ?? true,
```

and add the setter, following `setAlbumAnimation` exactly:

```dart
  /// Applies [value] now and records it for the next launch (FR-LB-21).
  Future<void> setRechecksAtStartup(bool value) async {
    state = state.copyWith(rechecksAtStartup: value, lastChangeUnsaved: false);
    await _persist((settings) => settings.setRechecksAtStartup(value));
  }
```

- [ ] **Step 3: Add the strings**

`lib/core/l10n/app_en.arb`:

```json
  "startupRecheckLabel": "Re-check the library at startup",
  "@startupRecheckLabel": {
    "description": "Preference controlling whether the catalog is re-checked against the disk each time a session is established."
  },
  "startupRecheckDescription": "Looks for files added, changed, or removed while Alexandria was closed.",
  "@startupRecheckDescription": {
    "description": "Explains what the startup re-check preference does, beneath its label in the preferences dialog."
  },
```

`lib/core/l10n/app_pt.arb`:

```json
  "startupRecheckLabel": "Verificar a biblioteca ao iniciar",
  "startupRecheckDescription": "Procura arquivos adicionados, alterados ou removidos enquanto o Alexandria esteve fechado.",
```

Run: `flutter gen-l10n`

- [ ] **Step 4: Offer it in the dialog**

Add a group to `preferences_dialog.dart` built the way the theme, language and album-animation groups already are — read the file and follow its `_GroupLabel` and control pattern rather than introducing a fourth style. This one is a boolean, so a `SwitchListTile` is the natural control; use `startupRecheckDescription` as its subtitle.

- [ ] **Step 5: Write the failing tests**

Add to `test/features/shell/presentation/preferences_dialog_test.dart`, using its existing helpers:

```dart
  group('the startup re-check (FR-LB-21)', () {
    testWidgets(
      'GivenPreferences_WhenTheyOpen_ThenTheStartupRecheckIsOfferedAndOn',
      (tester) async {
        // On by default: a library that has fallen behind is the normal state
        // after the application has been closed for a while.
        await openFromShell(tester);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );

        expect(find.text(l10n.startupRecheckLabel), findsOneWidget);
        expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue,
        );
      },
    );

    testWidgets(
      'GivenPreferences_WhenTheRecheckIsTurnedOff_ThenItIsAppliedAndStored',
      (tester) async {
        final store = InMemorySettingsStore();
        await openFromShell(tester, settings: store);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(PreferencesDialog)),
        );

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(
          container.read(preferencesControllerProvider).rechecksAtStartup,
          isFalse,
        );
        expect(store.rechecksAtStartup, isFalse);
      },
    );

    testWidgets(
      'GivenTheStoreRefusesAWrite_WhenTheRecheckIsTurnedOff_ThenTheOwnerIsTold',
      (tester) async {
        // UC-39 AF-02: the choice applies for the session either way; what
        // the owner must not get is the silent belief that it was remembered.
        await tester.pumpShellWithFailingSettings();
        await tester.openSettingsMenuEntry(
          AppLocalizations.of(
            tester.element(find.byType(ShellScreen)),
          ).preferencesLabel,
        );

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(PreferencesDialog)),
        );
        expect(find.text(l10n.preferencesUnsaved), findsOneWidget);
      },
    );
  });
```

`openFromShell`'s signature may not take a `settings` argument yet — the album-animation group's tests added one. Read the file and use what is there; if it is missing, add it the way that group did.

If the dialog has more than one `SwitchListTile` by the time you write this, scope the finders to this group rather than taking the only one.

- [ ] **Step 6: Run the tests, the suite, and analyze**

Run: `flutter test test/features/shell test/core/settings && flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: add the startup re-check preference"
```

---

### Task 2: The `begin()` hook

**Files:**
- Modify: `lib/features/shell/domain/session_activity.dart`
- Modify: `lib/features/catalog/application/catalog_session_activity.dart`, `lib/features/editing/application/editing_session_activity.dart`, `lib/features/playback/application/playback_session_activity.dart`, `lib/features/library_sources/application/index_session_activity.dart`
- Modify: `lib/features/auth/application/session_controller.dart`
- Test: `test/features/auth/application/session_controller_test.dart` (or wherever `establish` is currently tested — find it)

**Interfaces:**
- Produces: `Future<void> SessionActivity.begin()` — called once per established session, after the session is recorded.

- [ ] **Step 1: Write the failing test**

Find where `establish` is tested and add, in that file's style:

```dart
  test(
    'GivenActivities_WhenASessionIsEstablished_ThenEachIsBegunAfterItIsRecorded',
    () {
      // After, not before: an activity that reads the credential — as the
      // library re-check does — would find none if it ran alongside the
      // winding-down of the session that just ended.
      final activity = RecordingSessionActivity();
      final container = testContainer(
        extraOverrides: [
          sessionActivitiesProvider.overrideWithValue([activity]),
        ],
      );

      container
          .read(sessionControllerProvider.notifier)
          .establish(aSession());

      expect(activity.begunWithSessionActive, isTrue);
    },
  );
```

`RecordingSessionActivity` is a fake you write in the test's support: its `begin()` records whether `sessionControllerProvider`'s state was already active when it was called. That is the assertion that matters — a test that only counts calls would pass against the ordering bug this exists to prevent.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/features/auth/application/session_controller_test.dart`
Expected: FAIL — `begin()` does not exist.

- [ ] **Step 3: Add it to the interface**

In `lib/features/shell/domain/session_activity.dart`, beside `end()`:

```dart
  /// Starts whatever this activity does for the length of a session.
  ///
  /// Called after the session is recorded, so anything that needs the
  /// credential has it — which is the difference between this and [end],
  /// whose whole purpose is to run while the *previous* session's state is
  /// still there to drop.
  ///
  /// Most activities have nothing to start. Indexing does: a library that
  /// changed while the application was closed is re-checked here (FR-LB-21).
  Future<void> begin();
```

- [ ] **Step 4: Implement it as a no-op everywhere but indexing**

In `catalog_session_activity.dart`, `editing_session_activity.dart` and `playback_session_activity.dart`:

```dart
  /// Nothing to start: this activity only has state to drop, not work to do.
  @override
  Future<void> begin() async {}
```

In `index_session_activity.dart`, the same for now — Task 3 fills it in. Say so in a comment rather than leaving it bare.

- [ ] **Step 5: Call it, after the session is recorded**

In `session_controller.dart`'s `establish`, after `state = SessionState.active(...)`:

```dart
    // After the state assignment, not with the `end()` calls above: an
    // activity that begins by reading the credential — the library re-check
    // does — would find none if it ran before the session was recorded.
    for (final activity in ref.read(sessionActivitiesProvider)) {
      unawaited(activity.begin());
    }
```

Unawaited for the same reason the `end()` loop is: `establish` is what the login screen calls on its way to the shell, and nothing here may block that.

- [ ] **Step 6: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: give a session activity a beginning"
```

---

### Task 3: The re-check itself

**Files:**
- Modify: `lib/features/library_sources/application/index_runs_controller.dart`
- Modify: `lib/features/library_sources/application/index_session_activity.dart`
- Test: `test/features/library_sources/application/index_session_activity_test.dart` (create), and the existing `index_runs_controller` tests

**Interfaces:**
- Consumes: `PreferencesState.rechecksAtStartup`, `SessionActivity.begin()`.
- Produces: `IndexRunsController.startRefresh({bool reportRefusals = true})` — when false, a refusal is not recorded in state.

- [ ] **Step 1: Write the failing tests**

Create `test/features/library_sources/application/index_session_activity_test.dart`. Four tests, one per rule, because four separate reasons deserve four separate failures:

```dart
  test(
    'GivenTheRecheckIsOn_WhenTheSessionBegins_ThenTheLibraryIsRechecked',
    () async {},
  );

  test(
    'GivenTheRecheckIsOff_WhenTheSessionBegins_ThenNothingIsStarted',
    () async {},
  );

  test(
    'GivenAnEmptyCatalog_WhenTheSessionBegins_ThenNothingIsStarted',
    () async {},
  );

  test(
    'GivenARunAlreadyInFlight_WhenTheSessionBegins_ThenItIsNotDisturbed',
    () async {},
  );
```

Fill each body in as you implement. Read `test/features/library_sources/application/` first and reuse its fake gateway and container helpers rather than writing a second set. Every body must assert on what the fake gateway was asked — a test that only checks state would pass against a re-check that never called the core.

Then add, in the index-runs controller's own test file:

```dart
  test(
    'GivenARefusalIsNotReported_WhenARefreshIsRefused_ThenNoMessageIsLeft',
    () async {
      // A re-check nobody asked for must not leave an explanation on the
      // Sources screen for a question the owner never asked. The refusal
      // still stops the run; it simply is not announced.
    },
  );
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/features/library_sources`
Expected: FAIL — the activity file has no behaviour and `startRefresh` takes no argument.

- [ ] **Step 3: Let `startRefresh` keep quiet**

In `index_runs_controller.dart`, give `startRefresh` the parameter and honour it at both refusal sites:

```dart
  /// Starts a catalog-wide re-check (UC-07 main flow, FR-LB-06).
  ///
  /// [reportRefusals] is false when nobody pressed anything — the startup
  /// re-check (FR-LB-21). A refusal explains to an owner why the button they
  /// pressed did nothing; left on screen after a re-check they never asked
  /// for, it is an answer to a question nobody asked.
  Future<void> startRefresh({bool reportRefusals = true}) async {
    if (state.isRefreshing) {
      if (reportRefusals) {
        state = state.copyWith(refreshRefusal: RefreshRefusal.alreadyRunning);
      }
      return;
    }
```

and the same shape at the `cataloged == 0` branch — the refusal is recorded only when `reportRefusals`, while `refreshStarting` is cleared either way.

Do not change anything else about the method: the credential check, the count-before-call ordering, the unauthorized branch and the `activeRunsControllerProvider.refresh()` call all stay exactly as they are.

- [ ] **Step 4: Implement `begin()`**

In `index_session_activity.dart`:

```dart
  /// Re-checks the library, once, when a session is established (FR-LB-21).
  ///
  /// The three cases where it does nothing — a run already outstanding, an
  /// empty catalog, no credential — are already `startRefresh`'s own rules,
  /// so they are not restated here: one place decides when a refresh may
  /// start, and a second copy of that decision would be one to keep in step.
  /// What this adds is that none of them is announced, because nobody asked.
  @override
  Future<void> begin() async {
    if (!_ref.read(preferencesControllerProvider).rechecksAtStartup) return;

    await _ref
        .read(indexRunsControllerProvider.notifier)
        .startRefresh(reportRefusals: false);
  }
```

- [ ] **Step 5: Run the tests, the suite, and analyze**

Run: `flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 6: Commit**

```bash
git add lib test
git commit -m "feat: re-check the library when a session begins"
```

---

### Task 4: The owner's symptom, and the requirements

**Files:**
- Test: `test/features/shell/presentation/` — a widget test at shell level
- Modify: `docs/requirements/System Requirements Document.md`

- [ ] **Step 1: Write the end-to-end test**

The tests so far prove the rules. This one proves the point: sign in, and a library that has fallen behind shows its changes without anybody pressing anything.

Put it where the shell's own tests live, and write it as the owner's experience:

```dart
  testWidgets(
    'GivenACatalogThatFellBehind_WhenTheOwnerSignsIn_ThenTheStripShowsARecheck',
    (tester) async {
      // The whole feature, from the outside: nobody presses Re-check, and
      // the strip reports one anyway.
      await tester.pumpShell();

      expect(find.byType(BackgroundActivityStrip), findsOneWidget);
      // Assert on what the strip is showing for the run, not merely that the
      // widget exists — it is in the tree at all times and takes no height
      // when nothing is running.
    },
  );
```

Finish that assertion against what the strip actually renders for a running refresh — read `background_activity_strip.dart` and assert on its progress row, not on the widget's presence.

- [ ] **Step 2: Run it, then the suite**

Run: `flutter test test/features/shell && flutter test && flutter analyze`
Expected: PASS and "No issues found!".

- [ ] **Step 3: Amend FR-LB-06**

It reads: *"The system shall start a refresh run covering everything already cataloged, independently of any single folder."* Add that a refresh also starts when a session is established, subject to FR-LB-21, in the register of the requirements around it.

- [ ] **Step 4: Add FR-LB-21**

```md
| FR-LB-21 | The system shall re-check the catalog when a session is established, unless the owner has turned that off, the catalog holds no files, or a run is already outstanding; and shall report such a re-check through the background activity indicator (FR-LB-15) without announcing a refusal the owner did not ask for. |
```

Then add it to every traceability table that lists FR-LB-20, the way FR-LB-19 and FR-LB-20 appear in them. Search the whole document for all of them.

- [ ] **Step 5: Commit**

```bash
git add test docs
git commit -m "docs: specify the startup library re-check"
```

- [ ] **Step 6: Run the application and watch it**

Run: `flutter run -d windows`

Sign in with a library already indexed, and watch the strip: a re-check should start on its own, show its progress, and clear itself. Add a file to a library folder, close the application, open it again, and check the file is there without pressing anything. Then turn the preference off and confirm signing in starts nothing.

This is the step the plan is for. A feature that passes every test and does not do this on a real window is a finding to report, not a task to tick.

---

## Self-Review

**Spec coverage**

| Spec section | Task |
| --- | --- |
| §1 When it runs — `begin()`, in indexing, not in the session controller | 2, 3 |
| §2 The three silences | 3 (all three are `startRefresh`'s existing rules) |
| §2 Each silence is silent | 3 (`reportRefusals`) |
| §2 Signing out and in starts another | 2 (falls out of the hook being per-session; no code) |
| §3 The preference | 1 |
| §4 The indication — nothing new built | 4 asserts it; no production change |
| Requirements impact | 4 |
| Testing | 1–4, with the manual watch in 4 |

**Placeholders:** Task 3's four activity tests and Task 4's strip assertion are named and reasoned but left for the implementer to fill against the fakes and the strip's real output. Each step says so explicitly and says what the assertion must be about. Everything else carries its code.

**Type consistency:** `rechecksAtStartup` is the name in the store, the state and the controller (Task 1) and is what Task 3 reads. `startRefresh({bool reportRefusals = true})` is defined in Task 3 step 3 and called in step 4. `SessionActivity.begin()` is defined in Task 2 step 3 and implemented in Task 2 step 4 and Task 3 step 4.

**One thing the spec did not settle, decided here:** the spec says each silence is silent, but `startRefresh` records refusals in state for the Sources screen to render. `reportRefusals` is how those two facts are reconciled; the alternative — checking the conditions in `begin()` before calling — would duplicate the rules and race with the state they read.
