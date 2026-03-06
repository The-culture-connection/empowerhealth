import { FileText, Download, Loader2, Calendar } from "lucide-react";
import { useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { generateReport, exportReportAsCSV, exportReportAsJSON, ReportType } from "../../lib/reports";
import { format } from "date-fns";

const reports = [
  {
    id: "health-understanding" as ReportType,
    title: "Health Understanding Impact Report",
    description: "Measures effectiveness of educational content and care planning tools",
    metrics: [
      "After Visit Summary usage",
      "Learning Module completion",
      "Birth Plan usage",
      "Confidence signals",
    ],
    color: 'var(--lavender-500)',
    bgColor: 'var(--lavender-100)',
  },
  {
    id: "self-advocacy" as ReportType,
    title: "Self Advocacy Confidence Report",
    description: "Tracks user empowerment and voice development throughout pregnancy",
    metrics: [
      "Journal reflections",
      "Visit summaries",
      "Helpfulness surveys",
      "Milestone check-ins",
    ],
    color: 'var(--success)',
    bgColor: 'var(--success-light)',
  },
  {
    id: "care-navigation" as ReportType,
    title: "Care Navigation Success Report",
    description: "Analyzes how well users find and access maternal healthcare resources",
    metrics: [
      "Feature usage",
      "Outcome success",
      "Positive vs negative patterns",
    ],
    color: '#f59e0b',
    bgColor: 'var(--warning-light)',
  },
  {
    id: "care-preparation" as ReportType,
    title: "Care Preparation Report",
    description: "Evaluates how users prepare for key pregnancy milestones",
    metrics: [
      "Pre-appointment use",
      "Labor milestone prep",
      "Postpartum support",
    ],
    color: '#8b5cf6',
    bgColor: '#f3e8ff',
  },
  {
    id: "engagement-pathway" as ReportType,
    title: "Engagement Pathway Report",
    description: "Compares engagement patterns between navigator-assisted and self-directed users",
    metrics: [
      "Learning modules",
      "Provider search",
      "Journal",
      "Community",
      "Birth plan",
    ],
    color: '#06b6d4',
    bgColor: '#cffafe',
  },
  {
    id: "community-support" as ReportType,
    title: "Community Support Report",
    description: "Measures peer interaction quality and community engagement levels",
    metrics: ["Peer interaction", "Support-seeking", "Content engagement"],
    color: '#ec4899',
    bgColor: '#fce7f3',
  },
];

export function Reports() {
  const { isAdmin, isResearchPartner } = useAuth();
  const [generating, setGenerating] = useState<string | null>(null);
  const [reportData, setReportData] = useState<Record<string, any>>({});
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
        anonymized: !isAdmin() || false, // Research partners always anonymized
        dateRange,
      });
      setReportData({ ...reportData, [reportType]: result });
    } catch (err: any) {
      setError(err.message || "Failed to generate report");
    } finally {
      setGenerating(null);
    }
  }

  function handleExport(reportType: ReportType, format: 'csv' | 'json') {
    const data = reportData[reportType];
    if (!data) return;

    const filename = `${reportType}_${format(new Date(), 'yyyy-MM-dd')}.${format}`;

    if (format === 'csv') {
      exportReportAsCSV(data.rows || [], filename);
    } else {
      exportReportAsJSON(data, filename);
    }
  }

  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Reports
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Generate and export research reports on platform impact and usage
          </p>
        </div>

        {error && (
          <div className="mb-4 p-4 rounded-xl" style={{ 
            backgroundColor: '#fee2e2',
            color: '#dc2626',
          }}>
            {error}
          </div>
        )}

        {/* Date Range Selector */}
        <div className="mb-8 p-6 rounded-2xl border" style={{
          backgroundColor: 'white',
          borderColor: 'var(--lavender-200)',
        }}>
          <h3 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            Date Range
          </h3>
          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                <Calendar className="w-4 h-4 inline mr-1" />
                Start Date
              </label>
              <input
                type="date"
                value={format(dateRange.start, 'yyyy-MM-dd')}
                onChange={(e) => setDateRange({ ...dateRange, start: new Date(e.target.value) })}
                className="w-full px-4 py-3 rounded-xl border"
                style={{
                  backgroundColor: 'var(--warm-50)',
                  borderColor: 'var(--lavender-200)',
                }}
              />
            </div>
            <div>
              <label className="block text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
                <Calendar className="w-4 h-4 inline mr-1" />
                End Date
              </label>
              <input
                type="date"
                value={format(dateRange.end, 'yyyy-MM-dd')}
                onChange={(e) => setDateRange({ ...dateRange, end: new Date(e.target.value) })}
                className="w-full px-4 py-3 rounded-xl border"
                style={{
                  backgroundColor: 'var(--warm-50)',
                  borderColor: 'var(--lavender-200)',
                }}
              />
            </div>
          </div>
        </div>

        {/* Report Cards */}
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
                  backgroundColor: 'white',
                  borderColor: 'var(--lavender-200)',
                }}
              >
                {/* Report Header */}
                <div className="flex items-start gap-4 mb-4">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0"
                    style={{ backgroundColor: report.bgColor }}
                  >
                    <FileText className="w-6 h-6" style={{ color: report.color }} />
                  </div>
                  <div className="flex-1">
                    <h3 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                      {report.title}
                    </h3>
                    <p className="text-sm" style={{ color: 'var(--warm-500)' }}>
                      {report.description}
                    </p>
                  </div>
                </div>

                {/* Tracked Metrics */}
                <div className="mb-4">
                  <div className="text-sm mb-2" style={{ color: 'var(--warm-600)' }}>
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

                {/* Report Data Preview */}
                {hasData && (
                  <div className="mb-4 p-4 rounded-xl" style={{
                    backgroundColor: 'var(--lavender-50)',
                  }}>
                    <h4 className="mb-2 text-sm font-semibold" style={{ color: 'var(--warm-600)' }}>
                      Key Metrics
                    </h4>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      {Object.entries(data.kpis || {}).slice(0, 4).map(([key, value]) => (
                        <div key={key}>
                          <span style={{ color: 'var(--warm-500)' }}>{key}: </span>
                          <span style={{ color: 'var(--warm-600)' }}>{String(value)}</span>
                        </div>
                      ))}
                    </div>
                    {data.insights && data.insights.length > 0 && (
                      <div className="mt-3">
                        <h5 className="mb-1 text-xs font-semibold" style={{ color: 'var(--warm-600)' }}>
                          Insights:
                        </h5>
                        <ul className="text-xs space-y-1" style={{ color: 'var(--warm-500)' }}>
                          {data.insights.slice(0, 3).map((insight: string, i: number) => (
                            <li key={i}>• {insight}</li>
                          ))}
                        </ul>
                      </div>
                    )}
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex gap-2">
                  <button
                    onClick={() => handleGenerateReport(report.id)}
                    disabled={isGenerating}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md disabled:opacity-50"
                    style={{
                      backgroundColor: report.color,
                      color: 'white',
                    }}
                  >
                    {isGenerating ? (
                      <>
                        <Loader2 className="w-4 h-4 animate-spin" />
                        Generating...
                      </>
                    ) : hasData ? (
                      'Regenerate'
                    ) : (
                      'Generate Report'
                    )}
                  </button>
                  {hasData && (
                    <>
                      <button
                        onClick={() => handleExport(report.id, 'csv')}
                        className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md"
                        style={{
                          backgroundColor: 'var(--warm-100)',
                          color: 'var(--warm-600)',
                        }}
                      >
                        <Download className="w-4 h-4" />
                        CSV
                      </button>
                      <button
                        onClick={() => handleExport(report.id, 'json')}
                        className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md"
                        style={{
                          backgroundColor: 'var(--warm-100)',
                          color: 'var(--warm-600)',
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

        {/* Report Generation Info */}
        <div
          className="mt-8 p-6 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: 'var(--lavender-200)',
          }}
        >
          <h3 className="mb-3" style={{ color: 'var(--warm-600)' }}>
            Report Generation Guidelines
          </h3>
          <ul className="space-y-2 text-sm" style={{ color: 'var(--warm-500)' }}>
            <li>• Reports are generated on-demand with your selected date range</li>
            <li>• All exported data follows HIPAA de-identification standards</li>
            <li>• Research Partners can only generate anonymized reports</li>
            <li>• CSV exports provide raw data for further analysis</li>
            <li>• JSON exports include full report data with KPIs and insights</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
