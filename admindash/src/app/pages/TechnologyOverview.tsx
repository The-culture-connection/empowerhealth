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
import { getLatestCommits, Commit, getGitHubCommitUrl as getCommitUrl, getCommitBySha } from "../../lib/commits";
import { getAllFeatures, TechnologyFeature, getFeatureChangeHistory, getFeatureById } from "../../lib/features";
import { getFeatureAnalytics, FeatureAnalytics } from "../../lib/featureAnalytics";
import { getFeatureAnalyticsSummary, FeatureAnalyticsSummary } from "../../lib/firestoreAnalytics";
import { useAuth } from "../../contexts/AuthContext";
import { KPIGoalsModal } from "../components/KPIGoalsModal";

export function TechnologyOverview() {
  const { isAdmin } = useAuth(); // Will be used for admin editing features
  const [selectedRelease, setSelectedRelease] = useState<Release | null>(null);
  const [selectedCommit, setSelectedCommit] = useState<Commit | null>(null);
  const [selectedFeature, setSelectedFeature] = useState<TechnologyFeature | null>(null);
  const [selectedFeatureAnalytics, setSelectedFeatureAnalytics] = useState<FeatureAnalytics | null>(null);
  const [selectedFeatureFirestoreAnalytics, setSelectedFeatureFirestoreAnalytics] = useState<FeatureAnalyticsSummary | null>(null);
  const [selectedFeatureChangeHistory, setSelectedFeatureChangeHistory] = useState<any[]>([]);
  const [editingKPI, setEditingKPI] = useState<TechnologyFeature | null>(null);
  const [commitFeatureChanges, setCommitFeatureChanges] = useState<any[]>([]);
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
      console.log('🔍 [useEffect] selectedFeature changed:', {
        id: selectedFeature.id,
        name: selectedFeature.name,
        hasId: !!selectedFeature.id,
        featureObject: selectedFeature,
      });
      
      // Validate that feature has an ID
      if (!selectedFeature.id) {
        console.error('❌ [useEffect] selectedFeature.id is undefined!', selectedFeature);
        return;
      }
      
      if (!selectedFeatureAnalytics) {
        loadFeatureAnalytics(selectedFeature.id);
      }
      loadFeatureChangeHistory(selectedFeature.id);
    } else {
      setSelectedFeatureAnalytics(null);
      setSelectedFeatureChangeHistory([]);
    }
  }, [selectedFeature]);

  // Load feature changes for selected commit
  useEffect(() => {
    if (selectedCommit) {
      loadCommitFeatureChanges(selectedCommit.commitSha);
    } else {
      setCommitFeatureChanges([]);
    }
  }, [selectedCommit]);

  async function loadCommitFeatureChanges(commitSha: string) {
    try {
      const changes: any[] = [];
      // Get all features and check their change history for this commit
      const features = await getAllFeatures();
      for (const feature of features) {
        const history = await getFeatureChangeHistory(feature.id);
        const commitChanges = history.filter((change: any) => 
          change.commitSha === commitSha || change.commitSha?.substring(0, 7) === commitSha.substring(0, 7)
        );
        if (commitChanges.length > 0) {
          changes.push({
            feature,
            changes: commitChanges
          });
        }
      }
      setCommitFeatureChanges(changes);
    } catch (err: any) {
      console.error('Failed to load commit feature changes:', err);
      setCommitFeatureChanges([]);
    }
  }

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
      // Try production first, then latest release as fallback
      let release = await getCurrentProductionRelease();
      if (!release) {
        // Fallback: get latest release if no production release
        const latestReleases = await getLatestReleases(1);
        if (latestReleases.length > 0) {
          release = latestReleases[0];
        }
      }
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
      // #region agent log
      fetch('http://127.0.0.1:7243/ingest/ddaaaa74-c4f8-4176-b507-91d3bb5b2296',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'cf9ac6'},body:JSON.stringify({sessionId:'cf9ac6',runId:'features-load-1',hypothesisId:'H1',location:'admindash/src/app/pages/TechnologyOverview.tsx:loadPlatformFeatures',message:'About to set platform features in state',data:{count:features.length,firstThree:features.slice(0,3).map((f)=>({id:f.id,name:f.name,recentUpdatesLen:Array.isArray(f.recentUpdates)?f.recentUpdates.length:0,howItWorksLen:typeof f.howItWorks==='string'?f.howItWorks.length:0}))},timestamp:Date.now()})}).catch(()=>{});
      // #endregion
      setPlatformFeatures(features);
    } catch (err: any) {
      // #region agent log
      fetch('http://127.0.0.1:7243/ingest/ddaaaa74-c4f8-4176-b507-91d3bb5b2296',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'cf9ac6'},body:JSON.stringify({sessionId:'cf9ac6',runId:'features-load-1',hypothesisId:'H3',location:'admindash/src/app/pages/TechnologyOverview.tsx:loadPlatformFeatures',message:'Platform features load failed',data:{error:err?.message ?? 'unknown'},timestamp:Date.now()})}).catch(()=>{});
      // #endregion
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
      // Use a longer date range (90 days) to capture enough history to identify returning users
      // This ensures we can see if users have used the feature before this week
      const dateRange = {
        start: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), // Last 90 days
        end: new Date(),
      };
      
      console.log('📅 [loadFeatureAnalytics] Date range:', {
        start: dateRange.start.toISOString(),
        end: dateRange.end.toISOString(),
        days: Math.round((dateRange.end.getTime() - dateRange.start.getTime()) / (24 * 60 * 60 * 1000)),
      });
      
      // Try to load from Cloud Function (legacy)
      try {
        const analytics = await getFeatureAnalytics(featureId, dateRange, true);
        setSelectedFeatureAnalytics(analytics);
      } catch (err) {
        console.warn('Cloud Function analytics not available, using Firestore:', err);
      }
      
      // Load from Firestore (new direct queries)
      try {
        console.log('🔄 [loadFeatureAnalytics] Loading Firestore analytics for feature:', featureId);
        const firestoreAnalytics = await getFeatureAnalyticsSummary(featureId, dateRange);
        console.log('✅ [loadFeatureAnalytics] Analytics loaded:', {
          feature: firestoreAnalytics.feature,
          usersThisWeek: firestoreAnalytics.usersThisWeek,
          returningUsers: firestoreAnalytics.returningUsers,
          totalEvents: firestoreAnalytics.totalEvents,
        });
        setSelectedFeatureFirestoreAnalytics(firestoreAnalytics);
      } catch (err) {
        console.error('❌ [loadFeatureAnalytics] Failed to load Firestore analytics:', err);
        console.error('Error details:', {
          message: err instanceof Error ? err.message : String(err),
          stack: err instanceof Error ? err.stack : undefined,
        });
      }
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

  // Create a flat list of all feature updates with feature reference
  interface FeatureUpdate {
    id: string;
    update: string;
    feature: TechnologyFeature;
    updateIndex: number;
  }

  const allFeatureUpdates: FeatureUpdate[] = platformFeatures
    .filter(f => f.recentUpdates && f.recentUpdates.length > 0)
    .flatMap(feature => 
      feature.recentUpdates!.map((update, idx) => ({
        id: `${feature.id}-update-${idx}`,
        update,
        feature,
        updateIndex: idx
      }))
    )
    .sort((a, b) => {
      // Sort by feature lastUpdated date (most recent first)
      const dateA = a.feature.lastUpdated?.getTime() || 0;
      const dateB = b.feature.lastUpdated?.getTime() || 0;
      return dateB - dateA;
    })
    .slice(0, 10); // Show latest 10 updates

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
      {/* Current Release Section */}
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
          className="p-8 rounded-2xl border mb-8 cursor-pointer transition-all"
          style={{
            backgroundColor: 'white',
            borderColor: '#e0e0e0',
          }}
          onClick={(e) => {
            // Only trigger if clicking on the card itself, not on buttons/links inside
            const target = e.target as HTMLElement;
            if (target.closest('button') || target.closest('a')) {
              return;
            }
            console.log('[TechnologyOverview] Card clicked, opening release:', currentRelease);
            setSelectedRelease(currentRelease);
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.borderColor = '#9575cd';
            e.currentTarget.style.boxShadow = '0 4px 6px rgba(149, 117, 205, 0.1)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.borderColor = '#e0e0e0';
            e.currentTarget.style.boxShadow = 'none';
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
                  onClick={(e) => {
                    e.stopPropagation();
                    copyToClipboard(`${currentRelease.versionName}+${currentRelease.buildNumber}`);
                  }}
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

          <div className="flex gap-3 no-click-through">
            <button
              onClick={async (e) => {
                e.stopPropagation();
                if (currentRelease.git?.commitSha) {
                  console.log('[TechnologyOverview] Opening commit detail for:', currentRelease.git.commitSha);
                  const commit = await getCommitBySha(currentRelease.git.commitSha);
                  if (commit) {
                    setSelectedCommit(commit);
                  } else {
                    // If commit not found, try to find it in commits list
                    const commitsList = await getLatestCommits(50);
                    const foundCommit = commitsList.find(c => c.commitSha === currentRelease.git.commitSha);
                    if (foundCommit) {
                      setSelectedCommit(foundCommit);
                    } else {
                      console.error('[TechnologyOverview] Commit not found:', currentRelease.git.commitSha);
                    }
                  }
                }
              }}
              className="px-6 py-2 rounded-xl transition-all no-click-through"
              style={{
                backgroundColor: '#9575cd',
                color: 'white',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#7e57c2')}
              onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#9575cd')}
            >
              View Commit Details
            </button>
            {currentRelease.git?.commitSha && (
              <a
                href={getGitHubCommitUrl(currentRelease.git.commitSha, currentRelease.git.repoUrl)}
                target="_blank"
                rel="noopener noreferrer"
                className="px-6 py-2 rounded-xl transition-all flex items-center gap-2 no-click-through"
                style={{
                  backgroundColor: '#f5f5f5',
                  color: '#616161',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
                onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                onClick={(e) => e.stopPropagation()}
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
            {allFeatureUpdates.length > 0 && (
              <div
                className="px-4 py-2 rounded-full text-sm"
                style={{
                  backgroundColor: '#f3e5f5',
                  color: '#7e57c2',
                }}
              >
                {allFeatureUpdates.length} updates
              </div>
            )}
          </div>

          {/* Feed-style updates - Scrollable with 3 visible */}
          {allFeatureUpdates.length === 0 ? (
            <div className="text-center py-8" style={{ color: '#757575' }}>
              No feature updates available.
            </div>
          ) : (
            <div 
              className="overflow-y-auto"
              style={{
                maxHeight: '540px', // Height for ~3 items (each ~180px)
                scrollbarWidth: 'thin',
                scrollbarColor: '#9575cd #f5f5f5',
              }}
            >
              <style>{`
                div::-webkit-scrollbar {
                  width: 8px;
                }
                div::-webkit-scrollbar-track {
                  background: #f5f5f5;
                  border-radius: 4px;
                }
                div::-webkit-scrollbar-thumb {
                  background: #9575cd;
                  border-radius: 4px;
                }
                div::-webkit-scrollbar-thumb:hover {
                  background: #7e57c2;
                }
              `}</style>
              <div className="space-y-4 pr-2">
                {allFeatureUpdates.map((featureUpdate) => (
                <div
                  key={featureUpdate.id}
                  onClick={() => setSelectedFeature(featureUpdate.feature)}
                  className="p-6 rounded-xl border transition-all cursor-pointer"
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
                          <span className="text-sm font-semibold" style={{ color: '#424242' }}>
                            {featureUpdate.feature.name}
                          </span>
                          <span className="text-xs" style={{ color: '#9e9e9e' }}>•</span>
                          <span className="text-xs" style={{ color: '#9e9e9e' }}>
                            {featureUpdate.feature.lastUpdated ? formatDate(featureUpdate.feature.lastUpdated) : 'Unknown'}
                          </span>
                        </div>
                        <div className="text-xs" style={{ color: '#757575' }}>
                          Feature Update · {featureUpdate.feature.domain}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Update Content */}
                  <div className="mb-4">
                    <div className="flex items-center gap-2 mb-2">
                      {featureUpdate.update.includes('[production]') && (
                        <span
                          className="px-2 py-0.5 rounded text-xs font-semibold"
                          style={{
                            backgroundColor: '#e8f5e9',
                            color: '#2e7d32',
                          }}
                        >
                          Production
                        </span>
                      )}
                      {featureUpdate.update.includes('[pilot]') && !featureUpdate.update.includes('[production]') && (
                        <span
                          className="px-2 py-0.5 rounded text-xs font-semibold"
                          style={{
                            backgroundColor: '#fff3e0',
                            color: '#e65100',
                          }}
                        >
                          Pilot
                        </span>
                      )}
                    </div>
                    <p className="text-sm leading-relaxed mb-3" style={{ color: '#616161' }}>
                      {featureUpdate.update.replace(/^\[(production|pilot)\]\s*/, '')}
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
                        #{featureUpdate.feature.name.toLowerCase().replace(/\s+/g, '-')}
                      </div>
                      <div
                        className="px-3 py-1 rounded-full text-xs"
                        style={{
                          backgroundColor: '#f3e5f5',
                          color: '#7e57c2',
                        }}
                      >
                        #{featureUpdate.feature.domain.toLowerCase().replace(/\s+/g, '-')}
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
                    <div className="px-4 py-2 rounded-lg text-sm flex items-center gap-2"
                      style={{
                        backgroundColor: 'transparent',
                        color: '#9575cd',
                        border: '1px solid #9575cd',
                      }}
                    >
                      View Feature Details
                      <ArrowUpRight className="w-4 h-4" />
                    </div>
                  </div>
                </div>
                ))}
              </div>
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
                    {feature.recentUpdates.slice(0, 2).map((update: string, idx: number) => {
                      const isProduction = update.includes('[production]');
                      const isPilot = update.includes('[pilot]');
                      const updateText = update.replace(/^\[(production|pilot)\]\s*/, '');
                      const updateKey = `${feature.id || 'feature'}-update-${idx}`;
                      
                      return (
                        <li key={updateKey} className="flex items-start gap-1">
                          <span 
                            className="mt-0.5" 
                            style={{ 
                              color: isProduction ? '#4caf50' : isPilot ? '#ff9800' : '#9575cd' 
                            }}
                          >
                            •
                          </span>
                          <span className="flex items-center gap-1">
                            {isProduction && (
                              <span
                                className="px-1 py-0.5 rounded text-[10px] font-semibold"
                                style={{
                                  backgroundColor: '#e8f5e9',
                                  color: '#2e7d32',
                                }}
                              >
                                PROD
                              </span>
                            )}
                            <span>{updateText.slice(0, 50)}...</span>
                          </span>
                        </li>
                      );
                    })}
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
                    className={`transition-colors cursor-pointer ${
                      index !== commits.length - 1 ? "border-b" : ""
                    }`}
                    style={{
                      borderColor: '#f5f5f5',
                      backgroundColor: 'transparent',
                    }}
                    onClick={() => setSelectedCommit(commit)}
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
                      onClick={() => setEditingKPI(selectedFeature)}
                      className="px-4 py-2 rounded-lg text-sm transition-all"
                      style={{
                        backgroundColor: '#9575cd',
                        color: 'white',
                      }}
                      onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#7e57c2')}
                      onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#9575cd')}
                    >
                      Edit KPI
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
                      <div className="text-xs mb-2" style={{ color: '#9e9e9e' }}>Users This Week</div>
                      <div className="text-2xl mb-1" style={{ color: '#424242' }}>
                        {selectedFeatureFirestoreAnalytics?.usersThisWeek || 0}
                      </div>
                      <div className="text-xs" style={{ color: '#2e7d32' }}>
                        <TrendingUp className="w-3 h-3 inline mr-1" />
                        {selectedFeatureFirestoreAnalytics && selectedFeatureFirestoreAnalytics.usersThisWeek > 0 
                          ? 'Active' 
                          : 'No activity'}
                      </div>
                    </div>
                    <div
                      className="p-4 rounded-xl"
                      style={{ backgroundColor: '#fafafa' }}
                    >
                      <div className="text-xs mb-2" style={{ color: '#9e9e9e' }}>Returning Users</div>
                      <div className="text-2xl mb-1" style={{ color: '#424242' }}>
                        {selectedFeatureFirestoreAnalytics?.returningUsers || 0}
                      </div>
                      <div className="text-xs" style={{ color: '#757575' }}>
                        {selectedFeatureFirestoreAnalytics && selectedFeatureFirestoreAnalytics.usersThisWeek > 0
                          ? `${Math.round((selectedFeatureFirestoreAnalytics.returningUsers / selectedFeatureFirestoreAnalytics.usersThisWeek) * 100)}% of this week's users`
                          : 'From previous use'}
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
              {selectedFeatureFirestoreAnalytics && (
                <div className="grid gap-6 md:grid-cols-2 mb-8">
                  {/* Events by Type Chart */}
                  <div
                    className="p-6 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                    }}
                  >
                    <h3 className="text-sm mb-4" style={{ color: '#424242' }}>
                      Events by Type
                    </h3>
                    {Object.keys(selectedFeatureFirestoreAnalytics.eventsByType).length > 0 ? (
                      <ResponsiveContainer width="100%" height={200}>
                        <BarChart
                          data={Object.entries(selectedFeatureFirestoreAnalytics.eventsByType)
                            .map(([name, count]) => ({
                              name: name.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
                              count: count as number,
                            }))
                            .sort((a, b) => b.count - a.count)
                            .slice(0, 8)} // Top 8 events
                        >
                          <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                          <XAxis
                            dataKey="name"
                            stroke="#9e9e9e"
                            tick={{ fontSize: 10 }}
                            angle={-45}
                            textAnchor="end"
                            height={60}
                          />
                          <YAxis stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                          <Tooltip
                            contentStyle={{
                              backgroundColor: 'white',
                              border: '1px solid #e0e0e0',
                              borderRadius: '8px',
                              fontSize: '12px',
                            }}
                          />
                          <Bar dataKey="count" fill="#9575cd" radius={[4, 4, 0, 0]} />
                        </BarChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="flex items-center justify-center h-[200px] text-sm" style={{ color: '#9e9e9e' }}>
                        No event data available
                      </div>
                    )}
                  </div>

                  {/* Daily Activity Chart */}
                  <div
                    className="p-6 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                    }}
                  >
                    <h3 className="text-sm mb-4" style={{ color: '#424242' }}>
                      Daily Activity (Last 7 Days)
                    </h3>
                    {selectedFeatureFirestoreAnalytics.recentEvents.length > 0 ? (
                      <ResponsiveContainer width="100%" height={200}>
                        <LineChart
                          data={(() => {
                            // Group events by day for the last 7 days
                            const days: Record<string, number> = {};
                            const now = new Date();
                            for (let i = 6; i >= 0; i--) {
                              const date = new Date(now);
                              date.setDate(date.getDate() - i);
                              const dayKey = format(date, 'MMM d');
                              days[dayKey] = 0;
                            }
                            
                            selectedFeatureFirestoreAnalytics.recentEvents.forEach(event => {
                              const eventDate = new Date(event.timestamp);
                              const dayKey = format(eventDate, 'MMM d');
                              if (days.hasOwnProperty(dayKey)) {
                                days[dayKey]++;
                              }
                            });
                            
                            return Object.entries(days).map(([date, count]) => ({
                              date,
                              events: count,
                            }));
                          })()}
                        >
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
                            dataKey="events"
                            stroke="#9575cd"
                            strokeWidth={2}
                            dot={{ fill: '#9575cd', r: 3 }}
                          />
                        </LineChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="flex items-center justify-center h-[200px] text-sm" style={{ color: '#9e9e9e' }}>
                        No recent activity
                      </div>
                    )}
                  </div>

                  {/* Cohort Breakdown Chart */}
                  <div
                    className="p-6 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                    }}
                  >
                    <h3 className="text-sm mb-4" style={{ color: '#424242' }}>
                      Users by Cohort
                    </h3>
                    {selectedFeatureFirestoreAnalytics.cohortBreakdown.navigator > 0 ||
                    selectedFeatureFirestoreAnalytics.cohortBreakdown.self_directed > 0 ? (
                      <ResponsiveContainer width="100%" height={200}>
                        <BarChart
                          data={[
                            {
                              name: 'Navigator',
                              users: selectedFeatureFirestoreAnalytics.cohortBreakdown.navigator,
                            },
                            {
                              name: 'Self-Directed',
                              users: selectedFeatureFirestoreAnalytics.cohortBreakdown.self_directed,
                            },
                          ]}
                        >
                          <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                          <XAxis dataKey="name" stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                          <YAxis stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                          <Tooltip
                            contentStyle={{
                              backgroundColor: 'white',
                              border: '1px solid #e0e0e0',
                              borderRadius: '8px',
                              fontSize: '12px',
                            }}
                          />
                          <Bar dataKey="users" fill="#9575cd" radius={[4, 4, 0, 0]} />
                        </BarChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="flex items-center justify-center h-[200px] text-sm" style={{ color: '#9e9e9e' }}>
                        No cohort data available
                      </div>
                    )}
                  </div>

                  {/* Trimester Breakdown Chart */}
                  <div
                    className="p-6 rounded-xl border"
                    style={{
                      backgroundColor: 'white',
                      borderColor: '#e0e0e0',
                    }}
                  >
                    <h3 className="text-sm mb-4" style={{ color: '#424242' }}>
                      Usage by Trimester
                    </h3>
                    {selectedFeatureFirestoreAnalytics.trimesterBreakdown.first > 0 ||
                    selectedFeatureFirestoreAnalytics.trimesterBreakdown.second > 0 ||
                    selectedFeatureFirestoreAnalytics.trimesterBreakdown.third > 0 ||
                    selectedFeatureFirestoreAnalytics.trimesterBreakdown.postpartum > 0 ? (
                      <ResponsiveContainer width="100%" height={200}>
                        <BarChart
                          data={[
                            { name: '1st', events: selectedFeatureFirestoreAnalytics.trimesterBreakdown.first },
                            { name: '2nd', events: selectedFeatureFirestoreAnalytics.trimesterBreakdown.second },
                            { name: '3rd', events: selectedFeatureFirestoreAnalytics.trimesterBreakdown.third },
                            { name: 'Postpartum', events: selectedFeatureFirestoreAnalytics.trimesterBreakdown.postpartum },
                          ]}
                        >
                          <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                          <XAxis dataKey="name" stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                          <YAxis stroke="#9e9e9e" tick={{ fontSize: 11 }} />
                          <Tooltip
                            contentStyle={{
                              backgroundColor: 'white',
                              border: '1px solid #e0e0e0',
                              borderRadius: '8px',
                              fontSize: '12px',
                            }}
                          />
                          <Bar dataKey="events" fill="#9575cd" radius={[4, 4, 0, 0]} />
                        </BarChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="flex items-center justify-center h-[200px] text-sm" style={{ color: '#9e9e9e' }}>
                        No trimester data available
                      </div>
                    )}
                  </div>
                </div>
              )}

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
                    {selectedFeature.recentUpdates.map((update, idx) => {
                      // Create a unique key - use feature id if available, otherwise use index with update content hash
                      const featureId = selectedFeature?.id || selectedFeature?.name?.toLowerCase().replace(/\s+/g, '-') || 'unknown';
                      const updateHash = update.substring(0, 20).replace(/\s/g, '-').replace(/[^a-z0-9-]/gi, '');
                      const updateKey = `${featureId}-update-${idx}-${updateHash}`;
                      // Check if update is tagged with [production] or [pilot]
                      const isProduction = update.includes('[production]');
                      const isPilot = update.includes('[pilot]');
                      const updateText = update.replace(/^\[(production|pilot)\]\s*/, '');
                      
                      return (
                        <div
                          key={updateKey}
                          className="p-4 rounded-lg"
                          style={{
                            backgroundColor: 'white',
                            border: '1px solid #e0e0e0',
                          }}
                        >
                          <div className="flex items-start gap-3">
                            <div
                              className="w-2 h-2 rounded-full mt-2 flex-shrink-0"
                              style={{ 
                                backgroundColor: isProduction ? '#4caf50' : isPilot ? '#ff9800' : '#9575cd' 
                              }}
                            />
                            <div className="flex-1">
                              <div className="flex items-center gap-2 mb-1">
                                {isProduction && (
                                  <span
                                    className="px-2 py-0.5 rounded text-xs font-semibold"
                                    style={{
                                      backgroundColor: '#e8f5e9',
                                      color: '#2e7d32',
                                    }}
                                  >
                                    Production
                                  </span>
                                )}
                                {isPilot && !isProduction && (
                                  <span
                                    className="px-2 py-0.5 rounded text-xs font-semibold"
                                    style={{
                                      backgroundColor: '#fff3e0',
                                      color: '#e65100',
                                    }}
                                  >
                                    Pilot
                                  </span>
                                )}
                              </div>
                              <p className="text-sm leading-relaxed" style={{ color: '#616161' }}>
                                {updateText}
                              </p>
                            </div>
                          </div>
                        </div>
                      );
                    })}
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
                    selectedFeatureChangeHistory.map((change, idx) => {
                      // Create a unique key with multiple fallbacks
                      const changeKey = change.version 
                        ? `${change.version}-${idx}`
                        : change.commitSha 
                        ? `${change.commitSha}-${idx}`
                        : change.date 
                        ? `change-${change.date.getTime?.() || change.date}-${idx}`
                        : `change-${idx}-${Date.now()}`;
                      return (
                      <div
                        key={changeKey}
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
                      );
                    })
                  )}
                </div>
              </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Commit Detail Drawer */}
      {selectedCommit && (
        <div className="fixed inset-0 z-50 flex items-start justify-end">
          {/* Backdrop */}
          <div
            className="absolute inset-0"
            style={{ backgroundColor: 'rgba(0, 0, 0, 0.4)' }}
            onClick={() => setSelectedCommit(null)}
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
                    <GitCommit className="w-6 h-6" style={{ color: '#9575cd' }} />
                    <h2 className="text-xl font-mono" style={{ color: '#424242' }}>
                      {selectedCommit.commitSha.substring(0, 7)}
                    </h2>
                    {selectedCommit.channel && (
                      <div
                        className="px-3 py-1 rounded-md text-sm"
                        style={{
                          backgroundColor: selectedCommit.channel === 'production' ? '#e8f5e9' : '#fff3e0',
                          color: selectedCommit.channel === 'production' ? '#2e7d32' : '#e65100',
                        }}
                      >
                        {selectedCommit.channel === 'production' ? 'Production' : 'Pilot'}
                      </div>
                    )}
                    {selectedCommit.fullVersion && (
                      <div
                        className="px-3 py-1 rounded-md text-sm"
                        style={{
                          backgroundColor: '#f5f5f5',
                          color: '#616161',
                        }}
                      >
                        v{selectedCommit.fullVersion}
                      </div>
                    )}
                  </div>
                  <p className="text-sm mb-2" style={{ color: '#757575' }}>
                    {selectedCommit.commitMessage || 'No commit message'}
                  </p>
                  <div className="flex items-center gap-4 text-xs" style={{ color: '#9e9e9e' }}>
                    <span>Author: {selectedCommit.commitAuthor || 'Unknown'}</span>
                    <span>•</span>
                    <span>Branch: {selectedCommit.branch || 'main'}</span>
                    <span>•</span>
                    <span>Date: {formatDate(selectedCommit.commitDate)}</span>
                  </div>
                  {selectedCommit.gitTag && (
                    <div className="mt-2 text-xs" style={{ color: '#757575' }}>
                      Tag: {selectedCommit.gitTag}
                    </div>
                  )}
                </div>
                <button
                  onClick={() => setSelectedCommit(null)}
                  className="p-2 rounded-lg transition-colors"
                  style={{ color: '#757575' }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="flex gap-2">
                <a
                  href={getCommitUrl(selectedCommit.commitSha)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-4 py-2 rounded-xl text-sm transition-all flex items-center gap-2"
                  style={{
                    backgroundColor: '#9575cd',
                    color: 'white',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#7e57c2')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#9575cd')}
                >
                  <ExternalLink className="w-4 h-4" />
                  View on GitHub
                </a>
                <button
                  onClick={() => copyToClipboard(selectedCommit.commitSha)}
                  className="px-4 py-2 rounded-xl text-sm transition-all flex items-center gap-2"
                  style={{
                    backgroundColor: '#f5f5f5',
                    color: '#616161',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
                >
                  <Copy className="w-4 h-4" />
                  Copy SHA
                </button>
              </div>
            </div>

            {/* Commit Details Content */}
            <div className="p-6">
              {/* Commit Information */}
              <div
                className="p-6 rounded-xl border mb-6"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                }}
              >
                <div className="flex items-center gap-2 mb-4">
                  <Clock className="w-5 h-5" style={{ color: '#9575cd' }} />
                  <h3 className="text-lg" style={{ color: '#424242' }}>
                    Commit Information
                  </h3>
                </div>
                <div className="space-y-3">
                  <div>
                    <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Full Commit SHA</div>
                    <div className="font-mono text-sm" style={{ color: '#424242' }}>
                      {selectedCommit.commitSha}
                    </div>
                  </div>
                  <div>
                    <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Commit Message</div>
                    <div className="text-sm leading-relaxed" style={{ color: '#616161' }}>
                      {selectedCommit.commitMessage || 'No commit message available'}
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Author</div>
                      <div className="text-sm" style={{ color: '#616161' }}>
                        {selectedCommit.commitAuthor || 'Unknown'}
                      </div>
                    </div>
                    <div>
                      <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Branch</div>
                      <div className="text-sm" style={{ color: '#616161' }}>
                        {selectedCommit.branch || 'main'}
                      </div>
                    </div>
                    <div>
                      <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Commit Date</div>
                      <div className="text-sm" style={{ color: '#616161' }}>
                        {formatDate(selectedCommit.commitDate)}
                      </div>
                    </div>
                    <div>
                      <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Recorded At</div>
                      <div className="text-sm" style={{ color: '#616161' }}>
                        {formatDate(selectedCommit.createdAt)}
                      </div>
                    </div>
                  </div>
                  {selectedCommit.buildNumber && (
                    <div>
                      <div className="text-xs mb-1" style={{ color: '#9e9e9e' }}>Build Number</div>
                      <div className="text-sm" style={{ color: '#616161' }}>
                        {selectedCommit.buildNumber}
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Associated Release */}
              {selectedCommit.fullVersion && (
                <div
                  className="p-6 rounded-xl border mb-6"
                  style={{
                    backgroundColor: 'white',
                    borderColor: '#e0e0e0',
                  }}
                >
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-2">
                      <FileText className="w-5 h-5" style={{ color: '#9575cd' }} />
                      <h3 className="text-lg" style={{ color: '#424242' }}>
                        Associated Release
                      </h3>
                    </div>
                    <button
                      onClick={() => {
                        const release = releaseHistory.find(r => r.buildNumber === selectedCommit.buildNumber);
                        if (release) {
                          setSelectedRelease(release);
                          setSelectedCommit(null);
                        }
                      }}
                      className="px-4 py-2 rounded-lg text-sm transition-all"
                      style={{
                        backgroundColor: '#9575cd',
                        color: 'white',
                      }}
                      onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#7e57c2')}
                      onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#9575cd')}
                    >
                      View Release Notes
                    </button>
                  </div>
                  <div className="text-sm" style={{ color: '#616161' }}>
                    Version {selectedCommit.fullVersion} ({selectedCommit.channel || 'pilot'})
                  </div>
                </div>
              )}

              {/* Feature Changes */}
              <div
                className="p-6 rounded-xl border"
                style={{
                  backgroundColor: 'white',
                  borderColor: '#e0e0e0',
                }}
              >
                <div className="flex items-center gap-2 mb-4">
                  <Sparkles className="w-5 h-5" style={{ color: '#9575cd' }} />
                  <h3 className="text-lg" style={{ color: '#424242' }}>
                    Feature Changes
                  </h3>
                </div>
                {commitFeatureChanges.length === 0 ? (
                  <div className="text-sm" style={{ color: '#757575' }}>
                    No feature changes associated with this commit.
                  </div>
                ) : (
                  <div className="space-y-4">
                    {commitFeatureChanges.map((item, idx) => (
                      <div
                        key={idx}
                        className="p-4 rounded-lg border"
                        style={{
                          backgroundColor: '#fafafa',
                          borderColor: '#e0e0e0',
                        }}
                      >
                        <div className="flex items-center justify-between mb-3">
                          <h4 className="text-base font-semibold" style={{ color: '#424242' }}>
                            {item.feature.name}
                          </h4>
                          <button
                            onClick={() => {
                              setSelectedFeature(item.feature);
                              setSelectedCommit(null);
                            }}
                            className="px-3 py-1 rounded-lg text-xs transition-all"
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
                            View Feature
                          </button>
                        </div>
                        <div className="space-y-2">
                          {item.changes.map((change: any, changeIdx: number) => (
                            <div
                              key={changeIdx}
                              className="flex gap-3 pb-2 border-b last:border-b-0"
                              style={{ borderColor: '#f0f0f0' }}
                            >
                              <div
                                className="w-2 h-2 rounded-full mt-2 flex-shrink-0"
                                style={{ backgroundColor: '#9575cd' }}
                              />
                              <div className="flex-1">
                                <div className="flex items-center gap-2 mb-1">
                                  <span className="text-xs font-semibold" style={{ color: '#616161' }}>
                                    {change.title || 'Update'}
                                  </span>
                                  {change.date && (
                                    <span className="text-xs" style={{ color: '#9e9e9e' }}>
                                      • {formatDate(change.date)}
                                    </span>
                                  )}
                                </div>
                                <p className="text-sm leading-relaxed" style={{ color: '#757575' }}>
                                  {change.description || change.change || 'No description'}
                                </p>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* KPI Goals Edit Modal */}
      {editingKPI && (
        <KPIGoalsModal
          feature={editingKPI}
          analytics={selectedFeatureFirestoreAnalytics}
          onClose={() => setEditingKPI(null)}
          onSave={() => {
            loadPlatformFeatures();
            if (selectedFeature?.id === editingKPI.id) {
              // Reload selected feature if KPIs were updated
              getFeatureById(editingKPI.id).then(feature => {
                if (feature) {
                  setSelectedFeature(feature);
                  // Reload analytics to show updated goals
                  if (feature.id) {
                    loadFeatureAnalytics(feature.id);
                  }
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
