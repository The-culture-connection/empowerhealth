# Hearth restyle: build plan

**For:** Claude Code, working in this repo (`empowerhealth-main`, Flutter 3.41.x).
**Goal:** every screen of the app takes on the "Hearth" look, matching the 112 mockups in
`design/hearth/`, with one consistent theme, and **nothing built or fixed on 10/7 is undone**.
**Scope:** look only. Colours, type, spacing, shapes, icons, card/button/chip styles, screen chrome,
and emoji removal. No new features, no layout restructuring beyond what the mockups show for an
existing element, no copy changes. The open items in `UNFIXED-REVISIONS-TODO.md` are a separate,
later job; do not work on them here.

Read in this order: `CLAUDE.md` → this plan → `design/hearth/THEME_SPEC.md` → `design/hearth/SCREEN_MAP.md`.

---

## The one rule that matters most: source of truth

The mockups were drawn from the code as it stood around 6 pm on 10/7. Five QA rounds landed after
that (`79caf91eb` … `63bf7b881`), touching almost every screen. So:

| Question | Follow |
|---|---|
| Which sections, cards, buttons, fields and steps exist, in what order, and what they say and do | **The current Dart code** |
| What those things look like: colour, font, size, spacing, radius, borders, icons, header/nav/sheet style | **The mockup** (and `THEME_SPEC.md` for exact numbers) |
| The code has an element the mockup doesn't show | Keep it; style it with the nearest Hearth component; log it in `PROGRESS.md` → Drift |
| The mockup shows an element the code doesn't have | Do not add it; log it in Drift |
| The mockup's sample text differs from the code's text | Keep the code's text (mockup text is sample data) |

"Copied exactly" means the look is copied exactly. It never means replacing today's code with the
mockup's content.

---

## Preflight (Phase 0) — before any code changes

1. `git status` — you are on `prelaunch-review-fixes`. `lib/` and `pubspec.yaml` must have no
   uncommitted changes. (Untracked .docx files and `UNFIXED-REVISIONS-TODO.md` edits are the
   owner's; leave them alone, never commit them.) Commit the handoff files on their own:
   `git add CLAUDE.md design/hearth scripts/hearth assets/fonts/hearth` then
   `git commit -m "Hearth: add restyle handoff (plan, spec, mockups, fonts, verify script)"`.
2. `flutter --version` reports 3.41.x (the QA harness Dockerfile pins 3.41.6). `flutter pub get` succeeds.
3. `flutter analyze` and `flutter test` run. Note the counts. If `flutter test` fails **before you
   change anything**, stop and report which tests fail (hard gate) — you would not be able to tell
   your breakage from existing breakage.
4. Record the baseline (what must not change):
   `node scripts/hearth/verify.mjs baseline --with-flutter`
   This writes `design/hearth/baseline.json`: the current commit, every string literal in `lib/`, and
   the analyzer error count. Commit it alone: `Hearth: record baseline before restyle`.
   If a baseline already exists from an earlier session and HEAD has moved since, do not overwrite
   it — ask.
5. Confirm the unused-screen list: `node scripts/hearth/verify.mjs phase all --no-flutter` prints
   `info` lines for any "legacy" file that is now referenced. Those are in scope for Phase 16.

**Done when:** `baseline.json` is committed and `node scripts/hearth/verify.mjs phase 0` prints `RESULT: PASS`.

---

## Hard gates — stop and ask the owner

- Any change under `lib/services`, `lib/models`, `functions/`, Firestore/Storage rules, `deploy/`,
  `tool/`, `scripts/search-check`, or the QA harness files (`lib/qa/*.dart` except the generated
  `widget_index.g.dart`). The verify script fails on these.
- Any change to `pubspec.yaml` other than the fonts block (no new packages).
- Any string that the verify script reports as missing, unless it is plainly a style literal you
  replaced (then add it to `design/hearth/string-allowlist.json` with a reason). Never reword copy to
  make the check pass.
- `git push`, any deploy (`firebase deploy`, Railway), `git reset --hard`, rebase, amend of someone
  else's commit, force anything, deleting files.
- Writing data in a running app against the real Firebase project (posting, reviewing, uploading a
  visit, saving a profile) without a test account the owner has given you.
- Someone else committed to this branch while you work and their commit touches a file you are
  restyling. (New commits on other files are fine: re-run the phase check and carry on.)
- `flutter test` or `flutter analyze` gets worse and the cause is outside the files in scope.

Everything else (including code/mockup drift) you decide yourself and log in `PROGRESS.md`.

---

## Files touched map

| Phase | Files |
|---|---|
| 0 | `design/hearth/baseline.json` (new) |
| 1 | `pubspec.yaml` (fonts block only), `assets/fonts/hearth/*` (already supplied), `lib/cors/ui_theme.dart`, `lib/widgets/ambient_background.dart`, `test/hearth_theme_test.dart` (new) |
| 2 | `lib/design_system/hearth.dart` (new), `lib/design_system/widgets.dart`, `lib/cors/main_navigation_scaffold.dart`, shared widgets in `lib/widgets/` listed in `phases.json`, `test/hearth_components_test.dart` (new), `lib/qa/widget_index.g.dart` (regenerated) |
| 3–15 | exactly the files listed for that phase in `design/hearth/phases.json` |
| 16 | any remaining `lib/` file the whole-app lint flags |
| all | `design/hearth/PROGRESS.md`, `design/hearth/string-allowlist.json` |

If you need to touch a file not on this map, say why in the phase's commit message.

---

## Phase 1 — Theme foundation

**What is wrong:** `lib/cors/ui_theme.dart` defines the old palette (gradients, turquoise, lavender
washes, six grey-purple text shades, purple drop shadows) and the `Primary`/`Secondary` fonts.
`AmbientBackground` paints a beige-to-lavender gradient behind Home, Journal and Community, which is
why those tabs look different from Learn and You. 1,100+ raw `Color(...)`/`Colors.*` literals are
spread across screens.

**Change:**
1. Add the five font files (already in `assets/fonts/hearth/`) to the pubspec fonts block exactly as
   in THEME_SPEC §2. Keep the old families until Phase 16.
2. In `ui_theme.dart`: re-point every existing token and add the new ones per THEME_SPEC §1; make the
   two gradients single-colour and `shadowSoft()`/`shadowMedium()` return `const []`; mark retired
   tokens `@Deprecated('Hearth: use …')`.
3. Rebuild `AppTheme.light()` around Hearth: scaffold background `ground`; text theme per §2
   (YoungSerif for display/headline, Figtree for the rest); `elevatedButtonTheme`/`filledButtonTheme`
   purple stadium 52 high; `outlinedButtonTheme` purple outline; `textButtonTheme` purple 700;
   `inputDecorationTheme` per §3; `chipTheme`; `checkboxTheme`/`radioTheme`/`switchTheme` purple;
   `cardTheme` (surface, radius 24, 1px border, elevation 0); `dialogTheme` and `bottomSheetTheme`
   (ground, radius 28); `appBarTheme` (ground, ink, YoungSerif 20, no elevation);
   `bottomNavigationBarTheme` per §4. Leave `dark()` and `ThemeMode.light` as they are.
4. `newUiAppBar` and `responsiveTitleStyle`: switch to YoungSerif/ink.
5. `AmbientBackground`: keep the widget and its constructor, render a flat `ground` fill.

**Done when:** `node scripts/hearth/verify.mjs phase 1` passes. Launching the app, every tab has the
same flat warm ground and the new fonts, even though individual screens still have old details.
Do not fix individual screens in this phase.

**Test:** `test/hearth_theme_test.dart` — asserts each THEME_SPEC §1 token's value, that the text
theme uses YoungSerif for headlines and Figtree for body, and that buttons are stadium-shaped and
52 high. *Proves: the app has one palette and one type pairing, matching the owner's "same colours,
one streamlined theme" requirement.*

---

## Phase 2 — Shared components and app chrome

**What is wrong:** each screen hand-builds its own cards, headers, chips and buttons (that is why
they drift apart). `lib/design_system/widgets.dart` (`DS.cta` ~line 65, `DS.secondary` ~84,
`DS.heroHeader` ~247) uses gradients and random background images. The bottom nav and the floating
assistant button live in `lib/cors/main_navigation_scaffold.dart` (nav items ~lines 319–355, FAB
~256–262 and ~374–402).

**Change:**
1. Create `lib/design_system/hearth.dart` with every component in THEME_SPEC §4. Each takes the
   app's existing strings and callbacks as parameters; none holds copy of its own.
2. Re-implement the `DS.*` helpers on top of the Hearth components so screens still calling `DS`
   pick up the look. Keep their signatures.
3. In `main_navigation_scaffold.dart`, swap the nav bar for `HearthBottomNav` and the FAB for
   `HearthSupportFab`, keeping the existing tab logic, the `_index == 0` rule (Home only), the
   keyboard-hidden rule and `Navigator.pushNamed(Routes.assistant)`.
4. Restyle the shared widgets listed for phase 2 in `phases.json` (disclaimer banner, trust cue,
   Mama Approved badge, survey dialog, step scroll).
5. Regenerate the QA widget index: `dart run tool/gen_qa_widget_index.dart`.

**Done when:** `node scripts/hearth/verify.mjs phase 2` passes; the bottom nav matches the bottom of
`png/Main.png` (gold bar over the active tab, all five labels fully visible), and the Support button
appears on Home only.

**Test:** `test/hearth_components_test.dart` — pumps each component at 390 px wide with the app's
longest real strings ("My Visits & What It Means", "Danielle Whitfield, CNM" plus the Mama Approved
badge, the five nav labels, a long option-row label), then asserts `qaRunAudit()` (from
`lib/qa/layout_auditor.dart`) reports no `squeezed`, `mid-word`, `truncated` or `overflow` issues and
Flutter raised no overflow error. *Proves: the defects from the pre-launch review (one-letter
columns, broken words, clipped labels, cut-off "You") cannot come back through the shared components.*

---

## Phases 3–15 — screen sweeps

Each phase restyles the Dart files listed for it in `design/hearth/phases.json` to match its
mockups (`design/hearth/SCREEN_MAP.md` lists them with notes). Same steps every time:

1. Open the phase's PNGs and mockup files. Read each Dart file's `build` method fully before editing.
2. Replace hand-built containers with Hearth components; replace every raw colour, gradient, shadow,
   old font and retired token with Hearth tokens; apply the mockup's spacing, type and chrome.
3. Remove emoji from user-facing strings (icon in its place where it carried meaning). Change
   all-caps section headings to sentence case. Touch no other copy.
4. Keep every widget's behaviour: callbacks, navigation, validation, conditions, keys, analytics calls.
   Restyle the widget in place; do not rebuild a screen from the mockup.
5. Run the app, open each screen of the phase at 390×844, compare with its PNG, and fill its rows in
   `PROGRESS.md` (Match yes/no, notes). Log every code/mockup difference under Drift.
6. `node scripts/hearth/verify.mjs phase <N>` must pass, then commit: `Hearth phase N: <name>`.

| Phase | Area | Mockups |
|---|---|---|
| 3 | Sign in and onboarding | `Start-*` (14) |
| 4 | Create your profile | `Setup-*` (8) |
| 5 | Home | `Main`, `Home-*` (10) |
| 6 | My visits | `Visits-*` (10) |
| 7 | Learn | `Learn-*` (9) |
| 8 | Journal | `Journal-*` (6) |
| 9 | Community | `Community-*` except the loss variant (6) |
| 10 | Find your care | `Care-Search*`, `Care-Loading`, `Care-Results*`, `Care-MamaApproved` (7) |
| 11 | Provider profile and reviews | `Care-Provider`, `Care-Report`, `Care-Review`, `Care-ShareExperience*`, `Care-AddProvider*` (7) |
| 12 | Birth plan | `Birth-*` (9) |
| 13 | You and privacy | `You-*` (12) |
| 14 | Assistant and support | `Support-*` (5) |
| 15 | Pregnancy-loss mode | `Loss-*`, `Community-Feed-Loss` (9) |

**Done when (each phase):** `verify.mjs phase N` prints `RESULT: PASS`; every mockup row for the
phase in `PROGRESS.md` is filled; the phase is committed.

**Test (each phase):** the verify script's `strings` check — *proves no copy, option list, label or
route string from 10/7 was lost* — and its `lint` check — *proves the phase's files use only Hearth
tokens and no emoji*. Existing `flutter test` suites (Mama Approved threshold, learning markup, note
highlights, layout auditor, analytics) keep passing — *proves today's behaviour fixes still hold.*

### Phase notes that are easy to get wrong

- **5 Home:** the support FAB already exists only on Home; keep it that way. Search field icon is the
  sparkle. Keep every Home section the code currently renders, in its current order.
- **5 & 14:** `immediate_support_home_card.dart` appears on Home and in support flows — check both.
- **8 Journal:** three states in one file (hub / quick / write). The mode chooser belongs to the hub only.
- **9 & 15:** `community_screen.dart` renders both the normal feed and the pregnancy-loss feed. After
  phase 15, re-check `Community-Feed`.
- **7 & 15:** loss learning topics reuse `learning_module_detail_screen.dart`. After phase 15,
  re-check `Learn-Module`.
- **13 & 15:** the support-stage tile and its picker sheet live in `support_stage_settings_tile.dart`
  (phase 13) and lead into the loss transition (phase 15). Check the whole path once at the end.
- **10:** the provider search was rewritten on 10/7 (`a8241a27a`) and passed a 299-check live test.
  Restyle only; do not touch how searches are built or results merged. Re-run nothing against
  production for this.
- **14 & 15:** 988 actions are purple (hub) and gentle cream rows (loss mode), as in code. No red.
- **Welcome screen (3):** the mockup shows a placeholder where the app has a real photo; keep the photo.

---

## Phase 16 — Global sweep and final check

1. `node scripts/hearth/verify.mjs phase all` and fix every remaining finding in files not covered
   above (dialogs, shared widgets, legacy screens the script says are referenced). For screens with
   no mockup, use the nearest pattern and list them in `PROGRESS.md`.
2. Remove the `Primary`/`Secondary` font entries from pubspec once nothing references them, and
   delete the deprecated tokens once unused (keep `assets/fonts/Primary.ttf` and `secondary.ttf`
   files on disk; deleting files is a hard gate).
3. Regenerate the QA widget index.
4. Walk the integration pairs above once more.

**Done when:** `node scripts/hearth/verify.mjs phase all` prints `RESULT: PASS`, `PROGRESS.md` has all
112 rows filled, and the final commit is made. Then report to the owner (see "Report back").

---

## Criteria matrix (all checked by `node scripts/hearth/verify.mjs phase all`)

| Owner's requirement | Machine check | Where |
|---|---|---|
| One streamlined theme, same colours | No raw colour, gradient, retired token or drop shadow in any in-scope file; Hearth tokens present | `lint`, `theme` |
| Warm, not clinical type | YoungSerif and Figtree bundled and used; no `Primary`/`Secondary` | `theme`, `lint` |
| No emoji | No emoji in any user-facing line | `lint` |
| Don't roll back today's adjustments | Baseline commit still in history; every baseline string literal still present; services/models/functions/rules/QA tooling unchanged; existing tests unmodified and passing | `history`, `strings`, `protected`, `flutter` |
| Organisation, buttons and labels the same | Every label, option and route string present (case/emoji ignored) | `strings` |
| Nothing breaks | Analyzer errors not above baseline; `flutter test` passes | `flutter` |
| Shared parts don't reintroduce clipping | Component audit test | `flutter` (`hearth_components_test.dart`) |

**A passing check is not proof the screens look right.** The script proves the plumbing (tokens,
copy, protected code). Whether each screen matches its mockup is only proven by looking at it.

## What cannot be proven automatically

- That each running screen matches its PNG (spacing, hierarchy, feel).
- That every state of a screen (empty, error, long names, large text) still looks right.
- That a screen not drawn in the mockups was restyled sensibly.
- That behaviour is unchanged beyond what the existing tests cover (the string check catches lost
  copy and keys, not a changed `onTap`).

## Manual checklist (for the owner, on the QA harness or a phone)

| Do this | Expect this | Something is wrong if |
|---|---|---|
| Open each of the five tabs | Same warm cream background, serif titles, gold bar over the active tab | Any tab has a lavender/beige gradient, or a nav label is cut off |
| Look at Home | Matches `png/Main.png`; Support button bottom-right | Support button shows on another tab |
| Open Learning center → a module → Save to Journal | Module and notes dialog match `Learn-Module`, `Learn-Notes` | A button or step that worked yesterday is missing |
| Journal: Quick check-in, pick a mood, Save | Nature icons, no emoji, saves as before | Faces/emoji appear, or saving fails |
| Find your care: search a ZIP with no specialty | Results load as before (search passed its live test 10/7) | You are asked for a specialty, or results differ from yesterday |
| Open a provider → Write a review | Matches `Care-Provider`, `Care-Review` | Badge squeezes the name, stars or chips look off-palette |
| Birth plan builder, all five steps | Matches `Birth-Builder-*` | A question or option from yesterday is missing |
| You tab → Privacy & Trust Center | Matches `You-Profile`, `You-Privacy` | Edit Profile collides with the name |
| Turn on Bold Text / large text in the harness | Text wraps, nothing clips | One-letter columns or "…" on essential text |
| Switch support stage to pregnancy loss | Calm screens, no decorative circle, 988 as soft rows | Bright accents or red buttons |
| Compare a few screens with yesterday's build | Same buttons, same words, new look | Anything you relied on is gone or reworded |

## Report back (end of run)

One message: phases completed, `verify.mjs phase all` result, the Drift table, screens restyled
without a mockup, anything in the string allowlist with its reason, and anything you stopped on.

## After this plan

1. **Execute** — run Phases 0–16 in order without checking in, except at hard gates.
2. **Adversarial review** — a fresh Claude Code session (not this one) reads the diff from the
   baseline commit and looks for behaviour that changed under a restyle, and for collisions between
   phases (the pairs listed above).
3. **QA harness pass** — the owner pushes the branch when satisfied; Railway rebuilds the harness;
   `node scripts/hearth/verify.mjs deployed --url <harness URL>` confirms the deployed build is this
   commit; run the harness layout audit on each screen.
4. **The owner's eyes** — the manual checklist above.
