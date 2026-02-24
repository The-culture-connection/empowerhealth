# BIPOC Provider Import Instructions

This guide explains how to import BIPOC providers from the Excel file into your Firestore database.

## Overview

The import process will:
1. Read the "BIPOC Provider Directory.xlsx" file
2. Parse provider information (name, specialty, NPI, location, contact info, etc.)
3. Add each provider to Firestore with a "BIPOC" identity tag
4. If a provider already exists (matched by NPI or name), it will update the existing record to add the BIPOC tag

## Prerequisites

1. Install the required npm package:
   ```bash
   cd functions
   npm install
   ```

2. Ensure you have Firebase Admin credentials set up. The script will try to use:
   - A `serviceAccountKey.json` file in the project root (if available)
   - Default Firebase credentials (if running in Firebase Functions environment)

## IMPORTANT: Upload Excel File to Firebase Storage First

Before BIPOC providers can appear in search results, you need to upload the Excel file to Firebase Storage:

1. Navigate to the functions directory:
   ```bash
   cd functions
   ```

2. Run the upload script:
   ```bash
   node uploadBipocExcelToStorage.js
   ```

This will upload the Excel file to Firebase Storage at `bipoc-directory/BIPOC Provider Directory.xlsx`, making it accessible to the search function.

## Method 1: Run the Import Script Locally

1. Navigate to the functions directory:
   ```bash
   cd functions
   ```

2. Run the import script:
   ```bash
   node importBipocProviders.js "C:\Users\grace\EmpowerHealth\BIPOC Provider Directory.xlsx"
   ```
   
   Or if the Excel file is in the project root:
   ```bash
   node importBipocProviders.js "../BIPOC Provider Directory.xlsx"
   ```

3. The script will:
   - Read and parse the Excel file
   - Display the headers found
   - Show progress as it imports/updates each provider
   - Display a summary at the end

## Method 2: Use Firebase Function (Recommended for Production)

1. Upload the Excel file to Firebase Storage (optional, if using storagePath)

2. Call the Firebase function from your app or via HTTP:
   ```javascript
   // From your app
   const functions = getFunctions();
   const importFunction = httpsCallable(functions, 'importBipocProviders');
   
   await importFunction({
     filePath: "path/to/BIPOC Provider Directory.xlsx", // Local path
     // OR
     storagePath: "bipoc-directory/BIPOC Provider Directory.xlsx" // Firebase Storage path
   });
   ```

## Excel File Format

The script automatically detects common column name variations. It looks for:

- **Name**: "name", "provider name", "provider", "full name"
- **Practice Name**: "practice", "practice name", "organization", "clinic"
- **Specialty**: "specialty", "specialties", "type", "provider type"
- **NPI**: "npi", "national provider identifier"
- **Phone**: "phone", "telephone", "phone number", "contact"
- **Email**: "email", "e-mail", "email address"
- **Website**: "website", "url", "web"
- **Address**: "address", "street", "street address"
- **City**: "city"
- **State**: "state" (defaults to "OH" if not found)
- **ZIP**: "zip", "zipcode", "zip code", "postal code"

## What Gets Imported

Each provider will have:
- All available information from the Excel file
- A **BIPOC identity tag** with:
  - `id`: "bipoc"
  - `name`: "BIPOC"
  - `category`: "identity"
  - `source`: "admin"
  - `verificationStatus`: "verified"
- `source`: "bipoc_directory"

## Matching Existing Providers

The script matches existing providers by:
1. **NPI** (if available) - exact match
2. **Name + Practice Name** (if practice name is available)
3. **Name only** (if no practice name)

If a match is found:
- The BIPOC tag is added (if not already present)
- Missing information is updated (practice name, specialty, phone, email, website)
- New locations are merged with existing ones

## Verification

After importing, you can verify the providers in Firebase Console:
1. Go to Firestore Database
2. Open the "providers" collection
3. Check that providers have `identityTags` array containing a BIPOC tag
4. Search for providers - they should now show the BIPOC tag in search results

## Troubleshooting

### "Headers found: []" or empty data
- Check that your Excel file has headers in the first row
- Ensure the file is not empty
- Try opening the file in Excel and saving it again

### "Failed to initialize Firebase Admin"
- Ensure you have Firebase credentials set up
- For local runs, you may need a `serviceAccountKey.json` file
- For Firebase Functions, ensure you're authenticated

### Providers not showing BIPOC tag in search
- The tag should appear automatically via the `enrichProvidersWithFirestore` function
- Check that the provider was successfully imported to Firestore
- Verify the identityTags array contains the BIPOC tag

## Notes

- The script is case-insensitive when matching column names
- Phone numbers are automatically formatted to (XXX) XXX-XXXX
- ZIP codes are truncated to 5 digits
- Addresses are parsed automatically, but complex formats may need manual adjustment
- The script processes providers one at a time to avoid overwhelming Firestore
