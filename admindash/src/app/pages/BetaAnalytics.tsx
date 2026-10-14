import { useCallback, useMemo, useState, type CSSProperties, type ReactNode } from "react";
import { Activity, ClipboardList, Download, FlaskConical, Loader2, Users, X, Clock } from "lucide-react";
import { auth } from "../../firebase/firebase";
import {
  attachSurveyContext,
  buildRange,
  buildTimeline,
  buildUserSummaries,
  defaultRangeKeys,
  downloadText,
  EVENT_HARD_CAP,
  eventsCsv,
  eventToJson,
  iso,
  loadBetaData,
  rangeSuffix,
  sessionsCsv,
  sessionToJson,
  surveysCsv,
  surveyToJson,
  SURVEY_TYPE_LABELS,
  timelineCsv,
  userSummaryToJson,
  usersCsv,
  type BetaEvent,
  type BetaSurvey,
  type LoadedBetaData,
  type SurveyType,
  type TimelineRow,
} from "../../lib/betaAnalytics";

type TabKey = "users" | "surveys" | "events";

const EVENTS_SHOWN = 500;
const EVENTS_PAGE = 100;

const C = {
  text: "#424242",
  sub: "#616161",
  muted: "#757575",
  border: "#e0e0e0",
  rowBorder: "#f5f5f5",
  accent: "#9575cd",
  accentSoft: "#ede7f6",
  accentText: "#7e57c2",
  surveyBg: "#f3e5f5",
  sessionBg: "#e8f5e9",
  warnBg: "#fff8e1",
  warnText: "#8d6e00",
  errBg: "#fee2e2",
  errText: "#dc2626",
};

const card: CSSProperties = { backgroundColor: "white", borderColor: C.border };
const inputStyle: CSSProperties = { backgroundColor: "white", borderColor: C.border, color: C.text };

function fmtTime(d: Date | null | undefined): string {
  if (!d) return "—";
  return d.toLocaleString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function shortId(id: string | null | undefined): string {
  if (!id) return "—";
  return id.length > 12 ? `${id.slice(0, 6)}…${id.slice(-4)}` : id;
}

function Th({ children, right }: { children: ReactNode; right?: boolean }) {
  return (
    <th className={`${right ? "text-right" : "text-left"} py-3 px-3 text-xs whitespace-nowrap`} style={{ color: C.muted }}>
      {children}
    </th>
  );
}

function Td({ children, right, mono }: { children: ReactNode; right?: boolean; mono?: boolean }) {
  return (
    <td
      className={`${right ? "text-right" : "text-left"} py-2 px-3 text-sm align-top ${mono ? "font-mono text-xs" : ""}`}
      style={{ color: C.sub }}
    >
      {children}
    </td>
  );
}

function AnswerList({ answers }: { answers: BetaSurvey["answers"] }) {
  const entries = Object.entries(answers).filter(([, v]) => v !== null && v !== "");
  if (entries.length === 0) return <div className="text-xs" style={{ color: C.muted }}>No answers recorded</div>;
  return (
    <dl className="text-xs space-y-1">
      {entries.map(([k, v]) => (
        <div key={k} className="flex gap-2">
          <dt className="shrink-0" style={{ color: C.muted }}>
            {k}:
          </dt>
          <dd className="break-words" style={{ color: C.text }}>
            {String(v)}
          </dd>
        </div>
      ))}
    </dl>
  );
}

export function BetaAnalytics() {
  const defaults = useMemo(() => defaultRangeKeys(), []);
  const [startKey, setStartKey] = useState(defaults.startKey);
  const [endKey, setEndKey] = useState(defaults.endKey);
  const [userFilter, setUserFilter] = useState("");
  const [eventFilter, setEventFilter] = useState("");
  const [includeCloud, setIncludeCloud] = useState(false);

  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState("");
  const [error, setError] = useState("");
  const [data, setData] = useState<LoadedBetaData | null>(null);

  const [tab, setTab] = useState<TabKey>("users");
  const [selectedUid, setSelectedUid] = useState<string | null>(null);
  const [eventsPage, setEventsPage] = useState(0);

  async function handleLoad() {
    const range = buildRange(startKey, endKey);
    if (!range) {
      setError("Pick a valid start and end date (end on or after start).");
      return;
    }
    setLoading(true);
    setError("");
    setProgress("Starting...");
    setSelectedUid(null);
    setEventsPage(0);
    try {
      const u = auth.currentUser;
      if (u) await u.getIdToken(true);
      const loaded = await loadBetaData(range, setProgress);
      setData(loaded);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      setError(`Failed to load data: ${msg}`);
    } finally {
      setLoading(false);
      setProgress("");
    }
  }

  // Cloud-function docs duplicate mobile events, so they are left out unless asked for.
  const baseEvents = useMemo<BetaEvent[]>(
    () => (data ? (includeCloud ? data.events : data.events.filter((e) => e.source !== "cloud_function")) : []),
    [data, includeCloud],
  );

  const cloudCount = useMemo(
    () => (data ? data.events.filter((e) => e.source === "cloud_function").length : 0),
    [data],
  );

  // null = no user filter.
  const matchingUids = useMemo<Set<string> | null>(() => {
    const f = userFilter.trim().toLowerCase();
    if (!f || !data) return null;
    const out = new Set<string>();
    for (const [uid, p] of data.users) {
      if (uid.toLowerCase().includes(f) || p.email.toLowerCase().includes(f)) out.add(uid);
    }
    return out;
  }, [userFilter, data]);

  const keepUser = useCallback(
    (uid: string | null) => (matchingUids ? uid != null && matchingUids.has(uid) : true),
    [matchingUids],
  );

  const userEvents = useMemo(() => baseEvents.filter((e) => keepUser(e.userId)), [baseEvents, keepUser]);

  const shownEvents = useMemo(() => {
    const f = eventFilter.trim().toLowerCase();
    return f ? userEvents.filter((e) => e.eventName.toLowerCase().includes(f)) : userEvents;
  }, [userEvents, eventFilter]);

  const sessions = useMemo(
    () => (data ? data.sessions.filter((s) => keepUser(s.userId)) : []),
    [data, keepUser],
  );

  // Context is computed against every (non-duplicate) event, before the user/name filters.
  const surveysWithContext = useMemo(
    () => (data ? attachSurveyContext(data.surveys, baseEvents) : []),
    [data, baseEvents],
  );

  const surveys = useMemo(
    () =>
      surveysWithContext
        .filter((s) => keepUser(s.userId))
        .sort((a, b) => (b.time?.getTime() ?? 0) - (a.time?.getTime() ?? 0)),
    [surveysWithContext, keepUser],
  );

  const userSummaries = useMemo(
    () => (data ? buildUserSummaries(data.users, userEvents, sessions, surveys) : []),
    [data, userEvents, sessions, surveys],
  );

  const eventsDesc = useMemo(
    () => [...shownEvents].sort((a, b) => (b.time?.getTime() ?? 0) - (a.time?.getTime() ?? 0)),
    [shownEvents],
  );

  const selectedTimeline = useMemo<TimelineRow[]>(() => {
    if (!selectedUid) return [];
    return buildTimeline(
      userEvents.filter((e) => e.userId === selectedUid),
      sessions.filter((s) => s.userId === selectedUid),
      surveys.filter((s) => s.userId === selectedUid),
    );
  }, [selectedUid, userEvents, sessions, surveys]);

  const selectedSummary = selectedUid ? userSummaries.find((u) => u.uid === selectedUid) ?? null : null;

  const stats = useMemo(() => {
    const active = new Set(shownEvents.map((e) => e.userId).filter((v): v is string => Boolean(v)));
    return {
      events: shownEvents.length,
      activeUsers: active.size,
      sessions: sessions.length,
      surveys: surveys.length,
    };
  }, [shownEvents, sessions, surveys]);

  // ------------------------------------------------------------------ downloads

  function download(kind: "eventsCsv" | "eventsJson" | "surveys" | "sessions" | "users" | "timeline" | "all") {
    if (!data) return;
    const sfx = rangeSuffix(data.range);
    switch (kind) {
      case "eventsCsv":
        downloadText(`beta-events_${sfx}.csv`, eventsCsv(shownEvents), "text/csv;charset=utf-8");
        break;
      case "eventsJson":
        downloadText(
          `beta-events_${sfx}.json`,
          JSON.stringify(shownEvents.map(eventToJson), null, 2),
          "application/json",
        );
        break;
      case "surveys":
        downloadText(`beta-surveys_${sfx}.csv`, surveysCsv(surveys, data.users), "text/csv;charset=utf-8");
        break;
      case "sessions":
        downloadText(`beta-sessions_${sfx}.csv`, sessionsCsv(sessions, data.users), "text/csv;charset=utf-8");
        break;
      case "users":
        downloadText(`beta-users_${sfx}.csv`, usersCsv(userSummaries), "text/csv;charset=utf-8");
        break;
      case "timeline":
        downloadText(
          `beta-timeline_${sfx}.csv`,
          timelineCsv(buildTimeline(shownEvents, sessions, surveys)),
          "text/csv;charset=utf-8",
        );
        break;
      case "all":
        downloadText(
          `beta-analytics-all_${sfx}.json`,
          JSON.stringify(
            {
              range: {
                startDate: data.range.startKey,
                endDateInclusive: data.range.endKey,
                startIso: iso(data.range.start),
                endExclusiveIso: iso(data.range.endExclusive),
              },
              generatedAt: new Date().toISOString(),
              filters: {
                user: userFilter.trim() || null,
                eventName: eventFilter.trim() || null,
                includeCloudFunctionDuplicates: includeCloud,
              },
              eventsCapped: data.eventsCapped,
              warnings: data.warnings,
              events: shownEvents.map(eventToJson),
              sessions: sessions.map(sessionToJson),
              surveys: surveys.map((s) => surveyToJson(s, data.users)),
              users: userSummaries.map(userSummaryToJson),
            },
            null,
            2,
          ),
          "application/json",
        );
        break;
    }
  }

  // ------------------------------------------------------------------ render

  const eventPageCount = Math.max(1, Math.ceil(Math.min(eventsDesc.length, EVENTS_SHOWN) / EVENTS_PAGE));
  const pageRows = eventsDesc.slice(eventsPage * EVENTS_PAGE, Math.min((eventsPage + 1) * EVENTS_PAGE, EVENTS_SHOWN));

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl mb-2" style={{ color: C.text }}>
            Beta Analytics
          </h1>
          <p className="text-base" style={{ color: C.sub }}>
            Raw events, sessions and surveys for beta testers, joined per user and exportable
          </p>
        </div>
        <FlaskConical className="w-8 h-8" style={{ color: C.accent }} />
      </div>

      {/* Controls */}
      <div className="p-6 rounded-2xl border mb-6" style={card}>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-4">
          <label className="text-xs flex flex-col gap-1" style={{ color: C.muted }}>
            Start date
            <input
              type="date"
              value={startKey}
              onChange={(e) => setStartKey(e.target.value)}
              className="px-3 py-2 rounded-lg border text-sm"
              style={inputStyle}
            />
          </label>
          <label className="text-xs flex flex-col gap-1" style={{ color: C.muted }}>
            End date (inclusive)
            <input
              type="date"
              value={endKey}
              onChange={(e) => setEndKey(e.target.value)}
              className="px-3 py-2 rounded-lg border text-sm"
              style={inputStyle}
            />
          </label>
          <label className="text-xs flex flex-col gap-1" style={{ color: C.muted }}>
            User (uid or email contains)
            <input
              type="text"
              value={userFilter}
              placeholder="optional"
              onChange={(e) => {
                setUserFilter(e.target.value);
                setEventsPage(0);
              }}
              className="px-3 py-2 rounded-lg border text-sm"
              style={inputStyle}
            />
          </label>
          <label className="text-xs flex flex-col gap-1" style={{ color: C.muted }}>
            Event name contains
            <input
              type="text"
              value={eventFilter}
              placeholder="optional"
              onChange={(e) => {
                setEventFilter(e.target.value);
                setEventsPage(0);
              }}
              className="px-3 py-2 rounded-lg border text-sm"
              style={inputStyle}
            />
          </label>
        </div>
        <div className="flex flex-wrap items-center gap-4">
          <label className="flex items-center gap-2 text-sm" style={{ color: C.sub }}>
            <input type="checkbox" checked={includeCloud} onChange={(e) => setIncludeCloud(e.target.checked)} />
            Include cloud-function duplicates
            {data ? <span style={{ color: C.muted }}>({cloudCount.toLocaleString()} in range)</span> : null}
          </label>
          <button
            className="px-4 py-2 rounded-lg border flex items-center gap-2 text-sm transition-colors disabled:opacity-60"
            style={{ backgroundColor: C.accent, borderColor: C.accent, color: "white" }}
            onClick={() => void handleLoad()}
            disabled={loading}
          >
            {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Activity className="w-4 h-4" />}
            Load data
          </button>
          {loading && progress ? (
            <span className="text-sm" style={{ color: C.muted }}>
              {progress}
            </span>
          ) : null}
        </div>
        <p className="text-xs mt-3" style={{ color: C.muted }}>
          Date, user and duplicate filters apply to everything. The event-name filter narrows the Events table and the
          event, timeline and combined exports only; user summaries and survey context always use every event.
          Times are shown in your local time zone and exported as ISO (UTC).
        </p>
      </div>

      {error && (
        <div className="mb-4 p-4 rounded-xl" style={{ backgroundColor: C.errBg, color: C.errText }}>
          {error}
        </div>
      )}
      {data?.eventsCapped && (
        <div className="mb-4 p-4 rounded-xl text-sm" style={{ backgroundColor: C.warnBg, color: C.warnText }}>
          Event loading stopped at the {EVENT_HARD_CAP.toLocaleString()}-event cap. Events after{" "}
          {fmtTime(data.events[data.events.length - 1]?.time)} are missing; narrow the date range to see them.
        </div>
      )}
      {data && data.warnings.length > 0 && (
        <div className="mb-4 p-4 rounded-xl text-sm" style={{ backgroundColor: C.warnBg, color: C.warnText }}>
          {data.warnings.map((w) => (
            <div key={w}>{w}</div>
          ))}
        </div>
      )}

      {!data ? (
        <div className="p-12 rounded-2xl border text-center text-sm" style={{ ...card, color: C.muted }}>
          {loading ? "Loading..." : "Choose a date range and press Load data."}
        </div>
      ) : (
        <>
          {/* Summary cards */}
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 mb-6">
            {[
              { icon: Activity, label: "Events", value: stats.events },
              { icon: Users, label: "Active users", value: stats.activeUsers },
              { icon: Clock, label: "Sessions", value: stats.sessions },
              { icon: ClipboardList, label: "Surveys", value: stats.surveys },
            ].map((m) => (
              <div key={m.label} className="p-5 rounded-2xl border" style={card}>
                <div className="flex items-center gap-2 mb-2">
                  <m.icon className="w-4 h-4" style={{ color: C.accent }} />
                  <div className="text-xs" style={{ color: C.muted }}>
                    {m.label}
                  </div>
                </div>
                <div className="text-2xl" style={{ color: C.text }}>
                  {m.value.toLocaleString()}
                </div>
              </div>
            ))}
          </div>

          {/* Downloads */}
          <div className="p-5 rounded-2xl border mb-6" style={card}>
            <div className="text-sm mb-3" style={{ color: C.text }}>
              Downloads ({data.range.startKey} to {data.range.endKey}, current filters)
            </div>
            <div className="flex flex-wrap gap-2">
              {(
                [
                  ["eventsCsv", "Events CSV"],
                  ["eventsJson", "Events JSON"],
                  ["surveys", "Surveys CSV"],
                  ["sessions", "Sessions CSV"],
                  ["users", "Users summary CSV"],
                  ["timeline", "Combined timeline CSV"],
                ] as const
              ).map(([k, label]) => (
                <button
                  key={k}
                  className="px-3 py-2 rounded-lg text-sm flex items-center gap-2"
                  style={{ backgroundColor: C.accentSoft, color: C.accentText }}
                  onClick={() => download(k)}
                >
                  <Download className="w-4 h-4" />
                  {label}
                </button>
              ))}
              <button
                className="px-3 py-2 rounded-lg border text-sm flex items-center gap-2"
                style={{ backgroundColor: C.accent, borderColor: C.accent, color: "white" }}
                onClick={() => download("all")}
              >
                <Download className="w-4 h-4" />
                Download everything (JSON)
              </button>
            </div>
          </div>

          {/* Tabs */}
          <div className="flex gap-2 mb-4">
            {(
              [
                ["users", `Users (${userSummaries.length})`],
                ["surveys", `Surveys (${surveys.length})`],
                ["events", `Events (${shownEvents.length.toLocaleString()})`],
              ] as const
            ).map(([k, label]) => (
              <button
                key={k}
                className="px-4 py-2 rounded-xl text-sm"
                style={{
                  backgroundColor: tab === k ? C.accentSoft : "white",
                  color: tab === k ? C.accentText : C.sub,
                  border: `1px solid ${tab === k ? C.accentSoft : C.border}`,
                }}
                onClick={() => setTab(k)}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "users" && (
            <div className="p-6 rounded-2xl border mb-6" style={card}>
              <p className="text-xs mb-3" style={{ color: C.muted }}>
                Click a row to open that user's timeline.
              </p>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr style={{ borderBottom: `2px solid ${C.border}` }}>
                      <Th>User</Th>
                      <Th>Cohort</Th>
                      <Th>Research</Th>
                      <Th>First seen</Th>
                      <Th>Last seen</Th>
                      <Th right>Events</Th>
                      <Th right>Active days</Th>
                      <Th right>Session min</Th>
                      <Th right>Days 10+ min</Th>
                      <Th right>Surveys</Th>
                      <Th right>Checklist</Th>
                      <Th right>Goals met</Th>
                    </tr>
                  </thead>
                  <tbody>
                    {userSummaries.map((u) => (
                      <tr
                        key={u.uid}
                        className="cursor-pointer"
                        style={{
                          borderBottom: `1px solid ${C.rowBorder}`,
                          backgroundColor: selectedUid === u.uid ? C.accentSoft : undefined,
                        }}
                        onClick={() => setSelectedUid(selectedUid === u.uid ? null : u.uid)}
                      >
                        <Td>
                          <div style={{ color: C.text }}>{u.email || u.name || "(no profile)"}</div>
                          <div className="font-mono text-xs" style={{ color: C.muted }} title={u.uid}>
                            {u.name && u.email ? `${u.name} · ` : ""}
                            {shortId(u.uid)}
                          </div>
                        </Td>
                        <Td>{u.cohortType || "—"}</Td>
                        <Td>
                          {u.isResearchParticipant == null ? "—" : u.isResearchParticipant ? "Yes" : "No"}
                          {u.studyId ? <div className="font-mono text-xs">{u.studyId}</div> : null}
                        </Td>
                        <Td>{fmtTime(u.firstSeen)}</Td>
                        <Td>{fmtTime(u.lastSeen)}</Td>
                        <Td right>{u.eventCount.toLocaleString()}</Td>
                        <Td right>{u.activeDays}</Td>
                        <Td right>{u.totalSessionMinutes.toFixed(1)}</Td>
                        <Td right>{u.daysWith10SessionMinutes}</Td>
                        <Td right>
                          <span
                            title={Object.entries(u.surveysByType)
                              .map(([t, n]) => `${SURVEY_TYPE_LABELS[t as SurveyType]}: ${n}`)
                              .join("\n")}
                          >
                            {u.surveysTotal}
                          </span>
                        </Td>
                        <Td right>
                          <span title={u.betaChecklistItemIds.join("\n")}>{u.betaChecklistItemsCompleted}</span>
                        </Td>
                        <Td right>{u.betaDailyGoalsMet}</Td>
                      </tr>
                    ))}
                    {userSummaries.length === 0 && (
                      <tr>
                        <td colSpan={12} className="py-6 text-center text-sm" style={{ color: C.muted }}>
                          No users match.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {tab === "users" && selectedUid && (
            <div className="p-6 rounded-2xl border mb-6" style={card}>
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h2 className="text-xl mb-1" style={{ color: C.text }}>
                    Timeline: {selectedSummary?.email || selectedSummary?.name || selectedUid}
                  </h2>
                  <div className="font-mono text-xs" style={{ color: C.muted }}>
                    {selectedUid}
                  </div>
                  <div className="text-xs mt-1" style={{ color: C.muted }}>
                    {selectedTimeline.filter((r) => r.kind === "event").length} events ·{" "}
                    {selectedTimeline.filter((r) => r.kind === "session").length} sessions ·{" "}
                    {selectedTimeline.filter((r) => r.kind === "survey").length} surveys
                  </div>
                </div>
                <button onClick={() => setSelectedUid(null)} aria-label="Close timeline" style={{ color: C.muted }}>
                  <X className="w-5 h-5" />
                </button>
              </div>
              <div className="max-h-[600px] overflow-y-auto space-y-1">
                {selectedTimeline.map((r, i) => (
                  <TimelineItem key={`${r.kind}-${i}`} row={r} />
                ))}
              </div>
            </div>
          )}

          {tab === "surveys" && (
            <div className="p-6 rounded-2xl border mb-6" style={card}>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr style={{ borderBottom: `2px solid ${C.border}` }}>
                      <Th>Time</Th>
                      <Th>Type</Th>
                      <Th>User</Th>
                      <Th>Feature / source</Th>
                      <Th>Session</Th>
                      <Th>Previous event</Th>
                      <Th>Next event</Th>
                      <Th right>Events 30 min before</Th>
                      <Th right>User events in range</Th>
                      <Th>Answers</Th>
                    </tr>
                  </thead>
                  <tbody>
                    {surveys.map((s) => {
                      const c = s.context;
                      const p = s.userId ? data.users.get(s.userId) : undefined;
                      return (
                        <tr key={s.docPath} style={{ borderBottom: `1px solid ${C.rowBorder}` }}>
                          <Td>{fmtTime(s.time)}</Td>
                          <Td>{SURVEY_TYPE_LABELS[s.surveyType]}</Td>
                          <Td>
                            <div style={{ color: C.text }}>{p?.email || p?.name || "—"}</div>
                            <div className="font-mono text-xs" title={s.userId ?? ""}>
                              {shortId(s.userId)}
                            </div>
                          </Td>
                          <Td>
                            {s.feature || "—"}
                            {s.sourceId ? <div className="font-mono text-xs">{s.sourceId}</div> : null}
                          </Td>
                          <Td>
                            {c && c.sessionMatch !== "none" ? (
                              <>
                                <div className="font-mono text-xs" title={c.matchedSessionId}>
                                  {shortId(c.matchedSessionId)} ({c.sessionMatch})
                                </div>
                                <div className="text-xs">
                                  {c.sessionEventCount} events{c.sessionFeatures.length ? `: ${c.sessionFeatures.join(", ")}` : ""}
                                </div>
                              </>
                            ) : (
                              "—"
                            )}
                          </Td>
                          <Td>
                            {c?.prevEvent ? (
                              <>
                                <div>{c.prevEvent.name}</div>
                                <div className="text-xs">
                                  {[c.prevEvent.feature, c.prevEvent.screen].filter(Boolean).join(" / ")}
                                </div>
                                <div className="text-xs">{fmtTime(c.prevEvent.time)}</div>
                              </>
                            ) : (
                              "—"
                            )}
                          </Td>
                          <Td>
                            {c?.nextEvent ? (
                              <>
                                <div>{c.nextEvent.name}</div>
                                <div className="text-xs">
                                  {[c.nextEvent.feature, c.nextEvent.screen].filter(Boolean).join(" / ")}
                                </div>
                                <div className="text-xs">{fmtTime(c.nextEvent.time)}</div>
                              </>
                            ) : (
                              "—"
                            )}
                          </Td>
                          <Td right>{c?.eventsPrev30Min ?? "—"}</Td>
                          <Td right>{c?.userEventsInPeriod ?? "—"}</Td>
                          <Td>
                            <div className="min-w-[280px] max-w-[420px]">
                              <AnswerList answers={s.answers} />
                            </div>
                          </Td>
                        </tr>
                      );
                    })}
                    {surveys.length === 0 && (
                      <tr>
                        <td colSpan={10} className="py-6 text-center text-sm" style={{ color: C.muted }}>
                          No surveys in this range.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {tab === "events" && (
            <div className="p-6 rounded-2xl border mb-6" style={card}>
              <div className="flex items-center justify-between mb-3">
                <p className="text-xs" style={{ color: C.muted }}>
                  Newest first. Showing up to the first {EVENTS_SHOWN} of {shownEvents.length.toLocaleString()} events;
                  download for the full set.
                </p>
                <div className="flex items-center gap-2 text-sm" style={{ color: C.sub }}>
                  <button
                    className="px-3 py-1 rounded-lg border disabled:opacity-50"
                    style={inputStyle}
                    disabled={eventsPage === 0}
                    onClick={() => setEventsPage((p) => Math.max(0, p - 1))}
                  >
                    Prev
                  </button>
                  <span>
                    Page {eventsPage + 1} / {eventPageCount}
                  </span>
                  <button
                    className="px-3 py-1 rounded-lg border disabled:opacity-50"
                    style={inputStyle}
                    disabled={eventsPage + 1 >= eventPageCount}
                    onClick={() => setEventsPage((p) => Math.min(eventPageCount - 1, p + 1))}
                  >
                    Next
                  </button>
                </div>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr style={{ borderBottom: `2px solid ${C.border}` }}>
                      <Th>Time</Th>
                      <Th>Event</Th>
                      <Th>Feature</Th>
                      <Th>Screen</Th>
                      <Th>User</Th>
                      <Th>Session</Th>
                      <Th>Source</Th>
                      <Th>Platform / version</Th>
                      <Th>Metadata</Th>
                    </tr>
                  </thead>
                  <tbody>
                    {pageRows.map((e) => {
                      const p = e.userId ? data.users.get(e.userId) : undefined;
                      const meta = JSON.stringify(e.metadata);
                      return (
                        <tr key={e.id} style={{ borderBottom: `1px solid ${C.rowBorder}` }}>
                          <Td>{fmtTime(e.time)}</Td>
                          <Td>{e.eventName}</Td>
                          <Td>{e.feature || "—"}</Td>
                          <Td>{e.screen || "—"}</Td>
                          <Td>
                            <span title={e.userId ?? e.anonUserId ?? ""}>
                              {p?.email || shortId(e.userId ?? e.anonUserId)}
                            </span>
                          </Td>
                          <Td mono>
                            <span title={e.sessionId}>{shortId(e.sessionId)}</span>
                          </Td>
                          <Td>{e.source || "—"}</Td>
                          <Td>{[e.platform, e.appVersion].filter(Boolean).join(" / ") || "—"}</Td>
                          <Td mono>
                            <span title={meta}>{meta.length > 80 ? `${meta.slice(0, 80)}…` : meta}</span>
                          </Td>
                        </tr>
                      );
                    })}
                    {pageRows.length === 0 && (
                      <tr>
                        <td colSpan={9} className="py-6 text-center text-sm" style={{ color: C.muted }}>
                          No events match.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

function TimelineItem({ row }: { row: TimelineRow }) {
  if (row.kind === "survey" && row.survey) {
    const s = row.survey;
    return (
      <div className="p-3 rounded-xl border" style={{ backgroundColor: C.surveyBg, borderColor: C.accent }}>
        <div className="flex flex-wrap items-center gap-2 text-sm mb-2">
          <ClipboardList className="w-4 h-4" style={{ color: C.accentText }} />
          <span style={{ color: C.muted }}>{fmtTime(row.time)}</span>
          <strong style={{ color: C.accentText }}>{SURVEY_TYPE_LABELS[s.surveyType]}</strong>
          {s.feature ? <span style={{ color: C.sub }}>{s.feature}</span> : null}
          {s.sourceId ? <span className="font-mono text-xs" style={{ color: C.muted }}>{s.sourceId}</span> : null}
        </div>
        <AnswerList answers={s.answers} />
      </div>
    );
  }
  if (row.kind === "session" && row.session) {
    const s = row.session;
    return (
      <div className="px-3 py-2 rounded-lg text-sm flex flex-wrap gap-2" style={{ backgroundColor: C.sessionBg, color: C.sub }}>
        <span style={{ color: C.muted }}>{fmtTime(row.time)}</span>
        <strong>Session started</strong>
        <span>
          {s.durationSeconds != null ? `${(s.durationSeconds / 60).toFixed(1)} min` : "duration unknown"}
          {s.entryPoint ? ` · ${s.entryPoint}` : ""}
          {s.platform ? ` · ${s.platform}` : ""}
        </span>
        <span className="font-mono text-xs" title={s.id}>
          {shortId(s.id)}
        </span>
      </div>
    );
  }
  const e = row.event;
  const meta = e ? JSON.stringify(e.metadata) : "";
  return (
    <div className="px-3 py-1 text-sm flex flex-wrap gap-2" style={{ color: C.sub, borderBottom: `1px solid ${C.rowBorder}` }}>
      <span style={{ color: C.muted }}>{fmtTime(row.time)}</span>
      <span style={{ color: C.text }}>{row.name}</span>
      {row.feature ? <span>{row.feature}</span> : null}
      {e?.screen ? <span style={{ color: C.muted }}>{e.screen}</span> : null}
      {e?.source === "cloud_function" ? <span style={{ color: C.muted }}>(cloud)</span> : null}
      {meta && meta !== "{}" ? (
        <span className="font-mono text-xs truncate max-w-[480px]" style={{ color: C.muted }} title={meta}>
          {meta}
        </span>
      ) : null}
    </div>
  );
}
