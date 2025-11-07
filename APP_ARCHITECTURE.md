# EmpowerHealth App Architecture

## Navigation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                          App Launch                              │
│                              ↓                                   │
│                      ┌──────────────┐                            │
│                      │ Auth Screen  │                            │
│                      │  (Initial)   │                            │
│                      └──────┬───────┘                            │
│                             │                                    │
│              ┌──────────────┴──────────────┐                     │
│              ↓                             ↓                     │
│      ┌──────────────┐              ┌──────────────┐             │
│      │Login Screen  │              │Signup Screen │             │
│      └──────┬───────┘              └──────┬───────┘             │
│             └────────────┬─────────────────┘                     │
│                          ↓                                       │
│              ┌──────────────────────┐                            │
│              │Main Navigation Screen│                            │
│              │  (Bottom Nav Bar)    │                            │
│              └──────────┬───────────┘                            │
│                         │                                        │
│     ┌──────────┬────────┼────────┬──────────┐                   │
│     ↓          ↓        ↓        ↓          ↓                   │
│ ┌────────┐┌────────┐┌──────┐┌────────┐┌────────┐               │
│ │Dashboard││Transcr││Comm- ││Feedback││Other   │               │
│ │ Screen ││iption ││unity ││Screen  ││Screens │               │
│ └───┬────┘└────────┘└──────┘└────────┘└────────┘               │
│     │                                                            │
│     └─────────┬─────────────────────────────────┐               │
│               ↓                                 ↓               │
│     ┌──────────────────┐              ┌──────────────┐          │
│     │Appointments      │              │Transcription │          │
│     │Screen (Calendar) │              │Screen (Quick)│          │
│     └──────────────────┘              └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Dashboard Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ┌─────┐  Dashboard             ┌──────────────────┐         │
│ │Logo │  Welcome back!         │  🎤 Microphone   │         │
│ └─────┘                        │ (Quick Action)   │         │
│                                 └──────────────────┘         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ╔════════════════════════════════════════════════════╗      │
│  ║         📅 Upcoming Appointments                   ║      │
│  ║         Tap to view calendar                       ║      │
│  ║  ┌──────────────────────────────────────────────┐ ║      │
│  ║  │ 📅 Dr. Smith - General Checkup             │ ║      │
│  ║  │    Today at 2:00 PM                        │ ║      │
│  ║  └──────────────────────────────────────────────┘ ║      │
│  ╚════════════════════════════════════════════════════╝      │
│                                                               │
│  ┌──────────────────────────┐  ┌──────────────────────────┐ │
│  │  👥 Community            │  │  💬 Feedback             │ │
│  │  Most recent message     │  │  Recent feedback         │ │
│  │  ┌────────────────────┐  │  │  ┌────────────────────┐ │ │
│  │  │ Sarah M.           │  │  │  │ App Performance    │ │ │
│  │  │ Just finished...   │  │  │  │ [In Progress]      │ │ │
│  │  │ 5 min ago          │  │  │  │ 2 days ago         │ │ │
│  │  └────────────────────┘  │  │  └────────────────────┘ │ │
│  └──────────────────────────┘  └──────────────────────────┘ │
│                                                               │
│  Quick Actions                                                │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ View Profile      │  │ Settings          │                 │
│  └──────────────────┘  └──────────────────┘                 │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│ Bottom Navigation Bar:                                       │
│ [Dashboard] [Record] [Community] [Feedback]                  │
└─────────────────────────────────────────────────────────────┘
```

## Feature Screens

### 1. Auth Screen
- **Purpose**: Initial landing page
- **Elements**:
  - App logo and branding
  - "Create Account" button → Signup Screen
  - "Sign In" button → Login Screen
- **Background**: Gradient overlay

### 2. Dashboard Screen
- **Purpose**: Main hub for app navigation
- **Key Features**:
  - Microphone button (top-right corner) for quick transcription access
  - Appointments widget with next appointment preview
  - Community widget showing latest message
  - Feedback widget showing recent feedback
  - Quick action buttons
- **Navigation**: All widgets are tappable and lead to their respective screens

### 3. Appointments Screen
- **Purpose**: Manage and view appointments
- **Key Features**:
  - Interactive calendar widget (table_calendar)
  - Date selection
  - List of appointments for selected date
  - Add new appointment button
- **Background**: Fixed gradient with scroll overlay

### 4. Transcription Screen
- **Purpose**: Record and manage voice transcriptions
- **Key Features**:
  - Large circular microphone button
  - Recording status indicator
  - Live transcription preview
  - List of recent transcriptions with previews
- **Background**: Fixed gradient with scroll overlay

### 5. Community Screen
- **Purpose**: Community interaction and posts
- **Key Features**:
  - Create post input
  - Filter chips (All, Questions, Success Stories, Support)
  - Community message feed
  - Like, comment, share actions
  - Floating action button for new posts
- **Background**: Fixed gradient with scroll overlay

### 6. Feedback Screen
- **Purpose**: Submit and track feedback
- **Key Features**:
  - Feedback form (type, title, message)
  - Feedback history list
  - Status badges (In Progress, Under Review, Resolved)
  - Type icons (Bug, Feature, Complaint, Compliment)
- **Background**: Fixed gradient with scroll overlay

## Design System

### Colors (Theme)
- **Background**: Light tan (#F5F2EE)
- **Foreground**: Dark brown (#5C524A)
- **Primary**: Medium tan/brown (#B8865A)
- **Accent**: Tan/gold (#C8A97A)
- **Success**: Green (#6B9B7A)
- **Warning**: Gold (#D4A574)
- **Error**: Red/brown (#B86B5C)

### Typography
- **Font Family**: Inter
- **Display**: 36px, 32px, 28px (bold)
- **Headline**: 24px, 22px, 20px (semi-bold)
- **Title**: 18px, 16px, 14px (semi-bold)
- **Body**: 16px, 14px, 12px (regular)

### Spacing
- XS: 8px
- S: 12px
- M: 16px
- L: 24px
- XL: 32px
- XXL: 48px

### Border Radius
- Standard: 20px
- Small: 12px

## Key Technical Decisions

### 1. Fixed Background Implementation
```dart
Stack(
  children: [
    // Fixed background layer
    Positioned.fill(
      child: Container(decoration: gradient/image),
    ),
    // Scrollable content layer
    SafeArea(
      child: SingleChildScrollView(...),
    ),
  ],
)
```

### 2. Navigation Pattern
- Named routes for all screens
- Bottom navigation for main sections
- Push navigation for detail screens
- Replace navigation for auth flow

### 3. State Management
- Currently using StatefulWidget for local state
- Ready for integration with Provider/Riverpod/Bloc

### 4. Widget Reusability
- DS (Design System) class for common widgets
- Consistent spacing using gap constants
- Theme-based styling throughout

## Directory Structure

```
lib/
├── app_router.dart                    # Route definitions
├── main.dart                          # App entry point
├── core/
│   └── constants.dart                 # Route constants
├── design_system/
│   ├── theme.dart                     # App theme
│   └── widgets.dart                   # Reusable widgets (DS class)
└── features/
    ├── appointments/
    │   └── appointments_screen.dart   # Calendar & appointments
    ├── auth/
    │   ├── auth_screen.dart          # Landing auth screen
    │   ├── login_screen.dart         # Login form
    │   └── signup_screen.dart        # Registration form
    ├── community/
    │   └── community_screen.dart     # Community posts
    ├── dashboard/
    │   └── dashboard_screen.dart     # Main dashboard
    ├── feedback/
    │   └── feedback_screen.dart      # Feedback submission
    ├── navigation/
    │   └── main_navigation_screen.dart # Bottom nav container
    └── transcription/
        └── transcription_screen.dart  # Voice recording
```

## Dependencies

### Core
- `flutter` - Framework
- `cupertino_icons` - iOS-style icons

### Added
- `table_calendar: ^3.1.2` - Calendar widget for appointments

## Next Steps for Development

### Immediate
1. Run `flutter pub get`
2. Add actual background images to `assets/images/`
3. Test navigation flow
4. Verify UI on different screen sizes

### Backend Integration
1. Authentication service integration
2. Appointments API connection
3. Transcription service integration
4. Community posts backend
5. Feedback submission API

### Enhancements
1. Add state management solution
2. Implement offline support
3. Add push notifications
4. Implement search functionality
5. Add user profile screen
6. Add settings screen

### Testing
1. Unit tests for business logic
2. Widget tests for UI components
3. Integration tests for navigation
4. End-to-end user flow tests
