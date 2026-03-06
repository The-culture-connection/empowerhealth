# Deployment Commands

## Prerequisites

Make sure you're in the `admindash` directory and authenticated with Firebase:

```bash
cd "C:\Users\grace\The Culture Connection Tech Solutions\Empower Health Watch\EmpowerHealth\admindash"
firebase login
```

## Deploy All Functions

To deploy all Cloud Functions (recommended):

```bash
firebase deploy --only functions
```

**Note:** This will deploy all functions including the new ones:
- `getFeatureAnalytics` (new)
- `updateFeature` (new)
- `publishRelease` (enhanced)
- All existing functions

## Deploy Specific Functions

If you only want to deploy the new functions:

### Deploy getFeatureAnalytics function
```bash
cd admindash
firebase deploy --only functions:getFeatureAnalytics
```

### Deploy updateFeature function
```bash
cd admindash
firebase deploy --only functions:updateFeature
```

### Deploy publishRelease function (enhanced version)
```bash
cd admindash
firebase deploy --only functions:publishRelease
```

### Deploy both new functions together
```bash
cd admindash
firebase deploy --only functions:getFeatureAnalytics,functions:updateFeature
```

## Deploy Firestore Rules

```bash
cd admindash
firebase deploy --only firestore:rules
```

## Deploy Everything

To deploy functions, rules, and indexes together:

```bash
cd admindash
firebase deploy --only functions,firestore:rules,firestore:indexes
```
