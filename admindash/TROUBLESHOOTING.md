# Troubleshooting Guide

## Permission Errors After Deploying Firestore Rules

If you're getting "Missing or insufficient permissions" errors, check the following:

### 1. Verify Your User Has a Role Document

The admin dashboard requires users to have a role document in one of these collections:
- `ADMIN/{uid}` - For admins
- `RESEARCH_PARTNERS/{uid}` - For research partners  
- `COMMUNITY_MANAGERS/{uid}` - For community managers

**Check if you have a role document:**
1. Go to Firebase Console → Firestore Database
2. Check if there's a document in `ADMIN` collection with your UID as the document ID
3. If not, you need to create one (see below)

### 2. Create Your Admin Role Document

If you don't have a role document, create one:

**Option A: Using Firebase Console**
1. Go to Firestore Database
2. Create a new document in `ADMIN` collection
3. Use your Firebase Auth UID as the document ID
4. Add fields:
   - `email`: your email address
   - `displayName`: your name (optional)
   - `role`: "admin"
   - `createdAt`: current timestamp
   - `createdBy`: your UID

**Option B: Using the Admin Dashboard**
1. Log in to the admin dashboard
2. Go to "Users & Roles" page
3. Search for your email
4. Assign yourself the "Admin" role

### 3. Email Fallback

If your email is one of these, you should have access even without a role document:
- `osrgnoi@gmail.com`
- `corinntaylor@gmail.com`

If your email is different, you need to either:
- Add it to the `isAdminByEmail()` function in `firestore.rules`, OR
- Create a role document (recommended)

### 4. Check What Specific Permission Error You're Getting

The error message will tell you which collection is failing:
- `technology_features` - You need admin dashboard role
- `releases` - You need admin dashboard role
- `system_health` - You need admin dashboard role
- `users` - You need admin dashboard role to read all users

### 5. Verify Rules Were Deployed

Make sure the rules were deployed successfully:
```bash
cd admindash
firebase deploy --only firestore:rules
```

Check the Firebase Console to verify the rules match what's in `firestore.rules`.

## TypeScript Compilation Errors

All TypeScript errors have been fixed. The functions should now compile successfully.

## Testing After Deployment

1. **Deploy functions:**
   ```bash
   cd admindash
   firebase deploy --only functions
   ```

2. **Deploy rules:**
   ```bash
   cd admindash
   firebase deploy --only firestore:rules
   ```

3. **Test in the dashboard:**
   - Log in to the admin dashboard
   - Try accessing the Technology Overview page
   - Check browser console for any errors
   - Check Network tab to see which Firestore queries are failing
