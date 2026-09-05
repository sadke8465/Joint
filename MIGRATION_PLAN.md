# Couples To‑Do iOS — Native Swift Migration Plan

> **Working repository name:** `couples-todo-ios`  
> **Status:** Product + technical migration specification  
> **Source product:** `sadke8465/omer_noam`  
> **Target:** Native iPhone app, public App Store product, built specifically for exactly two people  
> **Primary implementation style:** Agent-executable, milestone-driven  
> **Last updated:** 2026-09-06

---

## 1. Product Definition

Build a native iPhone to-do app for couples.

This is **not** a generic task manager with sharing added afterward. The product should feel like a small shared space built for exactly two people.

The core value is:

- tasks that naturally belong to one person or the couple,
- a shared weekly view that makes the couple's week understandable at a glance,
- personal, reliable daily reminders,
- immediate partner activity notifications,
- small custom emoji lists,
- a polished, familiar native iOS experience,
- enough personalization that the app feels like "ours."

The app should remain deliberately small. Do not turn v1 into a project-management system.

### Product principles

1. **Two people, explicitly**
   - One user belongs to one couple.
   - One couple contains at most two active members.
   - Do not build team/workspace abstractions into the UI.

2. **Fast enough for everyday life**
   - Adding a task must be nearly as fast as Apple Reminders.
   - Common task actions should take one gesture or one tap.
   - Secondary fields stay out of the way until needed.

3. **The shared week is the product**
   - The weekly couple overview is more important than a traditional dashboard.
   - The app should answer: "What do we need to get done this week, and who is doing what?"

4. **Personal, not cute for the sake of cute**
   - Names, chosen colors, avatar, language, grammatical form, shared lists and notifications make the product personal.
   - Avoid gamification, streaks, points, trophies or excessive relationship gimmicks.

5. **Native polish over feature count**
   - SwiftUI interactions, haptics, transitions, keyboard behavior, swipe gestures and loading states should feel intentional.
   - Respect Reduce Motion and accessibility settings.

6. **Low operating cost**
   - Avoid paid AI APIs in v1.
   - Avoid a separate Google Calendar backend integration in v1.
   - Use managed infrastructure only where it materially improves reliability.

---

## 2. Key Decisions

### 2.1 New codebase

Create a **fresh repository** rather than converting the React/Vite project in place.

Working name:

```text
couples-todo-ios
```

The current `omer_noam` repository remains a product/reference implementation during the rewrite and can be archived later.

Do not copy the existing web code into the new repository except for:

- product behavior references,
- Hebrew copy worth preserving,
- notification timing ideas,
- visual references,
- test fixtures if useful.

### 2.2 Platform

- iPhone only for v1.
- SwiftUI.
- Swift Concurrency (`async/await`).
- Minimum deployment target: **iOS 18.0**.
- Build using the current stable Xcode at implementation time.
- No iPad-specific UI in v1.
- No Apple Watch, Mac or widgets in v1.
- Keep domain/service layers reusable enough that these can be added later.

### 2.3 Backend

Use **Supabase** for v1.

Do **not** use CloudKit as the primary shared database.

Reasons:

- reliable two-user account model,
- straightforward Sign in with Apple,
- explicit couple membership and row-level authorization,
- Realtime synchronization,
- Edge Functions for partner push notifications,
- scheduled server jobs for daily reminders,
- low cost at early scale,
- easier observability and migration than a CloudKit-share-only architecture.

CloudKit can be reconsidered for a future Apple-only variant, but it should not block v1.

### 2.4 Local persistence

Use **SwiftData as a local cache and mutation queue**, not as the canonical shared database.

Supabase remains the authoritative shared source.

Expected behavior:

- app opens immediately using locally cached tasks,
- recent data is available without network,
- creates/edits/completions can be optimistic,
- temporary offline mutations are queued,
- reconnect flushes queued mutations,
- Realtime changes from the partner reconcile into the local cache.

This is **offline-tolerant**, not a complex CRDT/offline-collaboration system.

### 2.5 Authentication

Use:

1. **Sign in with Apple** as primary authentication.
2. **Email magic link** as a secondary fallback.

Do not use passwords in v1.

Every user has an account before creating or joining a couple.

### 2.6 Couple invitation

Recommended invite flow:

1. User signs in.
2. User chooses **Create our space**.
3. Server creates a couple and one one-time invite.
4. App shows:
   - a shareable invite link,
   - an 8-character short code,
   - optional QR representation of the same invite.
5. Partner installs/opens app.
6. Partner signs in.
7. Partner accepts invite.
8. Couple becomes full and no third member can join.

Invite requirements:

- one-time use,
- expiration (default: 7 days),
- server-side validation,
- regenerate/revoke support before partner joins,
- rate-limit attempts against short codes,
- never authorize membership based only on client-provided IDs.

### 2.7 Assignment semantics

Do **not** create separate "Both" and "Any" states.

The UI has exactly three choices:

- **Me**
- **Partner**
- **Together**

Under the hood the labels resolve to the two real user IDs.

A `Together` task has **one shared completion state**. Either member completing it completes it for the couple.

Do not require both members to separately confirm completion in v1.

Keep the schema extensible enough to add a future `completion_mode` if real user behavior proves this is needed.

### 2.8 Default home

Default to the **Week** view.

Do not add a separate Today tab in v1.

Instead:

- Week opens to the current week.
- Today is visually prominent within the week.
- User can horizontally swipe to previous/next week.
- List and Calendar are adjacent modes in the same main screen.

This keeps the app distinctive and avoids four competing top-level views.

### 2.9 Navigation

Keep the current compact philosophy.

Main app shell:

```text
Main
 ├─ Week
 ├─ List
 └─ Calendar
```

Use a polished custom segmented/toolbar switcher at the top rather than a bottom tab bar.

Secondary destinations:

- Profile / Couple
- Notification settings
- Calendar settings
- Archive
- Trash
- App settings

Open secondary destinations from a profile/settings control in the main header.

Do not add a separate dashboard.

---

## 3. V1 Scope

### Must ship

- account creation/sign-in,
- create or join exactly one couple,
- two member profiles,
- optional profile image/avatar,
- chosen member accent colors,
- Hebrew and English,
- RTL/LTR switching based on chosen app language,
- Hebrew grammatical/address preference,
- add task,
- edit every task field,
- assign task to either member or Together,
- optional due date,
- optional due time,
- optional notes,
- one optional emoji list per task,
- complete/uncomplete,
- soft delete + undo,
- trash,
- archive,
- List view,
- Week view,
- Calendar view,
- swipe between weeks,
- task filtering,
- search,
- Realtime partner changes,
- cached local state,
- basic offline mutation queue,
- daily summary notifications,
- partner activity notifications,
- user-configurable reminder times,
- notification actions,
- optional app badge,
- add to Calendar,
- haptics,
- native animations and interaction polish,
- TestFlight-ready privacy/error/empty states.

### Explicit non-goals for v1

Do not implement:

- subtasks,
- recurring tasks,
- task priority,
- file attachments,
- task photos,
- location reminders,
- estimated duration,
- multi-person spaces,
- multiple couple spaces,
- comments/chat,
- reactions,
- AI task creation,
- AI-generated daily text,
- Apple Reminders integration,
- direct Google OAuth/calendar API integration,
- widgets,
- Lock Screen widgets,
- Control Center controls,
- Live Activities,
- Siri/App Intents,
- Share Extension,
- Spotlight integration,
- Apple Watch,
- iPad-specific design,
- macOS,
- dark mode,
- activity/social feed,
- gamification.

---

## 4. Task Model

The current web model is a good baseline, but the native product needs generic couple/member IDs and lifecycle metadata.

### Domain model

```swift
struct TaskItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let coupleID: UUID

    var title: String
    var notes: String?

    var assigneeKind: AssigneeKind
    var assigneeUserID: UUID?

    var dueDate: Date?
    var dueTime: DateComponents?

    var listID: UUID?

    var status: TaskStatus

    var createdBy: UUID
    var createdAt: Date
    var updatedAt: Date

    var completedBy: UUID?
    var completedAt: Date?

    var deletedAt: Date?
}
```

### Assignee

```swift
enum AssigneeKind: String, Codable {
    case person
    case together
}
```

Rules:

- `.person` requires `assigneeUserID`.
- `.together` requires `assigneeUserID == nil`.
- No unassigned tasks in v1.

### Task status

Use explicit lifecycle state rather than relying only on a boolean.

```swift
enum TaskStatus: String, Codable {
    case active
    case completed
}
```

Deletion is represented separately with `deleted_at`.

### Dates

A task may have:

- no date,
- date only,
- date + time.

Do not require a time.

Date-only is still the dominant task model.

### "Someday"

Keep Someday as a lightweight concept.

Definition:

```text
active task + due_date == nil
```

Do not create a separate Inbox/backlog model in v1.

In UI, call this group **Someday**.

This preserves the useful current behavior without adding another task state.

---

## 5. Emoji Lists

The existing loose emoji-tag idea becomes a small first-class model called `lists`.

A list:

- belongs to one couple,
- is represented primarily by one emoji,
- may contain many tasks,
- each task can belong to zero or one list,
- is shared by both members.

V1 UI should expose the emoji, not require a visible text name.

Recommended DB fields:

```text
id
couple_id
emoji
internal_name nullable
sort_order
created_by
created_at
updated_at
deleted_at
```

`internal_name` exists for future migration but does not need to appear in v1 UI.

Examples:

```text
🏠
🛒
✈️
💍
💡
```

The list picker should include:

- existing couple emojis,
- preset suggestions,
- custom emoji input,
- create new emoji,
- remove task from list.

One emoji must be a single grapheme cluster.

---

## 6. Main UX

## 6.1 Header

Main header should include:

- couple title / names,
- active task count or compact contextual line,
- profile/settings button,
- List / Week / Calendar mode switch.

Do not permanently display a large dashboard.

### Personalization

The title can be generated from profile names:

```text
Omer & Noam
עומר ונועם
```

Avoid hardcoding names or gender.

---

## 6.2 Week — default

This is the primary experience.

### Structure

For the selected week:

- week range,
- horizontal swipe between weeks,
- today emphasis,
- grouped days that contain tasks,
- each day groups tasks by:
  - member A,
  - member B,
  - Together.

### Sentence-style summaries

Preserve the distinctive current behavior, but generate it deterministically.

Example English:

```text
Today
Noam needs to buy wine and call the venue.
Omer needs to pick up the dress.
Together: choose the flowers.
```

Example Hebrew, gendered:

```text
היום
נועם צריך לקנות יין ולהתקשר לאולם.
עומר צריכה לאסוף את השמלה.
ביחד: לבחור פרחים.
```

Example Hebrew neutral/name-first mode:

```text
היום
לנועם: לקנות יין ולהתקשר לאולם.
לעומר: לאסוף את השמלה.
ביחד: לבחור פרחים.
```

Do not use an LLM for these summaries in v1.

Use deterministic localized templates so:

- they work offline,
- they are free,
- they are predictable,
- grammar can be tested.

### Completed tasks

Show a small collapsed "Done this week" section at the bottom.

Do not let completed tasks dominate the week.

---

## 6.3 List

Recommended structure:

```text
Filters
↓
Dated active tasks
↓
Someday
↓
Recently completed (collapsed)
```

Filters:

- All
- Mine
- Partner
- Together
- emoji lists

Add optional smart-filter chips:

- Today
- This week
- Overdue

Do not show every filter simultaneously if space becomes crowded. Use horizontally scrollable chips or a compact filter menu.

### Search

Use native `.searchable`.

Search:

- title,
- notes.

Do not create a separate search tab.

---

## 6.4 Calendar

Use a **month grid + selected-day agenda**.

Behavior:

1. Month calendar at top.
2. Dates with tasks show subtle indicators.
3. Selecting a date reveals tasks below.
4. Swipe month navigation.
5. Today shortcut.
6. Tapping task opens task editor.

Calendar is a task calendar, not an external-calendar viewer.

Do not read the user's Apple/Google calendar into this screen in v1.

---

## 7. Task Creation

Use a native polished bottom sheet.

### Interaction hierarchy

1. Title — autofocus.
2. Assignee.
3. Date.
4. Optional time.
5. Emoji list.
6. Notes.
7. Add.

Keep secondary controls visually quiet.

### Fast add

Two submit paths:

- tapping the primary Add button saves and closes,
- pressing the keyboard's Add/Return command saves the task, clears the composer and stays focused, enabling rapid consecutive entry.

Provide a Done/close action for leaving rapid-entry mode.

### Defaults

Do not remember the previous assignee automatically.

Recommended default:

- `Together` if entering from All/Week,
- the selected member if entering while filtered to that member,
- selected emoji list if entering from a list filter.

### Editing

Every task field is editable after creation:

- title,
- notes,
- assignee,
- date,
- time,
- emoji list.

Use the same visual language for create and edit.

---

## 8. Task Gestures

Use familiar iOS gestures, but do not hide essential functionality exclusively behind gestures.

Recommended:

### Swipe leading
- Complete / Uncomplete

### Swipe trailing
- Reschedule
- Delete

### Tap
- Open editor/details

### Long press
- Optional context menu:
  - Complete,
  - Edit,
  - Move to list,
  - Change assignee,
  - Add to Calendar,
  - Delete.

Do not build drag-and-drop ordering in v1.

---

## 9. Haptics and Microinteractions

Haptics are part of the product quality.

Use them intentionally.

### Suggested feedback

- complete task: success feedback,
- uncomplete: light impact,
- add task: light success/impact,
- crossing swipe action threshold: selection feedback,
- changing assignee: selection,
- changing emoji list: selection,
- destructive confirmation: warning,
- invite accepted: success,
- realtime partner task appearing: animation only, no haptic,
- ordinary scrolling/filtering: no haptic.

Use native SwiftUI `sensoryFeedback` where possible.

### Animation

Use native SwiftUI animations:

- spring insertion/removal,
- checkbox morph,
- sheet transitions,
- list regrouping,
- filter transitions,
- week swipe,
- task completion collapse,
- matched movement where appropriate.

Avoid:

- excessive bouncing,
- arbitrary staggered entrance animations every time a screen opens,
- animations that delay input,
- custom physics where native springs suffice.

Respect Reduce Motion.

---

## 10. Profiles and Language

Each member profile should contain:

```text
id
display_name
avatar_path nullable
accent_color
app_language
hebrew_address_style nullable
created_at
updated_at
```

### Language

Supported v1:

- English
- Hebrew

Language is selected during onboarding and editable in Settings.

Behavior:

- English -> LTR
- Hebrew -> RTL

Changing language should update both copy and layout direction.

Do not tie app language to device language permanently.

### Hebrew grammatical preference

When Hebrew is active, ask:

**How should the app address you?**

Options:

- masculine,
- feminine,
- neutral / name-first.

Prefer neutral structures where easy even when a grammatical preference exists.

Never infer gender from name, avatar, partner or color.

---

## 11. Couple Setup and Permissions

Both partners have equal product permissions in v1.

Either member may:

- create tasks,
- edit any task,
- reassign tasks,
- complete any task,
- uncomplete any task,
- create/remove emoji lists,
- change due dates,
- delete tasks.

Profile settings remain personal.

Notification settings remain personal.

Couple-level destructive actions such as leaving/dissolving the couple should require an explicit confirmation flow.

---

## 12. Archive and Trash

### Archive

Archive is task history, primarily completed work.

Include:

- completed tasks,
- search,
- filters by member/list/date,
- restore to active.

The main list may show a small collapsed `Recently completed` group, but Archive holds the full history.

### Trash

Deletion should be soft-delete first.

Flow:

1. User deletes.
2. Task disappears.
3. Show Undo toast/snackbar for several seconds.
4. If not undone, task remains in Trash.
5. Trash allows Restore or Delete Forever.

Recommended eventual automatic purge:

- 30 days after deletion.

Do not hard-delete immediately.

---

## 13. Calendar Integration

The app's tasks remain the source of truth.

Calendar integration is **export**, not two-way task synchronization, in v1.

### Why

A due date is not always a calendar event.

Automatically placing every task onto a calendar would:

- clutter calendars,
- create duplicate/conflict problems,
- blur the boundary between tasks and events,
- require much more complex sync semantics.

### Native implementation

Use EventKit / EventKitUI.

Task action:

```text
Add to Calendar
```

Behavior:

- date only -> all-day event,
- date + time -> timed event,
- notes copied to event notes,
- title copied to event title.

Use the system calendar chooser/editor.

This naturally supports writable calendars configured on the iPhone, including iCloud and Google calendars.

Therefore:

- do not build Google OAuth in v1,
- do not call Google Calendar API in v1,
- do not require users to connect a separate Google account inside the app.

### Future

Potential later setting:

```text
Automatically add timed tasks to my chosen calendar
```

Do not implement until real usage shows demand.

Do not implement two-way calendar sync until there is a clear product rule for conflicts/deletions.

---

## 14. Notifications — Product Behavior

Notifications are a core differentiator and must be designed as a system, not an afterthought.

There are two classes.

### A. Daily couple reminders

Preserve the current three-reminder concept:

1. evening before,
2. morning of,
3. evening of.

Each user can independently configure:

- enable/disable each reminder,
- time for each reminder,
- timezone,
- app badge on/off.

Suggested defaults:

```text
Evening before: 21:00
Morning of:      10:00
Evening of:      18:30
```

Each notification is generated from current shared data.

Example:

```text
Tomorrow
You: pick up the package.
Omer: call the venue.
Together: buy wine.
```

Use the recipient's chosen language and Hebrew address style.

Do not send one global notification to every app user.

### B. Partner activity notifications

Optional per user, enabled by default:

- partner created a task assigned to me,
- partner reassigned a task to me,
- partner changed the date of a task assigned to me / Together,
- partner completed a task,
- partner uncompleted a task.

Avoid notifying someone about their own action.

Avoid sending noisy pushes for:

- notes typo edits,
- list emoji changes,
- title edits that do not materially affect responsibility,
- every Realtime database update.

### Completion

Recommended push:

```text
Omer finished "Pick up dry cleaning"
```

For Together:

```text
Omer finished "Book the hotel"
```

No generic "Congratulations!" spam.

### Notification actions

Keep actions small.

For due-task reminders:

- **Done**
- **Tomorrow**
- **Open**

For partner activity:

- **Open**

`Tomorrow` should move only the selected task when the notification represents one task.

For aggregated daily summaries, do not offer Tomorrow for the whole summary.

### Badge

Personal setting:

```text
App icon badge: On / Off
```

If enabled, badge count = incomplete tasks relevant to the user:

- assigned to user,
- Together.

Do not count partner-only tasks.

---

## 15. Notifications — Technical Architecture

Do not copy the current OneSignal `included_segments: ["All"]` approach.

### Device tokens

Create table:

```text
device_tokens
```

Fields:

```text
id uuid
user_id uuid
token text
platform text default 'ios'
environment text ('development' | 'production')
app_version text nullable
last_seen_at timestamptz
created_at timestamptz
updated_at timestamptz
```

Unique:

```text
(user_id, token)
```

RLS:

- user can insert/update/delete only their own device tokens,
- ordinary clients cannot read other users' tokens.

### Partner activity pushes

Flow:

```text
task mutation
    ↓
database webhook / trigger
    ↓
Supabase Edge Function
    ↓
validate old vs new state
    ↓
resolve partner + preferences
    ↓
send APNs notification only to intended recipient
```

Use direct APNs rather than OneSignal in the new app.

Keep the APNs `.p8` signing key and Supabase service credentials only in server secrets.

Never ship them in the iOS app.

### Daily scheduled reminders

Use Supabase Cron + Edge Function.

Recommended:

- cron invokes a reminder dispatcher every 5 minutes,
- dispatcher finds user reminder slots whose local configured time falls in the current window,
- queries current due tasks,
- builds localized summary,
- sends APNs,
- records delivery.

Add table:

```text
notification_deliveries
```

Fields:

```text
id uuid
user_id uuid
couple_id uuid
kind text
local_date date
slot text
sent_at timestamptz
dedupe_key text unique
```

This prevents double delivery.

Example dedupe keys:

```text
{userID}:morning-of:2026-09-06
{userID}:evening-before:2026-09-06
```

### Notification preferences table

```text
notification_preferences
```

Suggested fields:

```text
user_id uuid primary key
timezone text

evening_before_enabled bool
evening_before_time time

morning_of_enabled bool
morning_of_time time

evening_of_enabled bool
evening_of_time time

notify_task_assigned bool
notify_task_reassigned bool
notify_task_date_changed bool
notify_task_completed bool
notify_task_uncompleted bool

badge_enabled bool

updated_at timestamptz
```

Store times in the user's local intended wall-clock time and store IANA timezone separately.

Do not hardcode Israel timezone.

---

## 16. Supabase Data Model

Recommended public tables:

```text
profiles
couples
couple_members
couple_invites
lists
tasks
notification_preferences
device_tokens
notification_deliveries
```

Potential server-only/private schema:

```text
private.push_jobs
private.invite_rate_limits
```

### `profiles`

```text
id uuid PK -> auth.users.id
display_name text
avatar_path text nullable
accent_color text
app_language text
hebrew_address_style text nullable
created_at timestamptz
updated_at timestamptz
```

### `couples`

```text
id uuid PK
created_by uuid
created_at timestamptz
updated_at timestamptz
dissolved_at timestamptz nullable
```

### `couple_members`

```text
couple_id uuid
user_id uuid
joined_at timestamptz
member_position smallint
PRIMARY KEY (couple_id, user_id)
UNIQUE (user_id)
```

Constraints:

- member position is 1 or 2,
- max two active members per couple,
- one active couple per user.

Enforce the two-person rule server-side, not only in Swift.

### `couple_invites`

```text
id uuid
couple_id uuid
created_by uuid
token_hash text
short_code_hash text
expires_at timestamptz
accepted_by uuid nullable
accepted_at timestamptz nullable
revoked_at timestamptz nullable
created_at timestamptz
```

Do not store raw reusable invite secrets if a hash is sufficient.

### `lists`

As defined earlier.

### `tasks`

```text
id uuid PK
couple_id uuid NOT NULL
title text NOT NULL
notes text nullable

assignee_kind text NOT NULL
assignee_user_id uuid nullable

due_date date nullable
due_time time nullable

list_id uuid nullable

status text NOT NULL default 'active'

created_by uuid NOT NULL
created_at timestamptz NOT NULL
updated_at timestamptz NOT NULL

completed_by uuid nullable
completed_at timestamptz nullable

deleted_at timestamptz nullable
```

Checks:

```text
assignee_kind IN ('person', 'together')
status IN ('active', 'completed')
```

Assignment integrity:

```text
person   -> assignee_user_id IS NOT NULL
together -> assignee_user_id IS NULL
```

Additionally validate that a person assignee is a member of the task's couple.

### Realtime

Enable Realtime for:

- tasks,
- lists,
- relevant couple/profile changes.

Configure previous-row availability as required for update/delete handling.

Do not expose notification token data over Realtime.

---

## 17. RLS and Security

This is a complete redesign from the current personal app's allow-all policy.

Every exposed table must have RLS enabled.

### Core policy rule

A member may access couple data only if:

```sql
exists (
  select 1
  from couple_members cm
  where cm.couple_id = row.couple_id
    and cm.user_id = auth.uid()
)
```

### Profiles

User can:

- update own profile,
- read own profile,
- read partner profile only when they share a couple.

### Couples / members

User can read only their own couple.

Ordinary client writes that could bypass the two-member invariant should go through a controlled server function/Edge Function.

### Tasks

Both members of the couple can:

- select,
- insert,
- update,
- soft-delete.

Insert/update must check:

- task couple is user's couple,
- `created_by` is valid,
- assignee belongs to that couple when assignee kind is person.

### Device tokens / preferences

Only the owner may manage them.

### Service role

Never expose the Supabase service-role key to the app.

### Authorization metadata

Do not use editable user metadata as the source of couple authorization.

Couple membership lives in database tables protected by RLS.

### Security verification before launch

Run:

- Supabase database advisors,
- RLS policy tests using two unrelated users,
- invite abuse tests,
- token ownership tests,
- task cross-couple access tests,
- Edge Function auth tests.

A test must prove User A cannot read or modify Couple B's task even if User A knows the UUID.

---

## 18. Swift Architecture

Avoid a large architecture framework in v1.

Use:

- SwiftUI,
- Observation,
- Swift Concurrency,
- SwiftData,
- Supabase Swift SDK,
- UserNotifications,
- EventKit/EventKitUI,
- AuthenticationServices.

### Suggested layers

```text
App
 ├─ Domain
 ├─ Data
 │   ├─ Local
 │   ├─ Remote
 │   └─ Repositories
 ├─ Services
 ├─ Features
 ├─ DesignSystem
 ├─ Localization
 └─ Utilities
```

### Recommended source layout

```text
CouplesTodo/
├── App/
│   ├── CouplesTodoApp.swift
│   ├── AppEnvironment.swift
│   ├── AppRouter.swift
│   └── AppState.swift
│
├── Domain/
│   ├── Models/
│   │   ├── UserProfile.swift
│   │   ├── Couple.swift
│   │   ├── CoupleMember.swift
│   │   ├── TaskItem.swift
│   │   ├── EmojiList.swift
│   │   └── NotificationPreferences.swift
│   └── Types/
│       ├── AssigneeKind.swift
│       ├── TaskStatus.swift
│       └── HebrewAddressStyle.swift
│
├── Data/
│   ├── Remote/
│   │   ├── SupabaseClientProvider.swift
│   │   ├── DTO/
│   │   └── Realtime/
│   ├── Local/
│   │   ├── SwiftDataModels/
│   │   └── PendingMutation.swift
│   └── Repositories/
│       ├── AuthRepository.swift
│       ├── CoupleRepository.swift
│       ├── TaskRepository.swift
│       ├── ListRepository.swift
│       └── ProfileRepository.swift
│
├── Services/
│   ├── SyncService.swift
│   ├── PushRegistrationService.swift
│   ├── NotificationActionService.swift
│   ├── CalendarService.swift
│   ├── HapticsService.swift
│   └── LocalizationService.swift
│
├── Features/
│   ├── Auth/
│   ├── Onboarding/
│   ├── CoupleInvite/
│   ├── Main/
│   ├── Week/
│   ├── List/
│   ├── Calendar/
│   ├── TaskEditor/
│   ├── Archive/
│   ├── Trash/
│   ├── Profile/
│   └── Settings/
│
├── DesignSystem/
│   ├── Components/
│   ├── Motion/
│   ├── Typography/
│   ├── Spacing/
│   └── MemberColors.swift
│
├── Localization/
│   ├── Localizable.xcstrings
│   └── CoupleSentenceFormatter.swift
│
└── Resources/
```

### State

Use feature-specific `@Observable` models/stores.

Avoid a single giant app view model.

Example:

```text
SessionStore
WeekViewModel
TaskListViewModel
TaskEditorViewModel
NotificationSettingsViewModel
```

Repositories own data operations.

Views do not call Supabase directly.

---

## 19. Sync Strategy

### Startup

1. Restore auth session.
2. Load cached couple/tasks from SwiftData.
3. Render immediately.
4. Fetch fresh server snapshot.
5. Reconcile cache.
6. Subscribe to Realtime.
7. Flush pending local mutations.

### Optimistic task mutations

For:

- add,
- edit,
- complete,
- reschedule,
- delete,

update UI first, then sync.

If remote mutation fails:

- keep pending state if network-related,
- retry when connectivity returns,
- show unobtrusive sync indicator if needed,
- rollback only on permanent authorization/validation failure.

### Conflict policy

V1 uses last-write-wins at task-record level using server `updated_at`.

Do not build field-level CRDT merging.

If simultaneous edits become a real issue later, add a version column and conflict UI.

### Realtime

Realtime should:

- insert partner-created task,
- update task,
- remove/soft-delete task,
- update list changes.

Avoid full refetch on every event.

Perform periodic full reconciliation:

- app foreground,
- pull-to-refresh,
- after Realtime reconnect.

---

## 20. Onboarding Flow

### New user

```text
Launch
→ Language
→ Sign in
→ Display name
→ Hebrew address style if relevant
→ Accent color
→ Avatar optional
→ Create our space / Join partner
```

### Create

```text
Create our space
→ Couple created
→ Invite screen
→ Share link/code
→ Waiting state
→ Partner joins
→ notification permission prompt
→ app
```

### Join

```text
Open invite / enter code
→ Sign in if needed
→ preview inviter name
→ Accept
→ profile setup
→ notification permission
→ app
```

### Notification permission

Do not show the iOS notification permission prompt on first launch without explanation.

Use a small pre-permission screen after couple setup explaining:

- daily reminders,
- partner task updates.

Then request system permission.

### Calendar permission

Do not request during onboarding.

Ask only when the user first uses `Add to Calendar` or enables calendar settings.

---

## 21. Visual Migration

Use the existing web product as the visual baseline, not a pixel-perfect spec.

Preserve:

- light neutral background,
- compact white task cards,
- rounded geometry,
- member color cues,
- emoji list concept,
- restrained hierarchy,
- simple top mode switch,
- bottom-sheet task creation,
- sentence-based week view.

Improve natively:

- safe areas,
- native sheet detents,
- keyboard avoidance,
- interactive dismissal,
- swipe actions,
- contextual menus,
- springs,
- haptics,
- Dynamic Type,
- native date/time pickers,
- calendar UI,
- loading/reconnect behavior.

Do not import React/Tailwind measurements blindly.

Create a small design system with semantic tokens before polishing every screen.

---

## 22. Accessibility

Accessibility is required even though the first design is compact.

Implement:

- VoiceOver labels for assignee color dots,
- do not communicate assignment by color alone,
- Dynamic Type,
- sufficient touch targets,
- Reduce Motion handling,
- Reduce Transparency fallback where needed,
- clear destructive labels,
- locale-aware date formatting,
- accessibility actions for Complete/Edit/Delete,
- keyboard focus correctness in task composer.

Do not force tiny fixed typography because the current prototype uses small pixel values.

---

## 23. AI

No AI dependency in v1.

Do not call a remote LLM for:

- summaries,
- task parsing,
- categorization.

The current week-summary concept can be implemented deterministically.

Future optional feature:

- on-device Apple Foundation Models for natural-language task entry or summary rewriting,
- only behind availability checks,
- never required for core task behavior.

Example future input:

```text
Buy wine tomorrow for Omer 🍷
```

Potential parser output:

```json
{
  "title": "Buy wine",
  "due": "tomorrow",
  "assignee": "partner",
  "list": "🍷"
}
```

Keep this out of initial scope.

---

## 24. Testing Strategy

### Unit tests

Required:

- assignment validation,
- weekly grouping,
- Today/Tomorrow calculations,
- overdue calculation,
- Hebrew sentence formatter,
- English sentence formatter,
- neutral Hebrew mode,
- archive/trash filters,
- notification schedule calculation across timezones,
- notification dedupe key generation,
- task sorting,
- emoji validation,
- DTO mapping,
- sync reconciliation.

### Integration tests

Required:

- Sign in with Apple mocked/service abstraction,
- create couple,
- accept invite,
- reject third member,
- create task,
- partner receives Realtime update,
- edit task,
- complete task,
- offline queue flush,
- RLS access from unrelated account denied,
- trash/restore,
- reminder dispatch only once,
- partner push excludes actor.

### UI tests

Critical flows:

1. first user creates space,
2. partner joins,
3. add task,
4. assign partner,
5. add date,
6. complete via swipe,
7. edit task,
8. switch week,
9. filter by member,
10. change Hebrew/English direction,
11. add to calendar,
12. open push deep link.

### Device testing

At minimum:

- two physical iPhones,
- two Apple IDs,
- development APNs,
- production/TestFlight APNs,
- poor network,
- airplane mode,
- Hebrew device,
- English device,
- different timezones if possible.

Real two-device testing is mandatory before TestFlight release.

---

# 25. Implementation Plan

Each phase should end in a runnable state and a clean commit.

---

## Phase 0 — Preserve reference and create new repository

### Tasks

- Create fresh GitHub repository: `couples-todo-ios`.
- Keep it private during active development unless intentionally open-sourcing.
- Add:
  - README,
  - `.gitignore`,
  - `MIGRATION_PLAN.md`,
  - architecture notes folder,
  - issue template optional.
- Link the original repository in README as historical prototype.
- Create Xcode project.
- Configure bundle ID placeholder.
- Configure development team.
- Set deployment target to iOS 18.
- Add Swift Package Manager dependency for Supabase Swift.
- Add initial test targets.

### Acceptance

- Clean clone builds.
- Empty app launches on physical iPhone.
- No secrets committed.

### Commit

```text
chore: bootstrap native iOS project
```

---

## Phase 1 — Design system + static app shell

### Build

- semantic colors,
- typography,
- spacing,
- card shape,
- member color component,
- task checkbox,
- haptic abstraction,
- main header,
- view switcher,
- Week/List/Calendar empty shells,
- task composer shell.

Use mock local data only.

### Acceptance

- English and Hebrew previews.
- RTL layout works.
- Dynamic Type does not destroy main layout.
- Reduce Motion respected.
- Main navigation feels native.

### Commit

```text
feat: build native app shell and design system
```

---

## Phase 2 — Domain models and local prototype

Implement domain models and SwiftData cache.

Build full local-only task functionality:

- create,
- edit,
- complete,
- delete,
- undo,
- trash,
- restore,
- emoji lists,
- date/time,
- filters,
- search.

No auth/backend yet.

### Acceptance

App is already a usable single-device to-do app.

Restarting app preserves data.

### Commit

```text
feat: implement local task domain and persistence
```

---

## Phase 3 — Week and calendar experiences

### Week

- current week,
- swipe weeks,
- grouping,
- localized sentence formatter,
- completed-this-week,
- Today emphasis,
- overdue state.

### Calendar

- month grid,
- task indicators,
- selected day agenda,
- task editor navigation.

### Acceptance

All three main views are fully functional with local data.

### Commit

```text
feat: complete week list and calendar task views
```

---

## Phase 4 — Fresh Supabase project + schema

Create a **new Supabase project** rather than reusing the personal app schema.

Add local Supabase CLI setup.

Create migrations for:

- profiles,
- couples,
- couple_members,
- couple_invites,
- lists,
- tasks,
- notification_preferences,
- device_tokens,
- notification_deliveries.

Enable RLS.

Add policies.

Enable required Realtime tables.

Add updated-at triggers carefully.

### Mandatory verification

Create three test users:

```text
A
B
C
```

A + B share Couple 1.

C must be unable to:

- select Couple 1,
- select tasks,
- update tasks,
- insert tasks into Couple 1,
- read device tokens.

### Acceptance

Security tests pass.

### Commit

```text
feat: add secure Supabase schema and RLS
```

---

## Phase 5 — Authentication and profiles

Implement Supabase Auth.

### Features

- Sign in with Apple,
- email magic link fallback,
- session restore,
- sign out,
- profile creation,
- avatar upload,
- member color,
- language,
- Hebrew address style.

### Acceptance

- clean install sign-in works,
- reinstall restores session when expected,
- Apple credential revocation/error handled,
- no password UI,
- profile persists.

### Commit

```text
feat: add authentication and user profiles
```

---

## Phase 6 — Couple creation and invitation

Implement:

- create couple,
- invite generation,
- short code,
- share sheet,
- universal/deep link handling,
- join flow,
- revoke/regenerate,
- two-member limit.

The invite acceptance operation should be server-authoritative.

### Acceptance

- A creates couple,
- B joins,
- C cannot join afterward,
- expired invite fails clearly,
- reused invite fails,
- wrong code doesn't leak couple data.

### Commit

```text
feat: implement secure couple pairing
```

---

## Phase 7 — Shared task repository + sync

Replace local-only repository with synchronized repository.

Implement:

- server snapshot,
- SwiftData cache,
- optimistic writes,
- pending mutation queue,
- Realtime channel,
- reconnect reconciliation.

### Acceptance

Two devices:

1. A adds task -> B sees it quickly.
2. B edits -> A updates.
3. A completes -> B updates.
4. One device offline -> local edits queue.
5. Reconnect -> edits upload.
6. Duplicate Realtime events do not duplicate rows.

### Commit

```text
feat: add realtime couple task sync
```

---

## Phase 8 — Notification preferences + APNs registration

Implement iOS permission and device token handling.

Build Notification Settings:

- evening-before enabled/time,
- morning-of enabled/time,
- evening-of enabled/time,
- assignment pushes,
- date-change pushes,
- completion pushes,
- badge.

Register token with backend.

Delete/refresh stale tokens.

### Acceptance

- notification permission denied state works,
- Settings links to system settings,
- token updates stored for correct user,
- sign-out removes or disables device token.

### Commit

```text
feat: add push registration and notification preferences
```

---

## Phase 9 — Immediate partner notifications

Create Edge Function for task activity.

Detect meaningful transitions:

```text
created assigned-to-recipient
reassigned-to-recipient
due-date changed
completed
uncompleted
```

Send direct APNs.

Add deep-link payload:

```text
task_id
couple_id
event_type
```

### Acceptance

- actor never receives duplicate self notification,
- partner receives expected notification,
- unrelated users receive nothing,
- tapping push opens correct task,
- push language matches recipient preference.

### Commit

```text
feat: add targeted partner task notifications
```

---

## Phase 10 — Scheduled daily reminders

Create Cron dispatcher.

Implement:

- timezone-aware reminder windows,
- task aggregation,
- localization,
- notification delivery dedupe,
- APNs send,
- badge count.

### Acceptance

For one test date:

- evening-before arrives once,
- morning arrives once,
- evening arrives once,
- disabled slot sends nothing,
- changing user time changes next delivery,
- completed tasks disappear from later summary,
- tasks added before a later slot appear in later summary.

### Commit

```text
feat: add configurable daily couple reminders
```

---

## Phase 11 — Notification actions

Implement notification categories/actions.

### Single-task due push

- Done
- Tomorrow
- Open

### Aggregate summary

- Open

### Partner event

- Open

Actions must authenticate against normal backend rules.

### Acceptance

- Done updates partner in Realtime.
- Tomorrow correctly changes due date.
- Action failures are recoverable.
- No mutation occurs for stale/deleted tasks.

### Commit

```text
feat: add interactive notification actions
```

---

## Phase 12 — Calendar export

Implement EventKit/EventKitUI.

Task action:

```text
Add to Calendar
```

Support:

- all-day task,
- timed task,
- notes,
- system calendar picker/editor.

Do not implement two-way sync.

### Acceptance

Test with:

- iCloud calendar,
- Google calendar added to iOS,
- calendar permission rejected,
- task with date only,
- task with date and time.

### Commit

```text
feat: add native calendar export
```

---

## Phase 13 — Polish pass

Focus only on quality.

Review:

- task completion animation,
- insertion/deletion,
- week paging,
- date picker,
- emoji picker,
- keyboard,
- swipe thresholds,
- haptics,
- loading,
- skeletons only where useful,
- offline indicator,
- reconnect,
- empty states,
- errors,
- permission states,
- invite waiting state.

Compare side-by-side with original web product and preserve its warmth/minimality.

### Acceptance

No major interaction feels like a web app recreated in SwiftUI.

### Commit

```text
refactor: polish native interactions and motion
```

---

## Phase 14 — Accessibility, localization and copy QA

Audit:

- English,
- Hebrew masculine,
- Hebrew feminine,
- Hebrew neutral,
- RTL,
- VoiceOver,
- Dynamic Type,
- Reduce Motion,
- date formats,
- long names,
- long task titles.

### Commit

```text
fix: complete localization and accessibility audit
```

---

## Phase 15 — App Store / TestFlight readiness

### Technical

- production Supabase environment,
- production APNs,
- associated domains,
- universal links,
- App Store bundle ID,
- release configuration,
- logging strategy,
- crash reporting decision,
- privacy manifest review,
- delete-account flow,
- privacy policy,
- terms if needed.

### Product

- app icon,
- screenshots,
- App Store description,
- notification copy review,
- onboarding review,
- TestFlight group.

### Data/privacy

Document:

- account data,
- task content,
- profile data,
- push tokens,
- avatar storage,
- calendar permission behavior.

Provide in-app account deletion.

### Acceptance

Submit a TestFlight build and complete two-person real-world usage for several days before App Store submission.

### Commit

```text
chore: prepare first TestFlight release
```

---

# 26. Agent Execution Rules

This project is expected to be built mainly by a coding agent.

The agent should follow these rules.

## Work in vertical slices

Do not generate the entire application in one huge pass.

Each phase must:

1. compile,
2. run,
3. have tests where relevant,
4. preserve previous working behavior,
5. end with a scoped commit.

## Do not guess backend behavior

Before changing Supabase:

- inspect current Supabase documentation,
- create schema changes through proper migrations,
- run RLS/security tests,
- verify Realtime behavior.

## Do not put backend access directly in views

All remote mutations go through repositories/services.

## Avoid unnecessary dependencies

Do not add:

- architecture frameworks,
- third-party animation frameworks,
- third-party date libraries,
- networking wrappers,

unless there is a demonstrated need.

Supabase Swift is the main external SDK.

## Never commit secrets

Safe client configuration can be injected through build configuration.

Never commit:

- Supabase service role,
- APNs private key,
- APNs signing secret,
- production server secrets.

## Keep files small

If a SwiftUI screen becomes large, split by reusable visual/behavioral responsibility.

Avoid reproducing the original giant `App.tsx` pattern.

---

# 27. Proposed First Repository Issues

Create these issues/milestones after repository setup.

1. Bootstrap Xcode project
2. Design tokens and main shell
3. Local Task model + SwiftData
4. Native task composer
5. Task card interactions
6. List filters + Someday
7. Week sentence formatter
8. Swipeable Week view
9. Calendar month/agenda
10. Archive + Trash
11. Localization + RTL
12. Supabase schema
13. RLS security tests
14. Sign in with Apple
15. Profile setup
16. Couple invitation
17. Shared task repository
18. Realtime sync
19. Offline mutation queue
20. Push token registration
21. Notification settings
22. Partner event Edge Function
23. APNs sender
24. Daily reminder Cron
25. Notification actions
26. Calendar export
27. Accessibility pass
28. TestFlight release checklist

---

# 28. Recommended V1 Defaults

Use these unless testing indicates otherwise.

```text
Home: Week
Week starts: locale-aware; Hebrew default Sunday, English locale-aware
Add-task default assignee: Together
Together completion: either partner can complete
No-date group: Someday
Completed on List: collapsed
Full completed history: Archive
Deleted tasks: Trash
Trash retention: 30 days
Morning reminder: 10:00
Evening reminder: 18:30
Evening-before reminder: 21:00
Partner assignment pushes: On
Partner completion pushes: On
Date-change pushes: On
Badge: Off by default
Language: onboarding selection
Calendar export: manual
AI: Off / absent
Dark mode: not in v1
```

---

# 29. Product Questions to Revisit Only After Real Usage

Do not block v1 on these.

Measure actual behavior first.

1. Do couples need true "both members must complete" tasks?
2. Are three daily reminders too many for most people?
3. Do people want recurring tasks badly enough to add them?
4. Do emoji lists need names?
5. Is Week truly the best default after several weeks of usage?
6. Do people need comments on tasks?
7. Do people want a real activity feed?
8. Is automatic calendar export desirable?
9. Do people need direct Google Calendar integration outside EventKit?
10. Does natural-language task entry materially improve speed?
11. Do users want widgets before any other platform expansion?
12. Is a shared shopping-specific experience worth separating from tasks?

---

# 30. Migration Definition of Done

The migration is complete when all of the following are true:

- the native app can be installed from TestFlight,
- two unrelated users can create accounts,
- they can pair into exactly one couple,
- no third user can access that couple,
- either user can create/edit/complete shared tasks,
- partner changes appear in near real time,
- app remains usable through short offline periods,
- Week/List/Calendar all work,
- Hebrew RTL and English LTR both work,
- personalized daily reminders are reliable,
- partner event pushes are correctly targeted,
- notification actions work,
- task history is archived,
- deletion is recoverable,
- calendar export works for calendars configured on iOS,
- the old web app is no longer required,
- no production secret exists in the client repository,
- the UI feels like a native product rather than a wrapped/recreated website.

---

# 31. Immediate Next Action

Do **not** begin by porting React components one by one.

Start with:

```text
1. Create fresh repository.
2. Create native SwiftUI project.
3. Implement the static Week/List/Calendar shell.
4. Implement local Task domain + SwiftData.
5. Recreate the core UX locally.
6. Only then introduce the new secure backend.
```

This gives the project a native product foundation before backend complexity is introduced.

The original `omer_noam` app should remain open next to the native build as a behavior/visual reference throughout Phases 1–3.
