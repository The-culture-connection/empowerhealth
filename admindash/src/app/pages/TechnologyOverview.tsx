import { Calendar, GitCommit, ExternalLink, Copy, Search, ChevronDown, X, FileText, BarChart3, TrendingUp, Sparkles, ArrowUpRight, Users, Clock, Code2, History, Loader2 } from "lucide-react";
import { useState, useEffect } from "react";
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { format } from "date-fns";
import { 
  getCurrentProductionRelease, 
  getLatestReleases, 
  extractFunctionalUpdates,
  getGitHubCommitUrl,
  Release 
} from "../../lib/releases";
import { getLatestCommits, Commit, getGitHubCommitUrl as getCommitUrl } from "../../lib/commits";
import { getAllFeatures, TechnologyFeature, getFeatureChangeHistory, getFeatureById } from "../../lib/features";
import { getFeatureAnalytics, FeatureAnalytics } from "../../lib/featureAnalytics";
import { useAuth } from "../../contexts/AuthContext";
import { FeatureEditModal } from "../components/FeatureEditModal";

export function TechnologyOverview() {
  const { isAdmin } = useAuth(); // Will be used for admin editing features
  const [selectedRelease, setSelectedRelease] = useState<Release | null>(null);
  const [selectedFeature, setSelectedFeature] = useState<TechnologyFeature | null>(null);
  const [selectedFeatureAnalytics, setSelectedFeatureAnalytics] = useState<FeatureAnalytics | null>(null);
  const [selectedFeatureChangeHistory, setSelectedFeatureChangeHistory] = useState<any[]>([]);
  const [editingFeature, setEditingFeature] = useState<TechnologyFeature | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [expandedDomain, setExpandedDomain] = useState<string | null>(null);
  const [featureSearchQuery, setFeatureSearchQuery] = useState("");
  const [selectedDomain, setSelectedDomain] = useState<string>("all");

  // Data state
  const [currentRelease, setCurrentRelease] = useState<Release | null>(null);
  const [releaseHistory, setReleaseHistory] = useState<Release[]>([]);
  const [platformFeatures, setPlatformFeatures] = useState<TechnologyFeature[]>([]);
  const [commits, setCommits] = useState<Commit[]>([]);
  // functionalUpdates are extracted per-release, not stored in state

  // Loading and error states
  const [loadingRelease, setLoadingRelease] = useState(true);
  const [loadingHistory, setLoadingHistory] = useState(true);
  const [loadingFeatures, setLoadingFeatures] = useState(true);
  const [loadingCommits, setLoadingCommits] = useState(true);
  const [loadingAnalytics, setLoadingAnalytics] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load data on mount
  useEffect(() => {
    loadCurrentRelease();
    loadReleaseHistory();
    loadPlatformFeatures();
    loadCommits();
  }, []);

  // Load analytics and change history when feature modal opens
  useEffect(() => {
    if (selectedFeature) {
      if (!selectedFeatureAnalytics) {
        loadFeatureAnalytics(selectedFeature.id);
      }
      loadFeatureChangeHistory(selectedFeature.id);
    } else {
      setSelectedFeatureAnalytics(null);
      setSelectedFeatureChangeHistory([]);
    }
  }, [selectedFeature]);

  async function loadFeatureChangeHistory(featureId: string) {
    try {
      const history = await getFeatureChangeHistory(featureId);
      setSelectedFeatureChangeHistory(history);
    } catch (err: any) {
      console.error('Failed to load change history:', err);
    }
  }

  async function loadCurrentRelease() {
    setLoadingRelease(true);
    try {
      const release = await getCurrentProductionRelease();
      setCurrentRelease(release);
    } catch (err: any) {
      console.error('Failed to load current release:', err);
      setError(err.message || 'Failed to load current release');
    } finally {
      setLoadingRelease(false);
    }
  }

  async function loadReleaseHistory() {
    setLoadingHistory(true);
    try {
      const releases = await getLatestReleases(13);
      setReleaseHistory(releases);
    } catch (err: any) {
      console.error('Failed to load release history:', err);
      setError(err.message || 'Failed to load release history');
    } finally {
      setLoadingHistory(false);
    }
  }

  async function loadPlatformFeatures() {
    setLoadingFeatures(true);
    try {
      const features = await getAllFeatures();
      setPlatformFeatures(features);
    } catch (err: any) {
      console.error('Failed to load platform features:', err);
      setError(err.message || 'Failed to load platform features');
    } finally {
      setLoadingFeatures(false);
    }
  }

  async function loadCommits() {
    setLoadingCommits(true);
    try {
      const latestCommits = await getLatestCommits(20);
      setCommits(latestCommits);
    } catch (err: any) {
      console.error('Failed to load commits:', err);
      // Don't set error for commits, just log it
    } finally {
      setLoadingCommits(false);
    }
  }

  async function loadFeatureAnalytics(featureId: string) {
    setLoadingAnalytics(true);
    try {
      const dateRange = {
        start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
        end: new Date(),
      };
      const analytics = await getFeatureAnalytics(featureId, dateRange, true);
      setSelectedFeatureAnalytics(analytics);
    } catch (err: any) {
      console.error('Failed to load feature analytics:', err);
    } finally {
      setLoadingAnalytics(false);
    }
  }

  // Domain names mapping
  const domainNames: Record<string, string> = {
    "care-understanding": "Care Understanding",
    "care-preparation": "Care Preparation",
    "care-navigation": "Care Navigation",
    "community-support": "Community Support",
    "self-reflection": "Self-Reflection",
    "birth-planning": "Birth Planning",
  };


  // Filter features
  const filteredFeatures = platformFeatures.filter((feature) => {
    const matchesSearch = feature.name.toLowerCase().includes(featureSearchQuery.toLowerCase()) ||
                         feature.description.toLowerCase().includes(featureSearchQuery.toLowerCase());
    const matchesDomain = selectedDomain === "all" || feature.domain === selectedDomain;
    return matchesSearch && matchesDomain;
  });

  const domainOptions = ["all", ...Array.from(new Set(platformFeatures.map(f => f.domain)))];

  // Get recently updated features (updated in last 7 days)
  const recentlyUpdatedFeatures = platformFeatures.filter(f => {
    if (!f.lastUpdated) return false;
    const daysSinceUpdate = (Date.now() - f.lastUpdated.getTime()) / (1000 * 60 * 60 * 24);
    return daysSinceUpdate <= 7;
  });

  // Helper functions
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

  // Format date helper
  const formatDate = (date: Date | any): string => {
    if (!date) return 'Unknown';
    if (date instanceof Date) {
      return format(date, 'MMM d, yyyy');
    }
    if (date.toDate) {
      return format(date.toDate(), 'MMM d, yyyy');
    }
    return String(date);
  };

  const formatDateShort = (date: Date | any): string => {
    if (!date) return 'Unknown';
    if (date instanceof Date) {
      return format(date, 'MMM d, yyyy');
    }
    if (date.toDate) {
      return format(date.toDate(), 'MMM d, yyyy');
    }
    return String(date);
  };

  // Get functional updates for selected release
  const getReleaseFunctionalUpdates = (release: Release | null): Record<string, any[]> => {
    if (!release) return {};
    return extractFunctionalUpdates(release);
  };

  return (
    <div>
      {/* Platform Status Summary */}
      {loadingRelease ? (
        <div className="flex items-center justify-center py-12 mb-8">
          <Loader2 className="w-8 h-8 animate-spin" style={{ color: '#9575cd' }} />
        </div>
      ) : error ? (
        <div className="p-8 mb-8 rounded-2xl border" style={{ backgroundColor: '#fff3e0', borderColor: '#ff9800' }}>
          <h3 className="text-lg mb-2" style={{ color: '#e65100' }}>Error Loading Release Data</h3>
          <p style={{ color: '#616161' }}>{error}</p>
        </div>
      ) : !currentRelease ? (
        <div className="p-8 mb-8 rounded-2xl border" style={{ backgroundColor: '#fafafa', borderColor: '#e0e0e0' }}>
          <h3 className="text-lg mb-2" style={{ color: '#424242' }}>No Release Data</h3>
          <p style={{ color: '#616161' }}>No production release has been published yet.</p>
        </div>
      ) : (
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
              Platform version {currentRelease.versionName}+{currentRelease.buildNumber} deployed on {formatDate(currentRelease.createdAt || currentRelease.railway?.deployedAt)}. All systems operational.
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
                  {currentRelease.versionName}+{currentRelease.buildNumber}
                </span>
                <button
                  onClick={() => copyToClipboard(`${currentRelease.versionName}+${currentRelease.buildNumber}`)}
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
                {formatDate(currentRelease.createdAt || currentRelease.railway?.deployedAt)}
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
                  backgroundColor: getStatusColor(currentRelease.channel === 'production' ? 'operational' : 'monitoring').bg,
                  color: getStatusColor(currentRelease.channel === 'production' ? 'operational' : 'monitoring').color,
                }}
              >
                {currentRelease.channel === 'production' ? 'Production' : 'Pilot'}
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
            {currentRelease.git?.commitSha && (
              <a
                href={getGitHubCommitUrl(currentRelease.git.commitSha, currentRelease.git.repoUrl)}
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
                {currentRelease.git.commitSha.substring(0, 7)}
                <ExternalLink className="w-3 h-3" />
              </a>
            )}
          </div>
        </div>
      )}

      {/* Recent Updates - Feed Section */}
      {loadingFeatures ? (
        <div className="flex items-center justify-center py-12 mb-8">
          <Loader2 className="w-8 h-8 animate-spin" style={{ color: '#9575cd' }} />
        </div>
      ) : (
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
            {recentlyUpdatedFeatures.length > 0 && (
              <div
                className="px-4 py-2 rounded-full text-sm"
                style={{
                  backgroundColor: '#f3e5f5',
                  color: '#7e57c2',
                }}
              >
                {recentlyUpdatedFeatures.length} new updates
              </div>
            )}
          </div>

          {/* Feed-style updates */}
          {recentlyUpdatedFeatures.length === 0 ? (
            <div className="text-center py-8" style={{ color: '#757575' }}>
              No recent feature updates in the last 7 days.
            </div>
          ) : (
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
                        {feature.lastUpdated ? formatDate(feature.lastUpdated) : 'Unknown'}
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
                {feature.updateHighlight && (
                  <h3 className="text-base mb-2" style={{ color: '#424242' }}>
                    {feature.updateHighlight}
                  </h3>
                )}
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
                      View analytics
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
          )}
        </div>
      )}

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

              {/* How the Feature Works - Preview */}
              {feature.howItWorks && (
                <div className="mb-3 p-2 rounded-lg" style={{ backgroundColor: '#f3e5f5' }}>
                  <div className="text-xs font-semibold mb-1" style={{ color: '#7e57c2' }}>
                    How it works:
                  </div>
                  <p className="text-xs leading-relaxed" style={{ color: '#616161' }}>
                    {feature.howItWorks.slice(0, 80)}...
                  </p>
                </div>
              )}

              {/* Recent Updates - Preview */}
              {feature.recentUpdates && feature.recentUpdates.length > 0 && (
                <div className="mb-3">
                  <div className="text-xs font-semibold mb-1" style={{ color: '#9575cd' }}>
                    Recent Updates:
                  </div>
                  <ul className="text-xs space-y-1" style={{ color: '#757575' }}>
                    {feature.recentUpdates.slice(0, 2).map((update: string, idx: number) => (
                      <li key={idx} className="flex items-start gap-1">
                        <span className="text-[#9575cd] mt-0.5">•</span>
                        <span>{update.slice(0, 60)}...</span>
                      </li>
                    ))}
                    {feature.recentUpdates.length > 2 && (
                      <li className="text-xs" style={{ color: '#9e9e9e' }}>
                        +{feature.recentUpdates.length - 2} more
                      </li>
                    )}
                  </ul>
                </div>
              )}

              {feature.lastUpdated && (
                <div className="text-xs mb-3" style={{ color: '#9e9e9e' }}>
                  Updated {formatDate(feature.lastUpdated)}
                </div>
              )}

              <div className="text-xs" style={{ color: '#9575cd' }}>
                View detailed insights →
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Deployment History Table */}
      {loadingHistory || loadingCommits ? (
        <div className="flex items-center justify-center py-12 mb-8">
          <Loader2 className="w-8 h-8 animate-spin" style={{ color: '#9575cd' }} />
        </div>
      ) : commits.length === 0 && releaseHistory.length === 0 ? (
        <div className="p-8 mb-8 rounded-2xl border" style={{ backgroundColor: '#fafafa', borderColor: '#e0e0e0' }}>
          <h3 className="text-lg mb-2" style={{ color: '#424242' }}>No Deployment History</h3>
          <p style={{ color: '#616161' }}>No commits or releases have been tracked yet.</p>
        </div>
      ) : (
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
                    Commit
                  </th>
                  <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                    Message
                  </th>
                  <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                    Author
                  </th>
                  <th className="text-left px-6 py-3 text-sm" style={{ color: '#616161' }}>
                    Date
                  </th>
                </tr>
              </thead>
              <tbody>
                {commits.map((commit, index) => (
                  <tr
                    key={commit.commitSha}
                    className={`transition-colors ${
                      index !== commits.length - 1 ? "border-b" : ""
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
                        {commit.fullVersion || (commit.buildNumber ? `Build ${commit.buildNumber}` : 'N/A')}
                      </span>
                      {commit.channel && (
                        <div
                          className="inline-block ml-2 px-2 py-0.5 rounded text-xs"
                          style={{
                            backgroundColor: commit.channel === 'production' ? '#e8f5e9' : '#fff3e0',
                            color: commit.channel === 'production' ? '#2e7d32' : '#e65100',
                          }}
                        >
                          {commit.channel === 'production' ? 'Prod' : 'Pilot'}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <a
                        href={getCommitUrl(commit.commitSha)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-2 text-sm font-mono"
                        style={{ color: '#9575cd' }}
                      >
                        <GitCommit className="w-4 h-4" />
                        {commit.commitSha.substring(0, 7)}
                        <ExternalLink className="w-3 h-3" />
                      </a>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm" style={{ color: '#757575' }}>
                        {commit.commitMessage || 'No message'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm" style={{ color: '#616161' }}>
                        {commit.commitAuthor || 'Unknown'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-sm" style={{ color: '#757575' }}>
                        {formatDateShort(commit.commitDate)}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

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
                        Updated {formatDate(selectedFeature.lastUpdated)}
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
                <div className="flex items-center gap-2">
                  {isAdmin() && (
                    <button
                      onClick={() => setEditingFeature(selectedFeature)}
                      className="px-4 py-2 rounded-lg text-sm transition-all"
                      style={{
                        backgroundColor: '#f5f5f5',
                        color: '#616161',
                      }}
                      onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
                      onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                    >
                      Edit Feature
                    </button>
                  )}
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
            </div>

            {/* Modal Content */}
            <div className="p-6">
              {loadingAnalytics ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="w-8 h-8 animate-spin" style={{ color: '#9575cd' }} />
                </div>
              ) : (
                <>
                  {/* Analytics Overview */}
                  <div className="grid gap-6 md:grid-cols-4 mb-8">
                    <div
                      className="p-4 rounded-xl"
                      style={{ backgroundColor: '#fafafa' }}
                    >
                      <div className="text-xs mb-2" style={{ color: '#9e9e9e' }}>Active Users</div>
                      <div className="text-2xl mb-1" style={{ color: '#424242' }}>
                        {selectedFeatureAnalytics?.activeUsers || 0}
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
                        {selectedFeatureAnalytics?.adoptionRate || 0}%
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
                    <LineChart data={selectedFeatureAnalytics?.engagementTrend || []}>
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
                    <BarChart data={selectedFeatureAnalytics?.usageByWeek || []}>
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

              {/* How the Feature Works */}
              {selectedFeature.howItWorks && (
                <div
                  className="p-6 rounded-xl border mb-8"
                  style={{
                    backgroundColor: '#fafafa',
                    borderColor: '#e0e0e0',
                  }}
                >
                  <div className="flex items-center gap-2 mb-4">
                    <Code2 className="w-5 h-5" style={{ color: '#9575cd' }} />
                    <h3 className="text-lg" style={{ color: '#424242' }}>
                      How the Feature Works
                    </h3>
                  </div>
                  <div className="prose max-w-none">
                    <p className="text-sm leading-relaxed whitespace-pre-wrap" style={{ color: '#616161' }}>
                      {selectedFeature.howItWorks}
                    </p>
                  </div>
                </div>
              )}

              {/* Recent Updates */}
              {selectedFeature.recentUpdates && selectedFeature.recentUpdates.length > 0 && (
                <div
                  className="p-6 rounded-xl border mb-8"
                  style={{
                    backgroundColor: '#fafafa',
                    borderColor: '#e0e0e0',
                  }}
                >
                  <div className="flex items-center gap-2 mb-4">
                    <Sparkles className="w-5 h-5" style={{ color: '#9575cd' }} />
                    <h3 className="text-lg" style={{ color: '#424242' }}>
                      Recent Updates
                    </h3>
                  </div>
                  <div className="space-y-3">
                    {selectedFeature.recentUpdates.map((update, idx) => (
                      <div
                        key={idx}
                        className="p-4 rounded-lg"
                        style={{
                          backgroundColor: 'white',
                          border: '1px solid #e0e0e0',
                        }}
                      >
                        <div className="flex items-start gap-3">
                          <div
                            className="w-2 h-2 rounded-full mt-2 flex-shrink-0"
                            style={{ backgroundColor: '#9575cd' }}
                          />
                          <p className="text-sm leading-relaxed flex-1" style={{ color: '#616161' }}>
                            {update}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

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
                  {selectedFeatureAnalytics?.kpis && Array.isArray(selectedFeatureAnalytics.kpis) ? (
                    selectedFeatureAnalytics.kpis.map((kpi: any, idx: number) => (
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
                                  backgroundColor: kpi.trend?.includes('New') ? '#e8eaf6' : '#e8f5e9',
                                  color: kpi.trend?.includes('New') ? '#5e35b1' : '#2e7d32',
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
                    ))
                  ) : (
                    <div className="text-sm" style={{ color: '#757575' }}>No KPI data available.</div>
                  )}
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
                      {selectedFeature.implementation?.architecture || 'Not specified'}
                              </p>
                  </div>
                  <div>
                    <h4 className="text-sm mb-2" style={{ color: '#757575' }}>Key Components</h4>
                    <div className="flex flex-wrap gap-2">
                      {selectedFeature.implementation?.components?.map((component, idx) => (
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
                      {selectedFeature.implementation?.dataFlow || 'Not specified'}
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
                  {selectedFeatureChangeHistory.length === 0 ? (
                    <div className="text-sm" style={{ color: '#757575' }}>No change history available.</div>
                  ) : (
                    selectedFeatureChangeHistory.map((change, idx) => (
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
                              {formatDate(change.date)}
                            </span>
                          </div>
                          <p className="text-sm leading-relaxed" style={{ color: '#616161' }}>
                            {change.change}
                          </p>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Feature Edit Modal */}
      {editingFeature && (
        <FeatureEditModal
          feature={editingFeature}
          onClose={() => setEditingFeature(null)}
          onSave={() => {
            loadPlatformFeatures();
            if (selectedFeature?.id === editingFeature.id) {
              // Reload selected feature if it was edited
              getFeatureById(editingFeature.id).then(feature => {
                if (feature) {
                  setSelectedFeature(feature);
                }
              });
            }
          }}
        />
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
                      Version {selectedRelease.versionName}+{selectedRelease.buildNumber}
                    </h2>
                    <div
                      className="px-3 py-1 rounded-md text-sm"
                      style={{
                        backgroundColor: '#f5f5f5',
                        color: '#616161',
                      }}
                    >
                      {selectedRelease.channel === 'production' ? 'Production' : 'Pilot'}
                    </div>
                  </div>
                  <p className="text-sm mb-2" style={{ color: '#757575' }}>
                    Deployed {formatDate(selectedRelease.createdAt || selectedRelease.railway?.deployedAt)}
                  </p>
                  {selectedRelease.git?.commitSha && (
                    <a
                      href={getGitHubCommitUrl(selectedRelease.git.commitSha, selectedRelease.git.repoUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-2 text-sm"
                      style={{ color: '#9575cd' }}
                    >
                      <GitCommit className="w-4 h-4" />
                      Commit: {selectedRelease.git.commitSha.substring(0, 7)}
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
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
                    copyToClipboard(`${selectedRelease.versionName}+${selectedRelease.buildNumber}`)
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
                {selectedRelease.git?.commitSha && (
                  <button
                    onClick={() => copyToClipboard(selectedRelease.git.commitSha)}
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
                )}
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
                {Object.entries(getReleaseFunctionalUpdates(selectedRelease)).map(([key, updates]) => {
                  const domainName = domainNames[key] || updates[0]?.domain || key;
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
                          <span style={{ color: '#424242' }}>{domainName}</span>
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
