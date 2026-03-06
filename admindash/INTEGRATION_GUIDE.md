# Mobile App Data Integration Guide

## Overview

The Admin Dashboard uses the **same Firestore database** as the mobile app. This allows the dashboard to display real-time data from the mobile app without any data synchronization.

## Architecture Decision

✅ **Use the same database** - This is the recommended approach because:
- Single source of truth
- Real-time data updates
- No data synchronization needed
- Simpler architecture
- Better performance

❌ **Don't create a separate database** - This would require:
- Complex data syncing
- Duplicate storage costs
- Data consistency issues
- More complex architecture

## Mobile App Collections

The mobile app uses these Firestore collections that the dashboard can access:

### User Data
- `users/{userId}` - User profiles
- `users/{userId}/notes` - Journal entries
- `users/{userId}/learning_tasks` - Learning modules and todos
- `users/{userId}/file_uploads` - PDF uploads
- `users/{userId}/fcmTokens` - Push notification tokens

### Visit Summaries
- `visit_summaries/{summaryId}` - After visit summaries

### Provider Data
- `providers/{providerId}` - Healthcare providers
- `reviews/{reviewId}` - Provider reviews
- `provider_submissions/{submissionId}` - User-submitted providers
- `identity_tags/{tagId}` - Provider identity tags
- `provider_identity_claims/{claimId}` - Identity tag claims
- `mama_approved_status/{statusId}` - Mama Approved status

## Security Rules

The Firestore security rules have been updated to allow:

1. **Mobile app users**: Can read/write their own data
2. **Admin dashboard users**: Can read all data (with role-based restrictions)
3. **Admins**: Can write to any collection
4. **Research Partners**: Can read anonymized data (via Cloud Functions)

See `firestore.rules` for the complete security configuration.

## Using Mobile App Data in Dashboard

### Example: Display Real User Count

```typescript
import { getAllUserProfiles } from '../lib/mobileAppData';

// In your component
const [userCount, setUserCount] = useState(0);

useEffect(() => {
  async function loadData() {
    const users = await getAllUserProfiles();
    setUserCount(users.length);
  }
  loadData();
}, []);
```

### Example: Display Recent Journal Entries

```typescript
import { getAllJournalEntries } from '../lib/mobileAppData';

const [entries, setEntries] = useState([]);

useEffect(() => {
  async function loadData() {
    const allEntries = await getAllJournalEntries(50);
    setEntries(allEntries);
  }
  loadData();
}, []);
```

### Example: Analytics Dashboard

```typescript
import { 
  getUserCountByStage, 
  getActiveUsersCount 
} from '../lib/mobileAppData';

const [analytics, setAnalytics] = useState({});

useEffect(() => {
  async function loadAnalytics() {
    const [byStage, activeUsers] = await Promise.all([
      getUserCountByStage(),
      getActiveUsersCount(30)
    ]);
    
    setAnalytics({
      byStage,
      activeUsers,
    });
  }
  loadAnalytics();
}, []);
```

## Available Helper Functions

All helper functions are in `src/lib/mobileAppData.ts`:

### User Data
- `getAllUserProfiles(limit?)` - Get all user profiles
- `getUserProfile(userId)` - Get specific user profile

### Journal Entries
- `getUserJournalEntries(userId, limit?)` - Get entries for a user
- `getAllJournalEntries(limit?)` - Get all entries across users

### Learning Tasks
- `getUserLearningTasks(userId, limit?)` - Get tasks for a user
- `getAllLearningTasks(limit?)` - Get all tasks across users

### Visit Summaries
- `getAllVisitSummaries(limit?)` - Get all visit summaries
- `getUserVisitSummaries(userId)` - Get summaries for a user

### Analytics
- `getUserCountByStage()` - Count users by pregnancy stage
- `getActiveUsersCount(days)` - Count active users

## Updating Dashboard Pages

### Dashboard.tsx
Update to show real data:
- Active users count from `getAllUserProfiles()`
- Recent activity from `getAllJournalEntries()` and `getAllVisitSummaries()`
- Feature usage from `getAllLearningTasks()`

### Analytics.tsx
Update to show real analytics:
- User counts by stage from `getUserCountByStage()`
- Active users from `getActiveUsersCount()`
- Feature usage from learning tasks and visit summaries

### Reports.tsx
Reports already use Cloud Functions which can aggregate mobile app data.

## Data Privacy & Anonymization

For Research Partners:
- Use Cloud Functions to anonymize data before returning
- Never expose user IDs or PII directly
- Use `analytics_events` collection (already anonymized)

For Admins:
- Full access to all data
- Can see user IDs and PII
- Use `analytics_events_private` for detailed tracking

## Next Steps

1. **Deploy updated Firestore rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Update Dashboard components** to use real data:
   - Replace mock data with calls to `mobileAppData.ts` functions
   - Add loading states
   - Handle errors gracefully

3. **Test with real data**:
   - Ensure security rules work correctly
   - Verify role-based access
   - Test anonymization for Research Partners

4. **Monitor performance**:
   - Use pagination for large datasets
   - Cache frequently accessed data
   - Use Cloud Functions for heavy aggregations

## Troubleshooting

**Error: "Missing or insufficient permissions"**
- Check Firestore rules are deployed
- Verify user has correct role in ADMIN/RESEARCH_PARTNERS/COMMUNITY_MANAGERS collection
- Check that the collection exists

**Data not updating**
- Firestore queries are real-time by default
- Use `onSnapshot()` for real-time updates instead of `getDocs()`
- Check network connectivity

**Performance issues**
- Add pagination (limit queries)
- Use Cloud Functions for heavy aggregations
- Cache data client-side when appropriate
