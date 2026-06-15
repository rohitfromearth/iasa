# IASA Healthcare

Offline-first Flutter application for the IASA SDE-2 technical assessment. The app demonstrates clean architecture, SQLite-backed offline reliability, honest healthcare UX, and Provider-based state management.

## Project Overview

Warriors submit healthcare questions that are queued locally when offline and synchronized when connectivity returns. Moderators review an open-case queue and update workflow status on device. Cached clinical answers always show synchronization metadata and offline staleness warnings.

**Stack:** Flutter · Dart 3.12 · Provider · sqflite · connectivity_plus · uuid · shared_preferences

## Architecture

```
lib/
├── main.dart, app.dart
├── injection/injection.dart     # Provider dependency graph
├── core/                        # Database, auth, network, Result<T>
├── domain/                      # Entities, use cases, repository contracts
├── data/                        # Repository impl, local/remote datasources
└── presentation/                # Screens, providers, widgets, theme
```

**Dependency rule:** Presentation → Domain → Data → Datasources. Domain has no Flutter imports.

**State management:** Four `ChangeNotifier` providers (`AuthProvider`, `CaseListProvider`, `CaseDetailProvider`, `SubmissionProvider`) with `Selector` for targeted rebuilds.

## Features

| Area | Capability |
|------|------------|
| **Authentication** | Demo login, session restore via `SharedPreferences`, role-based navigation |
| **Warrior** | Case list, case detail, submit question, photo/file attachments, offline outbox |
| **Moderator** | Open-case queue, local status updates with online/local comparison |
| **Sync** | Manual queue sync, pull-to-refresh (outbox sync + remote refresh), idempotent UUID submissions |
| **Integrity** | `lastSyncedAt` / `verifiedAt` display, offline answer warning banner, queued-not-successful messaging |

## Offline Reliability Features

- **SQLite outbox** — `pending_submissions` table stores write intents before network confirmation
- **UUID idempotency** — client-generated IDs prevent duplicate server records on retry
- **Crash recovery** — stuck `syncing` rows reset to `pending` on next sync pass
- **Startup hydration** — `SubmissionProvider` loads persisted outbox on app launch so `PendingSyncBanner` works after cold restart
- **Local vs online status** — `status` (local) and `online_status` (last server-confirmed) stored separately; refresh merge preserves unsynced local moderator edits
- **Honest UI** — submissions show *"Submission queued. Waiting for confirmation."* never premature server success

## Demo Credentials

**Not production authentication.** Used for role-based navigation only.

| Email | Password | Role |
|-------|----------|------|
| warrior@iasa.com | password123 | Warrior → Case List |
| moderator@iasa.com | password123 | Moderator → Moderator Queue |

Session restores on launch: `SplashScreen` → `SharedPreferences` → home or login.

## Running The Project

```bash
flutter pub get
flutter analyze
flutter run
```

## Running Tests

```bash
flutter test
```

Uses `sqflite_common_ffi` for in-memory SQLite in unit tests. No device emulator required for the test suite.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| SQLite outbox over separate `sync_queue` table | Single outbox type; YAGNI |
| UUID as sole identity + idempotency key | No offline/online ID reconciliation |
| No premature submission success | Healthcare trust over perceived speed |
| `verifiedAt` / `lastSyncedAt` disclosure | Cached data must not imply clinical currency |
| Provider over Riverpod/Bloc | Assessment constraint + proportional complexity |
| Moderator status persisted locally only | SQLite durability without expanding mock API contract |
| Manual sync + pull-to-refresh | Demonstrates controlled sync without background workers |

See `DESIGN_DOCUMENT.md` for full architecture reasoning, rejected alternatives, and tradeoffs.

## Known Limitations

- Demo auth only — no server-side credential validation
- Moderator status changes are not pushed to the API
- Mock API state is in-memory — remote data lost on app restart until local refresh/sync
- No background sync on connectivity restoration
- No encryption at rest (plaintext SQLite)
- No push/local notifications — in-app banners and SnackBars only
- Sequential sync with no exponential backoff

## Track B Walkthrough

### Introduction 

Hello, my name is Rohit.

For Track B, I built an offline-first Flutter application that simulates the Cancer Warrior and Moderator workflow.

The main goal of the project was not feature count, but correctness under unreliable network conditions and maintaining user trust in a healthcare-adjacent application.

The app uses Flutter, Provider, Clean Architecture-inspired layering, SQLite persistence, and a mock API.

---

### Architecture Overview 

The application is organized into four layers:

**Presentation:**
Screens, widgets, and Provider-based state management.

**Domain:**
Entities, use cases, repository contracts, and business rules.

**Data:**
Repository implementation, local datasource, and mock API datasource.

**Core:**
Database, networking utilities, authentication, state wrappers, and shared infrastructure.

Providers never talk directly to SQLite or APIs.
All interactions flow through use cases and repository abstractions.

This structure keeps the code testable and makes replacing the mock API with a real backend straightforward.

---

### Warrior Flow Demo 

A Warrior can log in, view their case list, open case details, and submit a new question.

When submitting a question:

- Validation is performed locally.
- A UUID is generated immediately.
- The submission is stored in SQLite.
- The user receives a message that the submission has been queued.

The application never claims the submission was successfully delivered to the server before synchronization actually occurs.

This was a deliberate healthcare trust decision.

---

### Offline Submit

One of the main design challenges was the offline submit race.

A user may submit while offline, reopen the application, and attempt to submit again because they believe the first submission failed.

To address this:

- Every submission receives a UUID before any network interaction.
- The UUID acts as both the local identifier and idempotency key.
- Pending submissions are stored in an outbox table.
- Synchronization reuses the same UUID.

If synchronization retries after a crash or connectivity issue, the server treats the request as the same submission rather than creating duplicates.

This provides exactly-once behavior from the user's perspective.

---

### Stale Answer Integrity 

Another important challenge was stale clinical data.

The application may contain a cached answer while the device is offline.

To avoid misleading the user:

- Every answer displays synchronization metadata.
- `lastSyncedAt` is shown.
- `verifiedAt` is shown.
- An offline warning banner appears when viewing a cached answer without connectivity.

The application never assumes locally cached data is current simply because it exists on the device.

---

### Local vs Online Status 

Moderator updates are stored locally and persisted in SQLite.

To avoid confusing local changes with server-confirmed changes:

- `status` represents local state.
- `onlineStatus` represents last server-confirmed state.

The UI can display both values and indicate when a local change has not yet been synchronized.

This makes synchronization state transparent to the user.

---

### State Management and Scalability 

State management uses four focused providers:

- `AuthProvider`
- `CaseListProvider`
- `CaseDetailProvider`
- `SubmissionProvider`

Each provider owns a specific concern.

`Selector` is used to limit rebuilds to only the portions of UI that need updates.

This keeps the state model manageable as the application grows.

---

### Testing and Reliability 

The project currently contains 43 automated tests covering:

- Providers
- Repositories
- Local persistence
- Database migrations
- Synchronization flows
- Widget behavior

The goal was to verify the critical reliability paths rather than only testing UI rendering.

---

### Self Critique 
The two weakest parts of the submission are:

First, moderator status changes are persisted locally but are not synchronized back to the server.

With more time I would implement a moderator outbox similar to the warrior submission flow.

Second, synchronization is manual.

A production system should automatically synchronize when connectivity is restored, using retry and backoff strategies.

I intentionally kept synchronization manual because it is easier to reason about, test, and demonstrate during the assessment.

---

### Closing

The main principle behind this project is:

Record intent locally, synchronize with idempotency, and tell the user the truth about what the system knows.

Thank you for reviewing my submission.

---

## Walkthrough Recording

Screen recording demonstrating offline submission, sync, local vs online status, and stale answer handling:

[IASA Track B Walkthrough](https://drive.google.com/file/d/1oUVIPomt7qCEpXzwcMGSPO8zvJwEznjC/view?usp=sharing&t=14.099)
