/**
 * Firestore Analytics
 * Direct Firestore queries for analytics data
 */

import { collection, query, where, getDocs, Timestamp, orderBy, limit, startAt, endAt } from 'firebase/firestore';
import { firestore } from '../firebase/firebase';

/**
 * Map technology feature IDs to analytics feature names
 * This maps the feature IDs from technology_features collection to the feature names used in analytics_events
 */
function mapFeatureIdToAnalyticsFeature(featureId: string): string | null {
  const mapping: Record<string, string> = {
    // Map common feature IDs to analytics feature names
    'provider-search': 'provider-search',
    'authentication-onboarding': 'authentication-onboarding',
    'user-feedback': 'user-feedback',
    'appointment-summarizing': 'appointment-summarizing',
    'journal': 'journal',
    'learning-modules': 'learning-modules',
    'birth-plan-generator': 'birth-plan-generator',
    'community': 'community',
    'profile-editing': 'profile-editing',
    // Add more mappings as needed
  };
  
  // If direct mapping exists, use it
  if (mapping[featureId]) {
    return mapping[featureId];
  }
  
  // Try to find by partial match (e.g., "Provider Search" -> "provider-search")
  const normalizedId = featureId.toLowerCase().replace(/\s+/g, '-');
  if (mapping[normalizedId]) {
    return mapping[normalizedId];
  }
  
  // Return the featureId as-is (might work if they match)
  return featureId;
}

export interface AnalyticsEvent {
  id: string;
  userId: string | null;
  anonUserId: string;
  eventName: string;
  feature: string;
  timestamp: Date;
  sessionId: string;
  cohortType: string | null;
  gestationalWeek: number | null;
  trimester: string | null;
  metadata: Record<string, any>;
}

export interface FeatureKPIGoals {
  // Event goals - goals for specific event types
  eventGoals?: Record<string, number>; // eventName -> target count
  // Cohort usage goals
  cohortGoals?: {
    navigator?: number; // Target number of navigator users
    self_directed?: number; // Target number of self-directed users
  };
  // General usage goals
  usageGoals?: {
    dailyEvents?: number; // Target daily events
    weeklyUsers?: number; // Target weekly unique users
    monthlyUsers?: number; // Target monthly unique users
  };
  // Trimester usage goals
  trimesterGoals?: {
    first?: number; // Target events for 1st trimester
    second?: number; // Target events for 2nd trimester
    third?: number; // Target events for 3rd trimester
    postpartum?: number; // Target events for postpartum
  };
}

export interface FeatureAnalyticsSummary {
  feature: string;
  totalEvents: number;
  uniqueUsers: number;
  uniqueSessions: number;
  usersThisWeek: number;
  returningUsers: number;
  eventsByType: Record<string, number>;
  recentEvents: AnalyticsEvent[];
  cohortBreakdown: {
    navigator: number;
    self_directed: number;
    unknown: number;
  };
  trimesterBreakdown: {
    first: number;
    second: number;
    third: number;
    postpartum: number;
    unknown: number;
  };
}

/**
 * Get analytics events for a specific feature
 * Now queries from technology_features/{featureId}/analytics_events subcollection
 */
export async function getFeatureEvents(
  feature: string,
  dateRange: { start: Date; end: Date } = {
    start: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), // Default to 90 days to capture more history
    end: new Date()
  }
): Promise<AnalyticsEvent[]> {
  console.log('🔍 [getFeatureEvents] Starting query:', {
    feature,
    dateRangeStart: dateRange.start.toISOString(),
    dateRangeEnd: dateRange.end.toISOString(),
  });
  
  try {
    // Validate feature parameter
    if (!feature || feature.trim() === '') {
      console.warn('⚠️ [getFeatureEvents] feature parameter is empty, returning empty array');
      return [];
    }
    
    // Map feature ID to analytics feature name (for backward compatibility)
    const analyticsFeature = mapFeatureIdToAnalyticsFeature(feature);
    const featureId = analyticsFeature || feature;
    console.log('📊 [getFeatureEvents] Feature mapping:', { original: feature, mapped: analyticsFeature, using: featureId });
    
    // Try subcollection first, then fallback to legacy collection
    let events: AnalyticsEvent[] = [];
    
    // First, try querying from technology_features/{featureId}/analytics_events subcollection
    try {
      const eventsRef = collection(firestore, 'technology_features', featureId, 'analytics_events');
      console.log('📂 [getFeatureEvents] Querying subcollection: technology_features/' + featureId + '/analytics_events');
      
      // Build query
      const constraints: any[] = [
        where('timestamp', '>=', Timestamp.fromDate(dateRange.start)),
        where('timestamp', '<=', Timestamp.fromDate(dateRange.end)),
      ];
      
      constraints.push(orderBy('timestamp', 'desc'));
      constraints.push(limit(1000));
      
      const q = query(eventsRef, ...constraints);
      
      console.log('⏳ [getFeatureEvents] Executing subcollection query...');
      const snapshot = await getDocs(q);
      console.log('✅ [getFeatureEvents] Subcollection query completed. Found', snapshot.docs.length, 'documents');
      
      events = snapshot.docs.map(doc => {
        const data = doc.data();
        const event = {
          id: doc.id,
          userId: data.userId || null,
          anonUserId: data.anonUserId || '',
          eventName: data.eventName || '',
          feature: data.feature || featureId,
          timestamp: data.timestamp?.toDate() || new Date(),
          sessionId: data.sessionId || '',
          cohortType: data.cohortType || null,
          gestationalWeek: data.gestationalWeek || null,
          trimester: data.trimester || null,
          metadata: data.metadata || {},
        };
        
        // Log sample events for debugging
        if (snapshot.docs.indexOf(doc) < 3) {
          console.log('📄 [getFeatureEvents] Sample event from subcollection:', {
            id: event.id,
            eventName: event.eventName,
            anonUserId: event.anonUserId,
            timestamp: event.timestamp.toISOString(),
            feature: event.feature,
          });
        }
        
        return event;
      });
      
      if (events.length > 0) {
        console.log('✅ [getFeatureEvents] Using', events.length, 'events from subcollection');
        return events;
      }
    } catch (subcollectionError) {
      console.warn('⚠️ [getFeatureEvents] Subcollection query failed, will try legacy collection:', subcollectionError);
    }
    
    // Fallback to legacy analytics_events collection
    console.log('🔄 [getFeatureEvents] Trying legacy analytics_events collection...');
    const eventsRef = collection(firestore, 'analytics_events');
    const constraints: any[] = [
      where('timestamp', '>=', Timestamp.fromDate(dateRange.start)),
      where('timestamp', '<=', Timestamp.fromDate(dateRange.end)),
      where('feature', '==', analyticsFeature || feature),
      orderBy('timestamp', 'desc'),
      limit(1000),
    ];
    const q = query(eventsRef, ...constraints);
    console.log('⏳ [getFeatureEvents] Executing legacy query...');
    const snapshot = await getDocs(q);
    console.log('✅ [getFeatureEvents] Legacy query completed. Found', snapshot.docs.length, 'documents');
    
    events = snapshot.docs.map(doc => {
      const data = doc.data();
      const event = {
        id: doc.id,
        userId: data.userId || null,
        anonUserId: data.anonUserId || '',
        eventName: data.eventName || '',
        feature: data.feature || (analyticsFeature || feature),
        timestamp: data.timestamp?.toDate() || new Date(),
        sessionId: data.sessionId || '',
        cohortType: data.cohortType || null,
        gestationalWeek: data.gestationalWeek || null,
        trimester: data.trimester || null,
        metadata: data.metadata || {},
      };
      
      // Log sample events for debugging
      if (snapshot.docs.indexOf(doc) < 3) {
        console.log('📄 [getFeatureEvents] Sample event from legacy collection:', {
          id: event.id,
          eventName: event.eventName,
          anonUserId: event.anonUserId,
          timestamp: event.timestamp.toISOString(),
          feature: event.feature,
        });
      }
      
      return event;
    });
    
    console.log('📈 [getFeatureEvents] Returning', events.length, 'events from legacy collection');
    return events;
  } catch (error) {
    console.error('❌ [getFeatureEvents] Error fetching feature events:', error);
    return [];
  }
}

/**
 * Get analytics summary for a feature
 */
export async function getFeatureAnalyticsSummary(
  feature: string,
  dateRange: { start: Date; end: Date } = {
    start: new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), // Default to 90 days to capture more history for returning users
    end: new Date()
  }
): Promise<FeatureAnalyticsSummary> {
  console.log('🚀 [getFeatureAnalyticsSummary] Starting for feature:', feature);
  
  // Validate and map feature ID to analytics feature name
  if (!feature || feature.trim() === '') {
    console.warn('⚠️ [getFeatureAnalyticsSummary] feature parameter is empty');
    return {
      feature: feature || 'unknown',
      totalEvents: 0,
      uniqueUsers: 0,
      uniqueSessions: 0,
      usersThisWeek: 0,
      returningUsers: 0,
      eventsByType: {},
      recentEvents: [],
      cohortBreakdown: { navigator: 0, self_directed: 0, unknown: 0 },
      trimesterBreakdown: { first: 0, second: 0, third: 0, postpartum: 0, unknown: 0 },
    };
  }
  
  // Map feature ID to analytics feature name
  const analyticsFeature = mapFeatureIdToAnalyticsFeature(feature);
  console.log('🔄 [getFeatureAnalyticsSummary] Feature mapping:', { original: feature, mapped: analyticsFeature });
  
  if (!analyticsFeature) {
    console.warn(`⚠️ [getFeatureAnalyticsSummary] Could not map feature ID "${feature}" to analytics feature name`);
    return {
      feature: feature,
      totalEvents: 0,
      uniqueUsers: 0,
      uniqueSessions: 0,
      usersThisWeek: 0,
      returningUsers: 0,
      eventsByType: {},
      recentEvents: [],
      cohortBreakdown: { navigator: 0, self_directed: 0, unknown: 0 },
      trimesterBreakdown: { first: 0, second: 0, third: 0, postpartum: 0, unknown: 0 },
    };
  }
  
  // Get events for the full date range (to check for returning users)
  console.log('📥 [getFeatureAnalyticsSummary] Fetching events...');
  const allEvents = await getFeatureEvents(analyticsFeature, dateRange);
  console.log('📊 [getFeatureAnalyticsSummary] Retrieved', allEvents.length, 'total events');
  
  if (allEvents.length === 0) {
    console.warn('⚠️ [getFeatureAnalyticsSummary] No events found for feature:', analyticsFeature);
  }
  
  // Calculate this week's date range (last 7 days)
  // Use UTC to avoid timezone issues
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setUTCDate(now.getUTCDate() - 7);
  weekStart.setUTCHours(0, 0, 0, 0);
  
  // Ensure we're using the correct timezone-aware dates
  const weekStartTime = weekStart.getTime();
  const nowTime = now.getTime();
  
  console.log('📅 [getFeatureAnalyticsSummary] Date ranges:', {
    weekStart: weekStart.toISOString(),
    weekStartLocal: weekStart.toLocaleString(),
    now: now.toISOString(),
    nowLocal: now.toLocaleString(),
    dateRangeStart: dateRange.start.toISOString(),
    dateRangeStartLocal: dateRange.start.toLocaleString(),
    dateRangeEnd: dateRange.end.toISOString(),
    dateRangeEndLocal: dateRange.end.toLocaleString(),
    daysInRange: Math.round((dateRange.end.getTime() - dateRange.start.getTime()) / (24 * 60 * 60 * 1000)),
    daysInWeek: Math.round((nowTime - weekStartTime) / (24 * 60 * 60 * 1000)),
  });
  
  // Get events from this week (last 7 days)
  const thisWeekEvents = allEvents.filter(event => {
    const eventTime = event.timestamp.getTime();
    const weekStartTime = weekStart.getTime();
    const nowTime = now.getTime();
    return eventTime >= weekStartTime && eventTime <= nowTime;
  });
  console.log('📈 [getFeatureAnalyticsSummary] Events this week (last 7 days):', thisWeekEvents.length);
  
  // Count events per user (across all time in the date range)
  const userEventCounts: Record<string, number> = {};
  allEvents.forEach(event => {
    if (event.anonUserId) {
      userEventCounts[event.anonUserId] = (userEventCounts[event.anonUserId] || 0) + 1;
    }
  });
  
  console.log('📊 [getFeatureAnalyticsSummary] Total unique users in date range:', Object.keys(userEventCounts).length);
  console.log('📊 [getFeatureAnalyticsSummary] User event counts sample:', 
    Object.entries(userEventCounts).slice(0, 5).map(([userId, count]) => ({ userId: userId.substring(0, 8) + '...', count }))
  );
  
  // Users this week - unique users who used the feature this week
  const usersThisWeekSet = new Set<string>();
  const usersByDay: Record<string, Set<string>> = {};
  
  thisWeekEvents.forEach(event => {
    if (event.anonUserId) {
      usersThisWeekSet.add(event.anonUserId);
      
      // Group by day for logging
      const dayKey = event.timestamp.toISOString().split('T')[0]; // YYYY-MM-DD
      if (!usersByDay[dayKey]) {
        usersByDay[dayKey] = new Set<string>();
      }
      usersByDay[dayKey].add(event.anonUserId);
    }
  });
  
  // Log users per day
  console.log('📆 [getFeatureAnalyticsSummary] Users per day this week:');
  Object.entries(usersByDay).forEach(([day, users]) => {
    console.log(`  ${day}: ${users.size} unique users`);
  });
  
  console.log('👥 [getFeatureAnalyticsSummary] Total unique users this week:', usersThisWeekSet.size);
  
  // Returning users = users who used this week AND have 2+ total events (meaning they've used it before)
  const returningUsersSet = new Set<string>();
  usersThisWeekSet.forEach(userId => {
    const totalEventCount = userEventCounts[userId] || 0;
    if (totalEventCount >= 2) {
      returningUsersSet.add(userId);
      console.log(`  ✅ Returning user: ${userId.substring(0, 8)}... (${totalEventCount} total events)`);
    }
  });
  
  console.log('🔄 [getFeatureAnalyticsSummary] Returning users (used this week AND have 2+ total events):', returningUsersSet.size);
  console.log('📊 [getFeatureAnalyticsSummary] Breakdown:', {
    usersThisWeek: usersThisWeekSet.size,
    returningUsers: returningUsersSet.size,
    newUsers: usersThisWeekSet.size - returningUsersSet.size,
    returningPercentage: usersThisWeekSet.size > 0 
      ? ((returningUsersSet.size / usersThisWeekSet.size) * 100).toFixed(1) + '%'
      : '0%',
  });
  
  const uniqueUsers = new Set<string>();
  const uniqueSessions = new Set<string>();
  const eventsByType: Record<string, number> = {};
  const cohortBreakdown = {
    navigator: 0,
    self_directed: 0,
    unknown: 0,
  };
  const trimesterBreakdown = {
    first: 0,
    second: 0,
    third: 0,
    postpartum: 0,
    unknown: 0,
  };
  
  allEvents.forEach(event => {
    if (event.anonUserId) uniqueUsers.add(event.anonUserId);
    if (event.sessionId) uniqueSessions.add(event.sessionId);
    
    eventsByType[event.eventName] = (eventsByType[event.eventName] || 0) + 1;
    
    if (event.cohortType === 'navigator') {
      cohortBreakdown.navigator++;
    } else if (event.cohortType === 'self_directed') {
      cohortBreakdown.self_directed++;
    } else {
      cohortBreakdown.unknown++;
    }
    
    if (event.trimester) {
      const trimester = event.trimester.toLowerCase();
      if (trimester.includes('first')) {
        trimesterBreakdown.first++;
      } else if (trimester.includes('second')) {
        trimesterBreakdown.second++;
      } else if (trimester.includes('third')) {
        trimesterBreakdown.third++;
      } else if (trimester.includes('postpartum')) {
        trimesterBreakdown.postpartum++;
      } else {
        trimesterBreakdown.unknown++;
      }
    } else {
      trimesterBreakdown.unknown++;
    }
  });
  
  const result = {
    feature: analyticsFeature,
    totalEvents: allEvents.length,
    uniqueUsers: uniqueUsers.size,
    uniqueSessions: uniqueSessions.size,
    usersThisWeek: usersThisWeekSet.size,
    returningUsers: returningUsersSet.size,
    eventsByType,
    recentEvents: allEvents.slice(0, 10),
    cohortBreakdown,
    trimesterBreakdown,
    engagementTrend: [], // Placeholder, actual calculation would be more complex
    usageByWeek: [],     // Placeholder
  };
  
  console.log('✅ [getFeatureAnalyticsSummary] Final result:', {
    feature: result.feature,
    totalEvents: result.totalEvents,
    uniqueUsers: result.uniqueUsers,
    uniqueSessions: result.uniqueSessions,
    usersThisWeek: result.usersThisWeek,
    returningUsers: result.returningUsers,
    returningPercentage: result.usersThisWeek > 0 
      ? ((result.returningUsers / result.usersThisWeek) * 100).toFixed(1) + '%'
      : '0%',
  });
  
  return result;
}

/**
 * Get all features with analytics
 */
export async function getAllFeaturesWithAnalytics(
  dateRange: { start: Date; end: Date } = {
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date()
  }
): Promise<Record<string, FeatureAnalyticsSummary>> {
  try {
    const eventsRef = collection(firestore, 'analytics_events');
    const q = query(
      eventsRef,
      where('timestamp', '>=', Timestamp.fromDate(dateRange.start)),
      where('timestamp', '<=', Timestamp.fromDate(dateRange.end)),
      orderBy('timestamp', 'desc'),
      limit(5000)
    );
    
    const snapshot = await getDocs(q);
    const eventsByFeature: Record<string, AnalyticsEvent[]> = {};
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const feature = data.feature || 'unknown';
      if (!eventsByFeature[feature]) {
        eventsByFeature[feature] = [];
      }
      eventsByFeature[feature].push({
        id: doc.id,
        userId: data.userId || null,
        anonUserId: data.anonUserId || '',
        eventName: data.eventName || '',
        feature: data.feature || '',
        timestamp: data.timestamp?.toDate() || new Date(),
        sessionId: data.sessionId || '',
        cohortType: data.cohortType || null,
        gestationalWeek: data.gestationalWeek || null,
        trimester: data.trimester || null,
        metadata: data.metadata || {},
      });
    });
    
    const summaries: Record<string, FeatureAnalyticsSummary> = {};
    
    for (const [feature, events] of Object.entries(eventsByFeature)) {
      // Calculate this week's date range
      const now = new Date();
      const weekStart = new Date(now);
      weekStart.setDate(now.getDate() - 7);
      weekStart.setHours(0, 0, 0, 0);
      
      // Get events from this week
      const thisWeekEvents = events.filter(event => 
        event.timestamp >= weekStart && event.timestamp <= now
      );
      
      // Get events from before this week (to identify returning users)
      const beforeThisWeekEvents = events.filter(event => 
        event.timestamp < weekStart
      );
      
      // Users this week
      const usersThisWeekSet = new Set<string>();
      thisWeekEvents.forEach(event => {
        if (event.anonUserId) usersThisWeekSet.add(event.anonUserId);
      });
      
      // Users from before this week
      const previousUsersSet = new Set<string>();
      beforeThisWeekEvents.forEach(event => {
        if (event.anonUserId) previousUsersSet.add(event.anonUserId);
      });
      
      // Returning users = users who used this week AND used before
      const returningUsersSet = new Set<string>();
      usersThisWeekSet.forEach(userId => {
        if (previousUsersSet.has(userId)) {
          returningUsersSet.add(userId);
        }
      });
      
      const uniqueUsers = new Set<string>();
      const uniqueSessions = new Set<string>();
      const eventsByType: Record<string, number> = {};
      const cohortBreakdown = {
        navigator: 0,
        self_directed: 0,
        unknown: 0,
      };
      const trimesterBreakdown = {
        first: 0,
        second: 0,
        third: 0,
        postpartum: 0,
        unknown: 0,
      };
      
      events.forEach(event => {
        if (event.anonUserId) uniqueUsers.add(event.anonUserId);
        if (event.sessionId) uniqueSessions.add(event.sessionId);
        
        eventsByType[event.eventName] = (eventsByType[event.eventName] || 0) + 1;
        
        if (event.cohortType === 'navigator') {
          cohortBreakdown.navigator++;
        } else if (event.cohortType === 'self_directed') {
          cohortBreakdown.self_directed++;
        } else {
          cohortBreakdown.unknown++;
        }
        
        if (event.trimester) {
          const trimester = event.trimester.toLowerCase();
          if (trimester.includes('first')) {
            trimesterBreakdown.first++;
          } else if (trimester.includes('second')) {
            trimesterBreakdown.second++;
          } else if (trimester.includes('third')) {
            trimesterBreakdown.third++;
          } else if (trimester.includes('postpartum')) {
            trimesterBreakdown.postpartum++;
          } else {
            trimesterBreakdown.unknown++;
          }
        } else {
          trimesterBreakdown.unknown++;
        }
      });
      
      summaries[feature] = {
        feature,
        totalEvents: events.length,
        uniqueUsers: uniqueUsers.size,
        uniqueSessions: uniqueSessions.size,
        usersThisWeek: usersThisWeekSet.size,
        returningUsers: returningUsersSet.size,
        eventsByType,
        recentEvents: events.slice(0, 10),
        cohortBreakdown,
        trimesterBreakdown,
      };
    }
    
    return summaries;
  } catch (error) {
    console.error('Error fetching all features analytics:', error);
    return {};
  }
}
