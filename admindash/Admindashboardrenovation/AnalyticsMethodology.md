# Analytics methodology — collection, export, and backend storage

This dossier describes how EmpowerHealth analytics are **collected**, **persisted in the backend (Firestore + Cloud Functions)**, and **exported or surfaced** in the admin dashboard. It is scoped to what the repository implements today. For a full product-wide overview (including Firebase Analytics and mobile client details), see `docs/analytics-system-overview.md`, `docs/realtime-analytics.md`, and `docs/mobile-analytics-inventory.md`.

---

## 1. Design principles (backend-relevant)

- **Dual writes to `analytics_events`**: A callable Cloud Function logs anonymized + lifecycle-enriched events with `source: cloud_function`. The Flutter app also writes enriched rows with `source: mobile` for realtime rollups. The aggregation trigger **ignores** `cloud_function` rows so dashboard counters are not double-counted.
- **Append-only event stores**: Clients and functions **create** documents; Firestore security rules disallow updates/deletes on analytics event paths.
- **Role-gated reads**: Anonymized streams are usable for research-oriented roles; raw Firebase Auth UIDs live only in `analytics_events_private`, which is callable-written and admin-readable per rules.

---

## 2. How analytics are collected

### 2.1 Mobile app (primary production path)

1. **`AnalyticsService`** (`lib/services/analytics_service.dart`) invokes the HTTPS callable **`logAnalyticsEvent`** (Firebase Functions, Gen-2 style in `admindash/functions/src/index.ts`). That establishes server-side anonymization and optional lifecycle fields from metadata.
2. After a successful callable, **`RealtimeAnalyticsService`** (`lib/services/analytics/realtime_analytics_service.dart`) writes a document to the top-level Firestore collection **`analytics_events`** with:
   - `source: mobile` (constant from `realtime_analytics_config.dart`)
   - `aggregationVersion`
   - Time partition keys: `dateKey`, `hourKey`, `monthKey` (UTC)
   - `platform`, `environment`, `appVersion`, `clientTimestamp`
   - `userId`, `anonUserId`, `sessionId`, sanitized `metadata`, optional cohort fields
   - `timestamp: serverTimestamp()`
3. When the feature maps to a technology dossier id, the same payload is **mirrored** to  
   `technology_features/{featureId}/analytics_events` for feature-scoped tooling.

### 2.2 Callable `logAnalyticsEvent` (server-side collection)

Authenticated callers send `eventName`, `feature`, optional `metadata`, `durationMs`, and `sessionId`. The function:

- Validates `feature` against an allowlist (unknown values are logged with a warning and normalized in practice).
- Computes **`anonUserId`** as the first 16 hex chars of `SHA256(uid + ANALYTICS_SALT)` (`ANALYTICS_SALT` is a deploy-time param; default exists for local dev).
- Copies known lifecycle keys from `metadata` into a merged **`enrichedMetadata`** object.
- Writes **two** documents:
  - **`analytics_events`**: anonymized row (`anonUserId`, no `uid`), `source: cloud_function`, `aggregationVersion: 1`, `timestamp` server-side.
  - **`analytics_events_private`**: same payload plus **`uid`** for admin-only correlation.

App Check is explicitly **not** enforced on these callables; **Firebase Auth** is required.

### 2.3 Admin dashboard web app

- **`admindash/src/lib/analytics.ts`**: `logEvent` calls `logAnalyticsEvent` the same way as mobile (anonymization path). `getAnalyticsData` calls the **`getAnalyticsData`** callable for server-computed rollups over Firestore query results.
- **Direct Firestore reads**: Pages such as **`Analytics.tsx`** query **`analytics_events`** in the browser (with date filters) and subscribe to **`analytics_summary/global`** for live counters. Helpers in **`analyticsDashboardFirestore.ts`** read pre-aggregated daily and per-feature summary collections.

---

## 3. How data is saved in the backend

### 3.1 Firestore collections (authoritative storage)

| Collection | Written by | Purpose |
|------------|------------|---------|
| **`analytics_events`** | `logAnalyticsEvent` (CF), mobile `RealtimeAnalyticsService` | Primary event lake: anonymized id on CF rows; mobile rows include `userId` for rules-scoped reads. Mixed `source` values. |
| **`analytics_events_private`** | `logAnalyticsEvent` only | Admin-only copy including **`uid`**. Clients cannot write (rules). |
| **`analytics_summary`** / doc `global` | `onAnalyticsEventCreated` | Rolling global counters, `lastEvent*`, first-class “today*” increments for selected event names. |
| **`analytics_summary_daily`** / `{YYYY-MM-DD}` | Same trigger | Per-day totals, `countsByEventName`, `countsByFeature`, plus mapped daily fields. |
| **`analytics_summary_hourly`** / `{YYYY-MM-DD-HH}` | Same trigger | Hourly rollups. |
| **`analytics_feature_summary`** / `{featureDocId}` | Same trigger | Per-feature totals and `countsByEventName`. |
| **`technology_features/{id}/analytics_events`** | Mobile only | Mirror of mobile events for feature-level queries in the admin UI. |

**Security rules** (`firestore.rules`): authenticated users may **create** `analytics_events` only when `userId` is null or equals their Auth uid; admin-role users may read broadly; `analytics_events_private` and summary collections are **read** for admins (and partners where noted) with **no client writes** on summaries/private.

### 3.2 Realtime aggregation (`onAnalyticsEventCreated`)

- **Trigger**: Firestore `onDocumentCreated` on `analytics_events/{eventId}` (`admindash/functions/src/analyticsAggregation.ts`, region `us-central1`).
- **Skip rule**: If `data.source === 'cloud_function'`, the handler returns immediately — only **mobile-originated** rows update summary documents.
- **Mechanics**: A single batch **merge-sets** increments (`FieldValue.increment`) into global, daily, hourly, and per-feature docs; event names are escaped for map keys; `dateKey` / `hourKey` prefer client-supplied keys when valid, else derive from `timestamp`.

### 3.3 Server-side rollups and reports (read + compute, optional write)

- **`getAnalyticsData`**: Queries `analytics_events` or `analytics_events_private` with optional `dateRange` and `feature`, then computes dashboard metrics (active users, feature usage, durations, event counts, holistic report blocks). **Does not** persist its output to Firestore; it returns JSON to the client.
- **`getFeatureAnalytics`**: Similar pattern scoped by `featureId` with role checks (admin, research partner, community manager); research partners are restricted to anonymized mode.
- **`generateReport`**: Loads events from the appropriate collection by date range, builds a report object, and appends an **`audit_logs`** entry (`action: report_generated`). Report payload is returned to the caller, not stored as a dedicated “report document” in the snippets reviewed.

### 3.4 Tracked `eventName` values (custom Firestore / callables)

These are the **custom** event names the Flutter `AnalyticsService` (`lib/services/analytics_service.dart`) and a few screens emit through **`logAnalyticsEvent`** (and therefore can appear in **`analytics_events`** / **`analytics_events_private`**). They are **not** the same as GA4 automatic events; the app also mirrors many of these to **Google Analytics for Firebase** with sanitized parameters (`_logToFirebaseAnalytics`).

| Category | `eventName` values |
|----------|-------------------|
| Session / shell | `session_started`, `session_ended`, `feature_session_started`, `feature_session_ended`, `screen_view`, `screen_time_spent`, `feature_time_spent`, `flow_abandoned` |
| Notifications (API present; may be sparse) | `notification_opened`, `notification_received` |
| Learning | `learning_module_viewed`, `know_your_rights_viewed`, `learning_module_started`, `learning_module_completed`, `learning_module_video_played`, `learning_module_video_completed`, `learning_module_survey_submitted` |
| Visit summary | `visit_summary_created`, `visit_summary_viewed`, `visit_summary_edited`, `visit_summary_exported_pdf`, `visit_summary_shared_provider`, `visit_summary_voice_note_added` |
| Birth plan | `birth_plan_started`, `birth_plan_template_selected`, `birth_plan_completed`, `birth_plan_updated`, `birth_plan_viewed`, `birth_plan_exported`, `birth_plan_shared_provider`, `birth_plan_downloaded_pdf` |
| Provider | `provider_search_initiated`, `provider_filter_applied`, `provider_profile_viewed`, `provider_contact_clicked`, `provider_saved`, `provider_review_viewed`, `provider_review_submitted`, `provider_listing_report_submitted`, `provider_selected_success` |
| Journal | `journal_entry_created`, `journal_entry_updated`, `journal_entry_deleted`, `journal_mood_selected`, `journal_entry_shared` |
| Community | `community_post_created`, `community_post_viewed`, `community_reply_created`, `community_post_liked`, `community_post_replied`, `community_post_reported`, `community_support_request` |
| Surveys / measures | `micro_measure_submitted`, `helpfulness_survey_submitted`, `milestone_checkin_submitted`, `care_navigation_outcome_submitted` |
| Auth / profile (direct `logEvent` in UI) | `sign_in_completed` (`lib/auth/Login_screen.dart`), `profile_updated` (`lib/editprofile/edit_profile_screen.dart`) |

**Backend `feature` field** (on the same documents) must be one of:  
`provider-search`, `authentication-onboarding`, `user-feedback`, `appointment-summarizing`, `journal`, `learning-modules`, `birth-plan-generator`, `community`, `profile-editing`, `app` (see `realtime_analytics_config.dart` and `logAnalyticsEvent` allowlist).

**First-class rollup keys** in `analytics_summary` / daily docs: only a subset of event names increment dedicated counters (e.g. `community_post_created` → `todayPostsCreated`). See `firstClassIncrements` in `admindash/functions/src/analyticsAggregation.ts` for the exact mapping.

### 3.5 Example Firestore documents (illustrative JSON)

Below, `timestamp` is a **Firestore Timestamp** in the database; examples use ISO-8601 strings for readability. **`FieldValue.increment(n)`** is shown as numeric totals **after** merges (as clients read them). Document IDs (`"abc123..."`) are auto-generated by `.add()`.

#### A. `analytics_events/{eventId}` — **mobile** (`source: "mobile"`)

Written by `RealtimeAnalyticsService.writeMobileAnalyticsEvent`. These rows **are** processed by `onAnalyticsEventCreated`.

```json
{
  "eventName": "visit_summary_created",
  "userId": "FirebaseAuthUidExample01",
  "feature": "appointment-summarizing",
  "screen": "upload_visit_summary",
  "timestamp": "2026-05-03T14:22:01.000Z",
  "clientTimestamp": "2026-05-03T14:22:01.123Z",
  "platform": "ios",
  "appVersion": "1.4.2+120",
  "environment": "prod",
  "sessionId": "sess_8f3c2a1b",
  "metadata": {
    "cohort_type": "navigator",
    "trimester": "second",
    "pregnancy_week": 24,
    "screen_name": "upload_visit_summary",
    "summary_id": "vs_doc_99"
  },
  "source": "mobile",
  "aggregationVersion": 1,
  "dateKey": "2026-05-03",
  "hourKey": "2026-05-03-14",
  "monthKey": "2026-05",
  "cohortType": "navigator",
  "gestationalWeek": 24,
  "trimester": "second",
  "anonUserId": "a1b2c3d4e5f67890"
}
```

#### B. `analytics_events/{eventId}` — **cloud function** (`source: "cloud_function"`)

Written by `logAnalyticsEvent` only. **No** `userId` on the anonymized doc; **not** aggregated into summaries.

```json
{
  "anonUserId": "a1b2c3d4e5f67890",
  "eventName": "visit_summary_created",
  "feature": "appointment-summarizing",
  "metadata": {
    "user_id": "FirebaseAuthUidExample01",
    "cohort_type": "navigator",
    "navigator": true,
    "self_directed": false,
    "pregnancy_week": 24,
    "trimester": "second",
    "session_id": "sess_8f3c2a1b",
    "summary_id": "vs_doc_99"
  },
  "durationMs": null,
  "sessionId": "sess_8f3c2a1b",
  "timestamp": "2026-05-03T14:22:00.800Z",
  "source": "cloud_function",
  "aggregationVersion": 1
}
```

#### C. `analytics_events_private/{eventId}`

Same logical event as (B), plus **`uid`** for admin correlation. Client apps **cannot** write this collection (rules).

```json
{
  "uid": "FirebaseAuthUidExample01",
  "anonUserId": "a1b2c3d4e5f67890",
  "eventName": "visit_summary_created",
  "feature": "appointment-summarizing",
  "metadata": {
    "user_id": "FirebaseAuthUidExample01",
    "cohort_type": "navigator",
    "navigator": true,
    "self_directed": false,
    "pregnancy_week": 24,
    "trimester": "second",
    "session_id": "sess_8f3c2a1b",
    "summary_id": "vs_doc_99"
  },
  "durationMs": null,
  "sessionId": "sess_8f3c2a1b",
  "timestamp": "2026-05-03T14:22:00.800Z"
}
```

#### D. `analytics_summary/global` (document id: `global`)

Counters grow with each **mobile** event; optional “today*” fields appear when `eventName` matches `firstClassIncrements`.

```json
{
  "updatedAt": "2026-05-03T14:25:00.000Z",
  "totalEvents": 154328,
  "lastEventName": "screen_view",
  "lastEventAt": "2026-05-03T14:24:58.000Z",
  "aggregationVersion": 1,
  "todayVisitSummaries": 42,
  "todayJournalEntries": 18,
  "todaySessionsStarted": 210,
  "todayScreenViews": 905
}
```

#### E. `analytics_summary_daily/{dateKey}` (document id = `YYYY-MM-DD`)

`countsByEventName` keys are derived from `eventName` with non-alphanumeric characters replaced by `_` (max length 100).

```json
{
  "dateKey": "2026-05-03",
  "updatedAt": "2026-05-03T14:25:00.000Z",
  "totalEvents": 4821,
  "countsByEventName": {
    "screen_view": 1200,
    "session_started": 310,
    "visit_summary_created": 42
  },
  "countsByFeature": {
    "app": 1500,
    "appointment-summarizing": 200,
    "journal": 90
  },
  "eventsSubmitted": 42,
  "postsCreated": 15,
  "profileUpdated": 8
}
```

#### F. `analytics_summary_hourly/{hourKey}` (document id = `YYYY-MM-DD-HH` UTC)

```json
{
  "hourKey": "2026-05-03-14",
  "dateKey": "2026-05-03",
  "updatedAt": "2026-05-03T14:25:00.000Z",
  "totalEvents": 212,
  "countsByEventName": {
    "screen_view": 88,
    "journal_entry_created": 12
  }
}
```

#### G. `analytics_feature_summary/{featureDocId}`

`featureDocId` is the `feature` string with Firestore path characters (`/.#$[]\`) replaced by `_`, truncated to 200 characters.

```json
{
  "feature": "journal",
  "updatedAt": "2026-05-03T14:25:00.000Z",
  "totalEvents": 9032,
  "lastEventName": "journal_entry_created",
  "lastEventAt": "2026-05-03T14:24:40.000Z",
  "countsByEventName": {
    "journal_entry_created": 410,
    "journal_mood_selected": 205
  }
}
```

#### H. `technology_features/{featureId}/analytics_events/{eventId}`

**Same field payload** as top-level mobile `analytics_events` (mirrored write). Example for `featureId` = `journal`:

```json
{
  "eventName": "journal_entry_created",
  "userId": "FirebaseAuthUidExample01",
  "feature": "journal",
  "screen": "journal_home",
  "timestamp": "2026-05-03T09:10:00.000Z",
  "clientTimestamp": "2026-05-03T09:10:00.045Z",
  "platform": "android",
  "appVersion": "1.4.2+118",
  "environment": "prod",
  "sessionId": "sess_morning_1",
  "metadata": {
    "cohort_type": "self_directed",
    "trimester": "third",
    "pregnancy_week": 34,
    "screen_name": "journal_home"
  },
  "source": "mobile",
  "aggregationVersion": 1,
  "dateKey": "2026-05-03",
  "hourKey": "2026-05-03-09",
  "monthKey": "2026-05",
  "cohortType": "self_directed",
  "gestationalWeek": 34,
  "trimester": "third",
  "anonUserId": "fedcba0987654321"
}
```

### 3.6 `analytics_daily`

Rules exist for **`analytics_daily/{date}`** (client read for privileged roles, no client write). The admin functions **health check** reads this collection to infer last job activity; **no writer** for `analytics_daily` appears in the TypeScript sources searched alongside this dossier — treat it as **reserved or legacy batch output** unless another pipeline populates it.

### 3.7 Related persistence (not `analytics_events`, but report inputs)

**`admindash/src/lib/firestore/reportsRepo.ts`** loads a **`ReportDataset`** from Firestore in parallel: `analytics_events` (by timestamp range), plus `module_feedback`, `care_surveys`, `care_navigation_outcomes`, and `users` profiles. Those feeds power structured PDF/HTML-style reports, not the raw analytics CSV.

---

## 4. How analytics are exported or consumed

### 4.1 Admin UI — CSV export (client-side)

**`admindash/src/app/pages/Analytics.tsx`** loads raw rows from **`analytics_events`** for the selected date window, keeps them in component state, and **`exportRawEventsCsv`** builds a CSV string in the browser (`Blob` + download anchor). This is an **export of whatever rows the dashboard already queried**, not a separate backend export job.

### 4.2 Callables (server-mediated “export”)

- **`getAnalyticsData`** / **`getFeatureAnalytics`**: Return aggregated JSON for charts and tables without writing files.
- **`generateReport`**: Returns a structured report for authorized roles and logs access in **`audit_logs`**.

### 4.3 Reports module

Report builders consume **`getReportDataset`** → normalized **`analytics_events`** rows plus other collections (`reportsRepo.ts`). Output format is defined by the report pipeline (whitelisted events, evidence copy), distinct from the Analytics page CSV.

---

## 5. Operational checklist

- Deploy **`admindash/functions`** so `logAnalyticsEvent`, `getAnalyticsData`, `getFeatureAnalytics`, `generateReport`, and **`onAnalyticsEventCreated`** are live in the same Firebase project as the app’s Firestore.
- Configure **`ANALYTICS_SALT`** in production for stable anonymization.
- Ensure **composite indexes** exist for any production queries that combine `timestamp` + `feature` (the dashboard and callables use such filters).
- For **parity** between Google Analytics dashboards and Firestore, keep mobile instrumentation aligned with `AnalyticsService` / `RealtimeAnalyticsService` (see repo docs under `docs/`).

---

## 6. Source map (quick reference)

| Concern | Location |
|---------|----------|
| Callable log + private copy | `admindash/functions/src/index.ts` — `logAnalyticsEvent` |
| Callable reads / rollups | `admindash/functions/src/index.ts` — `getAnalyticsData`, `getFeatureAnalytics`, `generateReport` |
| Firestore trigger | `admindash/functions/src/analyticsAggregation.ts` — `onAnalyticsEventCreated` |
| Mobile Firestore writer | `lib/services/analytics/realtime_analytics_service.dart` |
| Admin callable wrappers | `admindash/src/lib/analytics.ts`, `admindash/src/lib/featureAnalytics.ts` |
| Summary reads | `admindash/src/lib/analyticsDashboardFirestore.ts` |
| Raw events for reports | `admindash/src/lib/firestore/reportsRepo.ts` |
| Rules | `firestore.rules` (root) and mirrored concepts in `admindash/firestore.rules` |
