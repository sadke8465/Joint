# Architecture Notes

This folder records architectural decisions that affect more than one feature. The migration plan remains the source of truth for product scope and phase sequencing.

## Initial boundaries

- `App` owns process entry, root dependency wiring, session-level state, and routing.
- `Domain` will contain platform-independent models and value types.
- `Data` will contain local SwiftData models, remote DTOs, and repository implementations.
- `Services` will contain cross-feature integrations such as sync, notifications, haptics, and EventKit.
- `Features` will contain small SwiftUI screens and feature-specific observable state.
- `DesignSystem` will contain reusable visual tokens and controls.
- `Localization` will contain the string catalog and sentence-formatting rules.

Views must not call Supabase directly. Supabase is the authoritative shared store; SwiftData is a cache and pending-mutation queue. The app should render cached state before refreshing and subscribing to Realtime.

## Bootstrap decisions

| Decision | Initial choice |
| --- | --- |
| UI framework | SwiftUI |
| Minimum OS | iOS 18.0 |
| Device family | iPhone only |
| Concurrency | Swift Concurrency with complete checking |
| Remote SDK | Supabase Swift through Swift Package Manager |
| Project generation | Checked-in Xcode project generated from `project.yml` |
| Secrets | Never committed; local build overrides use ignored `Local.xcconfig` |

Add a focused note here when a later phase changes one of these decisions or introduces a durable cross-feature convention.
