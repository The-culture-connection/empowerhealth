import { pct } from "./reportMetrics";

export const insightsHealthUnderstanding = (x: {
  moduleCompletionRate: number;
  avsRate: number;
  avgModuleUnderstanding: number | null;
  surveySubmitRate: number;
  usersWithModule: number;
  usersTotal: number;
}): string[] => {
  const out: string[] = [];
  if (x.usersTotal > 0) {
    out.push(`${pct(x.moduleCompletionRate)} of active users completed at least one learning module in this window.`);
  }
  out.push(
    `After-visit summary activity reached ${pct(x.avsRate)} of active users (visit_summary_created / active users).`,
  );
  if (x.avgModuleUnderstanding != null) {
    out.push(
      `Average module understanding star rating (ModuleFeedback) was ${x.avgModuleUnderstanding.toFixed(2)} on a 1–5 scale.`,
    );
  } else {
    out.push("No ModuleFeedback with understanding scores in this date range.");
  }
  out.push(
    `Module survey / gate submissions (learning_module_survey_submitted) reached ${pct(x.surveySubmitRate)} of users who completed a module.`,
  );
  if (x.usersWithModule > 0 && x.avgModuleUnderstanding != null && x.avgModuleUnderstanding >= 4) {
    out.push("Users engaging with modules show strong self-reported understanding in ModuleFeedback.");
  }
  return out;
};

export const insightsSelfAdvocacy = (x: {
  avgCare: number | null;
  journalRate: number;
  confidencePulseRate: number;
}): string[] => {
  const out: string[] = [];
  if (x.avgCare != null) {
    out.push(
      `Care navigation survey composite access score averaged ${x.avgCare.toFixed(2)} (1–5 scale mapped from access responses).`,
    );
  }
  out.push(`${pct(x.journalRate)} of active users recorded at least one journal entry.`);
  out.push(`${pct(x.confidencePulseRate)} of active users submitted a confidence_signal_submitted pulse.`);
  if (x.journalRate > 0.15 && x.avgCare != null && x.avgCare >= 3.5) {
    out.push("Journal use and care-survey scores both suggest reflective, supported engagement for a subset of users.");
  }
  return out;
};

export const insightsCareNavigation = (x: {
  contactRate: number;
  selectionRate: number;
  avgProfilesPerSearch: number;
}): string[] => {
  return [
    `Provider contact taps occurred in ${pct(x.contactRate)} of provider searches (provider_contact_clicked / provider_search_initiated).`,
    `Successful provider selection signals in ${pct(x.selectionRate)} of searches (provider_selected_success / provider_search_initiated).`,
    `Rough exploration depth: ${x.avgProfilesPerSearch.toFixed(2)} profile views per search (provider_profile_viewed / provider_search_initiated).`,
  ];
};

export const insightsEngagementPathway = (x: {
  navigatorModuleRate: number;
  selfModuleRate: number;
  navigatorSessions: number;
  selfSessions: number;
}): string[] => {
  const out: string[] = [];
  out.push(
    `Navigator cohort: ${x.navigatorSessions} session_started events; self-directed: ${x.selfSessions}. (Users can appear in unknown if cohort metadata is missing.)`,
  );
  out.push(
    `Learning module completion share: navigator-aligned ${pct(x.navigatorModuleRate)} vs self-directed ${pct(x.selfModuleRate)} among users with known cohort.`,
  );
  if (x.navigatorModuleRate > x.selfModuleRate && x.selfModuleRate >= 0) {
    out.push("Navigator-labeled users show higher module completion participation in this window.");
  } else if (x.selfModuleRate > x.navigatorModuleRate) {
    out.push("Self-directed users show higher module completion participation in this window.");
  }
  return out;
};

export const insightsCarePreparation = (x: {
  birthPlanRate: number;
  learningPrepRate: number;
  prepUnderstanding: number | null;
}): string[] => {
  const out: string[] = [
    `${pct(x.birthPlanRate)} of active users completed a birth plan.`,
    `${pct(x.learningPrepRate)} started and/or completed learning modules (proxy for preparation engagement).`,
  ];
  if (x.prepUnderstanding != null) {
    out.push(`Module feedback understanding averaged ${x.prepUnderstanding.toFixed(2)} for preparation-related learning signals.`);
  }
  return out;
};

export const insightsCommunitySupport = (x: {
  postRate: number;
  replyRate: number;
  overlapRate: number;
}): string[] => {
  return [
    `${pct(x.postRate)} of active users created a community post.`,
    `${pct(x.replyRate)} of active users replied to a post.`,
    `${pct(x.overlapRate)} of users who posted also journaled (co-engagement proxy).`,
  ];
};
