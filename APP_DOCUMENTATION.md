# EmpowerHealth App - Comprehensive Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Authentication & User Management](#authentication--user-management)
4. [Core Features](#core-features)
5. [Detailed Feature Descriptions](#detailed-feature-descriptions)
6. [Data Models & Storage](#data-models--storage)
7. [AI Integration](#ai-integration)
8. [Provider Search Feature](#provider-search-feature)
9. [Navigation & User Flow](#navigation--user-flow)
10. [Firebase Functions](#firebase-functions)

---

## Overview

EmpowerHealth is a comprehensive maternal health mobile application designed to empower expectant mothers, particularly those from marginalized communities, with tools for healthcare advocacy, education, and support. The app provides culturally sensitive, trauma-informed resources to help users navigate their pregnancy journey with confidence and knowledge.

### Key Objectives
- **Health Literacy**: Provide accessible, plain-language explanations of medical information
- **Advocacy Support**: Help users understand and exercise their patient rights
- **Personalized Care**: Generate customized birth plans and learning modules based on user profiles
- **Community Support**: Facilitate peer-to-peer support and information sharing
- **Provider Matching**: Help users find culturally competent healthcare providers

---

## Architecture & Technology Stack

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: StatefulWidget, StreamBuilder
- **UI Components**: Material Design
- **Real-time Data**: Cloud Firestore streams

### Backend
- **Backend Services**: Firebase
  - **Authentication**: Firebase Auth
  - **Database**: Cloud Firestore
  - **Storage**: Firebase Storage (for PDF uploads)
  - **Functions**: Firebase Cloud Functions (Node.js)
  - **AI Integration**: OpenAI GPT-4 API

### Key Libraries
- `cloud_firestore`: Real-time database operations
- `firebase_auth`: User authentication
- `firebase_storage`: File storage
- `firebase_functions`: Cloud function calls
- `flutter_markdown`: Markdown rendering for content
- `syncfusion_flutter_pdf`: PDF text extraction
- `file_picker`: File selection
- `intl`: Date/time formatting

---

## Authentication & User Management

### Authentication Flow
1. **Initial Launch**: App checks authentication state
2. **Unauthenticated Users**: Redirected to `AuthScreen` with login/signup options
3. **New Users**: 
   - Sign up via `SignUpScreen`
   - Complete profile creation via `ProfileCreationScreen`
   - Accept terms and conditions
4. **Returning Users**: 
   - Login via `LoginScreen`
   - Automatic profile check
   - Redirect to main app if profile exists

### User Profile
Stored in Firestore collection: `users/{userId}`
- Basic information (name, email, due date)
- Pregnancy stage/trimester
- Health information (allergies, conditions, complications)
- Preferences (birth preferences, learning style, cultural preferences)
- Education level (for personalized content)

### Profile Creation Steps
1. Basic Information (name, due date, pregnancy stage)
2. Health Information (allergies, medical conditions, complications)
3. Preferences (birth preferences, cultural considerations)
4. Learning Style & Goals

---

## Core Features

### 1. Home Screen (`HomeScreenV2`)
The main dashboard providing:
- Personalized greeting with time-based messages
- Quick access widgets:
  - **Active Learning Modules**: Displays 2 most recent active learning modules
  - **Recent Appointment Analysis**: Shows most recent visit summary
  - **Quick Tools**: 
    - Generate Learning Modules
    - Upload Visit Summary
    - After Visit Summary (links to appointments list)
- Search bar (navigates to Provider Search)
- Navigation to all major features

### 2. Learning Center (`LearningModulesScreenV2`)
Comprehensive learning and task management system.

#### Filtering Options
- **All**: Shows all active items (todos and learning modules)
- **Todos**: Shows only todo items (from birth plans or visit summaries)
- **Learning Modules**: Shows only educational content modules
- **Archived**: Shows completed/archived items

#### Item Types

**Learning Modules**:
- AI-generated educational content
- Generated from visit summaries
- Personalized based on user profile
- Rich markdown content with structured sections
- Can be marked as complete and archived

**Todos**:
- Action items from birth plans
- Follow-up tasks from visit summaries
- Advocacy reminders
- Medication/test reminders
- Can be checked off to mark complete and archive

#### Features
- Real-time updates via Firestore streams
- Checkbox to mark items as done (auto-archives)
- Visual differentiation:
  - Birth Plan Todos: Orange color scheme with checklist icon
  - Regular Todos: Blue color scheme with task icon
  - Learning Modules: Purple/blue gradient with book icon
- Detail view for learning modules with full content
- Archive management

### 3. Birth Plan (`ComprehensiveBirthPlanScreen`)
Comprehensive birth planning tool with multiple sections:

#### Section 1: Parent Information
- Support person details (name, relationship, contact)
- Emergency contact information
- Allergies, medical conditions, pregnancy complications
- Due date

#### Section 2: Environment Preferences
- Lighting preferences (dim, bright)
- Noise preferences (quiet, music, affirmations)
- Visitor policies
- Photography/videography permissions
- Preferred language
- Trauma-informed care requests

#### Section 3: Labor Preferences
- Preferred labor positions
- Movement freedom preferences
- Monitoring preferences (intermittent, continuous, wireless)
- Pain management preferences
- Natural comfort measures
- IV fluids preference
- Doula usage
- Water labor availability
- Communication style preferences

#### Section 4: Medical Interventions
- Induction methods preferences
- Augmentation preferences (Pitocin, membrane sweep)
- Vaginal exams preferences
- Membrane rupture preferences
- Episiotomy preferences
- Vacuum/forceps preferences

#### Section 5: Pushing Preferences
- Preferred pushing positions
- Pushing style preferences
- Mirror during pushing
- Episiotomy preferences
- Tearing preferences
- Who catches baby
- Delayed pushing with epidural

#### Section 6: Newborn Care
- Delayed cord clamping preferences
- Who cuts cord
- Immediate skin-to-skin
- Baby stays with parent
- Vitamin K, eye ointment, Hep B vaccine preferences
- Cord blood banking

#### Section 7: Feeding
- Feeding preference (breastfeeding, formula, combination)
- Lactation consultant requests
- Rooming-in preferences

#### Section 8: Postpartum
- Postpartum pain management
- Postpartum support preferences

#### Birth Plan Features
- Comprehensive form with validation
- Auto-generates todos based on preferences
- Saves to Firestore collection: `birth_plans`
- Displays formatted birth plan document
- Can be shared with providers

### 4. Appointments & Visit Summaries

#### Upload Visit Summary (`UploadVisitSummaryScreen`)
- **PDF Upload**: Users can upload visit summary PDFs
- **Date Selection**: Select appointment date
- **AI Analysis**: PDF is analyzed using OpenAI GPT-4
- **Storage**: PDF stored in Firebase Storage
- **Processing**: 
  - PDF text extraction
  - AI analysis for:
    - Summary generation
    - Learning module creation
    - Todo generation
    - Medical term explanations
    - Next steps identification
    - Advocacy tips

#### Visit Summary Analysis Features
- **Structured Summary**: 
  - How baby is doing
  - How you are doing
  - Key medical terms (with explanations)
  - Next steps
  - Questions to ask
  - Empowerment tips
  - New diagnoses
  - Tests/procedures
  - Medications
  - Follow-up instructions
- **Learning Modules**: Auto-generated educational content
- **Todos**: Action items (medications, tests, follow-ups)
- **Red Flags**: Identifies potential mistreatment or unclear communication

#### Appointments List (`AppointmentsListScreen`)
- Displays all past visit summaries
- Chronological listing
- Click to view full summary
- Duplicate prevention (client-side filtering)
- Formatted display with markdown support

### 5. Journal (`JournalScreen`)
Personal journaling feature for thoughts and feelings.

#### Features
- **Text Entry**: Free-form text input for journal entries
- **Emoji Feelings**: Click emojis to save as "Feelings" entries
- **Prompts**: Pre-written prompts to help users reflect:
  - "How are you feeling today?"
  - "What questions do you have for your provider?"
  - "What are you grateful for?"
  - "What concerns you?"
- **Prompt Expansion**: Long-press prompts to expand in dialog
- **Notes from Learning Modules**: Can save highlighted text from learning modules as journal entries
- **Tagging**: Entries can be tagged (e.g., "Question for provider", "Update birth plan", "Track a symptom")
- **Storage**: Saved to `users/{userId}/notes` collection
- **Real-time Display**: Shows recent entries with timestamps

### 6. Community (`CommunityScreen`)
Peer-to-peer support and information sharing platform.

#### Features
- **Post Categories**:
  - All
  - Questions
  - Birth Stories
  - Support
  - Resources
- **Create Posts**: Users can create posts with:
  - Title
  - Content
  - Category selection
- **View Posts**: 
  - List view with author, replies count, time ago
  - Click to view full post details
- **Post Interactions** (`PostDetailScreen`):
  - **Like**: Toggle likes, shows count
  - **Reply**: Add replies to posts
  - **Report**: Report inappropriate content (saved to `post_reports` collection)
- **Real-time Updates**: Uses Firestore streams for live updates
- **Mock Data**: Seeded with initial posts if collection is empty

### 7. AI Assistant (`AssistantScreen`)
AI-powered chat assistant for maternal health questions.

#### Features
- **Chat Interface**: Clean, modern chat UI
- **OpenAI Integration**: Uses GPT-4 via Firebase Functions
- **Context-Aware**: Configured as maternal health assistant
- **Capabilities**:
  - Answer questions about pregnancy
  - Explain medical terms
  - Provide information about patient rights
  - Offer healthcare advocacy guidance
  - Culturally sensitive responses
  - 6th-8th grade reading level
- **Message History**: Maintains conversation history during session
- **Loading States**: Shows loading indicator while processing

### 8. Provider Search (`ProviderSearchScreen`)
Healthcare provider search and discovery feature.

#### Features
- **Hero Header**: Gradient background with search bar
- **Category Filters**: Horizontal scrollable pills
  - All Providers
  - OB-GYNs
  - Midwives
  - Doulas
- **Quick Filters**:
  - Near me
  - Accepting patients
  - Background match (toggle)
  - Black Mama Approved
- **Provider Cards**: Detailed provider information including:
  - Avatar/photo
  - Name and specialty
  - Practice name
  - Acceptance status
  - Black Mama Approved tag
  - Rating and review count
  - Distance
  - Phone number
  - Hours
  - Languages spoken
  - Specialties
  - Featured review
- **Community Trust Badge**: Special badge for trusted providers
- **Mock Data**: Currently uses mock provider data (ready for backend integration)

---

## Detailed Feature Descriptions

### Learning Module Generation
**Location**: Home Screen → Generate Learning Modules

**Process**:
1. User clicks "Generate Learning Modules" button
2. System checks if user profile is complete
3. Dialog shows generation progress
4. Firebase Function called with user profile data
5. AI generates personalized learning modules based on:
   - Pregnancy stage/trimester
   - Health conditions
   - Birth preferences
   - Cultural preferences
   - Learning style
6. Modules saved to Firestore
7. User notified of completion

**Module Content Structure**:
- Title
- Description
- Detailed content (markdown format)
- Sections:
  - What This Is
  - Why It Matters
  - What to Expect
  - Questions to Ask
  - Risks and Alternatives
  - When to Seek Help
  - Empowerment Connection
  - Key Points
  - Your Rights
  - Insurance Notes

### Visit Summary Analysis Workflow
**Location**: Home Screen → Upload Visit Summary

**Process**:
1. User selects PDF file
2. User selects appointment date
3. PDF uploaded to Firebase Storage
4. Firebase Function `analyzeVisitSummaryPDF` called
5. Function:
   - Downloads PDF from Storage
   - Extracts text using OpenAI file API
   - Analyzes content with GPT-4
   - Generates structured summary
   - Creates learning modules
   - Generates todos
   - Identifies red flags
6. Results saved to Firestore:
   - `visit_summaries` collection
   - `learning_tasks` collection (for modules and todos)
7. User can view summary in Appointments List

**Duplicate Prevention**:
- Date normalization to UTC midnight
- Range query to catch timezone variations
- Processing locks to prevent race conditions
- Client-side filtering for display

### Birth Plan Todo Generation
When a birth plan is created, the system automatically generates todos based on preferences:

**Todo Categories**:
- Medical Preparation (e.g., "Ask OB provider about delayed cord clamping policy")
- Advocacy (e.g., "Discuss trauma-informed care preferences with provider")
- Planning (e.g., "Confirm water birth availability")
- Follow-up (e.g., "Schedule follow-up appointment")

Todos are saved to `learning_tasks` collection with:
- `birthPlanId`: Reference to birth plan
- `category`: Todo category
- `title`: Action item title
- `description`: Detailed description
- `isCompleted`: Completion status
- `isArchived`: Archive status

---

## Data Models & Storage

### Firestore Collections

#### `users/{userId}`
User profile data:
```javascript
{
  name: string,
  email: string,
  dueDate: Timestamp,
  pregnancyStage: string,
  allergies: string[],
  medicalConditions: string[],
  pregnancyComplications: string[],
  birthPreference: string,
  educationLevel: string,
  chronicConditions: string[],
  healthLiteracyGoals: string[],
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### `users/{userId}/notes`
Journal entries:
```javascript
{
  content: string,
  tag: string,
  isFeelingPrompt: boolean,
  moduleTitle: string,
  moduleId: string,
  highlightedText: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### `users/{userId}/learning_tasks`
Learning modules and todos:
```javascript
{
  title: string,
  description: string,
  content: string | Map,
  moduleType: string,
  trimester: string,
  isCompleted: boolean,
  isArchived: boolean,
  category: string,
  birthPlanId: string,
  visitSummaryId: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### `users/{userId}/file_uploads`
PDF upload metadata:
```javascript
{
  fileName: string,
  storagePath: string,
  downloadUrl: string,
  appointmentDate: Timestamp,
  fileSize: number,
  status: string,
  createdAt: Timestamp
}
```

#### `visit_summaries`
Visit summary documents:
```javascript
{
  userId: string,
  appointmentDate: Timestamp,
  summary: string,
  summaryData: Map,
  formattedSummary: string,
  keyMedicalTerms: Array,
  nextSteps: string,
  questionsToAsk: Array,
  empowermentTips: Array,
  newDiagnoses: Array,
  testsProcedures: Array,
  medications: Array,
  followUpInstructions: string,
  redFlags: Array,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### `birth_plans`
Birth plan documents:
```javascript
{
  userId: string,
  fullName: string,
  dueDate: Timestamp,
  supportPersonName: string,
  // ... all birth plan preferences
  status: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### `community_posts`
Community posts:
```javascript
{
  userId: string,
  authorName: string,
  title: string,
  content: string,
  category: string,
  likes: string[],
  replies: Array,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

#### `post_reports`
Post reports:
```javascript
{
  userId: string,
  postId: string,
  reason: string,
  details: string,
  createdAt: Timestamp
}
```

---

## AI Integration

### OpenAI API Usage

#### 1. Text Simplification (`simplifyText`)
**Purpose**: Simplify complex medical text to 6th grade reading level

**Usage**:
- General AI assistant (when context provided)
- Text simplification (default mode)

**Implementation**:
- Firebase Cloud Function
- Uses GPT-4 model
- Configurable system prompt via context parameter

#### 2. Visit Summary Analysis (`analyzeVisitSummaryPDF`)
**Purpose**: Analyze visit summary PDFs and generate structured summaries

**Process**:
1. PDF uploaded to Firebase Storage
2. PDF processed via OpenAI File API
3. Text extracted and analyzed
4. GPT-4 generates:
   - Structured summary
   - Learning modules
   - Todos
   - Red flag identification

**Output Structure**:
- JSON format with multiple sections
- Plain language explanations
- Culturally sensitive language
- Trauma-informed approach

#### 3. Birth Plan Generation (`generateBirthPlan`)
**Purpose**: Generate personalized birth plans from user preferences

**Input**: User preferences, medical history, concerns
**Output**: Comprehensive birth plan document

#### 4. Learning Module Generation
**Purpose**: Create personalized educational content

**Based On**:
- Pregnancy stage
- Health conditions
- Birth preferences
- Cultural considerations
- Learning style

---

## Provider Search Feature

### Current Implementation
The Provider Search feature is fully implemented in the UI but currently uses mock data. The screen is accessible via:
- Home screen search bar
- Direct navigation to `/providers` route

### UI Components

#### Header Section
- Gradient background (purple theme)
- Search bar for text-based provider search
- Close button to return to previous screen

#### Category Filters
Horizontal scrollable chips:
- All Providers
- OB-GYNs
- Midwives
- Doulas

#### Quick Filters
Toggleable filter chips:
- **Near me**: Location-based filtering
- **Accepting patients**: Only show providers accepting new patients
- **Background match**: Filter for providers matching user's background
- **Black Mama Approved**: Filter for Black Mama Approved providers

#### Provider Cards
Each card displays:
- Provider photo/avatar
- Name and specialty
- Practice name
- Acceptance status badge
- Black Mama Approved tag (if applicable)
- Star rating and review count
- Distance from user
- Phone number
- Business hours
- Languages spoken
- Specialties list
- Featured review (most helpful recent review)
- Community Trust Badge (for highly rated providers)

### Mock Data Structure
```javascript
{
  name: string,
  specialty: string,
  practice: string,
  location: string,
  distance: string,
  rating: number,
  reviews: number,
  acceptingNew: boolean,
  languages: string[],
  specialties: string[],
  hasBlackMamaTag: boolean,
  raceMatch: boolean,
  phone: string,
  hours: string,
  priceRange: string,
  recentReviews: Array
}
```

### Future Integration
To connect to a real provider database:
1. Replace mock data with Firestore query
2. Add provider collection to Firestore
3. Implement location-based search
4. Add user location permissions
5. Integrate with provider API if available

---

## Navigation & User Flow

### Main Navigation Structure
```
MainNavigationScaffold
├── Home Tab
│   ├── Home Screen (HomeScreenV2)
│   ├── Learning Center (LearningModulesScreenV2)
│   ├── Appointments (AppointmentsListScreen)
│   └── Provider Search (ProviderSearchScreen)
├── Journal Tab
│   └── Journal Screen (JournalScreen)
├── Community Tab
│   ├── Community Screen (CommunityScreen)
│   ├── Create Post Screen (CreatePostScreen)
│   └── Post Detail Screen (PostDetailScreen)
└── Assistant Tab
    └── Assistant Screen (AssistantScreen)
```

### Key Navigation Flows

#### New User Flow
1. Launch app → Auth Screen
2. Sign Up → Terms & Conditions
3. Profile Creation (multi-step)
4. Main App

#### Visit Summary Flow
1. Home → Upload Visit Summary
2. Select PDF → Select Date
3. Upload & Analyze
4. View Results → Appointments List
5. Click Summary → View Details

#### Birth Plan Flow
1. Home → Birth Plan
2. Comprehensive Form (8 sections)
3. Generate Birth Plan
4. View Formatted Plan
5. Todos Auto-Generated

#### Learning Module Flow
1. Home → Generate Learning Modules
2. AI Generation Process
3. Modules Appear in Learning Center
4. Click Module → View Details
5. Mark Complete → Archive

---

## Firebase Functions

### Available Functions

#### 1. `simplifyText`
**Purpose**: Simplify text or act as general AI assistant
**Input**: `{text: string, context?: string}`
**Output**: `{success: boolean, simplified: string}`
**Secrets**: OpenAI API Key

#### 2. `analyzeVisitSummaryPDF`
**Purpose**: Analyze visit summary PDFs
**Input**: 
```javascript
{
  storagePath: string,
  downloadUrl: string,
  appointmentDate: string,
  educationLevel?: string,
  userProfile?: object
}
```
**Output**: Structured summary with learning modules and todos
**Secrets**: OpenAI API Key
**Processing**:
- Downloads PDF from Storage
- Uses OpenAI File API for text extraction
- Analyzes with GPT-4
- Generates structured output
- Saves to Firestore

#### 3. `generateBirthPlan`
**Purpose**: Generate AI-powered birth plan
**Input**: User preferences, medical history
**Output**: Formatted birth plan document
**Secrets**: OpenAI API Key

#### 4. `generateLearningModules`
**Purpose**: Generate personalized learning modules
**Input**: User profile data
**Output**: Array of learning modules
**Secrets**: OpenAI API Key

### Function Security
- All functions require authentication
- User ID extracted from auth token
- Input validation on all parameters
- Error handling with user-friendly messages
- Rate limiting considerations

---

## Additional Features

### Keyboard Dismiss
All text input fields include a keyboard dismiss button (keyboard icon) in the suffix icon position. Users can tap this to dismiss the keyboard at any time.

### Real-time Updates
Most screens use Firestore `StreamBuilder` widgets for real-time data updates:
- Learning modules and todos
- Community posts
- Journal entries
- Visit summaries

### Error Handling
- User-friendly error messages
- Loading states for async operations
- Retry mechanisms where appropriate
- Offline handling (Firestore handles caching)

### Accessibility
- Clear visual hierarchy
- Readable font sizes
- Color contrast considerations
- Icon labels and tooltips

---

## Future Enhancements

### Planned Features
1. **Provider Search Backend**: Connect to real provider database
2. **Push Notifications**: Reminders for appointments and todos
3. **Offline Mode**: Enhanced offline functionality
4. **Data Export**: Export birth plans and summaries
5. **Provider Integration**: Direct communication with providers
6. **Telehealth**: Integration with telehealth platforms
7. **Medication Tracking**: Track medications and reminders
8. **Symptom Tracker**: Track symptoms over time
9. **Appointment Scheduling**: Schedule appointments through app
10. **Provider Reviews**: User-submitted provider reviews

---

## Technical Notes

### Date Handling
- All dates normalized to UTC midnight for consistency
- Timestamp objects used in Firestore
- String dates converted to Timestamps where needed

### Duplicate Prevention
- Visit summaries: Date-based duplicate detection
- Processing locks prevent concurrent processing
- Client-side filtering for display

### Content Formatting
- Markdown support for learning modules
- Structured JSON for visit summaries
- Plain text for journal entries

### Performance Considerations
- Firestore queries limited and indexed
- Image optimization for provider photos
- Lazy loading for long lists
- Caching where appropriate

---

## Conclusion

EmpowerHealth is a comprehensive maternal health application that combines AI-powered personalization, community support, and healthcare advocacy tools. The app is designed to be culturally sensitive, trauma-informed, and accessible to users with varying health literacy levels.

The current implementation includes all core features with a focus on user experience and data privacy. The provider search feature is UI-complete and ready for backend integration when provider data becomes available.

For technical support or feature requests, please refer to the codebase documentation or contact the development team.

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: EmpowerHealth Development Team
