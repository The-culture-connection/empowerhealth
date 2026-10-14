import { FileText, Download, Loader2, Calendar } from "lucide-react";
import { useState } from "react";
import { Link } from "react-router";
import { useAuth } from "../../contexts/AuthContext";
import {
  generateReport,
  exportReportAsCSV,
  exportReportAsJSON,
  exportReportKpisAsCSV,
  type ReportType,
  type ReportResult,
  type EventImplementationStatus,
} from "../../lib/reports";

function statusLabel(s: EventImplementationStatus): string {
  if (s === "needs-implementation") return "needs implementation";
  return s;
}
import { format as formatDate } from "date-fns";

const reports = [
  {
    id: "health_understanding_impact" as ReportType,
    title: "Health Understanding Impact Report",
    description: "Measures effectiveness of educational content and care planning tools",
    metrics: [
      "After Visit Summary usage",
      "Learning Module completion",
      "Know your rights views",
      "Birth Plan usage",
      "Confidence signals",
    ],
    color: "var(--lavender-500)",
    bgColor: "var(--lavender-100)",
  },
  {
    id: "self_advocacy_confidence" as ReportType,
    title: "Self Advocacy Confidence Report",
    description: "Tracks user empowerment and voice development throughout pregnancy",
    metrics: [
      "Journal reflections",
      "Know your rights views",
      "Visit summaries",
      "Helpfulness surveys",
      "Milestone check-ins",
    ],
    color: "var(--success)",
    bgColor: "var(--success-light)",
  },
  {
    id: "care_navigation_success" as ReportType,
    title: "Care Navigation Success Report",
    description: "Analyzes how well users find and access maternal healthcare resources",
    metrics: ["Feature usage", "Know your rights views", "Outcome success", "Positive vs negative patterns"],
    color: "#f59e0b",
    bgColor: "var(--warning-light)",
  },
  {
    id: "care_preparation" as ReportType,
    title: "Care Preparation Report",
    description: "Evaluates how users prepare for key pregnancy milestones",
    metrics: ["Pre-appointment use", "Know your rights views", "Labor milestone prep", "Postpartum support"],
    color: "#8b5cf6",
    bgColor: "#f3e8ff",
  },
  {
    id: "engagement_pathway" as ReportType,
    title: "Engagement Pathway Report",
    description: "Compares engagement patterns between navigator-assisted and self-directed users",
    metrics: ["Learning modules", "Know your rights views", "Provider search", "Journal", "Community", "Birth plan"],
    color: "#06b6d4",
    bgColor: "#cffafe",
  },
  {
    id: "community_support" as ReportType,
    title: "Community Support Report",
    description: "Measures peer interaction quality and community engagement levels",
    metrics: ["Peer interaction", "Support-seeking", "Content engagement"],
    color: "#ec4899",
    bgColor: "#fce7f3",
  },
  {
    id: "user_recruitment_avenues" as ReportType,
    title: "User Recruitment Avenues Report",
    description: "Breaks down where new users heard about EmpowerHealth Watch",
    metrics: ["Recruitment source mix", "Research participant count", "Missing source rate"],
    color: "#0ea5e9",
    bgColor: "#e0f2fe",
  },
];

export function Reports() {
  const { isAdmin, isResearchPartner } = useAuth();
  const [generating, setGenerating] = useState<string | null>(null);
  const [reportData, setReportData] = useState<Record<string, ReportResult>>({});
  const [error, setError] = useState("");
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date(),
  });

  async function handleGenerateReport(reportType: ReportType) {
    setGenerating(reportType);
    setError("");

    try {
      const result = await generateReport({
        reportType,
        anonymized: isResearchPartner() || !isAdmin(),
        dateRange,
      });
      setReportData({ ...reportData, [reportType]: result });
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Failed to generate report");
    } finally {
      setGenerating(null);
    }
  }

  function handleExportCsv(reportType: ReportType) {
    const data = reportData[reportType];
    if (!data) return;
    const filename = `${reportType}_${formatDate(new Date(), "yyyy-MM-dd")}.csv`;
    if (data.rows && data.rows.length > 0) {
      exportReportAsCSV(data.rows, filename);
    } else {
      exportReportKpisAsCSV(data, filename);
    }
  }

  function handleExportJson(reportType: ReportType) {
    const data = reportData[reportType];
    if (!data) return;
    const filename = `${reportType}_${formatDate(new Date(), "yyyy-MM-dd")}.json`;
    exportReportAsJSON(data, filename);
  }

  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: "var(--warm-600)" }}>
            Reports
          </h1>
          <p style={{ color: "var(--warm-400)" }}>
            Generate and export research reports on platform impact and usage
          </p>
          <p className="mt-3 text-sm rounded-xl border px-4 py-3" style={{ borderColor: "var(--lavender-200)", color: "var(--warm-600)" }}>
            For <strong>REDCap-aligned</strong>, fixed-column research datasets keyed by <code>study_id</code>, use the{" "}
            <Link to="/research" className="underline font-medium" style={{ color: "var(--eh-primary)" }}>
              Research
            </Link>{" "}
            page (structured exports). This Reports area stays for holistic PDF-style narratives built from{" "}
            <code>analytics_events</code> plus surveys.
          </p>
        </div>

        {error && (
          <div
            className="mb-4 p-4 rounded-xl"
            style={{
              backgroundColor: "#fee2e2",
              color: "#dc2626",
            }}
          >
            {error}
          </div>
        )}

        <div
          className="mb-8 p-6 rounded-2xl border"
          style={{
            backgroundColor: "white",
            borderColor: "var(--lavender-200)",
          }}
        >
          <h3 className="mb-4" style={{ color: "var(--warm-600)" }}>
            Date Range
          </h3>
          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className="block text-sm mb-2" style={{ color: "var(--warm-600)" }}>
                <Calendar className="w-4 h-4 inline mr-1" />
                Start Date
              </label>
              <input
                type="date"
                value={formatDate(dateRange.start, "yyyy-MM-dd")}
                onChange={(e) => setDateRange({ ...dateRange, start: new Date(e.target.value) })}
                className="w-full px-4 py-3 rounded-xl border"
                style={{
                  backgroundColor: "var(--warm-50)",
                  borderColor: "var(--lavender-200)",
                }}
              />
            </div>
            <div>
              <label className="block text-sm mb-2" style={{ color: "var(--warm-600)" }}>
                <Calendar className="w-4 h-4 inline mr-1" />
                End Date
              </label>
              <input
                type="date"
                value={formatDate(dateRange.end, "yyyy-MM-dd")}
                onChange={(e) => setDateRange({ ...dateRange, end: new Date(e.target.value) })}
                className="w-full px-4 py-3 rounded-xl border"
                style={{
                  backgroundColor: "var(--warm-50)",
                  borderColor: "var(--lavender-200)",
                }}
              />
            </div>
          </div>
        </div>

        <div className="grid gap-6 md:grid-cols-2">
          {reports.map((report) => {
            const data = reportData[report.id];
            const isGenerating = generating === report.id;
            const hasData = !!data;

            return (
              <div
                key={report.id}
                className="p-6 rounded-2xl border hover:shadow-lg transition-shadow"
                style={{
                  backgroundColor: "white",
                  borderColor: "var(--lavender-200)",
                }}
              >
                <div className="flex items-start gap-4 mb-4">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
                    style={{ backgroundColor: report.bgColor }}
                  >
                    <FileText className="w-6 h-6" style={{ color: report.color }} />
                  </div>
                  <div className="flex-1">
                    <h3 className="mb-1" style={{ color: "var(--warm-600)" }}>
                      {report.title}
                    </h3>
                    <p className="text-sm" style={{ color: "var(--warm-500)" }}>
                      {report.description}
                    </p>
                  </div>
                </div>

                <div className="mb-4">
                  <div className="text-sm mb-2" style={{ color: "var(--warm-600)" }}>
                    Tracked Metrics:
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {report.metrics.map((metric) => (
                      <div
                        key={metric}
                        className="px-3 py-1 rounded-lg text-xs"
                        style={{
                          backgroundColor: report.bgColor,
                          color: report.color,
                        }}
                      >
                        {metric}
                      </div>
                    ))}
                  </div>
                </div>

                {hasData && data.evidence && (
                  <div
                    className="mb-4 p-4 rounded-xl space-y-4 text-xs"
                    style={{
                      backgroundColor: "var(--lavender-50)",
                    }}
                  >
                    <section>
                      <h4 className="mb-1 font-semibold" style={{ color: "var(--warm-600)" }}>
                        A) Report summary
                      </h4>
                      <p className="leading-relaxed mb-2" style={{ color: "var(--warm-600)" }}>
                        {data.evidence.summaryParagraph}
                      </p>
                      <ul className="space-y-1" style={{ color: "var(--warm-500)" }}>
                        <li>• Users included: {data.evidence.totalUsers}</li>
                        <li>• Date range: {data.evidence.dateRangeLabel}</li>
                        <li>• Main trend: {data.evidence.mainTrend}</li>
                        {data.evidence.takeaways.map((t, i) => (
                          <li key={i}>• Takeaway: {t}</li>
                        ))}
                      </ul>
                    </section>

                    <section>
                      <h4 className="mb-2 font-semibold" style={{ color: "var(--warm-600)" }}>
                        B) Relevant events included
                      </h4>
                      <div className="max-h-40 overflow-auto border rounded-lg" style={{ borderColor: "var(--lavender-200)" }}>
                        <table className="w-full text-left border-collapse">
                          <thead>
                            <tr style={{ backgroundColor: "var(--warm-50)" }}>
                              <th className="p-2 font-medium" style={{ color: "var(--warm-600)" }}>
                                Event
                              </th>
                              <th className="p-2 font-medium" style={{ color: "var(--warm-600)" }}>
                                What it measures
                              </th>
                              <th className="p-2 font-medium whitespace-nowrap" style={{ color: "var(--warm-600)" }}>
                                Status
                              </th>
                            </tr>
                          </thead>
                          <tbody>
                            {data.evidence.eventsIncluded.map((row) => (
                              <tr key={row.eventName} style={{ borderTop: "1px solid var(--lavender-100)" }}>
                                <td className="p-2 align-top font-mono text-[11px]" style={{ color: "var(--warm-600)" }}>
                                  {row.eventName}
                                </td>
                                <td className="p-2 align-top" style={{ color: "var(--warm-500)" }}>
                                  {row.whatItMeasures}
                                </td>
                                <td className="p-2 align-top whitespace-nowrap" style={{ color: "var(--warm-600)" }}>
                                  {statusLabel(row.status)}
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </section>

                    <section>
                      <h4 className="mb-2 font-semibold" style={{ color: "var(--warm-600)" }}>
                        C) Metrics
                      </h4>
                      <div className="grid grid-cols-1 gap-1 max-h-36 overflow-y-auto">
                        {(data.evidence.metricsKpis || data.kpisList || []).map((k) => (
                          <div key={k.key}>
                            <span style={{ color: "var(--warm-500)" }}>{k.label}: </span>
                            <span style={{ color: "var(--warm-600)" }}>{String(k.value)}</span>
                          </div>
                        ))}
                      </div>
                    </section>

                    <section>
                      <h4 className="mb-2 font-semibold" style={{ color: "var(--warm-600)" }}>
                        D) Outcome signals
                      </h4>
                      <ul className="space-y-1 mb-2" style={{ color: "var(--warm-500)" }}>
                        {data.evidence.outcomeSignals.lines.map((line, i) => (
                          <li key={i}>• {line}</li>
                        ))}
                      </ul>
                      {data.evidence.outcomeSignals.moduleFeedback && (
                        <p style={{ color: "var(--warm-500)" }}>
                          ModuleFeedback: n={data.evidence.outcomeSignals.moduleFeedback.n}
                          {data.evidence.outcomeSignals.moduleFeedback.avgUnderstanding != null &&
                            `, avg understanding ${data.evidence.outcomeSignals.moduleFeedback.avgUnderstanding.toFixed(2)}`}
                        </p>
                      )}
                      {data.evidence.outcomeSignals.careSurvey && (
                        <p style={{ color: "var(--warm-500)" }}>
                          CareSurvey: n={data.evidence.outcomeSignals.careSurvey.n}
                          {data.evidence.outcomeSignals.careSurvey.avgComposite != null &&
                            `, avg composite ${data.evidence.outcomeSignals.careSurvey.avgComposite.toFixed(2)}`}
                        </p>
                      )}
                      {data.evidence.outcomeSignals.pulseAverages && data.evidence.outcomeSignals.pulseAverages.nEvents > 0 && (
                        <p style={{ color: "var(--warm-500)" }}>
                          Pulses (micro_measure / confidence_signal): n=
                          {data.evidence.outcomeSignals.pulseAverages.nEvents}
                          {data.evidence.outcomeSignals.pulseAverages.understandMeaning != null &&
                            `, avg understand_meaning ${data.evidence.outcomeSignals.pulseAverages.understandMeaning.toFixed(2)}`}
                          {data.evidence.outcomeSignals.pulseAverages.knowNextStep != null &&
                            `, know_next_step ${data.evidence.outcomeSignals.pulseAverages.knowNextStep.toFixed(2)}`}
                          {data.evidence.outcomeSignals.pulseAverages.confidence != null &&
                            `, confidence ${data.evidence.outcomeSignals.pulseAverages.confidence.toFixed(2)}`}
                        </p>
                      )}
                      {data.evidence.outcomeSignals.careNavigationOutcomes && (
                        <p style={{ color: "var(--warm-500)" }}>
                          Care navigation outcomes: n={data.evidence.outcomeSignals.careNavigationOutcomes.n}, positive
                          share {data.evidence.outcomeSignals.careNavigationOutcomes.positiveShare}
                        </p>
                      )}
                    </section>

                    <section>
                      <h4 className="mb-2 font-semibold" style={{ color: "var(--warm-600)" }}>
                        E) Interpretation / conclusions
                      </h4>
                      <ul className="space-y-1" style={{ color: "var(--warm-500)" }}>
                        {data.evidence.conclusions.map((c, i) => (
                          <li key={i}>• {c}</li>
                        ))}
                      </ul>
                    </section>

                    <section>
                      <h4 className="mb-1 font-semibold" style={{ color: "var(--warm-600)" }}>
                        F) Coverage note
                      </h4>
                      <p style={{ color: "var(--warm-500)" }}>{data.evidence.coverageNote}</p>
                    </section>

                    {data.coverageFlags && data.coverageFlags.length > 0 && (
                      <div className="pt-2 border-t" style={{ borderColor: "var(--lavender-200)" }}>
                        <h5 className="mb-1 font-semibold" style={{ color: "var(--warm-600)" }}>
                          Legacy analytics coverage flags
                        </h5>
                        <ul className="space-y-1" style={{ color: "var(--warm-500)" }}>
                          {data.coverageFlags
                            .filter((c) => c.status !== "tracked" || c.limitedInRange)
                            .slice(0, 6)
                            .map((c) => (
                              <li key={c.eventOrSource}>
                                • {c.eventOrSource} ({c.status}
                                {c.limitedInRange ? ", limited in range" : ""})
                              </li>
                            ))}
                        </ul>
                      </div>
                    )}
                  </div>
                )}
                {hasData && !data.evidence && (
                  <div
                    className="mb-4 p-4 rounded-xl"
                    style={{
                      backgroundColor: "var(--lavender-50)",
                    }}
                  >
                    <h4 className="mb-2 text-sm font-semibold" style={{ color: "var(--warm-600)" }}>
                      Key metrics
                    </h4>
                    <div className="grid grid-cols-1 gap-1 text-xs max-h-48 overflow-y-auto">
                      {(data.kpisList || []).slice(0, 8).map((k) => (
                        <div key={k.key}>
                          <span style={{ color: "var(--warm-500)" }}>{k.label}: </span>
                          <span style={{ color: "var(--warm-600)" }}>{String(k.value)}</span>
                        </div>
                      ))}
                    </div>
                    {data.insights && data.insights.length > 0 && (
                      <div className="mt-3">
                        <h5 className="mb-1 text-xs font-semibold" style={{ color: "var(--warm-600)" }}>
                          Insights
                        </h5>
                        <ul className="text-xs space-y-1" style={{ color: "var(--warm-500)" }}>
                          {data.insights.slice(0, 4).map((insight, i) => (
                            <li key={i}>• {insight}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                )}

                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={() => handleGenerateReport(report.id)}
                    disabled={isGenerating}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md disabled:opacity-50 min-w-[8rem]"
                    style={{
                      backgroundColor: report.color,
                      color: "white",
                    }}
                  >
                    {isGenerating ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Generating...
                      </>
                    ) : hasData ? (
                      "Regenerate"
                    ) : (
                      "Generate Report"
                    )}
                  </button>
                  {hasData && (
                    <>
                      <button
                        onClick={() => handleExportCsv(report.id)}
                        className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md"
                        style={{
                          backgroundColor: "var(--warm-100)",
                          color: "var(--warm-600)",
                        }}
                      >
                        <Download className="w-4 h-4" />
                        CSV
                      </button>
                      <button
                        onClick={() => handleExportJson(report.id)}
                        className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md"
                        style={{
                          backgroundColor: "var(--warm-100)",
                          color: "var(--warm-600)",
                        }}
                      >
                        <Download className="w-4 h-4" />
                        JSON
                      </button>
                    </>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <div
          className="mt-8 p-6 rounded-2xl border"
          style={{
            backgroundColor: "white",
            borderColor: "var(--lavender-200)",
          }}
        >
          <h3 className="mb-3" style={{ color: "var(--warm-600)" }}>
            Report Generation Guidelines
          </h3>
          <ul className="space-y-2 text-sm" style={{ color: "var(--warm-500)" }}>
            <li>
              • Each report uses only a whitelist of events from `analytics_events` (plus `ModuleFeedback`, `CareSurvey`,
              care navigation outcomes, or helpfulness where applicable), aligned with `/analytics/info`
            </li>
            <li>• Sections A–F summarize evidence: summary, event table with implementation status, metrics, outcome signals, deterministic conclusions, and coverage notes</li>
            <li>• Research Partners receive anonymized exports (user ids stripped from CSV rows)</li>
            <li>• JSON exports include the full `ReportResult` (including `evidence`); CSV without row-level data includes KPIs plus flattened evidence fields</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
