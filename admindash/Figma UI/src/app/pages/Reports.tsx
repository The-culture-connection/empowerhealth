import { FileText, Download } from "lucide-react";

export function Reports() {
  const reports = [
    {
      id: "health-understanding",
      title: "Health Understanding Impact Report",
      description: "Measures effectiveness of educational content and care planning tools",
      metrics: [
        "After Visit Summary usage",
        "Learning Module completion",
        "Birth Plan usage",
        "Confidence signals",
      ],
      lastGenerated: "February 28, 2026",
      color: 'var(--lavender-500)',
      bgColor: 'var(--lavender-100)',
    },
    {
      id: "self-advocacy",
      title: "Self Advocacy Confidence Report",
      description: "Tracks user empowerment and voice development throughout pregnancy",
      metrics: [
        "Journal reflections",
        "Visit summaries",
        "Helpfulness surveys",
        "Milestone check-ins",
      ],
      lastGenerated: "February 28, 2026",
      color: 'var(--success)',
      bgColor: 'var(--success-light)',
    },
    {
      id: "care-navigation",
      title: "Care Navigation Success Report",
      description: "Analyzes how well users find and access maternal healthcare resources",
      metrics: [
        "Feature usage",
        "Outcome success",
        "Positive vs negative patterns",
      ],
      lastGenerated: "February 28, 2026",
      color: '#f59e0b',
      bgColor: 'var(--warning-light)',
    },
    {
      id: "care-preparation",
      title: "Care Preparation Report",
      description: "Evaluates how users prepare for key pregnancy milestones",
      metrics: [
        "Pre-appointment use",
        "Labor milestone prep",
        "Postpartum support",
      ],
      lastGenerated: "February 28, 2026",
      color: '#8b5cf6',
      bgColor: '#f3e8ff',
    },
    {
      id: "engagement-pathway",
      title: "Engagement Pathway Report",
      description: "Compares engagement patterns between navigator-assisted and self-directed users",
      metrics: [
        "Learning modules",
        "Provider search",
        "Journal",
        "Community",
        "Birth plan",
      ],
      lastGenerated: "February 28, 2026",
      color: '#06b6d4',
      bgColor: '#cffafe',
    },
    {
      id: "community-support",
      title: "Community Support Report",
      description: "Measures peer interaction quality and community engagement levels",
      metrics: ["Peer interaction", "Support-seeking", "Content engagement"],
      lastGenerated: "February 28, 2026",
      color: '#ec4899',
      bgColor: '#fce7f3',
    },
  ];

  const exportFormats = [
    { format: "CSV", icon: "📊" },
    { format: "JSON", icon: "{ }" },
    { format: "PDF", icon: "📄" },
  ];

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

        {/* Export Options Info */}
        <div
          className="mb-8 p-6 rounded-2xl border"
          style={{
            backgroundColor: 'var(--lavender-50)',
            borderColor: 'var(--lavender-200)',
          }}
        >
          <h3 className="mb-3" style={{ color: 'var(--lavender-600)' }}>
            Available Export Formats
          </h3>
          <div className="flex gap-3">
            {exportFormats.map((format) => (
              <div
                key={format.format}
                className="px-4 py-2 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: 'var(--lavender-200)',
                  color: 'var(--warm-600)',
                }}
              >
                <span className="mr-2">{format.icon}</span>
                {format.format}
              </div>
            ))}
          </div>
        </div>

        {/* Report Cards */}
        <div className="grid gap-6 md:grid-cols-2">
          {reports.map((report) => (
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

              {/* Last Generated */}
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs" style={{ color: 'var(--warm-400)' }}>
                  Last generated: {report.lastGenerated}
                </span>
              </div>

              {/* Export Buttons */}
              <div className="flex gap-2">
                {exportFormats.map((format) => (
                  <button
                    key={format.format}
                    className="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl transition-all hover:shadow-md"
                    style={{
                      backgroundColor: format.format === "PDF" ? report.color : 'var(--warm-100)',
                      color: format.format === "PDF" ? 'white' : 'var(--warm-600)',
                    }}
                  >
                    <Download className="w-4 h-4" />
                    {format.format}
                  </button>
                ))}
              </div>
            </div>
          ))}
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
            <li>• Reports are automatically generated monthly on the 1st</li>
            <li>• Custom date ranges can be requested for research purposes</li>
            <li>• All exported data follows HIPAA de-identification standards</li>
            <li>• PDF reports include visualizations and executive summaries</li>
            <li>• CSV/JSON exports provide raw data for further analysis</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
