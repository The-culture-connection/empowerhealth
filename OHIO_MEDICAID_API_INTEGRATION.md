# Ohio Medicaid API Integration - Complete Parameter Support

## Overview
This document describes the complete integration of all Ohio Medicaid Provider Directory API parameters based on the [official API documentation](https://ohiomedicaidprovider.com/PublicSearchAPI.aspx#).

## API Endpoint
```
https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR
```

## Implemented Parameters

### Required Parameters (Already Implemented)
- ✅ `state` - Fixed to "OH"
- ✅ `zip` - 5-digit ZIP code
- ✅ `City` - City name (capital C)
- ✅ `healthplan` - Health plan name (lowercase)
- ✅ `ProviderTypeIDsDelimited` - Comma-delimited provider type IDs
- ✅ `radius` - Search radius in miles
- ✅ `Program` - Program code (defaults to "1")

### Newly Added Optional Parameters

#### Basic Filters
- ✅ `Program` - Program selection (defaults to "1")
- ✅ `FacilityType` - Facility type dropdown
- ✅ `PrimaryCareProviders` - Primary care provider filter
- ✅ `OrgName` - Provider name search (text input)
- ✅ `DMEProductsServices` - DME products/services filter
- ✅ `County` - Ohio county selection
- ✅ `Gender` - Provider gender filter
- ✅ `HospitalAffiliation` - Hospital affiliation filter

#### Patient Demographics
- ✅ `AcceptsPatientsAsYoungAs` - Minimum patient age
- ✅ `AcceptsPatientsAsOldAs` - Maximum patient age
- ✅ `AcceptsPatientsofGender` - Patient gender filter
- ✅ `AcceptsNewPatients` - Boolean (already implemented)
- ✅ `AcceptsNewborns` - Boolean (newly added)
- ✅ `AcceptsPregnantWomen` - Boolean (already implemented)

#### Specialized Services
- ✅ `Telehealth` - Boolean (already implemented)
- ✅ `CHIP` - Children's Health Insurance Program (newly added)
- ✅ `NewMedicaidPatients` - Accepts new Medicaid patients (newly added)

#### Multi-Select Filters
- ✅ `SpecialtyTypeIDsDelimited` - Specialty type IDs (comma-delimited)
- ✅ `LanguagesSpoken` - Languages spoken (comma-delimited, already implemented)
- ✅ `SpecializedTraining` - Specialized training (comma-delimited, newly added)
- ✅ `CulturalCompetencies` - Cultural competencies (comma-delimited, newly added)
- ✅ `ADAAccommodations` - ADA accommodations (comma-delimited, newly added)
- ✅ `BoardCertifications` - Board certifications (comma-delimited, newly added)

## Implementation Details

### Service Layer (`OhioMedicaidDirectoryService`)
- All parameters are optional except the core required ones
- Parameters are only added to the query if they have values
- Boolean parameters are converted to strings ("true"/"false")
- List parameters are joined with commas

### UI Layer (`ProviderSearchEntryScreen`)
- New fields added to the "Advanced Filters" section
- Multi-select fields use expandable chip selectors
- Single-select fields use dropdowns
- Boolean fields use toggle switches
- Text fields use standard text inputs

### Constants (`OhioMedicaidApiOptions`)
- Comprehensive lists for all dropdown options
- Based on API documentation
- Includes all Ohio counties
- Includes all languages, specialized training, cultural competencies, ADA accommodations, and board certifications

## Parameter Mapping

| UI Field | API Parameter | Type | Notes |
|----------|---------------|------|-------|
| Health Plan | `healthplan` | string | Required, lowercase |
| Program | `Program` | string | Capital P, defaults to "1" |
| Provider Types | `ProviderTypeIDsDelimited` | string | Comma-delimited IDs, required |
| Facility Type | `FacilityType` | string | Optional |
| Primary Care Providers | `PrimaryCareProviders` | string | Optional |
| Provider Name | `OrgName` | string | Optional, text search |
| DME Products/Services | `DMEProductsServices` | string | Optional |
| Patient Age (Min) | `AcceptsPatientsAsYoungAs` | string | Optional |
| Patient Age (Max) | `AcceptsPatientsAsOldAs` | string | Optional |
| Patient Gender | `AcceptsPatientsofGender` | string | Optional |
| Accepting New Patients | `AcceptsNewPatients` | bool | Optional |
| Accepts Newborns | `AcceptsNewborns` | bool | Optional |
| Accepts Pregnant Women | `AcceptsPregnantWomen` | bool | Optional |
| County | `County` | string | Optional |
| Specialties | `SpecialtyTypeIDsDelimited` | string | Optional, comma-delimited |
| Provider Gender | `Gender` | string | Optional |
| Hospital Affiliation | `HospitalAffiliation` | string | Optional |
| Languages Spoken | `LanguagesSpoken` | string | Optional, comma-delimited |
| Specialized Training | `SpecializedTraining` | string | Optional, comma-delimited |
| Cultural Competencies | `CulturalCompetencies` | string | Optional, comma-delimited |
| ADA Accommodations | `ADAAccommodations` | string | Optional, comma-delimited |
| Board Certifications | `BoardCertifications` | string | Optional, comma-delimited |
| Telehealth | `Telehealth` | bool | Optional |
| CHIP | `CHIP` | bool | Optional |
| New Medicaid Patients | `NewMedicaidPatients` | bool | Optional |

## Notes

1. **Parameter Casing**: The API is case-sensitive. Key parameters:
   - `City` (capital C)
   - `Program` (capital P)
   - `ProviderTypeIDsDelimited` (exact casing)
   - `healthplan` (lowercase)

2. **Boolean Parameters**: Converted to strings "true" or "false" when sent to API

3. **List Parameters**: Joined with commas (e.g., "English,Spanish,French")

4. **Optional Parameters**: Only included in query if they have values

5. **SpecialtyTypeIDsDelimited**: This is different from the specialty display names. The API expects MMIS PS Codes, not display names. Currently using specialty display names for local filtering only.

## Testing

To test with known-good parameters:
```dart
final service = OhioMedicaidDirectoryService();
final result = await service.runSanityCheck();
// This uses: state=OH, zip=45202, City=Cincinnati, healthplan=Buckeye, 
// ProviderTypeIDsDelimited=01,09, radius=15, Program=1
```

## Future Enhancements

1. Map specialty display names to MMIS PS Codes for `SpecialtyTypeIDsDelimited`
2. Add age range picker UI for `AcceptsPatientsAsYoungAs` and `AcceptsPatientsAsOldAs`
3. Add hospital affiliation search/autocomplete
4. Add DME products/services multi-select
5. Add patient gender multi-select
6. Add facility type multi-select
