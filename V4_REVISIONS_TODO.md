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

- [ ] **Today's Guidance card** — simplify the card copy and reduce card height.
  New copy: *"Today's Guidance / Understand your care, prepare questions, and find support. / See options →"*
  (Card currently lives in `lib/emotional_support/widgets/home_emotional_support_card.dart`. This supersedes the V3 Today's Guidance copy.)
- [ ] **Care Check-In card** — update copy so it no longer overlaps with Today's Guidance:
  *"Care Check-In / Tell us what you needed help with and whether you got it. / Start check-in →"*
- [ ] **Trimester / Learning Center card** — convert the large purple trimester card into a shorter learning card:
  *"Week 38 • Third Trimester / What to expect this week, what to ask, and when to call your provider. / Open Learning Center →"*
- [ ] **Home screen layout reorder** — current order is Welcome → Search → Trimester → Today's Guidance → Understand Your Care → Your Space → Community.
  Requested order: **Welcome/Search → Your Space → Today's Guidance → Care Check-In → Trimester Learning Card → Community**
- [ ] **"Know your rights" entry copy** — *"Know your rights / Understand your options and feel confident speaking up."*
- [ ] **Remove AI banner** — delete the *"Extra topics below use personalized explanations (AI) — unique to this app"* banner from the Know Your Rights page.
- [ ] **Learning module feedback widget** — add a post-completion feedback prompt placed immediately after module completion (not low on the page):
  - After learning modules: *"Did this help?"* → 💜 I understand it better now / 🙂 It helped a little / 😕 I still have questions
  - After care planning / birth planning / checklists: *"How do you feel now?"* → 💪 I feel more prepared / 🙂 A little more prepared / 😕 Still unsure
- [ ] **Community section copy** — replace *"Help another mama"* with *"Help Another Mama Choose Care"*;
  description: *"Share your experience with a provider, hospital, doula, or birth team. Your feedback helps other mothers find care where they feel heard, respected, and supported."*;
  CTA: *💜 Share Provider Experience*
- [ ] **Support icon discoverability** — the Support feature (💜🤲 icon) needs a label ("Support" / "Get Support"), a first-time tooltip, or a dedicated support card so its purpose is clear.
- [ ] **Mama Approved™ presentation** — surface it as a core trust feature throughout provider search/profiles (clarify purpose and value), not an isolated badge.

### ⚙️ Functionality changes (logic, data, workflows)

- [ ] **"My Visits" stuck on loading** — fix the data load under *My Visits* (currently shows "loading").
- [ ] **Provider search → universal search** — return matching results regardless of provider type; make specialty filters optional, not required before searching.
- [ ] **Know Your Rights — Save to Journal** — review the Copy functionality and replace/supplement it with Save to Journal using the existing note workflow.
- [ ] **Learning Module actions** — review the Add Note / Save / Copy / Share workflow; replace Copy with Save to Journal; leverage the existing journal tagging system.
- [ ] **Journal auto-categorization** — auto-tag saved entries based on their source section:
  - Know Your Rights → Rights & Self-Advocacy
  - Questions to Ask → Questions for My Provider
  - Birth Preferences → Birth Preferences
  - Labor & Delivery Education → Labor & Delivery Questions
  - Health Made Simple → Health Information I Want to Remember
  - Emotional Support → Emotional Reflection
  - *Goal: users should not have to manually organize every saved item — the app already knows the content source.*
- [ ] **AI Assistant intro card — dismissible** — add an X to close it; once dismissed it stays hidden in future sessions (requires persistence) unless reset. Primary focus of the screen should be the user's questions and the assistant's responses.
- [ ] **Community → Reviews → Mama Approved™ flow** — build explicit navigation linking the three (Community Experience → Share Provider Experience → Provider Review Submission → Provider Trust Score → Mama Approved™ Badge). Make provider review submissions the primary source of Mama Approved™ qualification.
- [ ] **Provider trust score** — feed review responses (*"I felt heard," "I felt respected," "Things were explained clearly"*) into trust indicators and Mama Approved™ scoring.
- [ ] **Fix provider profile rendering** — resolve rendering issues that hide Mama Approved™ badges on provider profiles.
- [ ] **Community feedback survey** — evaluate/replace current participation-focused items (*"I feel supported by this community," "I feel heard when I share something here"*) with mission-aligned alternatives:
  - This app helped me understand my care.
  - This app helped me prepare for an appointment.
  - I found information that was useful to me.
  - I would recommend this app to another mother.
- [ ] **Pregnancy Details edit workflow** — verify users can edit Due date, Current pregnancy status, Pregnancy stage/week (recalculated from due date), and other pregnancy profile info. If it exists, make the entry point more visible; if not, add the edit workflow (this data drives personalized content throughout the app).

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
