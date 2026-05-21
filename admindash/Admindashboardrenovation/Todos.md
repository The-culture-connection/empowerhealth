Research Dashboard + Export TODOs
1. Add required research fields to user profiles
Add study_id as the primary research linkage key.
Add research_participant toggle.
Add recruitment_source.
Add recruitment_source_other with skip logic when source = Other.
Add recruitment_pathway.
Add baseline fields:
age_years
derived age_group
pp_status
gest_week
postpartum_month
insurance_type
insurance_other
support_person_nav
baseline_advocacy_conf

Current analytics is mostly event-based, using collections like analytics_events, analytics_events_private, summaries, and feature summaries. The new spec requires structured research variables tied to study_id, not only raw event records.

2. Create structured research collections

Add dedicated Firestore storage separate from raw analytics events:

research_participants/{study_id}
research_baseline/{study_id}
research_micro_measures/{event_id}
research_needs_checklists/{event_id}
research_navigation_outcomes/{event_id}
research_milestone_prompts/{event_id}
research_app_activity/{event_id}

This matters because the current dashboard exports queried raw analytics_events, while the new spec needs stable export field names, coded values, timestamps, and REDCap alignment.

3. Add app forms and skip logic

Implement form logic for:

Pregnant users: show gest_week.
Postpartum users: show postpartum_month.
Insurance = Other: show insurance_other.
Recruitment source = Other: show recruitment_source_other.
Need category selected: show the matching outcome field.
Need other selected: show need_other_text.
4. Replace free-text categories with coded values

Use numeric coded values exactly like the field spec:

Yes/No: 1 = Yes, 0 = No
Pregnancy/postpartum: 1 = Pregnant, 2 = Postpartum
Recruitment source: 1–7
Recruitment pathway: 1 = Navigator-supported, 2 = Self-directed
Likert ratings: 1–5
Navigation outcomes: 1 = Yes, 2 = Partly, 3 = No, 4 = Didnt_try, 5 = Didnt_know_how, 6 = Couldnt_access
5. Add micro-measure tracking

For each module or visit summary rating, store:

study_id
micro_understand
micro_next_step
micro_confidence
content_id
content_type
micro_ts

The current analytics system already tracks events like micro_measure_submitted, but the new requirement is to store export-ready structured variables.

6. Add needs checklist tracking

Store each need as its own binary field:

need_prenatal_postpartum
need_delivery_prep
need_med_followup
need_mental_health
need_lactation
need_infant_care
need_benefits
need_transport
need_other
need_other_text
needs_ts
7. Add navigation outcome tracking

For every selected need, store the matching outcome field:

need_prenatal_postpartum_outcome
need_delivery_prep_outcome
need_med_followup_outcome
need_mental_health_outcome
need_lactation_outcome
need_infant_care_outcome
need_benefits_outcome
need_transport_outcome
need_other_outcome
8. Add milestone prompt tracking

Store:

milestone_health_question
milestone_clear_next_step
milestone_app_helped_next_step
milestone_type
milestone_ts
9. Add app activity export records

Make sure these export cleanly by study_id:

Module completions
Provider review activity
AVS upload type
Plain-language library access
Needs checklist selections
Navigation outcomes
Micro ratings

The new spec explicitly says research export must include user study ID, module completions, needs checklist selections, navigation outcomes, micro ratings, provider review activity, recruitment source, and de-identified CSV/JSON export.

10. Build research export backend function

Create a callable/admin-only export function, for example:

exportResearchDataset

It should support:

CSV export
JSON export
date range filters
export by study_id
export by cohort/recruitment pathway
de-identified output
no names
no emails
stable export column names
11. Build REDCap-aligned export files

Create separate export tabs/files for:

Baseline data
Micro measures
Needs checklist
Navigation outcomes
Milestone prompts
App activity logs
Provider review activity
Module completion events

Use the export names from the field specification so they match REDCap variables.

12. Update admin dashboard views

Add a dedicated Research Dashboard section with:

participant count
research participant filter
navigator-supported vs self-directed comparison
module completion rates
average micro-measure scores
needs selected by category
navigation outcome success rates
milestone response summaries
provider review activity
AVS upload activity
export buttons for CSV and JSON
13. Keep raw analytics, but do not rely on it as the research dataset

Current analytics_events should remain useful for behavior patterns, screen views, feature usage, and session behavior. But the research export should come from structured research fields and research event records, not only from the raw analytics CSV.

14. Update security rules

Add rules so:

only admins/research-authorized roles can read research exports
app users cannot read other users’ research records
direct identifiers stay out of research exports
raw UID linkage remains admin-only
research exports use study_id, not name/email
15. Validate with test users

Create 3–5 fake test users and verify:

skip logic works
coded values save correctly
timestamps are consistent
CSV export columns are stable
JSON export is structured correctly
no names/emails appear in export
REDCap variable names match the spec
dashboard summaries match exported records