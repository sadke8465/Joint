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

## Phase 1 UI conventions

- The root owns one `AppRouter`; enum-driven sheets avoid parallel presentation flags.
- Main-mode selection and mock completion state remain local to `MainView` until repositories arrive.
- Reusable controls consume semantic design tokens instead of feature-specific measurements.
- Motion goes through `AppMotion` and checks Reduce Motion before animating layout changes.
- Haptics use native SwiftUI sensory feedback through `AppHaptics`.
- Member assignment is communicated with an icon and localized label in addition to color.
- Preview and UI-test fixtures stay deterministic and never connect to Supabase.

## Phase 2 local-domain conventions

- `TaskItem`, `TaskDraft`, `EmojiList`, assignment, and status are value types that do not depend on SwiftUI or SwiftData.
- `StoredTask` and `StoredEmojiList` are the only SwiftData model classes. Stored enum values use raw strings so the domain layer remains independent from persistence details.
- One root `ModelContainer` owns the on-device store. Its main context is passed to repository implementations when the app environment is created.
- Views never fetch or mutate SwiftData models. `TaskStore` exposes observable domain values and delegates writes to `TaskRepository` and `EmojiListRepository`.
- Repository writes explicitly save before the store republishes a fresh projection. This keeps Week, List, Calendar, Archive, and Trash consistent after every mutation.
- Deletion is soft by default. The task receives a deletion timestamp, remains recoverable in Trash, and can be restored immediately from the six-second undo banner. Permanent deletion is isolated to the Trash screen and requires confirmation.
- The local prototype uses stable placeholder identifiers for the couple and its two members. Authentication will replace those values without changing task assignment invariants.
- Person assignment always includes a member identifier; together assignment always clears it. A missing due date represents Someday, and a due time is never retained without a due date.
- Emoji lists require one emoji grapheme and a non-empty title. Removing a list preserves its tasks and clears only their list association.
- Sheet presentation remains enum-driven and carries only a task identifier for editing. The editor owns save and dismissal behavior.

Phase 2 deliberately does not add backend calls, authentication, or synchronization. The repositories form the seam that later phases will use to combine the local cache with Supabase.

## Phase 3 presentation conventions

- Week data is derived from one selected week boundary. Active tasks are grouped by day and then by assignment in a stable Me, Partner, Together order.
- `TaskSentenceFormatter` owns deterministic sentence generation. It uses localized templates plus Foundation list formatting, works offline, and never calls a generative service.
- The local prototype uses neutral role-first copy instead of inventing member names or Hebrew grammatical gender. Profile-backed names and grammar preferences arrive with authentication and profile phases.
- The current week surfaces overdue tasks from earlier dates in a separate section. A date-only task becomes overdue after its calendar day; a timed task becomes overdue after its exact local due time.
- Completed-this-week is based on `completedAt`, not the task's due date, and stays collapsed so completed work does not dominate the primary view.
- Week and Calendar keep visible previous/next buttons and also accept deliberate horizontal drags. Vertical scrolling wins unless horizontal movement clearly dominates, and navigation animations honor Reduce Motion.
- Task menus expose quick Today, Tomorrow, and Someday rescheduling while the editor remains the complete route for field changes.
- The task card keeps essential controls visible and adds equivalent accessibility actions for complete, edit, and delete.
- Keyboard submit in a new-task composer persists the task, resets every field to the documented defaults, and retains title focus for rapid entry. The primary button still saves and closes.
