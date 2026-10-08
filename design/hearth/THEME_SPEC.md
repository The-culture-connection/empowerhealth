# Hearth theme spec (Flutter)

This is the visual system the 112 mockups in `design/hearth/mockups/` use, written as Flutter values.
The mockups are the picture; this file is the numbers. When a mockup and this file disagree, the
mockup wins for that screen; when the **current Dart code** disagrees with a mockup about content,
structure or behaviour, the **code wins** (see the plan's "Source of truth" rule).

Measurements in the mockups are CSS px at a 390-wide phone. Use them as Flutter logical pixels 1:1.
Line height in CSS (`15px / 22px`) becomes `TextStyle(fontSize: 15, height: 22 / 15)`.

## 1. Colour tokens (`lib/cors/ui_theme.dart`)

Keep every existing `AppTheme` name so the existing references keep compiling, and re-point
its value. Add the new names. Nothing outside `ui_theme.dart` and `design_system/hearth.dart` may
write a raw colour (`Color(0x…)`, `Colors.*` except `Colors.transparent`).

| Role | Hex | New name | Existing names to re-point to it |
|---|---|---|---|
| Page ground | `#F5F1E8` | `ground` | `backgroundWarm`, `lightBackground`, `backgroundGradientEnd` |
| Card / sheet surface | `#FAF8F4` | `surface` | `surfaceCard`, `backgroundGradientStart`, `navBarBgLight` |
| Inset field inside a card | `#F5F1E8` | `surfaceInset` | — |
| Field on the page ground | `#FAF8F4` | — | `surfaceInput` |
| Warm border (cards, fields, chips) | `#E6D5B8` | `borderWarm` | `borderLight`, `borderLighter`, `borderLightest`, `navBarBorderLight`, `borderSubtlePurple` (make it a const) |
| Warm tint (icon chips, highlighted card, tags, selected fill) | `#EFE0C6` | `tintWarm` | `gradientGoldStart`, `gradientBeigeStart`, `gradientBeigeEnd` |
| Gold (encouragement buttons, active-tab bar, badges) | `#D4A574` | — | `brandGold`, `brandGoldEnd`, `gradientGoldEnd`, `lightAccent` |
| Terracotta (star outline only) | `#C4956A` | — | `brandTerracotta` |
| Star outline (filled star) | `#8F5F33` | `starStroke` | — |
| Purple (primary actions, links, icons, selected outline) | `#663399` | — | `brandPurple`, `lightPrimary`, `brandTurquoise` (retire), `lightSecondary` (retire) |
| Purple step (chip on a purple card) | `#7744AA` | — | `brandPurpleMid` |
| Lavender (assistant bubbles, AI notes only) | `#EDE7F3` | `lavender` | `gradientPurpleStart`, `gradientPurpleEnd`, `ambientPurpleBlur` |
| Ink (headings, body) | `#2D2733` | `ink` | `brandBlack`, `textPrimary`, `lightForeground` |
| Secondary text | `#4A3F52` | — | `textSecondary` |
| Muted text (captions, placeholders, inactive nav) | `#6B5C75` | — | `textMuted`, `textLight`, `textLighter`, `textLightest`, `textBarelyVisible`, `navInactiveLight` |
| Text on purple | `#FFFFFF` / secondary `#F5F1E8` | `onPurple`, `onPurpleSecondary` | `brandWhite` |
| Emergency only | `#D4183D` | `emergency` | `error` |
| Sheet handle | `#C9B8A0` | `sheetHandle` | — |
| Modal scrim | ink at 45% (`0x732D2733`) | `scrim` | — |

Retired (keep the names compiling, then remove every use; the lint flags them): `brandTurquoise`,
`lightSecondary`, `lightMuted`, `primaryActionGradient`, `encouragementGradient`, all `gradient*`
colours, `ambientPurpleBlur`, `shadowSoft`, `shadowMedium`. Re-point the two gradients to a single
flat colour (`[brandPurple, brandPurple]`, `[brandGold, brandGold]`) and make `shadowSoft()` /
`shadowMedium()` return `const []` so nothing breaks while screens are converted.

Colour rules:
- No turquoise, green, blue or grey chips anywhere. Success/done = purple check or a tint tag.
- Red (`emergency`) is reserved for a true emergency control. The current app has none: the 988
  buttons are purple in the support hub and gentle cream rows in pregnancy-loss mode (copy the mockups).
- Destructive actions (Delete, Sign out, Block) use the outlined ink style, not red.
- Text on gold is always ink. Text on purple is white.
- At most one purple feature card per screen.

## 2. Type

Bundle the fonts (already supplied in `assets/fonts/hearth/`, OFL licences included):

```yaml
  fonts:
    - family: YoungSerif
      fonts:
        - asset: assets/fonts/hearth/YoungSerif-Regular.ttf
    - family: Figtree
      fonts:
        - asset: assets/fonts/hearth/Figtree-Regular.ttf
          weight: 400
        - asset: assets/fonts/hearth/Figtree-Medium.ttf
          weight: 500
        - asset: assets/fonts/hearth/Figtree-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/hearth/Figtree-Bold.ttf
          weight: 700
```

Keep the old `Primary` / `Secondary` entries in pubspec until no code references them (lint flags uses).
Do not fetch fonts at runtime (`google_fonts`) — the app must look right offline.

| Use | Family | Size / line height | Weight | Colour |
|---|---|---|---|---|
| Tab-root screen title | YoungSerif | 34 / 40 | 400 | ink |
| Pushed-screen title | YoungSerif | 26 / 32 | 400 | ink |
| Section heading | YoungSerif | 20 / 26 | 400 | ink |
| Feature-card title (tint or purple card) | YoungSerif | 19 / 25 | 400 | ink / white |
| Card or row title | Figtree | 16–17 / 22–24 | 700 | ink |
| Body | Figtree | 15 / 22 (14 / 21 inside cards) | 400 | secondary |
| Caption / meta | Figtree | 13 / 18 | 400 | muted |
| Field label | Figtree | 14 / 20 | 600 | ink |
| Button | Figtree | 16 | 700 | per button |
| Chip | Figtree | 14–15 | 600 (700 selected) | secondary / purple |
| Tag | Figtree | 12 / 18 | 700 | secondary |
| Bottom-nav label | Figtree | 11 | 500 (700 active) | muted / purple |

`ThemeData.textTheme`: display*/headline* → YoungSerif; title*/body*/label* → Figtree with the sizes above.
Section headings are never letter-spaced capitals. Where the source string is all caps
(`'UNDERSTAND YOUR CARE'`), change the literal to sentence case (`'Understand your care'`). The
string check ignores case, so this is allowed.

## 3. Shape and spacing

| Element | Spec |
|---|---|
| Screen side padding | 20 |
| Gap between sections | 24–28 |
| Gap between cards in a list | 12 |
| Card | radius 24, fill `surface`, 1px `borderWarm`, padding 16–20, **no shadow** |
| Feature card (tint) | radius 24, fill `tintWarm`, no border |
| Feature card (purple) | radius 24, fill `brandPurple`, white text, icon chip gold with ink icon |
| Icon chip | 46 circle, fill `tintWarm` (on a tint card: `surface`; on purple: gold), 22 icon in purple (ink on gold) |
| Text field | height 52, radius 18, fill `surfaceInput` (on page) / `surfaceInset` (in a card), 1px `borderWarm`, padding 0 16, 15/22 text; focused: 2px purple |
| Button | height 52, stadium shape, 16 / 700 |
| Chip / pill | height 44, stadium, padding 0 18 |
| Tag | stadium, padding 3 × 12 |
| Dialog | radius 28, padding 24, fill `ground` |
| Bottom sheet | top radius 28, fill `ground`, padding 12 20 32, handle 40 × 4 `sheetHandle` centred |
| Switch | 52 × 32 track; on = purple track, white knob; off = `borderWarm` track, `surface` knob |
| Checkbox / radio | 22, purple when on, sits at the **left** of its label |
| Touch target | ≥ 44 |

Only the floating Support button has a shadow (`0 6 18` ink at 20%, plus a 3px `ground` ring).

## 4. Components to build once (`lib/design_system/hearth.dart`)

Each one is drawn in the mockups; match it. Screens then use these instead of hand-rolled containers.

| Widget | What it is | Where to look |
|---|---|---|
| `HearthTabHeader(title, subtitle, trailing, warmCircle: true)` | Tab-root header: 34px serif title, 16/23 subtitle, decorative 200px `tintWarm` circle top-right (offset −70 top, −60 right, clipped). `warmCircle: false` in pregnancy-loss mode. Content starts 20 below the safe area. | `Main`, `Journal-Hub`, `Learn-Center`, `Community-Feed`, `You-Profile` |
| `HearthPushedHeader(title, subtitle, onBack, backLabel, actions)` | 44 back circle (`surface`, `borderWarm`, ink chevron), optional text label beside it, trailing 44 circle actions or a text action; 26px serif title below. Close × variant for modals. | most pushed screens, e.g. `Visits-Detail`, `Care-Provider` |
| `HearthCard`, `HearthFeatureCard(tone: tint \| purple)` | Cards above. | everywhere |
| `HearthIconChip(icon, tone)` | 46 circle chip. | everywhere |
| `HearthSectionHeading(text, trailing)` | 20/26 serif. | everywhere |
| `HearthRowCard(icon, title, subtitle, onTap)` | Icon chip + title + subtitle + chevron. | `Learn-Rights`, `You-Privacy` |
| `HearthButton.primary / .encourage / .secondary / .destructive / .text / .emergency` | Purple filled · gold filled with ink text · purple outline · ink outline · purple text with optional chevron · red (reserved). Keep whichever kind the code uses today. | everywhere |
| `HearthChoiceChip(label, selected)` | Unselected: `surface`, 1px `borderWarm`, secondary text 600. Selected: `tintWarm`, 2px purple border, purple text 700. Primary filter tabs (All / Modules / Archived) use solid purple for the selected one. | `Setup-*`, `Learn-Center`, `Community-Feed` |
| `HearthOptionRow(control: radio \| checkbox, label, selected)` | Full-width card row, control left; selected row = 2px purple border + `tintWarm`. | `Care-Report`, `Home-NeedsChecklist`, `Support-CheckIn` |
| `HearthTag(text, tone)` | Small stadium tag; "Mama Approved" = gold fill, ink text, heart icon. | `Care-Results`, `Learn-Center` |
| `HearthNote(icon, text, tone: cream \| lavender)` | Info / privacy / disclaimer note. AI disclaimers use lavender. | `Visits-Upload-Result`, `Support-Assistant` |
| `HearthStepProgress(step, total, label)` | "Step 2 of 7" caption over a 6px bar (track `borderWarm`, fill purple). | `Setup-*`, `Start-ResearchBaseline*` |
| `HearthStarRating(value)` | Filled stars gold with `starStroke` outline; empty stars outline `brandTerracotta`. | `Care-Review`, `Learn-Survey` |
| `HearthAvatar(initials)` | 46 circle `tintWarm`, serif 19 purple initials. | `Community-*`, `You-Profile` |
| `HearthBottomNav(index)` | 5 tabs Home / Learn / Journal / Community / You; `surface` fill, 1px top border; active = purple icon + 700 label + 24×3 gold bar on the top edge; inactive = muted. No label may be clipped ("You" was cut off before). | every tab root |
| `HearthSupportFab` | 60 purple circle, white headset icon, ground ring, shadow. **Home tab only**, opens the assistant (as the code does today). | `Main` |
| `showHearthSheet` / `showHearthDialog` | Theme-driven sheet and dialog shells. | `*-Dialog-*`, `Care-Report`, `Learn-Notes` |

Wire as much as possible through `ThemeData` (buttons, inputs, chips, checkbox, radio, switch,
dialog, bottom sheet, app bar, card) so plain Material widgets already look right.

## 5. Icons

Use Material outlined/rounded icons; no new icon package, no emoji, no images.

| Mockup icon | Flutter |
|---|---|
| home, book, heart, chat, person (nav) | `Icons.home_outlined`, `menu_book_outlined`, `favorite_border`, `chat_bubble_outline`, `person_outline` |
| search · sparkle (assistant search) | `search` · `auto_awesome_outlined` |
| document · checklist | `description_outlined` · `checklist` |
| shield · lock · info | `shield_outlined` · `lock_outline` · `info_outline` |
| pencil · plus-in-square · plus · check · close | `edit_outlined` · `add_box_outlined` · `add` · `check` · `close` |
| chevrons / back | `chevron_right`, `expand_more`, `arrow_back_ios_new` (or `chevron_left`) |
| headset (Support) | `headset_mic_outlined` |
| calendar · upload · pin · phone · bell | `calendar_today_outlined` · `upload_outlined` · `location_on_outlined` · `phone_outlined` · `notifications_none` |
| star | `star_rounded` / `star_outline_rounded` |
| share · trash · flag · external | `ios_share` · `delete_outline` · `flag_outlined` · `open_in_new` |
| Moods: Joyful · Calm · Okay · Worried · Tearful | `wb_sunny_outlined` · `eco_outlined` · `waves` · `cloud_outlined` · `water_drop_outlined` |

## 6. Screen chrome

- **Tab roots** (Home, Learn, Journal, Community, You): `HearthTabHeader`, `HearthBottomNav`. Support FAB on Home only.
- **Pushed screens**: `HearthPushedHeader`, no bottom nav unless the code shows one today.
- **Dialogs / sheets**: `showHearthDialog` / `showHearthSheet`.
- **Pregnancy-loss mode**: same components, `warmCircle: false`, no decorative accents, purple only for actions.
- Remove `AmbientBackground`'s gradient wash: make it render the flat `ground` colour (keep its API).

## 7. Copy rules for the restyle

- Remove every emoji from user-facing strings. If an emoji carried meaning, put the matching icon
  next to the text instead (e.g. "Private to you" gets `lock_outline`). Do not remove emoji from
  `print`/`debugPrint` lines — they are not user-facing; leave those lines alone.
- Do not reword, shorten, reorder or delete any other copy. The verify script fails on any string
  literal that disappears (case, emoji and spacing ignored).
