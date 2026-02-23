# Provider Search Firebase Function

## Overview
This document describes the Firebase Cloud Function for provider search that processes API requests and returns combined results from Ohio Medicaid and NPI Registry.

## Function Location
The function code is in `functions/searchProviders.js` (placeholder structure created).

## Integration into index.js

To integrate this function into `functions/index.js`, add the following at the end of the file (before the closing):

```javascript
// Import the searchProviders function
const {searchProviders} = require("./searchProviders");

// Export it (if using separate file)
// OR inline the function directly in index.js
```

## Deployment Command

To deploy ONLY the searchProviders function:

```bash
firebase deploy --only functions:searchProviders
```

To deploy ALL functions:

```bash
firebase deploy --only functions
```

## Required Dependencies

Add to `functions/package.json`:

```json
{
  "dependencies": {
    "axios": "^1.6.0"
  }
}
```

Then run:

```bash
cd functions && npm install
```

## Function Parameters

The function accepts the following parameters:

- `zip` (required): 5-digit ZIP code
- `city` (required): City name
- `healthPlan` (required): Health plan name (must match Ohio Medicaid options)
- `providerTypeIds` (required): Array of provider type IDs (e.g., ["09", "71"])
- `radius` (required): Search radius in miles
- `specialty` (optional): Specialty name for filtering
- `includeNpi` (optional, default: false): Whether to include NPI Registry results
- `acceptsPregnantWomen` (optional): Boolean filter
- `acceptsNewborns` (optional): Boolean filter
- `telehealth` (optional): Boolean filter

## Return Value

The function returns:

```javascript
{
  providers: Array<Provider>, // Array of provider objects
  count: number // Number of providers found
}
```

## Implementation Status

⚠️ **NOTE**: The function in `functions/searchProviders.js` is a placeholder structure. The following still needs to be implemented:

1. **Full FHIR Bundle Parsing**: Complete the `parseMedicaidResponse` function to properly extract all provider data from FHIR resources
2. **NPI API Integration**: Implement the NPI Registry API call with proper taxonomy code mapping
3. **Deduplication Logic**: Remove duplicate providers from combined results
4. **Firestore Enrichment**: Complete the enrichment logic to fetch reviews, identity tags, and Mama Approved status
5. **Error Handling**: Add comprehensive error handling for API failures
6. **Rate Limiting**: Consider rate limiting for API calls

## Next Steps

1. Copy the function code from `functions/searchProviders.js` into `functions/index.js`
2. Complete the implementation of helper functions (parseMedicaidResponse, extractName, etc.)
3. Add axios dependency to `functions/package.json`
4. Test the function locally using Firebase Emulator
5. Deploy using the command above

## Alternative: Keep Client-Side Processing

If you prefer to keep the API processing on the client side (current implementation), you can skip this Firebase function. The current Flutter implementation in `lib/services/provider_repository.dart` already handles all the API calls and processing.
