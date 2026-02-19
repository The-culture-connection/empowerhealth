# HIPAA-Aligned Privacy & Security Implementation Notes

**Document Version**: 1.0  
**Last Updated**: February 2026  
**Project**: EmpowerHealth Maternal Health App

---

## Overview

This document outlines the HIPAA-aligned privacy and security measures implemented in the EmpowerHealth app. These measures are designed to protect Protected Health Information (PHI) while maintaining a warm, user-friendly experience.

---

## What Was Implemented

### 1. Privacy & Trust UX Layer

#### A1. First-Run Consent Screen (`lib/privacy/privacy_consent_screen.dart`)
- **Location**: Shown after signup, accessible from Settings
- **Features**:
  - Clear explanation of data storage
  - AI use disclosure with separate toggle
  - Terms of Service and Privacy Policy acceptance
  - Emergency disclaimer
  - Warm, non-clinical tone
- **Storage**: Consent timestamps stored in `users/{userId}/consents`

#### A2. Privacy Center (`lib/privacy/privacy_center_screen.dart`)
- **Location**: Accessible from Profile/Settings
- **Features**:
  - AI features toggle (on/off)
  - Research data sharing toggle (opt-in, default: off)
  - Save original documents toggle (default: off for privacy)
  - Data export functionality
  - Account deletion with double confirmation
  - Links to Privacy Policy and Terms
  - Community posting privacy note
  - Support and report concern links

#### A3. Inline Disclaimers
- **AI Assistant**: Banner disclaimer on all AI assistant screens
- **Visit Summary Upload**: Disclaimer banner explaining educational support
- **Learning Modules**: Disclaimers in generation dialogs
- **Birth Plan**: Disclaimers in AI-generated content

**Disclaimer Text Style**:
> "This provides educational support and is not medical advice. Always consult your healthcare provider for medical decisions."

---

### 2. PHI-Safe Appointment Summarization

#### B1. Manual Text Input Pathway
- **Location**: `lib/appointments/upload_visit_summary_screen.dart`
- **Features**:
  - Segmented choice: Upload PDF vs. Type Notes
  - Multi-line text input for manual entry
  - "Save my original text" toggle (default: off)
  - Privacy recommendation banner
- **Backend**: New Cloud Function `analyzeVisitSummaryText` handles manual text analysis

#### B2. Data Minimization Defaults
- **Default Behavior**: 
  - Raw PDF text extraction NOT stored in Firestore
  - Raw user-entered text NOT stored unless user opts in
  - Only structured summary JSON, learning tasks, and metadata stored
- **User Control**: Toggle to save original documents (off by default)

#### B3. PHI Redaction Before AI Processing
- **Location**: `functions/index.js` - `redactPHI()` function
- **Redacts**:
  - Email addresses
  - Phone numbers (US format)
  - SSN patterns
  - Medical Record Numbers (MRN)
  - Street addresses
- **Warning**: User notified if redaction flags potential PHI
- **Storage**: Redaction flags stored in visit summary metadata

---

### 3. Security Hardening

#### C1. Firestore Security Rules (`firestore.rules`)
**Strict User Isolation**:
- `users/{userId}`: Only accessible by owner
- `users/{userId}/visit_summaries`: Strict user isolation
- `users/{userId}/notes`: Strict user isolation
- `users/{userId}/learning_tasks`: Strict user isolation
- `users/{userId}/file_uploads`: Strict user isolation
- `birth_plans`: User-scoped with userId validation
- `learning_tasks`: User-scoped with userId validation
- `visit_summaries` (top-level): User-scoped (deprecated, prefer subcollection)

**Community Posts**:
- Public read (authenticated users)
- Strict write controls (userId validation)
- Non-owners can only update likes/replies arrays
- Field length validation (title ≤ 200, content ≤ 5000)

**Post Reports**:
- Users can create reports
- Users can read own reports
- Admins can read all reports (future role-based access)

#### C2. Firebase Storage Rules (`storage.rules`)
- **Path**: `visit_summaries/{userId}/{allPaths=**}`
- **Read**: Only by owner (userId match)
- **Write**: Only by owner with validation:
  - File type: PDF only
  - File size: 10MB maximum
- **Default**: Deny all other paths

#### C3. Cloud Functions Security
**Authentication**:
- All callable functions require `request.auth`
- User ID extracted from auth token
- No public access

**Input Validation**:
- Strict schema validation on all parameters
- Type checking (string, number, array)
- Length limits (content ≤ 5000, title ≤ 200)
- Required field validation

**Safe Logging**:
- `safeLog()` utility function strips PHI from logs
- Removes: text, pdfText, originalText, visitNotes, content, summary, userProfile, email, phone, address, MRN
- All sensitive operations use safeLog instead of console.log

**Rate Limiting** (Recommended):
- Consider implementing per-user daily limits for AI analysis
- Example: Max 5 visit summary analyses per user per day
- Not yet implemented (requires additional infrastructure)

#### C4. Key Management
- OpenAI API key stored in Firebase Secrets Manager
- Never exposed to client-side code
- Functions access via `defineSecret("OPENAI_API_KEY")`
- **Action Required**: Add repository scanning to prevent key leakage in commits

---

### 4. Data Export & Deletion

#### Export Function (`exportUserData`)
- **Location**: `functions/index.js`
- **Exports**:
  - User profile (sanitized)
  - Visit summaries
  - Learning tasks
  - Journal entries (notes)
  - Birth plans
  - File upload metadata
- **Format**: JSON bundle
- **Access**: User-initiated from Privacy Center

#### Delete Function (`deleteUserAccount`)
- **Location**: `functions/index.js`
- **Deletes**:
  - Firestore documents (user profile, subcollections)
  - Storage files (PDFs)
  - Firebase Auth user account
- **Process**: Recursive cleanup with batch operations
- **Confirmation**: Double confirmation required in UI

---

### 5. Consent Management

#### Consent Tracking
- **Storage**: `users/{userId}/consents`
- **Fields**:
  - `termsAccepted`: boolean
  - `privacyAccepted`: boolean
  - `aiUseAccepted`: boolean
  - `termsVersion`: string (for re-consent on updates)
  - `privacyVersion`: string
  - `acceptedAt`: Timestamp
  - `lastUpdatedAt`: Timestamp

#### Re-Consent Flow
- **Trigger**: When Terms or Privacy Policy version changes
- **Implementation**: Check version on app launch
- **Status**: Not yet implemented (requires version tracking system)

---

## What Still Requires Legal/Policy Work

### 1. Business Associate Agreement (BAA)
- **Status**: Required
- **Action**: Execute BAA with:
  - Firebase/Google Cloud (if storing PHI)
  - OpenAI (if processing PHI)
  - Any other third-party services handling PHI

### 2. Privacy Policy & Terms of Service
- **Status**: Placeholder links exist
- **Action**: 
  - Draft comprehensive Privacy Policy
  - Draft Terms of Service
  - Include HIPAA Notice of Privacy Practices
  - Link from Privacy Center and first-run consent

### 3. Incident Response Plan
- **Status**: Not implemented
- **Action**: Create documented plan for:
  - Data breach detection
  - Notification procedures (users, HHS if required)
  - Containment and remediation
  - Post-incident review

### 4. Staff Training
- **Status**: Not applicable (development team)
- **Action**: If hiring support/admin staff:
  - HIPAA training
  - PHI handling procedures
  - Security awareness

### 5. Audit Logging
- **Status**: Partial (Firebase Functions logs)
- **Action**: Implement comprehensive audit trail:
  - User access logs
  - Data modification logs
  - Admin action logs
  - Retention policy (6 years recommended)

### 6. Encryption at Rest
- **Status**: Handled by Firebase (default encryption)
- **Action**: Verify Firebase encryption settings meet requirements

### 7. Encryption in Transit
- **Status**: Handled by Firebase (HTTPS/TLS)
- **Action**: Verify all API calls use HTTPS

### 8. Access Controls
- **Status**: Basic (Firestore rules)
- **Action**: Consider implementing:
  - Role-based access control (admin, support, research)
  - Custom claims for user roles
  - Admin dashboard with access logging

### 9. Data Retention Policy
- **Status**: Not defined
- **Action**: Define and implement:
  - How long to retain user data
  - Automatic deletion of inactive accounts
  - Archive vs. delete procedures

### 10. Research Data Sharing
- **Status**: Opt-in toggle exists
- **Action**: 
  - Implement anonymization process
  - Create data sharing agreement template
  - Establish IRB approval process (if applicable)

---

## Technical Implementation Details

### Safe Logging Utility
```javascript
function safeLog(level, message, data = {}) {
  const sanitized = { ...data };
  // Remove PHI fields
  delete sanitized.text;
  delete sanitized.pdfText;
  // ... (see functions/index.js for full list)
  console[level](message, sanitized);
}
```

### PHI Redaction Function
```javascript
function redactPHI(text) {
  // Redacts emails, phones, SSNs, MRNs, addresses
  // Returns: { redactedText, redactionFlags, confidence }
}
```

### Security Rules Pattern
```javascript
// User isolation pattern
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId && 
                 request.resource.data.userId == request.auth.uid;
}
```

---

## Testing Recommendations

### Security Rules Testing
1. **User Isolation**: Verify users cannot access other users' data
2. **Community Posts**: Verify public read, restricted write
3. **Storage**: Verify users can only access own files

### Redaction Testing
1. Test with sample visit summaries containing PHI
2. Verify redaction flags are set correctly
3. Verify redacted text is sent to OpenAI (not original)

### Export/Delete Testing
1. Export user data and verify completeness
2. Delete account and verify all data removed
3. Verify Storage files are deleted

### Consent Flow Testing
1. Verify first-run consent blocks app access
2. Verify consent can be updated from Settings
3. Test re-consent flow (when implemented)

---

## Compliance Checklist

- [x] First-run consent screen
- [x] Privacy Center UI
- [x] Manual text input for visit summaries
- [x] PHI redaction before AI processing
- [x] Safe logging (no PHI in logs)
- [x] Strict Firestore security rules
- [x] Strict Storage security rules
- [x] Data export function
- [x] Account deletion function
- [x] Inline disclaimers in AI features
- [x] User control toggles (AI, research, save originals)
- [ ] Privacy Policy (draft required)
- [ ] Terms of Service (draft required)
- [ ] BAA with service providers (execute)
- [ ] Incident response plan (create)
- [ ] Audit logging system (implement)
- [ ] Rate limiting (implement)
- [ ] Re-consent flow (implement version tracking)

---

## Notes for Legal/Compliance Team

1. **HIPAA Applicability**: This app handles maternal health data, which may include PHI. Even if not a "covered entity" under HIPAA, implementing HIPAA-aligned practices demonstrates commitment to privacy.

2. **OpenAI & PHI**: The app sends visit summary text to OpenAI for analysis. Consider:
   - BAA with OpenAI (if available)
   - Alternative: Use OpenAI's Business Associate Agreement option
   - Or: Implement additional redaction/encryption before sending

3. **User Consent**: Users explicitly consent to:
   - Data storage
   - AI processing
   - Research data sharing (opt-in)

4. **Data Minimization**: Default behavior minimizes PHI storage:
   - Original documents not saved by default
   - Only structured summaries stored
   - User can opt-in to save originals

5. **Emergency Disclaimer**: All AI features include clear disclaimers that this is educational support, not medical advice, and users should call 911 for emergencies.

---

## Future Enhancements

1. **Role-Based Access Control**: Implement admin/research roles with custom claims
2. **Audit Logging**: Comprehensive access and modification logs
3. **Rate Limiting**: Per-user daily limits for AI analysis
4. **Re-Consent System**: Automatic prompts when Terms/Privacy Policy update
5. **Data Anonymization**: Automated process for research data sharing
6. **Encryption**: Additional client-side encryption for sensitive fields (if needed)
7. **Backup & Recovery**: Documented backup procedures and recovery testing

---

## Contact

For questions about this implementation, contact the development team.

**Last Review**: February 2026  
**Next Review**: Quarterly or when major changes are made
