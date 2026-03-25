/**
 * Event definitions aligned with `/analytics/info` (Analytics Info).
 * Status and “what it measures” text mirror that page where the event appears.
 */

import type { EventImplementationStatus } from "./types";

export interface DictionaryEntry {
  /** Human-readable: what this measures */
  measures: string;
  status: EventImplementationStatus;
}

/** Primary lookup by `eventName` as stored in `analytics_events`. */
export const EVENT_DICTIONARY: Record<string, DictionaryEntry> = {
  session_started: {
    measures: "App session begins (cold start or resume after background)",
    status: "tracked",
  },
  session_ended: {
    measures: "Session ends with duration; updates user_sessions",
    status: "tracked",
  },
  screen_view: {
    measures: "Screen / surface exposure",
    status: "tracked",
  },
  screen_time_spent: {
    measures: "Dwell time on a named screen",
    status: "tracked",
  },
  feature_time_spent: {
    measures: "Dwell time attributed to a feature id",
    status: "tracked",
  },
  flow_abandoned: {
    measures: "User left a key flow before completion",
    status: "partial",
  },
  provider_search_initiated: {
    measures: "Search intent",
    status: "tracked",
  },
  provider_profile_viewed: {
    measures: "Profile detail viewed",
    status: "tracked",
  },
  provider_contact_clicked: {
    measures: "Contact action (call / web / directions)",
    status: "tracked",
  },
  provider_selected_success: {
    measures: "Successful provider selection / save signal",
    status: "tracked",
  },
  provider_review_submitted: {
    measures: "User submitted a provider review (rating + optional text)",
    status: "tracked",
  },
  micro_measure_submitted: {
    measures: "Micro-measure / confidence payload stored and logged",
    status: "tracked",
  },
  confidence_signal_submitted: {
    measures: "Confidence / understanding pulse",
    status: "tracked",
  },
  visit_summary_created: {
    measures: "Summary created or upload succeeded",
    status: "tracked",
  },
  visit_summary_viewed: {
    measures: "User opened an existing appointment / visit summary (list → detail)",
    status: "tracked",
  },
  visit_summary_edited: {
    measures: "Summary edited",
    status: "needs-implementation",
  },
  journal_entry_created: {
    measures: "New journal entry",
    status: "tracked",
  },
  journal_mood_selected: {
    measures: "Mood self-report",
    status: "tracked",
  },
  learning_module_viewed: {
    measures: "Module detail opened",
    status: "tracked",
  },
  learning_module_started: {
    measures: "User began engaging with module content",
    status: "tracked",
  },
  learning_module_survey_submitted: {
    measures: "Learning module survey completed (qualitative or archive gate; not a quiz)",
    status: "tracked",
  },
  learning_module_completed: {
    measures: "Module marked complete / archived",
    status: "tracked",
  },
  birth_plan_viewed: {
    measures: "User opened saved birth plan display screen",
    status: "tracked",
  },
  birth_plan_completed: {
    measures: "Birth plan completed / saved",
    status: "tracked",
  },
  birth_plan_exported: {
    measures: "User shared or exported birth plan via system share sheet",
    status: "tracked",
  },
  community_post_created: {
    measures: "New post created",
    status: "tracked",
  },
  community_post_viewed: {
    measures: "Post detail viewed",
    status: "tracked",
  },
  community_post_liked: {
    measures: "Post liked",
    status: "tracked",
  },
  community_post_replied: {
    measures: "Reply submitted",
    status: "tracked",
  },
  /** Logged from app; not all rows appear on Analytics Info glossary — treat as tracked when present. */
  helpfulness_survey_submitted: {
    measures: "Helpfulness rating submitted (also writes helpfulness_surveys collection)",
    status: "tracked",
  },
  /** Logged when structured outcome is saved; parallel to CareSurvey in some flows. */
  care_navigation_outcome_submitted: {
    measures: "Structured care navigation outcome recorded (care_navigation_outcomes collection)",
    status: "partial",
  },
};

/** Non–analytics_events sources documented in reports. */
export const SOURCE_DICTIONARY: Record<string, DictionaryEntry> = {
  ModuleFeedback: {
    measures: "Learning module archive-gate / survey: star ratings (understanding, next steps, confidence) + optional text",
    status: "tracked",
  },
  CareSurvey: {
    measures: "Care navigation survey: selected needs + per-need access responses (Firestore CareSurvey)",
    status: "tracked",
  },
  care_navigation_outcomes: {
    measures: "Structured outcome rows (need type, outcome code, optional notes) in care_navigation_outcomes",
    status: "partial",
  },
};

export function dictionaryRowsForEvents(eventNames: readonly string[]): { eventName: string; measures: string; status: EventImplementationStatus }[] {
  const seen = new Set<string>();
  const out: { eventName: string; measures: string; status: EventImplementationStatus }[] = [];
  for (const name of eventNames) {
    if (seen.has(name)) continue;
    seen.add(name);
    const d = EVENT_DICTIONARY[name];
    out.push({
      eventName: name,
      measures: d?.measures ?? "(See Analytics Info — event name may be legacy or rare.)",
      status: d?.status ?? "partial",
    });
  }
  return out;
}

export function dictionaryRowsForSources(sourceKeys: readonly string[]): { eventName: string; measures: string; status: EventImplementationStatus }[] {
  return sourceKeys.map((key) => {
    const d = SOURCE_DICTIONARY[key];
    return {
      eventName: key,
      measures: d?.measures ?? key,
      status: d?.status ?? "partial",
    };
  });
}
