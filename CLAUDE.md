# Working rules for this repo

These rules are for the Hearth restyle (see `design/hearth/HEARTH_BUILD_PLAN.md`). Read that plan
before starting work.

## What this app is

EmpowerHealth Watch — a Flutter maternal-health app (`lib/`), Firebase backend (`functions/`,
Firestore), and a Flutter-web QA harness deployed on Railway (`deploy/webapp`, `lib/qa/`).

## Editable vs read-only during the restyle

- Editable: the Dart files listed in `design/hearth/phases.json`, `lib/cors/ui_theme.dart`,
  `lib/design_system/`, the pubspec **fonts block**, new tests under `test/`, and the tracking files in
  `design/hearth/` (`PROGRESS.md`, `string-allowlist.json`, `baseline.json` in Phase 0 only).
- Read-only: `lib/services/`, `lib/models/`, `functions/`, Firestore/Storage rules, `deploy/`, `tool/`,
  `scripts/search-check/`, `lib/qa/*.dart` (except regenerating `widget_index.g.dart` with
  `dart run tool/gen_qa_widget_index.dart`), existing tests, `design/hearth/mockups/`, `design/hearth/png/`,
  and the owner's review documents (`*.docx`, `*.pdf`, `*-TODO.md`, `V4_*`).

## Source of truth

Current Dart code decides content, order and behaviour. Mockups decide the look. Never paste mockup
copy over code copy; mockup text is sample data.

## Git

- Work on the current branch, `prelaunch-review-fixes`. Commit after each phase with a message
  starting `Hearth phase N:`. Never push, never deploy, never reset, rebase, amend or force.
- Commit only your own files. Never stage the owner's untracked `.docx` files or their edits to
  `UNFIXED-REVISIONS-TODO.md` / other TODO docs.
- Another session may commit to this branch while you work. Before each phase, `git status` and
  `git log -3`. If a new commit touches a file you are restyling, stop and ask.

## Checks

- After every phase: `node scripts/hearth/verify.mjs phase <N>` must print `RESULT: PASS`.
- Never edit `scripts/hearth/verify.mjs`, `design/hearth/phases.json` or `design/hearth/baseline.json`
  to make a check pass. If a check is wrong, stop and say why.
- A passing script is not proof a screen looks right. Look at the running screen next to its PNG.

## Code style

- Write and edit code with file tools (Edit/Write), never with shell one-liners (`sed`, `echo >`,
  PowerShell `Set-Content`): escape sequences get eaten and the file still looks fine.
- Colours only through `AppTheme` tokens; shapes and text styles from the theme or
  `lib/design_system/hearth.dart`. No raw `Color(0x…)` / `Colors.*` (except `Colors.transparent`)
  outside `ui_theme.dart` and `hearth.dart`.
- No emoji in user-facing strings. Leave `print`/`debugPrint` lines alone.
- Match the surrounding comment style: short, plain sentences explaining why, not what.
- The test font renders every glyph as a 14px square; layout tests that use `qaRunAudit()` rely on that.

## Environment notes

- Flutter 3.41.x (the harness Dockerfile pins 3.41.6). The owner's machine is Windows.
- The app talks to the production Firebase project. Do not create, edit or delete real data while
  checking screens unless the owner gives you a test account.
