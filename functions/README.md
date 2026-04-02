# EmpowerHealth Firebase Functions

AI-powered backend functions for the EmpowerHealth app.

## Features

- **Learning Content Generation**: Creates trimester-based learning modules at 6th grade reading level
- **Visit Summary Tool**: Translates complex medical notes into simple language
- **Birth Plan Creator**: Generates personalized birth plans
- **Appointment Checklists**: Creates preparation checklists for medical visits
- **Emotional Analysis**: Identifies confusion and emotional moments in journal entries
- **Patient Rights**: Explains maternal healthcare rights in accessible language

## Setup

See `../FIREBASE_FUNCTIONS_SETUP.md` for detailed setup instructions.

Quick start:

```bash
npm install
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions
```

## Development

Run locally:

```bash
npm run serve
```

Deploy:

```bash
npm run deploy
```

## Environment Variables

Required secrets:
- `OPENAI_API_KEY` - Your OpenAI API key

## Testing

The functions are designed to be called from authenticated Flutter clients using Firebase Functions SDK.

Example usage from Flutter:

```dart
final result = await aiService.generateLearningContent(
  topic: 'Nutrition in Pregnancy',
  trimester: 'first',
  moduleType: 'educational',
);
```

