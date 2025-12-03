// Load environment variables from .env file (for local development)
require("dotenv").config();

const {onCall} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const {OpenAI} = require("openai");

admin.initializeApp();

// Define the OpenAI API key as a secret
const openaiApiKey = defineSecret("OPENAI_API_KEY");

// Helper to get OpenAI client
function getOpenAIClient(apiKey) {
  if (!apiKey) {
    throw new Error("OpenAI API key not configured");
  }
  return new OpenAI({
    apiKey: apiKey,
  });
}

// Helper function to simplify text to 6th grade level
async function simplifyTo6thGrade(text, context = "") {
  try {
    const openai = getOpenAIClient();
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a medical communication expert who translates complex medical information 
into simple, clear language appropriate for a 6th grade reading level. Use short sentences, 
common words, and avoid medical jargon. When medical terms are necessary, explain them simply. 
Focus on what the person needs to know and do.`,
        },
        {
          role: "user",
          content: `${context ? context + "\n\n" : ""}Please simplify this to 6th grade reading level:\n\n${text}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 1000,
    });

    return response.choices[0].message.content;
  } catch (error) {
    console.error("Error in simplifyTo6thGrade:", error);
    throw new functions.https.HttpsError("internal", "Failed to simplify text");
  }
}

// 1. Generate AI-powered learning module content
exports.generateLearningContent = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;

  const {topic, trimester, moduleType, userProfile} = data;

  // Determine reading level based on education
  const getReadingLevel = (educationLevel) => {
    if (!educationLevel) return "6th grade";
    if (educationLevel.includes("Graduate") || educationLevel.includes("Bachelor")) {
      return "8th grade";
    }
    if (educationLevel.includes("High School") || educationLevel.includes("Some College")) {
      return "6th-7th grade";
    }
    return "5th-6th grade";
  };

  const readingLevel = userProfile?.educationLevel ?
    getReadingLevel(userProfile.educationLevel) : "6th grade";

  // Build personalized context
  let personalContext = "";
  if (userProfile) {
    if (userProfile.chronicConditions && userProfile.chronicConditions.length > 0) {
      personalContext += `\nUser has these conditions: ${userProfile.chronicConditions.join(", ")}. Address any relevant considerations.`;
    }
    if (userProfile.healthLiteracyGoals && userProfile.healthLiteracyGoals.length > 0) {
      personalContext += `\nUser's learning goals: ${userProfile.healthLiteracyGoals.join(", ")}.`;
    }
    if (userProfile.insuranceType) {
      personalContext += `\nInsurance type: ${userProfile.insuranceType}. Mention coverage considerations if relevant.`;
    }
    if (userProfile.providerPreferences && userProfile.providerPreferences.length > 0) {
      personalContext += `\nProvider preferences: ${userProfile.providerPreferences.join(", ")}.`;
    }
  }

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a maternal health educator creating personalized content for pregnant women. 
Create engaging, supportive, and medically accurate content at a ${readingLevel} reading level. 
Include practical tips, what to expect, and when to seek medical help. Use warm, encouraging tone.
Tailor your content to the user's specific health situation and learning goals when provided.`,
        },
        {
          role: "user",
          content: `Create a learning module about "${topic}" for ${trimester} trimester. 
Type: ${moduleType}. 

${personalContext}

Include:
1. Overview (2-3 simple sentences)
2. What to Know (3-5 key points)
3. What to Do (practical steps)
4. When to Call Your Doctor
5. Helpful Tips

Keep everything at ${readingLevel} reading level with short paragraphs. Make it personally relevant based on the user's profile.`,
        },
      ],
      temperature: 0.8,
      max_tokens: 1500,
    });

    const content = response.choices[0].message.content;

    // Save to Firestore
    await admin.firestore().collection("learning_modules").add({
      topic,
      trimester,
      moduleType,
      content,
      generatedBy: "ai",
      personalizedFor: userProfile ? request.auth.uid : null,
      readingLevel,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      userId: request.auth.uid,
    });

    return {success: true, content};
  } catch (error) {
    console.error("Error generating learning content:", error);
    throw new Error("Failed to generate content");
  }
});

// 2. Summarize appointment/visit notes
exports.summarizeVisitNotes = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;

  const {visitNotes, providerInstructions, medications, diagnoses, emotionalFlags} = data;

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a patient advocate helping pregnant women understand their medical visits. 
Translate medical information into simple, clear language at a 6th grade reading level. 
Be warm, supportive, and encouraging. Organize information clearly with headers.`,
        },
        {
          role: "user",
          content: `Create a visit summary that a 6th grader could understand:

Visit Notes: ${visitNotes || "None provided"}

Diagnoses: ${diagnoses || "None listed"}

Medications: ${medications || "None prescribed"}

Provider Instructions: ${providerInstructions || "None given"}

${emotionalFlags ? `Emotional Notes: ${emotionalFlags}` : ""}

Format as:
## What Happened Today
[Simple summary]

## Your Health Update
[Explain any diagnoses simply]

## Your Medications
[Explain what each medicine does and how to take it]

## What You Need To Do
[Clear action steps]

## Questions to Ask Next Time
[Suggest 2-3 questions based on this visit]`,
        },
      ],
      temperature: 0.7,
      max_tokens: 2000,
    });

    const summary = response.choices[0].message.content;

    // Save to Firestore
    await admin.firestore().collection("visit_summaries").add({
      userId: request.auth.uid,
      originalNotes: visitNotes,
      summary,
      diagnoses,
      medications,
      emotionalFlags,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true, summary};
  } catch (error) {
    console.error("Error summarizing visit notes:", error);
    throw new Error("Failed to summarize visit");
  }
});

// 3. Generate personalized birth plan
exports.generateBirthPlan = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;

  const {preferences, medicalHistory, concerns, supportPeople} = data;

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a doula helping create personalized birth plans. Create a comprehensive 
yet simple birth plan that respects the mother's wishes while being medically informed. 
Use a warm, supportive tone and 6th grade reading level.`,
        },
        {
          role: "user",
          content: `Create a birth plan based on these preferences:

Preferences: ${JSON.stringify(preferences)}
Medical History: ${medicalHistory || "None noted"}
Concerns: ${concerns || "None noted"}
Support People: ${supportPeople || "Not specified"}

Include sections for:
- Labor preferences
- Pain management
- Delivery preferences
- After birth preferences
- Support people and their roles
- Special requests

Keep language simple and clear.`,
        },
      ],
      temperature: 0.8,
      max_tokens: 2000,
    });

    const birthPlan = response.choices[0].message.content;

    // Save to Firestore
    const docRef = await admin.firestore().collection("birth_plans").add({
      userId: request.auth.uid,
      preferences,
      medicalHistory,
      birthPlan,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {success: true, birthPlan, planId: docRef.id};
  } catch (error) {
    console.error("Error generating birth plan:", error);
    throw new Error("Failed to generate birth plan");
  }
});

// 4. Generate appointment checklist
exports.generateAppointmentChecklist = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;

  const {appointmentType, trimester, concerns, lastVisit} = data;

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a patient advocate helping pregnant women prepare for medical appointments. 
Create clear, actionable checklists at a 6th grade reading level. Be encouraging and thorough.`,
        },
        {
          role: "user",
          content: `Create an appointment preparation checklist for:

Appointment Type: ${appointmentType}
Trimester: ${trimester}
Patient Concerns: ${concerns || "None specified"}
Last Visit Notes: ${lastVisit || "First visit"}

Include:
1. What to bring
2. Questions to ask
3. Symptoms to mention
4. What to expect during visit
5. Important topics to discuss

Keep language simple and actionable.`,
        },
      ],
      temperature: 0.7,
      max_tokens: 1500,
    });

    const checklist = response.choices[0].message.content;

    return {success: true, checklist};
  } catch (error) {
    console.error("Error generating checklist:", error);
    throw new Error("Failed to generate checklist");
  }
});

// 5. Analyze emotional moments and confusion in visit notes
exports.analyzeEmotionalContent = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;

  const {journalEntry, visitNotes} = data;

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a compassionate healthcare advocate. Analyze text for emotional content, 
confusion, concerns, or distress. Identify moments that might need follow-up or support. 
Provide gentle, supportive recommendations.`,
        },
        {
          role: "user",
          content: `Analyze this content for emotional moments, confusion, or concerns:

${journalEntry || visitNotes}

Identify:
1. Emotional moments (fear, anxiety, confusion, sadness)
2. Questions or confusion about medical care
3. Potential red flags
4. Suggested support or follow-up

Respond in JSON format:
{
  "emotionalFlags": [],
  "confusionPoints": [],
  "redFlags": [],
  "recommendations": []
}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 1000,
    });

    const analysis = JSON.parse(response.choices[0].message.content);

    return {success: true, analysis};
  } catch (error) {
    console.error("Error analyzing emotional content:", error);
    throw new Error("Failed to analyze content");
  }
});

// 6. Generate "Know Your Rights" content
exports.generateRightsContent = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;

  const {topic, state} = data;

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a patient rights advocate specializing in maternal healthcare. 
Explain patient rights clearly and empoweringly at a 6th grade reading level. 
Be specific, actionable, and encouraging.`,
        },
        {
          role: "user",
          content: `Explain patient rights about "${topic}" in maternity care${state ? ` for ${state}` : ""}.

Include:
1. Your Rights (what you can say yes or no to)
2. What Your Provider Must Do
3. When to Speak Up
4. How to Advocate for Yourself
5. Resources for Help

Keep language simple, clear, and empowering.`,
        },
      ],
      temperature: 0.7,
      max_tokens: 1500,
    });

    const content = response.choices[0].message.content;

    return {success: true, content};
  } catch (error) {
    console.error("Error generating rights content:", error);
    throw new Error("Failed to generate rights content");
  }
});

// Export helper function for use in other functions
exports.simplifyText = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const {text, context: textContext} = request.data;

    try {
      const openai = getOpenAIClient(openaiApiKey.value());
      const response = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: `You are a medical communication expert who translates complex medical information 
into simple, clear language appropriate for a 6th grade reading level. Use short sentences, 
common words, and avoid medical jargon. When medical terms are necessary, explain them simply. 
Focus on what the person needs to know and do.`,
          },
          {
            role: "user",
            content: `${textContext ? textContext + "\n\n" : ""}Please simplify this to 6th grade reading level:\n\n${text}`,
          },
        ],
        temperature: 0.7,
        max_tokens: 1000,
      });

      const simplified = response.choices[0].message.content;
      return {success: true, simplified};
    } catch (error) {
      console.error("Error simplifying text:", error);
      throw new Error("Failed to simplify text");
    }
  }
);

