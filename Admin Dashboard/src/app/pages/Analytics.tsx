import { useState } from "react";
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from "recharts";

export function Analytics() {
  const [activeTab, setActiveTab] = useState<"anonymized" | "unanonymized">("anonymized");

  const featureUsageData = [
    { feature: "Learning", usage: 850 },
    { feature: "Journal", usage: 720 },
    { feature: "Birth Plan", usage: 640 },
    { feature: "Visits", usage: 580 },
    { feature: "Community", usage: 520 },
    { feature: "Provider", usage: 380 },
  ];

  const engagementTrendData = [
    { month: "Sep", engaged: 420, total: 520 },
    { month: "Oct", engaged: 480, total: 580 },
    { month: "Nov", engaged: 550, total: 650 },
    { month: "Dec", engaged: 620, total: 720 },
    { month: "Jan", engaged: 680, total: 780 },
    { month: "Feb", engaged: 740, total: 850 },
  ];

  const confidenceData = [
    { stage: "Early", score: 6.2 },
    { stage: "Mid", score: 7.1 },
    { stage: "Late", score: 8.3 },
    { stage: "Birth", score: 8.8 },
    { stage: "Postpartum", score: 7.9 },
  ];

  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Analytics
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Platform usage insights and engagement metrics
          </p>
        </div>

        {/* Tab Navigation */}
        <div className="flex gap-2 mb-8">
          <button
            onClick={() => setActiveTab("anonymized")}
            className={`px-6 py-3 rounded-xl transition-all ${
              activeTab === "anonymized" ? "shadow-sm" : ""
            }`}
            style={{
              backgroundColor: activeTab === "anonymized" ? 'var(--lavender-200)' : 'var(--warm-100)',
              color: activeTab === "anonymized" ? 'var(--lavender-600)' : 'var(--warm-600)',
            }}
          >
            Anonymized Data
          </button>
          <button
            onClick={() => setActiveTab("unanonymized")}
            className={`px-6 py-3 rounded-xl transition-all ${
              activeTab === "unanonymized" ? "shadow-sm" : ""
            }`}
            style={{
              backgroundColor: activeTab === "unanonymized" ? 'var(--lavender-200)' : 'var(--warm-100)',
              color: activeTab === "unanonymized" ? 'var(--lavender-600)' : 'var(--warm-600)',
            }}
          >
            Unanonymized Data
          </button>
        </div>

        {activeTab === "anonymized" && (
          <div className="space-y-8">
            {/* Feature Usage */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <h2 className="mb-6" style={{ color: 'var(--warm-600)' }}>
                Feature Usage
              </h2>
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={featureUsageData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--lavender-200)" />
                  <XAxis dataKey="feature" stroke="var(--warm-500)" />
                  <YAxis stroke="var(--warm-500)" />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'white',
                      border: '1px solid var(--lavender-200)',
                      borderRadius: '12px',
                    }}
                  />
                  <Bar dataKey="usage" fill="var(--lavender-400)" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* Engagement Trends */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <h2 className="mb-6" style={{ color: 'var(--warm-600)' }}>
                Engagement Trends
              </h2>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={engagementTrendData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--lavender-200)" />
                  <XAxis dataKey="month" stroke="var(--warm-500)" />
                  <YAxis stroke="var(--warm-500)" />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'white',
                      border: '1px solid var(--lavender-200)',
                      borderRadius: '12px',
                    }}
                  />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="engaged"
                    stroke="var(--lavender-500)"
                    strokeWidth={3}
                    dot={{ fill: 'var(--lavender-500)', r: 5 }}
                    name="Engaged Users"
                  />
                  <Line
                    type="monotone"
                    dataKey="total"
                    stroke="var(--warm-400)"
                    strokeWidth={2}
                    strokeDasharray="5 5"
                    dot={{ fill: 'var(--warm-400)', r: 4 }}
                    name="Total Users"
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Confidence Signals */}
            <div
              className="p-6 rounded-2xl border"
              style={{
                backgroundColor: 'white',
                borderColor: 'var(--lavender-200)',
              }}
            >
              <h2 className="mb-6" style={{ color: 'var(--warm-600)' }}>
                Confidence Signals
              </h2>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={confidenceData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="var(--lavender-200)" />
                  <XAxis dataKey="stage" stroke="var(--warm-500)" />
                  <YAxis domain={[0, 10]} stroke="var(--warm-500)" />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'white',
                      border: '1px solid var(--lavender-200)',
                      borderRadius: '12px',
                    }}
                  />
                  <Line
                    type="monotone"
                    dataKey="score"
                    stroke="var(--success)"
                    strokeWidth={3}
                    dot={{ fill: 'var(--success)', r: 6 }}
                    name="Confidence Score"
                  />
                </LineChart>
              </ResponsiveContainer>
              <div className="mt-4 p-4 rounded-xl" style={{ backgroundColor: 'var(--lavender-50)' }}>
                <p className="text-sm" style={{ color: 'var(--warm-600)' }}>
                  Average confidence scores across pregnancy journey stages (scale 1-10)
                </p>
              </div>
            </div>

            {/* Summary Stats */}
            <div className="grid gap-6 md:grid-cols-4">
              {[
                { label: "Active Users", value: "850", change: "+12%" },
                { label: "Avg. Session", value: "18min", change: "+5%" },
                { label: "Completion Rate", value: "73%", change: "+8%" },
                { label: "Retention (30d)", value: "68%", change: "+3%" },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="p-6 rounded-2xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                >
                  <div className="text-sm mb-2" style={{ color: 'var(--warm-500)' }}>
                    {stat.label}
                  </div>
                  <div className="text-2xl mb-1" style={{ color: 'var(--warm-600)' }}>
                    {stat.value}
                  </div>
                  <div className="text-sm" style={{ color: 'var(--success)' }}>
                    {stat.change}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {activeTab === "unanonymized" && (
          <div
            className="p-12 rounded-2xl border text-center"
            style={{
              backgroundColor: 'var(--lavender-50)',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <h2 className="mb-4" style={{ color: 'var(--lavender-600)' }}>
              Unanonymized Data Access
            </h2>
            <p className="mb-6 max-w-2xl mx-auto" style={{ color: 'var(--warm-500)' }}>
              Access to personally identifiable information requires additional authentication and is
              logged for compliance purposes. This data view is restricted to Admin roles only.
            </p>
            <button
              className="px-6 py-3 rounded-xl shadow-sm hover:shadow-md transition-all"
              style={{
                backgroundColor: 'var(--lavender-500)',
                color: 'white',
              }}
            >
              Request Access
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
