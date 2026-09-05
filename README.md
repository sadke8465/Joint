# Couples Todo for iOS

A native SwiftUI to-do app designed for exactly two people. The shared week is the primary experience, with personal assignment, shared completion, offline-tolerant local state, and targeted notifications planned for v1.

This repository is the native successor to the historical [`sadke8465/omer_noam`](https://github.com/sadke8465/omer_noam) web prototype. The prototype remains a product and visual reference during the early migration phases; its implementation is not copied into this codebase.

## Current status

Phase 0 of [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md) is implemented:

- native iPhone-only SwiftUI application target,
- iOS 18.0 minimum deployment target,
- Supabase Swift package declaration,
- unit and UI test targets,
- reproducible XcodeGen project specification,
- local signing configuration that stays out of version control.

The app is intentionally a small launch shell at this stage. Product UI starts in Phase 1.

## Requirements

- Xcode 26.6 or newer
- iOS 18.0 or newer
- XcodeGen 2.45 or newer only when regenerating the checked-in project

## First run

1. Copy `Configuration/Local.xcconfig.example` to `Configuration/Local.xcconfig`.
2. Replace the example Apple development team and bundle identifier values.
3. Open `CouplesTodo.xcodeproj` in Xcode.
4. Select an iPhone simulator or connected iPhone and run the `CouplesTodo` scheme.

The committed Xcode project builds directly. Run `xcodegen generate` only after changing `project.yml` or when intentionally regenerating project metadata.

## Configuration safety

`Configuration/Local.xcconfig` is ignored by Git. Keep signing identifiers and future environment-specific client configuration there. Never place a Supabase service-role key, APNs private key, or other server credential in the iOS project.

## Documentation

- [`MIGRATION_PLAN.md`](MIGRATION_PLAN.md) — product and technical migration specification
- [`docs/architecture/README.md`](docs/architecture/README.md) — initial architecture boundaries and decision record
