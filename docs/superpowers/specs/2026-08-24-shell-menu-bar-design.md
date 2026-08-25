# The shell menu bar

**Date:** 2026-08-24
**Status:** approved

## Problem

Two of the shell's controls live at the bottom of the navigation rail: the
library tools menu and the preferences button. Neither is a destination, and
the rail says so only by drawing a divider above them. An owner looking for
their library sources, their watchlists, or the theme has to read past ten
destinations to find a pair of buttons that are not destinations at all.

Sign-out is worse: it is inside the preferences dialog, which is behind the
preferences button, which is at the bottom of the rail. Leaving the
application takes three levels of nesting and one screen that does not
announce it holds the exit.

The global search field has the opposite problem. It searches every type at
once, but it is drawn inside the content area under whichever destination's
heading is showing, so a library-wide control reads as belonging to the list
beneath it.

Desktop applications with this much surface put the library-wide actions
across the top. MusicBee, foobar2000, and Calibre use a named menu bar with a
tree beside it; Plex and Spotify keep the left navigation and put search and
the account menu in a bar above it. In both arrangements the left panel is
only destinations, which is what this rail is trying to be.

## Design

### 1. A fourth shell region

`ShellScreen` is a column: the navigation-and-content row, the background
activity strip, and the playback bar. A new `ShellMenuBar` becomes the first
child of that column, spanning the full width above the rail and the content
area.

It is a frame element in the sense the playback bar already is: it does not
know which destination is showing and it holds no feature logic. What it
carries is what belongs to the library rather than to one list.

```txt
┌──────────────────────────────────────────────────────┐
│ Library ▾   Settings ▾        [ 🔍 search…      ]     │
├────────┬─────────────────────────────────────────────┤
│ Home   │                                             │
│ Music  │            content area                     │
│ …      │                                             │
├────────┴─────────────────────────────────────────────┤
│ background activity strip                            │
├──────────────────────────────────────────────────────┤
│ playback bar                                         │
└──────────────────────────────────────────────────────┘
```

The rail loses its `trailing` area entirely and becomes destinations and
nothing else.

### 2. Library ▾

The existing `LibraryToolsButton` moves into the bar as a `SubmenuButton`
inside a Material `MenuBar`. Its entries and its three group headings are
unchanged:

| Group    | Entries                          |
| -------- | -------------------------------- |
| Library  | Sources, Collections             |
| Tracking | Watchlists, Reading lists        |
| Review   | Deleted items, Missing files     |

This is a relocation. The menu already uses `MenuAnchor` and `MenuItemButton`,
so what changes is the anchor it hangs from, not what it offers or what any of
its entries do.

### 3. Settings ▾

A new submenu with three entries:

- **Preferences…** — the preferences dialog.
- **Change credentials…** — the credentials screen, today reached from inside
  that dialog.
- **Sign out** — `SignOutButton`'s action, today reached from inside that
  dialog.

The preferences dialog is slimmed to theme and language: the two account
actions are account actions, not preferences, and a dialog that holds both is
why leaving the application is currently three levels deep. Its unsaved-change
notice, its confirmation on sign-out with unsaved changes, and every other
behaviour of the two moved actions are unchanged — they move with them.

`PreferencesButton` stays exactly as it is. The login and sign-up screens use
it and have no shell around them, so preferences must still be reachable from
a button of its own there.

### 4. Search moves up

`CatalogSearchField` moves out of `ShellContentArea` and into the menu bar's
trailing position. The search term is already a global provider, so no state
moves with it and no search behaviour changes — the field is drawn somewhere
else, and that is all.

Two rules carry over unchanged: bookmarks show no field, because FR-CT-06
matches files and a bookmark is not one; and while a term is present the
content area shows results instead of the listing.

The destination heading stays in the content area. It names what is below it,
which is exactly what the menu bar is not for.

### 5. Across the breakpoints

FR-UX-02 allows collapsing a control and forbids hiding one, and the menu bar
keeps that bargain the way the rail does:

| Tier              | Menus                        | Search                      |
| ----------------- | ---------------------------- | --------------------------- |
| Expanded, medium  | Icon and label               | Fixed-width field           |
| Compact           | Icon only, with a tooltip    | Fills the remaining width   |

Nothing is dropped at any tier, and no entry inside either menu changes with
the width.

## Components

| Component                                | Change                                                            |
| ---------------------------------------- | ----------------------------------------------------------------- |
| `shell/presentation/shell_menu_bar.dart` | New. The bar, the two submenus, and the breakpoint behaviour.      |
| `shell/presentation/shell_screen.dart`   | Adds the bar as the column's first child; drops the search field.  |
| `shell/presentation/library_tools_button.dart` | Becomes the Library submenu; loses its own anchor button.    |
| `shell/presentation/shell_navigation_panel.dart` | Loses its `trailing` area.                                 |
| `shell/presentation/preferences_dialog.dart` | Loses the account section; keeps theme, language, and `PreferencesButton`. |

No application or domain layer changes: every action behind the bar already
has a controller, and this design moves what invokes them.

## Requirements impact

- **FR-UX-01** names three regions and becomes four, naming the menu bar.
- **FR-UX-02** names the menu bar among what collapses across the breakpoints.
- **UC-38** describes the shell's regions and needs the same amendment where it
  enumerates them.

No new use case. Every action the bar offers is an existing one reached from a
new place.

## Testing

Widget tests, at `test/features/shell/presentation/shell_menu_bar_test.dart`:

- Each Library entry opens its screen.
- Each Settings entry opens its screen, including sign-out reaching the
  sign-out flow with its unsaved-changes confirmation intact.
- Sign-out and change-credentials are absent from the preferences dialog.
- The search field is in the bar, filters the listing from there, and is absent
  on bookmarks.
- At the compact breakpoint both menus render icon-only and every entry inside
  them is still reachable.

Existing tests that reach the library tools, preferences, or search through the
rail or the content area are updated to their new locations rather than
duplicated: the assertions are about behaviour that has not changed, and two
copies of them would mean the old placement still has a test asserting it
exists.

## Risks

The menu bar takes vertical height from a window whose minimum is already
enforced (FR-UX-03, NFR-07). The bar is one row of standard menu height, and
the rail's own scrolling already handles short windows; if the minimum window
turns out not to fit the bar, the playback bar and the activity strip are what
it competes with, and that is a layout question to settle against a real
minimum-size window rather than by guessing here.
