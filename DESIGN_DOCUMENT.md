# IASA Healthcare — Design Document

**Submission:** IASA SDE-2 Technical Assessment  
**Project:** `iasa` — Offline-first healthcare workflow (Flutter)  
**Stack:** Flutter 3.44 (stable) · Dart 3.12 · Provider · sqflite · connectivity_plus · uuid · shared_preferences

---

## 1. Executive Summary

This application demonstrates engineering judgement for a clinical-adjacent, offline-first mobile workflow. The core problem is not feature breadth: a warrior must be able to submit a healthcare question when connectivity is absent or unreliable, and must never be misled into believing a submission reached a server before it actually has.

The solution applies Clean Architecture–inspired layering with strict dependency direction, SQLite as the system of record on device, a pending-submission outbox for write operations, and UUID-based idempotency for retry-safe synchronization. The UI is intentionally honest: users see *"Submission queued. Waiting for confirmation."* rather than premature success messaging, and cached clinical answers carry explicit synchronization metadata plus an offline staleness warning.

State is managed through four focused `ChangeNotifier` providers wired via `MultiProvider`, with `Selector` used to minimize rebuild scope. A mock API simulates latency and intermittent failure to validate retry and idempotency behaviour without requiring a live backend.

The assessment prioritizes **correctness over polish**. Several production gaps are documented openly in Section 13 rather than hidden behind optimistic abstractions.

---

## 2. Architecture Overview

### 2.1 Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION                                │
│  Screens · Widgets · AuthProvider · CaseListProvider            │
│          CaseDetailProvider · SubmissionProvider                │
└────────────────────────────┬────────────────────────────────────┘
                             │ use cases only (no repository calls)
┌────────────────────────────▼────────────────────────────────────┐
│                       DOMAIN                                    │
│  CaseEntity · PendingSubmission · Enums · CaseRepository (abs)  │
│  GetCases · RefreshCases · SubmitQuestion · SyncPending · GetPending │
│  UpdateCaseStatus                                                  │
└────────────────────────────▲────────────────────────────────────┘
                             │ implements
┌────────────────────────────┴────────────────────────────────────┐
│                        DATA                                     │
│  CaseRepositoryImpl · CaseLocalDataSource · MockApiDataSource   │
│  CaseModel · PendingSubmissionModel                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                        CORE                                     │
│  DatabaseHelper · NetworkInfo · UuidGenerator · Result/Failure  │
│  UiState · DatabaseConstants                                    │
└─────────────────────────────────────────────────────────────────┘
```

**Dependency rule:** dependencies point inward. Widgets never call repositories or data sources directly. Domain entities contain no Flutter imports.

### 2.2 Provider Architecture

`Injection.providers()` composes the graph in dependency order:

| Registration | Type | Role |
|---|---|---|
| Core | `DatabaseHelper`, `NetworkInfo`, `UuidGenerator` | Infrastructure |
| Data | `CaseLocalDataSource`, `ApiDataSource`, `CaseRepository` | Persistence + remote |
| Domain | `GetCasesUseCase`, `RefreshCasesUseCase`, `SubmitQuestionUseCase`, `SyncPendingSubmissionsUseCase`, `GetPendingSubmissionsUseCase`, `UpdateCaseStatusUseCase` | Application services |
| Presentation | `AuthProvider`, `CaseListProvider`, `CaseDetailProvider`, `SubmissionProvider` | UI state |

Providers are **feature-scoped**, not monolithic. Each owns a coherent slice of UI state and delegates mutations to use cases.

### 2.3 Repository Architecture

`CaseRepository` is the single write/read orchestration boundary:

| Method | Behaviour |
|---|---|
| `getCases()` | Read all cases from SQLite |
| `getPendingSubmissions()` | Read outbox rows (`pending` / `failed`) for provider hydration |
| `submitQuestion()` | Insert into `pending_submissions` only — **no network** |
| `syncPendingSubmissions()` | Push outbox to API; upsert confirmed cases locally |
| `refreshCases()` | Pull remote cases when online; merge into SQLite |
| `updateLocalCaseStatus()` | Persist moderator workflow change locally; preserve `onlineStatus` |

`CaseRepositoryImpl` maps `AppException` → `Failure` and returns `Result<T>` rather than throwing across layer boundaries. This keeps providers free of try/catch boilerplate while preserving explicit error channels.

### 2.4 Data Flow

**Read path (offline-safe):**

```
Screen → Provider → GetCasesUseCase → CaseRepository → CaseLocalDataSource → SQLite
```

**Write path (offline-first):**

```
SubmitQuestionScreen → SubmissionProvider → SubmitQuestionUseCase
  → CaseRepository.submitQuestion()
  → INSERT pending_submissions (sync_status = pending)
  → return PendingSubmission immediately
```

**Sync path (connectivity-gated):**

```
SubmissionProvider / CaseListScreen → SyncPendingSubmissionsUseCase
  → NetworkInfo.isConnected? ──no──► NetworkFailure
  → resetStuckSyncingSubmissions()
  → for each pending|failed submission:
        mark syncing → API(idempotencyKey) → upsert cases → mark synced|failed
```

**Refresh path:**

```
CaseListProvider.refreshCases() → RefreshCasesUseCase
  → API.fetchCases() → upsert cases with refreshed lastSyncedAt
```

---

## 3. Data Model

### 3.1 CaseEntity

Represents a healthcare case stored locally (and confirmed remotely after sync).

| Field | Type | Purpose |
|---|---|---|
| `id` | `String` | Client UUID; primary identity and idempotency key |
| `title` | `String` | Case label |
| `questionBody` | `String` | Warrior's question |
| `answerBody` | `String?` | Moderator response when available |
| `status` | `CaseStatus` | Local workflow state on this device |
| `onlineStatus` | `CaseStatus?` | Last status confirmed from server |
| `createdByRole` | `UserRole` | Originating role |
| `syncStatus` | `SyncStatus` | Local transport state for this record |
| `createdAt` / `updatedAt` | `DateTime` | Temporal metadata |
| `lastSyncedAt` | `DateTime?` | Last successful sync timestamp — **displayed to user** |
| `verifiedAt` | `DateTime?` | Server verification of answer — **displayed to user** |

**Design choice:** `serverId` was deliberately omitted. A single client UUID serves as both local primary key and idempotency key, eliminating identity reconciliation complexity in an offline-first context.

### 3.2 PendingSubmission

Represents an outbox entry — a write intent not yet server-confirmed.

| Field | Type | Purpose |
|---|---|---|
| `id` | `String` | UUID idempotency key (generated before any network call) |
| `caseId` | `String?` | `null` for new cases; set after sync for follow-ups |
| `title` / `questionBody` | `String` | Submission payload |
| `submittedByRole` | `UserRole` | Audit consistency |
| `syncStatus` | `SyncStatus` | Outbox transport state |
| `attemptCount` | `int` | Retry counter |
| `lastAttemptAt` | `DateTime?` | Last sync attempt |
| `lastError` | `String?` | User-visible failure message |
| `createdAt` | `DateTime` | Queue insertion time |
| `photos` / `attachments` | Lists | Local media paths; child tables in SQLite |

### 3.3 Enums

**CaseStatus** (workflow): `submitted` · `inReview` · `underDiscussion` · `answered` · `rejected` · `closed`

**UserRole**: `warrior` · `moderator`

**SyncStatus** (transport): `pending` · `syncing` · `synced` · `failed`

**Separation rationale:** A case can be `answered` on the server while a follow-up edit remains `pending` locally. Conflating workflow and transport state into one enum would obscure offline behaviour.

### 3.4 SQLite Schema

**Database version:** 4 (`AppConstants.databaseVersion`)

| Table | Role |
|---|---|
| `cases` | Cached/confirmed case read model |
| `pending_submissions` | Warrior outbox (`FK` → `cases`, `ON DELETE SET NULL`) |
| `pending_submission_photos` | Photo attachments for outbox rows |
| `pending_submission_attachments` | Document attachments for outbox rows |

A separate `sync_queue` table was considered and **rejected** (see Section 12). `pending_submissions` is the outbox for this assessment scope.

**Migration history:**

| Version | Change |
|---|---|
| v1 | Core tables + indexes |
| v2 | `online_status` column on `cases` (local vs server status split) |
| v3 | Media child tables for offline attachment queuing |
| v4 | `upload_status` / `uploaded_at` on media rows |

**Why media tables:** Submit-question attachments must survive offline queueing the same way text does. Storing paths in child tables keeps the outbox transactional (submission + media inserted atomically) and allows per-file upload retry without denormalizing JSON blobs into `pending_submissions`.

DDL is defined in testable `DatabaseConstants.schemaV1Statements` plus versioned `onUpgrade` steps in `DatabaseHelper`.

---

## 4. Offline-First Strategy

### 4.1 SQLite Persistence

All cases and pending submissions survive process death. `DatabaseHelper` opens a singleton database at app documents path with `PRAGMA foreign_keys = ON`. Schema DDL lives in testable `DatabaseConstants.schemaV1Statements`.

**Why SQLite over shared_preferences or files:** Structured queries, indexed lookups, transactional inserts, and foreign-key integrity for healthcare records that must not be silently corrupted.

### 4.2 Restart Recovery

On cold start:

1. `SplashScreen` calls `SubmissionProvider.hydratePendingSubmissions()` — outbox counts match SQLite before any screen renders.
2. `getCases()` reads whatever was last persisted in `cases`.
3. `pending_submissions` rows in `pending` or `failed` state remain in the outbox.
4. `syncPendingSubmissions()` can be invoked manually (sync button / pull-to-refresh) to resume the queue.

`resetStuckSyncingSubmissions()` runs at the start of every sync pass, converting any `syncing` rows back to `pending`. This handles crash mid-sync without leaving the outbox permanently stuck.

### 4.3 Pending Submission Queue

The outbox pattern decouples user intent from network availability:

```
User taps "Queue Submission"
  → UUID generated
  → row inserted (pending)
  → UI shows queued message
  → [later, when online] sync worker processes queue
```

The queue is FIFO-ordered by `created_at`. Indexes on `(sync_status, created_at)` support efficient worker queries.

---

## 5. Offline Submission Race

### 5.1 Problem

A warrior may tap submit while offline, then connectivity returns before the user navigates away. Concurrently, a background sync may start. Without coordination, the same submission could be:

- Inserted twice locally
- Sent to the server twice
- Marked successful in UI before server acknowledgement

### 5.2 Risks

| Risk | Consequence |
|---|---|
| Duplicate server records | Clinical data integrity violation |
| Lost submissions | User believes question was sent; it was not |
| Stuck `syncing` state | Queue halts after crash |
| False success UI | User acts on unconfirmed data |

### 5.3 Idempotency Key Strategy

Every submission receives a UUID **before** any network call. That UUID is:

1. The `pending_submissions` primary key (DB-level duplicate prevention)
2. The `idempotencyKey` sent to `ApiDataSource.submitQuestion()`
3. The `CaseEntity.id` after successful sync

`MockApiDataSource` maintains an in-memory `Map<idempotencyKey, CaseModel>`. Duplicate keys return the existing case without creating a new record — simulating server-side idempotent behaviour.

### 5.4 Why UUID Was Chosen

| Alternative | Rejected because |
|---|---|
| Auto-increment integer | Requires server assignment; unavailable offline |
| Timestamp-based ID | Collision risk under rapid taps |
| Hash of content | Different retries of same intent produce different hashes |
| Separate idempotency key + case ID | Adds reconciliation logic without benefit at this scale |

UUID v4 provides collision-resistant, client-generatable, opaque identifiers that work identically offline and online. The tradeoff is non-sequential IDs (index locality), which is acceptable for a mobile outbox of modest size.

---

## 6. Stale Clinical Data Integrity

### 6.1 `verifiedAt`

Indicates when a server authority last verified an answer. The UI displays this explicitly via `SyncMetadataPanel`. An answer without `verifiedAt` is labelled *"Not verified"*.

**Why:** In healthcare contexts, presence of text does not imply clinical currency. Verification is a distinct event from synchronization.

### 6.2 `lastSyncedAt`

Records the last successful bidirectional sync for a case. Updated on `refreshCases()` and after successful `syncPendingSubmissions()` merge.

**Why:** Users need to know how old their cached view is, especially when offline for extended periods.

### 6.3 Offline Warning Banner

`CaseDetailScreen` displays `OfflineAnswerBanner` when:

```
answerBody != null  AND  NetworkInfo.isConnected == false
```

Message: *"This answer may have changed since last synchronization."*

### 6.4 Why Cached Answers Are Never Treated as Current

The application does not infer freshness from local presence alone. A cached answer is a **point-in-time snapshot**, not an authoritative clinical statement. Three mechanisms enforce this:

1. **Metadata disclosure** — `lastSyncedAt` and `verifiedAt` are always visible on detail screen.
2. **Explicit warning** — offline + answer triggers the banner.
3. **No silent overwrite** — refresh requires explicit user action (pull-to-refresh / sync button).

This is a deliberate product decision: **under-warning is preferable to over-confidence** in clinical-adjacent UX.

### 6.5 Local vs Online Status Integrity

**Problem:** A moderator may change workflow status locally before any server round-trip. Showing only `status` misrepresents server truth; showing only `onlineStatus` hides work still in progress on device.

| Field | Meaning |
|---|---|
| `status` | Local workflow state — what this device believes the case is now |
| `onlineStatus` | Last status confirmed from the server via sync or `refreshCases` |

**Solution — show both, flag divergence:**

- `CaseStatusDisplay` renders local and online rows side by side.
- `CaseEntity.hasUnsyncedStatusChange` is true when `onlineStatus != null` and `status != onlineStatus`.
- `UpdateCaseStatusUseCase` → `updateLocalCaseStatus()` writes to SQLite, sets `syncStatus: pending`, preserves `onlineStatus`.
- `refreshCases` merge (`_mergeRemoteCase`) keeps local `status` when a pending local change exists; updates `onlineStatus` from remote.

**Tradeoffs:**

| Choice | Benefit | Cost |
|---|---|---|
| Dual columns vs single status | Honest about unsynced moderator work | More UI surface |
| Local wins on merge | Moderator edits not silently overwritten by refresh | Server may have moved on; conflict resolution deferred |
| No moderator API sync (this build) | Scope contained; warrior path fully exercised | Status never reaches server — documented limitation |

---

## 7. Honest UI vs Optimistic UI

### 7.1 What Is Optimistic

| Action | Optimistic element |
|---|---|
| Queue submission | Form accepts input and returns immediately after local persist |
| Case list display | Shows locally cached cases without waiting for network |
| Moderator status update | Local status written to SQLite immediately; online status preserved |

Local persistence is optimistic in the sense that the device acts on user intent immediately, trusting SQLite durability.

### 7.2 What Is Not Optimistic

| Action | Behaviour |
|---|---|
| Submission confirmation | Never shows "Submission Successful" before server sync |
| Answer freshness | Never implies cached answer is current when offline |
| Sync result | Reports `syncedCount` and `failedCount` honestly |
| Network failures | Surfaces `lastError` on failed submissions |

### 7.3 Why Submission Success Is Never Shown Before Sync

Showing success before server confirmation creates a **false sense of clinical closure**. The user might:

- Navigate away believing a clinician received the question
- Make decisions based on a submission that failed silently
- Lose trust in the application after discovering the discrepancy

The queued message — *"Submission queued. Waiting for confirmation."* — accurately represents system state: the intent is recorded locally; confirmation is pending. This aligns with the assessment's healthcare trust rules.

---

## 8. Synchronization Design

### 8.1 Retry Strategy

Sync is **manual-triggered** (sync button / pull-to-refresh) rather than background-scheduled. Each invocation:

1. Gates on `NetworkInfo.isConnected`
2. Resets stuck `syncing` rows
3. Loads `pending` + `failed` submissions
4. Processes sequentially with per-item try/catch

**Pull-to-refresh flow (warrior + moderator):**

```
Pull To Refresh
  → syncPendingSubmissions()     (push outbox)
  → hydratePendingSubmissions()  (reconcile provider with SQLite)
  → refreshCases()               (pull remote, merge into SQLite)
  → UI updates via CaseListProvider
```

Failed items increment `attemptCount`, store `lastError`, and remain in the outbox for the next sync pass. There is no exponential backoff in this assessment build — a production system would add jittered backoff and max-retry policies.

### 8.2 Failure Handling

| Layer | Failure type | Handling |
|---|---|---|
| API | `NetworkException` | Mark submission `failed`, store message |
| Repository | `NetworkFailure` | Return `Error` to provider |
| Provider | `lastError` | Display in UI; submission remains retryable |
| Mock API | ~12.5% random failure | Exercises retry path in development |

`SyncResult` reports `{ syncedCount, failedCount }` without masking partial failure as total success.

### 8.3 Crash Recovery

```
App crash during sync (submission stuck in 'syncing')
  → next syncPendingSubmissions() call
  → resetStuckSyncingSubmissions()  (syncing → pending)
  → submission reprocessed with same UUID/idempotency key
```

Because the idempotency key is stable, a crash after server acceptance but before local mark-synced will not create duplicates on retry.

### 8.4 Sync Status Lifecycle

**PendingSubmission:**

```
pending ──► syncing ──► synced (terminal for queue purposes)
              │
              └──► failed ──► (retry) ──► syncing ──► ...
```

**CaseEntity.syncStatus:**

Updated to `synced` when merged from a successful API response. Moderator local status changes set `syncStatus: pending` in SQLite until a future API sync (not implemented in this build). See §6.5 for the local/online status model.

### 8.5 Startup Outbox Hydration

On app launch, `SplashScreen` calls `SubmissionProvider.hydratePendingSubmissions()` via `GetPendingSubmissionsUseCase`. This loads `pending` + `failed` rows from SQLite so `pendingSubmissionCount` and `PendingSyncBanner` reflect the persisted outbox after cold restart.

---

## 9. Provider Scalability

### 9.1 Why Multiple Providers

A single global `AppProvider` would couple unrelated concerns: role selection, case listing, detail viewing, and submission queuing. Changes to submission state would rebuild case list widgets unnecessarily.

Four providers enforce **separation of UI concerns**:

| Provider | Owns |
|---|---|
| `AuthProvider` | Session, `currentUser`, role |
| `CaseListProvider` | `UiState<List<CaseEntity>>`, refresh flag, moderator filter |
| `CaseDetailProvider` | `UiState<CaseEntity>`, local status update |
| `SubmissionProvider` | Outbox tracking (hydrated from SQLite on launch), sync flags, queue counts |

### 9.2 Rebuild Minimization

- `notifyListeners()` is called only when state actually changes (equality checks via `provider_state.dart` helpers).
- `CaseListProvider.refreshCases()` does not flash `UiLoading` over existing data — it sets `isRefreshing` instead.
- `CaseDetailProvider.loadCase()` skips reload if the same case is already loaded successfully.

### 9.3 Selector Usage

`Selector` isolates rebuilds to the precise slice of state a widget needs:

```dart
Selector<CaseListProvider, UiState<List<CaseEntity>>>(
  selector: (_, p) => p.state,
  builder: ...
)

Selector<SubmissionProvider, bool>(
  selector: (_, p) => p.isSyncing,
  builder: ...
)
```

This avoids the common Provider anti-pattern of rebuilding entire screen trees on unrelated notifier changes.

---

## 10. Security Considerations

### 10.1 Input Validation

- Submit form rejects empty title/question before calling provider.
- UUID generation is centralized in `UuidGenerator` — widgets do not fabricate identifiers.
- Enum values are stored as `.name` strings and parsed with `byName` at the data layer.

**Gap:** No server-side schema validation, sanitization against injection, or length limits. Acceptable for assessment; production would enforce max lengths and content policy.

### 10.2 Local Persistence

- Database lives in app documents directory (platform-sandboxed).
- No encryption at rest in this build.
- No PII redaction in logs.

**Tradeoff:** sqflite without SQLCipher keeps the assessment simple. Production healthcare apps would require encrypted storage, secure key management, and potentially hardware-backed keystore integration.

### 10.3 Source of Truth

| Data | Authority |
|---|---|
| Pending writes | `pending_submissions` table (outbox) |
| Confirmed cases | `cases` table after successful sync |
| In-flight UI state | Providers (ephemeral) |
| Remote state | Mock API (simulated; ephemeral per session) |

The device SQLite database is the offline source of truth. The server is authoritative only after successful sync confirmation. Moderator workflow edits live in `cases.status`; `cases.online_status` holds the last server-confirmed value.

### 10.4 Future Security Improvements

- TLS certificate pinning for API transport
- Encrypted SQLite (SQLCipher)
- Production authentication beyond demo `AuthProvider`
- Audit log table for moderator actions
- Biometric app lock for clinical data at rest

### 10.5 Notification Correctness (Future Architecture)

This build has **no push notifications** — only in-app banners and SnackBars. IASA evaluates whether engineers understand that notifications must not become a second, untrusted data channel.

**Principle:** FCM payloads are **signals**, not sources of truth. Clinical content always flows through the same path as manual refresh:

```
FCM data message (caseId, event type only)
  → trigger refreshCases() / targeted case fetch
  → merge into SQLite
  → UI reads from local cache with existing metadata (lastSyncedAt, verifiedAt)
```

**Scenarios:**

| Scenario | Handling |
|---|---|
| Push arrives while offline | Queue signal; on reconnect, run refresh before surfacing content — never render payload body |
| Push arrives during submission sync | Serialize: complete outbox sync first, then refresh — avoids race between warrior write and moderator read |
| Answer revised after push was sent | Stale push is harmless if UI always re-fetches; `verifiedAt` may update on refresh |

**Why payload text is never authoritative:** Push content can be delayed, duplicated, or crafted. Treating it as clinical fact bypasses idempotency, merge logic, and staleness warnings already built for offline-first operation. Production would add FCM plus a minimal event envelope; the SQLite cache remains the display source after refresh.

---

## 11. Testing Strategy

**Current status:** 43 tests passing (`flutter test`). `flutter analyze` reports no errors (pre-existing style warnings only).

### 11.1 Unit & Domain Tests

| Area | Coverage |
|---|---|
| Domain entities | `CaseEntity`, `PendingSubmission` — `copyWith`, equality |
| `DatabaseConstants` | DDL shape, v3/v4 migrations, FK constraints, no `sync_queue` |
| `DatabaseHelper` migrations | v1 → v4 upgrade paths |
| Media storage | Attachment path rules, extension allowlists |

### 11.2 Data Layer Tests

| Area | Validates |
|---|---|
| `CaseLocalDataSource` | Insert/upsert cases, outbox persistence, media rows, stuck-sync reset |
| `MockApiDataSource` | Idempotent duplicate UUID handling |
| `CaseRepositoryImpl` | Local-only submit, sync retry, `getPendingSubmissions`, `refreshCases` merge, `updateLocalCaseStatus` |

Tests use `sqflite_common_ffi` for in-memory SQLite — no device emulator required.

### 11.3 Provider Tests

| Provider | Validates |
|---|---|
| `AuthProvider` | Login, logout, session restore |
| `CaseListProvider` | Load/empty/error mapping; refresh without flashing full-screen loader |
| `CaseDetailProvider` | Case resolution; missing-case error |
| `SubmissionProvider` | Queue on submit; **hydration from persisted outbox**; sync success/failure state |

### 11.4 Widget Tests

| Test | Validates |
|---|---|
| `OfflineAnswerBanner` | Offline staleness warning copy |
| `SubmissionQueuedBanner` | Queued message — not premature success |
| `UiStateView` | Empty state rendering |
| App bootstrap | Splash → session restore + outbox hydration → login screen |

### 11.5 What Is Not Tested

- Full multi-screen navigation integration (warrior submit → sync → detail)
- Real network flapping or airplane-mode timing
- Moderator status push to API (not implemented)
- FCM / push notification handling (not implemented)
- Accessibility and localization

---

## 12. Rejected Alternatives

### 12.1 Riverpod

Riverpod offers compile-safe providers and fine-grained rebuild control. Rejected because the assessment specification requires Provider. Introducing Riverpod would violate constraints and add evaluator friction without proportional benefit at this app size.

### 12.2 Bloc

Bloc enforces event-driven state machines with explicit transition maps. Rejected as over-engineering for four providers and a linear sync flow. The `Result<T>` + `UiState<T>` pattern provides sufficient explicitness with less boilerplate.

### 12.3 Complex Sync Engine

A dedicated `sync_queue` table with priority, payload JSON, and a background worker was designed and then **removed**. For a single outbox type (`pending_submissions`), a separate queue table added indirection without capability gain. The simpler model:

```
pending_submissions = outbox
syncPendingSubmissions() = worker
```

### 12.4 Optimistic Submission Success

Showing immediate "Submission Successful" would improve perceived responsiveness. Rejected because it violates healthcare trust requirements. The queued message is less satisfying UX but **accurate UX** — a tradeoff this project accepts deliberately.

### 12.5 Other Rejected Items

| Item | Reason |
|---|---|
| `serverId` separate from client ID | Reconciliation complexity |
| `is_dirty` flag | Redundant with `syncStatus` |
| `sync_queue` table | Duplicate of outbox |
| Auto-sync on connectivity change | Out of scope; manual sync demonstrates control |

---

## 13. Self Critique

### 13.1 Deliberate Weaknesses

**Weakness #1 — Moderator status is local-only**

Moderator workflow changes persist to SQLite (`updateLocalCaseStatus`) but are **not synchronized to the API**. Local and online status diverge honestly in UI, yet the server never learns the edit.

*Why accepted:* Assessment scope prioritized warrior-side offline reliability — outbox, idempotency, and honest submission UX. Expanding the mock API for moderator writes would add contract surface without strengthening the core thesis.

*Production path:* A `moderator_actions` outbox (same pattern as `pending_submissions`) with idempotent status-update endpoints and merge rules on refresh.

**Weakness #2 — Synchronization is manual**

Sync and refresh require explicit user action (sync button, pull-to-refresh). No background worker listens to connectivity changes.

*Why accepted:* Manual sync is predictable, testable, and easier to reason about in a submission demo. Automatic sync introduces timing races with in-flight edits and makes failure attribution harder during evaluation.

*Production path:* Debounced `connectivity_plus` listener triggering outbox sync then `refreshCases()`, with exponential backoff on failed rows.

### 13.2 Additional Limitations

| Limitation | Impact |
|---|---|
| Mock API in-memory | Remote seed data lost on process death; local SQLite retains cases |
| Demo authentication | Client-side credential map — not a security boundary |
| No encryption at rest | Plaintext SQLite in app documents |
| Sequential sync | No batching; large queues would be slow |
| No push notifications | Users must open app to learn of remote changes |

### 13.3 Production Follow-ups

1. Moderator outbox + API sync
2. Connectivity-aware background sync with backoff
3. Conflict resolution beyond last-known merge
4. Real API client with auth tokens and server-driven `verifiedAt`
5. Encrypted storage, audit logging, integration/golden tests

---

## 14. AI Usage Disclosure

### 14.1 How AI Was Used

AI assistance (Cursor IDE agent) accelerated scaffolding — folder layout, model boilerplate, test skeletons, and initial document structure. Every suggestion was reviewed against assessment constraints before landing in the repo.

All AI-assisted code was validated through `flutter analyze` and the **43-test suite**. AI did not run the app on a physical device or produce submission screenshots.

### 14.2 AI Suggestions Rejected

| Suggestion | Rejection rationale |
|---|---|
| Separate `sync_queue` table | Duplicates `pending_submissions`; one outbox type needs one table |
| Optimistic "Submission Successful" UI | Violates healthcare trust rules; queued state is accurate |
| Riverpod / extra state libraries | Assessment requires Provider; added complexity without benefit at this scale |
| Fifth global provider for sync state | Sync flags belong in `SubmissionProvider`; avoids rebuild coupling |
| Auto-sync on every connectivity blip | Hard to test and debug; manual sync demonstrates controlled recovery |

These rejections were intentional scope and integrity decisions, not omissions.

### 14.3 Human Architectural Decisions

| Decision | Rationale |
|---|---|
| Offline-first SQLite outbox | Submissions must survive connectivity loss |
| UUID as sole identity + idempotency key | No offline/online ID reconciliation |
| No premature submission success UI | Healthcare trust over perceived speed |
| `verifiedAt` / `lastSyncedAt` disclosure | Cached data must not imply clinical currency |
| Provider over Riverpod/Bloc | Assessment constraint + proportional complexity |
| `pending_submissions` as sole outbox | YAGNI — no parallel sync engine |
| Four focused providers | Rebuild isolation |
| `Result<T>` at repository boundary | Explicit errors without exception-driven flow |
| Local/online status split in SQLite | Honest moderator UX without API expansion in this build |
| Startup outbox hydration | Banner counts must reflect persisted queue after restart |

---

## 15. Lightweight Offline Authentication

Authentication in this build is **demonstration-only**. It exists to show role-based navigation and session persistence across app restarts — not to secure clinical data in production.

### Flow

```
SplashScreen → restoreSession() + hydratePendingSubmissions()
  ├── no session → LoginScreen
  └── valid session → Warrior CaseList | Moderator Queue
```

### Components

| Component | Role |
|---|---|
| `AuthUser` | Immutable `email` + `UserRole` |
| `SessionStorage` | `SharedPreferences` read/write for `isLoggedIn`, `email`, `role` |
| `AuthProvider` | `login()`, `logout()`, `restoreSession()`, `currentUser`, `isAuthenticated` |
| `AuthConstants` | Hard-coded dummy credential map (local validation only) |

### Dummy credentials

| Email | Password | Role |
|---|---|---|
| `warrior@iasa.com` | `password123` | Warrior → Case List |
| `moderator@iasa.com` | `password123` | Moderator → Moderator Queue |

### Design constraints

- **No backend calls** — credentials validated in `AuthProvider` against `AuthConstants`.
- **No repository changes** — auth is presentation + `core/auth` only.
- **No impact on sync/outbox** — `SubmissionProvider` continues to read `AuthProvider.selectedRole` (derived from `currentUser.role`).
- **`RoleSelectionScreen`** retained on disk for backward compatibility but removed from the normal navigation graph.

### Tradeoffs

| Choice | Why |
|---|---|
| `SharedPreferences` over SQLite user table | Minimal persistence for a two-user demo |
| Plaintext password in constants | Acceptable for assessment; not production-safe |
| Logout clears session only | Offline queue and cases remain in SQLite (correct offline-first behaviour) |

---

## 16. Conclusion

This project demonstrates that a small Flutter application can make credible architectural statements about offline reliability, clinical data honesty, and state management discipline — without a large feature surface.

The core engineering thesis is straightforward: **record intent locally, synchronize with idempotency, and tell the user the truth about what the system knows.**

The codebase is intentionally small. Complexity budget was spent on sync correctness, data integrity signals, and testable layer boundaries rather than UI animation or feature breadth. Documented limitations in Section 13 are scope decisions, not oversights.

---

## Appendix A — Requirement Mapping

| Requirement | Implementation |
|---|---|
| Clean Architecture layering | `core` / `domain` / `data` / `presentation`; inward dependencies |
| Provider state management | Four `ChangeNotifier` providers, `Selector` rebuild control |
| SQLite persistence | `DatabaseHelper` v4; `cases` + outbox + media tables |
| Offline queue | `pending_submissions` outbox; survives restart |
| Startup hydration | `GetPendingSubmissionsUseCase` → `SubmissionProvider.hydratePendingSubmissions()` |
| Retry-safe synchronization | Stuck-sync reset; failed rows retry; `SyncResult` honesty |
| Idempotency keys | UUID before network; `MockApiDataSource` deduplication |
| Honest UI | `SubmissionQueuedBanner`; no pre-sync success |
| Stale data integrity | `lastSyncedAt`, `verifiedAt`, `OfflineAnswerBanner` |
| Local vs online status | `status` / `onlineStatus`; `CaseStatusDisplay`; merge on refresh |
| Role-based navigation | `AuthProvider` + demo login; warrior / moderator routes |
| Manual sync + pull-to-refresh | `syncQueueAndReload`: sync → hydrate → `refreshCases()` |
| Offline authentication | `SessionStorage` (`SharedPreferences`); splash restore |
| Testing | 43 tests: providers, repository, datasource, migration, widget, hydration |
| Documentation | This document + `README.md` |

---

*End of document.*
