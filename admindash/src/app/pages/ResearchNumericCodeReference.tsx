import { ChevronRight } from "lucide-react";
import {
  AVS_UPLOAD_TYPE_SLUGS,
  CODE_AGE_GROUP,
  CODE_PP_STATUS,
  CODE_YES_NO,
  INSURANCE_TYPE_CODES,
  LIKERT_MAX,
  LIKERT_MIN,
  NAVIGATION_OUTCOME_CODES,
  MILESTONE_TYPE_CODES,
  PROVIDER_REVIEW_ACTIVITY_LABELS,
  RECRUITMENT_PATHWAY_CODES,
  RECRUITMENT_SOURCE_CODES,
} from "@research/researchFieldSpec";

const AGE_GROUP_LABELS: Record<keyof typeof CODE_AGE_GROUP, string> = {
  under_18: "Under 18 years",
  age_18_24: "18 through 24 years",
  age_25_34: "25 through 34 years",
  age_35_44: "35 through 44 years",
  age_45_plus: "45 years and older",
};

function CodeTable({ rows }: { rows: { code: string; meaning: string }[] }) {
  return (
    <div className="overflow-x-auto rounded-lg border text-sm" style={{ borderColor: "var(--lavender-200)" }}>
      <table className="w-full min-w-[280px] border-collapse">
        <thead>
          <tr style={{ backgroundColor: "var(--lavender-50)" }}>
            <th className="text-left px-3 py-2 font-medium" style={{ color: "var(--warm-700)", width: "6rem" }}>
              Code
            </th>
            <th className="text-left px-3 py-2 font-medium" style={{ color: "var(--warm-700)" }}>
              Meaning
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.code} className="border-t" style={{ borderColor: "var(--lavender-100)" }}>
              <td className="px-3 py-2 font-mono" style={{ color: "var(--eh-primary)" }}>
                {r.code}
              </td>
              <td className="px-3 py-2" style={{ color: "var(--warm-700)" }}>
                {r.meaning}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function ResearchNumericCodeReference() {
  const ageGroupRows = (
    Object.entries(CODE_AGE_GROUP) as [keyof typeof CODE_AGE_GROUP, (typeof CODE_AGE_GROUP)[keyof typeof CODE_AGE_GROUP]][]
  ).map(([key, val]) => ({
    code: String(val),
    meaning: AGE_GROUP_LABELS[key],
  }));

  const ppRows = [
    { code: String(CODE_PP_STATUS.pregnant), meaning: "Currently pregnant" },
    { code: String(CODE_PP_STATUS.postpartum), meaning: "Postpartum" },
  ];

  const insuranceRows = (
    Object.entries(INSURANCE_TYPE_CODES) as [keyof typeof INSURANCE_TYPE_CODES, number][]
  ).map(([key, val]) => ({
    code: String(val),
    meaning: key.replace(/_/g, " "),
  }));

  const recruitmentRows = (Object.entries(RECRUITMENT_SOURCE_CODES) as [string, string][]).map(([code, slug]) => ({
    code,
    meaning: slug.replace(/_/g, " "),
  }));

  const pathwayRows = [
    { code: String(RECRUITMENT_PATHWAY_CODES.navigator_supported), meaning: "Navigator-supported cohort" },
    { code: String(RECRUITMENT_PATHWAY_CODES.self_directed), meaning: "Self-directed cohort" },
  ];

  const navRows = (
    Object.entries(NAVIGATION_OUTCOME_CODES) as [keyof typeof NAVIGATION_OUTCOME_CODES, number][]
  ).map(([key, val]) => ({
    code: String(val),
    meaning: key.replace(/_/g, " "),
  }));

  const navigationOutcomeExportRows = [
    { code: "0", meaning: "Need not selected on the linked needs checklist (N/A for that column)" },
    ...navRows,
  ];

  const milestoneTypeRows = (
    Object.entries(MILESTONE_TYPE_CODES) as [keyof typeof MILESTONE_TYPE_CODES, number][]
  ).map(([key, val]) => ({
    code: String(val),
    meaning: key.replace(/_/g, " "),
  }));

  const providerReviewActivityRows = Object.entries(PROVIDER_REVIEW_ACTIVITY_LABELS).map(([code, meaning]) => ({
    code,
    meaning,
  }));

  const avsUploadTypeRows = AVS_UPLOAD_TYPE_SLUGS.map((slug) => ({
    code: slug,
    meaning:
      slug === "pdf"
        ? "After-visit summary uploaded as PDF"
        : slug === "image_gallery"
          ? "Photo or scan chosen from files (converted to PDF for analysis)"
          : slug === "image_camera"
            ? "Photo captured in-app with camera (when supported)"
            : slug === "notes_typed"
              ? "Visit notes typed and analyzed as text"
              : "Unknown or unspecified channel",
  }));

  const yesNoRows = [
    { code: String(CODE_YES_NO.yes), meaning: "Yes / endorsed / present" },
    { code: String(CODE_YES_NO.no), meaning: "No / not endorsed / absent" },
  ];

  return (
    <details className="rounded-2xl border p-6" style={{ borderColor: "var(--lavender-200)", backgroundColor: "white" }}>
      <summary className="cursor-pointer list-none font-medium text-lg outline-none [&::-webkit-details-marker]:hidden" style={{ color: "var(--warm-800)" }}>
        <span className="inline-flex items-center gap-2">
          <ChevronRight className="w-5 h-5 shrink-0 text-[var(--eh-primary)]" aria-hidden />
          {"Numeric code reference (exports & REDCap alignment)"}
        </span>
      </summary>
      <p className="mt-3 text-sm mb-6" style={{ color: "var(--warm-600)" }}>
        Research CSV/JSON use numeric codes for categorical fields. Canonical definitions live in{" "}
        <code className="text-xs bg-[var(--lavender-50)] px-1 rounded">functions/src/research/researchFieldSpec.ts</code>{" "}
        (also <code className="text-xs bg-[var(--lavender-50)] px-1 rounded">@research</code> in this app).
      </p>

      <div className="space-y-8">
        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Baseline — <code className="font-mono text-sm">age_group</code>
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Derived from <code className="font-mono">age_years</code> at ingest (server-side).
          </p>
          <CodeTable rows={ageGroupRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Baseline — <code className="font-mono text-sm">pp_status</code>
          </h3>
          <CodeTable rows={ppRows} />
          <p className="text-xs mt-2" style={{ color: "var(--warm-500)" }}>
            When <code className="font-mono">pp_status = 1</code>, expect <code className="font-mono">gest_week</code> and
            null <code className="font-mono">postpartum_month</code>. When <code className="font-mono">2</code>, the reverse.
          </p>
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Baseline — <code className="font-mono text-sm">insurance_type</code>
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Code <strong>5</strong> (other) requires free text in <code className="font-mono">insurance_other</code>; other
            codes should have empty <code className="font-mono">insurance_other</code>.
          </p>
          <CodeTable rows={insuranceRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Participants — <code className="font-mono text-sm">recruitment_source</code>
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Code <strong>6</strong> requires <code className="font-mono">recruitment_source_other</code>; code{" "}
            <strong>7</strong> is declined / unknown.
          </p>
          <CodeTable rows={recruitmentRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            {"Participants & baseline — "}
            <code className="font-mono text-sm">recruitment_pathway</code>
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Matches export filter options on this page.
          </p>
          <CodeTable rows={pathwayRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Baseline — <code className="font-mono text-sm">support_person_nav</code>
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Integer <strong>1</strong>–<strong>6</strong> only (same labels as the per-need access codes below, without the export-only{" "}
            <strong>0</strong> sentinel).
          </p>
          <CodeTable rows={navRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Baseline — <code className="font-mono text-sm">baseline_advocacy_conf</code>
          </h3>
          <p className="text-sm" style={{ color: "var(--warm-600)" }}>
            Integer Likert <strong>{LIKERT_MIN}</strong>–<strong>{LIKERT_MAX}</strong> (higher = more confident).
          </p>
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Participants — <code className="font-mono text-sm">research_participant</code>
          </h3>
          <CodeTable rows={yesNoRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Micro-measures — <code className="font-mono text-sm">micro_understand</code>,{" "}
            <code className="font-mono text-sm">micro_next_step</code>, <code className="font-mono text-sm">micro_confidence</code>
          </h3>
          <p className="text-sm" style={{ color: "var(--warm-600)" }}>
            Likert <strong>{LIKERT_MIN}</strong>–<strong>{LIKERT_MAX}</strong> (required). Rows are created only by the{" "}
            <code className="font-mono text-xs">submitMicroMeasure</code> callable. <code className="font-mono text-xs">content_type</code>{" "}
            is one of: <code className="font-mono text-xs">learning_module</code>, <code className="font-mono text-xs">visit_summary_avs</code>,{" "}
            <code className="font-mono text-xs">visit_summary_notes</code>, <code className="font-mono text-xs">micro_measure</code>,{" "}
            <code className="font-mono text-xs">user_feedback</code>. Optional validated <code className="font-mono text-xs">micro_ts_client</code>{" "}
            (ISO-8601) is stored when the client sends it; canonical <code className="font-mono text-xs">micro_ts</code> /{" "}
            <code className="font-mono text-xs">recorded_at</code> are server timestamps.
          </p>
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Needs checklist — <code className="font-mono text-sm">need_prenatal_postpartum</code> …{" "}
            <code className="font-mono text-sm">need_other</code>
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Each need flag is coded <strong>0</strong> = not selected, <strong>1</strong> = selected. Rows are written only by the{" "}
            <code className="font-mono text-xs">submitNeedsChecklist</code> callable. <code className="font-mono text-xs">need_other_text</code>{" "}
            is required when <code className="font-mono text-xs">need_other</code> is <strong>1</strong> and must be absent or empty when{" "}
            <code className="font-mono text-xs">need_other</code> is <strong>0</strong>. Canonical <code className="font-mono text-xs">needs_ts</code> /{" "}
            <code className="font-mono text-xs">recorded_at</code> are server timestamps.
          </p>
          <CodeTable rows={yesNoRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Navigation outcomes — <code className="font-mono text-sm">need_*_outcome</code> (
            <code className="font-mono text-sm">research_navigation_outcomes</code>)
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            One row per completed care access flow, linked by <code className="font-mono text-xs">needs_event_id</code>. Rows are written only by the{" "}
            <code className="font-mono text-xs">submitNavigationOutcome</code> callable. For each need column: <strong>0</strong> when that need was not
            selected on the linked checklist; <strong>1</strong>–<strong>6</strong> when it was selected (care access answers). Canonical{" "}
            <code className="font-mono text-xs">outcome_ts</code> / <code className="font-mono text-xs">recorded_at</code> are server timestamps.
          </p>
          <CodeTable rows={navigationOutcomeExportRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            Milestone prompts — <code className="font-mono text-sm">milestone_type</code> (
            <code className="font-mono text-sm">research_milestone_prompts</code>)
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Longitudinal window code (integer). <code className="font-mono text-xs">scheduleMilestonePrompt</code> derives a suggested type from{" "}
            <code className="font-mono text-xs">research_baseline</code> (gestational week or postpartum month). Rows are written only by{" "}
            <code className="font-mono text-xs">submitMilestoneCheckIn</code>. <strong>9</strong> = general / legacy mapping when no specific window
            applies.
          </p>
          <CodeTable rows={milestoneTypeRows} />
          <p className="text-sm mt-4 mb-2" style={{ color: "var(--warm-600)" }}>
            <code className="font-mono text-sm">milestone_health_question</code>,{" "}
            <code className="font-mono text-sm">milestone_clear_next_step</code>,{" "}
            <code className="font-mono text-sm">milestone_app_helped_next_step</code> — required <strong>0</strong> / <strong>1</strong>. Canonical{" "}
            <code className="font-mono text-xs">milestone_ts</code> / <code className="font-mono text-xs">recorded_at</code> are server timestamps.
          </p>
          <CodeTable rows={yesNoRows} />
        </section>

        <section>
          <h3 className="text-base font-semibold mb-2" style={{ color: "var(--warm-800)" }}>
            App activity — <code className="font-mono text-sm">research_app_activity</code> (Phase 6)
          </h3>
          <p className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
            Rows are written only by <code className="font-mono text-xs">recordModuleCompletion</code>,{" "}
            <code className="font-mono text-xs">recordProviderReviewActivity</code>, <code className="font-mono text-xs">recordAvsUploadActivity</code>, or{" "}
            <code className="font-mono text-xs">recordHealthMadeSimpleAccess</code>. <code className="font-mono text-xs">activity_type</code> is one of:{" "}
            <code className="font-mono text-xs">module_completed</code>, <code className="font-mono text-xs">provider_review</code>,{" "}
            <code className="font-mono text-xs">avs_upload</code>, <code className="font-mono text-xs">health_made_simple_access</code>. Exports use the{" "}
            <code className="font-mono text-xs">activity_export</code> file stem (alias of <code className="font-mono text-xs">app_activity</code>).
          </p>
          <p className="text-sm font-medium mb-1" style={{ color: "var(--warm-700)" }}>
            <code className="font-mono text-sm">provider_review_activity</code>
          </p>
          <CodeTable rows={providerReviewActivityRows} />
          <p className="text-sm font-medium mt-4 mb-1" style={{ color: "var(--warm-700)" }}>
            <code className="font-mono text-sm">avs_upload_type</code>
          </p>
          <CodeTable rows={avsUploadTypeRows} />
          <p className="text-sm mt-4" style={{ color: "var(--warm-600)" }}>
            <code className="font-mono text-sm">module_completion</code> is <strong>0</strong> or <strong>1</strong>.{" "}
            <code className="font-mono text-sm">health_made_simple_access</code> is a short lowercase slug (source and optional topic), max 64 characters,
            no PHI.
          </p>
        </section>
      </div>
    </details>
  );
}
