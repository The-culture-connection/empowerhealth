import { useState, useEffect, useMemo } from "react";
import { collection, doc, getDocs, onSnapshot, query, where, Timestamp } from "firebase/firestore";
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { Link } from "react-router";
import { Download, Users, Clock, Activity, TrendingUp, Target, AlertTriangle, Loader2 } from "lucide-react";
import { firestore, auth } from "../../firebase/firebase";

type DateRangeKey = "7d" | "30d" | "90d" | "all";

type RawEvent = {
  id: string;
  eventName: string;
  feature: string;
  durationMs: number | null;
  timestamp: Date | null;
  source: string;
  metadata?: Record<string, unknown>;
  uid?: string;
  anonUserId?: string;
};

function tsToDate(v: unknown): Date | null {
  if (v instanceof Timestamp) return v.toDate();
  if (v && typeof v === "object" && "toDate" in (v as any)) return (v as any).toDate();
  if (typeof v === "string" || typeof v === "number") {
    const d = new Date(v);
    if (!Number.isNaN(d.getTime())) return d;
  }
  return null;
}

function fmtShortDate(d: Date): string {
  return `${d.getMonth() + 1}/${d.getDate()}`;
}

function toCsvRow(values: Array<string | number | null>): string {
  return values
    .map((v) => {
      const s = v == null ? "" : String(v);
      return `"${s.replace(/"/g, '""')}"`;
    })
    .join(",");
}

export function Analytics() {
  const [dateRange, setDateRange] = useState<DateRangeKey>("30d");
  const [selectedFeature, setSelectedFeature] = useState<string>("all");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [events, setEvents] = useState<RawEvent[]>([]);
  const [liveGlobalSummary, setLiveGlobalSummary] = useState<Record<string, unknown> | null>(null);

  useEffect(() => {
    const ref = doc(firestore, "analytics_summary", "global");
    const unsub = onSnapshot(
      ref,
      (snap) => setLiveGlobalSummary(snap.exists() ? (snap.data() as Record<string, unknown>) : null),
      () => setLiveGlobalSummary(null),
    );
    return () => unsub();
  }, []);

  useEffect(() => {
    async function loadEvents() {
      setLoading(true);
      setError("");
      try {
        const user = auth.currentUser;
        if (user) {
          await user.getIdToken(true);
        }

        const eventsRef = collection(firestore, "analytics_events");
        let q = query(eventsRef);
        if (dateRange !== "all") {
          const days = dateRange === "7d" ? 7 : dateRange === "30d" ? 30 : 90;
          const start = new Date();
          start.setDate(start.getDate() - days);
          q = query(eventsRef, where("timestamp", ">=", Timestamp.fromDate(start)));
        }

        const snap = await getDocs(q);
        const parsed: RawEvent[] = snap.docs.map((d) => {
          const data = d.data();
          return {
            id: d.id,
            eventName: String(data.eventName || "unknown"),
            feature: String(data.feature || "unknown"),
            durationMs: typeof data.durationMs === "number" ? data.durationMs : null,
            timestamp: tsToDate(data.timestamp),
            source: String(data.source || "unknown"),
            metadata: (data.metadata || {}) as Record<string, unknown>,
            uid: typeof data.uid === "string" ? data.uid : undefined,
            anonUserId: typeof data.anonUserId === "string" ? data.anonUserId : undefined,
          };
        });
        parsed.sort((a, b) => (b.timestamp?.getTime() || 0) - (a.timestamp?.getTime() || 0));
        setEvents(parsed);
      } catch (e: any) {
        setError(e?.message || "Failed to load analytics events");
        setEvents([]);
      } finally {
        setLoading(false);
      }
    }
    void loadEvents();
  }, [dateRange]);

  const featureOptions = useMemo(() => {
    const features = Array.from(new Set(events.map((e) => e.feature))).sort();
    return ["all", ...features];
  }, [events]);

  const filteredEvents = useMemo(
    () => (selectedFeature === "all" ? events : events.filter((e) => e.feature === selectedFeature)),
    [events, selectedFeature],
  );

  const metrics = useMemo(() => {
    const sessionStarted = filteredEvents.filter((e) => e.eventName === "session_started").length;
    const flowAbandoned = filteredEvents.filter((e) => e.eventName === "flow_abandoned").length;

    const users = new Set(
      filteredEvents.map((e) => e.anonUserId || e.uid).filter((v): v is string => Boolean(v)),
    );

    const sessionEndedDurMs = filteredEvents
      .filter((e) => e.eventName === "session_ended")
      .map((e) => {
        const m = e.metadata || {};
        if (typeof m.duration_seconds === "number") return m.duration_seconds * 1000;
        return e.durationMs ?? null;
      })
      .filter((v): v is number => v != null && v > 0);
    const avgSessionMs =
      sessionEndedDurMs.length > 0
        ? sessionEndedDurMs.reduce((a, b) => a + b, 0) / sessionEndedDurMs.length
        : 0;

    const byUserCount: Record<string, number> = {};
    filteredEvents.forEach((e) => {
      const k = e.anonUserId || e.uid;
      if (!k) return;
      byUserCount[k] = (byUserCount[k] || 0) + 1;
    });
    const engagedUsers = Object.values(byUserCount).filter((c) => c >= 3).length;
    const returningUsers = Object.values(byUserCount).filter((c) => c > 1).length;

    return {
      totalSessions: sessionStarted,
      activeUsers: users.size,
      avgSessionMinutes: avgSessionMs > 0 ? avgSessionMs / 60000 : 0,
      engagementRate: users.size > 0 ? (engagedUsers / users.size) * 100 : 0,
      retentionRate: users.size > 0 ? (returningUsers / users.size) * 100 : 0,
      abandonmentRate: sessionStarted > 0 ? (flowAbandoned / sessionStarted) * 100 : 0,
    };
  }, [filteredEvents]);

  const featureUsageData = useMemo(() => {
    const byFeature: Record<string, { sessions: number; completions: number; durations: number[] }> = {};
    filteredEvents.forEach((e) => {
      const f = e.feature;
      if (!byFeature[f]) byFeature[f] = { sessions: 0, completions: 0, durations: [] };
      byFeature[f].sessions += 1;
      if (e.eventName.includes("completed") || e.eventName.includes("created")) {
        byFeature[f].completions += 1;
      }
      if (typeof e.durationMs === "number" && e.durationMs > 0) {
        byFeature[f].durations.push(e.durationMs);
      }
    });
    return Object.entries(byFeature)
      .map(([feature, v]) => ({
        feature,
        sessions: v.sessions,
        completions: v.completions,
        avgTime: v.durations.length > 0 ? v.durations.reduce((a, b) => a + b, 0) / v.durations.length / 60000 : 0,
      }))
      .sort((a, b) => b.sessions - a.sessions);
  }, [filteredEvents]);

  const learningFunnelData = useMemo(() => {
    const steps = [
      "learning_module_viewed",
      "learning_module_started",
      "learning_module_quiz_submitted",
      "learning_module_completed",
    ];
    const counts = steps.map((s) => filteredEvents.filter((e) => e.eventName === s).length);
    const base = counts[0] || 1;
    return [
      { stage: "Viewed", count: counts[0], percentage: (counts[0] / base) * 100 },
      { stage: "Started", count: counts[1], percentage: (counts[1] / base) * 100 },
      { stage: "Quiz Submitted", count: counts[2], percentage: (counts[2] / base) * 100 },
      { stage: "Completed", count: counts[3], percentage: (counts[3] / base) * 100 },
    ];
  }, [filteredEvents]);

  const providerFunnelData = useMemo(() => {
    const steps = [
      "provider_search_initiated",
      "provider_profile_viewed",
      "provider_contact_clicked",
      "provider_selected_success",
    ];
    const counts = steps.map((s) => filteredEvents.filter((e) => e.eventName === s).length);
    const base = counts[0] || 1;
    return [
      { stage: "Search Initiated", count: counts[0], percentage: (counts[0] / base) * 100 },
      { stage: "Profile Viewed", count: counts[1], percentage: (counts[1] / base) * 100 },
      { stage: "Contact Clicked", count: counts[2], percentage: (counts[2] / base) * 100 },
      { stage: "Provider Selected", count: counts[3], percentage: (counts[3] / base) * 100 },
    ];
  }, [filteredEvents]);

  const engagementOverTimeData = useMemo(() => {
    const byWeek: Record<string, { sessions: number; screenViews: number; featureTime: number }> = {};
    filteredEvents.forEach((e) => {
      if (!e.timestamp) return;
      const d = new Date(e.timestamp);
      const first = new Date(d.getFullYear(), 0, 1);
      const weekNo = Math.ceil(((d.getTime() - first.getTime()) / 86400000 + first.getDay() + 1) / 7);
      const k = `${d.getFullYear()}-W${weekNo}`;
      if (!byWeek[k]) byWeek[k] = { sessions: 0, screenViews: 0, featureTime: 0 };
      if (e.eventName === "session_started") byWeek[k].sessions += 1;
      if (e.eventName === "screen_view") byWeek[k].screenViews += 1;
      if (e.eventName === "feature_time_spent") byWeek[k].featureTime += 1;
    });
    return Object.entries(byWeek)
      .sort(([a], [b]) => a.localeCompare(b))
      .slice(-6)
      .map(([date, v]) => ({ date, ...v }));
  }, [filteredEvents]);

  const communityData = useMemo(
    () => [
      { metric: "Posts Created", count: filteredEvents.filter((e) => e.eventName === "community_post_created").length },
      { metric: "Replies", count: filteredEvents.filter((e) => e.eventName === "community_post_replied").length },
      { metric: "Likes", count: filteredEvents.filter((e) => e.eventName === "community_post_liked").length },
    ],
    [filteredEvents],
  );

  const moodData = useMemo(() => {
    const map: Record<string, number> = {};
    filteredEvents
      .filter((e) => e.eventName === "journal_mood_selected")
      .forEach((e) => {
        const mood = String((e.metadata?.mood_type as string) || "unknown");
        map[mood] = (map[mood] || 0) + 1;
      });
    const colors = ["#4caf50", "#9e9e9e", "#ff9800", "#f44336", "#9575cd"];
    return Object.entries(map).map(([mood, count], i) => ({ mood, count, color: colors[i % colors.length] }));
  }, [filteredEvents]);

  const outcomeSignalsData = useMemo(() => {
    const weekAgg: Record<string, { confidence: number[]; understanding: number[] }> = {};
    filteredEvents
      .filter((e) => e.eventName === "micro_measure_submitted" || e.eventName === "confidence_signal_submitted")
      .forEach((e) => {
        const t = e.timestamp ? fmtShortDate(e.timestamp) : "unknown";
        if (!weekAgg[t]) weekAgg[t] = { confidence: [], understanding: [] };
        const c = e.metadata?.confidence_score;
        const u = e.metadata?.understand_meaning_score;
        if (typeof c === "number") weekAgg[t].confidence.push(c);
        if (typeof u === "number") weekAgg[t].understanding.push(u);
      });
    return Object.entries(weekAgg)
      .map(([week, v]) => ({
        week,
        confidence: v.confidence.length ? v.confidence.reduce((a, b) => a + b, 0) / v.confidence.length : 0,
        understanding: v.understanding.length ? v.understanding.reduce((a, b) => a + b, 0) / v.understanding.length : 0,
      }))
      .slice(-6);
  }, [filteredEvents]);

  const abandonmentData = useMemo(() => {
    const map: Record<string, number> = {};
    filteredEvents
      .filter((e) => e.eventName === "flow_abandoned")
      .forEach((e) => {
        const flow = String((e.metadata?.flow_name as string) || e.feature || "unknown");
        map[flow] = (map[flow] || 0) + 1;
      });
    const sessions = filteredEvents.filter((e) => e.eventName === "session_started").length || 1;
    return Object.entries(map).map(([flow, count]) => ({ flow, abandonmentRate: (count / sessions) * 100 }));
  }, [filteredEvents]);

  const screenTimeData = useMemo(() => {
    const map: Record<string, { durations: number[]; sessions: number }> = {};
    filteredEvents
      .filter((e) => e.eventName === "screen_time_spent")
      .forEach((e) => {
        const screen = String((e.metadata?.screen_name as string) || "unknown");
        if (!map[screen]) map[screen] = { durations: [], sessions: 0 };
        map[screen].sessions += 1;
        const s = e.metadata?.time_spent_seconds;
        if (typeof s === "number") map[screen].durations.push(s);
      });
    return Object.entries(map).map(([screen, v]) => ({
      screen,
      avgTime: v.durations.length ? v.durations.reduce((a, b) => a + b, 0) / v.durations.length / 60 : 0,
      sessions: v.sessions,
    }));
  }, [filteredEvents]);

  function exportRawEventsCsv() {
    const headers = ["eventName", "feature", "duration", "timestamp", "source"];
    const rows = filteredEvents.map((e) =>
      toCsvRow([
        e.eventName,
        e.feature,
        e.durationMs ?? "",
        e.timestamp ? e.timestamp.toISOString() : "",
        e.source,
      ]),
    );
    const csv = [toCsvRow(headers), ...rows].join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `analytics-events-${dateRange}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  const retentionStr = `${metrics.retentionRate.toFixed(1)}%`;
  const engagementStr = `${metrics.engagementRate.toFixed(1)}%`;
  const abandonStr = `${metrics.abandonmentRate.toFixed(1)}%`;
  const avgSessionStr = `${metrics.avgSessionMinutes.toFixed(1)}m`;

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl mb-2" style={{ color: "#424242" }}>
            Research Analytics
          </h1>
          <p className="text-base" style={{ color: "#616161" }}>
            Event tracking, user behavior, and outcome measurement
          </p>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value as DateRangeKey)}
            className="px-4 py-2 rounded-lg border text-sm"
            style={{ backgroundColor: "white", borderColor: "#e0e0e0", color: "#424242" }}
          >
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
            <option value="90d">Last 90 days</option>
            <option value="all">All time</option>
          </select>
          <select
            value={selectedFeature}
            onChange={(e) => setSelectedFeature(e.target.value)}
            className="px-4 py-2 rounded-lg border text-sm"
            style={{ backgroundColor: "white", borderColor: "#e0e0e0", color: "#424242" }}
          >
            {featureOptions.map((f) => (
              <option key={f} value={f}>
                {f === "all" ? "All features" : f}
              </option>
            ))}
          </select>
          <button
            className="px-4 py-2 rounded-lg border flex items-center gap-2 text-sm transition-colors"
            style={{ backgroundColor: "#9575cd", borderColor: "#9575cd", color: "white" }}
            onClick={exportRawEventsCsv}
          >
            <Download className="w-4 h-4" />
            Export Data
          </button>
          <Link
            to="/analytics/info"
            className="px-4 py-2 rounded-lg text-sm"
            style={{ backgroundColor: "#ede7f6", color: "#7e57c2" }}
          >
            Analytics Info
          </Link>
        </div>
      </div>

      {liveGlobalSummary && typeof liveGlobalSummary.totalEvents === "number" && (
        <div className="mb-6 p-4 rounded-xl border text-sm" style={{ backgroundColor: "#f3e5f5", borderColor: "#e0e0e0", color: "#424242" }}>
          <strong>Realtime summary:</strong> {(liveGlobalSummary.totalEvents as number).toLocaleString()} total events, last{" "}
          {liveGlobalSummary.lastEventName ? String(liveGlobalSummary.lastEventName) : "—"}.
        </div>
      )}

      {error && (
        <div className="mb-4 p-4 rounded-xl" style={{ backgroundColor: "#fee2e2", color: "#dc2626" }}>
          {error}
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin" style={{ color: "#9575cd" }} />
        </div>
      ) : (
        <>
          <div className="grid gap-6 md:grid-cols-3 lg:grid-cols-6 mb-8">
            {[
              { icon: Activity, label: "Total Sessions", value: metrics.totalSessions.toLocaleString() },
              { icon: Users, label: "Active Users", value: metrics.activeUsers.toLocaleString() },
              { icon: Clock, label: "Avg Session", value: avgSessionStr },
              { icon: TrendingUp, label: "Engagement Rate", value: engagementStr },
              { icon: Target, label: "30d Retention", value: retentionStr },
              { icon: AlertTriangle, label: "Abandonment", value: abandonStr },
            ].map((m) => (
              <div key={m.label} className="p-5 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
                <div className="flex items-center gap-2 mb-2">
                  <m.icon className="w-4 h-4" style={{ color: "#9575cd" }} />
                  <div className="text-xs" style={{ color: "#757575" }}>
                    {m.label}
                  </div>
                </div>
                <div className="text-2xl mb-1" style={{ color: "#424242" }}>
                  {m.value}
                </div>
              </div>
            ))}
          </div>

          <div className="p-8 rounded-2xl border mb-8" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
            <div className="mb-6">
              <h2 className="text-xl mb-2" style={{ color: "#424242" }}>
                Feature Usage Analysis
              </h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr style={{ borderBottom: "2px solid #e0e0e0" }}>
                    <th className="text-left py-3 px-4 text-sm" style={{ color: "#757575" }}>Feature</th>
                    <th className="text-right py-3 px-4 text-sm" style={{ color: "#757575" }}>Sessions</th>
                    <th className="text-right py-3 px-4 text-sm" style={{ color: "#757575" }}>Completions</th>
                    <th className="text-right py-3 px-4 text-sm" style={{ color: "#757575" }}>Completion Rate</th>
                    <th className="text-right py-3 px-4 text-sm" style={{ color: "#757575" }}>Avg Time (min)</th>
                  </tr>
                </thead>
                <tbody>
                  {featureUsageData.map((f) => {
                    const rate = f.sessions > 0 ? (f.completions / f.sessions) * 100 : 0;
                    return (
                      <tr key={f.feature} style={{ borderBottom: "1px solid #f5f5f5" }}>
                        <td className="py-4 px-4 text-sm" style={{ color: "#424242" }}>{f.feature}</td>
                        <td className="text-right py-4 px-4 text-sm" style={{ color: "#616161" }}>{f.sessions.toLocaleString()}</td>
                        <td className="text-right py-4 px-4 text-sm" style={{ color: "#616161" }}>{f.completions.toLocaleString()}</td>
                        <td className="text-right py-4 px-4 text-sm" style={{ color: "#616161" }}>{rate.toFixed(1)}%</td>
                        <td className="text-right py-4 px-4 text-sm" style={{ color: "#616161" }}>{f.avgTime.toFixed(1)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>

          <div className="grid gap-6 md:grid-cols-2 mb-8">
            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Learning Module Journey</h3>
              <div className="space-y-3">
                {learningFunnelData.map((s) => (
                  <div key={s.stage}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm" style={{ color: "#616161" }}>{s.stage}</span>
                      <span className="text-sm" style={{ color: "#424242" }}>{s.count.toLocaleString()} ({s.percentage.toFixed(1)}%)</span>
                    </div>
                    <div className="h-2 rounded-full" style={{ backgroundColor: "#f5f5f5" }}>
                      <div className="h-2 rounded-full" style={{ width: `${Math.max(0, Math.min(100, s.percentage))}%`, backgroundColor: "#9575cd" }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Provider Search Journey</h3>
              <div className="space-y-3">
                {providerFunnelData.map((s) => (
                  <div key={s.stage}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm" style={{ color: "#616161" }}>{s.stage}</span>
                      <span className="text-sm" style={{ color: "#424242" }}>{s.count.toLocaleString()} ({s.percentage.toFixed(1)}%)</span>
                    </div>
                    <div className="h-2 rounded-full" style={{ backgroundColor: "#f5f5f5" }}>
                      <div className="h-2 rounded-full" style={{ width: `${Math.max(0, Math.min(100, s.percentage))}%`, backgroundColor: "#9575cd" }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="grid gap-6 md:grid-cols-2 mb-8">
            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Engagement Trends</h3>
              <ResponsiveContainer width="100%" height={280}>
                <LineChart data={engagementOverTimeData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
                  <XAxis dataKey="date" stroke="#9e9e9e" style={{ fontSize: "12px" }} />
                  <YAxis stroke="#9e9e9e" style={{ fontSize: "12px" }} />
                  <Tooltip />
                  <Legend wrapperStyle={{ fontSize: "12px" }} />
                  <Line type="monotone" dataKey="sessions" stroke="#9575cd" strokeWidth={2} name="Sessions" />
                  <Line type="monotone" dataKey="screenViews" stroke="#7e57c2" strokeWidth={2} name="Screen Views" />
                </LineChart>
              </ResponsiveContainer>
            </div>

            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Community Engagement</h3>
              <div className="space-y-4">
                {communityData.map((i) => (
                  <div key={i.metric}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm" style={{ color: "#616161" }}>{i.metric}</span>
                      <span className="text-lg" style={{ color: "#424242" }}>{i.count.toLocaleString()}</span>
                    </div>
                    <div className="h-2 rounded-full" style={{ backgroundColor: "#f5f5f5" }}>
                      <div className="h-2 rounded-full" style={{ width: `${Math.min(100, (i.count / 5000) * 100)}%`, backgroundColor: "#9575cd" }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="grid gap-6 md:grid-cols-2 mb-8">
            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Journal Mood Distribution</h3>
              <div className="space-y-4">
                {moodData.map((m) => {
                  const total = moodData.reduce((sum, x) => sum + x.count, 0) || 1;
                  const p = (m.count / total) * 100;
                  return (
                    <div key={m.mood}>
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-sm" style={{ color: "#616161" }}>{m.mood}</span>
                        <span className="text-sm" style={{ color: "#424242" }}>{m.count} ({p.toFixed(1)}%)</span>
                      </div>
                      <div className="h-2 rounded-full" style={{ backgroundColor: "#f5f5f5" }}>
                        <div className="h-2 rounded-full" style={{ width: `${p}%`, backgroundColor: m.color }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Outcome Signals</h3>
              <ResponsiveContainer width="100%" height={240}>
                <LineChart data={outcomeSignalsData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
                  <XAxis dataKey="week" stroke="#9e9e9e" style={{ fontSize: "12px" }} />
                  <YAxis domain={[0, 10]} stroke="#9e9e9e" style={{ fontSize: "12px" }} />
                  <Tooltip />
                  <Legend wrapperStyle={{ fontSize: "12px" }} />
                  <Line type="monotone" dataKey="confidence" stroke="#2e7d32" strokeWidth={2} name="Confidence Score" />
                  <Line type="monotone" dataKey="understanding" stroke="#1976d2" strokeWidth={2} name="Understanding Score" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="grid gap-6 md:grid-cols-2 mb-8">
            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Flow Abandonment Rates</h3>
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={abandonmentData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
                  <XAxis type="number" stroke="#9e9e9e" style={{ fontSize: "12px" }} />
                  <YAxis dataKey="flow" type="category" width={120} stroke="#9e9e9e" style={{ fontSize: "12px" }} />
                  <Tooltip />
                  <Bar dataKey="abandonmentRate" fill="#f57c00" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            <div className="p-8 rounded-2xl border" style={{ backgroundColor: "white", borderColor: "#e0e0e0" }}>
              <h3 className="text-lg mb-6" style={{ color: "#424242" }}>Screen Time Distribution</h3>
              <div className="space-y-4">
                {screenTimeData.map((s) => (
                  <div key={s.screen}>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm" style={{ color: "#616161" }}>{s.screen}</span>
                      <span className="text-sm" style={{ color: "#424242" }}>
                        {s.avgTime.toFixed(1)}m avg / {s.sessions} sessions
                      </span>
                    </div>
                    <div className="h-2 rounded-full" style={{ backgroundColor: "#f5f5f5" }}>
                      <div className="h-2 rounded-full" style={{ width: `${Math.min(100, (s.avgTime / 20) * 100)}%`, backgroundColor: "#7e57c2" }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
