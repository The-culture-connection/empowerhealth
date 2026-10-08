# Hearth restyle progress

Fill in one row per mockup as you finish it. "Match" = the running screen at 390×844 matches the PNG in layout, colour, type and spacing, with the code's current content. Put every difference between code and mockup in the Drift table.

| Phase | Mockup | Screen checked at 390×844 | Match | Notes |
|---|---|---|---|---|
| 3 | Start-Welcome | yes (/auth) | yes | Real photo kept inside the arch frame |
| 3 | Start-Terms | yes (/terms) | yes | |
| 3 | Start-SignUp | yes (/signup) | yes | Same card pattern as Login |
| 3 | Start-Login | yes (/login) | yes | Google icon is Material g_mobiledata |
| 3 | Start-ResetPassword | no (dialog needs a tap on a live account flow) | not checked | Theme dialog; Email label above field |
| 3 | Start-GuestPrompt | no (shown only to guests) | not checked | showHearthSheet with lock chip |
| 3 | Start-Consent | yes (/consent) | yes | |
| 3 | Start-Research | no (reached only after enrolling; would write research data) | not checked | Restyled from the mockup |
| 3 | Start-ResearchBaseline1 | no (as above) | not checked | |
| 3 | Start-ResearchBaseline2 | no (as above) | not checked | |
| 3 | Start-ResearchBaseline3 | no (as above) | not checked | |
| 3 | Start-ResearchBaseline4 | no (as above) | not checked | |
| 3 | Start-ResearchBaseline5 | no (as above) | not checked | |
| 3 | Start-ResearchBaseline6 | no (as above) | not checked | |
| 4 | Setup-1-Basic | yes (/profile-creation) | yes | Switch was Cupertino grey on iOS; now the Hearth switch |
| 4 | Setup-2-Demographics | no (Next would validate/save the real profile) | not checked | Same field pattern as step 1 |
| 4 | Setup-3-Health | no (as above) | not checked | |
| 4 | Setup-4-Support | no (as above) | not checked | |
| 4 | Setup-5-Wellness | no (as above) | not checked | |
| 4 | Setup-5b-Referral | no (as above) | not checked | |
| 4 | Setup-6-Preferences | no (as above) | not checked | |
| 4 | Setup-7-Goals | no (as above) | not checked | |
| 5 | Main | yes (Home tab, scrolled) | yes | Warm circle is clipped at the safe-area line, not the screen top (see Drift) |
| 5 | Home-PregnancyJourney | yes (/pregnancy-journey, guest without due date) | yes for the no-due-date state | Week/trimester state needs a profile with a due date |
| 5 | Home-NeedsChecklist | yes (/care-survey) | yes | |
| 5 | Home-CareCheckIn-Support | no (needs answers that would be saved) | not checked | |
| 5 | Home-CareCheckIn-3-Access | no (as above) | not checked | |
| 5 | Home-CareCheckIn-4-Outcome | no (as above) | not checked | |
| 5 | Home-CareCheckIn-5-Complete | no (as above) | not checked | |
| 5 | Home-Resources | yes (/resources) | yes | |
| 5 | Home-MilestoneTracker | no (bell sheet needs milestone data) | not checked | |
| 5 | Home-MilestoneCheckIn | no (as above) | not checked | |
| 6 | Visits-List | no (guest account has no visits; uploading would write data) | not checked | Cards restyled from the mockup |
| 6 | Visits-List-Empty | yes (/appointments, guest) | yes | |
| 6 | Visits-Upload-HowItWorks | no (opens on upload) | not checked | |
| 6 | Visits-Upload | no (as above) | not checked | |
| 6 | Visits-Upload-Text | no (as above) | not checked | |
| 6 | Visits-Privacy | no (linked from upload) | not checked | |
| 6 | Visits-Upload-Result | no (needs a real upload) | not checked | |
| 6 | Visits-Rating | no (after a real upload) | not checked | |
| 6 | Visits-Detail | no (needs a saved visit) | not checked | |
| 6 | Visits-Detail-Delete | no (as above) | not checked | |
| 7 | Learn-Center | yes (Learn tab, guest) | yes, apart from card height | Birth-basics carousel cards are taller than the mockup's (height set for large text) |
| 7 | Learn-Center-Archived | no (guest has nothing archived) | not checked | |
| 7 | Learn-Module | no (opening a module from the carousel needs a tap in the module list) | not checked | |
| 7 | Learn-Notes | no (saving a note writes data) | not checked | |
| 7 | Learn-ModuleExit | no | not checked | |
| 7 | Learn-Survey | no | not checked | |
| 7 | Learn-Rating | no | not checked | |
| 7 | Learn-Rights | yes (/rights) | yes | |
| 7 | Learn-RightsDetail | no | not checked | |
| 8 | Journal-Hub | no (guest has no entries; saving one writes data) | not checked | Same header and chooser as Journal-Empty |
| 8 | Journal-CheckIn | no (opening is fine but saving writes data; not opened) | not checked | Moods use nature icons; saved text format unchanged |
| 8 | Journal-Write | no (as above) | not checked | |
| 8 | Journal-LearningNotes | no (needs saved notes) | not checked | |
| 8 | Journal-Entry | no (needs a saved entry) | not checked | Mood emoji is no longer shown in the entry dialog or the save snackbar |
| 8 | Journal-Empty | yes (Journal tab, guest) | yes | Floating shortcuts have the ground ring but no shadow (lint) |
| 9 | Community-Feed | yes (Community tab, live posts) | yes | Re-checked after phase 15 (same file renders the loss feed) |
| 9 | Community-NewPost | no (posting writes data) | not checked | |
| 9 | Community-Post | no (opening a post is read-only but needs a tap on a real post; not opened) | not checked | |
| 9 | Community-Report | no (would write a report) | not checked | |
| 9 | Community-Block | no (would write a block) | not checked | |
| 9 | Community-Delete | no (guest owns no posts) | not checked | |
| 10 | Care-Search | yes (/providers) | yes | Badge sits on its own line under the name |
| 10 | Care-Search-Quick | no (opened from the search pill; not opened) | not checked | |
| 10 | Care-Search-Form | yes (/providers/search) | yes | Search logic untouched (whitespace-ignoring diff shows only the import above line 449) |
| 10 | Care-Loading | no (would run a live search against production) | not checked | |
| 10 | Care-Results | no (as above) | not checked | |
| 10 | Care-Results-Empty | no (as above) | not checked | |
| 10 | Care-MamaApproved | no (not opened) | not checked | |
| 11 | Care-Provider | no (needs a tap on a provider card) | not checked | |
| 11 | Care-Report | no (would write a report) | not checked | |
| 11 | Care-Review | no (would write a review) | not checked | |
| 11 | Care-ShareExperience | no (not opened) | not checked | |
| 11 | Care-ShareExperience-NoResults | no | not checked | |
| 11 | Care-AddProvider | yes (/providers/add) | yes | Captured only; nothing submitted |
| 11 | Care-AddProvider-Success | no (needs a submission) | not checked | |
| 12 | Birth-List | no (no route; needs a tap from Home) | not checked | |
| 12 | Birth-List-Empty | no | not checked | |
| 12 | Birth-Builder-1-Support | no | not checked | |
| 12 | Birth-Builder-2-Space | no | not checked | |
| 12 | Birth-Builder-3-Comfort | no | not checked | |
| 12 | Birth-Builder-4-AfterBaby | no | not checked | |
| 12 | Birth-Builder-5-PlansChange | no | not checked | |
| 12 | Birth-Builder-Feedback | no (dialog after saving) | not checked | Dialog is qualitative_survey_dialog.dart (phase 2) |
| 12 | Birth-Plan | no | not checked | |
| 13 | You-Profile | no (guest sees the guest view) | not checked | Edit Profile sits on its own row under the name |
| 13 | You-Profile-Open | no | not checked | |
| 13 | You-EditProfile | no | not checked | |
| 13 | You-Profile-Guest | yes (You tab, guest) | yes | |
| 13 | You-Dialog-SupportStage | no (would change the profile) | not checked | |
| 13 | You-Dialog-DeleteProfile | no | not checked | |
| 13 | You-Dialog-SignOut | no | not checked | |
| 13 | You-Privacy | yes (/privacy-center) | yes | |
| 13 | You-Privacy-Open | no (not expanded) | not checked | |
| 13 | You-BlockedUsers | no (guest has none) | not checked | |
| 13 | You-BlockedUsers-Empty | no (not opened) | not checked | |
| 13 | You-Dialog-DeleteAccount | no | not checked | |
| 14 | Support-Assistant-Empty | yes (/assistant, guest) | yes | |
| 14 | Support-Assistant | no (sending a message writes data) | not checked | |
| 14 | Support-CheckIn | yes (/immediate-support) | yes | |
| 14 | Support-Hub | no (after Continue) | not checked | 988 actions purple, no red |
| 14 | Support-Hub-Selected | no | not checked | |
| 15 | Loss-StagePicker | no (switching stage changes the profile) | not checked | Picker in support_stage_settings_tile.dart |
| 15 | Loss-Transition | no (as above) | not checked | |
| 15 | Loss-Preferences | no | not checked | |
| 15 | Loss-Home | no | not checked | Scaffold background now ground (was PregnancyLossTheme lavender) |
| 15 | Loss-Support | no | not checked | 988 as cream rows, no red |
| 15 | Loss-ProviderQuestions | no | not checked | |
| 15 | Loss-Learn | no | not checked | No warm circle |
| 15 | Loss-Learn-Topic | no | not checked | Uses learning_module_detail_screen.dart (phase 7) |
| 15 | Community-Feed-Loss | no | not checked | Loss feed: no warm circle |

## Drift (code and mockup disagree; code was followed)

| Mockup | What differs | What was done |
|---|---|---|
| Start-Welcome | Mockup has a tinted placeholder; code has a real photo (assets/Authscreen.jpeg) | Kept the photo, inside the mockup's arch frame between wordmark and buttons |
| Start-Login / Start-SignUp | Mockup Google icon is an outlined "G" | Kept Material `g_mobiledata` (no outlined G in Material icons) |
| Start-ResetPassword | Mockup dialog is surface with a border | Theme dialog (ground) |
| Start-Terms | Mockup draws HTML lists | Kept the code's single text block per section with "•" characters |
| Start-GuestPrompt | Gap under the handle is 20 in the mockup | showHearthSheet gives 16 |
| Start-SignUp | Code has an unused name controller | Kept; no Name field added |
| Start-Research / Baseline5 | Mockup dropdowns show a "Select" placeholder; code has no hint | No hint added |
| Start-ResearchBaseline2 | Mockup's selected option label is purple 700 | HearthOptionRow (ink 600) |
| Start-ResearchBaseline1–6 | Mockup shows a back circle on every step; code showed back only when the route could pop | Header follows the code |
| Start-Research | Code has an error line and a loading spinner not in the mockup | Error as cream HearthNote; spinner kept |
| Start-Consent | Code uses a Checkbox inside a tappable card | Kept the Checkbox on a card that turns tint + 2px purple when checked |
| Setup-1..7 | Mockup puts field labels above fields; code used floating labelText | Same strings moved to labels above the fields, same files |
| Setup-1..7 | Mockup header scrolls with content; code keeps header, progress and step title fixed | Kept the code's layout |
| Setup-1-Basic | Code has Delivery Date and Child's Age (postpartum) not in the mockup | Same date-row card and field pattern |
| Setup-3-Health | Code has a Pregnancy Stage dropdown not in the mockup | Styled like the Setup-2 dropdowns |
| Setup-1 / Setup-3 | Mockups put the trimester/auto-stage notes on lavender (spec reserves lavender for AI) | Followed the mockups |
| Setup-4 / 6 / 7 | Mockup option rows radius 24 and 16px bold titles | HearthOptionRow (radius 18, 15px) |
| Setup-5-Wellness | Full-width centred Yes/No pills | Full-width OutlinedButton in chip colours (HearthChoiceChip can't centre when stretched) |
| Setup-5b-Referral | Mockup dialog surface with border | Theme dialog (ground) |
| Main | Warm circle sits at the very top of the screen in the mockup | HearthTabHeader clips it at the top of the header (below the safe area) |
| Main | "Learning guides" card (loss branch) and latest-visit fallback card are not in the mockup | Kept, styled as Hearth cards |
| Main | Community title is two code strings ("Welcome to" + "EmpowerHealth Watch") | Kept both, 17/700 |
| Main | Mockup bell has a screen-reader label; code has none | Not added (no new copy) |
| Home-PregnancyJourney | Code has decorative blurred circles and a small gold circle | Removed (decoration only) |
| Home-PregnancyJourney | Mockup baby icon is a leaf | Kept the code's child_care_outlined in an icon chip |
| Home-NeedsChecklist | Mockup unselected rows are ground with ink text | HearthOptionRow (surface, secondary) |
| Home-Resources | Code has a highlighted-resource state not in the mockup | Tint + 2px purple border |
| Home-MilestoneTracker | Code used a turquoise check | Purple check_circle_outline |
| Home-MilestoneCheckIn | Mockup "Check-in" header label is ink 16/700 | HearthPushedHeader label style (14/600 secondary) |
| Home-CareCheckIn-5-Complete | Code had a filled gold heart | 80px icon chip with purple favorite_border + HearthNote |
| Visits-List | Mockup has a back circle; old screen had no back control | HearthPushedHeader back (calls maybePop; the screen is always pushed) |
| Visits-List | Code's "Lessons from this visit" section and "No older visits yet." line aren't in the mockup | Kept, card label + HearthButton.text / body text |
| Visits-List-Empty | Mockup icon is plus-in-square; code used medical_information_outlined | add_box_outlined in a tint chip |
| Visits-Detail | Mockup shows suggested learning as plain numbered text; code has tappable rows with reason and spinner | Kept the code's rows, restyled |
| Visits-Detail-Delete / Visits-Upload-HowItWorks / Visits-Rating | Mockup dialogs are surface with a border | Theme dialog (ground) |
| Visits-Upload | Selected card shows "PDF Selected" + file name; code shows 'Ready to upload' + 'Your document'/'Your photo' | Code copy in the mockup's tint/purple-border card |
| Visits-Upload-Result | Mockup's "We're making this easier" body differs | Code copy kept |
| Visits-Upload | Code has a hint under Simplify and a progress box | Caption + tint progress card |
| Visits-Upload | "AI Features Disabled" dialog has no mockup | Theme AlertDialog |
| Learn-Center | Carousel icon is plus-in-square; code uses local_hospital_outlined | Code's icon in a Hearth chip |
| Learn-Center | Chevron shows only when a module has content; mockup always shows it | Code's condition kept |
| Learn-Center | Code has Archive action, Todos filter state and Unarchive label | Kept (44px text action) |
| Learn-Center | Module cards had per-module green/blue/amber colours | One warm chip for all; icon still varies |
| Learn-Rights | Support-person icon: people in mockup, hand-heart in code | people_outline (icon only) |
| Learn-RightsDetail | Full-screen AI-topic loading dialog not in the mockup | Kept |
| Learn-Module | Mockup has "Save" (outline) + "Save to Journal"; code has one "Save" | One filled Save; nothing added |
| Learn-Module | Mockup share button is labelled "Share"; code has no tooltip | Not added (no new copy) |
| Learn-Notes / Learn-Survey / Learn-Rating | Mockups use surface dialogs with a border | Followed the mockups for these three |
| Learn-Notes | Code has a dismiss-keyboard icon and state-dependent title/highlight box | Kept |
| Learn-Survey | Mockup stars have per-star screen-reader labels | Not added (no new copy) |
| Learn-ModuleExit | Quick-feedback emoji faces | Icons: favorite_border, eco_outlined, cloud_outlined, wb_sunny_outlined |
| Learn-Rating | Submit is a compact right-aligned pill | HearthButton.primary(expand: false) |
| Journal-Hub / Empty / LearningNotes | Mockup shortcut buttons have a drop shadow | Ground ring only (only the Support FAB may have a shadow) |
| Journal-CheckIn / Write | Code had a face / pencil icon beside the card titles | Removed (decorative); serif titles |
| Journal-Hub / CheckIn / Entry | Saved check-ins start with a mood emoji | Shown as the mood's nature icon; the emoji stays in stored data only |
| Journal-Write | Unselected prompt chips are ground-filled at 14px | HearthChoiceChip (surface, 15px) |
| Journal-Hub | "Private to you" pill sits in the header in the mockup | First item of the scroll list, as the code had it |
| Journal-Entry | Prompt and "From:" boxes | Warm-tint rows with psychology_outlined / menu_book_outlined |
| Community-Feed | Old chip row had a right-edge fade | Removed (it was a gradient); the cut-off chip shows there are more |
| Community-Feed | Empty states and loading spinner not in the mockup | Icon chip + theme text |
| Community-Post | Code has a delete circle for the post owner | Kept as a third header circle |
| Community-Post | Mockup reply field is a full pill | Theme field radius 18 (field grows to several lines) |
| Community-Post | "No replies yet" and blocked-content placeholder have no mockup | HearthCard / icon chip / primary button |
| Community-Report | Report Reply has no mockup | Same pattern as Report Post |
| Care-Search-Form | "Add a provider →" literal has a text arrow; mockup uses an icon | Literal kept |
| Care-Search-Form | Unselected chips are ground-filled 14px | HearthChoiceChip (surface, 15px) |
| Care-Search-Form | Mockup NPI checkbox is 22px | Theme Checkbox |
| Care-Search-Quick | Labels drawn above fields; code used floating labelText | Same literals moved to labels above the fields |
| Care-Search-Quick | Cultural-tags section shown open | Code's ExpansionTile starts collapsed; kept |
| Care-MamaApproved | Rating drawn as bold number + star icon | Code has one string with ★; kept, muted body |
| Care-Loading | Code used the AI disclaimer (now lavender); mockup shows a cream note | Cream HearthNote with the same strings |
| Care-Results | Mockup has an outlined tag style | Private _OutlineTag (ground, borderWarm) for specialties/identity/unmatched types |
| Care-Results | "✓ Accepting new patients" has the ✓ in the literal | Literal kept in a tint HearthTag |
| Care-Results / Care-Provider / Care-Review | Mockup buttons/stars have screen-reader labels the code lacks | Not added (no new copy) |
| Care-Results-Empty | Suggestions shown conditionally in code | Code's conditions kept |
| Care-Provider | Mockup puts the info icon inside the gold Mama Approved tag | Badge draws it after the tag |
| Care-Provider | "✓ Would recommend" / "Write a review →" literals hold text symbols | Literals kept |
| Care-Provider | "Updated …", "Additional notes", "Cultural tags" review blocks not in the mockup | Kept, review label/caption/body styles |
| Care-Report | Mockup "Details (optional)" label sits above the field | Kept the floating labelText |
| Care-ShareExperience | Heading literal ended with a purple-heart emoji | Emoji removed, no-break space kept |
| Care-ShareExperience | Badge sat beside the name | Moved under the name |
| Care-AddProvider | Mockup search field looks pill-shaped | Theme field radius 18 |
| Birth-Builder-1..5 | Spec asks for HearthStepProgress; mockups show the chip banner | Restyled the code's chip banner; no bar added |
| Birth-Builder-1 | Add button is ground-filled with an aria label | HearthCircleButton, no tooltip (no new copy) |
| Birth-Builder-2..5 | Dropdown menus open inline | Stock dropdown menu, surface + radius 18 |
| Birth-Builder-5 | Save plan in a separate filled block | Previous and Save stacked, as the code had them |
| Birth-Builder | Code has "Cord blood company name" field | Kept, labelled field |
| Birth-Plan | Mockup shows serif "Birth plan" heading and bold numbered headings in the plan text | Styled the formatter's own lines (case-only change on the first line in display); PDF untouched |
| Birth-Plan | Download PDF shows a download icon | ios_share |
| You-Profile | Sign Out drawn as a row card | Ink row card (not red) |
| You-EditProfile | Labels above fields, no prefix icons | Kept labelText and prefix icons (theme-styled) |
| You-EditProfile | Editing banner is lavender (spec reserves lavender for AI) | Followed the mockup |
| You-Dialog-* / You-Privacy | Dialogs drawn on surface with a 22px title | Theme dialog (ground, 20px serif) |
| You-Privacy | Mockup shows Research Data Sharing off | Sample data; value from code |
| Support-Assistant | Compact disclaimer, signed-out text, spinners and thinking bubble not in the mockup | Kept; thinking bubble lavender (AI) |
| Support-Hub | Mockup bolds the "does not provide counseling" sentence | Same constant, bolded at runtime |
| Support-CheckIn | Rows radius 24, unselected labels ink | HearthOptionRow (radius 18, secondary) |
| Loss-Preferences | Option rows radius 24, padding 16 | HearthOptionRow |
| Loss-Home / Loss-Support | Destination icons come from pregnancy_loss_navigation.dart (not on the phase map) | Left as they are |
| Loss-Support | PSI link is 14px | HearthButton.text (15px) |
| Loss-Learn | Topic icons differ slightly | Two icons changed (help_outline, calendar_today_outlined) |

## Screens with no mockup (restyled from the nearest pattern)

| Dart file | Pattern used |
|---|---|
| lib/design_system/widgets.dart (`DS` helpers; no callers in lib/) | Rebuilt on HearthButton / HearthCard / HearthRowCard / HearthAvatar / HearthIconChip; hero header is a tint panel with the photo at 15% |
| lib/widgets/trust_cue_banner.dart | Cream HearthNote with lock_outline (privacy note pattern from Visits-Upload) |
| lib/widgets/ai_disclaimer_banner.dart | Lavender HearthNote (AI note pattern from Visits-Upload-Result) |
| lib/profile/research/baseline_research_form.dart ("other insurance" page) | Field with label above, as Baseline1 |
| lib/profile/research/insurance_question.dart, recruitment_source_question.dart ("Other (specify)") | Field with label above |
| lib/profile/research/pregnancy_postpartum_question.dart (week/month fields) | Field with label above |
| lib/research/micro_measure_prompt.dart (star rows inside rating modals) | HearthStarRating (size 40), card-title labels, caption hint |
| lib/Home/home_screen_v2.dart (unused todo modal / module-generation dialog) | Theme dialog, serif title, icon chip, borderWarm progress |
| lib/learning/module_notes.dart (notes viewer + delete confirm) | Theme dialog, serif title, close circle, HearthCard per note, ink-outline Delete |
| lib/widgets/module_quick_feedback.dart (showModuleFeedbackSheet) | Same sheet pattern as Learn-ModuleExit |
| lib/widgets/learning_module_formatted_content.dart ("Your notes on this lesson") | Serif heading, bordered ground rows, purple chevron |
| lib/Home/Learning Modules/learning_module_detail_screen.dart (unused old review/survey sections) | HearthCard, HearthButton, HearthStarRating, HearthNote |
| lib/Community/post_detail_screen.dart (_BlockedContentPlaceholder) | Icon chip + headlineMedium + bodyMedium + primary button |
| lib/providers/provider_search_screen.dart (empty state) | Icon chip, headlineMedium, bodyLarge, primary button |
| lib/providers/mama_approved_providers_screen.dart (error / empty) | Card title / headline, body, secondary "Try again" |
| lib/providers/provider_search_results_screen.dart (error state) | Same as the empty state |
| lib/appointments/upload_visit_summary_screen.dart ("AI Features Disabled" dialog) | Theme AlertDialog |
| lib/privacy/privacy_center_screen.dart ("Sign in to manage blocked users") | Centred bodyLarge |

Note: the local harness's iPhone 15 preset is 393×852, 3px wider than the 390×844 mockups; screens were compared at that size.
