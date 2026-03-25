/**
 * Realtime aggregation for mobile-originated `analytics_events` documents.
 * Skips `source: cloud_function` rows to avoid double-counting (CF + client both write).
 */
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

function escapeKey(s: string): string {
  const t = String(s || 'unknown').replace(/[^a-zA-Z0-9_]/g, '_');
  return t.substring(0, 100) || 'unknown';
}

function safeDateKey(data: admin.firestore.DocumentData): string {
  if (typeof data.dateKey === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(data.dateKey)) {
    return data.dateKey;
  }
  const ts = data.timestamp as admin.firestore.Timestamp | undefined;
  if (ts && typeof ts.toDate === 'function') {
    return ts.toDate().toISOString().split('T')[0];
  }
  return new Date().toISOString().split('T')[0];
}

function safeHourKey(data: admin.firestore.DocumentData, dateKey: string): string {
  if (typeof data.hourKey === 'string' && /^\d{4}-\d{2}-\d{2}-\d{2}$/.test(data.hourKey)) {
    return data.hourKey;
  }
  const ts = data.timestamp as admin.firestore.Timestamp | undefined;
  if (ts && typeof ts.toDate === 'function') {
    const d = ts.toDate();
    const h = d.getUTCHours().toString().padStart(2, '0');
    return `${dateKey}-${h}`;
  }
  return `${dateKey}-00`;
}

/**
 * First-class counters derived from EmpowerHealth inventory event names.
 */
function firstClassIncrements(eventName: string): {
  global: Record<string, admin.firestore.FieldValue | number>;
  daily: Record<string, admin.firestore.FieldValue | number>;
} {
  const g: Record<string, FirebaseFirestore.FieldValue | number> = {};
  const d: Record<string, FirebaseFirestore.FieldValue | number> = {};

  switch (eventName) {
    case 'community_post_created':
      g.todayPostsCreated = FieldValue.increment(1);
      d.postsCreated = FieldValue.increment(1);
      break;
    case 'community_reply_created':
      d.commentsCreated = FieldValue.increment(1);
      break;
    case 'journal_entry_created':
      g.todayJournalEntries = FieldValue.increment(1);
      break;
    case 'visit_summary_created':
      g.todayVisitSummaries = FieldValue.increment(1);
      d.eventsSubmitted = FieldValue.increment(1);
      break;
    case 'birth_plan_completed':
      g.todayBirthPlansCompleted = FieldValue.increment(1);
      break;
    case 'provider_search_initiated':
      g.todayProviderSearches = FieldValue.increment(1);
      break;
    case 'session_started':
      g.todaySessionsStarted = FieldValue.increment(1);
      break;
    case 'screen_view':
      g.todayScreenViews = FieldValue.increment(1);
      break;
    case 'profile_updated':
      g.todayProfileUpdates = FieldValue.increment(1);
      d.profileUpdated = FieldValue.increment(1);
      break;
    case 'sign_in_completed':
      g.todaySignIns = FieldValue.increment(1);
      break;
    default:
      break;
  }

  return { global: g, daily: d };
}

export const onAnalyticsEventCreated = onDocumentCreated(
  {
    document: 'analytics_events/{eventId}',
    region: 'us-central1',
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log('[onAnalyticsEventCreated] no snapshot');
      return;
    }
    const data = snap.data();

    if (data.source === 'cloud_function') {
      console.log('[onAnalyticsEventCreated] skip cloud_function', event.id);
      return;
    }

    const rawEventName = String(data.eventName || 'unknown');
    const eventNameKey = escapeKey(rawEventName);
    const featureLabel = String(data.feature || 'unknown');
    const featureDocId = featureLabel.replace(/[/\\.#$[\]]/g, '_').substring(0, 200) || 'unknown';
    const dateKey = safeDateKey(data);
    const hourKey = safeHourKey(data, dateKey);
    const safeEventKey = eventNameKey;

    const fc = firstClassIncrements(rawEventName);

    try {
      const batch = db.batch();
      const globalRef = db.collection('analytics_summary').doc('global');
      const dailyRef = db.collection('analytics_summary_daily').doc(dateKey);
      const hourlyRef = db.collection('analytics_summary_hourly').doc(hourKey);
      const featureRef = db.collection('analytics_feature_summary').doc(featureDocId);

      batch.set(
        globalRef,
        {
          updatedAt: FieldValue.serverTimestamp(),
          totalEvents: FieldValue.increment(1),
          lastEventName: rawEventName,
          lastEventAt: FieldValue.serverTimestamp(),
          aggregationVersion: 1,
          ...fc.global,
        },
        { merge: true },
      );

      batch.set(
        dailyRef,
        {
          dateKey,
          updatedAt: FieldValue.serverTimestamp(),
          totalEvents: FieldValue.increment(1),
          countsByEventName: {
            [safeEventKey]: FieldValue.increment(1),
          },
          countsByFeature: {
            [featureLabel]: FieldValue.increment(1),
          },
          ...fc.daily,
        },
        { merge: true },
      );

      batch.set(
        hourlyRef,
        {
          hourKey,
          dateKey,
          updatedAt: FieldValue.serverTimestamp(),
          totalEvents: FieldValue.increment(1),
          countsByEventName: {
            [safeEventKey]: FieldValue.increment(1),
          },
        },
        { merge: true },
      );

      batch.set(
        featureRef,
        {
          feature: featureLabel,
          updatedAt: FieldValue.serverTimestamp(),
          totalEvents: FieldValue.increment(1),
          lastEventName: rawEventName,
          lastEventAt: FieldValue.serverTimestamp(),
          countsByEventName: {
            [safeEventKey]: FieldValue.increment(1),
          },
        },
        { merge: true },
      );

      await batch.commit();
      console.log('[onAnalyticsEventCreated] ok', event.id, rawEventName, featureLabel, dateKey);
    } catch (err) {
      console.error('[onAnalyticsEventCreated] failed', event.id, err);
    }
  },
);
