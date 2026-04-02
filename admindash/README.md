# EmpowerHealth Admin Dashboard

A comprehensive admin dashboard webapp built with Vite + React + Firebase for managing the EmpowerHealth maternal health platform.

## Features

- **Authentication & RBAC**: Role-based access control with Admin, Research Partner, and Community Manager roles
- **Documentation Management**: Upload and manage Privacy Policy, Terms & Conditions, and Support documents
- **Technology Overview**: Display build versions with feature dossiers from Flutter app
- **Analytics Dashboard**: View anonymized and unanonymized analytics with charts and metrics
- **Report Generation**: Generate and export research reports (CSV/JSON) with insights
- **Push Notifications**: Compose and send push notifications to user segments
- **User Management**: Onboard users and assign roles
- **Audit Logging**: Comprehensive audit trail for all admin actions

## Prerequisites

- Node.js 18+ and npm/pnpm
- Firebase project with:
  - Authentication enabled
  - Firestore database
  - Storage bucket
  - Cloud Functions (for production)

## Setup Instructions

### 1. Install Dependencies

```bash
cd "Admin Dashboard"
npm install
# or
pnpm install
```

### 2. Configure Firebase

1. Copy the example environment file:
   ```bash
   cp .env.local.example .env.local
   ```

2. Get your Firebase config from the Firebase Console:
   - Go to Project Settings > General
   - Scroll to "Your apps" and select your web app (or create one)
   - Copy the Firebase configuration object

3. Fill in `.env.local` with your Firebase credentials:
   ```env
   VITE_FIREBASE_API_KEY=your-api-key-here
   VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=your-project-id
   VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
   VITE_FIREBASE_APP_ID=your-app-id
   VITE_FIREBASE_MEASUREMENT_ID=your-measurement-id
   VITE_FUNCTIONS_URL=https://us-central1-your-project.cloudfunctions.net
   ```

### 3. Set Up Firestore Collections

Create the following collections in Firestore:

- `ADMIN` - Admin users (documents keyed by uid)
- `RESEARCH_PARTNERS` - Research partner users (documents keyed by uid)
- `COMMUNITY_MANAGERS` - Community manager users (documents keyed by uid)
- `admin_documents` - Documentation metadata
- `build_versions` - Build version history
- `analytics_events` - Anonymized analytics events
- `analytics_events_private` - Unanonymized analytics events (Admin only)
- `audit_logs` - Audit trail

### 4. Set Up Firestore Security Rules

Add these rules to your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is admin
    function isAdmin() {
      return exists(/databases/$(database)/documents/ADMIN/$(request.auth.uid));
    }
    
    // Helper function to check if user is research partner
    function isResearchPartner() {
      return exists(/databases/$(database)/documents/RESEARCH_PARTNERS/$(request.auth.uid));
    }
    
    // Helper function to check if user is community manager
    function isCommunityManager() {
      return exists(/databases/$(database)/documents/COMMUNITY_MANAGERS/$(request.auth.uid));
    }
    
    // Role collections - only admins can write
    match /ADMIN/{uid} {
      allow read: if isAdmin() || isResearchPartner() || isCommunityManager();
      allow write: if isAdmin();
    }
    
    match /RESEARCH_PARTNERS/{uid} {
      allow read: if isAdmin() || isResearchPartner() || isCommunityManager();
      allow write: if isAdmin();
    }
    
    match /COMMUNITY_MANAGERS/{uid} {
      allow read: if isAdmin() || isResearchPartner() || isCommunityManager();
      allow write: if isAdmin();
    }
    
    // Admin documents - all authenticated users can read, only admins can write
    match /admin_documents/{docId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
      
      match /history/{historyId} {
        allow read: if request.auth != null;
        allow write: if isAdmin();
      }
    }
    
    // Build versions - all authenticated users can read
    match /build_versions/{buildNumber} {
      allow read: if request.auth != null;
      allow write: if false; // Only via Cloud Function
    }
    
    // Analytics - anonymized for research partners, full access for admins
    match /analytics_events/{eventId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via Cloud Function
    }
    
    match /analytics_events_private/{eventId} {
      allow read: if isAdmin();
      allow write: if false; // Only via Cloud Function
    }
    
    // Audit logs - only admins can read
    match /audit_logs/{logId} {
      allow read: if isAdmin();
      allow write: if request.auth != null; // Cloud Functions can write
    }
  }
}
```

### 5. Run Development Server

```bash
npm run dev
# or
pnpm dev
```

The app will be available at `http://localhost:5173`

### 6. Create First Admin User

1. Sign up a user via Firebase Authentication (email/password)
2. Manually create a document in the `ADMIN` collection:
   - Document ID: user's uid
   - Fields: `{ email, displayName, role: "admin", createdAt, createdBy: "system" }`
3. Sign in with that user's credentials

## Cloud Functions Setup

### 1. Install Functions Dependencies

```bash
cd functions
npm install
```

### 2. Configure Functions

Set the analytics salt (for anonymization):

```bash
firebase functions:config:set analytics.salt="your-random-salt-here"
```

### 3. Deploy Functions

```bash
firebase deploy --only functions
```

## Uploading Build Versions

Build versions are uploaded via Cloud Function. You can call it from a CI/CD script or manually.

### Using the Cloud Function

```javascript
import { httpsCallable } from 'firebase/functions';
import { functions } from './firebase/firebase';

const uploadBuildVersion = httpsCallable(functions, 'uploadBuildVersion');

await uploadBuildVersion({
  fullVersion: "1.2.3+13",
  commitHash: "abc123def456",
  featureDossier: {
    summary: "Major update with new features",
    features: [
      {
        name: "New Learning Module",
        description: "Added comprehensive birth planning content",
        status: "active",
        tags: ["Learning"],
        userFacingImpacts: ["Improved birth preparation", "Better user engagement"]
      }
    ],
    notes: "This build includes significant improvements to the learning module",
    knownIssues: ["Minor UI glitch on iOS"]
  }
});
```

### From Flutter Repo (Node Script)

Create a script in your Flutter repo to parse `pubspec.yaml` and call the function:

```javascript
// scripts/publish_build_version.js
const yaml = require('js-yaml');
const fs = require('fs');
const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./path-to-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Parse pubspec.yaml
const pubspec = yaml.load(fs.readFileSync('pubspec.yaml', 'utf8'));
const version = pubspec.version; // e.g., "1.2.3+13"

// Parse version
const [versionName, buildNumber] = version.split('+');

// Call Cloud Function
const functions = admin.functions();
const uploadBuildVersion = functions.httpsCallable('uploadBuildVersion');

uploadBuildVersion({
  fullVersion: version,
  commitHash: process.env.GIT_COMMIT_HASH || 'unknown',
  featureDossier: {
    summary: "Build from CI/CD",
    features: [], // Add features from your changelog
    notes: "",
    knownIssues: []
  }
}).then(result => {
  console.log('Build version uploaded:', result.data);
}).catch(error => {
  console.error('Error uploading build version:', error);
});
```

## Production Build

```bash
npm run build
# or
pnpm build
```

The built files will be in the `dist` directory. Deploy to your hosting service (Firebase Hosting, Vercel, Netlify, etc.).

### Deploy to Firebase Hosting

```bash
firebase init hosting
firebase deploy --only hosting
```

## Project Structure

```
Admin Dashboard/
├── src/
│   ├── app/
│   │   ├── components/
│   │   │   ├── Layout.tsx          # Main layout with navigation
│   │   │   └── ui/                 # UI components (shadcn/ui)
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx       # Main dashboard
│   │   │   ├── Documentation.tsx   # Document management
│   │   │   ├── TechnologyOverview.tsx  # Build versions
│   │   │   ├── UsersAndRoles.tsx   # User management
│   │   │   ├── Analytics.tsx        # Analytics dashboard
│   │   │   ├── Reports.tsx         # Report generation
│   │   │   ├── Notifications.tsx   # Push notifications
│   │   │   └── Login.tsx           # Login page
│   │   ├── routes.ts               # Route configuration
│   │   └── App.tsx                 # App root
│   ├── contexts/
│   │   └── AuthContext.tsx         # Auth & RBAC context
│   ├── lib/
│   │   ├── userManagement.ts       # User onboarding
│   │   ├── documentation.ts       # Document upload/view
│   │   ├── buildVersions.ts        # Build version management
│   │   ├── analytics.ts            # Analytics logging
│   │   └── reports.ts              # Report generation
│   ├── firebase/
│   │   ├── config.ts               # Config loader
│   │   └── firebase.ts             # Firebase initialization
│   └── components/
│       ├── ErrorBoundary.tsx        # Error handling
│       └── RoleRoute.tsx           # Route protection
├── functions/
│   ├── src/
│   │   └── index.ts                # Cloud Functions
│   └── package.json
├── .env.local.example              # Environment template
└── README.md
```

## Role Permissions

### Admin
- Full access to all features
- Can manage users and roles
- Can upload documents
- Can view unanonymized analytics
- Can generate all report types

### Research Partner
- View anonymized analytics only
- Can generate anonymized reports
- Can view documentation
- Cannot manage users
- Cannot upload documents

### Community Manager
- Manage content and push notifications
- View aggregate analytics only
- Cannot access reports
- Cannot manage users

## Troubleshooting

### Firebase Config Error
If you see a configuration error on startup:
1. Check that `.env.local` exists and has all required variables
2. Verify Firebase credentials are correct
3. Restart the dev server

### Authentication Issues
- Ensure Firebase Authentication is enabled in your project
- Check that email/password provider is enabled
- Verify user exists in the appropriate role collection

### Cloud Functions Not Working
- Ensure functions are deployed: `firebase deploy --only functions`
- Check function logs: `firebase functions:log`
- Verify function URL in `.env.local`

## Support

For issues or questions, contact the development team or refer to the main EmpowerHealth documentation.
