import { CheckCircle2, AlertCircle, ChevronDown, ExternalLink } from "lucide-react";
import { useState } from "react";

export function TechnologyOverview() {
  const [expandedFeature, setExpandedFeature] = useState<string | null>(null);

  const features = [
    {
      id: "learning",
      name: "Learning Modules",
      status: "active",
      description: "Interactive educational content about pregnancy, birth, and postpartum care",
    },
    {
      id: "visits",
      name: "After Visit Summaries",
      status: "active",
      description: "Digital summaries of healthcare appointments with personalized information",
    },
    {
      id: "journal",
      name: "Reflective Journal",
      status: "active",
      description: "Private space for documenting thoughts, feelings, and pregnancy journey",
    },
    {
      id: "birthplan",
      name: "Birth Plan Builder",
      status: "active",
      description: "Customizable birth preferences and care plan tool",
    },
    {
      id: "community",
      name: "Community Forums",
      status: "update",
      description: "Peer support and connection with other expecting parents",
    },
    {
      id: "provider",
      name: "Provider Search",
      status: "active",
      description: "Find and connect with maternal healthcare providers",
    },
  ];

  const buildHistory = [
    { version: "v2.3.1", date: "March 1, 2026", notes: "Performance improvements, bug fixes" },
    { version: "v2.3.0", date: "February 15, 2026", notes: "New community moderation tools" },
    { version: "v2.2.5", date: "February 1, 2026", notes: "Analytics dashboard enhancements" },
    { version: "v2.2.0", date: "January 15, 2026", notes: "HIPAA compliance updates" },
  ];

  const repos = [
    { name: "empowerhealth-mobile", url: "github.com/org/mobile", branch: "main" },
    { name: "empowerhealth-api", url: "github.com/org/api", branch: "production" },
    { name: "empowerhealth-admin", url: "github.com/org/admin", branch: "main" },
  ];

  return (
    <div className="p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Technology Overview
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Platform features, version history, and technical resources
          </p>
        </div>

        {/* Current App Features */}
        <section className="mb-8">
          <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            Current App Features
          </h2>
          <div className="grid gap-4 md:grid-cols-2">
            {features.map((feature) => (
              <div
                key={feature.id}
                className="p-5 rounded-2xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: 'var(--lavender-200)',
                }}
              >
                <div className="flex items-start justify-between mb-2">
                  <div className="flex items-center gap-2">
                    {feature.status === "active" ? (
                      <CheckCircle2 className="w-5 h-5" style={{ color: 'var(--success)' }} />
                    ) : (
                      <AlertCircle className="w-5 h-5" style={{ color: 'var(--warning)' }} />
                    )}
                    <h3 style={{ color: 'var(--warm-600)' }}>{feature.name}</h3>
                  </div>
                  <button
                    onClick={() =>
                      setExpandedFeature(expandedFeature === feature.id ? null : feature.id)
                    }
                    className="p-1 rounded-lg hover:bg-opacity-10 transition-colors"
                    style={{ color: 'var(--warm-400)' }}
                  >
                    <ChevronDown
                      className={`w-4 h-4 transition-transform ${
                        expandedFeature === feature.id ? "rotate-180" : ""
                      }`}
                    />
                  </button>
                </div>

                {expandedFeature === feature.id && (
                  <p className="text-sm mt-2" style={{ color: 'var(--warm-500)' }}>
                    {feature.description}
                  </p>
                )}

                <div
                  className="inline-block px-3 py-1 rounded-full text-xs mt-3"
                  style={{
                    backgroundColor:
                      feature.status === "active" ? 'var(--success-light)' : 'var(--warning-light)',
                    color: feature.status === "active" ? 'var(--success)' : 'var(--warning)',
                  }}
                >
                  {feature.status === "active" ? "Active" : "Needs Update"}
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Build Version History */}
        <section className="mb-8">
          <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            Build Version History
          </h2>
          <div
            className="p-6 rounded-2xl border"
            style={{
              backgroundColor: 'white',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <div className="space-y-4">
              {buildHistory.map((build, index) => (
                <div
                  key={build.version}
                  className={`pb-4 ${index !== buildHistory.length - 1 ? "border-b" : ""}`}
                  style={{ borderColor: 'var(--lavender-100)' }}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium" style={{ color: 'var(--lavender-600)' }}>
                      {build.version}
                    </span>
                    <span className="text-sm" style={{ color: 'var(--warm-400)' }}>
                      {build.date}
                    </span>
                  </div>
                  <p className="text-sm" style={{ color: 'var(--warm-500)' }}>
                    {build.notes}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* GitHub Repositories */}
        <section>
          <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            GitHub Repository Links
          </h2>
          <div className="grid gap-4 md:grid-cols-3">
            {repos.map((repo) => (
              <div
                key={repo.name}
                className="p-5 rounded-2xl border hover:shadow-md transition-shadow cursor-pointer"
                style={{
                  backgroundColor: 'white',
                  borderColor: 'var(--lavender-200)',
                }}
              >
                <div className="flex items-start justify-between mb-2">
                  <h3 className="text-sm" style={{ color: 'var(--warm-600)' }}>
                    {repo.name}
                  </h3>
                  <ExternalLink className="w-4 h-4" style={{ color: 'var(--warm-400)' }} />
                </div>
                <p className="text-xs mb-2" style={{ color: 'var(--warm-400)' }}>
                  {repo.url}
                </p>
                <div
                  className="inline-block px-2 py-1 rounded-md text-xs"
                  style={{
                    backgroundColor: 'var(--lavender-100)',
                    color: 'var(--lavender-600)',
                  }}
                >
                  {repo.branch}
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
