import { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { TechnologyFeature, updateFeature } from '../../lib/features';
import { FeatureAnalyticsSummary, FeatureKPIGoals } from '../../lib/firestoreAnalytics';
import { useAuth } from '../../contexts/AuthContext';

interface KPIGoalsModalProps {
  feature: TechnologyFeature;
  analytics: FeatureAnalyticsSummary | null;
  onClose: () => void;
  onSave: () => void;
}

export function KPIGoalsModal({ feature, analytics, onClose, onSave }: KPIGoalsModalProps) {
  const { user, userProfile, loading: authLoading } = useAuth();
  const [kpiGoals, setKpiGoals] = useState<FeatureKPIGoals>(feature.kpiGoals || {});
  const [saving, setSaving] = useState(false);

  // Initialize event goals from current analytics
  useEffect(() => {
    if (analytics && analytics.eventsByType && !kpiGoals.eventGoals) {
      const eventGoals: Record<string, number> = {};
      Object.keys(analytics.eventsByType).forEach(eventName => {
        eventGoals[eventName] = 0; // Initialize to 0, user can set goals
      });
      setKpiGoals(prev => ({ ...prev, eventGoals }));
    }
  }, [analytics]);

  const handleSave = async () => {
    // Check authentication
    if (!user || !userProfile) {
      alert('You must be logged in to save KPI goals. Please refresh the page and try again.');
      return;
    }

    // Check if user is admin
    if (userProfile.role !== 'admin') {
      alert('Only administrators can save KPI goals.');
      return;
    }

    setSaving(true);
    try {
      // Refresh auth token before calling the function
      const token = await user.getIdToken(true);
      console.log('🔐 [KPIGoalsModal] User authenticated, token refreshed. UID:', user.uid);
      
      await updateFeature(feature.id, {
        kpiGoals: kpiGoals,
      });
      
      console.log('✅ [KPIGoalsModal] KPI goals saved successfully');
      onSave();
      onClose();
    } catch (error: any) {
      console.error('❌ [KPIGoalsModal] Error saving KPI goals:', error);
      
      // Provide more helpful error messages
      if (error?.code === 'unauthenticated' || error?.message?.includes('authenticated')) {
        alert('Authentication error: Please refresh the page and log in again, then try saving.');
      } else if (error?.code === 'permission-denied') {
        alert('Permission denied: Only administrators can save KPI goals.');
      } else {
        alert(`Failed to save KPI goals: ${error?.message || 'Unknown error'}. Please try again.`);
      }
    } finally {
      setSaving(false);
    }
  };

  const updateEventGoal = (eventName: string, value: number) => {
    setKpiGoals(prev => ({
      ...prev,
      eventGoals: {
        ...prev.eventGoals,
        [eventName]: value,
      },
    }));
  };

  const updateCohortGoal = (cohort: 'navigator' | 'self_directed', value: number) => {
    setKpiGoals(prev => ({
      ...prev,
      cohortGoals: {
        ...prev.cohortGoals,
        [cohort]: value,
      },
    }));
  };

  const updateUsageGoal = (type: 'dailyEvents' | 'weeklyUsers' | 'monthlyUsers', value: number) => {
    setKpiGoals(prev => ({
      ...prev,
      usageGoals: {
        ...prev.usageGoals,
        [type]: value,
      },
    }));
  };

  const updateTrimesterGoal = (trimester: 'first' | 'second' | 'third' | 'postpartum', value: number) => {
    setKpiGoals(prev => ({
      ...prev,
      trimesterGoals: {
        ...prev.trimesterGoals,
        [trimester]: value,
      },
    }));
  };

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
        style={{ borderColor: '#e0e0e0' }}
      >
        {/* Header */}
        <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between z-10" style={{ borderColor: '#e0e0e0' }}>
          <h2 className="text-xl font-semibold" style={{ color: '#424242' }}>
            Edit KPI Goals: {feature.name}
          </h2>
          <button
            onClick={onClose}
            className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
            style={{ color: '#757575' }}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Auth Status Warning */}
          {authLoading ? (
            <div className="p-3 rounded-lg bg-yellow-50 border border-yellow-200">
              <p className="text-sm text-yellow-800">Checking authentication...</p>
            </div>
          ) : (!user || !userProfile) ? (
            <div className="p-3 rounded-lg bg-red-50 border border-red-200">
              <p className="text-sm text-red-800">You must be logged in to save KPI goals.</p>
            </div>
          ) : userProfile.role !== 'admin' ? (
            <div className="p-3 rounded-lg bg-red-50 border border-red-200">
              <p className="text-sm text-red-800">Only administrators can save KPI goals.</p>
            </div>
          ) : null}
          
          {/* Event Goals */}
          {analytics && Object.keys(analytics.eventsByType).length > 0 && (
            <div>
              <h3 className="text-sm font-semibold mb-3" style={{ color: '#424242' }}>
                Event Goals
              </h3>
              <div className="space-y-2">
                {Object.entries(analytics.eventsByType).map(([eventName, currentCount]) => (
                  <div key={eventName} className="flex items-center justify-between p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                    <div className="flex-1">
                      <div className="text-sm font-medium" style={{ color: '#424242' }}>
                        {eventName.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </div>
                      <div className="text-xs" style={{ color: '#757575' }}>
                        Current: {currentCount as number}
                      </div>
                    </div>
                    <input
                      type="number"
                      min="0"
                      value={kpiGoals.eventGoals?.[eventName] || 0}
                      onChange={(e) => updateEventGoal(eventName, parseInt(e.target.value) || 0)}
                      className="w-24 px-3 py-1 rounded-lg border text-sm"
                      style={{ borderColor: '#e0e0e0' }}
                      placeholder="Goal"
                    />
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Cohort Goals */}
          <div>
            <h3 className="text-sm font-semibold mb-3" style={{ color: '#424242' }}>
              Cohort Usage Goals
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                <div className="text-sm font-medium mb-1" style={{ color: '#424242' }}>
                  Navigator
                </div>
                <div className="text-xs mb-2" style={{ color: '#757575' }}>
                  Current: {analytics?.cohortBreakdown.navigator || 0}
                </div>
                <input
                  type="number"
                  min="0"
                  value={kpiGoals.cohortGoals?.navigator || 0}
                  onChange={(e) => updateCohortGoal('navigator', parseInt(e.target.value) || 0)}
                  className="w-full px-3 py-1 rounded-lg border text-sm"
                  style={{ borderColor: '#e0e0e0' }}
                  placeholder="Goal"
                />
              </div>
              <div className="p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                <div className="text-sm font-medium mb-1" style={{ color: '#424242' }}>
                  Self-Directed
                </div>
                <div className="text-xs mb-2" style={{ color: '#757575' }}>
                  Current: {analytics?.cohortBreakdown.self_directed || 0}
                </div>
                <input
                  type="number"
                  min="0"
                  value={kpiGoals.cohortGoals?.self_directed || 0}
                  onChange={(e) => updateCohortGoal('self_directed', parseInt(e.target.value) || 0)}
                  className="w-full px-3 py-1 rounded-lg border text-sm"
                  style={{ borderColor: '#e0e0e0' }}
                  placeholder="Goal"
                />
              </div>
            </div>
          </div>

          {/* Usage Goals */}
          <div>
            <h3 className="text-sm font-semibold mb-3" style={{ color: '#424242' }}>
              General Usage Goals
            </h3>
            <div className="grid grid-cols-3 gap-4">
              <div className="p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                <div className="text-sm font-medium mb-1" style={{ color: '#424242' }}>
                  Daily Events
                </div>
                <input
                  type="number"
                  min="0"
                  value={kpiGoals.usageGoals?.dailyEvents || 0}
                  onChange={(e) => updateUsageGoal('dailyEvents', parseInt(e.target.value) || 0)}
                  className="w-full px-3 py-1 rounded-lg border text-sm"
                  style={{ borderColor: '#e0e0e0' }}
                  placeholder="Goal"
                />
              </div>
              <div className="p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                <div className="text-sm font-medium mb-1" style={{ color: '#424242' }}>
                  Weekly Users
                </div>
                <div className="text-xs mb-2" style={{ color: '#757575' }}>
                  Current: {analytics?.usersThisWeek || 0}
                </div>
                <input
                  type="number"
                  min="0"
                  value={kpiGoals.usageGoals?.weeklyUsers || 0}
                  onChange={(e) => updateUsageGoal('weeklyUsers', parseInt(e.target.value) || 0)}
                  className="w-full px-3 py-1 rounded-lg border text-sm"
                  style={{ borderColor: '#e0e0e0' }}
                  placeholder="Goal"
                />
              </div>
              <div className="p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                <div className="text-sm font-medium mb-1" style={{ color: '#424242' }}>
                  Monthly Users
                </div>
                <input
                  type="number"
                  min="0"
                  value={kpiGoals.usageGoals?.monthlyUsers || 0}
                  onChange={(e) => updateUsageGoal('monthlyUsers', parseInt(e.target.value) || 0)}
                  className="w-full px-3 py-1 rounded-lg border text-sm"
                  style={{ borderColor: '#e0e0e0' }}
                  placeholder="Goal"
                />
              </div>
            </div>
          </div>

          {/* Trimester Goals */}
          <div>
            <h3 className="text-sm font-semibold mb-3" style={{ color: '#424242' }}>
              Trimester Usage Goals
            </h3>
            <div className="grid grid-cols-4 gap-4">
              {(['first', 'second', 'third', 'postpartum'] as const).map((trimester) => (
                <div key={trimester} className="p-3 rounded-lg" style={{ backgroundColor: '#fafafa' }}>
                  <div className="text-sm font-medium mb-1" style={{ color: '#424242' }}>
                    {trimester === 'first' ? '1st' : trimester === 'second' ? '2nd' : trimester === 'third' ? '3rd' : 'Postpartum'}
                  </div>
                  <div className="text-xs mb-2" style={{ color: '#757575' }}>
                    Current: {analytics?.trimesterBreakdown[trimester] || 0}
                  </div>
                  <input
                    type="number"
                    min="0"
                    value={kpiGoals.trimesterGoals?.[trimester] || 0}
                    onChange={(e) => updateTrimesterGoal(trimester, parseInt(e.target.value) || 0)}
                    className="w-full px-3 py-1 rounded-lg border text-sm"
                    style={{ borderColor: '#e0e0e0' }}
                    placeholder="Goal"
                  />
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="sticky bottom-0 bg-white border-t px-6 py-4 flex items-center justify-end gap-3" style={{ borderColor: '#e0e0e0' }}>
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-lg text-sm transition-all"
            style={{
              backgroundColor: '#f5f5f5',
              color: '#616161',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#eeeeee')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#f5f5f5')}
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="px-4 py-2 rounded-lg text-sm transition-all text-white"
            style={{
              backgroundColor: saving ? '#b0b0b0' : '#9575cd',
            }}
            onMouseEnter={(e) => {
              if (!saving) {
                e.currentTarget.style.backgroundColor = '#7e57c2';
              }
            }}
            onMouseLeave={(e) => {
              if (!saving) {
                e.currentTarget.style.backgroundColor = '#9575cd';
              }
            }}
          >
            {saving ? 'Saving...' : 'Save Goals'}
          </button>
        </div>
      </div>
    </div>
  );
}
