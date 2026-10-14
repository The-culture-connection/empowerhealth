# Hearth restyle handoff

| File | What it is |
|---|---|
| `HEARTH_BUILD_PLAN.md` | The plan Claude Code follows: preflight, hard gates, phases 0–16, checks, manual checklist |
| `THEME_SPEC.md` | The theme as Flutter values: colour tokens, type, shapes, components, icons |
| `SCREEN_MAP.md` | Every mockup, the Dart file it was drawn from, its phase, and notes |
| `PROGRESS.md` | Filled in by Claude Code as each screen is matched; drift log |
| `phases.json` | Which Dart files and mockups belong to each phase (read by the verify script) |
| `string-allowlist.json` | Literals that may disappear, each with a reason (starts empty) |
| `baseline.json` | Written in Phase 0: the commit and every string that must survive |
| `mockups/` | The 112 design artboards (`.dc.html`, exact sizes and colours in inline styles) and the canvas layout |
| `png/` | A 2× render of every mockup with the real fonts — the visual target |

Also part of the handoff: `CLAUDE.md` (repo root), `scripts/hearth/verify.mjs`,
`assets/fonts/hearth/` (Young Serif and Figtree, OFL licensed).

Kick-off message for Claude Code:

> Read CLAUDE.md, then design/hearth/HEARTH_BUILD_PLAN.md, THEME_SPEC.md and SCREEN_MAP.md. Run
> Phase 0, then Phases 1–16 in order without checking in except at the hard gates. Report back as
> the plan's "Report back" section describes.
