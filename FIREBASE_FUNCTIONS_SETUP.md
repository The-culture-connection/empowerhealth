# Firebase Functions Setup Guide

This guide will help you set up and deploy the Firebase Functions with OpenAI integration for EmpowerHealth.

## Prerequisites

1. Firebase CLI installed (`npm install -g firebase-tools`)
2. Node.js 18 or higher
3. OpenAI API key

## Initial Setup

### 1. Login to Firebase

```bash
firebase login
```

### 2. Initialize Firebase Project (if not already done)

```bash
firebase init
```

Select:
- Functions
- Firestore

### 3. Install Dependencies

```bash
cd functions
npm install
```

### 4. Set Up OpenAI API Key

**IMPORTANT: Never commit your API key to version control!**

Set the OpenAI API key as a Firebase secret:

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

When prompted, paste your OpenAI API key.

**Note:** Never share or commit your API key to version control.

### 5. Deploy Functions

Deploy all functions:

```bash
firebase deploy --only functions
```

Deploy specific function:

```bash
firebase deploy --only functions:generateLearningContent
```

### 6. Deploy Firestore Rules and Indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## Available Functions

1. **generateLearningContent** - Creates AI-powered learning modules
2. **summarizeVisitNotes** - Simplifies medical visit notes to 6th grade level
3. **generateBirthPlan** - Creates personalized birth plans
4. **generateAppointmentChecklist** - Builds appointment preparation checklists
5. **analyzeEmotionalContent** - Identifies emotional moments and confusion
6. **generateRightsContent** - Explains patient rights in maternity care
7. **simplifyText** - Simplifies any text to 6th grade reading level

## Testing Functions Locally

Run the Firebase emulator:

```bash
cd functions
npm run serve
```

## Monitoring and Logs

View function logs:

```bash
firebase functions:log
```

View specific function logs:

```bash
firebase functions:log --only generateLearningContent
```

## Updating Functions

After making changes to function code:

1. Test locally with emulator
2. Deploy updated functions:
   ```bash
   firebase deploy --only functions
   ```

## Cost Considerations

- Firebase Functions has a free tier (2M invocations/month)
- OpenAI API costs vary by usage
- Monitor your Firebase console for usage

## Security Best Practices

1. ✅ Store API keys as Firebase secrets
2. ✅ Use Firestore security rules
3. ✅ Verify user authentication in functions
4. ❌ Never commit API keys to git
5. ❌ Don't expose functions publicly without auth

## Troubleshooting

### Function deployment fails
- Check Node.js version (should be 18)
- Verify Firebase CLI is up to date: `npm install -g firebase-tools`
- Check billing is enabled on Firebase project

### OpenAI API errors
- Verify API key is set correctly: `firebase functions:secrets:access OPENAI_API_KEY`
- Check OpenAI account has credits
- Review API usage limits

### CORS errors
- Enable CORS in Firebase console
- Check Firestore security rules

## Flutter Integration

The Flutter app uses these functions through the `AIService` class in `lib/services/ai_service.dart`.

To connect Flutter to Firebase Functions, ensure:
1. Firebase is initialized in `main.dart`
2. User is authenticated before calling functions
3. Error handling is implemented

## Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

