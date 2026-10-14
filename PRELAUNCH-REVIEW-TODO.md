# Pre-Launch Developer Review — TODO

Source: `EmpowerHealth_Watch_Final_PreLaunch_Developer_Review.docx`. Fixed on branch `prelaunch-review-fixes` (from `main`; `production` is stale and does not contain the reviewed screens).
P0 = release blocker, P1 = fix before public promotion, P2 = polish.

## Cross-screen
- [x] P0 Remove fixed/narrow text columns so text never renders one-char-per-line or word-by-word
- [x] P1 No ellipsis/clipping on essential labels, titles, dates, descriptions
- [x] P1 Generated woman-facing content uses "you/your", not "The patient..."
- [x] P2 Floating support/heart control never covers content, fields, CTAs or bottom nav

## 1. Home
- [x] P1 "My Visits & What It Means" / "My Care Plan" card copy wraps mid-word — give more width
- [x] P1 Search placeholder truncated ("Search symptoms, t...")
- [x] P1 "Find your care team" supporting text truncated
- [x] P1 "EmpowerHealth Watch" product name breaks mid-word on Community card
- [x] P1 Trimester learning card heading renders incomplete
- [x] P2 Floating support icon over lower-right content

## 2. Learn
- [x] P1 Learning Center module cards clipped horizontally
- [x] P0 Next Steps cards: description squeezed into narrow right column — use full width, move checkbox/badge
- [x] P1 Next Steps text uses "The patient..." — convert to "you/your"
- [x] P1 Long task descriptions — concise summary first, details behind expansion
- [x] P2 Add section context between Know Your Rights and visit-derived Next Steps
- [x] P1 All / Modules / Archived filters show distinct states; Archived empty state shows no active cards
- [x] P1 Trimester card title/subtitle truncated ("Second trimes…", "Week 18 of 40 · W…")
- [x] P1 Home trimester banner deep-links to the single trimester module (one source of truth)

## 3. Journal
- [x] P2/P1 "Save check-in" button oversized and wraps — balance with Cancel, one line
- [x] P1 Recent reflections date truncated — use "Sep 26, 2026"
- [x] P2 Floating heart overlaps content

## 4. Community
- [x] P0 "Community" header breaks to "Communit"+"y" — responsive header
- [x] P1 Category tabs clipped — deliberate horizontal scroll with edge affordance
- [x] P1 "Help Another Mama Choose Care" intro card too tall/centered — shorter, left-aligned, keep dismiss
- [x] P1 "Share app feedback" CTA inside provider-experience card — separate/relabel
- [x] P2 Post metadata low contrast/crowded
- [x] P1 Delete icon only for owner or moderator
- [x] P1 Category tabs filter correctly; create post records category, anonymous option visible

## 5. You / Profile
- [x] P0 Profile summary card name renders one char per line
- [x] P0 Updated-date metadata renders vertically
- [x] P1 Header subtitle "Manage your information and pr..." clipped
- [x] P1 Edit Profile button competes with name — stable separate row
- [x] P1 Privacy & Trust Center card copy narrow column
- [x] P2 Section label spacing/alignment consistent

## 6. AI Assistant
- [x] P1 Composer hidden by iOS keyboard — keep it above keyboard
- [x] P1 Re-entry lands mid-response — open at bottom, add "New conversation"
- [x] P1 Consistent behavior across entry paths
- [x] P1 External resource links (CDC Hear Her, 211, WIC) — verify destinations / return state

## 7. Find Your Care / Mama Approved
- [x] P0 Provider name wraps 1–2 letters per line — flexible header, badge in non-competing position
- [x] P1 Dense explanatory copy — shorten
- [x] P1 Mama Approved badge = ≥3 reviews AND avg ≥4.0 (verify boundaries)
- [x] P1 Search empty/no-result states understandable

## Manual QA (cannot be done in code)
- [ ] Regression test all five tabs on a small and a large iPhone viewport
- [ ] QA every external support link and return state on device
- [ ] Deploy `firestore.rules` (category required on posts; only owner/admin/community manager can delete; non-owners can only like/reply). Tested: `cd tests/firestore-rules && npm install && npm run test:emulator` (17 pass)
- [ ] Deploy functions (`firebase deploy --only functions`): "you/your" prompts, short next-step summaries, published-only review counts in search
- [ ] Verify in a browser: older CDC links (breastfeeding/pumping, formula-feeding, infant visits) in `lib/resources/app_external_resources.dart`
- [ ] Decide: no anonymous-posting option exists in Community (review assumed one might)
- [ ] Live-test standard + Expanded search with ZIP / radius / plan filters (filtering is done by the Ohio Medicaid API, so it cannot be unit-tested offline)
