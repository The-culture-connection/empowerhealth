# Hearth restyle progress

Fill in one row per mockup as you finish it. "Match" = the running screen at 390×844 matches the PNG in layout, colour, type and spacing, with the code's current content. Put every difference between code and mockup in the Drift table.

| Phase | Mockup | Screen checked at 390×844 | Match | Notes |
|---|---|---|---|---|
| 3 | Start-Welcome | | | |
| 3 | Start-Terms | | | |
| 3 | Start-SignUp | | | |
| 3 | Start-Login | | | |
| 3 | Start-ResetPassword | | | |
| 3 | Start-GuestPrompt | | | |
| 3 | Start-Consent | | | |
| 3 | Start-Research | | | |
| 3 | Start-ResearchBaseline1 | | | |
| 3 | Start-ResearchBaseline2 | | | |
| 3 | Start-ResearchBaseline3 | | | |
| 3 | Start-ResearchBaseline4 | | | |
| 3 | Start-ResearchBaseline5 | | | |
| 3 | Start-ResearchBaseline6 | | | |
| 4 | Setup-1-Basic | | | |
| 4 | Setup-2-Demographics | | | |
| 4 | Setup-3-Health | | | |
| 4 | Setup-4-Support | | | |
| 4 | Setup-5-Wellness | | | |
| 4 | Setup-5b-Referral | | | |
| 4 | Setup-6-Preferences | | | |
| 4 | Setup-7-Goals | | | |
| 5 | Main | | | |
| 5 | Home-PregnancyJourney | | | |
| 5 | Home-NeedsChecklist | | | |
| 5 | Home-CareCheckIn-Support | | | |
| 5 | Home-CareCheckIn-3-Access | | | |
| 5 | Home-CareCheckIn-4-Outcome | | | |
| 5 | Home-CareCheckIn-5-Complete | | | |
| 5 | Home-Resources | | | |
| 5 | Home-MilestoneTracker | | | |
| 5 | Home-MilestoneCheckIn | | | |
| 6 | Visits-List | | | |
| 6 | Visits-List-Empty | | | |
| 6 | Visits-Upload-HowItWorks | | | |
| 6 | Visits-Upload | | | |
| 6 | Visits-Upload-Text | | | |
| 6 | Visits-Privacy | | | |
| 6 | Visits-Upload-Result | | | |
| 6 | Visits-Rating | | | |
| 6 | Visits-Detail | | | |
| 6 | Visits-Detail-Delete | | | |
| 7 | Learn-Center | | | |
| 7 | Learn-Center-Archived | | | |
| 7 | Learn-Module | | | |
| 7 | Learn-Notes | | | |
| 7 | Learn-ModuleExit | | | |
| 7 | Learn-Survey | | | |
| 7 | Learn-Rating | | | |
| 7 | Learn-Rights | | | |
| 7 | Learn-RightsDetail | | | |
| 8 | Journal-Hub | | | |
| 8 | Journal-CheckIn | | | |
| 8 | Journal-Write | | | |
| 8 | Journal-LearningNotes | | | |
| 8 | Journal-Entry | | | |
| 8 | Journal-Empty | | | |
| 9 | Community-Feed | | | |
| 9 | Community-NewPost | | | |
| 9 | Community-Post | | | |
| 9 | Community-Report | | | |
| 9 | Community-Block | | | |
| 9 | Community-Delete | | | |
| 10 | Care-Search | | | |
| 10 | Care-Search-Quick | | | |
| 10 | Care-Search-Form | | | |
| 10 | Care-Loading | | | |
| 10 | Care-Results | | | |
| 10 | Care-Results-Empty | | | |
| 10 | Care-MamaApproved | | | |
| 11 | Care-Provider | | | |
| 11 | Care-Report | | | |
| 11 | Care-Review | | | |
| 11 | Care-ShareExperience | | | |
| 11 | Care-ShareExperience-NoResults | | | |
| 11 | Care-AddProvider | | | |
| 11 | Care-AddProvider-Success | | | |
| 12 | Birth-List | | | |
| 12 | Birth-List-Empty | | | |
| 12 | Birth-Builder-1-Support | | | |
| 12 | Birth-Builder-2-Space | | | |
| 12 | Birth-Builder-3-Comfort | | | |
| 12 | Birth-Builder-4-AfterBaby | | | |
| 12 | Birth-Builder-5-PlansChange | | | |
| 12 | Birth-Builder-Feedback | | | |
| 12 | Birth-Plan | | | |
| 13 | You-Profile | | | |
| 13 | You-Profile-Open | | | |
| 13 | You-EditProfile | | | |
| 13 | You-Profile-Guest | | | |
| 13 | You-Dialog-SupportStage | | | |
| 13 | You-Dialog-DeleteProfile | | | |
| 13 | You-Dialog-SignOut | | | |
| 13 | You-Privacy | | | |
| 13 | You-Privacy-Open | | | |
| 13 | You-BlockedUsers | | | |
| 13 | You-BlockedUsers-Empty | | | |
| 13 | You-Dialog-DeleteAccount | | | |
| 14 | Support-Assistant-Empty | | | |
| 14 | Support-Assistant | | | |
| 14 | Support-CheckIn | | | |
| 14 | Support-Hub | | | |
| 14 | Support-Hub-Selected | | | |
| 15 | Loss-StagePicker | | | |
| 15 | Loss-Transition | | | |
| 15 | Loss-Preferences | | | |
| 15 | Loss-Home | | | |
| 15 | Loss-Support | | | |
| 15 | Loss-ProviderQuestions | | | |
| 15 | Loss-Learn | | | |
| 15 | Loss-Learn-Topic | | | |
| 15 | Community-Feed-Loss | | | |

## Drift (code and mockup disagree; code was followed)

| Mockup | What differs | What was done |
|---|---|---|

## Screens with no mockup (restyled from the nearest pattern)

| Dart file | Pattern used |
|---|---|
| lib/design_system/widgets.dart (`DS` helpers; no callers in lib/) | Rebuilt on HearthButton / HearthCard / HearthRowCard / HearthAvatar / HearthIconChip; hero header is a tint panel with the photo at 15% |
| lib/widgets/trust_cue_banner.dart | Cream HearthNote with lock_outline (privacy note pattern from Visits-Upload) |
| lib/widgets/ai_disclaimer_banner.dart | Lavender HearthNote (AI note pattern from Visits-Upload-Result) |

Note: the local harness's iPhone 15 preset is 393×852, 3px wider than the 390×844 mockups; screens were compared at that size.
