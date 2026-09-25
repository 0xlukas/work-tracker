# Work Tracker

A macOS 27 app for tracking working hours against a Swiss (Zurich) work schedule: time entries per project, absences, public holidays, vacation allowance and overtime balance. The interface follows the macOS 27 Liquid Glass design language.

## Building

```sh
swift test                      # needs Xcode selected and its license accepted
scripts/build-app.sh            # release WorkTracker.app in .build/app
BUNDLE_ID=com.worktracker.app.test scripts/build-app.sh /tmp/test   # separate settings domain for testing
```

The script copies the compiled String Catalog into `Contents/Resources/<lang>.lproj` and sets `LSMinimumSystemVersion` to 27.0.

## Features

- **Daily Entry** — entries per day with project and optional note. Times are typed as `0930`, `930`, `9` or `9:30`; ↑/↓ nudge (⇧ for hours); the End field accepts `24:00`. ⌘[ / ⌘] move between days, ⌘T jumps to today, ⌘N adds an entry. Right-click an entry to duplicate it; **More ▸ Copy Entries from …** copies the previous day with entries (overlapping ones are skipped). New entries default to the last-used project.
- **Timer** — start a timer for a project from the toolbar or the menu bar item; stopping it creates entries, split at midnight and around existing entries. The menu bar shows today's hours and this week's balance. A running timer survives quitting.
- **Undo** — Edit ▸ Undo (⌘Z) reverts deleting, copying and editing entries, absences and projects.
- **Projects** — colour per project (click the circle), archiving (hides a project from pickers, keeps its history), and an hours-per-project report for any date range. Names must be unique.
- **Absences** — click cycle full day → half day → none, Shift-click for ranges. Built-in categories: vacation, sick, public service; plus custom categories (see below).
- **Overview** — today/week/month, balance to date, all-time balance (with opening balance), holiday and absence counts, monthly breakdown, CSV export (daily summary or every entry; comma or German-Excel semicolon format).

## Work schedule and balances

Settings ▸ Work holds the contract hours per weekday. Add a schedule change when the contract changes (for example 80% from next January); earlier days keep their old schedule. Half-day holidays and half-day absences count half of that day's scheduled hours. Days without scheduled hours expect nothing and take no absences.

Public holidays are the Zurich holidays as defined in `Holidays.swift` (Easter-based dates, Sechseläuten and Knabenschiessen), computed for any year.

The vacation allowance applies per calendar year. Optionally, unused days carry into the next year, and days can be carried into the first tracked year. Vacation beyond a year's allowance gets no time credit: those specific days count as working days, so every period — a month, a year, all-time — shows the same result. An opening balance (overtime from before tracking started) is added to the all-time balance.

## Custom absence categories

In **Absences**, use **Manage Categories…** beside the category picker. Add a name, colour, icon, and counting rule:

- **Reduce expected hours:** time off without consuming vacation allowance.
- **Use vacation allowance:** time off counted against the shared annual vacation allowance.
- **Leave expected hours unchanged:** record the absence without granting time credit.

Renaming or changing the colour/icon updates existing displays. Counting-rule changes apply only when assigning a category to a new entry; existing entries retain their original rule. Archiving removes a category from the picker while preserving historical entries and reports. Built-in categories cannot be edited or archived.

## Storage

The database is `WorkTracker.store` in `~/Library/Application Support/WorkTracker/` or a folder chosen in Settings ▸ Storage. Moving it copies a consistent snapshot (SQLite backup API) to the new folder and restarts the app; an existing database in the destination is never overwritten silently — you choose to replace it (the old file is kept under Backups) or to use it.

Keep the live database out of cloud-synced folders (Google Drive, iCloud Drive, Dropbox, OneDrive): sync clients upload the store and its WAL separately and can corrupt it. The app warns when the database is in such a folder and offers to move it to this Mac and copy backups there instead.

If the database cannot be opened, the app shows a recovery window instead of quitting: restore the latest backup, reveal the files, or quit. Nothing is deleted or recreated.

## Backups

The app checks hourly (while running, with or without a window) whether a backup is due and makes at most one a day; **Back Up Now** forces one. Snapshots use SQLite's online backup API, including committed WAL data, pass an integrity check, and are self-contained single files. If nothing changed since the last snapshot, that one is re-dated instead of storing a copy, so the 30 retained snapshots cover as much history as possible. Snapshots live under `~/Library/Application Support/WorkTracker/Backups/<id>/`; **Copy Backups To** additionally copies each one to another folder (for example a cloud drive), with the same retention.

To restore, pick a snapshot in Settings ▸ Backups ▸ Restore. The app restarts, moves the current database (with its WAL/SHM files) into `Backups/replaced-…`, and copies the snapshot in place before opening it. Preferences (schedule, allowance, start date, opening balance) live in the app's defaults, not in the database.

## Validation

`swift test` covers the calculator (all categories and day kinds, schedules, per-year allowance and carry-over), holidays, migrations V1–V4, backups, store moves and restores, CSV, the timer, entry actions, parsing, and catalog completeness. Set `WORK_TRACKER_TEST_STORE` to a standalone database snapshot to also check that a real store migrates without losing entries or hours.
