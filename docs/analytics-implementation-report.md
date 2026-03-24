# Analytics implementation report

## 1. What was added

- **Flutter** [`lib/services/analytics/realtime_analytics_service.dart`](../lib/services/analytics/realtime_analytics_service.dart): writes normalized `analytics_events` with `source: mobile`, time keys, platform, app version, sanitized metadata.
- **Flutter** [`lib/services/analytics/realtime_analytics_config.dart`](../lib/services/analytics/realtime_analytics_config.dart): shared constants and inventory event name references.
- **Integration**: [`lib/services/analytics_service.dart`](../lib/services/analytics_service.dart) `_saveEventToFirestore` now delegates to `RealtimeAnalyticsService` (replaces inline duplicate map + dual write logic).
- **Cloud Function** [`admindash/functions/src/analyticsAggregation.ts`](../admindash/functions/src/analyticsAggregation.ts): `onAnalyticsEventCreated` on `analytics_events/{eventId}` updates global, daily, hourly, and feature summaries; **skips** `source: cloud_function`.
- **Cloud Function** [`logAnalyticsEvent`](../admindash/functions/src/index.ts): adds `source: cloud_function` and `aggregationVersion: 1` to CF-written `analytics_events` rows.
- **Firestore rules**: read-only access for admins to `analytics_summary`, `analytics_summary_daily`, `analytics_feature_summary`, `analytics_summary_hourly`.
- **Firebase init**: optional Firestore emulator via `--dart-define=USE_FIREBASE_EMULATOR=true` in [`lib/services/firebase_service.dart`](../lib/services/firebase_service.dart).
- **Admin UI**: [`admindash/src/app/pages/Analytics.tsx`](../admindash/src/app/pages/Analytics.tsx) live snapshot of `analytics_summary/global`.
- **Instrumentation**: `sign_in_completed` (login), `profile_updated` (edit profile save).
- **Tests**: [`test/realtime_analytics_service_test.dart`](../test/realtime_analytics_service_test.dart).
- **Docs**: [`docs/realtime-analytics.md`](realtime-analytics.md), [`docs/analytics-audit-plan.md`](analytics-audit-plan.md).

## 2. Files changed

| Area | Files |
| --- | --- |
| Flutter | `pubspec.yaml`, `lib/services/analytics_service.dart`, `lib/services/firebase_service.dart`, `lib/services/analytics/realtime_analytics_service.dart`, `lib/services/analytics/realtime_analytics_config.dart`, `lib/auth/Login_screen.dart`, `lib/editprofile/edit_profile_screen.dart`, `test/realtime_analytics_service_test.dart` |
| Functions | `admindash/functions/src/index.ts`, `admindash/functions/src/analyticsAggregation.ts` |
| Rules | `firestore.rules` |
| Admin | `admindash/src/app/pages/Analytics.tsx` |
| Docs | `docs/analytics-audit-plan.md`, `docs/realtime-analytics.md`, `docs/analytics-implementation-report.md` |

## 3. Assumptions

- **Double storage** per user action remains: callable `logAnalyticsEvent` writes one `analytics_events` doc (now tagged `cloud_function`), and the client writes another (`mobile`). Only **mobile** rows increment realtime summaries.
- **Legacy** `analytics_events` without `source` are still aggregated (treated like mobile). After deployment, CF rows are excluded from aggregates.
- **`environment`**: `local` when `kDebugMode`, else `prod` (no separate staging flag in code).
- **Per-user summary** collection was **not** added (privacy + unclear product need).

## 4. Functionality at risk

- **Firestore write volume** increased slightly (schema-rich mobile docs; behavior existed before via `_saveEventToFirestore`).
- **Login / profile** paths now perform extra `AnalyticsService.logEvent` calls (wrapped in try/catch — should not block navigation).
- **Auth timing**: events may still **queue** if `_authReady` is false (existing behavior).

## 5. Regression checks performed

- `npm run build` in `admindash/functions` (TypeScript compile).
- `flutter test test/realtime_analytics_service_test.dart` (passed).
- `flutter analyze` on touched Dart files (no new errors; pre-existing infos/warnings remain in large files).

**Manual verification recommended:** deploy rules + functions, trigger a mobile event, confirm `analytics_summary/global` updates in console and Analytics page.

## 6. TODOs

- Wire **Auth emulator** / **Functions emulator** in Flutter for full offline parity (currently only Firestore emulator hook).
- **Exact unique daily active users** on global summary — not implemented (expensive without session pipeline).
- Align **QualitativeSurveyService** anon salt with `AnalyticsService` (pre-existing inconsistency; see inventory).
- Instrument remaining inventory gaps (session end, learning module completed + duration, community replies/likes, etc.).

## 7. Inventory events not yet wired in UI

See [`mobile-analytics-inventory.md`](mobile-analytics-inventory.md) “Gaps” sections: many `AnalyticsService` methods are still unused; realtime aggregates will increment **only when** those events are emitted with `source: mobile` through the existing pipeline.

## 8. Manual verification

- **Callable** analytics and **private** collection unchanged in behavior aside from new fields on CF rows.
- **Admin dashboard** `getAnalyticsData` still queries raw `analytics_events` — unchanged.
- Confirm **Firestore rules** deploy before relying on summary reads in production.
