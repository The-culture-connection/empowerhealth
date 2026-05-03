/**
 * EmpowerHealth Watch — research export field specification (machine-readable).
 * Align with: Admindashboardrenovation/EmpowerHealth Watch Research Field Specification for App + Export.pdf
 * and Admindashboardrenovation/Todos.md. Update when the PDF changes.
 */

export const RESEARCH_SPEC_VERSION = '1.0.0';

/** Yes/No for binary fields in research exports */
export const CODE_YES_NO = { yes: 1, no: 0 } as const;

/** Pregnancy / postpartum status */
export const CODE_PP_STATUS = { pregnant: 1, postpartum: 2 } as const;

/** Age group for baseline export (numeric codes; REDCap-aligned). */
export const CODE_AGE_GROUP = {
  under_18: 1,
  age_18_24: 2,
  age_25_34: 3,
  age_35_44: 4,
  age_45_plus: 5,
} as const;

export function deriveAgeGroupCode(ageYears: number): number {
  if (!Number.isFinite(ageYears) || ageYears < 0) return 5;
  if (ageYears < 18) return CODE_AGE_GROUP.under_18;
  if (ageYears <= 24) return CODE_AGE_GROUP.age_18_24;
  if (ageYears <= 34) return CODE_AGE_GROUP.age_25_34;
  if (ageYears <= 44) return CODE_AGE_GROUP.age_35_44;
  return CODE_AGE_GROUP.age_45_plus;
}

/** Insurance type for baseline (numeric). */
export const INSURANCE_TYPE_CODES = {
  medicaid: 1,
  medicare: 2,
  private_commercial: 3,
  uninsured_self_pay: 4,
  other: 5,
  unknown_declined: 6,
} as const;

/**
 * Recruitment source (1–7). Labels are illustrative until PDF text is synced verbatim.
 */
export const RECRUITMENT_SOURCE_CODES = {
  1: 'clinic_partner',
  2: 'community_org',
  3: 'social_media',
  4: 'referral',
  5: 'search',
  6: 'other',
  7: 'declined_unknown',
} as const;

export const RECRUITMENT_PATHWAY_CODES = {
  navigator_supported: 1,
  self_directed: 2,
} as const;

/** Likert-style 1–5 */
export const LIKERT_MIN = 1;
export const LIKERT_MAX = 5;

/**
 * Navigation / access outcome codes (Todos §4).
 */
export const NAVIGATION_OUTCOME_CODES = {
  yes: 1,
  partly: 2,
  no: 3,
  didnt_try: 4,
  didnt_know_how: 5,
  couldnt_access: 6,
} as const;

/** research_participants/{study_id} export (no Firebase UID) */
export const PARTICIPANT_EXPORT_COLUMNS = [
  'study_id',
  'research_participant',
  'recruitment_source',
  'recruitment_source_other',
  'recruitment_pathway',
  'recorded_at',
] as const;

/** research_baseline/{study_id} export */
export const BASELINE_EXPORT_COLUMNS = [
  'study_id',
  'recruitment_pathway',
  'age_years',
  'age_group',
  'pp_status',
  'gest_week',
  'postpartum_month',
  'insurance_type',
  'insurance_other',
  'support_person_nav',
  'baseline_advocacy_conf',
  'baseline_ts',
  'recorded_at',
] as const;

/** research_micro_measures export */
export const MICRO_MEASURE_EXPORT_COLUMNS = [
  'study_id',
  'micro_understand',
  'micro_next_step',
  'micro_confidence',
  'content_id',
  'content_type',
  'micro_ts',
  'recorded_at',
] as const;

/** research_needs_checklists export */
export const NEEDS_CHECKLIST_EXPORT_COLUMNS = [
  'study_id',
  'need_prenatal_postpartum',
  'need_delivery_prep',
  'need_med_followup',
  'need_mental_health',
  'need_lactation',
  'need_infant_care',
  'need_benefits',
  'need_transport',
  'need_other',
  'need_other_text',
  'needs_ts',
  'recorded_at',
] as const;

/** research_navigation_outcomes export */
export const NAVIGATION_OUTCOMES_EXPORT_COLUMNS = [
  'study_id',
  'needs_event_id',
  'need_prenatal_postpartum_outcome',
  'need_delivery_prep_outcome',
  'need_med_followup_outcome',
  'need_mental_health_outcome',
  'need_lactation_outcome',
  'need_infant_care_outcome',
  'need_benefits_outcome',
  'need_transport_outcome',
  'need_other_outcome',
  'outcome_ts',
  'recorded_at',
] as const;

/** research_milestone_prompts export */
export const MILESTONE_EXPORT_COLUMNS = [
  'study_id',
  'milestone_health_question',
  'milestone_clear_next_step',
  'milestone_app_helped_next_step',
  'milestone_type',
  'milestone_ts',
  'recorded_at',
] as const;

/** research_app_activity export (summary-friendly activity signals) */
export const APP_ACTIVITY_EXPORT_COLUMNS = [
  'study_id',
  'activity_type',
  'module_id',
  'avs_upload_type',
  'library_section',
  'provider_review_action',
  'extra',
  'activity_ts',
  'recorded_at',
] as const;

export type ResearchInstrumentId =
  | 'participants'
  | 'baseline'
  | 'micro_measures'
  | 'needs_checklist'
  | 'navigation_outcomes'
  | 'milestone_prompts'
  | 'app_activity';

export const RESEARCH_INSTRUMENTS: {
  id: ResearchInstrumentId;
  collection: string;
  columns: readonly string[];
}[] = [
  { id: 'participants', collection: 'research_participants', columns: PARTICIPANT_EXPORT_COLUMNS },
  { id: 'baseline', collection: 'research_baseline', columns: BASELINE_EXPORT_COLUMNS },
  { id: 'micro_measures', collection: 'research_micro_measures', columns: MICRO_MEASURE_EXPORT_COLUMNS },
  { id: 'needs_checklist', collection: 'research_needs_checklists', columns: NEEDS_CHECKLIST_EXPORT_COLUMNS },
  { id: 'navigation_outcomes', collection: 'research_navigation_outcomes', columns: NAVIGATION_OUTCOMES_EXPORT_COLUMNS },
  { id: 'milestone_prompts', collection: 'research_milestone_prompts', columns: MILESTONE_EXPORT_COLUMNS },
  { id: 'app_activity', collection: 'research_app_activity', columns: APP_ACTIVITY_EXPORT_COLUMNS },
];

export function csvEscape(value: unknown): string {
  if (value === null || value === undefined) return '';
  const s = String(value);
  if (/[",\n\r]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

export function rowToCsvLine(columns: readonly string[], row: Record<string, unknown>): string {
  return columns.map((c) => csvEscape(row[c])).join(',');
}
