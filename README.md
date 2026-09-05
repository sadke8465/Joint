# Couples Todo for iOS

A native SwiftUI to-do app designed for exactly two people. The shared week is the primary experience, with personal assignment, shared completion, offline-tolerant local state, and targeted notifications planned for v1.

This repository is the native successor to the historical [`sadke8465/omer_noam`](https://github.com/sadke8465/omer_noam) web prototype. The prototype remains a product and visual reference during the early migration phases; its implementation is not copied into this codebase.

## Current status

Phases 0–3 of [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md) are implemented:

- native iPhone-only SwiftUI application target,
- iOS 18.0 minimum deployment target,
- Supabase Swift package declaration,
- unit and UI test targets,
- reproducible XcodeGen project specification,
- local signing configuration that stays out of version control,
- semantic color, typography, spacing, card, member, checkbox, motion, and haptic primitives,
- live Week, List, and Calendar modes backed by the same persisted task store,
- native create and edit flows for title, notes, assignment, date, time, and emoji list,
- local create, edit, complete, reopen, soft-delete, undo, restore, and permanent-delete behavior,
- searchable assignment, date, and emoji-list filters,
- Archive, Trash, and emoji-list management screens,
- SwiftData persistence behind repository boundaries,
- assignee-grouped week sections with deterministic localized summaries,
- horizontal week and month navigation with Reduce Motion support,
- overdue visibility and completed-this-week history,
- quick Today, Tomorrow, and Someday rescheduling,
- rapid consecutive task entry from the keyboard,
- explicit accessibility actions for completion, editing, and deletion,
- English and Hebrew localization with verified RTL layout,
- Dynamic Type and Reduce Motion accommodations.

The next vertical slice is Phase 4: provision a fresh Supabase project and add the shared database schema and local CLI workflow.

## Requirements

- Xcode 26.6 or newer
- iOS 18.0 or newer
- XcodeGen 2.45 or newer only when regenerating the checked-in project

## First run

1. Copy `Configuration/Local.xcconfig.example` to `Configuration/Local.xcconfig`.
2. Replace the example Apple development team and bundle identifier values.
3. Open `CouplesTodo.xcodeproj` in Xcode.
4. Select a connected iPhone and run the `CouplesTodo` scheme.

The committed Xcode project builds directly. Run `xcodegen generate` only after changing `project.yml` or when intentionally regenerating project metadata.

For a compile-and-build check without launching a Simulator, build the scheme for the generic iOS device destination with code signing disabled.

## Configuration safety

`Configuration/Local.xcconfig` is ignored by Git. Keep signing identifiers and future environment-specific client configuration there. Never place a Supabase service-role key, APNs private key, or other server credential in the iOS project.

## Documentation

- [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md) — product and technical migration specification
- [`docs/architecture/README.md`](docs/architecture/README.md) — initial architecture boundaries and decision record
