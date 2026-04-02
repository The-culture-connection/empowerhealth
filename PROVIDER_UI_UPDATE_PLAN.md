# Provider Search UI Update Plan

## Completed
1. ✅ Removed mock providers from `provider_search_screen.dart`
2. ✅ Changed default sort to "Highest rated"
3. ✅ Updated rating display to show no stars when rating is null (not grayed out)

## In Progress / Remaining Tasks

### 1. Provider Search Results Screen (`provider_search_results_screen.dart`)
- [x] Default sort to "Highest rated"
- [x] Show no stars when no ratings (not grayed out)
- [ ] Match NewUI design exactly:
  - [ ] Update card layout to match NewUI ProviderSearchResults.tsx
  - [ ] Add bookmark/save functionality
  - [ ] Update filter chips styling
  - [ ] Add "Review" button to cards
  - [ ] Only show fields that have data (conditional rendering)

### 2. Provider Profile Screen (`provider_profile_screen.dart`)
- [ ] Match NewUI ProviderDetailProfile.tsx exactly:
  - [ ] Add tab navigation (Overview, Reviews, About)
  - [ ] Update hero card design
  - [ ] Add quick action buttons (Call, Book, Message)
  - [ ] Update contact info section
  - [ ] Add office hours section (if available)
  - [ ] Update identity tags section
  - [ ] Add experience ratings summary (if available)
  - [ ] Update specialties section
  - [ ] Add languages section (if available)
  - [ ] Add insurance section (if available)
  - [ ] Update reviews section with reply functionality
  - [ ] Add education & training section (if available)
  - [ ] Add certifications section (if available)
  - [ ] Add clinical interests section (if available)
  - [ ] Add hospital affiliations section (if available)
  - [ ] Add awards section (if available)
  - [ ] Only show sections that have data

### 3. Review Functionality
- [ ] Create review submission screen
- [ ] Store only endpoint ID (provider's API endpoint ID) when submitting review
- [ ] Add reply functionality to reviews
- [ ] Update review model to support replies
- [ ] Add review submission to Firestore with endpoint ID

### 4. Conditional Rendering
- [ ] Only show rating stars when rating exists and > 0
- [ ] Only show review count when > 0
- [ ] Only show sections that have data
- [ ] Hide empty fields gracefully

## Notes
- "Endpoint ID" refers to the provider's unique identifier from the API (Medicaid or NPI), not the Firestore document ID
- All UI should match NewUI design exactly
- No mock data should remain
- Default sort is "Highest rated"
