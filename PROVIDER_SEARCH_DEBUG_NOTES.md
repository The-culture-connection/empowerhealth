# Provider Search Debug Notes

## Issue: Missing "entry" Field in Ohio Medicaid API Response

### Problem
The Ohio Medicaid API is returning FHIR Bundles with only:
```json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "link": [{"relation": "self", "url": "..."}]
}
```
And no `"entry"` field.

### Root Cause
This indicates **zero results** for the search query. The API returns a valid FHIR Bundle structure, but when there are no matching providers, the `entry` field is either:
1. Missing entirely
2. An empty array `[]`

This is **not an error condition** - it's a valid response meaning "no providers found matching your criteria."

### Solution Implemented
- Added robust checking for `entry` field existence
- If `entry` is missing or empty, return empty list `[]` instead of throwing an error
- Added detailed logging to show when this occurs
- User sees friendly empty state instead of error message

### Parameter Verification
Based on the working example:
```
state=OH&zip=45202&healthplan=Buckeye&ProviderTypeIDsDelimited=09,01&radius=3&Program=1&City=Cincinnati
```

**Confirmed parameter names and casing:**
- `state` - lowercase
- `zip` - lowercase  
- `City` - **Capital C** (case-sensitive!)
- `healthplan` - lowercase (one word)
- `ProviderTypeIDsDelimited` - **Exact casing** (capital P, T, I, D)
- `radius` - lowercase
- `Program` - **Capital P**

All parameters are now built using this exact casing.

## Issue: NPI Registry taxonomy_description Error

### Problem
NPI Registry API returns:
```json
{
  "Errors": [{
    "description": "No taxonomy codes found with entered description",
    "field": "taxonomy_description",
    "number": "14"
  }]
}
```
When we send `taxonomy_description=OB-GYN`.

### Root Cause
The NPI Registry API does not accept free-form specialty descriptions. It requires:
1. **Exact taxonomy codes** (e.g., `207V00000X` for Obstetrics & Gynecology)
2. OR validated taxonomy descriptions that match their internal list exactly

We were sending `OB-GYN` which is not in their taxonomy description list.

### Solution Implemented
- **Switched to `taxonomy_code` parameter** instead of `taxonomy_description`
- Created `NpiTaxonomyCodes` mapping class with specialty → taxonomy code mappings:
  - `OB-GYN` / `Obstetrics` → `207V00000X` (Obstetrics & Gynecology)
  - `Certified Nurse Midwife` → `367A00000X` (Advanced Practice Midwife)
  - `Women's Health Nurse Practitioner` → `363LW0102X`
  - `Maternal-Fetal Medicine` → `207VM0101X`
  - And more...
- If specialty cannot be mapped, skip NPI search and return empty list
- **Doulas are NOT in NPI taxonomy** - they must come from Medicaid directory or user submissions

### Example NPI Query
```
https://npiregistry.cms.hhs.gov/api/?version=2.1&state=OH&limit=50&taxonomy_code=207V00000X
```

## Provider Type ID Mapping

### Issue: Leading Zeros
Provider type IDs must preserve leading zeros:
- `"09"` not `"9"` for Hospital
- `"01"` not `"1"` for OB-GYN

### Solution
- Added validation in `ProviderRepository` to ensure leading zeros are preserved
- `ProviderTypes.getTypeId()` already returns correct codes with leading zeros
- Added logging to show selected provider types and resulting IDs

### Common Provider Type Codes for Maternal Searches
- `01` - OB-GYN
- `09` - Hospital
- `11` - Free Standing Birth Center
- `19` - Osteopathic Physician (can provide OB care)
- `20` - Birth Doula
- `46` - Certified Nurse Midwife
- `50` - Doula
- `71` - Nurse Midwife Individual
- `44` - Nurse Practitioner

## Search Defaults and Recommendations

### When NPI Fallback is Enabled
If user selects "OB-GYN" specialty and includes NPI fallback:
- Provider type IDs should include physician types (`01`, `19`) if not already selected
- This ensures both Medicaid and NPI searches return relevant results

### Provider Type Validation
- Added recommendation logic: if user selects specialty like "OB-GYN" but provider types don't include physician types, show a helpful banner
- This prevents empty results due to mismatched filters

## Parsing Improvements

### FHIR Bundle Parser
- Safely handles missing `entry` field
- Handles entries with missing `resource` field
- Handles resources with missing required fields (name, address, etc.)
- Continues parsing other entries if one fails
- Detailed logging for each parsing step

### NPI Response Parser
- Checks for `Errors` array in response
- Handles missing `results` field
- Safely extracts name, address, phone, specialties
- Handles both individual and organization providers

## Empty State Handling

### User Experience
- Empty results (0 providers) is **not an error**
- Show friendly empty state with:
  - Message: "No providers found"
  - Suggestion: "Try adjusting your filters or search in a different area"
  - CTA: "Add a provider" button
- Only show error state for actual API failures (network errors, 400/500 status codes)

## Debugging Output

All services now include detailed logging with prefixes:
- `[OhioMedicaid]` - Ohio Medicaid Directory Service logs
- `[NPI]` - NPI Registry Service logs
- `[ProviderRepository]` - Provider Repository logs

Each log includes:
- Request parameters
- Response status and structure
- Parsing progress
- Error details with stack traces

## Testing Checklist

1. ✅ Empty results (missing entry field) - handled gracefully
2. ✅ Invalid specialty for NPI - skipped with message
3. ✅ Doula specialty - NPI search skipped (not in taxonomy)
4. ✅ Provider type ID leading zeros - preserved
5. ✅ Parameter casing - matches working example exactly
6. ✅ Error responses - logged and handled
7. ✅ Partial parsing failures - continue with other results

## Common Issues and Solutions

### Issue: "No providers found" when providers should exist
**Check:**
1. Provider type IDs match exactly (including leading zeros)
2. City name matches exactly (case-sensitive)
3. Health plan name matches dropdown options exactly
4. ZIP code is 5 digits
5. Radius is reasonable (try increasing)

### Issue: NPI search returns no results
**Check:**
1. Specialty is mappable to taxonomy code (see `NpiTaxonomyCodes`)
2. Specialty is not "Doula" (not in NPI taxonomy)
3. State is "OH" (NPI search is state-specific)

### Issue: API returns 400 Bad Request
**Check:**
1. All required parameters are present
2. Parameter names match exactly (case-sensitive)
3. Provider type IDs are valid (numeric strings)
4. ZIP code is exactly 5 digits
