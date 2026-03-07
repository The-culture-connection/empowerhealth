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
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date()
  }
): Promise<AnalyticsEvent[]> {
  try {
    // Validate feature parameter
    if (!feature || feature.trim() === '') {
      console.warn('getFeatureEvents: feature parameter is empty, returning empty array');
      return [];
    }
    
    // Map feature ID to analytics feature name (for backward compatibility)
    const analyticsFeature = mapFeatureIdToAnalyticsFeature(feature);
    const featureId = analyticsFeature || feature;
    
    // Query from technology_features/{featureId}/analytics_events subcollection
    const eventsRef = collection(firestore, 'technology_features', featureId, 'analytics_events');
    
    // Build query
    const constraints: any[] = [
      where('timestamp', '>=', Timestamp.fromDate(dateRange.start)),
      where('timestamp', '<=', Timestamp.fromDate(dateRange.end)),
    ];
    
    constraints.push(orderBy('timestamp', 'desc'));
    constraints.push(limit(1000));
    
    const q = query(eventsRef, ...constraints);
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
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
    });
  } catch (error) {
    console.error('Error fetching feature events:', error);
    // Fallback to legacy collection if subcollection doesn't exist
    try {
      console.log('Attempting fallback to legacy analytics_events collection...');
      const eventsRef = collection(firestore, 'analytics_events');
      const analyticsFeature = mapFeatureIdToAnalyticsFeature(feature);
      const constraints: any[] = [
        where('timestamp', '>=', Timestamp.fromDate(dateRange.start)),
        where('timestamp', '<=', Timestamp.fromDate(dateRange.end)),
        where('feature', '==', analyticsFeature || feature),
        orderBy('timestamp', 'desc'),
        limit(1000),
      ];
      const q = query(eventsRef, ...constraints);
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => {
        const data = doc.data();
        return {
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
        };
      });
    } catch (fallbackError) {
      console.error('Fallback query also failed:', fallbackError);
      return [];
    }
  }
}

/**
 * Get analytics summary for a feature
 */
export async function getFeatureAnalyticsSummary(
  feature: string,
  dateRange: { start: Date; end: Date } = {
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date()
  }
): Promise<FeatureAnalyticsSummary> {
  // Validate and map feature ID to analytics feature name
  if (!feature || feature.trim() === '') {
    console.warn('getFeatureAnalyticsSummary: feature parameter is empty');
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
  if (!analyticsFeature) {
    console.warn(`getFeatureAnalyticsSummary: Could not map feature ID "${feature}" to analytics feature name`);
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
  const allEvents = await getFeatureEvents(analyticsFeature, dateRange);
  
  // Calculate this week's date range
  const now = new Date();
  const weekStart = new Date(now);
  weekStart.setDate(now.getDate() - 7);
  weekStart.setHours(0, 0, 0, 0);
  
  // Get events from this week
  const thisWeekEvents = allEvents.filter(event => 
    event.timestamp >= weekStart && event.timestamp <= now
  );
  
  // Get events from before this week (to identify returning users)
  const beforeThisWeekEvents = allEvents.filter(event => 
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
  
  return {
    feature,
    totalEvents: allEvents.length,
    uniqueUsers: uniqueUsers.size,
    uniqueSessions: uniqueSessions.size,
    usersThisWeek: usersThisWeekSet.size,
    returningUsers: returningUsersSet.size,
    eventsByType,
    recentEvents: allEvents.slice(0, 10),
    cohortBreakdown,
    trimesterBreakdown,
  };
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
