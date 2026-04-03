import type {
  EvidenceReport,
  NormalizedEvent,
  OutcomeSignalsBlock,
  ReportDataset,
  ReportParams,
  ReportPayload,
  ReportResult,
} from "./types";
import * as M from "./reportMetrics";
import { WHITELIST, whitelistSet } from "./reportWhitelists";
import {
  buildEventRows,
  coverageNoteFromRows,
  filterEvents,
  mainTrendFromDaily,
} from "./reportEvidence";
import { careNeedCategoryLabel } from "../firestore/careSurveyRepo";

function makeSummary(title: string, params: ReportParams) {
  return {
    title,
    dateRangeLabel: `${params.dateRange.start.toLocaleDateString()} – ${params.dateRange.end.toLocaleDateString()}`,
    generatedAt: new Date().toISOString(),
    cohortFilter: params.cohortType,
  };
}

export function payloadToResult(p: ReportPayload): ReportResult {
  const kpis: Record<string, string | number> = {};
  for (const k of p.kpis) {
    kpis[k.key] = k.value;
  }
  return {
    summary: p.summary,
    evidence: p.evidence,
    kpis,
    kpisList: p.kpis,
    charts: p.charts,
    tables: p.tables,
    insights: p.evidence.conclusions,
    coverageFlags: p.coverageFlags,
    rows: p.rows,
  };
}

function avgMeta(ev: NormalizedEvent[], names: string[], field: string): number | null {
  const set = new Set(names);
  const vals: number[] = [];
  for (const e of ev) {
    if (!set.has(e.eventName)) continue;
    const v = e.metadata[field];
    if (typeof v === "number" && !Number.isNaN(v)) vals.push(v);
  }
  if (vals.length === 0) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

function zeroInWhitelist(ev: NormalizedEvent[], whitelist: readonly string[]): string[] {
  const counts = new Map<string, number>();
  for (const n of whitelist) counts.set(n, 0);
  for (const e of ev) {
    if (counts.has(e.eventName)) counts.set(e.eventName, (counts.get(e.eventName) || 0) + 1);
  }
  return whitelist.filter((n) => (counts.get(n) || 0) === 0);
}

/** Review + listing-report analytics (metadata from mobile `logEvent` payloads). */
function providerPeerFeedbackFromEvents(ev: NormalizedEvent[]): {
  lines: string[];
  extraKpis: { key: string; label: string; value: string | number }[];
} {
  const rev = ev.filter((e) => e.eventName === "provider_review_submitted");
  const rep = ev.filter((e) => e.eventName === "provider_listing_report_submitted");
  const nRev = rev.length;
  const nRep = rep.length;
  const metaT = (e: NormalizedEvent, k: string) => e.metadata[k] === true;
  const heard = rev.filter((e) => metaT(e, "felt_heard")).length;
  const respected = rev.filter((e) => metaT(e, "felt_respected")).length;
  const clear = rev.filter((e) => metaT(e, "explained_clearly")).length;
  const www = rev.filter((e) => metaT(e, "has_what_went_well")).length;
  const share = (num: number) => (nRev > 0 ? M.pct(M.safeRate(num, nRev)) : "n/a");

  const lines: string[] = [
    `Provider directory peer signals in this event set: ${nRev} review submissions, ${nRep} listing reports.`,
  ];
  if (nRev > 0) {
    lines.push(
      `Among review events, shares with felt_heard / felt_respected / explained_clearly / has_what_went_well are ≈ ${share(heard)} / ${share(respected)} / ${share(clear)} / ${share(www)}.`,
    );
  } else if (nRep > 0) {
    lines.push("No review events in range; listing reports still show users flagging directory issues.");
  }

  const extraKpis: { key: string; label: string; value: string | number }[] = [
    { key: "provider_review_events", label: "provider_review_submitted (count)", value: nRev },
    {
      key: "provider_listing_report_events",
      label: "provider_listing_report_submitted (count)",
      value: nRep,
    },
  ];
  if (nRev > 0) {
    extraKpis.push(
      { key: "review_felt_heard_share", label: "Reviews w/ felt_heard", value: share(heard) },
      { key: "review_felt_respected_share", label: "Reviews w/ felt_respected", value: share(respected) },
      { key: "review_explained_clearly_share", label: "Reviews w/ explained_clearly", value: share(clear) },
      { key: "review_has_www_share", label: "Reviews w/ has_what_went_well", value: share(www) },
    );
  }
  return { lines, extraKpis };
}

function pulseOutcome(ev: NormalizedEvent[]): OutcomeSignalsBlock {
  const n =
    ev.filter((e) => e.eventName === "micro_measure_submitted" || e.eventName === "confidence_signal_submitted")
      .length;
  return {
    lines: [
      `Micro-measure / confidence pulses in this evidence set: ${n} events (metadata may include understand_meaning_score, know_next_step_score, confidence_score).`,
    ],
    pulseAverages: {
      understandMeaning: avgMeta(ev, ["micro_measure_submitted", "confidence_signal_submitted"], "understand_meaning_score"),
      knowNextStep: avgMeta(ev, ["micro_measure_submitted", "confidence_signal_submitted"], "know_next_step_score"),
      confidence: avgMeta(ev, ["micro_measure_submitted", "confidence_signal_submitted"], "confidence_score"),
      nEvents: n,
    },
  };
}

export function buildHealthUnderstandingReport(dataset: ReportDataset, params: ReportParams): ReportPayload {
  const type = "health_understanding_impact" as const;
  const wl = whitelistSet(type);
  const ev = filterEvents(dataset.events, wl);
  const anonymized = params.anonymized;
  const users = M.uniqueUsers(ev, anonymized);
  const nUsers = users.size;
  const modFb = dataset.moduleFeedback;

  const rowsE = buildEventRows(WHITELIST[type], ["ModuleFeedback"]);
  const zeros = zeroInWhitelist(ev, WHITELIST[type]);

  const counts: Record<string, number> = {};
  for (const name of WHITELIST[type]) counts[name] = M.countByEvent(ev, name);

  const usersMod = M.usersWithAnyOf(ev, ["learning_module_completed"], anonymized);
  const usersAvs = M.usersWithAnyOf(ev, ["visit_summary_created"], anonymized);
  const modUnd = M.avgModuleUnderstanding(modFb);
  const pulse = pulseOutcome(ev);

  const outcome: OutcomeSignalsBlock = {
    lines: [
      ...pulse.lines,
      `ModuleFeedback (Firestore): ${modFb.length} submissions in range; avg understanding stars: ${modUnd != null ? modUnd.toFixed(2) : "n/a"} (1–5).`,
    ],
    moduleFeedback: { n: modFb.length, avgUnderstanding: modUnd },
    careSurvey: undefined,
    pulseAverages: pulse.pulseAverages,
  };

  const completionRate = M.safeRate(usersMod.size, Math.max(nUsers, 1));
  const avsRate = M.safeRate(usersAvs.size, Math.max(nUsers, 1));

  const conclusions: string[] = [];
  if (modUnd != null && modUnd >= 4 && usersMod.size > 0) {
    conclusions.push("Users who completed learning modules in this window also left strong understanding scores in ModuleFeedback on average.");
  }
  if (completionRate > 0.15 && avsRate > 0.1) {
    conclusions.push("Both learning completion and after-visit summary creation appear among a measurable share of users in this cohort.");
  }
  if ((pulse.pulseAverages?.understandMeaning ?? 0) > 3.5 && (pulse.pulseAverages?.nEvents ?? 0) > 0) {
    conclusions.push("Pulse events that carry understanding scores suggest respondents report meaningful comprehension when those events fire.");
  }
  if (conclusions.length === 0) {
    conclusions.push("Keep this window or widen dates to strengthen comparative statements; current activity is sparse or mixed.");
  }

  const trend = mainTrendFromDaily(ev, "learning_module_completed");
  const takeaways = [
    conclusions[0] ?? trend,
    conclusions[1] ?? `Unique users with any listed event: ${nUsers}.`,
    conclusions[2] ?? `Whitelisted event rows total: ${ev.length}.`,
  ].slice(0, 3);

  const summaryParagraph = `This evidence summary uses only the Health Understanding Impact event set (see table). It includes ${nUsers} distinct users with at least one such event in the selected range. ModuleFeedback provides the primary structured understanding stars for learning modules; micro-measure and confidence pulse events add standardized score fields when present.`;

  const evidence: EvidenceReport = {
    summaryParagraph,
    totalUsers: nUsers,
    dateRangeLabel: makeSummary("", params).dateRangeLabel,
    mainTrend: trend,
    takeaways,
    eventsIncluded: rowsE,
    metricsKpis: [
      { key: "eventRows", label: "Total events (whitelisted)", value: ev.length },
      { key: "uniqueUsers", label: "Unique users", value: nUsers },
      { key: "learningModuleCompletedUsers", label: "Users w/ learning_module_completed", value: usersMod.size },
      { key: "visitSummaryCreatedUsers", label: "Users w/ visit_summary_created", value: usersAvs.size },
      { key: "moduleCompletionShare", label: "Share of users completing a module", value: M.pct(completionRate) },
      { key: "avgModuleUnderstanding", label: "Avg ModuleFeedback understanding (1–5)", value: modUnd != null ? modUnd.toFixed(2) : "n/a" },
    ],
    outcomeSignals: outcome,
    conclusions,
    coverageNote: coverageNoteFromRows(rowsE, zeros),
  };

  const daily = M.dailyCounts(ev, ["learning_module_completed", "visit_summary_created"]);
  const labs = [...daily.keys()].sort();
  const vals = labs.map((l) => daily.get(l) || 0);

  const kpis = evidence.metricsKpis.map((k) => ({ key: k.key, label: k.label, value: k.value }));

  return {
    summary: makeSummary("Health Understanding Impact Report", params),
    evidence,
    kpis,
    charts: [
      {
        id: "huTrend",
        title: "Whitelisted learning + AVS activity (daily event counts)",
        kind: "line",
        labels: labs,
        series: [{ name: "Events / day", data: vals }],
      },
    ],
    tables: [
      {
        title: "Relevant events included (Analytics Info)",
        columns: ["Event", "What it measures", "Status"],
        rows: rowsE.map((r) => [r.eventName, r.whatItMeasures, r.status]),
      },
      {
        title: "Whitelisted event counts",
        columns: ["Event", "Count"],
        rows: WHITELIST[type].map((n) => [n, counts[n] || 0]),
      },
    ],
    insights: conclusions,
    coverageFlags: [],
    rows: [
      { section: "summary", uniqueUsers: nUsers, ...Object.fromEntries(WHITELIST[type].map((n) => [`count_${n}`, counts[n] || 0])) },
      ...labs.map((l, i) => ({ day: l, dailyLearningAvs: vals[i] })),
    ],
  };
}

export function buildSelfAdvocacyReport(dataset: ReportDataset, params: ReportParams): ReportPayload {
  const type = "self_advocacy_confidence" as const;
  const wl = whitelistSet(type);
  const ev = filterEvents(dataset.events, wl);
  const anonymized = params.anonymized;
  const users = M.uniqueUsers(ev, anonymized);
  const care = dataset.careSurveys;
  const avgCare = M.avgCareComposite(care);

  const rowsE = buildEventRows(WHITELIST[type], ["CareSurvey"]);
  const zeros = zeroInWhitelist(ev, WHITELIST[type]);

  const pulse = pulseOutcome(ev);
  const peer = providerPeerFeedbackFromEvents(ev);
  const outcome: OutcomeSignalsBlock = {
    lines: [
      ...peer.lines,
      ...pulse.lines,
      `CareSurvey: ${care.length} submissions; composite access score (1–5): ${avgCare != null ? avgCare.toFixed(2) : "n/a"}.`,
    ],
    careSurvey: { n: care.length, avgComposite: avgCare },
    pulseAverages: pulse.pulseAverages,
  };

  const journalUsers = M.usersWithAnyOf(ev, ["journal_entry_created"], anonymized);
  const conclusions: string[] = [];
  if (avgCare != null && avgCare >= 3.5 && care.length > 0) {
    conclusions.push("Care navigation survey responses in this window skew toward better access / clarity on average.");
  }
  if (journalUsers.size > 0 && (pulse.pulseAverages?.nEvents ?? 0) > 0) {
    conclusions.push("Some users both journal and submit confidence / micro-measure pulses—use cohort IDs for stronger causal claims.");
  }
  if (avgCare != null && journalUsers.size / Math.max(users.size, 1) > 0.2) {
    conclusions.push("Journal use and care-survey completion overlap for a subset of users in this window.");
  }
  if (conclusions.length === 0) {
    conclusions.push("Widen the date range or confirm instrumentation if confidence and journal signals look thin.");
  }
  if (peer.extraKpis[0] && Number(peer.extraKpis[0].value) > 0) {
    conclusions.push(
      "Provider reviews in this window carry structured experience flags—useful for whether users feel heard and respected in care settings.",
    );
  }
  if (Number(peer.extraKpis[1]?.value ?? 0) > 0) {
    conclusions.push("Listing reports indicate users exercising judgment on directory accuracy and safety.");
  }

  const trend = mainTrendFromDaily(ev, "journal_entry_created");
  const evidence: EvidenceReport = {
    summaryParagraph: `Self-advocacy confidence is summarized using journal, visit-summary, micro-measure, confidence pulse, CareSurvey, and provider directory peer signals (reviews + listing reports) listed below. ${users.size} users generated at least one whitelisted analytics event in range; CareSurvey adds structured navigation confidence.`,
    totalUsers: users.size,
    dateRangeLabel: makeSummary("", params).dateRangeLabel,
    mainTrend: trend,
    takeaways: conclusions.slice(0, 3),
    eventsIncluded: rowsE,
    metricsKpis: [
      { key: "uniqueUsers", label: "Unique users (whitelisted events)", value: users.size },
      { key: "journalUsers", label: "Users w/ journal_entry_created", value: journalUsers.size },
      { key: "careSurveyN", label: "CareSurvey submissions", value: care.length },
      { key: "avgCareComposite", label: "Avg CareSurvey composite", value: avgCare != null ? avgCare.toFixed(2) : "n/a" },
      ...peer.extraKpis,
    ],
    outcomeSignals: outcome,
    conclusions,
    coverageNote: coverageNoteFromRows(rowsE, zeros),
  };

  const daily = M.dailyCounts(ev, ["journal_entry_created", "confidence_signal_submitted"]);
  const labs = [...daily.keys()].sort();
  const vals = labs.map((l) => daily.get(l) || 0);

  return {
    summary: makeSummary("Self-Advocacy Confidence Report", params),
    evidence,
    kpis: evidence.metricsKpis.map((k) => ({ key: k.key, label: k.label, value: k.value })),
    charts: [{ id: "saTrend", title: "Journal + pulse activity (daily)", kind: "line", labels: labs, series: [{ name: "Events", data: vals }] }],
    tables: [
      {
        title: "Relevant events included",
        columns: ["Event", "What it measures", "Status"],
        rows: rowsE.map((r) => [r.eventName, r.whatItMeasures, r.status]),
      },
    ],
    insights: conclusions,
    coverageFlags: [],
    rows: [{ uniqueUsers: users.size, careSurveys: care.length, avgCare }],
  };
}

export function buildCareNavigationReport(dataset: ReportDataset, params: ReportParams): ReportPayload {
  const type = "care_navigation_success" as const;
  const wl = whitelistSet(type);
  const ev = filterEvents(dataset.events, wl);
  const anonymized = params.anonymized;
  const users = M.uniqueUsers(ev, anonymized);
  const care = dataset.careSurveys;
  const out = dataset.careNavigationOutcomes;
  const avgCare = M.avgCareComposite(care);

  const rowsE = buildEventRows(WHITELIST[type], ["CareSurvey", "care_navigation_outcomes"]);
  const zeros = zeroInWhitelist(ev, WHITELIST[type]);

  const searches = M.countByEvent(ev, "provider_search_initiated");
  const profiles = M.countByEvent(ev, "provider_profile_viewed");
  const contacts = M.countByEvent(ev, "provider_contact_clicked");
  const posOut = out.filter((o) => o.outcome === "yes" || o.outcome === "partly").length;
  const posShare = out.length > 0 ? M.pct(M.safeRate(posOut, out.length)) : "n/a";

  const outcome: OutcomeSignalsBlock = {
    lines: [
      `CareSurvey: ${care.length} submissions; avg composite ${avgCare != null ? avgCare.toFixed(2) : "n/a"}.`,
      `care_navigation_outcomes documents: ${out.length} rows; positive/partly share ≈ ${posShare}.`,
    ],
    careSurvey: { n: care.length, avgComposite: avgCare },
    careNavigationOutcomes: { n: out.length, positiveShare: String(posShare) },
  };

  const contactRate = M.safeRate(contacts, searches);
  const viewRate = M.safeRate(profiles, searches);

  const conclusions: string[] = [];
  if (searches > 0 && profiles > contacts) {
    conclusions.push("Provider profile views were common relative to contact taps—users may browse more than they call or email.");
  }
  if (contactRate < viewRate && searches > 5) {
    conclusions.push("Contact actions trail profile views; friction may sit between discovery and outreach.");
  }
  if (avgCare != null && avgCare >= 3.5) {
    conclusions.push("CareSurvey composite scores suggest many users could access care at least partly when they tried.");
  }
  if (conclusions.length === 0) {
    conclusions.push("Increase the date range or verify provider search instrumentation if funnel counts look low.");
  }

  const dist = M.outcomeDistribution(care);
  const distRows = Object.entries(dist)
    .sort((a, b) => b[1] - a[1])
    .map(([k, v]) => [k, v] as (string | number)[]);

  const needRows = (() => {
    const needCounts: Record<string, number> = {};
    for (const s of care) {
      for (const n of s.selectedNeeds) needCounts[n] = (needCounts[n] || 0) + 1;
    }
    return Object.entries(needCounts)
      .sort((a, b) => b[1] - a[1])
      .map(([id, c]) => [careNeedCategoryLabel(id), c] as (string | number)[]);
  })();

  const evidence: EvidenceReport = {
    summaryParagraph: `Care navigation success is measured only from provider funnel events plus CareSurvey and structured care_navigation_outcomes rows. ${users.size} users contributed whitelisted analytics events; surveys capture access quality per need.`,
    totalUsers: users.size,
    dateRangeLabel: makeSummary("", params).dateRangeLabel,
    mainTrend: mainTrendFromDaily(ev, "provider_search_initiated"),
    takeaways: conclusions.slice(0, 3),
    eventsIncluded: rowsE,
    metricsKpis: [
      { key: "uniqueUsers", label: "Unique users", value: users.size },
      { key: "searches", label: "provider_search_initiated", value: searches },
      { key: "contactRate", label: "Contacts / searches", value: M.pct(contactRate) },
      { key: "profileViews", label: "provider_profile_viewed", value: profiles },
    ],
    outcomeSignals: outcome,
    conclusions,
    coverageNote: coverageNoteFromRows(rowsE, zeros),
  };

  return {
    summary: makeSummary("Care Navigation Success Report", params),
    evidence,
    kpis: evidence.metricsKpis.map((k) => ({ key: k.key, label: k.label, value: k.value })),
    charts: [
      {
        id: "navFunnel",
        title: "Provider funnel (whitelisted counts)",
        kind: "bar",
        labels: ["search", "profile", "contact", "selected"],
        series: [
          {
            name: "Events",
            data: [
              searches,
              profiles,
              contacts,
              M.countByEvent(ev, "provider_selected_success"),
            ],
          },
        ],
      },
    ],
    tables: [
      {
        title: "Relevant events included",
        columns: ["Event", "What it measures", "Status"],
        rows: rowsE.map((r) => [r.eventName, r.whatItMeasures, r.status]),
      },
      { title: "CareSurvey access outcomes", columns: ["Code", "Count"], rows: distRows },
      { title: "CareSurvey needs mentioned", columns: ["Need", "Count"], rows: needRows },
    ],
    insights: conclusions,
    coverageFlags: [],
    rows: [{ searches, profiles, contacts, careSurveys: care.length, outcomeDocs: out.length }],
  };
}

export function buildEngagementPathwayReport(dataset: ReportDataset, params: ReportParams): ReportPayload {
  const type = "engagement_pathway" as const;
  const wl = whitelistSet(type);
  const ev = filterEvents(dataset.events, wl);
  const anonymized = params.anonymized;
  const users = M.uniqueUsers(ev, anonymized);

  const rowsE = buildEventRows(WHITELIST[type], []);
  const zeros = zeroInWhitelist(ev, WHITELIST[type]);

  const sessionByCohort = { navigator: 0, self_directed: 0, unknown: 0 };
  const modBy: Record<"navigator" | "self_directed" | "unknown", Set<string>> = {
    navigator: new Set(),
    self_directed: new Set(),
    unknown: new Set(),
  };
  for (const e of ev) {
    if (e.eventName === "session_started") sessionByCohort[M.cohortOf(e)]++;
    if (e.eventName === "learning_module_completed") {
      const k = M.userKey(e, anonymized);
      if (k) modBy[M.cohortOf(e)].add(k);
    }
  }
  const navUsers = new Set<string>();
  const selfUsers = new Set<string>();
  for (const e of ev) {
    const k = M.userKey(e, anonymized);
    if (!k) continue;
    const c = M.cohortOf(e);
    if (c === "navigator") navUsers.add(k);
    if (c === "self_directed") selfUsers.add(k);
  }
  const navRate = M.safeRate(modBy.navigator.size, Math.max(navUsers.size, 1));
  const selfRate = M.safeRate(modBy.self_directed.size, Math.max(selfUsers.size, 1));

  const avgScreen = M.avgSecondsForEventNames(ev, ["screen_time_spent"]);
  const avgFeat = M.avgSecondsForEventNames(ev, ["feature_time_spent"]);

  const conclusions: string[] = [];
  if (navRate > selfRate && navUsers.size > 0 && selfUsers.size > 0) {
    conclusions.push("Navigator-tagged users show a higher share completing learning modules than self-directed users in this window.");
  } else if (selfRate > navRate && navUsers.size > 0 && selfUsers.size > 0) {
    conclusions.push("Self-directed users show a higher share completing learning modules than navigator-tagged users in this window.");
  }
  if ((M.countByEvent(ev, "flow_abandoned") ?? 0) > 0) {
    conclusions.push("Flow abandonment events are present—review partial instrumentation in Analytics Info before over-interpreting.");
  }
  conclusions.push("Many events still lack cohort metadata; treat unknown cohort as missing data, not a third user type.");
  if (conclusions.length < 3) {
    conclusions.push(`Average screen_time_spent duration where present: ${avgScreen != null ? `${avgScreen.toFixed(0)}s` : "n/a"}; feature_time_spent: ${avgFeat != null ? `${avgFeat.toFixed(0)}s` : "n/a"}.`);
  }

  const peer = providerPeerFeedbackFromEvents(ev);

  const evidence: EvidenceReport = {
    summaryParagraph: `Engagement compares the listed shell, learning, provider (including reviews and listing reports), community, journal, and birth-plan events. Cohort tags come from event metadata (navigator / self_directed). ${users.size} users generated at least one whitelisted event.`,
    totalUsers: users.size,
    dateRangeLabel: makeSummary("", params).dateRangeLabel,
    mainTrend: mainTrendFromDaily(ev, "session_started"),
    takeaways: conclusions.slice(0, 3),
    eventsIncluded: rowsE,
    metricsKpis: [
      { key: "uniqueUsers", label: "Unique users", value: users.size },
      { key: "sessions_nav", label: "session_started (navigator)", value: sessionByCohort.navigator },
      { key: "sessions_self", label: "session_started (self_directed)", value: sessionByCohort.self_directed },
      { key: "moduleRate_nav", label: "Module completion rate (navigator users)", value: M.pct(navRate) },
      { key: "moduleRate_self", label: "Module completion rate (self-directed users)", value: M.pct(selfRate) },
      { key: "avgScreenSec", label: "Avg screen_time_spent duration (s)", value: avgScreen != null ? avgScreen.toFixed(0) : "n/a" },
      { key: "avgFeatureSec", label: "Avg feature_time_spent duration (s)", value: avgFeat != null ? avgFeat.toFixed(0) : "n/a" },
      ...peer.extraKpis,
    ],
    outcomeSignals: {
      lines: [
        ...peer.lines,
        "Outcome surveys are not primary in this report; focus is behavioral engagement by cohort.",
      ],
    },
    conclusions,
    coverageNote: coverageNoteFromRows(rowsE, zeros),
  };

  const dwell = M.featureDwellSecondsByCohort(ev);
  const tableRows: (string | number)[][] = [];
  for (const cohort of ["navigator", "self_directed", "unknown"] as const) {
    const rec = dwell.get(cohort) || {};
    for (const [feat, sec] of Object.entries(rec).sort((a, b) => b[1] - a[1]).slice(0, 3)) {
      tableRows.push([cohort, feat, Math.round(sec / 60)]);
    }
  }

  return {
    summary: makeSummary("Engagement Pathway Report", params),
    evidence,
    kpis: evidence.metricsKpis.map((k) => ({ key: k.key, label: k.label, value: k.value })),
    charts: [
      {
        id: "cohortSessions",
        title: "session_started by cohort tag",
        kind: "bar",
        labels: ["navigator", "self_directed", "unknown"],
        series: [{ name: "Count", data: [sessionByCohort.navigator, sessionByCohort.self_directed, sessionByCohort.unknown] }],
      },
    ],
    tables: [
      {
        title: "Relevant events included",
        columns: ["Event", "What it measures", "Status"],
        rows: rowsE.map((r) => [r.eventName, r.whatItMeasures, r.status]),
      },
      { title: "Feature dwell (min) sample by cohort", columns: ["Cohort", "Feature", "Min"], rows: tableRows },
    ],
    insights: conclusions,
    coverageFlags: [],
    rows: [{ uniqueUsers: users.size, navModuleRate: navRate, selfModuleRate: selfRate }],
  };
}

export function buildCarePreparationReport(dataset: ReportDataset, params: ReportParams): ReportPayload {
  const type = "care_preparation" as const;
  const wl = whitelistSet(type);
  const ev = filterEvents(dataset.events, wl);
  const anonymized = params.anonymized;
  const users = M.uniqueUsers(ev, anonymized);
  const modFb = dataset.moduleFeedback;

  const rowsE = buildEventRows(WHITELIST[type], ["ModuleFeedback"]);
  const zeros = zeroInWhitelist(ev, WHITELIST[type]);

  const birthU = M.usersWithAnyOf(ev, ["birth_plan_completed"], anonymized);
  const learnU = M.usersWithAnyOf(ev, ["learning_module_completed"], anonymized);
  const und = M.avgModuleUnderstanding(modFb);

  const conclusions: string[] = [];
  if (birthU.size > 0 && learnU.size > 0) {
    conclusions.push("Users completing birth plans and learning modules appear in overlapping subsets—good preparation signal.");
  }
  if (und != null && und >= 4) {
    conclusions.push("ModuleFeedback understanding averages are strong, suggesting materials feel clear before milestones.");
  }
  conclusions.push("Trimester tagging on events is only as complete as mobile metadata; sparse tags limit timing analysis.");

  const daily = M.dailyCounts(ev, ["birth_plan_completed"]);
  const labs = [...daily.keys()].sort();
  const vals = labs.map((l) => daily.get(l) || 0);

  const evidence: EvidenceReport = {
    summaryParagraph: `Preparation is assessed only from birth-plan, learning, visit-summary, journal, and ModuleFeedback sources below. ${users.size} users had ≥1 whitelisted event.`,
    totalUsers: users.size,
    dateRangeLabel: makeSummary("", params).dateRangeLabel,
    mainTrend: mainTrendFromDaily(ev, "birth_plan_completed"),
    takeaways: conclusions.slice(0, 3),
    eventsIncluded: rowsE,
    metricsKpis: [
      { key: "uniqueUsers", label: "Unique users", value: users.size },
      { key: "birthPlanUsers", label: "Users w/ birth_plan_completed", value: birthU.size },
      { key: "moduleUsers", label: "Users w/ learning_module_completed", value: learnU.size },
      { key: "avgModuleUnderstanding", label: "Avg ModuleFeedback understanding", value: und != null ? und.toFixed(2) : "n/a" },
    ],
    outcomeSignals: {
      lines: [`ModuleFeedback submissions: ${modFb.length}; avg understanding ${und != null ? und.toFixed(2) : "n/a"}.`],
      moduleFeedback: { n: modFb.length, avgUnderstanding: und },
    },
    conclusions,
    coverageNote: coverageNoteFromRows(rowsE, zeros),
  };

  return {
    summary: makeSummary("Care Preparation Report", params),
    evidence,
    kpis: evidence.metricsKpis.map((k) => ({ key: k.key, label: k.label, value: k.value })),
    charts: [{ id: "bp", title: "birth_plan_completed per day", kind: "line", labels: labs, series: [{ name: "Count", data: vals }] }],
    tables: [
      {
        title: "Relevant events included",
        columns: ["Event", "What it measures", "Status"],
        rows: rowsE.map((r) => [r.eventName, r.whatItMeasures, r.status]),
      },
    ],
    insights: conclusions,
    coverageFlags: [],
    rows: [{ uniqueUsers: users.size, moduleFeedbackN: modFb.length }],
  };
}

export function buildCommunitySupportReport(dataset: ReportDataset, params: ReportParams): ReportPayload {
  const type = "community_support" as const;
  const wl = whitelistSet(type);
  const ev = filterEvents(dataset.events, wl);
  const anonymized = params.anonymized;
  const users = M.uniqueUsers(ev, anonymized);
  const care = dataset.careSurveys;
  const avgCare = M.avgCareComposite(care);

  const rowsE = buildEventRows(WHITELIST[type], ["CareSurvey"]);
  const zeros = zeroInWhitelist(ev, WHITELIST[type]);

  const postU = M.usersWithAnyOf(ev, ["community_post_created"], anonymized);
  const journalU = M.usersWithAnyOf(ev, ["journal_entry_created"], anonymized);
  const overlap = new Set([...postU].filter((u) => journalU.has(u)));

  const helpful = M.countByEvent(ev, "helpfulness_survey_submitted");
  const peer = providerPeerFeedbackFromEvents(ev);

  const conclusions: string[] = [];
  if (postU.size > 0 && journalU.size > 0 && overlap.size > 0) {
    conclusions.push("Some users both posted in community and journaled—peer engagement and reflection co-occur for a subset.");
  }
  if (avgCare != null && postU.size > 0 && avgCare >= 3.5) {
    conclusions.push("CareSurvey clarity scores are relatively high among users who also engage with community in this window.");
  }
  if (helpful === 0) {
    conclusions.push("No helpfulness_survey_submitted events in range; that stream may be rare or users skipped it.");
  }
  if (conclusions.length < 2) {
    conclusions.push("Reply and like counts help gauge reciprocity; widen dates if interaction counts look small.");
  }
  if (Number(peer.extraKpis[0]?.value ?? 0) > 0) {
    conclusions.push("Provider reviews tie community-adjacent trust signals to real care experiences shared in-app.");
  }

  const evidence: EvidenceReport = {
    summaryParagraph: `Community support is measured from community, journal, helpfulness, CareSurvey, and provider peer-feedback events (reviews + listing reports) listed. ${users.size} users had ≥1 whitelisted event.`,
    totalUsers: users.size,
    dateRangeLabel: makeSummary("", params).dateRangeLabel,
    mainTrend: mainTrendFromDaily(ev, "community_post_created"),
    takeaways: conclusions.slice(0, 3),
    eventsIncluded: rowsE,
    metricsKpis: [
      { key: "uniqueUsers", label: "Unique users", value: users.size },
      { key: "postUsers", label: "Users creating posts", value: postU.size },
      { key: "replyEvents", label: "community_post_replied", value: M.countByEvent(ev, "community_post_replied") },
      { key: "careSurveyN", label: "CareSurvey submissions", value: care.length },
      { key: "avgCare", label: "Avg CareSurvey composite", value: avgCare != null ? avgCare.toFixed(2) : "n/a" },
      { key: "helpfulness", label: "helpfulness_survey_submitted", value: helpful },
      ...peer.extraKpis,
    ],
    outcomeSignals: {
      lines: [
        ...peer.lines,
        `CareSurvey (clarity / access proxy): ${care.length} docs, avg composite ${avgCare != null ? avgCare.toFixed(2) : "n/a"}.`,
        `Users both posting and journaling: ${overlap.size} (overlap among users with either action).`,
      ],
      careSurvey: { n: care.length, avgComposite: avgCare },
    },
    conclusions,
    coverageNote: coverageNoteFromRows(rowsE, zeros),
  };

  const daily = M.dailyCounts(ev, ["community_post_created", "community_post_replied"]);
  const labs = [...daily.keys()].sort();
  const vals = labs.map((l) => daily.get(l) || 0);

  return {
    summary: makeSummary("Community Support Report", params),
    evidence,
    kpis: evidence.metricsKpis.map((k) => ({ key: k.key, label: k.label, value: k.value })),
    charts: [{ id: "com", title: "Community events per day", kind: "line", labels: labs, series: [{ name: "Events", data: vals }] }],
    tables: [
      {
        title: "Relevant events included",
        columns: ["Event", "What it measures", "Status"],
        rows: rowsE.map((r) => [r.eventName, r.whatItMeasures, r.status]),
      },
    ],
    insights: conclusions,
    coverageFlags: [],
    rows: [{ uniqueUsers: users.size, overlapPostJournal: overlap.size }],
  };
}
