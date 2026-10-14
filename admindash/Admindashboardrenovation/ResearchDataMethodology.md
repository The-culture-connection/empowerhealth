# Research data methodology (structured layer)

This complements [AnalyticsMethodology.md](./AnalyticsMethodology.md) (product **`analytics_events`** pipeline). It describes the **research-grade** layer keyed by **`study_id`**.

## Principles

- **Separation**: Product analytics stay in `analytics_events` / summaries. Study exports use **`research_*`** collections only.
- **Join key**: **`study_id`** is stored on **`users/{uid}`** (`studyId` field) after **Phase 1** **`createResearchParticipant`** (Cloud Function). Exports never emit Firebase Auth UIDs.
- **Coding**: Numeric codes for enums are defined in [`../functions/src/research/researchFieldSpec.ts`](../functions/src/research/researchFieldSpec.ts) (shared with the admin web app via `@research`).

## Collections (Firestore)

| Collection | Doc id | Writer |
|------------|--------|--------|
| `research_participants` | `study_id` | Cloud Function **`createResearchParticipant`** (merge update if `studyId` already set) |
| `research_baseline` | `study_id` | Cloud Function **`submitBaselineResearchData`** |
| `research_micro_measures` | auto | same (on micro-measure / confidence flows) |
| `research_needs_checklists` | auto | (reserved — wire when Care checklist saves coded rows) |
| `research_navigation_outcomes` | auto | same (care navigation outcome submit) |
| `research_milestone_prompts` | auto | same (milestone check-in) |
| `research_app_activity` | auto | same (module complete, AVS upload, provider review) |

## Admin Cloud Functions

- **`exportResearchDataset`**: Returns either per-instrument CSV strings or a JSON object; filters by `dateRange`, optional `studyId`, optional `recruitment_pathway` (1 or 2). Writes **`audit_logs`** with `action: research_export`. Responses duplicate baseline rows under **`baseline_export`** for REDCap-style filenames.
- **`getResearchDashboardSummary`**: Row counts (including **`research_baseline`** / `baselineCount`) and sampled micro-measure averages for the Research dashboard.
- **Phase 1 identity / baseline**: **`createResearchParticipant`**, **`submitBaselineResearchData`**, **`validateResearchBaseline`**, **`deriveAgeGroup`** (`researchIdentity.ts`) — server validation, coded enums, pregnancy/postpartum skip rules, and rejection of email-like free text.

## Admin UI

- **`/research`**: [`ResearchDashboard.tsx`](../src/app/pages/ResearchDashboard.tsx) — filters, KPIs, export buttons calling the callables above.

## QA checklist (abbrev.)

1. Enroll a test user as `isResearchParticipant`, complete **Research onboarding** (study id + baseline), then trigger micro-measure → confirm `users.studyId` and downstream `research_*` rows.
2. Run CSV export → confirm column headers match `researchFieldSpec.ts`.
3. Confirm exports contain **no** email, display name, or Firebase UID.
