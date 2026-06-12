# EmpowerHealth Watch — V3 + V4 Revisions To-Do

Source: `V4 EmpowerHealth Watch Revisions.docx` (V4 Revision 6/8/2026)
Generated: 2026-06-12

These updates are intended to improve health literacy, appointment preparation,
self-advocacy, and usability while minimizing user burden prior to launch.

**Status legend:** `[x]` appears implemented in code · `[~]` partial / needs reconciliation · `[ ]` outstanding / verify

Active home screen: `lib/Home/home_screen_v2.dart`

---

## V4 — Outstanding Revisions (primary work)

### 🎨 Frontend / UI changes (copy, layout, components)

- [x] **Today's Guidance card** — slimmed the "We're here with you 💜" card (`immediate_support_home_card.dart`): collapsed four text blocks to a headline + one line + "See support options →", reduced padding. (Per client direction, kept this card rather than replacing it with new copy.)
- [x] **Care Check-In card** — updated to *"Care Check-In / Tell us what you needed help with and whether you got it. / Start check-in →"* (`home_screen_v2.dart`).
- [x] **Trimester / Learning Center card** — converted the large purple trimester card into a compact learning card: *"Week 38 • Third Trimester / What to expect this week, what to ask, and when to call your provider. / Open Learning Center →"* (removed decorative circles + progress bar).
- [x] **Home screen layout reorder** — new order: **Welcome/Search → Your Space → Today's Guidance (incl. Care Check-In) → Understand Your Care → Trimester → Community**. (Understand Your Care kept per client direction.)
- [x] **"Know your rights" entry copy** — updated to *"Know your rights / Understand your options and feel confident speaking up."* (`home_screen_v2.dart`).
- [x] **Remove AI banner** — removed the *"Extra topics below use personalized explanations (AI) — unique to this app"* banner from the Know Your Rights page (`rights_screen.dart`).
- [x] **Learning module feedback widget** — added `ModuleQuickFeedback` (`lib/widgets/module_quick_feedback.dart`), shown immediately after module content in the detail screen. Two variants: `didThisHelp` (💜/🙂/😕) and `howDoYouFeel` (💪/🙂/😕). Stores via the existing `QualitativeSurveyService`.
- [x] **Community section copy** — updated to *"Help Another Mama Choose Care"* + new description + CTA *"💜 Share Provider Experience"* (`community_survey_banner.dart`).
- [x] **Support icon discoverability** — converted the icon-only Support button on the AI Assistant screen into a labeled "Support" button (icon + label + tooltip) (`assistant_screen.dart`).
- [x] **Mama Approved™ presentation** — added "What mothers said" trust indicators on the profile, updated badge explainers (profile + search) to mention the experience questions, and made the **Mama Approved™ only** filter a prominent toggle above the advanced filters in search.

### ⚙️ Functionality changes (logic, data, workflows)

- [x] **"My Visits" stuck on loading** — home visit card no longer shows a stuck "Loading..."; it shows the helpful default card until a real visit loads (`home_screen_v2.dart`). Added `hasError` handling to the visits list (`appointments_list_screen.dart`).
- [x] **Provider search → universal search** — provider type is no longer required to search; when none is selected the search defaults to the core provider-type set (`ProviderTypes.mvpTypes`) so results return regardless of type (`provider_search_entry_screen.dart`). Backend requires ≥1 type, so an empty list is never sent.
- [x] **Know Your Rights — Save to Journal** — replaced the two Copy buttons in the rights detail view with **Save to Journal** (auto-categorized) (`rights_screen.dart`).
- [x] **Learning Module actions** — replaced **Copy** with **Save to Journal** in the module detail screen, opening the existing note workflow with the category pre-filled (`learning_module_detail_screen.dart`).
- [x] **Journal auto-categorization** — `NotesDialog` now accepts an `initialTag` and auto-selects the category from the source section via `NotesDialog.categoryForSection(...)`; expanded the category list to match the doc (`lib/learning/notes_dialog.dart`).
- [x] **AI Assistant intro card — dismissible** — added an X that dismisses the intro (subtitle + sources bar); persisted via SharedPreferences (`assistant_intro_dismissed_v1`) so it stays hidden across sessions. Compliance disclaimer kept always-visible (`assistant_screen.dart`).
- [x] **Community → Reviews → Mama Approved™ flow** — built a dedicated **Share Provider Experience** screen (`share_provider_experience_screen.dart`): search a provider by name → leave a review. Wired the Community banner's "💜 Share Provider Experience" CTA to it (`community_survey_banner.dart`); added a public `searchProvidersByName` to the repository.
- [x] **Provider trust score** — the three experience questions (`feltHeard`/`feltRespected`/`explainedClearly`) are now aggregated into per-provider rates (`provider.dart`, computed in `enrichProviderWithReviews` + persisted in the post-submit aggregation). Mama Approved™ now requires 3+ reviews AND ≥4★ AND a ≥60% average affirm-rate across the three questions (`mamaApprovedMinExperienceRate`), with graceful fallback when no experience data exists.
- [~] **Provider profile rendering / badge bug** — **deferred per your call ("seems fine now").** Badge logic is intentional; revisit with live repro if badges go missing in search results (suspected silent enrichment failure).
- [x] **Community feedback survey** — replaced participation items with the mission-aligned set (understand care / prepare for appointment / useful info / would recommend) (`community_survey_banner.dart`).
- [x] **Pregnancy Details edit workflow** — editing already existed (due date, pregnancy status) but was hard to find; added a visible **Edit** button on the Pregnancy Details card that scrolls to the editable fields (`edit_profile_screen.dart`).

### Mama Approved™ — implemented (decisions from 2026-06-12)

Per the product decisions taken, the suite is now built:

- **Trust score from review questions** ✅ — `feltHeardRate` / `feltRespectedRate` / `explainedClearlyRate` added to `Provider`, computed in `enrichProviderWithReviews` and persisted on review submission. `showsMamaApprovedBadge` now requires 3+ reviews, ≥4★, AND ≥60% average affirm-rate across the three questions (`mamaApprovedMinExperienceRate = 0.6`), falling back to the rating+count rule when no experience data is present.
- **Community → Share Provider Experience → Review flow** ✅ — new `ShareProviderExperienceScreen` (search-by-name → review), reachable from the Community banner CTA. `ProviderRepository.searchProvidersByName` added.
- **Presentation (explainer + filter)** ✅ — "What mothers said" trust indicators on the profile; badge explainers (profile + search) updated to mention the experience questions; prominent **Mama Approved™ only** filter toggle above advanced filters in search.
- **Badge rendering bug** — deferred ("seems fine now"); revisit only with a live repro.

Decisions recorded: trust = *contribute to score*; flow = *dedicated share screen*; presentation = *explainer + filter*; badge bug = *skip*.

---

## V3 — Home Screen Revision (Health Literacy Integration)

Mostly already implemented in `lib/Home/home_screen_v2.dart`. Verified status below.

### 🎨 Frontend / UI changes

- [x] **Welcome section** — *"Welcome, Mama 💜 / You're supported — with clear answers and tools to speak up."* (`home_screen_v2.dart`)
- [x] **Search bar placeholder** — *"Search symptoms, tests, or what to ask your doctor"* (`home_screen_v2.dart:387`)
- [x] **Trimester card** — added line *"Here's what's happening — and what to ask at your next visit."* present (`home_screen_v2.dart`)
- [~] **Today's Guidance section** — present, but copy is **superseded by the V4 request** to simplify copy + reduce card height (see V4 above). Card lives in `home_emotional_support_card.dart`.
- [x] **"Understand Your Care" cards** — all three present (`home_screen_v2.dart`): *What does this test mean? / Is this normal? / Know your rights in care*
- [x] **Your Space labels** — *My Visits & What It Means*, *My Birth Choices*, *My Care Plan* present; *How I'm Feeling* unchanged (`home_screen_v2.dart`)
- [x] **Assistant button microcopy** — *"Ask me anything about your care or what to do next"* (`lib/assistant/assistant_screen.dart`)

### ⚙️ Functionality / scope notes

- [ ] **Apply the V4 reorder on top of V3 layout** — see "Home screen layout reorder" in V4 (the V3 sections exist but are not yet in the V4 order).
- [i] **Product Support Definition** (Understanding / Preparation / Navigation / Connection) — framing/scope statement, not a direct code change. The app supports users in understanding, preparing for, and navigating existing healthcare/community systems; it does not directly deliver medical care.

---

## Reference specs already covered by prior work (confirm only)

These sections of the doc are detailed specs that align with existing commits
(`emotional support pathway`, `Pregnancy Loss V2`) and code directories
(`lib/care_survey`, `lib/emotional_support`, `lib/immediate_support`,
`lib/pregnancy_loss`, `lib/support_stage`). No new action assumed — verify against current build:

- **Care Needs Check-In** (Service Gap Detection + Personalized Support) — multi-select care needs + modular personalized support logic.
- **Immediate Support Pathway** (Trauma-Informed Universal Support Flow) — support entry points, support screen/options, per-selection display logic, content-source rules (988, PSI, SAMHSA, ACOG, CDC), AI guardrails (no diagnosis/risk/clinical advice), safety language, home screen support card.
- **Developer notes:** no structured "pregnancy loss" status field; no sensitive-event categories stored or in research exports; support interactions remain user-controlled and skippable; content stays educational/navigational, not clinical.

> The doc ends with an empty heading **"OTHER AREAS OF UPDATES NEEDED"** (no content).
