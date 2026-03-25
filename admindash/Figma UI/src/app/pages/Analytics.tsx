import { useState } from "react";
import { BarChart, Bar, LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend, PieChart, Pie, Cell, AreaChart, Area } from "recharts";
import { Download, Users, Clock, Activity, TrendingUp, BookOpen, MapPin, FileText, MessageCircle, Heart, Target, AlertTriangle } from "lucide-react";

export function Analytics() {
  const [dateRange, setDateRange] = useState("30d");
  const [selectedFeature, setSelectedFeature] = useState("all");

  // Overview Metrics
  const overviewMetrics = {
    totalSessions: 12453,
    activeUsers: 850,
    avgSessionDuration: 18.2, // minutes
    engagementRate: 73.4,
    retention30d: 68.2,
    flowAbandonmentRate: 14.3,
  };

  // Feature Usage Data
  const featureUsageData = [
    { feature: "Learning Modules", sessions: 3421, completions: 2890, avgTime: 12.3 },
    { feature: "Provider Search", sessions: 2156, completions: 1834, avgTime: 8.7 },
    { feature: "Journal", sessions: 2987, completions: 2654, avgTime: 6.4 },
    { feature: "Visit Summary", sessions: 1823, completions: 1721, avgTime: 9.2 },
    { feature: "Birth Plan", sessions: 1642, completions: 1523, avgTime: 15.6 },
    { feature: "Community", sessions: 1873, completions: 1456, avgTime: 11.8 },
  ];

  // Learning Module Funnel
  const learningFunnelData = [
    { stage: "Viewed", count: 3421, percentage: 100 },
    { stage: "Started", count: 3124, percentage: 91.3 },
    { stage: "Quiz Submitted", count: 2998, percentage: 87.6 },
    { stage: "Completed", count: 2890, percentage: 84.5 },
  ];

  // Provider Search Funnel
  const providerFunnelData = [
    { stage: "Search Initiated", count: 2156, percentage: 100 },
    { stage: "Profile Viewed", count: 1987, percentage: 92.2 },
    { stage: "Contact Clicked", count: 1923, percentage: 89.2 },
    { stage: "Provider Selected", count: 1834, percentage: 85.1 },
  ];

  // Time-based engagement
  const engagementOverTimeData = [
    { date: "Week 1", sessions: 2023, screenViews: 8912, featureTime: 4321 },
    { date: "Week 2", sessions: 2156, screenViews: 9234, featureTime: 4567 },
    { date: "Week 3", sessions: 2301, screenViews: 9876, featureTime: 4823 },
    { date: "Week 4", sessions: 2498, screenViews: 10234, featureTime: 5142 },
  ];

  // Community Engagement
  const communityData = [
    { metric: "Posts Created", count: 542 },
    { metric: "Replies", count: 1834 },
    { metric: "Likes", count: 4521 },
  ];

  // Mood Distribution
  const moodData = [
    { mood: "Positive", count: 2341, color: "#4caf50" },
    { mood: "Neutral", count: 1823, color: "#9e9e9e" },
    { mood: "Anxious", count: 987, color: "#ff9800" },
    { mood: "Overwhelmed", count: 432, color: "#f44336" },
  ];

  // Confidence & Understanding Signals
  const outcomeSignalsData = [
    { week: "Week 1", confidence: 6.2, understanding: 6.8 },
    { week: "Week 2", confidence: 6.7, understanding: 7.1 },
    { week: "Week 3", confidence: 7.3, understanding: 7.6 },
    { week: "Week 4", confidence: 7.8, understanding: 8.2 },
  ];

  // Abandonment Analysis
  const abandonmentData = [
    { flow: "Learning Module", abandonmentRate: 15.5 },
    { flow: "Provider Search", abandonmentRate: 14.9 },
    { flow: "Birth Plan", abandonmentRate: 7.2 },
    { flow: "Visit Summary", abandonmentRate: 5.6 },
    { flow: "Community Post", abandonmentRate: 22.3 },
  ];

  // Screen Time Distribution
  const screenTimeData = [
    { screen: "Learning Hub", avgTime: 12.3, sessions: 3421 },
    { screen: "Provider Directory", avgTime: 8.7, sessions: 2156 },
    { screen: "Journal View", avgTime: 6.4, sessions: 2987 },
    { screen: "Community Feed", avgTime: 11.8, sessions: 1873 },
    { screen: "Birth Plan Editor", avgTime: 15.6, sessions: 1642 },
  ];

  return (
    <div>
      {/* Header with Export */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl mb-2" style={{ color: '#424242' }}>
            Research Analytics
          </h1>
          <p className="text-base" style={{ color: '#616161' }}>
            Event tracking, user behavior, and outcome measurement
          </p>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={dateRange}
            onChange={(e) => setDateRange(e.target.value)}
            className="px-4 py-2 rounded-lg border text-sm"
            style={{
              backgroundColor: 'white',
              borderColor: '#e0e0e0',
              color: '#424242',
            }}
          >
            <option value="7d">Last 7 days</option>
            <option value="30d">Last 30 days</option>
            <option value="90d">Last 90 days</option>
            <option value="all">All time</option>
          </select>
          <button
            className="px-4 py-2 rounded-lg border flex items-center gap-2 text-sm transition-colors"
            style={{
              backgroundColor: '#9575cd',
              borderColor: '#9575cd',
              color: 'white',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#7e57c2')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#9575cd')}
          >
            <Download className="w-4 h-4" />
            Export Data
          </button>
        </div>
      </div>

      {/* Overview Metrics */}
      <div className="grid gap-6 md:grid-cols-3 lg:grid-cols-6 mb-8">
        <div
          className="p-5 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <Activity className="w-4 h-4" style={{ color: '#9575cd' }} />
            <div className="text-xs" style={{ color: '#757575' }}>Total Sessions</div>
          </div>
          <div className="text-2xl mb-1" style={{ color: '#424242' }}>
            {overviewMetrics.totalSessions.toLocaleString()}
          </div>
          <div className="text-xs" style={{ color: '#2e7d32' }}>+18% vs prev period</div>
        </div>

        <div
          className="p-5 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <Users className="w-4 h-4" style={{ color: '#9575cd' }} />
            <div className="text-xs" style={{ color: '#757575' }}>Active Users</div>
          </div>
          <div className="text-2xl mb-1" style={{ color: '#424242' }}>
            {overviewMetrics.activeUsers}
          </div>
          <div className="text-xs" style={{ color: '#2e7d32' }}>+12% vs prev period</div>
        </div>

        <div
          className="p-5 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <Clock className="w-4 h-4" style={{ color: '#9575cd' }} />
            <div className="text-xs" style={{ color: '#757575' }}>Avg Session</div>
          </div>
          <div className="text-2xl mb-1" style={{ color: '#424242' }}>
            {overviewMetrics.avgSessionDuration}m
          </div>
          <div className="text-xs" style={{ color: '#2e7d32' }}>+5% vs prev period</div>
        </div>

        <div
          className="p-5 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <TrendingUp className="w-4 h-4" style={{ color: '#9575cd' }} />
            <div className="text-xs" style={{ color: '#757575' }}>Engagement Rate</div>
          </div>
          <div className="text-2xl mb-1" style={{ color: '#424242' }}>
            {overviewMetrics.engagementRate}%
          </div>
          <div className="text-xs" style={{ color: '#2e7d32' }}>+8% vs prev period</div>
        </div>

        <div
          className="p-5 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <Target className="w-4 h-4" style={{ color: '#9575cd' }} />
            <div className="text-xs" style={{ color: '#757575' }}>30d Retention</div>
          </div>
          <div className="text-2xl mb-1" style={{ color: '#424242' }}>
            {overviewMetrics.retention30d}%
          </div>
          <div className="text-xs" style={{ color: '#2e7d32' }}>+3% vs prev period</div>
        </div>

        <div
          className="p-5 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-2">
            <AlertTriangle className="w-4 h-4" style={{ color: '#f57c00' }} />
            <div className="text-xs" style={{ color: '#757575' }}>Abandonment</div>
          </div>
          <div className="text-2xl mb-1" style={{ color: '#424242' }}>
            {overviewMetrics.flowAbandonmentRate}%
          </div>
          <div className="text-xs" style={{ color: '#d32f2f' }}>-2% vs prev period</div>
        </div>
      </div>

      {/* Feature Usage Breakdown */}
      <div
        className="p-8 rounded-2xl border mb-8"
        style={{
          backgroundColor: 'white',
          borderColor: '#e0e0e0',
        }}
      >
        <div className="mb-6">
          <h2 className="text-xl mb-2" style={{ color: '#424242' }}>
            Feature Usage Analysis
          </h2>
          <p className="text-sm" style={{ color: '#757575' }}>
            Session counts, completion rates, and average time spent per feature
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr style={{ borderBottom: '2px solid #e0e0e0' }}>
                <th className="text-left py-3 px-4 text-sm" style={{ color: '#757575' }}>Feature</th>
                <th className="text-right py-3 px-4 text-sm" style={{ color: '#757575' }}>Sessions</th>
                <th className="text-right py-3 px-4 text-sm" style={{ color: '#757575' }}>Completions</th>
                <th className="text-right py-3 px-4 text-sm" style={{ color: '#757575' }}>Completion Rate</th>
                <th className="text-right py-3 px-4 text-sm" style={{ color: '#757575' }}>Avg Time (min)</th>
              </tr>
            </thead>
            <tbody>
              {featureUsageData.map((feature) => {
                const completionRate = ((feature.completions / feature.sessions) * 100).toFixed(1);
                return (
                  <tr key={feature.feature} style={{ borderBottom: '1px solid #f5f5f5' }}>
                    <td className="py-4 px-4 text-sm" style={{ color: '#424242' }}>{feature.feature}</td>
                    <td className="text-right py-4 px-4 text-sm" style={{ color: '#616161' }}>
                      {feature.sessions.toLocaleString()}
                    </td>
                    <td className="text-right py-4 px-4 text-sm" style={{ color: '#616161' }}>
                      {feature.completions.toLocaleString()}
                    </td>
                    <td className="text-right py-4 px-4">
                      <span
                        className="px-3 py-1 rounded-full text-xs"
                        style={{
                          backgroundColor: parseFloat(completionRate) >= 80 ? '#e8f5e9' : '#fff3e0',
                          color: parseFloat(completionRate) >= 80 ? '#2e7d32' : '#f57c00',
                        }}
                      >
                        {completionRate}%
                      </span>
                    </td>
                    <td className="text-right py-4 px-4 text-sm" style={{ color: '#616161' }}>
                      {feature.avgTime}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* User Journey Funnels */}
      <div className="grid gap-6 md:grid-cols-2 mb-8">
        {/* Learning Module Funnel */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-6">
            <BookOpen className="w-5 h-5" style={{ color: '#9575cd' }} />
            <h3 className="text-lg" style={{ color: '#424242' }}>
              Learning Module Journey
            </h3>
          </div>

          <div className="space-y-3">
            {learningFunnelData.map((stage, idx) => (
              <div key={stage.stage}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm" style={{ color: '#616161' }}>{stage.stage}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-sm" style={{ color: '#424242' }}>
                      {stage.count.toLocaleString()}
                    </span>
                    <span className="text-xs" style={{ color: '#9575cd' }}>
                      {stage.percentage}%
                    </span>
                  </div>
                </div>
                <div
                  className="h-2 rounded-full"
                  style={{ backgroundColor: '#f5f5f5' }}
                >
                  <div
                    className="h-2 rounded-full transition-all"
                    style={{
                      width: `${stage.percentage}%`,
                      backgroundColor: '#9575cd',
                    }}
                  />
                </div>
                {idx < learningFunnelData.length - 1 && (
                  <div className="text-xs mt-1" style={{ color: '#f57c00' }}>
                    Drop-off: {(learningFunnelData[idx].percentage - learningFunnelData[idx + 1].percentage).toFixed(1)}%
                  </div>
                )}
              </div>
            ))}
          </div>

          <div
            className="mt-4 p-4 rounded-lg"
            style={{ backgroundColor: '#f3e5f5' }}
          >
            <div className="text-xs" style={{ color: '#7e57c2' }}>
              Overall conversion: {learningFunnelData[learningFunnelData.length - 1].percentage}% completion
            </div>
          </div>
        </div>

        {/* Provider Search Funnel */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-6">
            <MapPin className="w-5 h-5" style={{ color: '#9575cd' }} />
            <h3 className="text-lg" style={{ color: '#424242' }}>
              Provider Search Journey
            </h3>
          </div>

          <div className="space-y-3">
            {providerFunnelData.map((stage, idx) => (
              <div key={stage.stage}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm" style={{ color: '#616161' }}>{stage.stage}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-sm" style={{ color: '#424242' }}>
                      {stage.count.toLocaleString()}
                    </span>
                    <span className="text-xs" style={{ color: '#9575cd' }}>
                      {stage.percentage}%
                    </span>
                  </div>
                </div>
                <div
                  className="h-2 rounded-full"
                  style={{ backgroundColor: '#f5f5f5' }}
                >
                  <div
                    className="h-2 rounded-full transition-all"
                    style={{
                      width: `${stage.percentage}%`,
                      backgroundColor: '#9575cd',
                    }}
                  />
                </div>
                {idx < providerFunnelData.length - 1 && (
                  <div className="text-xs mt-1" style={{ color: '#f57c00' }}>
                    Drop-off: {(providerFunnelData[idx].percentage - providerFunnelData[idx + 1].percentage).toFixed(1)}%
                  </div>
                )}
              </div>
            ))}
          </div>

          <div
            className="mt-4 p-4 rounded-lg"
            style={{ backgroundColor: '#f3e5f5' }}
          >
            <div className="text-xs" style={{ color: '#7e57c2' }}>
              Overall conversion: {providerFunnelData[providerFunnelData.length - 1].percentage}% selection
            </div>
          </div>
        </div>
      </div>

      {/* Engagement Over Time & Community Analytics */}
      <div className="grid gap-6 md:grid-cols-2 mb-8">
        {/* Engagement Trends */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <h3 className="text-lg mb-6" style={{ color: '#424242' }}>
            Engagement Trends
          </h3>
          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={engagementOverTimeData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
              <XAxis dataKey="date" stroke="#9e9e9e" style={{ fontSize: '12px' }} />
              <YAxis stroke="#9e9e9e" style={{ fontSize: '12px' }} />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'white',
                  border: '1px solid #e0e0e0',
                  borderRadius: '8px',
                  fontSize: '12px',
                }}
              />
              <Legend wrapperStyle={{ fontSize: '12px' }} />
              <Line
                type="monotone"
                dataKey="sessions"
                stroke="#9575cd"
                strokeWidth={2}
                dot={{ fill: '#9575cd', r: 4 }}
                name="Sessions"
              />
              <Line
                type="monotone"
                dataKey="screenViews"
                stroke="#7e57c2"
                strokeWidth={2}
                dot={{ fill: '#7e57c2', r: 4 }}
                name="Screen Views"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Community Engagement */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-6">
            <MessageCircle className="w-5 h-5" style={{ color: '#9575cd' }} />
            <h3 className="text-lg" style={{ color: '#424242' }}>
              Community Engagement
            </h3>
          </div>

          <div className="space-y-4">
            {communityData.map((item) => (
              <div key={item.metric}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm" style={{ color: '#616161' }}>{item.metric}</span>
                  <span className="text-lg" style={{ color: '#424242' }}>
                    {item.count.toLocaleString()}
                  </span>
                </div>
                <div
                  className="h-2 rounded-full"
                  style={{ backgroundColor: '#f5f5f5' }}
                >
                  <div
                    className="h-2 rounded-full"
                    style={{
                      width: `${(item.count / 5000) * 100}%`,
                      backgroundColor: '#9575cd',
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          <div
            className="mt-6 p-4 rounded-lg"
            style={{ backgroundColor: '#fafafa' }}
          >
            <div className="text-xs mb-1" style={{ color: '#757575' }}>
              Engagement Ratio
            </div>
            <div className="text-sm" style={{ color: '#424242' }}>
              {((communityData[1].count + communityData[2].count) / communityData[0].count).toFixed(1)}x replies & likes per post
            </div>
          </div>
        </div>
      </div>

      {/* Mood Distribution & Outcome Signals */}
      <div className="grid gap-6 md:grid-cols-2 mb-8">
        {/* Mood Distribution */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-6">
            <Heart className="w-5 h-5" style={{ color: '#9575cd' }} />
            <h3 className="text-lg" style={{ color: '#424242' }}>
              Journal Mood Distribution
            </h3>
          </div>

          <div className="space-y-4">
            {moodData.map((mood) => {
              const total = moodData.reduce((sum, m) => sum + m.count, 0);
              const percentage = ((mood.count / total) * 100).toFixed(1);
              return (
                <div key={mood.mood}>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <div
                        className="w-3 h-3 rounded-full"
                        style={{ backgroundColor: mood.color }}
                      />
                      <span className="text-sm" style={{ color: '#616161' }}>{mood.mood}</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className="text-sm" style={{ color: '#424242' }}>
                        {mood.count.toLocaleString()}
                      </span>
                      <span className="text-xs" style={{ color: '#9e9e9e' }}>
                        {percentage}%
                      </span>
                    </div>
                  </div>
                  <div
                    className="h-2 rounded-full"
                    style={{ backgroundColor: '#f5f5f5' }}
                  >
                    <div
                      className="h-2 rounded-full"
                      style={{
                        width: `${percentage}%`,
                        backgroundColor: mood.color,
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>

          <div
            className="mt-6 p-4 rounded-lg"
            style={{ backgroundColor: '#e8f5e9' }}
          >
            <div className="text-xs" style={{ color: '#2e7d32' }}>
              {((moodData[0].count / moodData.reduce((sum, m) => sum + m.count, 0)) * 100).toFixed(1)}% of journal entries reflect positive sentiment
            </div>
          </div>
        </div>

        {/* Outcome Signals */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <h3 className="text-lg mb-6" style={{ color: '#424242' }}>
            Outcome Signals (Micro-Measures)
          </h3>
          <ResponsiveContainer width="100%" height={240}>
            <LineChart data={outcomeSignalsData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
              <XAxis dataKey="week" stroke="#9e9e9e" style={{ fontSize: '12px' }} />
              <YAxis domain={[0, 10]} stroke="#9e9e9e" style={{ fontSize: '12px' }} />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'white',
                  border: '1px solid #e0e0e0',
                  borderRadius: '8px',
                  fontSize: '12px',
                }}
              />
              <Legend wrapperStyle={{ fontSize: '12px' }} />
              <Line
                type="monotone"
                dataKey="confidence"
                stroke="#2e7d32"
                strokeWidth={2}
                dot={{ fill: '#2e7d32', r: 4 }}
                name="Confidence Score"
              />
              <Line
                type="monotone"
                dataKey="understanding"
                stroke="#1976d2"
                strokeWidth={2}
                dot={{ fill: '#1976d2', r: 4 }}
                name="Understanding Score"
              />
            </LineChart>
          </ResponsiveContainer>

          <div
            className="mt-4 p-4 rounded-lg"
            style={{ backgroundColor: '#fafafa' }}
          >
            <div className="text-xs" style={{ color: '#616161' }}>
              Average scores on 0-10 scale. Tracked via micro_measure_submitted and confidence_signal_submitted events.
            </div>
          </div>
        </div>
      </div>

      {/* Abandonment Analysis & Screen Time */}
      <div className="grid gap-6 md:grid-cols-2 mb-8">
        {/* Abandonment Rates */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center gap-2 mb-6">
            <AlertTriangle className="w-5 h-5" style={{ color: '#f57c00' }} />
            <h3 className="text-lg" style={{ color: '#424242' }}>
              Flow Abandonment Rates
            </h3>
          </div>

          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={abandonmentData} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="#f5f5f5" />
              <XAxis type="number" stroke="#9e9e9e" style={{ fontSize: '12px' }} />
              <YAxis dataKey="flow" type="category" width={120} stroke="#9e9e9e" style={{ fontSize: '12px' }} />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'white',
                  border: '1px solid #e0e0e0',
                  borderRadius: '8px',
                  fontSize: '12px',
                }}
              />
              <Bar dataKey="abandonmentRate" fill="#f57c00" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>

          <div
            className="mt-4 p-4 rounded-lg"
            style={{ backgroundColor: '#fff3e0' }}
          >
            <div className="text-xs" style={{ color: '#f57c00' }}>
              Tracked via flow_abandoned event. Lower rates indicate better user experience.
            </div>
          </div>
        </div>

        {/* Screen Time Distribution */}
        <div
          className="p-8 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <h3 className="text-lg mb-6" style={{ color: '#424242' }}>
            Screen Time Distribution
          </h3>

          <div className="space-y-4">
            {screenTimeData.map((screen) => (
              <div key={screen.screen}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm" style={{ color: '#616161' }}>{screen.screen}</span>
                  <div className="flex items-center gap-3">
                    <span className="text-sm" style={{ color: '#424242' }}>
                      {screen.avgTime}m avg
                    </span>
                    <span className="text-xs" style={{ color: '#9e9e9e' }}>
                      {screen.sessions.toLocaleString()} sessions
                    </span>
                  </div>
                </div>
                <div
                  className="h-2 rounded-full"
                  style={{ backgroundColor: '#f5f5f5' }}
                >
                  <div
                    className="h-2 rounded-full"
                    style={{
                      width: `${(screen.avgTime / 20) * 100}%`,
                      backgroundColor: '#7e57c2',
                    }}
                  />
                </div>
              </div>
            ))}
          </div>

          <div
            className="mt-6 p-4 rounded-lg"
            style={{ backgroundColor: '#fafafa' }}
          >
            <div className="text-xs" style={{ color: '#616161' }}>
              Tracked via screen_time_spent and feature_time_spent events
            </div>
          </div>
        </div>
      </div>

      {/* Event Tracking Reference */}
      <div
        className="p-8 rounded-2xl border"
        style={{
          backgroundColor: '#fafafa',
          borderColor: '#e0e0e0',
        }}
      >
        <h3 className="text-lg mb-4" style={{ color: '#424242' }}>
          Tracked Events Reference
        </h3>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[
            { category: "App Events", events: ["session_started", "screen_view", "feature_time_spent", "screen_time_spent", "flow_abandoned"] },
            { category: "Learning", events: ["learning_module_viewed", "learning_module_started", "learning_module_completed", "learning_module_survey_submitted"] },
            { category: "Provider Search", events: ["provider_search_initiated", "provider_profile_viewed", "provider_contact_clicked", "provider_selected_success"] },
            { category: "Care Documentation", events: ["visit_summary_created", "birth_plan_completed"] },
            { category: "Journal & Reflection", events: ["journal_entry_created", "journal_mood_selected"] },
            { category: "Community", events: ["community_post_created", "community_post_replied", "community_post_liked"] },
          ].map((group) => (
            <div key={group.category}>
              <h4 className="text-sm mb-2" style={{ color: '#7e57c2' }}>
                {group.category}
              </h4>
              <ul className="space-y-1">
                {group.events.map((event) => (
                  <li key={event} className="text-xs" style={{ color: '#616161' }}>
                    • {event}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
