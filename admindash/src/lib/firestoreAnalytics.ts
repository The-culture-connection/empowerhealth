/**
 * Firestore Analytics
 * Direct Firestore queries for analytics data
 */

import { collection, query, where, getDocs, Timestamp, orderBy, limit, startAt, endAt } from 'firebase/firestore';
import { db } from '../firebase/firebase';

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
 */
export async function getFeatureEvents(
  feature: string,
  dateRange: { start: Date; end: Date } = {
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date()
  }
): Promise<AnalyticsEvent[]> {
  try {
    const eventsRef = collection(db, 'analytics_events');
    const q = query(
      eventsRef,
      where('feature', '==', feature),
      where('timestamp', '>=', Timestamp.fromDate(dateRange.start)),
      where('timestamp', '<=', Timestamp.fromDate(dateRange.end)),
      orderBy('timestamp', 'desc'),
      limit(1000)
    );
    
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
  } catch (error) {
    console.error('Error fetching feature events:', error);
    return [];
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
  const events = await getFeatureEvents(feature, dateRange);
  
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
  
  return {
    feature,
    totalEvents: events.length,
    uniqueUsers: uniqueUsers.size,
    uniqueSessions: uniqueSessions.size,
    eventsByType,
    recentEvents: events.slice(0, 10),
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
    const eventsRef = collection(db, 'analytics_events');
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
