import { Calendar, GitCommit, ExternalLink, Copy, Search, ChevronDown, X, FileText, BarChart3, TrendingUp, Code2, History, Sparkles, ArrowUpRight, Clock, Users, Activity } from "lucide-react";
import { useState } from "react";
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";

interface Release {
  version: string;
  buildNumber: number;
  environment: "Pilot" | "Production";
  deployedAt: string;
  status: "operational" | "monitoring" | "maintenance";
  commit: string;
  notes: string;
}

interface FunctionalUpdate {
  name: string;
  description: string;
  domain: string;
}

interface FeatureDetail {
  id: string;
  name: string;
  domain: string;
  category: string;
  description: string;
  implementation: {
    architecture: string;
    components: string[];
    dataFlow: string;
  };
  changeHistory: {
    version: string;
    date: string;
    change: string;
  }[];
  analytics: {
    adoptionRate: number;
    activeUsers: number;
    engagementTrend: { date: string; value: number }[];
    usageByWeek: { week: string; sessions: number }[];
  };
  kpis: {
    name: string;
    value: string;
    trend: string;
    target: string;
    impact: string;
  }[];
  lastUpdated?: string;
  updateHighlight?: string;
}

export function ReleasesAndBuilds() {
  const [selectedRelease, setSelectedRelease] = useState<Release | null>(null);
  const [selectedFeature, setSelectedFeature] = useState<FeatureDetail | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [expandedDomain, setExpandedDomain] = useState<string | null>("care-understanding");
  const [featureSearchQuery, setFeatureSearchQuery] = useState("");
  const [selectedDomain, setSelectedDomain] = useState<string>("all");

  const currentRelease: Release = {
    version: "1.2.3",
    buildNumber: 13,
    environment: "Production",
    deployedAt: "March 1, 2026",
    status: "operational",
    commit: "a7f3c9d",
    notes: "Platform functional updates and system refinements",
  };

  const releaseHistory: Release[] = [
    {
      version: "1.2.3",
      buildNumber: 13,
      environment: "Production",
      deployedAt: "Mar 1, 2026",
      status: "operational",
      commit: "a7f3c9d",
      notes: "Platform functional updates and system refinements",
    },
    {
      version: "1.2.2",
      buildNumber: 12,
      environment: "Production",
      deployedAt: "Feb 28, 2026",
      status: "operational",
      commit: "b4e2f8a",
      notes: "Notification delivery process adjustments",
    },
    {
      version: "1.2.1",
      buildNumber: 11,
      environment: "Pilot",
      deployedAt: "Feb 26, 2026",
      status: "operational",
      commit: "c9d1a3e",
      notes: "Community moderation capability expansion",
    },
    {
      version: "1.2.0",
      buildNumber: 10,
      environment: "Production",
      deployedAt: "Feb 24, 2026",
      status: "operational",
      commit: "d2f5b7c",
      notes: "Educational content template expansion",
    },
    {
      version: "1.1.9",
      buildNumber: 9,
      environment: "Production",
      deployedAt: "Feb 22, 2026",
      status: "maintenance",
      commit: "e8c4a2b",
      notes: "Database schema revision required",
    },
  ];

  const platformFeatures: FeatureDetail[] = [
    {
      id: "visit-summary",
      name: "Visit Summary Documentation",
      domain: "Care Understanding",
      category: "Documentation",
      description: "Structured documentation system enabling participants to record and export clinical visit information in standardized formats.",
      lastUpdated: "Mar 1, 2026",
      updateHighlight: "PDF export now available with enhanced formatting options",
      implementation: {
        architecture: "Client-side document generation with cloud storage integration",
        components: ["React form interface", "PDF rendering engine", "Cloud storage API", "Template management system"],
        dataFlow: "User input → Validation layer → Document generation → Storage service → Retrieval interface",
      },
      changeHistory: [
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Introduced structured PDF export capability" },
        { version: "1.2.0+10", date: "Feb 24, 2026", change: "Enhanced form validation and error handling" },
        { version: "1.1.7+7", date: "Feb 10, 2026", change: "Initial template system implementation" },
      ],
      analytics: {
        adoptionRate: 68,
        activeUsers: 578,
        engagementTrend: [
          { date: "Feb 22", value: 520 },
          { date: "Feb 24", value: 535 },
          { date: "Feb 26", value: 548 },
          { date: "Feb 28", value: 565 },
          { date: "Mar 1", value: 578 },
        ],
        usageByWeek: [
          { week: "Week 1", sessions: 1240 },
          { week: "Week 2", sessions: 1385 },
          { week: "Week 3", sessions: 1520 },
          { week: "Week 4", sessions: 1680 },
        ],
      },
      kpis: [
        {
          name: "Documentation Completion Rate",
          value: "73.2%",
          trend: "+8.5%",
          target: "75%",
          impact: "Higher completion rates correlate with better information retention and care continuity",
        },
        {
          name: "Export Utilization",
          value: "42.1%",
          trend: "+15.3%",
          target: "50%",
          impact: "Shows strong adoption of the new PDF export feature for sharing with care providers",
        },
        {
          name: "Time to Complete",
          value: "8.4 min",
          trend: "-12%",
          target: "7 min",
          impact: "Faster completion times indicate improved user experience and reduced friction",
        },
      ],
    },
    {
      id: "learning-modules",
      name: "Educational Learning Modules",
      domain: "Care Preparation",
      category: "Preparation",
      description: "Structured educational content delivery system supporting multimedia learning materials and progress tracking across maternal health topics.",
      lastUpdated: "Mar 1, 2026",
      updateHighlight: "Video content integration now live with engagement tracking",
      implementation: {
        architecture: "Modular content management system with video streaming integration",
        components: ["Content delivery network", "Video player component", "Progress tracking service", "Assessment engine"],
        dataFlow: "Content request → CDN retrieval → Client rendering → Interaction logging → Progress database",
      },
      changeHistory: [
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Added embedded video content support" },
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Enhanced completion tracking with detailed analytics" },
        { version: "1.2.0+10", date: "Feb 24, 2026", change: "Expanded template library with 12 new modules" },
      ],
      analytics: {
        adoptionRate: 87,
        activeUsers: 740,
        engagementTrend: [
          { date: "Feb 22", value: 680 },
          { date: "Feb 24", value: 695 },
          { date: "Feb 26", value: 710 },
          { date: "Feb 28", value: 725 },
          { date: "Mar 1", value: 740 },
        ],
        usageByWeek: [
          { week: "Week 1", sessions: 2150 },
          { week: "Week 2", sessions: 2280 },
          { week: "Week 3", sessions: 2420 },
          { week: "Week 4", sessions: 2585 },
        ],
      },
      kpis: [
        {
          name: "Module Completion Rate",
          value: "81.5%",
          trend: "+6.2%",
          target: "85%",
          impact: "Strong completion rates demonstrate effective content design and user engagement",
        },
        {
          name: "Average Time per Module",
          value: "14.2 min",
          trend: "+2.8%",
          target: "15 min",
          impact: "Users are spending more time with content, indicating deeper engagement with materials",
        },
        {
          name: "Video Engagement Rate",
          value: "68.7%",
          trend: "+22.4%",
          target: "70%",
          impact: "New video content showing excellent adoption and watch-through rates",
        },
      ],
    },
    {
      id: "provider-search",
      name: "Provider Search & Discovery",
      domain: "Care Navigation",
      category: "Navigation",
      description: "Healthcare provider matching system with expanded search criteria supporting participant care navigation and provider selection processes.",
      lastUpdated: "Mar 1, 2026",
      updateHighlight: "Improved matching algorithm and new provider review system",
      implementation: {
        architecture: "Search indexing service with real-time filtering and geolocation support",
        components: ["Search index", "Filtering engine", "Geolocation service", "Provider database", "Rating aggregation"],
        dataFlow: "Search query → Index lookup → Filter application → Result ranking → Client display",
      },
      changeHistory: [
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Updated search logic to expand matching criteria" },
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Introduced provider rating and review system" },
        { version: "1.1.8+8", date: "Feb 15, 2026", change: "Added insurance network filtering" },
      ],
      analytics: {
        adoptionRate: 75,
        activeUsers: 638,
        engagementTrend: [
          { date: "Feb 22", value: 580 },
          { date: "Feb 24", value: 595 },
          { date: "Feb 26", value: 610 },
          { date: "Feb 28", value: 625 },
          { date: "Mar 1", value: 638 },
        ],
        usageByWeek: [
          { week: "Week 1", sessions: 1680 },
          { week: "Week 2", sessions: 1755 },
          { week: "Week 3", sessions: 1820 },
          { week: "Week 4", sessions: 1920 },
        ],
      },
      kpis: [
        {
          name: "Search Success Rate",
          value: "79.3%",
          trend: "+11.7%",
          target: "80%",
          impact: "Improved algorithm is helping more users find suitable providers on first search",
        },
        {
          name: "Provider Contact Rate",
          value: "34.2%",
          trend: "+5.8%",
          target: "40%",
          impact: "Higher contact rates indicate users are finding providers that meet their needs",
        },
        {
          name: "Search Refinement Rate",
          value: "2.1",
          trend: "-8.3%",
          target: "2.0",
          impact: "Fewer refinements needed, showing better initial matching accuracy",
        },
      ],
    },
    {
      id: "journal",
      name: "Self-Reflection Journal",
      domain: "Self-Reflection",
      category: "Reflection",
      description: "Personal documentation system for participant self-reflection with mood tracking and longitudinal wellness observation capabilities.",
      lastUpdated: "Mar 1, 2026",
      updateHighlight: "New mood tracking feature for emotional wellness insights",
      implementation: {
        architecture: "Encrypted client-side storage with optional cloud synchronization",
        components: ["Rich text editor", "Mood tracking interface", "Encryption layer", "Sync service", "Timeline viewer"],
        dataFlow: "User entry → Client encryption → Local storage → Optional sync → Retrieval & decryption",
      },
      changeHistory: [
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Added mood indicator collection to entry interface" },
        { version: "1.1.6+6", date: "Feb 5, 2026", change: "Implemented end-to-end encryption for entries" },
        { version: "1.0.8+4", date: "Jan 12, 2026", change: "Initial journal feature deployment" },
      ],
      analytics: {
        adoptionRate: 62,
        activeUsers: 527,
        engagementTrend: [
          { date: "Feb 22", value: 480 },
          { date: "Feb 24", value: 492 },
          { date: "Feb 26", value: 505 },
          { date: "Feb 28", value: 516 },
          { date: "Mar 1", value: 527 },
        ],
        usageByWeek: [
          { week: "Week 1", sessions: 2340 },
          { week: "Week 2", sessions: 2420 },
          { week: "Week 3", sessions: 2510 },
          { week: "Week 4", sessions: 2640 },
        ],
      },
      kpis: [
        {
          name: "Weekly Entry Frequency",
          value: "4.8",
          trend: "+9.1%",
          target: "5.0",
          impact: "Users are maintaining consistent journaling habits throughout their journey",
        },
        {
          name: "Mood Indicator Utilization",
          value: "71.4%",
          trend: "New",
          target: "75%",
          impact: "Strong early adoption of mood tracking feature for emotional wellness monitoring",
        },
        {
          name: "Entry Length Average",
          value: "187 words",
          trend: "+3.5%",
          target: "200 words",
          impact: "Longer entries suggest users are engaging in meaningful self-reflection",
        },
      ],
    },
    {
      id: "birth-plan",
      name: "Birth Plan Builder",
      domain: "Care Preparation",
      category: "Planning",
      description: "Structured birth preference documentation tool with template library supporting participant preparation and care team communication.",
      lastUpdated: "Mar 1, 2026",
      updateHighlight: "15 new templates added based on user feedback and requests",
      implementation: {
        architecture: "Template-based form system with PDF generation and sharing capabilities",
        components: ["Template engine", "Form builder", "PDF generator", "Sharing service", "Version control"],
        dataFlow: "Template selection → Preference input → Document generation → Storage → Provider sharing",
      },
      changeHistory: [
        { version: "1.2.3+13", date: "Mar 1, 2026", change: "Expanded template library with 15 additional options" },
        { version: "1.1.5+5", date: "Feb 1, 2026", change: "Added provider sharing capability" },
        { version: "1.0.9+3", date: "Jan 18, 2026", change: "Initial birth plan feature launch" },
      ],
      analytics: {
        adoptionRate: 71,
        activeUsers: 604,
        engagementTrend: [
          { date: "Feb 22", value: 550 },
          { date: "Feb 24", value: 565 },
          { date: "Feb 26", value: 580 },
          { date: "Feb 28", value: 592 },
          { date: "Mar 1", value: 604 },
        ],
        usageByWeek: [
          { week: "Week 1", sessions: 980 },
          { week: "Week 2", sessions: 1040 },
          { week: "Week 3", sessions: 1110 },
          { week: "Week 4", sessions: 1180 },
        ],
      },
      kpis: [
        {
          name: "Plan Completion Rate",
          value: "84.6%",
          trend: "+4.2%",
          target: "85%",
          impact: "High completion rates indicate users find the tool valuable for birth planning",
        },
        {
          name: "Provider Share Rate",
          value: "56.8%",
          trend: "+7.3%",
          target: "60%",
          impact: "More users sharing plans with providers, improving care team communication",
        },
        {
          name: "Template Utilization",
          value: "78.2%",
          trend: "+12.6%",
          target: "75%",
          impact: "New templates are meeting user needs and exceeding adoption targets",
        },
      ],
    },
  ];

  const functionalUpdates: Record<string, FunctionalUpdate[]> = {
    "care-understanding": [
      {
        name: "Structured Documentation Export",
        description: "Visit summary export functionality introduced structured PDF documentation capability.",
        domain: "Documentation",
      },
      {
        name: "Audio Annotation Support",
        description: "Audio recording capacity added to visit documentation workflows.",
        domain: "Documentation",
      },
    ],
    "care-preparation": [
      {
        name: "Video Content Integration",
        description: "Educational modules expanded to include embedded video content delivery.",
        domain: "Preparation",
      },
      {
        name: "Progress Documentation",
        description: "Participant completion tracking mechanisms enhanced for longitudinal observation.",
        domain: "Preparation",
      },
    ],
    "care-navigation": [
      {
        name: "Provider Matching Criteria",
        description: "Provider search logic updated to expand matching criteria and improve discovery pathways.",
        domain: "Navigation",
      },
    ],
    "community-support": [
      {
        name: "Moderation Workflow",
        description: "Administrative tools for community oversight refined with batch processing capabilities.",
        domain: "Engagement",
      },
      {
        name: "Thread Notification Logic",
        description: "Reply notification mechanisms corrected to properly handle nested conversation structures.",
        domain: "Engagement",
      },
    ],
    "self-reflection": [
      {
        name: "Emotional State Indicators",
        description: "Journal entry interface expanded to include mood indicator collection.",
        domain: "Reflection",
      },
    ],
    "birth-planning": [
      {
        name: "Planning Template Expansion",
        description: "Birth preparation documentation templates expanded with 15 additional structured options.",
        domain: "Planning",
      },
    ],
  };

  const domainNames: Record<string, string> = {
    "care-understanding": "Care Understanding",
    "care-preparation": "Care Preparation",
    "care-navigation": "Care Navigation",
    "community-support": "Community Support",
    "self-reflection": "Self-Reflection",
    "birth-planning": "Birth Planning",
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "operational":
        return { bg: '#e8f5e9', color: '#2e7d32', text: 'Operational' };
      case "monitoring":
        return { bg: '#fff3e0', color: '#e65100', text: 'Monitoring' };
      case "maintenance":
        return { bg: '#f5f5f5', color: '#616161', text: 'Maintenance' };
      default:
        return { bg: '#f5f5f5', color: '#616161', text: 'Unknown' };
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  const filteredFeatures = platformFeatures.filter((feature) => {
    const matchesSearch = feature.name.toLowerCase().includes(featureSearchQuery.toLowerCase()) ||
                         feature.description.toLowerCase().includes(featureSearchQuery.toLowerCase());
    const matchesDomain = selectedDomain === "all" || feature.domain === selectedDomain;
    return matchesSearch && matchesDomain;
  });

  const recentlyUpdatedFeatures = platformFeatures.filter(f => f.lastUpdated === "Mar 1, 2026");

  const domainOptions = ["all", ...Array.from(new Set(platformFeatures.map(f => f.domain)))];

  const serviceStatus = [
    { name: "API Services", status: "operational" as const, uptime: "99.98%" },
    { name: "Data Storage", status: "operational" as const, uptime: "99.99%" },
    { name: "Analytics Pipeline", status: "operational" as const, uptime: "99.95%" },
    { name: "User Segmentation", status: "operational" as const, uptime: "99.97%" },
    { name: "Notification Delivery", status: "operational" as const, uptime: "99.96%" },
    { name: "Authentication", status: "operational" as const, uptime: "99.99%" },
  ];

  return (
    <div>
      {/* Platform Status Summary */}
      <div
        className="p-8 rounded-2xl border mb-8"
        style={{
          backgroundColor: 'white',
          borderColor: '#e0e0e0',
        }}
      >
        <div className="mb-6">
          <h2 className="text-xl mb-3" style={{ color: '#424242' }}>
            Current Release
          </h2>
          <p className="text-base leading-relaxed" style={{ color: '#616161' }}>
            Platform version {currentRelease.version}+{currentRelease.buildNumber} deployed on {currentRelease.deployedAt}. All systems operational.
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-3 mb-6">
          <div
            className="p-4 rounded-xl"
            style={{ backgroundColor: '#fafafa', borderLeft: '4px solid #9575cd' }}
          >
            <div className="text-sm mb-1" style={{ color: '#757575' }}>
              Version
            </div>
            <div className="flex items-center gap-2">
              <span className="text-lg" style={{ color: '#424242' }}>
                {currentRelease.version}+{currentRelease.buildNumber}
              </span>
              <button
                onClick={() => copyToClipboard(`${currentRelease.version}+${currentRelease.buildNumber}`)}
                className="p-1 rounded transition-colors"
                style={{ color: '#757575' }}
                onMouseEnter={(e) => (e.currentTarget.style.color = '#424242')}
                onMouseLeave={(e) => (e.currentTarget.style.color = '#757575')}
              >
                <Copy className="w-4 h-4" />
              </button>
            </div>
          </div>

          <div
            className="p-4 rounded-xl"
            style={{ backgroundColor: '#fafafa', borderLeft: '4px solid #9575cd' }}
          >
            <div className="text-sm mb-1" style={{ color: '#757575' }}>
              Deployed
            </div>
            <div className="flex items-center gap-2 text-lg" style={{ color: '#424242' }}>
              <Calendar className="w-4 h-4" />
              {currentRelease.deployedAt}
            </div>
          </div>

          <div
            className="p-4 rounded-xl"
            style={{ backgroundColor: '#fafafa', borderLeft: '4px solid #9575cd' }}
          >
            <div className="text-sm mb-1" style={{ color: '#757575' }}>
              Status
            </div>
            <div
              className="inline-block px-3 py-1 rounded-md text-sm mt-1"
              style={{
                backgroundColor: getStatusColor(currentRelease.status).bg,
                color: getStatusColor(currentRelease.status).color,
              }}
            >
              {getStatusColor(currentRelease.status).text}
            </div>
          </div>
        </div>

        <div className="flex gap-3">
          <button
            onClick={() => setSelectedRelease(currentRelease)}
            className="px-6 py-2 rounded-xl transition-all"
            style={{
              backgroundColor: '#9575cd',
              color: 'white',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#7e57c2')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#9575cd')}
          >
            View Release Notes
          </button>
          <a
            href={`https://github.com/org/empowerhealth/commit/${currentRelease.commit}`}
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-2 rounded-xl transition-all flex items-center gap-2"
            style={{
              backgroundColor: '#f5f5f5',
              color: '#616161',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
          >
            <GitCommit className="w-4 h-4" />
            {currentRelease.commit}
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      </div>

      {/* Recent Updates - Feed Section */}
      <div
        className="p-8 rounded-2xl border mb-8"
        style={{
          backgroundColor: 'white',
          borderColor: '#e0e0e0',
        }}
      >
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl mb-2" style={{ color: '#424242' }}>
              Latest Updates
            </h2>
            <p className="text-base" style={{ color: '#616161' }}>
              Recent platform improvements and feature releases
            </p>
          </div>
          <div
            className="px-4 py-2 rounded-full text-sm"
            style={{
              backgroundColor: '#f3e5f5',
              color: '#7e57c2',
            }}
          >
            {recentlyUpdatedFeatures.length} new updates
          </div>
        </div>

        {/* Feed-style updates */}
        <div className="space-y-4">
          {recentlyUpdatedFeatures.map((feature) => (
            <div
              key={feature.id}
              className="p-6 rounded-xl border transition-all"
              style={{
                backgroundColor: '#fafafa',
                borderColor: '#e0e0e0',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = 'white';
                e.currentTarget.style.borderColor = '#9575cd';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = '#fafafa';
                e.currentTarget.style.borderColor = '#e0e0e0';
              }}
            >
              {/* Post Header */}
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div
                    className="w-12 h-12 rounded-full flex items-center justify-center"
                    style={{
                      backgroundColor: '#e8eaf6',
                    }}
                  >
                    <Sparkles className="w-6 h-6" style={{ color: '#7e57c2' }} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm" style={{ color: '#424242' }}>
                        Platform Engineering Team
                      </span>
                      <span className="text-xs" style={{ color: '#9e9e9e' }}>•</span>
                      <span className="text-xs" style={{ color: '#9e9e9e' }}>
                        {feature.lastUpdated}
                      </span>
                    </div>
                    <div className="text-xs" style={{ color: '#757575' }}>
                      Feature Update · {feature.domain}
                    </div>
                  </div>
                </div>
              </div>

              {/* Post Content */}
              <div className="mb-4">
                <h3 className="text-base mb-2" style={{ color: '#424242' }}>
                  {feature.updateHighlight}
                </h3>
                <p className="text-sm leading-relaxed mb-3" style={{ color: '#616161' }}>
                  {feature.description}
                </p>

                {/* Feature Tags */}
                <div className="flex flex-wrap gap-2 mb-3">
                  <div
                    className="px-3 py-1 rounded-full text-xs flex items-center gap-1"
                    style={{
                      backgroundColor: '#e8eaf6',
                      color: '#5e35b1',
                    }}
                  >
                    #{feature.name.toLowerCase().replace(/\s+/g, '-')}
                  </div>
                  <div
                    className="px-3 py-1 rounded-full text-xs"
                    style={{
                      backgroundColor: '#f3e5f5',
                      color: '#7e57c2',
                    }}
                  >
                    #{feature.domain.toLowerCase().replace(/\s+/g, '-')}
                  </div>
                  <div
                    className="px-3 py-1 rounded-full text-xs"
                    style={{
                      backgroundColor: '#f5f5f5',
                      color: '#616161',
                    }}
                  >
                    #{feature.category.toLowerCase()}
                  </div>
                </div>
              </div>

              {/* Post Metrics & CTA */}
              <div
                className="pt-4 border-t flex items-center justify-between"
                style={{ borderColor: '#e0e0e0' }}
              >
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <Users className="w-4 h-4" style={{ color: '#757575' }} />
                    <span className="text-sm" style={{ color: '#757575' }}>
                      {feature.analytics.activeUsers} active users
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <TrendingUp className="w-4 h-4" style={{ color: '#2e7d32' }} />
                    <span className="text-sm" style={{ color: '#757575' }}>
                      {feature.analytics.adoptionRate}% adoption
                    </span>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedFeature(feature)}
                  className="px-4 py-2 rounded-lg text-sm transition-all flex items-center gap-2"
                  style={{
                    backgroundColor: 'transparent',
                    color: '#9575cd',
                    border: '1px solid #9575cd',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = '#9575cd';
                    e.currentTarget.style.color = 'white';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = 'transparent';
                    e.currentTarget.style.color = '#9575cd';
                  }}
                >
                  View Analytics
                  <ArrowUpRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Key Metrics Dashboard + System Reliability */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4 mb-8">
        <div
          className="p-6 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm" style={{ color: '#757575' }}>Total Platform Users</h3>
            <Users className="w-5 h-5" style={{ color: '#9575cd' }} />
          </div>
          <div className="text-3xl mb-2" style={{ color: '#424242' }}>850</div>
          <div className="flex items-center gap-1 text-sm" style={{ color: '#2e7d32' }}>
            <TrendingUp className="w-4 h-4" />
            <span>+12.3% this month</span>
          </div>
        </div>

        <div
          className="p-6 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm" style={{ color: '#757575' }}>Active Features</h3>
            <Activity className="w-5 h-5" style={{ color: '#9575cd' }} />
          </div>
          <div className="text-3xl mb-2" style={{ color: '#424242' }}>{platformFeatures.length}</div>
          <div className="flex items-center gap-1 text-sm" style={{ color: '#757575' }}>
            <span>Across {domainOptions.length - 1} domains</span>
          </div>
        </div>

        <div
          className="p-6 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm" style={{ color: '#757575' }}>Avg. Engagement Rate</h3>
            <BarChart3 className="w-5 h-5" style={{ color: '#9575cd' }} />
          </div>
          <div className="text-3xl mb-2" style={{ color: '#424242' }}>72.5%</div>
          <div className="flex items-center gap-1 text-sm" style={{ color: '#2e7d32' }}>
            <TrendingUp className="w-4 h-4" />
            <span>+5.2% from last release</span>
          </div>
        </div>

        {/* System Reliability Widget */}
        <div
          className="p-6 rounded-2xl border"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
        >
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm" style={{ color: '#757575' }}>System Status</h3>
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: '#2e7d32' }}
            />
          </div>
          <div className="text-lg mb-3" style={{ color: '#424242' }}>All Systems Operational</div>
          <div className="space-y-2">
            {serviceStatus.slice(0, 3).map((service) => (
              <div key={service.name} className="flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <div
                    className="w-2 h-2 rounded-full"
                    style={{
                      backgroundColor: service.status === 'operational' ? '#2e7d32' : '#d32f2f'
                    }}
                  />
                  <span style={{ color: '#616161' }}>{service.name}</span>
                </div>
                <span style={{ color: '#9e9e9e' }}>{service.uptime}</span>
              </div>
            ))}
          </div>
          <button
            onClick={() => {
              // You can add modal or link to full system status
            }}
            className="mt-3 text-xs w-full text-center py-2 rounded-lg transition-colors"
            style={{
              backgroundColor: '#f5f5f5',
              color: '#616161',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
          >
            View All Services →
          </button>
        </div>
      </div>

      {/* Platform Features Catalog */}
      <div
        className="p-8 rounded-2xl border mb-8"
        style={{
          backgroundColor: 'white',
          borderColor: '#e0e0e0',
        }}
      >
        <div className="mb-6">
          <h2 className="text-xl mb-3" style={{ color: '#424242' }}>
            Platform Features Catalog
          </h2>
          <p className="text-base leading-relaxed mb-6" style={{ color: '#616161' }}>
            Browse all platform features with detailed analytics, implementation information, and performance insights.
          </p>

          {/* Search and Filter */}
          <div className="grid gap-4 md:grid-cols-2 mb-6">
            <div className="relative">
              <Search
                className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5"
                style={{ color: '#9e9e9e' }}
              />
              <input
                type="text"
                placeholder="Search features..."
                value={featureSearchQuery}
                onChange={(e) => setFeatureSearchQuery(e.target.value)}
                className="w-full pl-12 pr-4 py-3 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                  color: '#424242',
                }}
              />
            </div>
            <select
              value={selectedDomain}
              onChange={(e) => setSelectedDomain(e.target.value)}
              className="px-4 py-3 rounded-xl border"
              style={{
                backgroundColor: 'white',
                borderColor: '#e0e0e0',
                color: '#424242',
              }}
            >
              <option value="all">All Domains</option>
              {domainOptions.filter(d => d !== "all").map((domain) => (
                <option key={domain} value={domain}>{domain}</option>
              ))}
            </select>
          </div>
        </div>

        {/* Features Grid */}
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {filteredFeatures.map((feature) => (
            <div
              key={feature.id}
              onClick={() => setSelectedFeature(feature)}
              className="p-5 rounded-xl border cursor-pointer transition-all"
              style={{
                backgroundColor: '#fafafa',
                borderColor: '#e0e0e0',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#9575cd';
                e.currentTarget.style.backgroundColor = 'white';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = '#e0e0e0';
                e.currentTarget.style.backgroundColor = '#fafafa';
              }}
            >
              <div className="flex items-start justify-between mb-3">
                <h3 className="text-sm pr-2" style={{ color: '#424242' }}>
                  {feature.name}
                </h3>
                <BarChart3 className="w-4 h-4 flex-shrink-0" style={{ color: '#9575cd' }} />
              </div>

              <div
                className="text-xs px-2 py-1 rounded-md inline-block mb-3"
                style={{
                  backgroundColor: '#e8eaf6',
                  color: '#5e35b1',
                }}
              >
                {feature.domain}
              </div>

              <p className="text-xs leading-relaxed mb-3" style={{ color: '#757575' }}>
                {feature.description.slice(0, 100)}...
              </p>

              <div className="grid grid-cols-2 gap-3 mb-3">
                <div>
                  <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Active Users</div>
                  <div className="text-sm" style={{ color: '#424242' }}>{feature.analytics.activeUsers}</div>
                </div>
                <div>
                  <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Adoption</div>
                  <div className="text-sm" style={{ color: '#424242' }}>{feature.analytics.adoptionRate}%</div>
                </div>
              </div>

              <div className="text-xs" style={{ color: '#9575cd' }}>
                View detailed insights →
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Deployment History Table */}
      <div
        className="rounded-2xl border overflow-hidden"
        style={{
          backgroundColor: 'white',
          borderColor: '#e0e0e0',
        }}
      >
        <div className="px-6 py-4 border-b" style={{ borderColor: '#e0e0e0' }}>
          <h3 className="text-lg" style={{ color: '#424242' }}>Deployment History</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr style={{ backgroundColor: '#fafafa' }}>
                <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                  Version
                </th>
                <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                  Deployed
                </th>
                <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                  Status
                </th>
                <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                  Commit
                </th>
                <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                  Summary
                </th>
              </tr>
            </thead>
            <tbody>
              {releaseHistory.map((release, index) => (
                <tr
                  key={index}
                  onClick={() => setSelectedRelease(release)}
                  className={`cursor-pointer transition-colors ${
                    index !== releaseHistory.length - 1 ? "border-b" : ""
                  }`}
                  style={{
                    borderColor: '#f5f5f5',
                    backgroundColor: 'transparent',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = '#fafafa';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = 'transparent';
                  }}
                >
                  <td className="px-6 py-4">
                    <span style={{ color: '#424242' }}>
                      {release.version}+{release.buildNumber}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm" style={{ color: '#757575' }}>
                      {release.deployedAt}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div
                      className="inline-block px-3 py-1 rounded-md text-xs"
                      style={{
                        backgroundColor: getStatusColor(release.status).bg,
                        color: getStatusColor(release.status).color,
                      }}
                    >
                      {getStatusColor(release.status).text}
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm font-mono" style={{ color: '#757575' }}>
                      {release.commit}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className="text-sm" style={{ color: '#757575' }}>
                      {release.notes}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Feature Detail Modal */}
      {selectedFeature && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <div
            className="absolute inset-0"
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.5)' }}
            onClick={() => setSelectedFeature(null)}
          />

          {/* Modal */}
          <div
            className="relative w-full max-w-6xl max-h-[90vh] overflow-y-auto rounded-2xl shadow-2xl"
            style={{ backgroundColor: 'white' }}
          >
            {/* Modal Header */}
            <div
              className="sticky top-0 p-6 border-b"
              style={{
                backgroundColor: 'white',
                borderColor: '#e0e0e0',
                zIndex: 10,
              }}
            >
              <div className="flex items-start justify-between">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <h2 className="text-2xl" style={{ color: '#424242' }}>
                      {selectedFeature.name}
                    </h2>
                    <div
                      className="px-3 py-1 rounded-md text-sm"
                      style={{
                        backgroundColor: '#e8eaf6',
                        color: '#5e35b1',
                      }}
                    >
                      {selectedFeature.domain}
                    </div>
                    {selectedFeature.lastUpdated && (
                      <div
                        className="px-3 py-1 rounded-md text-sm flex items-center gap-1"
                        style={{
                          backgroundColor: '#f3e5f5',
                          color: '#7e57c2',
                        }}
                      >
                        <Clock className="w-3 h-3" />
                        Updated {selectedFeature.lastUpdated}
                      </div>
                    )}
                  </div>
                  <p className="text-base leading-relaxed" style={{ color: '#757575' }}>
                    {selectedFeature.description}
                  </p>
                  {selectedFeature.updateHighlight && (
                    <div
                      className="mt-3 p-3 rounded-lg flex items-start gap-2"
                      style={{ backgroundColor: '#f3e5f5' }}
                    >
                      <Sparkles className="w-4 h-4 mt-0.5 flex-shrink-0" style={{ color: '#9575cd' }} />
                      <p className="text-sm" style={{ color: '#5e35b1' }}>
                        <strong>Latest Update:</strong> {selectedFeature.updateHighlight}
                      </p>
                    </div>
                  )}
                </div>
                <button
                  onClick={() => setSelectedFeature(null)}
                  className="p-2 rounded-lg transition-colors flex-shrink-0"
                  style={{ color: '#757575' }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <X className="w-6 h-6" />
                </button>
              </div>
            </div>

            {/* Modal Content */}
            <div className="p-6">
              {/* Analytics Overview */}
              <div className="grid gap-6 md:grid-cols-4 mb-8">
                <div
                  className="p-4 rounded-xl"
                  style={{ backgroundColor: '#fafafa' }}
                >
                  <div className="text-xs mb-2" style={{ color: '#9e9e9e' }}>Active Users</div>
                  <div className="text-2xl mb-1" style={{ color: '#424242' }}>
                    {selectedFeature.analytics.activeUsers}
                  </div>
                  <div className="text-xs" style={{ color: '#2e7d32' }}>
                    <TrendingUp className="w-3 h-3 inline mr-1" />
                    Growing
                  </div>
                </div>
                <div
                  className="p-4 rounded-xl"
                  style={{ backgroundColor: '#fafafa' }}
                >
                  <div className="text-xs mb-2" style={{ color: '#9e9e9e' }}>Adoption Rate</div>
                  <div className="text-2xl mb-1" style={{ color: '#424242' }}>
                    {selectedFeature.analytics.adoptionRate}%
                  </div>
                  <div className="text-xs" style={{ color: '#757575' }}>
                    Of total users
                  </div>
                </div>
                <div
                  className="p-4 rounded-xl col-span-2"
                  style={{ backgroundColor: '#fafafa' }}
                >
                  <div className="text-xs mb-2" style={{ color: '#9e9e9e' }}>Feature Category</div>
                  <div className="text-lg mb-1" style={{ color: '#424242' }}>
                    {selectedFeature.category}
                  </div>
                  <div className="text-xs" style={{ color: '#757575' }}>
                    {selectedFeature.domain} domain
                  </div>
                </div>
              </div>

              {/* Charts */}
              <div className="grid gap-6 md:grid-cols-2 mb-8">
                <div
                  className="p-6 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                  }}
                >
                  <h3 className="text-sm mb-4" style={{ color: '#424242' }}>
                    User Engagement Trend
                  </h3>
                  <ResponsiveContainer width="100%" height={200}>
                    <LineChart data={selectedFeature.analytics.engagementTrend}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                      <XAxis dataKey="date" stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                      <YAxis stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'white',
                          border: '1px solid #e0e0e0',
                          borderRadius: '8px',
                          fontSize: '12px',
                        }}
                      />
                      <Line
                        type="monotone"
                        dataKey="value"
                        stroke="#9575cd"
                        strokeWidth={2}
                        dot={{ fill: '#9575cd', r: 3 }}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>

                <div
                  className="p-6 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                  }}
                >
                  <h3 className="text-sm mb-4" style={{ color: '#424242' }}>
                    Weekly Usage
                  </h3>
                  <ResponsiveContainer width="100%" height={200}>
                    <BarChart data={selectedFeature.analytics.usageByWeek}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                      <XAxis dataKey="week" stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                      <YAxis stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                      <Tooltip
                        contentStyle={{
                          backgroundColor: 'white',
                          border: '1px solid #e0e0e0',
                          borderRadius: '8px',
                          fontSize: '12px',
                        }}
                      />
                      <Bar dataKey="sessions" fill="#9575cd" radius={[4, 4, 0, 0]} />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* KPIs */}
              <div
                className="p-6 rounded-xl border mb-8"
                style={{
                  backgroundColor: '#fafafa',
                  borderColor: '#e0e0e0',
                }}
              >
                <div className="flex items-center gap-2 mb-4">
                  <BarChart3 className="w-5 h-5" style={{ color: '#9575cd' }} />
                  <h3 className="text-lg" style={{ color: '#424242' }}>
                    Key Performance Indicators
                  </h3>
                </div>
                <div className="space-y-4">
                  {selectedFeature.kpis.map((kpi, idx) => (
                    <div
                      key={idx}
                      className="p-5 rounded-xl"
                      style={{
                        backgroundColor: 'white',
                        border: '1px solid #e0e0e0',
                      }}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <h4 className="text-sm mb-1" style={{ color: '#424242' }}>
                            {kpi.name}
                          </h4>
                          <div className="flex items-center gap-3">
                            <span className="text-2xl" style={{ color: '#424242' }}>
                              {kpi.value}
                            </span>
                            <span
                              className="text-sm px-2 py-1 rounded-md"
                              style={{
                                backgroundColor: kpi.trend.includes('New') ? '#e8eaf6' : '#e8f5e9',
                                color: kpi.trend.includes('New') ? '#5e35b1' : '#2e7d32',
                              }}
                            >
                              {kpi.trend}
                            </span>
                          </div>
                        </div>
                        <div className="text-right">
                          <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Target</div>
                          <div className="text-sm" style={{ color: '#757575' }}>{kpi.target}</div>
                        </div>
                      </div>
                      <p className="text-sm leading-relaxed" style={{ color: '#757575' }}>
                        {kpi.impact}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Implementation Details */}
              <div
                className="p-6 rounded-xl border mb-8"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                }}
              >
                <div className="flex items-center gap-2 mb-4">
                  <Code2 className="w-5 h-5" style={{ color: '#9575cd' }} />
                  <h3 className="text-lg" style={{ color: '#424242' }}>
                    Implementation Details
                  </h3>
                </div>
                <div className="space-y-4">
                  <div>
                    <h4 className="text-sm mb-2" style={{ color: '#757575' }}>Architecture Overview</h4>
                    <p className="text-base leading-relaxed" style={{ color: '#616161' }}>
                      {selectedFeature.implementation.architecture}
                    </p>
                  </div>
                  <div>
                    <h4 className="text-sm mb-2" style={{ color: '#757575' }}>Key Components</h4>
                    <div className="flex flex-wrap gap-2">
                      {selectedFeature.implementation.components.map((component, idx) => (
                        <span
                          key={idx}
                          className="px-3 py-1 rounded-md text-sm"
                          style={{
                            backgroundColor: '#f5f5f5',
                            color: '#616161',
                          }}
                        >
                          {component}
                        </span>
                      ))}
                    </div>
                  </div>
                  <div>
                    <h4 className="text-sm mb-2" style={{ color: '#757575' }}>Data Flow</h4>
                    <p className="text-base leading-relaxed font-mono text-sm" style={{ color: '#616161' }}>
                      {selectedFeature.implementation.dataFlow}
                    </p>
                  </div>
                </div>
              </div>

              {/* Change History */}
              <div
                className="p-6 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                }}
              >
                <div className="flex items-center gap-2 mb-4">
                  <History className="w-5 h-5" style={{ color: '#9575cd' }} />
                  <h3 className="text-lg" style={{ color: '#424242' }}>
                    Change History
                  </h3>
                </div>
                <div className="space-y-3">
                  {selectedFeature.changeHistory.map((change, idx) => (
                    <div
                      key={idx}
                      className="flex gap-4 pb-3 border-b last:border-b-0"
                      style={{ borderColor: '#f5f5f5' }}
                    >
                      <div
                        className="w-2 h-2 rounded-full mt-2 flex-shrink-0"
                        style={{ backgroundColor: '#9575cd' }}
                      />
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-1">
                          <span className="text-sm font-mono" style={{ color: '#9575cd' }}>
                            {change.version}
                          </span>
                          <span className="text-xs" style={{ color: '#9e9e9e' }}>
                            {change.date}
                          </span>
                        </div>
                        <p className="text-sm leading-relaxed" style={{ color: '#616161' }}>
                          {change.change}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Release Notes Drawer */}
      {selectedRelease && (
        <div className="fixed inset-0 z-50 flex items-start justify-end">
          {/* Backdrop */}
          <div
            className="absolute inset-0"
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.4)' }}
            onClick={() => setSelectedRelease(null)}
          />

          {/* Drawer */}
          <div
            className="relative w-full max-w-3xl h-full overflow-y-auto shadow-2xl"
            style={{ backgroundColor: '#fafafa' }}
          >
            {/* Drawer Header */}
            <div
              className="sticky top-0 p-6 border-b"
              style={{
                backgroundColor: 'white',
                borderColor: '#e0e0e0',
              }}
            >
              <div className="flex items-start justify-between mb-4">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <h2 className="text-xl" style={{ color: '#424242' }}>
                      Version {selectedRelease.version}+{selectedRelease.buildNumber}
                    </h2>
                    <div
                      className="px-3 py-1 rounded-md text-sm"
                      style={{
                        backgroundColor: '#f5f5f5',
                        color: '#616161',
                      }}
                    >
                      {selectedRelease.environment}
                    </div>
                  </div>
                  <p className="text-sm mb-2" style={{ color: '#757575' }}>
                    Deployed {selectedRelease.deployedAt}
                  </p>
                  <a
                    href={`https://github.com/org/empowerhealth/commit/${selectedRelease.commit}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center gap-2 text-sm"
                    style={{ color: '#9575cd' }}
                  >
                    <GitCommit className="w-4 h-4" />
                    Commit: {selectedRelease.commit}
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
                <button
                  onClick={() => setSelectedRelease(null)}
                  className="p-2 rounded-lg transition-colors"
                  style={{ color: '#757575' }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="flex gap-2">
                <button
                  onClick={() =>
                    copyToClipboard(`${selectedRelease.version}+${selectedRelease.buildNumber}`)
                  }
                  className="px-4 py-2 rounded-xl text-sm transition-all"
                  style={{
                    backgroundColor: '#f5f5f5',
                    color: '#616161',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                >
                  <Copy className="w-4 h-4 inline mr-2" />
                  Copy Version
                </button>
                <button
                  onClick={() => copyToClipboard(selectedRelease.commit)}
                  className="px-4 py-2 rounded-xl text-sm transition-all"
                  style={{
                    backgroundColor: '#f5f5f5',
                    color: '#616161',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                >
                  <Copy className="w-4 h-4 inline mr-2" />
                  Copy Commit
                </button>
              </div>
            </div>

            {/* Release Notes Content */}
            <div className="p-6">
              <div className="flex items-start gap-3 mb-6">
                <FileText className="w-6 h-6 mt-1" style={{ color: '#9575cd' }} />
                <div>
                  <h3 className="text-lg mb-2" style={{ color: '#424242' }}>
                    Release Notes
                  </h3>
                  <p className="text-sm leading-relaxed" style={{ color: '#757575' }}>
                    Summary of changes and updates included in this release.
                  </p>
                </div>
              </div>

              {/* Search Bar */}
              <div className="mb-6 relative">
                <Search
                  className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5"
                  style={{ color: '#9e9e9e' }}
                />
                <input
                  type="text"
                  placeholder="Search updates..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-12 pr-4 py-3 rounded-xl border"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                    color: '#424242',
                  }}
                />
              </div>

              {/* Domain Accordions */}
              <div className="space-y-3">
                {Object.entries(domainNames).map(([key, name]) => {
                  const updates = functionalUpdates[key] || [];
                  const isExpanded = expandedDomain === key;

                  return (
                    <div
                      key={key}
                      className="rounded-xl border overflow-hidden"
                      style={{
                        backgroundColor: 'white',
                        borderColor: '#e0e0e0',
                      }}
                    >
                      <button
                        onClick={() => setExpandedDomain(isExpanded ? null : key)}
                        className="w-full flex items-center justify-between p-4 transition-colors"
                        style={{
                          backgroundColor: isExpanded ? '#fafafa' : 'transparent',
                        }}
                        onMouseEnter={(e) => {
                          if (!isExpanded) e.currentTarget.style.backgroundColor = '#fafafa';
                        }}
                        onMouseLeave={(e) => {
                          if (!isExpanded) e.currentTarget.style.backgroundColor = 'transparent';
                        }}
                      >
                        <div className="flex items-center gap-3">
                          <span style={{ color: '#424242' }}>{name}</span>
                          <span
                            className="px-2 py-0.5 rounded-md text-xs"
                            style={{
                              backgroundColor: '#f5f5f5',
                              color: '#757575',
                            }}
                          >
                            {updates.length}
                          </span>
                        </div>
                        <ChevronDown
                          className={`w-5 h-5 transition-transform ${
                            isExpanded ? "rotate-180" : ""
                          }`}
                          style={{ color: '#9e9e9e' }}
                        />
                      </button>

                      {isExpanded && (
                        <div className="border-t" style={{ borderColor: '#e0e0e0' }}>
                          {updates.map((update, idx) => (
                            <div
                              key={idx}
                              className="p-5 border-b last:border-b-0"
                              style={{ borderColor: '#f5f5f5' }}
                            >
                              <div className="flex items-start justify-between mb-2">
                                <h4 className="text-sm" style={{ color: '#424242' }}>
                                  {update.name}
                                </h4>
                                <div
                                  className="px-2 py-1 rounded-md text-xs"
                                  style={{
                                    backgroundColor: '#e8eaf6',
                                    color: '#5e35b1',
                                  }}
                                >
                                  {update.domain}
                                </div>
                              </div>
                              <p className="text-sm leading-relaxed" style={{ color: '#757575' }}>
                                {update.description}
                              </p>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
