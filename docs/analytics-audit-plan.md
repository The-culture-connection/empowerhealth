# Realtime analytics pipeline — audit and implementation plan

## Audit summary (pre-change)

### Existing pieces

| Area | Finding |
| --- | --- |
| **Flutter** | [`lib/services/analytics_service.dart`](lib/services/analytics_service.dart) calls callable `logAnalyticsEvent`, then `_saveEventToFirestore` writes to `analytics_events` + `technology_features/{id}/analytics_events`, Firebase Analytics, user context. |
| **Cloud Functions** | [`logAnalyticsEvent`](admindash/functions/src/index.ts) writes **anonymous** event to `analytics_events` and full to `analytics_events_private`. No Firestore trigger on `analytics_events` yet. |
| **Firestore rules** | `analytics_events` allows authenticated create when `userId` matches or null; admin read. No rules yet for `analytics_summary*`. |
| **Admin webapp** | [`getAnalyticsData`](admindash/src/lib/analytics.ts) uses callable; [`Analytics.tsx`](admindash/src/app/pages/Analytics.tsx) loads via callable — **unchanged** as primary path. |
| **Inventory** | [`docs/mobile-analytics-inventory.md`](mobile-analytics-inventory.md) lists event names and feature IDs. |

### Design decisions

1. **Avoid double-counting in aggregates**: Both the Cloud Function and the Flutter client write to `analytics_events`. Aggregation **only** processes documents with `source === 'mobile'` (client pipeline v1). CF writes include `source: 'cloud_function'` and are **skipped** by the trigger.
2. **Additive**: Do not remove CF writes or Flutter `_saveEventToFirestore`; extend mobile documents with the full schema (`dateKey`, `hourKey`, `aggregationVersion`, etc.).
3. **Summary collections**: Written **only** by Cloud Functions (Admin SDK); rules deny client writes.
4. **Emulator**: Optional `dart-define` hooks in [`lib/services/firebase_service.dart`](lib/services/firebase_service.dart) — document in `docs/realtime-analytics.md`.
5. **Per-user summary**: Not implemented (privacy + unclear dashboard need); left as TODO.

## Implementation order

1. Firestore rules for `analytics_summary`, `analytics_summary_daily`, `analytics_feature_summary`, `analytics_summary_hourly`.
2. Flutter: `RealtimeAnalyticsService` + config; wire from `_saveEventToFirestore`; add `package_info_plus`.
3. Cloud Functions: tag CF analytics docs with `source: 'cloud_function'`; add `onDocumentCreated` aggregation module.
4. Admin: optional live read of `analytics_summary/global` on Analytics page.
5. Docs: `realtime-analytics.md`, `analytics-implementation-report.md`.
6. Unit test: metadata sanitization helper.
