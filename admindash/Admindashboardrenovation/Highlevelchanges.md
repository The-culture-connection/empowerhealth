Core Change: From “Behavior Analytics” → “Structured Research Dataset”

Right now your system is built like a product analytics pipeline:

Event-driven (analytics_events)
Optimized for dashboards (counts, sessions, feature usage)
Flexible metadata
Export = whatever events you queried

That’s appropriate for product insights—but not sufficient for research-grade data.

The new spec requires you to operate like a clinical/research data system:

Fixed schema
Stable variable names
Coded values (not free text)
Deterministic exports
Linked by study_id
Designed for REDCap / statistical analysis
What Actually Needs to Change (Conceptually)
1. Your “unit of data” changes
Current:
Unit = event
Example: journal_entry_created, screen_view
New:
Unit = participant + structured variables + research events

You are no longer just tracking what users did
You are tracking what each participant experienced and reported

2. You need a second data system (not just events)
Current system:
analytics_events (append-only, flexible, mixed schema)
Required system:
Structured datasets like:
baseline profile
micro-measures
needs checklist
navigation outcomes
milestone responses
activity logs tied to study_id

👉 Key shift:
You can’t rely on parsing event metadata anymore—you must store clean variables explicitly.

3. You must introduce a stable research identity layer
Current:
userId / anonUserId
New:
study_id (primary key for all exports)

This is critical because:

Research datasets must be de-identified
Everything must join on study_id
You cannot export Firebase UIDs

👉 This becomes the backbone of your entire research dataset.

4. Replace flexible metadata with strict schema
Current:
metadata: {
  "cohort_type": "navigator",
  "trimester": "second"
}
New:
Explicit fields with fixed names:
recruitment_pathway = 1 or 2
pp_status = 1 or 2
insurance_type = 1–4

👉 No ambiguity, no string parsing, no variation.

Everything must be:

predictable
typed
coded
5. Introduce coded values instead of text
Current:
Strings like "Pregnant", "Postpartum"
New:
Numeric codes:
1 = Pregnant
2 = Postpartum

Why:

Required for statistical analysis
Required for REDCap compatibility
Prevents inconsistencies
6. Add conditional logic (skip logic) at the data level
Current:
UI may show/hide fields, but backend doesn’t enforce structure
New:
Data must follow rules like:
Only store gest_week if pregnant
Only store insurance_other if type = Other
Only store outcome if need was selected

👉 This ensures your dataset is clean and analyzable.

7. Separate “research signals” from “product events”

Right now you mix everything into analytics:

session tracking
feature usage
surveys
behavior
New separation:
Type	Purpose
analytics_events	Product behavior, UX, debugging
research datasets	Study outcomes, exports, reporting

👉 Do NOT try to retrofit analytics into research—this is the biggest trap.

8. Exports must be deterministic (not query-based)
Current:
Export = whatever the dashboard queried
New:
Export = predefined schema

Every export must always include:

same columns
same names
same coding
same structure

Example:

study_id
micro_understand
need_transport
need_transport_outcome

👉 No dynamic columns, no missing structure.

9. De-identification becomes a first-class requirement
Current:
You store both anonymized and private events
New:
Research exports must:
exclude names
exclude emails
exclude UID
only use study_id

👉 This is not optional—it’s a compliance requirement.

10. Your dashboard becomes analysis-driven, not event-driven
Current dashboard:
total events
sessions
feature usage
screen views
New dashboard:
% of users who completed modules
average confidence scores
needs selected by category
navigation success rates
differences by recruitment pathway

👉 You are moving from activity metrics → outcome metrics

The Simplest Way to Think About It
Right now:

“What did users do in the app?”

After changes:

“What happened to each participant, and what outcomes did the app produce?”

Bottom Line

You are not just upgrading your dashboard—you are:

Adding a research-grade data layer
Standardizing all variables
Introducing a study-based data model
Separating analytics from research
Making exports usable for statistical analysis + REDCap

If you want, I can next:

map your current event schema → new research schema (line-by-line), or
design the exact Firestore structure + export function so you can implement this cleanly in one pass.