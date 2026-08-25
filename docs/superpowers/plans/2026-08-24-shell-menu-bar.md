# Shell Menu Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the library tools, the settings actions, and the catalog search out of the navigation rail and the content area into a menu bar across the top of the shell.

**Architecture:** A new `ShellMenuBar` becomes the first child of `ShellScreen`'s column, holding a Material `MenuBar` with two submenus (Library, Settings) on the left and the existing `CatalogSearchField` on the right. The navigation rail loses its trailing area and becomes destinations only. No application or domain code changes: every action already has a controller, and this moves what invokes them.

**Tech Stack:** Flutter 3.47.1, Material 3 (`MenuBar`, `SubmenuButton`, `MenuItemButton`), Riverpod, `flutter_localizations` with `gen_l10n`.

## Global Constraints

- **Design document:** `docs/superpowers/specs/2026-08-24-shell-menu-bar-design.md`. It is the authority; this plan implements it.
- **Test naming:** every test is one identifier in Given-When-Then form — `GivenSomeCondition_WhenSomeAction_ThenSomeOutcome` (Testing Specification §5).
- **Test location:** the test tree mirrors `lib/` exactly, with `_test` appended (Testing Specification §4).
- **Localization:** every user-visible string comes from `AppLocalizations`. A new string goes into **both** `lib/core/l10n/app_en.arb` (with an `@key` description block — `required-resource-attributes: true` makes an undescribed message a generation failure) and `lib/core/l10n/app_pt.arb` (no description blocks). `test/core/l10n/arb_parity_test.dart` fails on any key present in one catalog and absent from the other.
- **Regenerating localizations:** `flutter gen-l10n`. Generated files under `lib/core/l10n/generated/` are committed.
- **Breakpoints:** `Breakpoint.compact` below 1280 logical pixels, `medium` from 1280, `expanded` from 1600. `Breakpoint.minimumWindowSize` is 1024 × 640.
- **FR-UX-02:** a control may collapse across breakpoints; it may never be clipped or hidden.
- **Verification before any completion claim:** run `flutter analyze` and `flutter test` and read the output. Never claim a task is done on an unrun test.
- **Commits:** conventional commit subject in lowercase, ≤50 characters, imperative; body wrapped at 72. End every commit message with `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `lib/features/shell/presentation/shell_menu_bar.dart` | **New.** The bar: the `MenuBar`, the two submenus' placement, the search field's placement, and the compact-tier collapse. |
| `lib/features/shell/presentation/library_menu.dart` | **New** (replaces `library_tools_button.dart`). The Library submenu and its six entries. |
| `lib/features/shell/presentation/settings_menu.dart` | **New.** The Settings submenu: preferences, change credentials, sign out. |
| `lib/features/shell/presentation/menu_entry.dart` | **New.** The shared `MenuEntry` item and `MenuGroupHeading`, used by both submenus. |
| `lib/features/shell/presentation/shell_screen.dart` | Modified. Adds the bar; drops the search field from the content area. |
| `lib/features/shell/presentation/shell_navigation_panel.dart` | Modified. Loses its `trailing` area. |
| `lib/features/shell/presentation/preferences_dialog.dart` | Modified. Loses the account section; keeps theme, language, and `PreferencesButton`. |
| `lib/features/shell/presentation/rail_action.dart` | **Deleted.** Its only two callers are the trailing actions this plan removes. |
| `lib/features/shell/presentation/library_tools_button.dart` | **Deleted.** Becomes `library_menu.dart`. |
| `lib/features/auth/presentation/sign_out_button.dart` | Modified. The confirm-then-sign-out flow becomes a function a menu item can call. |
| `lib/features/auth/presentation/change_credentials_dialog.dart` | Modified. Gains the recovery-codes section. |
| `test/support/shell_harness.dart` | Modified. `openLibraryTool` goes through the bar; `openSettingsMenu` is added. |

---

### Task 1: The menu bar, with the Library menu

**Files:**
- Create: `lib/features/shell/presentation/menu_entry.dart`
- Create: `lib/features/shell/presentation/library_menu.dart`
- Create: `lib/features/shell/presentation/shell_menu_bar.dart`
- Delete: `lib/features/shell/presentation/library_tools_button.dart`
- Modify: `lib/features/shell/presentation/shell_screen.dart`
- Modify: `lib/features/shell/presentation/shell_navigation_panel.dart` (remove `LibraryToolsButton` from `trailing`, keep the preferences action)
- Modify: `test/support/shell_harness.dart`
- Modify: `test/features/shell/presentation/shell_screen_test.dart` (its `openTools` helper)
- Test: `test/features/shell/presentation/shell_menu_bar_test.dart`

**Interfaces:**
- Consumes: `AppLocalizations`, `Breakpoint.from(BuildContext)`, `AppSpacing`, the six library screens' `show(BuildContext)` statics.
- Produces:
  - `class ShellMenuBar extends ConsumerWidget` — `const ShellMenuBar({super.key})`.
  - `class LibraryMenu extends StatelessWidget` — `const LibraryMenu({required bool showsLabel, super.key})`.
  - `class MenuEntry extends StatelessWidget` — `const MenuEntry({required IconData icon, required String label, required VoidCallback onSelected, super.key})`.
  - `class MenuGroupHeading extends StatelessWidget` — `const MenuGroupHeading(String text, {super.key})`.

- [ ] **Step 1: Write the failing test**

Create `test/features/shell/presentation/shell_menu_bar_test.dart`:

```dart
import 'package:alexandria_ui/core/l10n/generated/app_localizations.dart';
import 'package:alexandria_ui/core/theme/breakpoints.dart';
import 'package:alexandria_ui/features/lifecycle/presentation/missing_files_screen.dart';
import 'package:alexandria_ui/features/shell/presentation/library_menu.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_menu_bar.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_navigation_panel.dart';
import 'package:alexandria_ui/features/shell/presentation/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/shell_harness.dart';

/// The shell's menu bar (UC-37 main flow step 1, UC-39, FR-UX-01, FR-UX-02).
void main() {
  AppLocalizations localizations(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(ShellScreen)));

  /// Opens the Library menu.
  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.byType(LibraryMenu));
    await tester.pumpAndSettle();
  }

  group('placement (FR-UX-01)', () {
    testWidgets(
      'GivenASignedInOwner_WhenTheShellOpens_ThenTheMenuBarIsShown',
      (tester) async {
        await tester.pumpShell();

        expect(find.byType(ShellMenuBar), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShell_WhenTheMenuBarIsShown_ThenTheRailCarriesNoLibraryMenu',
      (tester) async {
        // The rail is destinations and nothing else: a second entry point
        // would be two controls claiming to be one.
        await tester.pumpShell();

        expect(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byType(LibraryMenu),
          ),
          findsNothing,
        );
      },
    );
  });

  group('the library menu (UC-37 main flow step 1)', () {
    testWidgets(
      'GivenTheMenuBar_WhenTheLibraryMenuIsOpened_ThenEveryLibraryWideAreaIsOffered',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await openLibrary(tester);

        for (final label in [
          l10n.librarySourcesOpen,
          l10n.collectionsOpen,
          l10n.watchlistsOpen,
          l10n.readingListsOpen,
          l10n.deletedItemsOpen,
          l10n.missingFilesOpen,
        ]) {
          expect(find.text(label), findsOneWidget, reason: label);
        }
      },
    );

    testWidgets(
      'GivenTheLibraryMenu_WhenAnEntryIsChosen_ThenItsScreenOpens',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await openLibrary(tester);
        await tester.tap(find.text(l10n.missingFilesOpen));
        await tester.pumpAndSettle();

        expect(find.byType(MissingFilesScreen), findsOneWidget);
      },
    );
  });

  group('across the breakpoints (FR-UX-02)', () {
    testWidgets(
      'GivenACompactWindow_WhenTheMenuBarIsShown_ThenTheLibraryMenuIsIconOnly',
      (tester) async {
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);
        final l10n = localizations(tester);

        expect(
          find.descendant(
            of: find.byType(LibraryMenu),
            matching: find.text(l10n.libraryToolsLabel),
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.widgets_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'GivenACompactWindow_WhenTheLibraryMenuIsOpened_ThenEveryEntryIsStillReachable',
      (tester) async {
        // Collapsed, not clipped: the trigger loses its label and the menu
        // behind it loses nothing.
        await tester.pumpShell(surfaceSize: Breakpoint.minimumWindowSize);
        final l10n = localizations(tester);

        await openLibrary(tester);

        expect(find.text(l10n.missingFilesOpen), findsOneWidget);
      },
    );

    testWidgets(
      'GivenAMediumWindow_WhenTheMenuBarIsShown_ThenTheLibraryMenuIsLabelled',
      (tester) async {
        await tester.pumpShell(surfaceSize: const Size(1280, 800));
        final l10n = localizations(tester);

        expect(
          find.descendant(
            of: find.byType(LibraryMenu),
            matching: find.text(l10n.libraryToolsLabel),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/shell/presentation/shell_menu_bar_test.dart`
Expected: FAIL — `library_menu.dart` and `shell_menu_bar.dart` do not exist, so the file does not compile.

- [ ] **Step 3: Create the shared menu entry widgets**

Create `lib/features/shell/presentation/menu_entry.dart` — this is `_ToolItem` and `_GroupHeading` lifted out of `library_tools_button.dart` unchanged except for being public, because the Settings menu needs the same two:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// One entry in a menu-bar menu.
class MenuEntry extends StatelessWidget {
  /// Creates an entry.
  const MenuEntry({
    required this.icon,
    required this.label,
    required this.onSelected,
    super.key,
  });

  /// The glyph beside the label.
  final IconData icon;

  /// What the entry is called.
  final String label;

  /// What choosing it does.
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => MenuItemButton(
    leadingIcon: Icon(icon),
    onPressed: onSelected,
    child: Text(label),
  );
}

/// A heading over a group of entries.
///
/// Not a `MenuItemButton`: a heading names a group, it does not open one, and
/// giving it the same hoverable, focusable treatment as the entries below it
/// would invite a tap that does nothing.
class MenuGroupHeading extends StatelessWidget {
  /// Creates a heading.
  const MenuGroupHeading(this.text, {super.key});

  /// The group's name.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Create the Library menu**

Create `lib/features/shell/presentation/library_menu.dart`. The entries, their order, and the three headings are `library_tools_button.dart`'s, unchanged; what changes is that it is a `SubmenuButton` in a bar rather than a `MenuAnchor` on a rail:

```dart
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../lifecycle/presentation/deleted_items_screen.dart';
import '../../lifecycle/presentation/missing_files_screen.dart';
import '../../library_sources/presentation/library_sources_screen.dart';
import '../../organization/presentation/collections_screen.dart';
import '../../tracking/presentation/reading_lists_screen.dart';
import '../../tracking/presentation/watchlists_screen.dart';
import 'menu_entry.dart';

/// The library-wide areas, reached from the menu bar (UC-37 main flow step 1,
/// FR-UX-01).
///
/// Six screens that belong to no single file type — sources, collections,
/// watchlists, reading lists, deleted items, and the missing-files review —
/// and so are not destinations of their own (FR-CT-01). They were reached from
/// the bottom of the navigation rail, below a divider that was the only thing
/// saying they were not destinations; a menu bar says it by construction.
///
/// Three headings inside, because a menu holding six unrelated screens cannot
/// be read at a glance without them. The order beneath each runs from filling
/// the library to reviewing what has left it.
class LibraryMenu extends StatelessWidget {
  /// Creates the menu.
  const LibraryMenu({required this.showsLabel, super.key});

  /// Whether the trigger carries its label beside its icon.
  ///
  /// False at the compact tier, where the bar has room for the icon and the
  /// search field but not for both menu labels as well (FR-UX-02).
  final bool showsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SubmenuButton(
      leadingIcon: const Icon(Icons.widgets_outlined),
      // The tooltip is what carries the name when the label is gone: an icon
      // alone would be a menu whose contents cannot be guessed before it is
      // opened, which is the complaint the headings inside it answered.
      child: showsLabel
          ? Text(l10n.libraryToolsLabel)
          : Tooltip(
              message: l10n.libraryToolsLabel,
              child: const SizedBox.shrink(),
            ),
      menuChildren: [
        MenuGroupHeading(l10n.libraryToolsGroupLibrary),
        MenuEntry(
          icon: Icons.folder_outlined,
          label: l10n.librarySourcesOpen,
          onSelected: () => LibrarySourcesScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.collections_bookmark_outlined,
          label: l10n.collectionsOpen,
          onSelected: () => CollectionsScreen.show(context),
        ),
        MenuGroupHeading(l10n.libraryToolsGroupTracking),
        MenuEntry(
          icon: Icons.playlist_play,
          label: l10n.watchlistsOpen,
          onSelected: () => WatchlistsScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.library_books_outlined,
          label: l10n.readingListsOpen,
          onSelected: () => ReadingListsScreen.show(context),
        ),
        MenuGroupHeading(l10n.libraryToolsGroupReview),
        MenuEntry(
          icon: Icons.delete_outline,
          label: l10n.deletedItemsOpen,
          onSelected: () => DeletedItemsScreen.show(context),
        ),
        MenuEntry(
          icon: Icons.help_outline,
          label: l10n.missingFilesOpen,
          onSelected: () => MissingFilesScreen.show(context),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Create the menu bar**

Create `lib/features/shell/presentation/shell_menu_bar.dart`. The search field arrives in Task 5; the trailing space is deliberately empty until then:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import 'library_menu.dart';

/// The shell's menu bar (FR-UX-01, FR-UX-02).
///
/// The library-wide menus across the top, above the rail and the content area.
/// A frame element in the sense the playback bar is: it does not know which
/// destination is showing and holds no feature logic, which is what keeps it
/// from becoming the file every later use case has to edit.
class ShellMenuBar extends StatelessWidget {
  /// Creates the bar.
  const ShellMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showsLabels = Breakpoint.from(context) != Breakpoint.compact;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            MenuBar(
              // A `MenuBar` paints its own surface and elevation, which inside
              // a bar that already has one would be a raised strip drawn on a
              // raised strip.
              style: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                elevation: WidgetStatePropertyAll(0),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              children: [LibraryMenu(showsLabel: showsLabels)],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Put the bar in the shell**

In `lib/features/shell/presentation/shell_screen.dart`, import `shell_menu_bar.dart` and make the bar the first child of the `Scaffold`'s `Column`, above the `Expanded` row:

```dart
      body: Column(
        children: [
          // FR-UX-01: the library-wide menus, above everything the destination
          // owns.
          const ShellMenuBar(),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: Row(
```

- [ ] **Step 7: Take the library tools off the rail**

In `lib/features/shell/presentation/shell_navigation_panel.dart`, delete the `import 'library_tools_button.dart';` line and the `const LibraryToolsButton(),` child from the `trailing` column. The preferences `RailAction` stays for now — Task 2 removes it and the whole trailing area with it.

Then delete `lib/features/shell/presentation/library_tools_button.dart`.

- [ ] **Step 8: Update the shell harness**

In `test/support/shell_harness.dart`, replace the `library_tools_button.dart` import with `library_menu.dart`, drop the now-unused `shell_navigation_panel.dart` import, and rewrite `openLibraryTool` to go through the bar:

```dart
  /// Opens one of the library-wide screens (UC-37 main flow step 1).
  ///
  /// The Library menu is the one entry point every one of them has, so a test
  /// that needs collections, deleted items, or the missing-files review opens
  /// it the way the owner does rather than through whichever screen happens to
  /// link to it.
  Future<void> openLibraryTool(String label) async {
    await tap(find.byType(LibraryMenu));
    await pumpAndSettle();

    await tap(find.text(label).last);
    await pumpAndSettle();
  }
```

- [ ] **Step 9: Update the shell screen test's own helper**

In `test/features/shell/presentation/shell_screen_test.dart`, replace the `library_tools_button.dart` import with `library_menu.dart` and rewrite `openTools`:

```dart
    /// Opens the bar's Library menu.
    Future<AppLocalizations> openTools(WidgetTester tester) async {
      await tester.tap(find.byType(LibraryMenu));
      await tester.pumpAndSettle();

      return AppLocalizations.of(tester.element(find.byType(ShellScreen)));
    }
```

Leave the assertions alone: what they assert — that every library-wide area is offered — has not changed, only where it is offered from.

- [ ] **Step 10: Run the tests**

Run: `flutter test test/features/shell test/features/organization`
Expected: PASS, including the new `shell_menu_bar_test.dart`. `shell_screen_golden_test.dart` is expected to FAIL here — the shell grew a bar and the six images predate it. Task 6 regenerates them; note the failure and continue.

- [ ] **Step 11: Analyze**

Run: `flutter analyze`
Expected: "No issues found!" A lint about an unused import in `shell_navigation_panel.dart` or the harness means a step-7 or step-8 edit was missed.

- [ ] **Step 12: Commit**

```bash
git add lib/features/shell/presentation test/features/shell/presentation/shell_menu_bar_test.dart test/features/shell/presentation/shell_screen_test.dart test/support/shell_harness.dart
git commit -m "feat: put the library menu in a shell menu bar"
```

---

### Task 2: The Settings menu, and the rail's trailing area removed

**Files:**
- Create: `lib/features/shell/presentation/settings_menu.dart`
- Modify: `lib/features/shell/presentation/shell_menu_bar.dart`
- Modify: `lib/features/shell/presentation/shell_navigation_panel.dart`
- Delete: `lib/features/shell/presentation/rail_action.dart`
- Modify: `lib/core/l10n/app_en.arb`, `lib/core/l10n/app_pt.arb`
- Modify: `test/features/shell/presentation/preferences_dialog_test.dart`
- Modify: `test/features/shell/presentation/shell_navigation_panel_test.dart` (only if it asserts on the trailing actions)
- Test: `test/features/shell/presentation/shell_menu_bar_test.dart` (added group)

**Interfaces:**
- Consumes: `MenuEntry`, `MenuGroupHeading`, `PreferencesDialog.show(BuildContext)`.
- Produces: `class SettingsMenu extends StatelessWidget` — `const SettingsMenu({required bool showsLabel, super.key})`. Task 3 and Task 4 add entries to it.
- Produces the localization keys `settingsMenuLabel` and `settingsMenuOpen`.

- [ ] **Step 1: Write the failing test**

Append to `test/features/shell/presentation/shell_menu_bar_test.dart` (and add the imports it needs: `settings_menu.dart`, `preferences_dialog.dart`, `rail_action.dart` is *not* imported — it is being deleted):

```dart
  group('the settings menu (UC-39 main flow step 1)', () {
    testWidgets(
      'GivenTheMenuBar_WhenTheSettingsMenuIsOpened_ThenPreferencesAreOffered',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();

        expect(find.text(l10n.preferencesLabel), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheSettingsMenu_WhenPreferencesAreChosen_ThenTheDialogOpens',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.preferencesLabel));
        await tester.pumpAndSettle();

        expect(find.byType(PreferencesDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheShell_WhenTheRailIsShown_ThenItCarriesNoActionsBesideDestinations',
      (tester) async {
        // The rail is destinations and nothing else once the bar carries the
        // two actions that used to sit under it.
        await tester.pumpShell();

        expect(
          find.descendant(
            of: find.byType(ShellNavigationPanel),
            matching: find.byIcon(Icons.settings_outlined),
          ),
          findsNothing,
        );
      },
    );
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/shell/presentation/shell_menu_bar_test.dart`
Expected: FAIL — `settings_menu.dart` does not exist.

- [ ] **Step 3: Add the two localization keys**

In `lib/core/l10n/app_en.arb`, beside the other `preferences*` keys:

```json
  "settingsMenuLabel": "Settings",
  "@settingsMenuLabel": {
    "description": "The menu bar's settings menu, holding preferences and the account actions."
  },
  "settingsMenuOpen": "Open settings",
  "@settingsMenuOpen": {
    "description": "Tooltip on the settings menu where the bar is too narrow to show its label."
  },
```

In `lib/core/l10n/app_pt.arb`, beside the other `preferences*` keys:

```json
  "settingsMenuLabel": "Configurações",
  "settingsMenuOpen": "Abrir configurações",
```

Then run: `flutter gen-l10n`

- [ ] **Step 4: Create the Settings menu**

Create `lib/features/shell/presentation/settings_menu.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import 'menu_entry.dart';
import 'preferences_dialog.dart';

/// Preferences and the account actions (UC-39 main flow step 1, FR-UX-01).
///
/// Preferences were behind a button at the bottom of the navigation rail, and
/// the account actions were inside the dialog that button opened — so leaving
/// the application took three levels of nesting through a screen that does not
/// announce it holds the exit. A named menu is one level, and it is where a
/// desktop owner looks first.
class SettingsMenu extends StatelessWidget {
  /// Creates the menu.
  const SettingsMenu({required this.showsLabel, super.key});

  /// Whether the trigger carries its label beside its icon (FR-UX-02).
  final bool showsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SubmenuButton(
      leadingIcon: const Icon(Icons.settings_outlined),
      child: showsLabel
          ? Text(l10n.settingsMenuLabel)
          : Tooltip(
              message: l10n.settingsMenuOpen,
              child: const SizedBox.shrink(),
            ),
      menuChildren: [
        MenuEntry(
          icon: Icons.tune_outlined,
          label: l10n.preferencesLabel,
          onSelected: () => PreferencesDialog.show(context),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Put it in the bar**

In `lib/features/shell/presentation/shell_menu_bar.dart`, import `settings_menu.dart` and extend the `MenuBar`'s children:

```dart
              children: [
                LibraryMenu(showsLabel: showsLabels),
                SettingsMenu(showsLabel: showsLabels),
              ],
```

- [ ] **Step 6: Strip the rail's trailing area**

In `lib/features/shell/presentation/shell_navigation_panel.dart`, delete the whole `trailing:` argument to `NavigationRail` — the `Padding`, the `IntrinsicWidth`, the `Column`, the `Divider`, and the preferences `RailAction` — along with the long comment above it that explains a trailing area there is no longer one. Delete the now-unused imports: `rail_action.dart`, `preferences_dialog.dart`, and `app_spacing.dart` if nothing else in the file uses it.

Then delete `lib/features/shell/presentation/rail_action.dart`.

- [ ] **Step 7: Point the preferences dialog test at the menu**

In `test/features/shell/presentation/preferences_dialog_test.dart`, replace the `preferencesActionInShell` helper and the `openFromShell` that uses it:

```dart
  /// Opens preferences from the shell's Settings menu.
  Future<void> openFromShell(
    WidgetTester tester, {
    ThemeMode? themeMode,
  }) async {
    await tester.pumpShell(themeMode: themeMode ?? ThemeMode.light);
    await tester.openSettingsMenuEntry(
      AppLocalizations.of(tester.element(find.byType(ShellScreen)))
          .preferencesLabel,
    );
  }
```

and add the helper it calls to `test/support/shell_harness.dart`:

```dart
  /// Chooses [label] from the shell's Settings menu (UC-39 main flow step 1).
  Future<void> openSettingsMenuEntry(String label) async {
    await tap(find.byType(SettingsMenu));
    await pumpAndSettle();

    await tap(find.text(label).last);
    await pumpAndSettle();
  }
```

Remove `shell_navigation_panel.dart` from the test's imports if nothing else in the file uses it.

- [ ] **Step 8: Run the tests**

Run: `flutter test test/features/shell`
Expected: PASS except `shell_screen_golden_test.dart`, which Task 6 regenerates.

- [ ] **Step 9: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 10: Commit**

```bash
git add lib test/features/shell test/support
git commit -m "feat: add a settings menu to the shell menu bar"
```

---

### Task 3: Change credentials and recovery codes leave the preferences dialog

**Files:**
- Modify: `lib/features/shell/presentation/settings_menu.dart`
- Modify: `lib/features/shell/presentation/preferences_dialog.dart`
- Modify: `lib/features/auth/presentation/change_credentials_dialog.dart`
- Modify: `test/features/auth/presentation/change_credentials_dialog_test.dart`
- Modify: `test/features/auth/presentation/recovery_codes_regenerate_test.dart`
- Test: `test/features/shell/presentation/shell_menu_bar_test.dart` (added tests)

**Interfaces:**
- Consumes: `ChangeCredentialsDialog.show(BuildContext)`, `RecoveryCodesSection`, `MenuEntry`, `PumpShell.openSettingsMenuEntry(String)` from Task 2.
- Produces: nothing new. The Settings menu gains its second entry.

- [ ] **Step 1: Write the failing tests**

Add to the settings group in `test/features/shell/presentation/shell_menu_bar_test.dart`:

```dart
    testWidgets(
      'GivenTheSettingsMenu_WhenCredentialsAreChosen_ThenTheCredentialsDialogOpens',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.changeCredentialsOpen);

        expect(find.byType(ChangeCredentialsDialog), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheCredentialsDialog_WhenItIsOpen_ThenTheRecoveryCodesAreOffered',
      (tester) async {
        // UC-42 beside UC-04: both are things an owner does to an account they
        // still have access to, and neither is a preference.
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.changeCredentialsOpen);

        expect(find.byType(RecoveryCodesSection), findsOneWidget);
      },
    );

    testWidgets(
      'GivenPreferences_WhenTheyAreOpen_ThenNoAccountActionIsOffered',
      (tester) async {
        // The dialog is theme and language: an account action inside it is
        // what made signing out three levels deep.
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.preferencesLabel);

        expect(find.text(l10n.changeCredentialsOpen), findsNothing);
        expect(find.byType(RecoveryCodesSection), findsNothing);
      },
    );
```

Add the imports these need: `change_credentials_dialog.dart` and `recovery_codes_section.dart`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/shell/presentation/shell_menu_bar_test.dart`
Expected: FAIL — the Settings menu has one entry, and the recovery-codes section is still in the preferences dialog.

- [ ] **Step 3: Add the credentials entry to the Settings menu**

In `lib/features/shell/presentation/settings_menu.dart`, import `../../auth/presentation/change_credentials_dialog.dart` and add the second entry after preferences:

```dart
        MenuEntry(
          icon: Icons.key_outlined,
          label: l10n.changeCredentialsOpen,
          onSelected: () => ChangeCredentialsDialog.show(context),
        ),
```

- [ ] **Step 4: Move the recovery-codes section into the credentials dialog**

In `lib/features/auth/presentation/change_credentials_dialog.dart`, import `recovery_codes_section.dart` and add the section below the dialog's existing form content, separated by a divider:

```dart
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              // UC-42 beside UC-04: regenerating the recovery codes and
              // changing the password are both things an owner does to an
              // account they still have access to, and the preferences dialog
              // they used to share was neither of those things.
              const RecoveryCodesSection(),
```

Place it as the last child of the dialog's content column, before the `actions:`.

- [ ] **Step 5: Strip the preferences dialog**

In `lib/features/shell/presentation/preferences_dialog.dart`, delete from the `if (signedIn) ...[` block the `RecoveryCodesSection`, the `Align`-wrapped change-credentials `TextButton.icon`, and the two `SizedBox`/`Divider` spacers introducing them. Keep `const SignOutButton()` — Task 4 moves it. Delete the now-unused imports for `recovery_codes_section.dart` and `change_credentials_dialog.dart`.

- [ ] **Step 6: Point the two auth tests at their new entry points**

In `test/features/auth/presentation/change_credentials_dialog_test.dart` and `test/features/auth/presentation/recovery_codes_regenerate_test.dart`, each opens preferences via the rail and then taps through to its dialog. Replace that with the Settings menu:

```dart
    await tester.pumpShell();
    await tester.openSettingsMenuEntry(
      AppLocalizations.of(
        tester.element(find.byType(ShellScreen)),
      ).changeCredentialsOpen,
    );
```

Delete the `RailAction`/`shell_navigation_panel.dart` references and the comments about the rail's inline preferences action from both files. Every assertion after the navigation stays exactly as it is.

- [ ] **Step 7: Run the tests**

Run: `flutter test test/features/auth test/features/shell`
Expected: PASS except the goldens.

- [ ] **Step 8: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "feat: move the account actions out of preferences"
```

---

### Task 4: Sign out moves into the Settings menu

**Files:**
- Modify: `lib/features/auth/presentation/sign_out_button.dart`
- Modify: `lib/features/shell/presentation/settings_menu.dart`
- Modify: `lib/features/shell/presentation/preferences_dialog.dart`
- Modify: `test/features/auth/presentation/sign_out_test.dart`
- Test: `test/features/shell/presentation/shell_menu_bar_test.dart` (added tests)

**Interfaces:**
- Consumes: `signOutControllerProvider`, `ConfirmationDialog.show`.
- Produces: `Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref)` — top-level, in `sign_out_button.dart`. Warns when the session holds unsaved changes, signs out when confirmed, and returns without signing out when the owner cancels. `SignOutButton` keeps its name and calls it.

- [ ] **Step 1: Write the failing tests**

Add to the settings group in `test/features/shell/presentation/shell_menu_bar_test.dart`:

```dart
    testWidgets(
      'GivenTheSettingsMenu_WhenItIsOpened_ThenSigningOutIsOffered',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.tap(find.byType(SettingsMenu));
        await tester.pumpAndSettle();

        expect(find.text(l10n.signOut), findsOneWidget);
      },
    );

    testWidgets(
      'GivenTheSettingsMenu_WhenSigningOutIsChosen_ThenTheLoginScreenReturns',
      (tester) async {
        await tester.pumpShell();
        final l10n = localizations(tester);

        await tester.openSettingsMenuEntry(l10n.signOut);

        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
```

Add the `login_screen.dart` import.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/shell/presentation/shell_menu_bar_test.dart`
Expected: FAIL — the Settings menu offers no sign-out.

- [ ] **Step 3: Make the sign-out flow callable from a menu**

In `lib/features/auth/presentation/sign_out_button.dart`, lift `_signOut` out of the widget as a top-level function and drop its trailing `navigator.pop()`. That pop existed to close the preferences dialog the button sat in; the button no longer sits in one, and popping from a menu item would dismiss the shell's own route:

```dart
/// Warns, then signs out (UC-03 main flow steps 2 to 4, AF-01).
///
/// The warning goes through the application's one confirmation dialog
/// (FR-UX-10), which names what is about to be lost and defaults to
/// cancelling — cancelling is how the owner goes back and saves first, which
/// is the option AF-01 requires.
///
/// Nothing is popped afterwards. Signing out replaces the shell with the login
/// screen at the root, and a pop here would be dismissing a route that the
/// session change has already taken away.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final controller = ref.read(signOutControllerProvider);

  if (controller.holdsUnsavedChanges) {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: l10n.signOutUnsavedTitle,
      message: l10n.signOutUnsavedMessage,
      confirmLabel: l10n.signOutUnsavedConfirm,
    );
    if (!confirmed) return;
  }

  await controller.signOut();
}
```

Keep `SignOutButton` in the file, now calling `confirmAndSignOut(context, ref)`: `recovery_codes_screen.dart` and any screen reached without a shell still need a button rather than a menu entry.

- [ ] **Step 4: Add the entry to the Settings menu**

`settings_menu.dart` becomes a `ConsumerWidget` — the sign-out flow needs a `WidgetRef`. Change the class declaration to `class SettingsMenu extends ConsumerWidget`, the build signature to `Widget build(BuildContext context, WidgetRef ref)`, add the `flutter_riverpod` and `sign_out_button.dart` imports, and add the third entry after credentials:

```dart
        // Last, and after a divider: it is the one action here that ends what
        // the others operate on.
        const Divider(),
        MenuEntry(
          icon: Icons.logout_outlined,
          label: l10n.signOut,
          onSelected: () => unawaited(confirmAndSignOut(context, ref)),
        ),
```

Add `import 'dart:async';` for `unawaited`.

- [ ] **Step 5: Take sign-out out of the preferences dialog**

In `lib/features/shell/presentation/preferences_dialog.dart`, delete the whole `if (signedIn) ...[ ... ]` block — after Task 3 its only remaining child is `const SignOutButton()` — and the `signedIn` local and the `sign_out_button.dart` import if nothing else uses them.

- [ ] **Step 6: Point the sign-out test at the menu**

In `test/features/auth/presentation/sign_out_test.dart`, replace `openPreferences` with a helper that reaches the menu, and `pressSignOut` with one that chooses the entry:

```dart
  /// Signs in and opens the Settings menu, where sign-out lives.
  Future<ProviderContainer> openSettings(
    WidgetTester tester, {
    List<SessionActivity> activities = const [],
    Locale? locale,
    ThemeMode themeMode = ThemeMode.light,
    List<Override> extraOverrides = const [],
  }) async {
    final container = await tester.pumpShell(
      locale: locale,
      themeMode: themeMode,
      extraOverrides: <Override>[
        sessionActivitiesProvider.overrideWithValue(activities),
        ...extraOverrides,
      ],
    );

    await tester.tap(find.byType(SettingsMenu));
    await tester.pumpAndSettle();

    return container;
  }

  /// Chooses the sign-out entry.
  Future<void> pressSignOut(WidgetTester tester) async {
    final l10n = AppLocalizations.of(tester.element(find.byType(ShellScreen)));

    await tester.tap(find.text(l10n.signOut).last);
    await tester.pumpAndSettle();
  }
```

Replace every `openPreferences(` call with `openSettings(`, and swap the `preferences_dialog.dart`/`shell_navigation_panel.dart`/`sign_out_button.dart` imports for `settings_menu.dart`. Every assertion — the unsaved-changes confirmation, the activities that block, the notice on the login screen — stays as it is: that behaviour has not changed.

- [ ] **Step 7: Run the tests**

Run: `flutter test test/features/auth test/features/shell`
Expected: PASS except the goldens.

- [ ] **Step 8: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 9: Commit**

```bash
git add lib test
git commit -m "feat: offer sign out from the settings menu"
```

---

### Task 5: The search field moves into the bar

**Files:**
- Modify: `lib/features/shell/presentation/shell_menu_bar.dart`
- Modify: `lib/features/shell/presentation/shell_screen.dart`
- Test: `test/features/shell/presentation/shell_menu_bar_test.dart` (added group)
- Modify: `test/features/catalog/presentation/` search tests, only where they locate the field by its position rather than by type

**Interfaces:**
- Consumes: `CatalogSearchField`, `shellControllerProvider`, `ShellDestination`.
- Produces: nothing new. `ShellMenuBar` becomes a `ConsumerWidget` to read the destination.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/shell/presentation/shell_menu_bar_test.dart`:

```dart
  group('the search field (UC-11 main flow step 1)', () {
    testWidgets(
      'GivenTheShell_WhenAFileTypeIsShown_ThenTheSearchFieldIsInTheMenuBar',
      (tester) async {
        await tester.pumpShell();

        expect(
          find.descendant(
            of: find.byType(ShellMenuBar),
            matching: find.byType(CatalogSearchField),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'GivenTheShell_WhenBookmarksAreShown_ThenNoSearchFieldIsOffered',
      (tester) async {
        // FR-CT-06 matches files and metadata, and a bookmark is neither: the
        // field would answer a question the area cannot ask.
        final container = await tester.pumpShell();

        container
            .read(shellControllerProvider.notifier)
            .go(ShellDestination.bookmarks);
        await tester.pumpAndSettle();

        expect(find.byType(CatalogSearchField), findsNothing);
      },
    );

    testWidgets(
      'GivenTheMenuBarsField_WhenATermIsTyped_ThenTheResultsReplaceTheListing',
      (tester) async {
        await tester.pumpShell();

        await tester.enterText(find.byType(CatalogSearchField), 'anything');
        await tester.pumpAndSettle();

        expect(find.byType(CatalogSearchResults), findsOneWidget);
      },
    );
  });
```

Add the imports: `catalog_search_view.dart`, `shell_destination.dart`, `providers.dart`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/shell/presentation/shell_menu_bar_test.dart`
Expected: FAIL — the field is in the content area, so the first test finds no descendant of the bar.

- [ ] **Step 3: Put the field in the bar**

In `lib/features/shell/presentation/shell_menu_bar.dart`, make the widget a `ConsumerWidget`, read the destination, and add the field to the row after the `MenuBar`:

```dart
class ShellMenuBar extends ConsumerWidget {
  /// Creates the bar.
  const ShellMenuBar({super.key});

  /// The widest the search field is drawn where the bar has room to spare.
  ///
  /// A field that grew with the window would put a single-word search term in
  /// the middle of a thousand pixels of empty input.
  static const double _searchWidth = 360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final showsLabels = Breakpoint.from(context) != Breakpoint.compact;

    // UC-11 searches every type at once, which is why the field belongs to the
    // frame rather than to whichever listing is showing. Bookmarks are the one
    // area that holds no files, and so the one area with nothing to answer.
    final searchable =
        ref.watch(shellControllerProvider) != ShellDestination.bookmarks;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            MenuBar(
              style: const MenuStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                elevation: WidgetStatePropertyAll(0),
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              children: [
                LibraryMenu(showsLabel: showsLabels),
                SettingsMenu(showsLabel: showsLabels),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            if (searchable)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    // At the compact tier the field takes what the collapsed
                    // menus left rather than a fixed width, which is the
                    // width that is actually there.
                    constraints: const BoxConstraints(maxWidth: _searchWidth),
                    child: const CatalogSearchField(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Take the field out of the content area**

In `lib/features/shell/presentation/shell_screen.dart`, delete from `ShellContentArea` the `searchable` local, the `if (searchable) ...[ const CatalogSearchField(), const SizedBox(...) ]` block, and the `catalog_search_view.dart` import if `CatalogSearchResults` no longer needs it — it does, so keep the import and delete only the field. Leave the `searching` local and the `_ when searchable && searching => const CatalogSearchResults()` branch, rewriting the guard as:

```dart
            child: switch (destination) {
              _ when searching && destination != ShellDestination.bookmarks =>
                const CatalogSearchResults(),
```

- [ ] **Step 5: Run the tests**

Run: `flutter test test/features/shell test/features/catalog`
Expected: PASS except the goldens. A catalog test that fails because it expected the field under the heading is updated in place — find it by type rather than by position; do not add a second assertion for the old location.

- [ ] **Step 6: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 7: Commit**

```bash
git add lib test
git commit -m "feat: move catalog search into the menu bar"
```

---

### Task 6: Goldens, requirements, and the full suite

**Files:**
- Modify: `test/features/shell/presentation/shell_screen_golden_test.dart` (its header comment only)
- Modify: `test/features/shell/presentation/goldens/*.png` (all six, regenerated)
- Modify: `docs/requirements/System Requirements Document.md`
- Modify: `docs/requirements/Use Case Specification Document.md` (UC-38)

**Interfaces:**
- Consumes: everything the previous five tasks built.
- Produces: nothing new.

- [ ] **Step 1: Regenerate the goldens**

Run: `flutter test test/features/shell/presentation/shell_screen_golden_test.dart --update-goldens`

- [ ] **Step 2: Look at the images**

Open all six of `test/features/shell/presentation/goldens/*.png`. Each must show the menu bar across the top with the two menus at the left; the three wider images show their labels and the minimum-window pair shows icons only. The rail must show destinations with no divider and no actions beneath them. A golden that does not show this is a bug in Tasks 1 to 5, not a golden to accept — regenerating an image is how a real regression gets committed.

- [ ] **Step 3: Update the golden test's header comment**

The comment in `shell_screen_golden_test.dart` describes the panel as carrying "a library-tools button beside preferences". Replace that sentence:

```dart
/// The panel has since lost both actions beneath its destinations — the
/// library tools and preferences now sit in the menu bar across the top of
/// the shell, which these images show above the panel and the content area.
```

- [ ] **Step 4: Amend the requirements**

In `docs/requirements/System Requirements Document.md`, line 285 onward:

```md
| FR-UX-01 | The system shall present a single-window shell comprising the library menu bar, the type navigation panel, the content area, and the persistent playback bar. |
| FR-UX-02 | The system shall adapt the shell across the defined width breakpoints, collapsing the navigation panel and the menu bar rather than clipping or hiding any control. |
```

- [ ] **Step 5: Amend UC-38**

In `docs/requirements/Use Case Specification Document.md`, find UC-38 and add the menu bar wherever the use case enumerates the shell's regions, in the same words FR-UX-01 now uses. Change nothing else about the use case: no flow, no alternative flow, and no other use case is affected — every action the bar offers already belongs to a use case of its own.

- [ ] **Step 6: Run the whole suite**

Run: `flutter test`
Expected: PASS, every test, including the goldens.

- [ ] **Step 7: Analyze**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add test docs
git commit -m "docs: name the menu bar in the shell requirements"
```

- [ ] **Step 9: Run the application and look at it**

Run: `flutter run -d windows`

Check, at a normal window and then at one dragged down to the minimum: the bar is one row above the rail, the two menus open and every entry works, search sits at the right and disappears on bookmarks, and the rail carries destinations only. A layout that is correct in the tests and ugly on screen is a finding to report, not a task to tick.

---

## Self-Review

**Spec coverage**

| Spec section | Task |
| --- | --- |
| §1 A fourth shell region | 1 |
| §2 Library ▾ | 1 |
| §3 Settings ▾ — preferences | 2 |
| §3 Settings ▾ — change credentials, recovery codes | 3 |
| §3 Settings ▾ — sign out | 4 |
| §3 The preferences dialog slimmed | 3, 4 |
| §3 `PreferencesButton` unchanged for the auth screens | 2 (untouched by design), asserted by the existing preferences dialog test |
| §4 Search moves up | 5 |
| §5 Across the breakpoints | 1 (Library), 2 (Settings), 5 (field width) |
| Components table — rail trailing removed | 2 |
| Components table — `rail_action.dart` deleted | 2 |
| Requirements impact | 6 |
| Testing | 1–5, with the goldens in 6 |

**Deviation from the spec, resolved during planning:** the spec did not say where the recovery-codes section goes when the account actions leave the preferences dialog. It goes into the change-credentials dialog (Task 3), which keeps the Settings menu at the three entries the design names.

**Placeholders:** none. Every code step carries the code; every test step carries the test.

**Type consistency:** `MenuEntry`/`MenuGroupHeading` (Task 1) are used unchanged in Tasks 2–4. `LibraryMenu`/`SettingsMenu` both take `required bool showsLabel`. `confirmAndSignOut(BuildContext, WidgetRef)` is defined in Task 4 step 3 and called in step 4. `PumpShell.openSettingsMenuEntry(String)` is defined in Task 2 step 7 and used in Tasks 3 and 4. `ShellMenuBar` is a `StatelessWidget` in Task 1 and becomes a `ConsumerWidget` in Task 5, which that task's step 3 states outright.
