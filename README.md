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

## Walkthrough Video Placeholder

<!-- Add link to screen recording demonstrating:
     1. Offline submission → queue banner after restart
     2. Sync + pull-to-refresh
     3. Moderator local vs online status
     4. Offline answer staleness warning
-->

_TODO: Insert walkthrough video URL before submission._
