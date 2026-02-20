# Provider Search Implementation Notes

## Overview
This document describes the Provider Search feature implementation for EmpowerHealth, including API integration, data models, and UI components.

## Required Parameters

### Ohio Medicaid Provider Directory API
**Base URL:** `https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR`

**Required Query Parameters:**
- `state` (string): Fixed to "OH"
- `zip` (string): 5-digit ZIP code (required)
- `City` (string): City name (required)
- `healthplan` (string): Must match dropdown options exactly (required)
  - Valid options: Buckeye, CareSource, Molina, UnitedHealthcare, Anthem, Aetna
- `ProviderTypeIDsDelimited` (string): Comma-delimited provider type IDs (required, at least one)
- `radius` (numeric): Search radius in miles (required)
- `Program` (string): Always "1"

**Example Call:**
```
https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR?state=OH&zip=45202&healthplan=Buckeye&ProviderTypeIDsDelimited=09,01&radius=3&Program=1&City=Cincinnati
```

### NPI Registry API (Fallback)
**Base URL:** `https://npiregistry.cms.hhs.gov/api/`

**Query Parameters:**
- `version` (string): "2.1"
- `state` (string): "OH"
- `taxonomy_description` (string, optional): Specialty description
- `limit` (numeric, optional): Result limit (default: 50)

**Example Call:**
```
https://npiregistry.cms.hhs.gov/api/?version=2.1&taxonomy_description=Obstetrics&state=OH
```

## Provider Type Mapping

### How Provider Type Mapping Works
Provider types are mapped using a two-way lookup system:

1. **Display Name → ID**: When user selects a provider type from the UI, the display name is converted to its corresponding ID code using `ProviderTypes.getTypeId(displayName)`
2. **ID → Display Name**: When displaying provider types from API responses, IDs are converted to display names using `ProviderTypes.getDisplayName(typeId)`

### Provider Type Codes
The complete list of provider type codes and their display names is stored in `lib/constants/provider_types.dart` in the `ProviderTypes.typeMap`.

**MVP Priority Types:**
- `09` - Hospital
- `71` - Nurse Midwife Individual
- `11` - Free Standing Birth Center
- `01` - OB-GYN
- `50` - Doula
- `46` - Certified Nurse Midwife
- `44` - Nurse Practitioner

### How to Update Provider Type List
1. Open `lib/constants/provider_types.dart`
2. Add new entries to the `typeMap` constant:
   ```dart
   'XX': 'New Provider Type Name',
   ```
3. The reverse mapping (`displayToId`) is automatically generated
4. If adding MVP types, update the `mvpTypes` list

## Specialty Handling Strategy

### Current Implementation (MVP)
For MVP, specialty handling works as follows:

1. **UI Selection**: Users select specialties from a curated list (`Specialties.specialties` in `lib/constants/provider_types.dart`)
2. **Medicaid API**: Specialties are NOT sent to the Medicaid endpoint (no `SpecialtyTypeIDsDelimited` field available yet)
3. **Local Filtering**: Selected specialties are used to filter Medicaid results locally after receiving the response
4. **NPI API**: When NPI fallback is enabled, specialties are sent as `taxonomy_description` parameter

### Future Enhancement
When `SpecialtyTypeIDsDelimited` codes become available for the Medicaid API:

1. Create a specialty code mapping similar to provider types
2. Convert selected specialties to their corresponding IDs
3. Include `SpecialtyTypeIDsDelimited` in the Medicaid API request
4. Remove local filtering logic (API will handle it)

### Example: "OB/GYN" or "Obstetrics"
- **Current**: Used for NPI `taxonomy_description` and local filtering of Medicaid results
- **Future**: Will be converted to specialty ID code and sent to Medicaid API

## Data Models

### Provider Model (`lib/models/provider.dart`)
- Core provider information
- Locations (multiple addresses supported)
- Provider types (stored as IDs)
- Specialties (stored as display names)
- Identity tags with verification status
- Mama Approved status and count
- Source tracking (medicaid, npi, user_submission)

### ProviderLocation Model
- Address information
- Distance calculation (from search location)
- Phone number per location

### IdentityTag Model
- Tag name and category
- Verification status (pending, verified, disputed)
- Source (user_claim, verified, admin)
- Verification metadata

### ProviderReview Model (`lib/models/provider_review.dart`)
- Rating (1-5 stars)
- Review text
- Experience fields (felt heard, felt respected, explained clearly)
- Would recommend boolean
- Helpful count
- Verification status

## Firestore Collections

### `providers`
- Core provider data
- Enriched with identity tags, Mama Approved status, reviews

### `provider_locations`
- Location-specific data (subcollection or embedded)

### `identity_tags`
- Tag definitions and metadata

### `provider_identity_claims`
- User-submitted identity tag claims
- Verification workflow

### `reviews`
- Provider reviews
- Indexed by `providerId`

### `mama_approved_status`
- Mama Approved status per provider
- Approval criteria and counts

### `provider_submissions`
- Moderation queue for user-submitted providers
- Status: pending, approved, rejected

## Services

### OhioMedicaidDirectoryService (`lib/services/ohio_medicaid_directory_service.dart`)
- Handles Medicaid API calls
- Parses FHIR Bundle responses
- Converts FHIR resources to Provider models
- Applies local specialty filtering

### NpiRegistryService (`lib/services/npi_registry_service.dart`)
- Handles NPI Registry API calls
- Parses NPI JSON responses
- Converts NPI results to Provider models

### ProviderRepository (`lib/services/provider_repository.dart`)
- Combines results from multiple sources
- Enriches providers with Firestore data
- Handles caching and deduplication
- Manages provider submissions and favorites

## UI Screens

### ProviderSearchScreen (`lib/providers/provider_search_screen.dart`)
- Main landing page
- Category filters
- Quick filter chips
- Provider cards (mock data for now)

### ProviderSearchEntryScreen (`lib/providers/provider_search_entry_screen.dart`)
- Search form with all filters
- Location input (ZIP, city, radius)
- Health plan selection
- Provider type multi-select
- Specialty typeahead
- Advanced filters (collapsible)
- Validation before search

### ProviderSearchResultsScreen (`lib/providers/provider_search_results_screen.dart`)
- Displays search results
- Sort options
- Filter summary
- Provider cards with key info
- Empty state with "Add provider" CTA

### ProviderProfileScreen (`lib/providers/provider_profile_screen.dart`)
- Full provider details
- Contact information
- Identity tags with verification status
- Reviews and ratings
- Mama Approved explanation
- "Report incorrect info" action

### AddProviderScreen (`lib/providers/add_provider_screen.dart`)
- Form for user submissions
- Required fields validation
- Success screen
- Moderation notice

## Security & Validation

### Input Validation
- ZIP code: Exactly 5 digits
- Health plan: Must match allowed options
- Provider types: At least one required
- City: Required, non-empty
- Radius: Numeric, from dropdown

### API Error Handling
- 400 errors: Show friendly validation message
- Network errors: Retry option
- Zero results: Offer to broaden filters or use NPI fallback

### Firestore Security Rules
- Providers: Read by all authenticated users
- Reviews: Read by all, write by authenticated users (own reviews)
- Submissions: Write by authenticated users, read by admins only

## Future Enhancements

1. **Specialty Code Mapping**: When Medicaid API supports `SpecialtyTypeIDsDelimited`
2. **Distance Calculation**: Calculate actual distances from user location
3. **Caching**: Cache provider results to reduce API calls
4. **Favorites**: Save favorite providers per user
5. **Review System**: Full review submission and moderation
6. **Identity Tag Claims**: User-submitted identity tags with verification workflow
7. **Mama Approved Algorithm**: Automated calculation based on review criteria
8. **Provider Verification**: Admin tools for verifying provider information
