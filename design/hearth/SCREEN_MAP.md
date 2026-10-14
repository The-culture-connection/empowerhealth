# Screen map

Every mockup, the Dart code it was drawn from, and the phase that restyles it. PNG renders of each mockup are in `design/hearth/png/<name>.png`; the source markup (exact sizes and colours in inline styles) is in `design/hearth/mockups/<name>.dc.html`.

**Source of truth:** the current Dart code decides content, order, which elements exist and what they do; the mockup decides how they look. Most screens changed in code after the mockups were drawn (QA rounds 1-5 on 10/7), so expect the code to have things the mockup lacks, or the reverse. Follow the code and log the difference in PROGRESS.md.

## Phase 3: Sign in and onboarding

Dart files: `lib/auth/auth_screen.dart`, `lib/auth/Login_screen.dart`, `lib/auth/Sign_up_screen.dart`, `lib/auth/terms_and_conditions_screen.dart`, `lib/auth/guest_guard.dart`, `lib/auth/guest_account_cta.dart`, `lib/privacy/consent_screen.dart`, `lib/profile/research/research_onboarding_screen.dart`, `lib/profile/research/baseline_research_form.dart`, `lib/profile/research/insurance_question.dart`, `lib/profile/research/pregnancy_postpartum_question.dart`, `lib/profile/research/recruitment_pathway_question.dart`, `lib/profile/research/recruitment_source_question.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Start-Welcome](png/Start-Welcome.png) | Welcome | `auth/auth_screen.dart` | Mockup shows a tinted placeholder where the app uses assets/Authscreen.jpeg: keep the real photo (code wins), restyle everything around it. |
| [Start-Terms](png/Start-Terms.png) | Terms & Conditions | `auth/terms_and_conditions_screen.dart` |  |
| [Start-SignUp](png/Start-SignUp.png) | Create Account | `auth/Sign_up_screen.dart` |  |
| [Start-Login](png/Start-Login.png) | Login | `auth/Login_screen.dart` |  |
| [Start-ResetPassword](png/Start-ResetPassword.png) | Reset Password dialog | `auth/Login_screen.dart` |  |
| [Start-GuestPrompt](png/Start-GuestPrompt.png) | Guest prompt sheet | `auth/guest_guard.dart` |  |
| [Start-Consent](png/Start-Consent.png) | First-run consent | `privacy/consent_screen.dart` |  |
| [Start-Research](png/Start-Research.png) | Research: Step 1 About you | `profile/research/research_onboarding_screen.dart` |  |
| [Start-ResearchBaseline1](png/Start-ResearchBaseline1.png) | Baseline 1 of 6: Age | `profile/research/baseline_research_form.dart` |  |
| [Start-ResearchBaseline2](png/Start-ResearchBaseline2.png) | Baseline 2 of 6: Pregnancy | `profile/research/pregnancy_postpartum_question.dart` |  |
| [Start-ResearchBaseline3](png/Start-ResearchBaseline3.png) | Baseline 3 of 6: Weeks | `profile/research/baseline_research_form.dart` |  |
| [Start-ResearchBaseline4](png/Start-ResearchBaseline4.png) | Baseline 4 of 6: Insurance | `profile/research/insurance_question.dart` |  |
| [Start-ResearchBaseline5](png/Start-ResearchBaseline5.png) | Baseline 5 of 6: Support | `profile/research/baseline_research_form.dart` |  |
| [Start-ResearchBaseline6](png/Start-ResearchBaseline6.png) | Baseline 6 of 6: Advocacy | `profile/research/baseline_research_form.dart` |  |

## Phase 4: Create your profile

Dart files: `lib/profile/profile_creation_screen.dart`, `lib/profile/steps/basic_info_step.dart`, `lib/profile/steps/demographics_step.dart`, `lib/profile/steps/health_info_step.dart`, `lib/profile/steps/support_network_step.dart`, `lib/profile/steps/wellness_access_step.dart`, `lib/profile/steps/preferences_step.dart`, `lib/profile/steps/goals_step.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Setup-1-Basic](png/Setup-1-Basic.png) | Setup 1 · Basic Information | `profile/steps/basic_info_step.dart` |  |
| [Setup-2-Demographics](png/Setup-2-Demographics.png) | Setup 2 · Demographics | `profile/steps/demographics_step.dart` |  |
| [Setup-3-Health](png/Setup-3-Health.png) | Setup 3 · Health Information | `profile/steps/health_info_step.dart` |  |
| [Setup-4-Support](png/Setup-4-Support.png) | Setup 4 · Support Network | `profile/steps/support_network_step.dart` |  |
| [Setup-5-Wellness](png/Setup-5-Wellness.png) | Setup 5 · Wellness & Access | `profile/steps/wellness_access_step.dart` | Yes/No both use the selected-chip style (no turquoise, no red tint). |
| [Setup-5b-Referral](png/Setup-5b-Referral.png) | Setup 5 · Referral dialog | `profile/steps/wellness_access_step.dart` |  |
| [Setup-6-Preferences](png/Setup-6-Preferences.png) | Setup 6 · Preferences | `profile/steps/preferences_step.dart` |  |
| [Setup-7-Goals](png/Setup-7-Goals.png) | Setup 7 · Your Goals | `profile/steps/goals_step.dart` |  |

## Phase 5: Home

Dart files: `lib/Home/home_screen_v2.dart`, `lib/Home/widgets/home_milestone_bell.dart`, `lib/Home/pregnancy_journey_screen.dart`, `lib/widgets/home_provider_search_entry.dart`, `lib/immediate_support/widgets/immediate_support_home_card.dart`, `lib/resources/app_resources_screen.dart`, `lib/care_survey/care_navigation_survey_screen.dart`, `lib/care_survey/care_checkin_support_screen.dart`, `lib/research/needs_checklist_screen.dart`, `lib/research/need_other_text_field.dart`, `lib/research/need_outcome_question_list.dart`, `lib/research/navigation_outcome_prompt.dart`, `lib/research/milestone_check_in_screen.dart`, `lib/research/milestone_tracker_sheet.dart`, `lib/research/micro_measure_prompt.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Main](png/Main.png) | Home | `Home/home_screen_v2.dart` | Full Home, top to bottom. Search field uses the sparkle icon (it opens the assistant). Support FAB here only. Trimester card is the tint feature card because "Know your rights" is the one purple card. Milestone bell shows for research participants only (as in code). |
| [Home-PregnancyJourney](png/Home-PregnancyJourney.png) | Pregnancy journey | `Home/pregnancy_journey_screen.dart` |  |
| [Home-NeedsChecklist](png/Home-NeedsChecklist.png) | Care check-in 1: needs | `research/needs_checklist_screen.dart` | Care Check-In step 1 of 5 (CareNavigationSurveyScreen); steps 3-5 follow in the next artboards. |
| [Home-CareCheckIn-Support](png/Home-CareCheckIn-Support.png) | Care check-in 2: support | `care_survey/care_checkin_support_screen.dart` |  |
| [Home-CareCheckIn-3-Access](png/Home-CareCheckIn-3-Access.png) | Care check-in 3: per need | `research/navigation_outcome_prompt.dart` |  |
| [Home-CareCheckIn-4-Outcome](png/Home-CareCheckIn-4-Outcome.png) | Care check-in 4: overall | `care_survey/care_navigation_survey_screen.dart` |  |
| [Home-CareCheckIn-5-Complete](png/Home-CareCheckIn-5-Complete.png) | Care check-in 5: thank you | `care_survey/care_navigation_survey_screen.dart` |  |
| [Home-Resources](png/Home-Resources.png) | Support resources | `resources/app_resources_screen.dart` |  |
| [Home-MilestoneTracker](png/Home-MilestoneTracker.png) | Milestone check-ins sheet | `research/milestone_tracker_sheet.dart` |  |
| [Home-MilestoneCheckIn](png/Home-MilestoneCheckIn.png) | Milestone check-in | `research/milestone_check_in_screen.dart` |  |

## Phase 6: My visits

Dart files: `lib/appointments/appointments_list_screen.dart`, `lib/appointments/upload_visit_summary_screen.dart`, `lib/appointments/visit_detail_screen.dart`, `lib/appointments/visit_summary_preview.dart`, `lib/appointments/suggested_learning_list.dart`, `lib/privacy/after_visit_privacy_screen.dart`, `lib/research/post_visit_summary_rating_modal.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Visits-List](png/Visits-List.png) | My visits | `appointments/appointments_list_screen.dart` |  |
| [Visits-List-Empty](png/Visits-List-Empty.png) | My visits — none yet | `appointments/appointments_list_screen.dart` |  |
| [Visits-Upload-HowItWorks](png/Visits-Upload-HowItWorks.png) | How After-Visit Support works | `appointments/upload_visit_summary_screen.dart` |  |
| [Visits-Upload](png/Visits-Upload.png) | Add a visit — file chosen | `appointments/upload_visit_summary_screen.dart` |  |
| [Visits-Upload-Text](png/Visits-Upload-Text.png) | Add a visit — type notes | `appointments/upload_visit_summary_screen.dart` |  |
| [Visits-Privacy](png/Visits-Privacy.png) | Your privacy | `privacy/after_visit_privacy_screen.dart` |  |
| [Visits-Upload-Result](png/Visits-Upload-Result.png) | Add a visit — summary ready | `appointments/upload_visit_summary_screen.dart` |  |
| [Visits-Rating](png/Visits-Rating.png) | Rate your visit summary | `research/post_visit_summary_rating_modal.dart` |  |
| [Visits-Detail](png/Visits-Detail.png) | Visit detail | `appointments/visit_detail_screen.dart` | The date card is the screen header. "Delete this summary" is a quiet text action; the confirm dialog uses the destructive (ink outline) button. |
| [Visits-Detail-Delete](png/Visits-Detail-Delete.png) | Delete this summary? | `appointments/visit_detail_screen.dart` |  |

## Phase 7: Learn

Dart files: `lib/Home/Learning Modules/learning_modules_screen_v2.dart`, `lib/Home/Learning Modules/learning_module_detail_screen.dart`, `lib/Home/Learning Modules/rights_screen.dart`, `lib/Home/Learning Modules/rights_static_content.dart`, `lib/Home/Learning Modules/module_survey_dialog.dart`, `lib/Home/Learning Modules/birth_labor_education_topics.dart`, `lib/learning/notes_dialog.dart`, `lib/learning/module_notes.dart`, `lib/widgets/learning_module_formatted_content.dart`, `lib/widgets/medical_citations_section.dart`, `lib/widgets/module_quick_feedback.dart`, `lib/widgets/note_highlight_spans.dart`, `lib/research/post_module_rating_modal.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Learn-Center](png/Learn-Center.png) | Learning center | `Home/Learning Modules/learning_modules_screen_v2.dart` | "Know your rights" is the purple feature card on both Home and Learn (the code draws it cream on Learn): a deliberate consistency change, styling only. |
| [Learn-Center-Archived](png/Learn-Center-Archived.png) | Learning center — Archived | `Home/Learning Modules/learning_modules_screen_v2.dart` |  |
| [Learn-Module](png/Learn-Module.png) | Learning module | `Home/Learning Modules/learning_module_detail_screen.dart` |  |
| [Learn-Notes](png/Learn-Notes.png) | Add note dialog | `learning/notes_dialog.dart` |  |
| [Learn-ModuleExit](png/Learn-ModuleExit.png) | Module exit check-in sheet | `widgets/module_quick_feedback.dart` |  |
| [Learn-Survey](png/Learn-Survey.png) | Complete Survey dialog | `Home/Learning Modules/module_survey_dialog.dart` |  |
| [Learn-Rating](png/Learn-Rating.png) | Quick check-in rating dialog | `research/post_module_rating_modal.dart` |  |
| [Learn-Rights](png/Learn-Rights.png) | Know Your Rights | `Home/Learning Modules/rights_screen.dart` |  |
| [Learn-RightsDetail](png/Learn-RightsDetail.png) | Rights topic detail | `Home/Learning Modules/rights_screen.dart` |  |

## Phase 8: Journal

Dart files: `lib/Journal/Journal_screen.dart`, `lib/Journal/journal_learning_note_opener.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Journal-Hub](png/Journal-Hub.png) | Journal | `Journal/Journal_screen.dart` | Journal has three states in code (hub / quick / write). Only the hub shows the mode chooser and the journal's two floating shortcuts. |
| [Journal-CheckIn](png/Journal-CheckIn.png) | Journal · Quick check-in | `Journal/Journal_screen.dart` | Quick mode: no chooser. Moods use the five nature icons, not faces or emoji. |
| [Journal-Write](png/Journal-Write.png) | Journal · Write | `Journal/Journal_screen.dart` |  |
| [Journal-LearningNotes](png/Journal-LearningNotes.png) | Journal · Learning notes | `Journal/Journal_screen.dart` |  |
| [Journal-Entry](png/Journal-Entry.png) | Journal entry (dialog) | `Journal/Journal_screen.dart` |  |
| [Journal-Empty](png/Journal-Empty.png) | Journal · No reflections yet | `Journal/Journal_screen.dart` |  |

## Phase 9: Community

Dart files: `lib/Community/community_screen.dart`, `lib/Community/create_post_screen.dart`, `lib/Community/post_detail_screen.dart`, `lib/widgets/community_survey_banner.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Community-Feed](png/Community-Feed.png) | Community | `Community/community_screen.dart` | Title and "New post" share one row and the title never wraps. Category pills scroll horizontally. Trash icon only on the user's own posts. No Support FAB. |
| [Community-NewPost](png/Community-NewPost.png) | Create Post | `Community/create_post_screen.dart` |  |
| [Community-Post](png/Community-Post.png) | Discussion (post opened) | `Community/post_detail_screen.dart` |  |
| [Community-Report](png/Community-Report.png) | Report Post (dialog) | `Community/post_detail_screen.dart` | AlertDialog in code; keep it a centred dialog. Confirm buttons for Block / Delete use the destructive ink-outline style. |
| [Community-Block](png/Community-Block.png) | Block user (dialog) | `Community/post_detail_screen.dart` |  |
| [Community-Delete](png/Community-Delete.png) | Delete post (dialog) | `Community/community_screen.dart` |  |

## Phase 10: Find your care

Dart files: `lib/providers/provider_search_screen.dart`, `lib/providers/provider_quick_search_screen.dart`, `lib/providers/provider_search_entry_screen.dart`, `lib/providers/provider_search_results_screen.dart`, `lib/providers/mama_approved_providers_screen.dart`, `lib/widgets/provider_search_loading.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Care-Search](png/Care-Search.png) | Find your care team (hub) | `providers/provider_search_screen.dart` |  |
| [Care-Search-Quick](png/Care-Search-Quick.png) | Search providers (quick) | `providers/provider_quick_search_screen.dart` |  |
| [Care-Search-Form](png/Care-Search-Form.png) | Expanded search form | `providers/provider_search_entry_screen.dart` |  |
| [Care-Loading](png/Care-Loading.png) | Search results — loading | `widgets/provider_search_loading.dart` |  |
| [Care-Results](png/Care-Results.png) | Search results | `providers/provider_search_results_screen.dart` | Mama Approved badge sits on its own line under the provider name, never squeezed beside it. |
| [Care-Results-Empty](png/Care-Results-Empty.png) | Search results — no matches | `providers/provider_search_results_screen.dart` |  |
| [Care-MamaApproved](png/Care-MamaApproved.png) | Mama Approved providers | `providers/mama_approved_providers_screen.dart` |  |

## Phase 11: Provider profile and reviews

Dart files: `lib/providers/provider_profile_screen.dart`, `lib/providers/provider_review_screen.dart`, `lib/providers/add_provider_screen.dart`, `lib/providers/provider_report_sheet.dart`, `lib/providers/share_provider_experience_screen.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Care-Provider](png/Care-Provider.png) | Provider profile | `providers/provider_profile_screen.dart` |  |
| [Care-Report](png/Care-Report.png) | Report this listing (sheet) | `providers/provider_report_sheet.dart` | Reason options must be the five labels in ProviderReportReason.labels. |
| [Care-Review](png/Care-Review.png) | Write a Review | `providers/provider_review_screen.dart` |  |
| [Care-ShareExperience](png/Care-ShareExperience.png) | Share Provider Experience | `providers/share_provider_experience_screen.dart` |  |
| [Care-ShareExperience-NoResults](png/Care-ShareExperience-NoResults.png) | Share Experience: no results | `providers/share_provider_experience_screen.dart` |  |
| [Care-AddProvider](png/Care-AddProvider.png) | Add a Provider | `providers/add_provider_screen.dart` |  |
| [Care-AddProvider-Success](png/Care-AddProvider-Success.png) | Add a Provider: submitted | `providers/add_provider_screen.dart` |  |

## Phase 12: Birth plan

Dart files: `lib/birthplan/birth_plans_list_screen.dart`, `lib/birthplan/comprehensive_birth_plan_screen.dart`, `lib/birthplan/birth_plan_display_screen.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Birth-List](png/Birth-List.png) | Birth plans | `birthplan/birth_plans_list_screen.dart` |  |
| [Birth-List-Empty](png/Birth-List-Empty.png) | Birth plans — none yet | `birthplan/birth_plans_list_screen.dart` |  |
| [Birth-Builder-1-Support](png/Birth-Builder-1-Support.png) | Builder 1 — Support team | `birthplan/comprehensive_birth_plan_screen.dart` | Step indicator is the horizontally scrolling chip banner the code already has, restyled (active purple, done gold with check, upcoming cream). |
| [Birth-Builder-2-Space](png/Birth-Builder-2-Space.png) | Builder 2 — Birth space | `birthplan/comprehensive_birth_plan_screen.dart` |  |
| [Birth-Builder-3-Comfort](png/Birth-Builder-3-Comfort.png) | Builder 3 — Comfort options | `birthplan/comprehensive_birth_plan_screen.dart` |  |
| [Birth-Builder-4-AfterBaby](png/Birth-Builder-4-AfterBaby.png) | Builder 4 — After baby | `birthplan/comprehensive_birth_plan_screen.dart` |  |
| [Birth-Builder-5-PlansChange](png/Birth-Builder-5-PlansChange.png) | Builder 5 — If plans change | `birthplan/comprehensive_birth_plan_screen.dart` |  |
| [Birth-Builder-Feedback](png/Birth-Builder-Feedback.png) | Birth plan feedback dialog | `widgets/qualitative_survey_dialog.dart (opened by birthplan/comprehensive_birth_plan_screen.dart after Save plan)` |  |
| [Birth-Plan](png/Birth-Plan.png) | Your birth preferences | `birthplan/birth_plan_display_screen.dart` |  |

## Phase 13: You and privacy

Dart files: `lib/editprofile/edit_profile_screen.dart`, `lib/privacy/privacy_center_screen.dart`, `lib/privacy/blocked_users_screen.dart`, `lib/pregnancy_loss/widgets/support_stage_settings_tile.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [You-Profile](png/You-Profile.png) | You — profile | `editprofile/edit_profile_screen.dart` | Edit Profile sits on its own row under the name. No Support FAB on this tab. |
| [You-Profile-Open](png/You-Profile-Open.png) | You — sections open | `editprofile/edit_profile_screen.dart` |  |
| [You-EditProfile](png/You-EditProfile.png) | You — editing profile | `editprofile/edit_profile_screen.dart` |  |
| [You-Profile-Guest](png/You-Profile-Guest.png) | You — guest | `auth/guest_account_cta.dart` |  |
| [You-Dialog-SupportStage](png/You-Dialog-SupportStage.png) | Update support dialog | `pregnancy_loss/widgets/support_stage_settings_tile.dart` |  |
| [You-Dialog-DeleteProfile](png/You-Dialog-DeleteProfile.png) | Delete Profile dialog | `editprofile/edit_profile_screen.dart` |  |
| [You-Dialog-SignOut](png/You-Dialog-SignOut.png) | Sign Out dialog | `editprofile/edit_profile_screen.dart` |  |
| [You-Privacy](png/You-Privacy.png) | Privacy & Trust | `privacy/privacy_center_screen.dart` |  |
| [You-Privacy-Open](png/You-Privacy-Open.png) | Privacy & Trust — info open | `privacy/privacy_center_screen.dart` |  |
| [You-BlockedUsers](png/You-BlockedUsers.png) | Blocked Users | `privacy/blocked_users_screen.dart` |  |
| [You-BlockedUsers-Empty](png/You-BlockedUsers-Empty.png) | Blocked Users — empty | `privacy/blocked_users_screen.dart` |  |
| [You-Dialog-DeleteAccount](png/You-Dialog-DeleteAccount.png) | Delete Account dialog | `privacy/privacy_center_screen.dart` |  |

## Phase 14: Assistant and support

Dart files: `lib/assistant/assistant_screen.dart`, `lib/immediate_support/immediate_support_hub_screen.dart`, `lib/immediate_support/immediate_support_checkin_screen.dart`, `lib/immediate_support/immediate_support_content.dart`, `lib/emotional_support/widgets/crisis_988_card.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Support-Assistant-Empty](png/Support-Assistant-Empty.png) | AI Assistant (first open) | `assistant/assistant_screen.dart` |  |
| [Support-Assistant](png/Support-Assistant.png) | AI Assistant | `assistant/assistant_screen.dart` |  |
| [Support-CheckIn](png/Support-CheckIn.png) | Support check-in | `immediate_support/immediate_support_checkin_screen.dart` |  |
| [Support-Hub](png/Support-Hub.png) | Support for you | `immediate_support/immediate_support_hub_screen.dart` | "Call 988" is the purple filled button, as in code. No red. |
| [Support-Hub-Selected](png/Support-Hub-Selected.png) | Support for you (your choices) | `immediate_support/immediate_support_hub_screen.dart` |  |

## Phase 15: Pregnancy-loss support mode

Dart files: `lib/pregnancy_loss/pregnancy_loss_transition_screen.dart`, `lib/pregnancy_loss/pregnancy_loss_preferences_screen.dart`, `lib/pregnancy_loss/pregnancy_loss_home_content.dart`, `lib/pregnancy_loss/widgets/pregnancy_loss_home_variant.dart`, `lib/pregnancy_loss/pregnancy_loss_support_hub_screen.dart`, `lib/pregnancy_loss/pregnancy_loss_provider_questions_screen.dart`, `lib/pregnancy_loss/pregnancy_loss_learning_screen.dart`, `lib/pregnancy_loss/pregnancy_loss_learning_topics.dart`, `lib/pregnancy_loss/widgets/pregnancy_loss_crisis_resources.dart`

| Mockup | Title | Drawn from | Notes |
|---|---|---|---|
| [Loss-StagePicker](png/Loss-StagePicker.png) | Loss: support stage picker | `pregnancy_loss/widgets/support_stage_settings_tile.dart` |  |
| [Loss-Transition](png/Loss-Transition.png) | Loss: transition | `pregnancy_loss/pregnancy_loss_transition_screen.dart` |  |
| [Loss-Preferences](png/Loss-Preferences.png) | Loss: support preferences | `pregnancy_loss/pregnancy_loss_preferences_screen.dart` |  |
| [Loss-Home](png/Loss-Home.png) | Loss: Home tab | `Home/home_screen_v2.dart + pregnancy_loss/widgets/pregnancy_loss_home_variant.dart` | Calm: no warm circle in the header. Call / Text / Chat with 988 are three equal soft rows, as in code. Support FAB present (Home tab). |
| [Loss-Support](png/Loss-Support.png) | Loss: support options | `pregnancy_loss/pregnancy_loss_support_hub_screen.dart` | Same three soft 988 rows. No decoration. |
| [Loss-ProviderQuestions](png/Loss-ProviderQuestions.png) | Loss: provider questions | `pregnancy_loss/pregnancy_loss_provider_questions_screen.dart` |  |
| [Loss-Learn](png/Loss-Learn.png) | Loss: Learn tab | `pregnancy_loss/pregnancy_loss_learning_screen.dart` |  |
| [Loss-Learn-Topic](png/Loss-Learn-Topic.png) | Loss: learning guide | `pregnancy_loss/pregnancy_loss_learning_topics.dart + Home/Learning Modules/learning_module_detail_screen.dart` |  |
| [Community-Feed-Loss](png/Community-Feed-Loss.png) | Loss: Community tab | `Community/community_screen.dart` | The pregnancy-loss variant of community_screen.dart (communityStageFilter). Same file as phase 9: re-check Community-Feed after editing. |
