/**
 * Implementation status for analytics streams (aligns with Analytics Info).
 * Used for coverage / "limited data" notes — does not block reports.
 */

import type { CoverageFlag, EventImplementationStatus } from "./types";

const PARTIAL: EventImplementationStatus = "partial";
const NEEDS: EventImplementationStatus = "needs-implementation";
const TRACKED: EventImplementationStatus = "tracked";

/** Baseline registry; merge with in-range observations in report builders. */
export const ANALYTICS_STREAM_COVERAGE: Omit<CoverageFlag, "limitedInRange">[] = [
  {
    eventOrSource: "session_ended",
    status: TRACKED,
    note: "Emitted on background and teardown; duration on user_sessions.",
  },
  {
    eventOrSource: "flow_abandoned",
    status: PARTIAL,
    note: "Currently wired for learning module early exit; other flows optional.",
  },
  {
    eventOrSource: "provider_filter_applied",
    status: NEEDS,
    note: "Helper exists; filter UI not fully instrumented.",
  },
  {
    eventOrSource: "visit_summary_edited",
    status: NEEDS,
    note: "Helper exists; edit flow instrumentation incomplete.",
  },
  {
    eventOrSource: "learning_module_survey_submitted",
    status: TRACKED,
    note: "Replaces legacy quiz naming; qualitative + archive-gate surveys.",
  },
  {
    eventOrSource: "learning_module_quiz_submitted",
    status: NEEDS,
    note: "Legacy name; treat as alias of learning_module_survey_submitted if present.",
  },
  {
    eventOrSource: "helpfulness_surveys collection",
    status: PARTIAL,
    note: "Event helpfulness_survey_submitted may exist; separate collection not queried unless events show usage.",
  },
  {
    eventOrSource: "milestone_checkins",
    status: PARTIAL,
    note: "Structured collection exists; included only via events in range.",
  },
];

export function baselineCoverageFlags(): CoverageFlag[] {
  return ANALYTICS_STREAM_COVERAGE.map((c) => ({ ...c }));
}
