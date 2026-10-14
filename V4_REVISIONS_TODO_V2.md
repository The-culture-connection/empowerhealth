# EmpowerHealth V4 Revisions — TODO

Source: [V4 Revisions Google Doc](https://docs.google.com/document/d/1iN2jJXTSGnmj-69I5cK5JNSh-MAZR_I0X8VPD4mWj00/edit)

> **Efficiency note:** the three provider-search / community items (Find your Care Team, Community + Mama Approved™, Help Another Mama Choose Care) all fail on the same root cause — **search still requires a specialty, and the review flow doesn't connect to the community page.** Fixing that one search behavior clears all three.

---

## Home screen
- [x] **Today's Guidance card** — simplify the copy and reduce card height.
  _Fixed — card now reads "Understand your care, prepare questions, and find support." with a "See options →" CTA; dropped the secondary line to reduce height (💜 kept in the section header)._
- [x] **Add the floating assistant icon back onto the homepage.**
  _Fixed — floating AI assistant button (bottom-right, Home tab only) opens the assistant._

## Provider search & Community / Mama Approved™
- [x] **Find your Care Team — universal search.** Return matching results regardless of provider type; specialty filters stay *optional*, never required.
  _Fixed — quick search no longer requires a provider type; blank text searches everyone nearby, and free text is treated as a name search. Removed the misleading "required" asterisk on Provider Type in expanded search._
- [x] **Community + Mama Approved™ alignment.** Make the flow clear: Community → Share Provider Experience → Review Submission → Provider Trust Score → Mama Approved™ badge.
  _Fixed — the review flow no longer dead-ends into a type-gated search; "no results" now offers "Search the full directory" (universal) and "Add a provider" so users can always reach a review._
- [x] **Community section copy** — replace "Help another mama" with **"Help Another Mama Choose Care."**
  Description: *"Share your experience with a provider, hospital, doula, or birth team. Your feedback helps other mothers find care where they feel heard, respected, and supported."*
  CTA: **💜 Share Provider Experience.**
  _Fixed — copy was already in; the "gets stuck if you don't know the provider type" was the same root cause, now resolved._
- [x] **Minimize the boxes and move them toward the bottom** — you currently have to scroll too far to reach the review.
  _Fixed — removed the large "You're among friends" hero + privacy banner from the top; category tabs and the "Share Provider Experience" review CTA now sit near the top, and a single minimized guidelines card moved to the bottom of the feed._
- [x] **Make the "Find your care team" banner part of the scroll view** (currently fixed/separate from the scroll).
  _Fixed — the header (location tag, title, search bar, Expanded search) now scrolls together with the provider list instead of being pinned._


## Know Your Rights
- [x] **Know Your Rights card** — copy: *"Understand your options and feel confident speaking up."*
  _Fixed — the Learning Center "Know your rights" card now uses that line; removed the old "Warm overviews plus optional personalized topics" description._

## Learning modules
- [x] **Feedback as an exit modal after leaving a learning module.**
  _Both questions ("Did this help?" and "How do you feel now?") now appear together in one bottom-sheet modal that pops up when the user navigates out of a learning module detail page. Removed the old inline surveys from the bottom of both module screens. Fixed the trigger — the custom back button was doing a direct `Navigator.pop` (bypassing `PopScope`); it and the system back now route through the modal first._
  - Make sure wired into admin dashboard user reporting
  _Fixed — both survey answers write to the `ModuleFeedback` collection (understanding/next-steps/confidence scores), which the dashboard's module-feedback report reads._
  - After care-planning / birth-planning — *"How do you feel now?"*
  _Also placed standalone on the **birth-plan** display screen. Care-planning tools / checklist screens still to get the same one-liner if wanted._

## Profile
- [x] **Fix the "Edit profile details" button** — currently not working.
  _Fixed & made obvious — the header button is now a prominent "Edit Profile" button that enters an edit mode: shows an "You're editing your profile…" banner, scrolls to the fields, and focuses the first field so the keyboard pops. Both edit buttons now trigger it; saving exits edit mode._

## App-wide / layout
- [x] **Correct the contact location.**
  _Fixed — provider addresses returned as raw API structures (`[{'ADDRESS_1':'…'}]`) are now parsed into a clean street line in `ProviderLocation.fromMap`, and phone numbers are formatted as `(513) 585-8222`. Applies everywhere providers render (search + profile)._
- [x] **Bottom-nav "You" label + global responsive review.**
  _Both bottom navs (standard + pregnancy-loss) are now scale-safe (`Expanded` items + `FittedBox` labels — can't clip). Added an app-wide text-scale clamp (0.9–1.3×). Ran a multi-agent responsive audit over all ~118 UI files that applied **27 conservative overflow fixes** (long/dynamic `Text` wrapped in `Flexible`/`Expanded` + ellipsis across home, provider, journal, checklist, birth-plan, profile, visit screens), plus fixed the survey rating row to shrink on small screens. `dart analyze` clean._
  - Remaining (lower priority, from the audit): width-proportional font sizes (`MediaQuery.width * fraction`) on the legacy home/auth screens over-scale on tablets → clamp them; a few fixed-px layouts (`SizedBox(width:112)` label column, square buttons) to convert to `ConstrainedBox`/`Wrap`.
