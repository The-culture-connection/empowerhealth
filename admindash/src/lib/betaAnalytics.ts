/**
 * Beta Analytics data layer.
 *
 * Loads raw analytics events, sessions, surveys and user profiles for a date range, then joins
 * surveys to the analytics events around them so each survey can be read in context.
 * Everything is read with the admin's client SDK; nothing is written.
 */

import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  Timestamp,
  where,
  type DocumentData,
  type Query,
  type QueryDocumentSnapshot,
  type QuerySnapshot,
} from "firebase/firestore";
import { firestore } from "../firebase/firebase";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type ScalarValue = string | number | boolean | null;

export interface BetaEvent {
  id: string;
  eventName: string;
  feature: string;
  screen: string;
  /** uid as written, or resolved from anonUserId when the doc only carries the anon id. */
  userId: string | null;
  userIdResolved: boolean;
  anonUserId: string | null;
  time: Date | null;
  clientTimestamp: string;
  platform: string;
  appVersion: string;
  environment: string;
  sessionId: string;
  source: string;
  dateKey: string;
  cohortType: string;
  gestationalWeek: number | null;
  trimester: string;
  durationMs: number | null;
  metadata: Record<string, unknown>;
}

export interface BetaSession {
  id: string;
  userId: string | null;
  anonUserId: string | null;
  startedAt: Date | null;
  endedAt: Date | null;
  durationSeconds: number | null;
  entryPoint: string;
  platform: string;
}

export type SurveyType =
  | "qualitative_survey"
  | "module_feedback"
  | "care_survey"
  | "micro_measure"
  | "helpfulness_survey"
  | "milestone_checkin"
  | "care_navigation_outcome";

export const SURVEY_TYPE_LABELS: Record<SurveyType, string> = {
  qualitative_survey: "Qualitative survey",
  module_feedback: "Module feedback",
  care_survey: "Care survey",
  micro_measure: "Micro measure",
  helpfulness_survey: "Helpfulness survey",
  milestone_checkin: "Milestone check-in",
  care_navigation_outcome: "Care navigation outcome",
};

export interface EventRef {
  id: string;
  name: string;
  feature: string;
  screen: string;
  time: Date | null;
  sessionId: string;
}

export interface SurveyContext {
  /** "exact" = survey doc carried a sessionId; "inferred" = taken from the last event within 30 min. */
  sessionMatch: "exact" | "inferred" | "none";
  matchedSessionId: string;
  sessionEventCount: number;
  sessionFeatures: string[];
  prevEvent: EventRef | null;
  nextEvent: EventRef | null;
  eventsPrev30Min: number;
  userEventsInPeriod: number;
}

export interface BetaSurvey {
  surveyType: SurveyType;
  docPath: string;
  userId: string | null;
  anonUserId: string | null;
  time: Date | null;
  feature: string;
  sourceId: string;
  sessionId: string;
  answers: Record<string, ScalarValue>;
  context: SurveyContext | null;
}

export interface BetaUserProfile {
  uid: string;
  exists: boolean;
  email: string;
  name: string;
  cohortType: string;
  isResearchParticipant: boolean | null;
  studyId: string;
  anonUserId: string;
  createdAt: Date | null;
  lastActiveAt: Date | null;
}

export interface BetaUserSummary extends BetaUserProfile {
  firstSeen: Date | null;
  lastSeen: Date | null;
  eventCount: number;
  activeDays: number;
  sessionCount: number;
  totalSessionMinutes: number;
  daysWith10SessionMinutes: number;
  surveysTotal: number;
  surveysByType: Partial<Record<SurveyType, number>>;
  betaChecklistItemsCompleted: number;
  betaChecklistItemIds: string[];
  betaDailyGoalsMet: number;
}

export interface DateRange {
  /** Local midnight of the first day. */
  start: Date;
  /** Local midnight of the day after the last (inclusive) day. */
  endExclusive: Date;
  startKey: string;
  endKey: string;
}

export interface LoadedBetaData {
  range: DateRange;
  /** All events in range, cloud-function duplicates included (filter with `source`). */
  events: BetaEvent[];
  eventsCapped: boolean;
  sessions: BetaSession[];
  surveys: BetaSurvey[];
  users: Map<string, BetaUserProfile>;
  warnings: string[];
}

export type ProgressFn = (message: string) => void;

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

export const EVENT_PAGE_SIZE = 1000;
export const EVENT_HARD_CAP = 50_000;
const THIRTY_MIN_MS = 30 * 60 * 1000;

export const QUALITATIVE_FEATURE_IDS = [
  "provider-search",
  "authentication-onboarding",
  "user-feedback",
  "appointment-summarizing",
  "journal",
  "learning-modules",
  "birth-plan-generator",
  "community",
  "profile-editing",
  "app",
] as const;

export const BETA_CHECKLIST_EVENT = "beta_checklist_item_completed";
export const BETA_GOAL_EVENT = "beta_daily_goal_met";

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------

export function tsToDate(v: unknown): Date | null {
  if (v == null) return null;
  if (v instanceof Timestamp) return v.toDate();
  if (v instanceof Date) return Number.isNaN(v.getTime()) ? null : v;
  if (typeof v === "object" && "toDate" in (v as object)) {
    try {
      const d = (v as { toDate: () => Date }).toDate();
      return Number.isNaN(d.getTime()) ? null : d;
    } catch {
      return null;
    }
  }
  if (typeof v === "string" || typeof v === "number") {
    const d = new Date(v);
    if (!Number.isNaN(d.getTime())) return d;
  }
  return null;
}

function str(v: unknown): string {
  if (v == null) return "";
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return String(v);
  return "";
}

function strOrNull(v: unknown): string | null {
  return typeof v === "string" && v.length > 0 ? v : null;
}

function numOrNull(v: unknown): number | null {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "" && Number.isFinite(Number(v))) return Number(v);
  return null;
}

export function iso(d: Date | null | undefined): string {
  return d && !Number.isNaN(d.getTime()) ? d.toISOString() : "";
}

/** YYYY-MM-DD in the viewer's local time zone. */
export function localDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/** Parses a YYYY-MM-DD input value as local midnight. */
export function parseDateInput(value: string): Date | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!m) return null;
  const d = new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
  return Number.isNaN(d.getTime()) ? null : d;
}

export function buildRange(startKey: string, endKey: string): DateRange | null {
  const start = parseDateInput(startKey);
  const end = parseDateInput(endKey);
  if (!start || !end || end < start) return null;
  const endExclusive = new Date(end);
  endExclusive.setDate(endExclusive.getDate() + 1);
  return { start, endExclusive, startKey, endKey };
}

export function defaultRangeKeys(): { startKey: string; endKey: string } {
  const end = new Date();
  const start = new Date(end);
  start.setDate(start.getDate() - 6);
  return { startKey: localDateKey(start), endKey: localDateKey(end) };
}

function inRange(d: Date | null, range: DateRange): boolean {
  if (!d) return false;
  const t = d.getTime();
  return t >= range.start.getTime() && t < range.endExclusive.getTime();
}

/** Turns any Firestore value into a CSV/JSON-friendly scalar. */
function toScalar(v: unknown): ScalarValue {
  if (v == null) return null;
  if (typeof v === "string" || typeof v === "number" || typeof v === "boolean") return v;
  const d = tsToDate(v);
  if (d && typeof v === "object") return d.toISOString();
  if (Array.isArray(v)) return v.map((x) => (typeof x === "object" ? JSON.stringify(jsonSafe(x)) : String(x))).join("; ");
  try {
    return JSON.stringify(jsonSafe(v));
  } catch {
    return String(v);
  }
}

/** Flattens a nested map into dotted keys; arrays are joined. */
function flattenInto(out: Record<string, ScalarValue>, prefix: string, v: unknown, depth = 0): void {
  if (
    v != null &&
    typeof v === "object" &&
    !Array.isArray(v) &&
    !(v instanceof Timestamp) &&
    !("toDate" in (v as object)) &&
    depth < 3
  ) {
    const entries = Object.entries(v as Record<string, unknown>);
    if (entries.length === 0) {
      out[prefix] = null;
      return;
    }
    for (const [k, child] of entries) flattenInto(out, prefix ? `${prefix}.${k}` : k, child, depth + 1);
    return;
  }
  out[prefix] = toScalar(v);
}

/** Converts Firestore values (Timestamps etc.) so JSON.stringify gives ISO strings. */
export function jsonSafe(v: unknown): unknown {
  if (v == null) return v;
  if (v instanceof Date) return iso(v);
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (Array.isArray(v)) return v.map(jsonSafe);
  if (typeof v === "object") {
    if ("toDate" in (v as object)) {
      const d = tsToDate(v);
      if (d) return d.toISOString();
    }
    const out: Record<string, unknown> = {};
    for (const [k, child] of Object.entries(v as Record<string, unknown>)) out[k] = jsonSafe(child);
    return out;
  }
  return v;
}

function errMsg(e: unknown): string {
  if (e && typeof e === "object") {
    const o = e as { code?: string; message?: string };
    return `${o.code ? `${o.code}: ` : ""}${o.message ?? String(e)}`;
  }
  return String(e);
}

// ---------------------------------------------------------------------------
// Loaders
// ---------------------------------------------------------------------------

function parseEvent(d: QueryDocumentSnapshot<DocumentData>): BetaEvent {
  const data = d.data();
  const metadata =
    data.metadata && typeof data.metadata === "object" && !Array.isArray(data.metadata)
      ? (data.metadata as Record<string, unknown>)
      : {};
  // Mobile docs write `userId`; older docs used `uid`.
  const userId = strOrNull(data.userId) ?? strOrNull(data.uid);
  return {
    id: d.id,
    eventName: str(data.eventName) || "unknown",
    feature: str(data.feature),
    screen: str(data.screen) || str(metadata.screen_name),
    userId,
    userIdResolved: false,
    anonUserId: strOrNull(data.anonUserId),
    time: tsToDate(data.timestamp) ?? tsToDate(data.clientTimestamp),
    clientTimestamp: str(data.clientTimestamp),
    platform: str(data.platform),
    appVersion: str(data.appVersion),
    environment: str(data.environment),
    sessionId: str(data.sessionId),
    source: str(data.source),
    dateKey: str(data.dateKey),
    cohortType: str(data.cohortType),
    gestationalWeek: numOrNull(data.gestationalWeek),
    trimester: str(data.trimester),
    durationMs: numOrNull(data.durationMs),
    metadata,
  };
}

async function loadEvents(
  range: DateRange,
  onProgress: ProgressFn,
): Promise<{ events: BetaEvent[]; capped: boolean }> {
  const ref = collection(firestore, "analytics_events");
  const base = [
    where("timestamp", ">=", Timestamp.fromDate(range.start)),
    where("timestamp", "<", Timestamp.fromDate(range.endExclusive)),
    orderBy("timestamp"),
  ];
  const events: BetaEvent[] = [];
  let last: QueryDocumentSnapshot<DocumentData> | null = null;
  let capped = false;
  for (;;) {
    const q: Query<DocumentData> = last
      ? query(ref, ...base, startAfter(last), limit(EVENT_PAGE_SIZE))
      : query(ref, ...base, limit(EVENT_PAGE_SIZE));
    const snap: QuerySnapshot<DocumentData> = await getDocs(q);
    for (const d of snap.docs) events.push(parseEvent(d));
    onProgress(`Loading events... ${events.length.toLocaleString()} fetched`);
    if (snap.docs.length < EVENT_PAGE_SIZE) break;
    if (events.length >= EVENT_HARD_CAP) {
      capped = true;
      break;
    }
    last = snap.docs[snap.docs.length - 1];
  }
  return { events, capped };
}

async function loadSessions(range: DateRange): Promise<BetaSession[]> {
  const q = query(
    collection(firestore, "user_sessions"),
    where("startedAt", ">=", Timestamp.fromDate(range.start)),
    where("startedAt", "<", Timestamp.fromDate(range.endExclusive)),
  );
  const snap = await getDocs(q);
  return snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      userId: strOrNull(data.userId),
      anonUserId: strOrNull(data.anonUserId),
      startedAt: tsToDate(data.startedAt),
      endedAt: tsToDate(data.endedAt),
      durationSeconds: numOrNull(data.durationSeconds),
      entryPoint: str(data.entryPoint),
      platform: str(data.platform),
    };
  });
}

/** Keys that describe the survey rather than being an answer. */
const SURVEY_META_KEYS = new Set([
  "userId",
  "uid",
  "anonUserId",
  "timestamp",
  "createdAt",
  "updatedAt",
  "completedAt",
  "submittedAt",
  "feature",
  "sourceId",
  "sessionId",
  "questions",
]);

function answersFromDoc(data: Record<string, unknown>): Record<string, ScalarValue> {
  const out: Record<string, ScalarValue> = {};
  for (const [k, v] of Object.entries(data)) {
    if (SURVEY_META_KEYS.has(k)) continue;
    flattenInto(out, k, v);
  }
  return out;
}

function qualitativeAnswers(data: Record<string, unknown>): Record<string, ScalarValue> {
  const out: Record<string, ScalarValue> = {};
  const qs = Array.isArray(data.questions) ? (data.questions as unknown[]) : [];
  qs.forEach((raw, i) => {
    const q = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
    const question = str(q.question).trim() || `question ${i + 1}`;
    const label = str(q.answerLabel);
    const answer = toScalar(q.answer);
    const key = `q${i + 1}: ${question}`;
    out[key] = label && label !== String(answer ?? "") ? `${answer ?? ""} (${label})` : answer;
  });
  // Everything else on the doc (feedbackType, cohortType, ...) is kept too.
  return { ...out, ...answersFromDoc(data) };
}

interface SurveySpec {
  type: SurveyType;
  collectionPath: string[];
  timeField: string;
  defaultFeature?: string;
}

function surveySpecs(): SurveySpec[] {
  const qualitative: SurveySpec[] = QUALITATIVE_FEATURE_IDS.map((f) => ({
    type: "qualitative_survey",
    collectionPath: ["technology_features", f, "qualitative_surveys"],
    timeField: "timestamp",
    defaultFeature: f,
  }));
  return [
    ...qualitative,
    { type: "module_feedback", collectionPath: ["ModuleFeedback"], timeField: "createdAt", defaultFeature: "learning-modules" },
    { type: "care_survey", collectionPath: ["CareSurvey"], timeField: "createdAt", defaultFeature: "user-feedback" },
    { type: "micro_measure", collectionPath: ["micro_measures"], timeField: "timestamp" },
    { type: "helpfulness_survey", collectionPath: ["helpfulness_surveys"], timeField: "timestamp" },
    { type: "milestone_checkin", collectionPath: ["milestone_checkins"], timeField: "timestamp" },
    { type: "care_navigation_outcome", collectionPath: ["care_navigation_outcomes"], timeField: "timestamp" },
  ];
}

function surveyTime(spec: SurveySpec, data: Record<string, unknown>): Date | null {
  if (spec.type === "care_survey") {
    return tsToDate(data.completedAt) ?? tsToDate(data.createdAt) ?? tsToDate(data.timestamp);
  }
  return tsToDate(data[spec.timeField]) ?? tsToDate(data.createdAt) ?? tsToDate(data.timestamp);
}

function parseSurvey(spec: SurveySpec, path: string, data: Record<string, unknown>): BetaSurvey {
  let sourceId = str(data.sourceId);
  if (!sourceId && spec.type === "module_feedback") sourceId = str(data.taskId) || str(data.moduleId);
  let feature = str(data.feature) || spec.defaultFeature || "";
  if (!feature && spec.type === "care_navigation_outcome") feature = str(data.sourceFeature);
  return {
    surveyType: spec.type,
    docPath: path,
    userId: strOrNull(data.userId) ?? strOrNull(data.uid),
    anonUserId: strOrNull(data.anonUserId),
    time: surveyTime(spec, data),
    feature,
    sourceId,
    sessionId: str(data.sessionId),
    answers: spec.type === "qualitative_survey" ? qualitativeAnswers(data) : answersFromDoc(data),
    context: null,
  };
}

async function loadSurveys(range: DateRange, warnings: string[]): Promise<BetaSurvey[]> {
  const startTs = Timestamp.fromDate(range.start);
  const endTs = Timestamp.fromDate(range.endExclusive);
  const results = await Promise.all(
    surveySpecs().map(async (spec) => {
      const path = spec.collectionPath.join("/");
      const ref = collection(firestore, spec.collectionPath[0], ...spec.collectionPath.slice(1));
      try {
        const snap = await getDocs(
          query(ref, where(spec.timeField, ">=", startTs), where(spec.timeField, "<", endTs)),
        );
        return snap.docs.map((d) => parseSurvey(spec, `${path}/${d.id}`, d.data() as Record<string, unknown>));
      } catch (e) {
        warnings.push(`Could not read ${path}: ${errMsg(e)}`);
        return [] as BetaSurvey[];
      }
    }),
  );
  return results.flat().filter((s) => s.time == null || inRange(s.time, range));
}

async function loadUserProfiles(uids: string[], onProgress: ProgressFn): Promise<Map<string, BetaUserProfile>> {
  const out = new Map<string, BetaUserProfile>();
  const CHUNK = 25;
  for (let i = 0; i < uids.length; i += CHUNK) {
    const chunk = uids.slice(i, i + CHUNK);
    const snaps = await Promise.all(
      chunk.map(async (uid) => {
        try {
          return { uid, snap: await getDoc(doc(firestore, "users", uid)) };
        } catch {
          return { uid, snap: null };
        }
      }),
    );
    for (const { uid, snap } of snaps) {
      const data = (snap && snap.exists() ? snap.data() : {}) as Record<string, unknown>;
      out.set(uid, {
        uid,
        exists: Boolean(snap && snap.exists()),
        email: str(data.email),
        name: str(data.username) || str(data.name) || str(data.displayName),
        cohortType: str(data.cohortType),
        isResearchParticipant: typeof data.isResearchParticipant === "boolean" ? data.isResearchParticipant : null,
        studyId: str(data.studyId),
        anonUserId: str(data.anonUserId),
        createdAt: tsToDate(data.createdAt),
        lastActiveAt: tsToDate(data.lastActiveAt),
      });
    }
    onProgress(`Loading user profiles... ${Math.min(i + CHUNK, uids.length)}/${uids.length}`);
  }
  return out;
}

/** Loads everything for the range. Survey/session failures become warnings instead of aborting. */
export async function loadBetaData(range: DateRange, onProgress: ProgressFn): Promise<LoadedBetaData> {
  const warnings: string[] = [];
  onProgress("Loading events...");
  const { events, capped } = await loadEvents(range, onProgress);

  onProgress("Loading sessions and surveys...");
  let sessions: BetaSession[] = [];
  try {
    sessions = await loadSessions(range);
  } catch (e) {
    warnings.push(`Could not read user_sessions: ${errMsg(e)}`);
  }
  const surveys = await loadSurveys(range, warnings);

  // Cloud-function docs carry only anonUserId; map anon ids back to uids where any other doc links them.
  const anonToUid = new Map<string, string>();
  const link = (anon: string | null, uid: string | null) => {
    if (anon && uid && !anonToUid.has(anon)) anonToUid.set(anon, uid);
  };
  for (const e of events) link(e.anonUserId, e.userId);
  for (const s of sessions) link(s.anonUserId, s.userId);
  for (const s of surveys) link(s.anonUserId, s.userId);
  for (const e of events) {
    if (!e.userId && e.anonUserId && anonToUid.has(e.anonUserId)) {
      e.userId = anonToUid.get(e.anonUserId)!;
      e.userIdResolved = true;
    }
  }
  for (const s of sessions) if (!s.userId && s.anonUserId) s.userId = anonToUid.get(s.anonUserId) ?? null;
  for (const s of surveys) if (!s.userId && s.anonUserId) s.userId = anonToUid.get(s.anonUserId) ?? null;

  const uids = new Set<string>();
  for (const e of events) if (e.userId) uids.add(e.userId);
  for (const s of sessions) if (s.userId) uids.add(s.userId);
  for (const s of surveys) if (s.userId) uids.add(s.userId);
  const users = await loadUserProfiles(Array.from(uids).sort(), onProgress);

  return { range, events, eventsCapped: capped, sessions, surveys, users, warnings };
}

// ---------------------------------------------------------------------------
// Join layer
// ---------------------------------------------------------------------------

function timeOf(e: { time: Date | null }): number {
  return e.time ? e.time.getTime() : Number.NaN;
}

/** Index of the first element with time >= t (events sorted ascending, untimed events excluded). */
function lowerBound(sorted: BetaEvent[], t: number): number {
  let lo = 0;
  let hi = sorted.length;
  while (lo < hi) {
    const mid = (lo + hi) >>> 1;
    if (timeOf(sorted[mid]) < t) lo = mid + 1;
    else hi = mid;
  }
  return lo;
}

function eventRef(e: BetaEvent | undefined): EventRef | null {
  if (!e) return null;
  return { id: e.id, name: e.eventName, feature: e.feature, screen: e.screen, time: e.time, sessionId: e.sessionId };
}

export function groupEventsByUser(events: BetaEvent[]): Map<string, BetaEvent[]> {
  const byUser = new Map<string, BetaEvent[]>();
  for (const e of events) {
    if (!e.userId || !e.time) continue;
    let list = byUser.get(e.userId);
    if (!list) byUser.set(e.userId, (list = []));
    list.push(e);
  }
  for (const list of byUser.values()) list.sort((a, b) => timeOf(a) - timeOf(b));
  return byUser;
}

/**
 * Attaches analytics context to each survey. `events` should already exclude the
 * cloud-function duplicates when they are not wanted, so counts are not doubled.
 */
export function attachSurveyContext(surveys: BetaSurvey[], events: BetaEvent[]): BetaSurvey[] {
  const byUser = groupEventsByUser(events);
  const bySession = new Map<string, BetaEvent[]>();
  for (const e of events) {
    if (!e.sessionId) continue;
    let list = bySession.get(e.sessionId);
    if (!list) bySession.set(e.sessionId, (list = []));
    list.push(e);
  }

  return surveys.map((s) => {
    const userEvents = (s.userId && byUser.get(s.userId)) || [];
    const t = s.time ? s.time.getTime() : Number.NaN;
    let prev: BetaEvent | undefined;
    let next: BetaEvent | undefined;
    let prev30 = 0;
    if (!Number.isNaN(t) && userEvents.length > 0) {
      // Events logged at the same instant as the survey (e.g. "survey_submitted") count as "before".
      const idx = lowerBound(userEvents, t + 1);
      prev = userEvents[idx - 1];
      next = userEvents[idx];
      prev30 = idx - lowerBound(userEvents, t - THIRTY_MIN_MS);
    }

    let sessionMatch: SurveyContext["sessionMatch"] = "none";
    let matchedSessionId = "";
    if (s.sessionId) {
      sessionMatch = "exact";
      matchedSessionId = s.sessionId;
    } else if (prev && prev.sessionId && !Number.isNaN(t) && t - timeOf(prev) <= THIRTY_MIN_MS) {
      sessionMatch = "inferred";
      matchedSessionId = prev.sessionId;
    }
    const sessionEvents = matchedSessionId ? bySession.get(matchedSessionId) ?? [] : [];
    const sessionFeatures = Array.from(new Set(sessionEvents.map((e) => e.feature).filter(Boolean))).sort();

    return {
      ...s,
      context: {
        sessionMatch,
        matchedSessionId,
        sessionEventCount: sessionEvents.length,
        sessionFeatures,
        prevEvent: eventRef(prev),
        nextEvent: eventRef(next),
        eventsPrev30Min: prev30,
        userEventsInPeriod: userEvents.length,
      },
    };
  });
}

export function buildUserSummaries(
  users: Map<string, BetaUserProfile>,
  events: BetaEvent[],
  sessions: BetaSession[],
  surveys: BetaSurvey[],
): BetaUserSummary[] {
  const summaries = new Map<string, BetaUserSummary>();
  const days = new Map<string, Set<string>>();
  const sessionMinutesByDay = new Map<string, Map<string, number>>();
  const checklist = new Map<string, Set<string>>();
  const goals = new Map<string, Set<string>>();

  const get = (uid: string): BetaUserSummary => {
    let s = summaries.get(uid);
    if (!s) {
      const p = users.get(uid);
      s = {
        uid,
        exists: p?.exists ?? false,
        email: p?.email ?? "",
        name: p?.name ?? "",
        cohortType: p?.cohortType ?? "",
        isResearchParticipant: p?.isResearchParticipant ?? null,
        studyId: p?.studyId ?? "",
        anonUserId: p?.anonUserId ?? "",
        createdAt: p?.createdAt ?? null,
        lastActiveAt: p?.lastActiveAt ?? null,
        firstSeen: null,
        lastSeen: null,
        eventCount: 0,
        activeDays: 0,
        sessionCount: 0,
        totalSessionMinutes: 0,
        daysWith10SessionMinutes: 0,
        surveysTotal: 0,
        surveysByType: {},
        betaChecklistItemsCompleted: 0,
        betaChecklistItemIds: [],
        betaDailyGoalsMet: 0,
      };
      summaries.set(uid, s);
    }
    return s;
  };
  const seen = (s: BetaUserSummary, d: Date | null) => {
    if (!d) return;
    if (!s.firstSeen || d < s.firstSeen) s.firstSeen = d;
    if (!s.lastSeen || d > s.lastSeen) s.lastSeen = d;
  };
  const addTo = (m: Map<string, Set<string>>, uid: string, v: string) => {
    let set = m.get(uid);
    if (!set) m.set(uid, (set = new Set<string>()));
    set.add(v);
  };

  for (const e of events) {
    if (!e.userId) continue;
    const s = get(e.userId);
    s.eventCount += 1;
    seen(s, e.time);
    if (e.time) addTo(days, e.userId, localDateKey(e.time));
    if (e.eventName === BETA_CHECKLIST_EVENT) {
      const id = str(e.metadata.item_id) || str(e.metadata.item_title);
      if (id) addTo(checklist, e.userId, id);
    } else if (e.eventName === BETA_GOAL_EVENT) {
      // Dedupe on the goal's own date so a retried log is not counted twice.
      const key = str(e.metadata.date) || (e.time ? localDateKey(e.time) : e.id);
      addTo(goals, e.userId, key);
    }
  }

  for (const se of sessions) {
    if (!se.userId) continue;
    const s = get(se.userId);
    s.sessionCount += 1;
    seen(s, se.startedAt);
    seen(s, se.endedAt);
    const minutes = (se.durationSeconds ?? 0) / 60;
    s.totalSessionMinutes += minutes;
    if (se.startedAt) {
      let m = sessionMinutesByDay.get(se.userId);
      if (!m) sessionMinutesByDay.set(se.userId, (m = new Map()));
      const k = localDateKey(se.startedAt);
      m.set(k, (m.get(k) ?? 0) + minutes);
    }
  }

  for (const sv of surveys) {
    if (!sv.userId) continue;
    const s = get(sv.userId);
    s.surveysTotal += 1;
    s.surveysByType[sv.surveyType] = (s.surveysByType[sv.surveyType] ?? 0) + 1;
    seen(s, sv.time);
  }

  for (const s of summaries.values()) {
    s.activeDays = days.get(s.uid)?.size ?? 0;
    const perDay = sessionMinutesByDay.get(s.uid);
    s.daysWith10SessionMinutes = perDay ? Array.from(perDay.values()).filter((m) => m >= 10).length : 0;
    const items = checklist.get(s.uid);
    s.betaChecklistItemIds = items ? Array.from(items).sort() : [];
    s.betaChecklistItemsCompleted = s.betaChecklistItemIds.length;
    s.betaDailyGoalsMet = goals.get(s.uid)?.size ?? 0;
    s.totalSessionMinutes = Math.round(s.totalSessionMinutes * 10) / 10;
  }

  return Array.from(summaries.values()).sort((a, b) => b.eventCount - a.eventCount);
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

export type TimelineKind = "event" | "survey" | "session";

export interface TimelineRow {
  kind: TimelineKind;
  userId: string;
  time: Date | null;
  name: string;
  feature: string;
  sessionId: string;
  details: string;
  survey?: BetaSurvey;
  event?: BetaEvent;
  session?: BetaSession;
}

export function buildTimeline(events: BetaEvent[], sessions: BetaSession[], surveys: BetaSurvey[]): TimelineRow[] {
  const rows: TimelineRow[] = [];
  for (const e of events) {
    if (!e.userId) continue;
    rows.push({
      kind: "event",
      userId: e.userId,
      time: e.time,
      name: e.eventName,
      feature: e.feature,
      sessionId: e.sessionId,
      details: JSON.stringify(jsonSafe({ screen: e.screen || undefined, source: e.source, ...e.metadata })),
      event: e,
    });
  }
  for (const s of sessions) {
    if (!s.userId) continue;
    rows.push({
      kind: "session",
      userId: s.userId,
      time: s.startedAt,
      name: "session",
      feature: "",
      sessionId: s.id,
      details: JSON.stringify({
        endedAt: iso(s.endedAt) || null,
        durationSeconds: s.durationSeconds,
        entryPoint: s.entryPoint || null,
        platform: s.platform || null,
      }),
      session: s,
    });
  }
  for (const s of surveys) {
    if (!s.userId) continue;
    rows.push({
      kind: "survey",
      userId: s.userId,
      time: s.time,
      name: s.surveyType,
      feature: s.feature,
      sessionId: s.sessionId || s.context?.matchedSessionId || "",
      details: JSON.stringify({ docPath: s.docPath, sourceId: s.sourceId || null, answers: s.answers }),
      survey: s,
    });
  }
  rows.sort((a, b) => {
    const ta = a.time ? a.time.getTime() : Number.MAX_SAFE_INTEGER;
    const tb = b.time ? b.time.getTime() : Number.MAX_SAFE_INTEGER;
    return ta - tb;
  });
  return rows;
}

// ---------------------------------------------------------------------------
// CSV / JSON export
// ---------------------------------------------------------------------------

export function csvCell(v: unknown): string {
  if (v == null) return "";
  let s: string;
  if (v instanceof Date) s = iso(v);
  else if (typeof v === "object") s = JSON.stringify(jsonSafe(v));
  else s = String(v);
  return /[",\r\n]/.test(s) || /^\s|\s$/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export function toCsv(headers: string[], rows: Array<Record<string, unknown>>): string {
  const lines = [headers.map(csvCell).join(",")];
  for (const r of rows) lines.push(headers.map((h) => csvCell(r[h])).join(","));
  // BOM so Excel opens UTF-8 correctly.
  return "﻿" + lines.join("\r\n") + "\r\n";
}

export function downloadText(filename: string, text: string, mime: string): void {
  const blob = new Blob([text], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function rangeSuffix(range: DateRange): string {
  return `${range.startKey}_to_${range.endKey}`;
}

/** Most common metadata keys, used for the flattened metadata.* CSV columns. */
export function commonMetadataKeys(events: BetaEvent[], max = 40): string[] {
  const counts = new Map<string, number>();
  for (const e of events) for (const k of Object.keys(e.metadata)) counts.set(k, (counts.get(k) ?? 0) + 1);
  return Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
    .slice(0, max)
    .map(([k]) => k)
    .sort();
}

export function eventToJson(e: BetaEvent): Record<string, unknown> {
  return {
    id: e.id,
    eventName: e.eventName,
    feature: e.feature,
    screen: e.screen,
    userId: e.userId,
    userIdResolvedFromAnon: e.userIdResolved,
    anonUserId: e.anonUserId,
    timestamp: iso(e.time) || null,
    clientTimestamp: e.clientTimestamp || null,
    platform: e.platform,
    appVersion: e.appVersion,
    environment: e.environment,
    sessionId: e.sessionId,
    source: e.source,
    dateKey: e.dateKey,
    cohortType: e.cohortType,
    gestationalWeek: e.gestationalWeek,
    trimester: e.trimester,
    durationMs: e.durationMs,
    metadata: jsonSafe(e.metadata),
  };
}

export function eventsCsv(events: BetaEvent[]): string {
  const metaKeys = commonMetadataKeys(events);
  const base = [
    "id",
    "timestamp",
    "clientTimestamp",
    "eventName",
    "feature",
    "screen",
    "userId",
    "userIdResolvedFromAnon",
    "anonUserId",
    "sessionId",
    "source",
    "platform",
    "appVersion",
    "environment",
    "dateKey",
    "cohortType",
    "gestationalWeek",
    "trimester",
    "durationMs",
    "metadata_json",
  ];
  const headers = [...base, ...metaKeys.map((k) => `metadata.${k}`)];
  const rows = events.map((e) => {
    const r: Record<string, unknown> = {
      ...eventToJson(e),
      metadata_json: JSON.stringify(jsonSafe(e.metadata)),
    };
    for (const k of metaKeys) r[`metadata.${k}`] = toScalar(e.metadata[k]);
    return r;
  });
  return toCsv(headers, rows);
}

export function sessionToJson(s: BetaSession): Record<string, unknown> {
  return {
    id: s.id,
    userId: s.userId,
    anonUserId: s.anonUserId,
    startedAt: iso(s.startedAt) || null,
    endedAt: iso(s.endedAt) || null,
    durationSeconds: s.durationSeconds,
    entryPoint: s.entryPoint,
    platform: s.platform,
  };
}

export function sessionsCsv(sessions: BetaSession[], users: Map<string, BetaUserProfile>): string {
  const headers = ["id", "userId", "email", "anonUserId", "startedAt", "endedAt", "durationSeconds", "entryPoint", "platform"];
  return toCsv(
    headers,
    sessions.map((s) => ({ ...sessionToJson(s), email: s.userId ? users.get(s.userId)?.email ?? "" : "" })),
  );
}

export function surveyToJson(s: BetaSurvey, users: Map<string, BetaUserProfile>): Record<string, unknown> {
  const p = s.userId ? users.get(s.userId) : undefined;
  return {
    surveyType: s.surveyType,
    docPath: s.docPath,
    userId: s.userId,
    email: p?.email ?? "",
    name: p?.name ?? "",
    anonUserId: s.anonUserId,
    time: iso(s.time) || null,
    feature: s.feature,
    sourceId: s.sourceId,
    sessionId: s.sessionId,
    answers: s.answers,
    context: s.context
      ? {
          ...s.context,
          prevEvent: s.context.prevEvent ? { ...s.context.prevEvent, time: iso(s.context.prevEvent.time) || null } : null,
          nextEvent: s.context.nextEvent ? { ...s.context.nextEvent, time: iso(s.context.nextEvent.time) || null } : null,
        }
      : null,
  };
}

export function surveysCsv(surveys: BetaSurvey[], users: Map<string, BetaUserProfile>): string {
  const answerKeys = Array.from(new Set(surveys.flatMap((s) => Object.keys(s.answers)))).sort();
  const headers = [
    "surveyType",
    "docPath",
    "time",
    "userId",
    "email",
    "name",
    "cohortType",
    "studyId",
    "feature",
    "sourceId",
    "sessionId",
    "ctx.sessionMatch",
    "ctx.matchedSessionId",
    "ctx.sessionEventCount",
    "ctx.sessionFeatures",
    "ctx.prevEvent.name",
    "ctx.prevEvent.feature",
    "ctx.prevEvent.screen",
    "ctx.prevEvent.time",
    "ctx.nextEvent.name",
    "ctx.nextEvent.feature",
    "ctx.nextEvent.screen",
    "ctx.nextEvent.time",
    "ctx.eventsPrev30Min",
    "ctx.userEventsInPeriod",
    "answers_json",
    ...answerKeys.map((k) => `answer.${k}`),
  ];
  const rows = surveys.map((s) => {
    const p = s.userId ? users.get(s.userId) : undefined;
    const c = s.context;
    const r: Record<string, unknown> = {
      surveyType: s.surveyType,
      docPath: s.docPath,
      time: iso(s.time),
      userId: s.userId ?? "",
      email: p?.email ?? "",
      name: p?.name ?? "",
      cohortType: p?.cohortType ?? "",
      studyId: p?.studyId ?? "",
      feature: s.feature,
      sourceId: s.sourceId,
      sessionId: s.sessionId,
      "ctx.sessionMatch": c?.sessionMatch ?? "",
      "ctx.matchedSessionId": c?.matchedSessionId ?? "",
      "ctx.sessionEventCount": c?.sessionEventCount ?? "",
      "ctx.sessionFeatures": c?.sessionFeatures.join("; ") ?? "",
      "ctx.prevEvent.name": c?.prevEvent?.name ?? "",
      "ctx.prevEvent.feature": c?.prevEvent?.feature ?? "",
      "ctx.prevEvent.screen": c?.prevEvent?.screen ?? "",
      "ctx.prevEvent.time": iso(c?.prevEvent?.time),
      "ctx.nextEvent.name": c?.nextEvent?.name ?? "",
      "ctx.nextEvent.feature": c?.nextEvent?.feature ?? "",
      "ctx.nextEvent.screen": c?.nextEvent?.screen ?? "",
      "ctx.nextEvent.time": iso(c?.nextEvent?.time),
      "ctx.eventsPrev30Min": c?.eventsPrev30Min ?? "",
      "ctx.userEventsInPeriod": c?.userEventsInPeriod ?? "",
      answers_json: JSON.stringify(s.answers),
    };
    for (const k of answerKeys) r[`answer.${k}`] = s.answers[k];
    return r;
  });
  return toCsv(headers, rows);
}

export function userSummaryToJson(u: BetaUserSummary): Record<string, unknown> {
  return {
    uid: u.uid,
    profileFound: u.exists,
    email: u.email,
    name: u.name,
    cohortType: u.cohortType,
    isResearchParticipant: u.isResearchParticipant,
    studyId: u.studyId,
    anonUserId: u.anonUserId,
    accountCreatedAt: iso(u.createdAt) || null,
    lastActiveAt: iso(u.lastActiveAt) || null,
    firstSeen: iso(u.firstSeen) || null,
    lastSeen: iso(u.lastSeen) || null,
    eventCount: u.eventCount,
    activeDays: u.activeDays,
    sessionCount: u.sessionCount,
    totalSessionMinutes: u.totalSessionMinutes,
    daysWith10SessionMinutes: u.daysWith10SessionMinutes,
    surveysTotal: u.surveysTotal,
    surveysByType: u.surveysByType,
    betaChecklistItemsCompleted: u.betaChecklistItemsCompleted,
    betaChecklistItemIds: u.betaChecklistItemIds,
    betaDailyGoalsMet: u.betaDailyGoalsMet,
  };
}

export function usersCsv(users: BetaUserSummary[]): string {
  const types = Object.keys(SURVEY_TYPE_LABELS) as SurveyType[];
  const headers = [
    "uid",
    "profileFound",
    "email",
    "name",
    "cohortType",
    "isResearchParticipant",
    "studyId",
    "anonUserId",
    "accountCreatedAt",
    "lastActiveAt",
    "firstSeen",
    "lastSeen",
    "eventCount",
    "activeDays",
    "sessionCount",
    "totalSessionMinutes",
    "daysWith10SessionMinutes",
    "surveysTotal",
    ...types.map((t) => `surveys.${t}`),
    "betaChecklistItemsCompleted",
    "betaChecklistItemIds",
    "betaDailyGoalsMet",
  ];
  return toCsv(
    headers,
    users.map((u) => {
      const r: Record<string, unknown> = {
        ...userSummaryToJson(u),
        betaChecklistItemIds: u.betaChecklistItemIds.join("; "),
      };
      for (const t of types) r[`surveys.${t}`] = u.surveysByType[t] ?? 0;
      return r;
    }),
  );
}

export function timelineCsv(rows: TimelineRow[]): string {
  const headers = ["kind", "userId", "time", "name", "feature", "sessionId", "details"];
  return toCsv(
    headers,
    rows.map((r) => ({
      kind: r.kind,
      userId: r.userId,
      time: iso(r.time),
      name: r.name,
      feature: r.feature,
      sessionId: r.sessionId,
      details: r.details,
    })),
  );
}
