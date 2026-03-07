# Platform Features Documentation

This document tracks all platform features, their current functionality, and change history.

## 1. Provider Search

### Current Functionality
The Provider Search feature allows users to find healthcare providers based on various criteria including location, specialty, identity tags, and user reviews. Users can search for providers, view detailed provider profiles with ratings and reviews, filter by specific criteria such as "Mama Approved" status, and save favorite providers for quick access. The search integrates with provider identity claims and allows users to submit new providers for review. The system tracks provider reviews, ratings, and user interactions to help users make informed healthcare decisions.

### Change History
- **2024-12-15** - **abc123def** - **Enhanced search filters**: Added medicaid directory.
- **2024-12-10** - **def456ghi** - **Provider reviews integration**: Integrated user reviews directly into provider search results for better decision-making.

---

## 2. Authentication and Onboarding

### Current Functionality
The Authentication and Onboarding system handles user account creation, login, password management, and initial user setup. Users can sign up with email and password, reset forgotten passwords, and complete an onboarding flow that collects initial preferences and needs. The system supports role-based access control for admin dashboard users and maintains user profiles with preferences and settings. Onboarding includes care survey collection to personalize the user experience.

### Change History
- **2024-12-14** - **xyz789abc** - **Biometric authentication**: Added support for fingerprint and face recognition login for faster access.
- **2024-12-08** - **mno321pqr** - **Onboarding improvements**: Streamlined the onboarding flow to reduce completion time by 30%.

---

## 3. User Feedback

### Current Functionality
The User Feedback system encompasses two main components: Care Check-in surveys and Learning Module reviews. Care Check-in allows users to provide feedback about their healthcare experiences, including questions about care quality, communication, and satisfaction. Learning Module reviews enable users to rate and review educational content, providing ratings for understanding, next steps clarity, and confidence levels. This feedback is aggregated to improve content quality and track user engagement with educational materials.

### Change History
- **2024-12-13** - **uvw456rst** - **Feedback analytics dashboard**: Did stuff

---

## 4. Appointment Summarizing

### Current Functionality
The Appointment Summarizing feature (After Visit Summary) allows users to upload PDF visit summaries or enter text notes from medical appointments. The system uses AI to process and summarize these documents, extracting key information, medications, recommendations, and next steps. Summaries are simplified to a 6th-grade reading level for accessibility. Users can view, edit, and manage their visit summaries, which are stored securely and can be referenced for future appointments or shared with other healthcare providers.

### Change History
- *No changes tracked yet*

---

## 5. Journal

### Current Functionality
The Journal feature provides users with a private space to record thoughts, experiences, and notes related to their healthcare journey. Users can create journal entries with text content, attach files or images, and organize entries by date. The journal supports emotional content analysis to identify significant moments or areas of confusion. Entries are stored securely and can be searched, filtered, and reviewed over time to track progress and patterns.

### Change History
- *No changes tracked yet*

---

## 6. Learning Modules

### Current Functionality
The Learning Modules feature provides educational content tailored to users' needs and pregnancy/postpartum journey. Modules cover topics such as pregnancy health, postpartum care, patient rights, and self-advocacy. Content is generated using AI to ensure it's at a 6th-grade reading level and culturally appropriate. Users can complete modules, track progress, receive personalized recommendations, and provide feedback. The system includes task management for learning goals and tracks completion rates and engagement metrics.

### Change History
- *No changes tracked yet*

---

## 7. Birth Plan Generator

### Current Functionality
The Birth Plan Generator helps users create personalized birth plans by guiding them through preferences for labor, delivery, and postpartum care. Users can specify preferences for pain management, delivery positions, who should be present, feeding preferences, and postpartum care. The system uses AI to generate comprehensive birth plans based on user inputs, which can be exported as PDFs and shared with healthcare providers. Plans can be updated as preferences change and are stored securely for reference.

### Change History
- *No changes tracked yet*

---

## 8. Community

### Current Functionality
The Community feature provides a forum where users can share experiences, ask questions, and support each other. Users can create posts, reply to others' posts, like content, and report inappropriate material. Posts are organized by topics and can be searched. The community fosters peer support and information sharing while maintaining moderation capabilities. Users can engage in discussions about pregnancy, postpartum, healthcare experiences, and related topics in a safe, supportive environment.

### Change History
- *No changes tracked yet*

---

## 9. Profile Editing

### Current Functionality
The Profile Editing feature allows users to manage their account information, preferences, and settings. Users can update their display name, email, profile picture, and personal information. The system includes privacy settings, notification preferences, and account management options. Users can view their activity history, manage connected accounts, and control data sharing preferences. Profile changes are tracked for audit purposes and synced across the platform.

### Change History
- *No changes tracked yet*

---

## How to Add Changes

When modifying any feature, add an entry to the "Change History" section for that feature in the following format:

```
- **[Date]** - **[Commit SHA]** - **[Description]**: [Detailed description of changes]
```

Example:
```
- **2024-01-15** - **abc123def** - **Enhanced search filters**: Added ability to filter providers by insurance type and distance radius. Improved search performance by 40%.
```
