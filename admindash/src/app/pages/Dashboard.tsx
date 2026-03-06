import { TrendingUp, Users, Activity, Bell, FileText, CheckCircle2, ArrowRight } from "lucide-react";
import { Link } from "react-router";
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

export function Dashboard() {
  const engagementData = [
    { date: "Feb 22", users: 680 },
    { date: "Feb 23", users: 695 },
    { date: "Feb 24", users: 710 },
    { date: "Feb 25", users: 725 },
    { date: "Feb 26", users: 740 },
    { date: "Feb 27", users: 760 },
    { date: "Feb 28", users: 780 },
    { date: "Mar 1", users: 850 },
  ];

  const featureUsageData = [
    { name: "Learning", value: 850 },
    { name: "Journal", value: 720 },
    { name: "Birth Plan", value: 640 },
  ];

  const stats = [
    {
      label: "Active Users",
      value: "850",
      change: "+12.5%",
      trend: "up",
      icon: Users,
      color: 'var(--lavender-500)',
      bgColor: 'var(--lavender-100)',
    },
    {
      label: "Engagement Rate",
      value: "87%",
      change: "+5.2%",
      trend: "up",
      icon: Activity,
      color: 'var(--success)',
      bgColor: 'var(--success-light)',
    },
    {
      label: "Avg. Session",
      value: "18min",
      change: "+3.1%",
      trend: "up",
      icon: TrendingUp,
      color: '#f59e0b',
      bgColor: 'var(--warning-light)',
    },
    {
      label: "Notifications Sent",
      value: "1,247",
      change: "Today",
      trend: "neutral",
      icon: Bell,
      color: '#8b5cf6',
      bgColor: '#f3e8ff',
    },
  ];

  const recentActivity = [
    {
      type: "New User",
      description: "Sarah M. joined the platform",
      time: "5 minutes ago",
      icon: Users,
      color: 'var(--lavender-500)',
    },
    {
      type: "Report Generated",
      description: "Health Understanding Impact Report",
      time: "1 hour ago",
      icon: FileText,
      color: 'var(--success)',
    },
    {
      type: "Notification Sent",
      description: "New Learning Module alert to 247 users",
      time: "2 hours ago",
      icon: Bell,
      color: '#f59e0b',
    },
    {
      type: "Feature Update",
      description: "Birth Plan Builder updated to v2.1",
      time: "5 hours ago",
      icon: CheckCircle2,
      color: '#06b6d4',
    },
  ];

  const quickLinks = [
    {
      title: "View Reports",
      description: "Generate and export analytics",
      href: "/reports",
      icon: FileText,
      color: 'var(--lavender-500)',
    },
    {
      title: "Manage Users",
      description: "Add or edit user roles",
      href: "/users-roles",
      icon: Users,
      color: 'var(--success)',
    },
    {
      title: "Send Notification",
      description: "Create a new push notification",
      href: "/notifications",
      icon: Bell,
      color: '#f59e0b',
    },
    {
      title: "View Analytics",
      description: "Detailed platform insights",
      href: "/analytics",
      icon: Activity,
      color: '#8b5cf6',
    },
  ];

  const systemStatus = [
    { service: "API Server", status: "Operational", uptime: "99.98%" },
    { service: "Database", status: "Operational", uptime: "99.99%" },
    { service: "Push Notifications", status: "Operational", uptime: "99.95%" },
    { service: "File Storage", status: "Operational", uptime: "99.97%" },
  ];

  return (
    <div className="p-8">
      <div className="max-w-7xl mx-auto">
        {/* Welcome Header */}
        <div className="mb-8">
          <h1 className="text-3xl mb-2" style={{ color: 'var(--warm-600)' }}>
            Welcome back
          </h1>
          <p style={{ color: 'var(--warm-400)' }}>
            Here's what's happening with EmpowerHealth today
          </p>
        </div>

        {/* Key Stats */}
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 mb-8">
          {stats.map((stat) => {
            const Icon = stat.icon;
            return (
              <div
                key={stat.label}
                className="p-6 rounded-2xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: 'var(--lavender-200)',
                }}
              >
                <div className="flex items-center justify-between mb-4">
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center"
                    style={{ backgroundColor: stat.bgColor }}
                  >
                    <Icon className="w-6 h-6" style={{ color: stat.color }} />
                  </div>
                  {stat.trend !== "neutral" && (
                    <div
                      className="px-2 py-1 rounded-lg text-xs"
                      style={{
                        backgroundColor: 'var(--success-light)',
                        color: 'var(--success)',
                      }}
                    >
                      {stat.change}
                    </div>
                  )}
                </div>
                <div className="text-2xl mb-1" style={{ color: 'var(--warm-600)' }}>
                  {stat.value}
                </div>
                <div className="text-sm" style={{ color: 'var(--warm-500)' }}>
                  {stat.label}
                </div>
              </div>
            );
          })}
        </div>

        <div className="grid gap-6 lg:grid-cols-3 mb-8">
          {/* Engagement Trend Chart */}
          <div
            className="lg:col-span-2 p-6 rounded-2xl border"
            style={{
              backgroundColor: 'white',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                  User Engagement
                </h2>
                <p className="text-sm" style={{ color: 'var(--warm-400)' }}>
                  Last 7 days
                </p>
              </div>
              <Link
                to="/analytics"
                className="text-sm flex items-center gap-1 hover:underline"
                style={{ color: 'var(--lavender-600)' }}
              >
                View Details
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={engagementData}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--lavender-200)" />
                <XAxis dataKey="date" stroke="var(--warm-500)" tick={{ fontSize: 12 }} />
                <YAxis stroke="var(--warm-500)" tick={{ fontSize: 12 }} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid var(--lavender-200)',
                    borderRadius: '12px',
                  }}
                />
                <Line
                  type="monotone"
                  dataKey="users"
                  stroke="var(--lavender-500)"
                  strokeWidth={3}
                  dot={{ fill: 'var(--lavender-500)', r: 4 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>

          {/* Top Features */}
          <div
            className="p-6 rounded-2xl border"
            style={{
              backgroundColor: 'white',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <div className="mb-6">
              <h2 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                Top Features
              </h2>
              <p className="text-sm" style={{ color: 'var(--warm-400)' }}>
                Most used this week
              </p>
            </div>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={featureUsageData} layout="vertical">
                <XAxis type="number" stroke="var(--warm-500)" tick={{ fontSize: 12 }} />
                <YAxis dataKey="name" type="category" stroke="var(--warm-500)" tick={{ fontSize: 12 }} width={80} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid var(--lavender-200)',
                    borderRadius: '12px',
                  }}
                />
                <Bar dataKey="value" fill="var(--lavender-400)" radius={[0, 8, 8, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-3 mb-8">
          {/* Recent Activity */}
          <div
            className="lg:col-span-2 p-6 rounded-2xl border"
            style={{
              backgroundColor: 'white',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <h2 className="mb-6" style={{ color: 'var(--warm-600)' }}>
              Recent Activity
            </h2>
            <div className="space-y-4">
              {recentActivity.map((activity, index) => {
                const Icon = activity.icon;
                return (
                  <div
                    key={index}
                    className="flex items-start gap-4 pb-4 border-b last:border-b-0"
                    style={{ borderColor: 'var(--lavender-100)' }}
                  >
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                      style={{ backgroundColor: activity.color + '20' }}
                    >
                      <Icon className="w-5 h-5" style={{ color: activity.color }} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-sm mb-1" style={{ color: 'var(--warm-600)' }}>
                        {activity.type}
                      </div>
                      <div className="text-sm mb-1" style={{ color: 'var(--warm-500)' }}>
                        {activity.description}
                      </div>
                      <div className="text-xs" style={{ color: 'var(--warm-400)' }}>
                        {activity.time}
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* System Status */}
          <div
            className="p-6 rounded-2xl border"
            style={{
              backgroundColor: 'white',
              borderColor: 'var(--lavender-200)',
            }}
          >
            <h2 className="mb-6" style={{ color: 'var(--warm-600)' }}>
              System Status
            </h2>
            <div className="space-y-4">
              {systemStatus.map((system, index) => (
                <div
                  key={index}
                  className="pb-4 border-b last:border-b-0"
                  style={{ borderColor: 'var(--lavender-100)' }}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm" style={{ color: 'var(--warm-600)' }}>
                      {system.service}
                    </span>
                    <div className="flex items-center gap-2">
                      <div
                        className="w-2 h-2 rounded-full"
                        style={{ backgroundColor: 'var(--success)' }}
                      />
                      <span className="text-xs" style={{ color: 'var(--success)' }}>
                        {system.status}
                      </span>
                    </div>
                  </div>
                  <div className="text-xs" style={{ color: 'var(--warm-400)' }}>
                    Uptime: {system.uptime}
                  </div>
                </div>
              ))}
            </div>
            <Link
              to="/technology"
              className="mt-4 text-sm flex items-center gap-1 hover:underline"
              style={{ color: 'var(--lavender-600)' }}
            >
              View Tech Overview
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>

        {/* Quick Links */}
        <div>
          <h2 className="mb-4" style={{ color: 'var(--warm-600)' }}>
            Quick Actions
          </h2>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {quickLinks.map((link) => {
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  to={link.href}
                  className="p-6 rounded-2xl border hover:shadow-lg transition-all"
                  style={{
                    backgroundColor: 'white',
                    borderColor: 'var(--lavender-200)',
                  }}
                >
                  <div
                    className="w-12 h-12 rounded-xl flex items-center justify-center mb-4"
                    style={{ backgroundColor: link.color + '20' }}
                  >
                    <Icon className="w-6 h-6" style={{ color: link.color }} />
                  </div>
                  <h3 className="mb-1" style={{ color: 'var(--warm-600)' }}>
                    {link.title}
                  </h3>
                  <p className="text-sm" style={{ color: 'var(--warm-500)' }}>
                    {link.description}
                  </p>
                  <ArrowRight
                    className="w-5 h-5 mt-3"
                    style={{ color: 'var(--warm-400)' }}
                  />
                </Link>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
