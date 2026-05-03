# Research data methodology (structured layer)

This complements [AnalyticsMethodology.md](./AnalyticsMethodology.md) (product **`analytics_events`** pipeline). It describes the **research-grade** layer keyed by **`study_id`**.

## Principles

- **Separation**: Product analytics stay in `analytics_events` / summaries. Study exports use **`research_*`** collections only.
- **Join key**: **`study_id`** is stored on **`users/{uid}`** (`studyId` field) when a research participant first triggers a research write. Exports never emit Firebase Auth UIDs.
- **Coding**: Numeric codes for enums are defined in [`../functions/src/research/researchFieldSpec.ts`](../functions/src/research/researchFieldSpec.ts) (shared with the admin web app via `@research`).

## Collections (Firestore)

| Collection | Doc id | Writer |
|------------|--------|--------|
| `research_participants` | `study_id` | Flutter `ResearchFirestoreService` |
| `research_baseline` | `study_id` | same |
| `research_micro_measures` | auto | same (on micro-measure / confidence flows) |
| `research_needs_checklists` | auto | (reserved — wire when Care checklist saves coded rows) |
| `research_navigation_outcomes` | auto | same (care navigation outcome submit) |
| `research_milestone_prompts` | auto | same (milestone check-in) |
| `research_app_activity` | auto | same (module complete, AVS upload, provider review) |

## Admin Cloud Functions

- **`exportResearchDataset`**: Returns either per-instrument CSV strings or a JSON object; filters by `dateRange`, optional `studyId`, optional `recruitment_pathway` (1 or 2). Writes **`audit_logs`** with `action: research_export`.
- **`getResearchDashboardSummary`**: Row counts and sampled micro-measure averages for the Research dashboard.

## Admin UI

- **`/research`**: [`ResearchDashboard.tsx`](../src/app/pages/ResearchDashboard.tsx) — filters, KPIs, export buttons calling the callables above.

## QA checklist (abbrev.)

1. Enroll a test user as `isResearchParticipant`, trigger micro-measure → confirm `users.studyId` and `research_*` rows.
2. Run CSV export → confirm column headers match `researchFieldSpec.ts`.
3. Confirm exports contain **no** email, display name, or Firebase UID.
