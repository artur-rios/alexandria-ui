# Testing Specification Document — Alexandria Desktop

## 1. Purpose

This document defines **how a use case is tested once it has been implemented**.
It is a standard to be followed by any human or agent that builds tests for this
project, so that every use case in the
[Use Case Specification Document](Use%20Case%20Specification%20Document.md)
receives the same shape of testing, with the same tools, naming, and structure.

The rule is simple:

> **After a use case is developed, tests are built for it in the same change —
> before it is considered done.** A use case without its tests is incomplete.

The tools and versions used are defined in the
[Technology Stack Document](Technology%20Stack%20Document.md); when the tests run
in the delivery flow is defined in the
[Development Workflow Document](Development%20Workflow%20Document.md).

## 2. Testing philosophy

1. **Behavior-driven.** A test describes what the owner experiences — the item
   appears, the error is shown, the file is written — not how the code arranged
   it. Renaming a private method must never break a test.
2. **Test at the right layer.** Domain rules, mappers, validation, and the
   status-code-to-failure translation are unit-tested with no widget involved.
   Anything the owner sees — layout, state transitions, empty and error states,
   theming, localization — is widget-tested. Anything that must be true of the
   *real* Alexandria core is integration-tested against it.
3. **Isolation in unit and widget tests.** Every gateway is replaced by a fake
   bound through a provider override. No unit or widget test loads the native
   library, touches the real filesystem beyond a temporary directory, or reads
   the developer's settings.
4. **Realism in integration tests.** The real core, the real FFI boundary, and a
   real fixture library folder — over a throwaway database. What is faked in the
   lower suites is exactly what these tests exist to verify.
5. **Both themes and both languages are test surface, not review surface.** A
   screen that only reads correctly in one is a failing screen, and the tests are
   where that is caught.
6. **Same pattern every time.** The workflow in §8 is applied identically to every
   use case.

## 3. What to test for each use case

| Artifact produced | Test kind | Test location |
| --- | --- | --- |
| Domain model, mapper, or validator | Unit | `test/<feature>/domain/` |
| Failure mapping from a core status code | Unit | `test/core/failures/` |
| View model or state notifier | Unit | `test/<feature>/application/` |
| Gateway implementation over the generated bindings | Integration | `integration_test/<feature>/` |
| Screen, dialog, or component | Widget | `test/<feature>/presentation/` |
| Responsive behavior across breakpoints | Widget | `test/<feature>/presentation/` |
| Theme and layout appearance of a key screen | Widget (golden) | `test/<feature>/presentation/goldens/` |
| Localization completeness | Unit | `test/l10n/` |
| A whole use case end to end | Integration | `integration_test/<feature>/` |

**What deliberately gets no tests.** Generated files — the `ffigen` bindings, the
`freezed` and `json_serializable` output, and the localization delegates — are not
unit-tested; they are exercised through the code that uses them, and testing a
generator's output tests the generator. Plain data holders with no behavior get no
test of their own. Third-party packages are not tested; the gateway or viewer that
wraps one is.

Being explicit about these exclusions is what keeps the suite from filling with
tests that assert nothing.

## 4. Test project layout

The test tree mirrors the source tree feature for feature, so the test for a file
is always at the same relative path under `test/`, with `_test` appended.

```txt
lib/
├── core/                       cross-cutting: failures, theme, l10n, di
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── library_sources/
│   ├── catalog/
│   ├── editing/
│   ├── playback/
│   ├── viewers/
│   ├── organization/
│   ├── tracking/
│   ├── lifecycle/
│   └── shell/
└── main.dart

test/                           unit and widget tests, mirroring lib/
├── core/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   └── …
├── l10n/
└── support/                    fakes, builders, and pump helpers

integration_test/               whole flows against the real core
├── support/                    temporary database and fixture library setup
├── auth/
├── library_sources/
└── …
```

`lib/features/auth/domain/session.dart` is tested by
`test/features/auth/domain/session_test.dart`. No other mapping is used.

## 5. Naming & structure

Every test is named with the **Given-When-Then** pattern, as a single identifier:

```txt
GivenSomeCondition_WhenSomeAction_ThenSomeOutcome
```

```dart
test('GivenAMalformedEmail_WhenTheOwnerSubmitsLogin_ThenTheCoreIsNeverCalled', () {
  // Given — the preconditions, and only those that matter to this test
  final gateway = FakeAuthGateway();
  final sut = LoginViewModel(gateway);

  // When — exactly one action
  sut.submit(email: 'not-an-email', password: 'correct horse');

  // Then — the observable outcome
  expect(gateway.loginCallCount, 0);
  expect(sut.state.emailError, isNotNull);
});
```

The condition names the state that makes the test interesting, the action names
the single thing performed, and the outcome names what an observer would see. A
test whose name needs "And" twice in the outcome is asserting too much; split it.

Widget tests follow the same naming and the same three-part body:

```dart
testWidgets(
  'GivenAnEmptyCatalog_WhenTheListingIsOpened_ThenTheEmptyStateIsShownNotTheSpinner',
  (tester) async {
    await tester.pumpCatalog(files: const []);

    expect(find.byType(EmptyLibraryView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  },
);
```

## 6. Unit testing standard

### 6.1 Scope of a unit test

One unit test exercises **one class** through its public surface, with every
collaborator replaced. It must not build a widget, load the native library, reach
the real filesystem, or read the settings store. If a test needs any of those, it
belongs in §7 rather than being made to work here.

### 6.2 Test doubles

| Collaborator | Double |
| --- | --- |
| A gateway interface | A hand-written fake in `test/support/`, when the test needs realistic behavior across several calls. |
| A single call's return or failure | A `mocktail` stub. |
| The settings store | An in-memory implementation. |
| The clock | An injected fixed time. Never `DateTime.now()` in a test. |
| The Alexandria core | Never doubled at this layer — it is not reached at all. |

`mocktail` is the only mocking library in the project. A second one is not
introduced, and a fake is preferred wherever the interaction spans more than one
call, because a fake that misbehaves fails loudly while a mis-stubbed mock passes
quietly.

### 6.3 Coverage per unit

For each production unit, walk this checklist:

- [ ] The happy path.
- [ ] Each validation failure the unit can produce, asserted individually.
- [ ] Each not-found condition.
- [ ] Each unauthorized condition, including that it clears the session.
- [ ] Each boundary: empty collection, single item, the maximum the unit accepts,
      and one past it.
- [ ] Each failure the Alexandria core can return that this unit maps, asserted as
      the typed failure it becomes.
- [ ] That no call is made when local validation already rejected the input.

## 7. Widget and integration testing standard

### 7.1 Widget tests

A widget test builds one screen, dialog, or component with its providers
overridden to fakes, and asserts what is on screen. Each screen is covered for:

- [ ] The loaded state with content.
- [ ] The loading state.
- [ ] The empty state, asserted to be distinct from loading and from error.
- [ ] The error state, asserted to show a readable message and a retry — never a
      raw status code.
- [ ] Every alternative flow of its use case that has a visible outcome.
- [ ] Each breakpoint, including the minimum supported window size, asserting that
      no control is clipped or unreachable.
- [ ] Both themes.
- [ ] Both languages, asserting that no key renders as its identifier.
- [ ] Keyboard reachability of the screen's primary action.
- [ ] For a destructive action: that the confirmation appears, that cancelling
      changes nothing, and that the confirmation names what will be removed and
      whether the on-disk file is affected.

Golden files are used for the key screens in both themes. They are regenerated
deliberately and reviewed in the pull request like any other change — a golden
updated without being looked at is worse than no golden.

### 7.2 Integration tests

One integration test drives a whole use case through the real Alexandria core over
FFI, entering through the same screens the owner uses.

### 7.3 External dependencies

| Dependency | How it is provided |
| --- | --- |
| The Alexandria core | The real shared library, loaded exactly as the application loads it. Never faked — verifying this boundary is the point of the suite. |
| The catalog database | A temporary SQLite file created per test run and deleted afterwards. |
| The library folder | A fixture directory of small sample files created per test run, never a real library. |
| Credentials | Set through the core's own set-credentials call at the start of the run. |
| The settings store | Pointed at a temporary directory, so no test can read or write the developer's own settings. |

A test that would touch a real library folder, the real application-support
directory, or the developer's catalog is a defect in the test, not a
configuration to work around.

### 7.4 Coverage per use case

For each use case, the integration suite asserts:

- [ ] The main flow, end to end, through the screens.
- [ ] Every `AF-xx` that is reachable with the real core.
- [ ] Both the visible outcome **and** the resulting state in the catalog — a
      rename is verified by re-reading the record *and* by the file's name on
      disk.
- [ ] That nothing outside the operation's scope changed: a soft delete leaves the
      file on disk, a collection deletion leaves its members, a watchlist deletion
      leaves its videos.
- [ ] That every string returned across the FFI boundary was freed.

## 8. Per-use-case workflow

Apply this every time:

1. Re-read the use case's flows and its `FR-xx` requirements.
2. List the units the implementation produced and place each in the table in §3.
3. Write the unit tests: happy path first, then the §6.3 checklist for each unit.
4. Write the widget tests: the §7.1 checklist for each screen the use case added
   or changed.
5. Write the integration test: the main flow, then each reachable `AF-xx`.
6. Run the full suite.
7. Fix failures — in the implementation or the tests — and re-run until green.
8. Confirm every alternative flow in the specification has a test that would fail
   if the flow regressed. A flow with no such test is not covered, whatever the
   coverage percentage says.

## 9. Running the suites

```bash
flutter test
```

| Suite | Command |
| --- | --- |
| Unit and widget (the default suite) | `flutter test` |
| One feature's tests | `flutter test test/features/auth` |
| With coverage | `flutter test --coverage` |
| Regenerate golden files | `flutter test --update-goldens` |
| Integration, on Windows | `flutter test integration_test -d windows` |
| Integration, on Linux | `flutter test integration_test -d linux` |

The separation is structural rather than tag-based: `test/` holds everything that
runs without the native library, and `integration_test/` holds everything that
needs it and a desktop device. That split is what lets the fast suite run on every
change while the integration suite runs per platform in the build.
