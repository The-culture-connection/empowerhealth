const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const {OpenAI} = require("openai");
const axios = require("axios");
const XLSX = require("xlsx");
const path = require("path");
const fs = require("fs");
const crypto = require("crypto");
const engine = require("./providerSearchEngine");
const {
  PREGNANCY_LOSS_LEARNING_SYSTEM,
  pregnancyLossLearningUserMessage,
  isPregnancyLossLearningRequest,
} = require("./pregnancyLossLearningPrompt");
// Import BIPOC provider import function (lazy load to avoid initialization issues)
let importBipocProviders = null;
function getImportBipocProviders() {
  if (importBipocProviders === null) {
    try {
      const importModule = require("./importBipocProviders");
      importBipocProviders = importModule.importBipocProviders;
    } catch (error) {
      console.warn("Could not load importBipocProviders module:", error.message);
      importBipocProviders = false; // Use false to indicate tried and failed
    }
  }
  return importBipocProviders || null;
}

// Initialize Firebase Admin (only if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

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

/** Parse client appointmentDate: YYYY-MM-DD (preferred) or ISO (date part only) or Timestamp. */
function parseAppointmentCalendarParts(appointmentDate) {
  if (appointmentDate == null || appointmentDate === "") {
    const n = new Date();
    return {y: n.getUTCFullYear(), m: n.getUTCMonth() + 1, d: n.getUTCDate()};
  }
  if (appointmentDate && typeof appointmentDate.toDate === "function") {
    const dt = appointmentDate.toDate();
    return {y: dt.getUTCFullYear(), m: dt.getUTCMonth() + 1, d: dt.getUTCDate()};
  }
  if (typeof appointmentDate === "string") {
    const dateStr = appointmentDate.split("T")[0].trim();
    const parts = dateStr.split("-").map(Number);
    if (parts.length >= 3 && parts.every((n) => !Number.isNaN(n))) {
      return {y: parts[0], m: parts[1], d: parts[2]};
    }
  }
  if (appointmentDate instanceof Date) {
    return {
      y: appointmentDate.getUTCFullYear(),
      m: appointmentDate.getUTCMonth() + 1,
      d: appointmentDate.getUTCDate(),
    };
  }
  const n = new Date();
  return {y: n.getUTCFullYear(), m: n.getUTCMonth() + 1, d: n.getUTCDate()};
}

function firestoreTimestampFromCalendarYmd(y, m, d) {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.UTC(y, m - 1, d, 12, 0, 0, 0)),
  );
}

function calendarYmdKey(y, m, d) {
  return `${y}-${String(m).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
}

function appointmentCalendarKeyFromValue(val) {
  const {y, m, d} = parseAppointmentCalendarParts(val);
  return calendarYmdKey(y, m, d);
}

/** OpenAI sometimes returns prose or fenced JSON; extract and parse. */
function parseJsonFromOpenAIContent(raw) {
  if (!raw || typeof raw !== "string") {
    throw new Error("Empty AI response");
  }
  let s = raw.trim();
  const fence = s.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (fence) {
    s = fence[1].trim();
  }
  try {
    return JSON.parse(s);
  } catch (e1) {
    const i = s.indexOf("{");
    const j = s.lastIndexOf("}");
    if (i !== -1 && j > i) {
      try {
        return JSON.parse(s.slice(i, j + 1));
      } catch (e2) {
        /* fall through */
      }
    }
    throw e1;
  }
}

// ============================================================================
// VOICE CONSISTENCY (second person, woman-facing content)
// ============================================================================

/**
 * Shared prompt rule: all woman-facing generated content speaks directly to
 * the mother in second person ("you/your"), never "the patient".
 */
const SECOND_PERSON_VOICE_RULE = `VOICE (required): Speak directly to the mother using second person ("you" / "your") in plain language. Never refer to her as "the patient", "the mother", "the client", or "she/her". Examples: write "Your next annual exam is in one year" (not "The patient's next annual exam..."), "You were referred to a specialist" (not "The patient has been referred..."), "Your blood pressure was normal" (not "The patient's blood pressure was normal"). Keep all clinical facts, numbers, medication names, doses, and instructions exactly accurate; change only who the sentence is addressed to. If you must quote the provider's notes word for word, introduce the quote for her, e.g. "Your provider's note says: '...'". Use third person only when it is clinically necessary (for example, describing the baby or another person). Do not use em dashes (—); use commas, periods or colons instead.`;

// Nouns that follow "the patient" in normal phrases we must not rewrite
// (e.g. "the patient portal", "the patient advocate").
const PATIENT_COMPOUND_NOUNS = [
  "portal", "portals", "advocate", "advocates", "advocacy", "navigator", "navigators",
  "education", "educator", "rights", "bill", "handbook", "experience", "services",
  "relations", "representative", "liaison", "safety", "center", "line", "access",
  "ID", "id", "number", "record", "records", "chart", "information", "instructions",
  "summary", "survey", "form", "forms", "account", "app", "care", "support", "guide",
];
const PATIENT_NOUN_GUARD = `(?!\\s+(?:${PATIENT_COMPOUND_NOUNS.join("|")})\\b)`;

// Third-person verbs that commonly follow "the patient" → second-person form.
const PATIENT_VERB_MAP = {
  "has": "have", "is": "are", "was": "were", "does": "do", "needs": "need",
  "wants": "want", "reports": "report", "reported": "reported", "states": "state",
  "denies": "deny", "plans": "plan", "requires": "require", "takes": "take",
  "continues": "continue", "presents": "present", "understands": "understand",
  "agrees": "agree", "prefers": "prefer", "feels": "feel", "appears": "appear",
  "remains": "remain", "declines": "decline", "receives": "receive",
  "should": "should", "will": "will", "can": "can", "may": "may", "must": "must",
  "would": "would", "could": "could",
};

/**
 * Conservative safety net: rewrite common third-person clinical phrasings
 * ("The patient's...", "The patient has been referred...") into second person.
 * Only matches "the patient" with the article, so "outpatient", "inpatient",
 * "patients", "patient portal", and "patient advocate" are left untouched.
 */
function toSecondPerson(text) {
  if (!text || typeof text !== "string" || !/\bthe patient\b/i.test(text)) {
    return text;
  }
  let out = text;

  // Possessive: "The patient's" → "Your", "the patient's" → "your"
  out = out.replace(/\bThe patient(?:'|’)s\b/g, "Your");
  out = out.replace(/\bthe patient(?:'|’)s\b/g, "your");

  // Subject + verb: "The patient has" → "You have", "the patient is" → "you are"
  const verbs = Object.keys(PATIENT_VERB_MAP).join("|");
  out = out.replace(new RegExp(`\\b(T|t)he patient\\s+(${verbs})\\b`, "g"), (match, t, verb) => {
    const pronoun = t === "T" ? "You" : "you";
    return `${pronoun} ${PATIENT_VERB_MAP[verb]}`;
  });

  // Remaining "The patient" / "the patient" (not followed by a compound noun)
  out = out.replace(new RegExp(`\\bThe patient\\b(?!(?:'|’))${PATIENT_NOUN_GUARD}`, "g"), "You");
  out = out.replace(new RegExp(`\\bthe patient\\b(?!(?:'|’))${PATIENT_NOUN_GUARD}`, "g"), "you");

  return out;
}

// Keys whose values are names/labels (medical terms, drug names, enums) — never rewritten.
const SECOND_PERSON_SKIP_KEYS = new Set(["term", "name", "diagnosis", "category", "type"]);

/** Recursively apply toSecondPerson to all strings in an AI JSON value. */
function toSecondPersonDeep(value, key = null) {
  if (key && SECOND_PERSON_SKIP_KEYS.has(key)) return value;
  if (typeof value === "string") return toSecondPerson(value);
  if (Array.isArray(value)) return value.map((v) => toSecondPersonDeep(v));
  if (value && typeof value === "object") {
    const out = {};
    Object.keys(value).forEach((k) => {
      out[k] = toSecondPersonDeep(value[k], k);
    });
    return out;
  }
  return value;
}

/**
 * Normalize woman-facing fields of a visit-summary AI response (summary text,
 * todos/next steps, learning modules, red-flag descriptions) to second person
 * before it is formatted, saved to Firestore, or returned to the app.
 */
function applySecondPersonToVisitAnalysis(parsed) {
  if (!parsed || typeof parsed !== "object") return parsed;
  if (parsed.summary && typeof parsed.summary === "object") {
    parsed.summary = toSecondPersonDeep(parsed.summary);
  }
  if (Array.isArray(parsed.todos)) {
    parsed.todos = parsed.todos.map((todo) => toSecondPersonDeep(todo));
  }
  if (Array.isArray(parsed.learningModules)) {
    parsed.learningModules = parsed.learningModules.map((mod) => toSecondPersonDeep(mod));
  }
  if (Array.isArray(parsed.redFlags)) {
    parsed.redFlags = parsed.redFlags.map((flag) => toSecondPersonDeep(flag));
  }
  return parsed;
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
Focus on what the person needs to know and do.

${SECOND_PERSON_VOICE_RULE}`,
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
        throw new HttpsError("internal", "Failed to simplify text");
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

  const usePregnancyLossPrompt = isPregnancyLossLearningRequest(data);

  try {
    const openai = getOpenAIClient(openaiApiKey.value());

    let messages;
    if (usePregnancyLossPrompt) {
      messages = [
        {role: "system", content: PREGNANCY_LOSS_LEARNING_SYSTEM},
        {
          role: "user",
          content: pregnancyLossLearningUserMessage(topic, personalContext),
        },
      ];
    } else {
      messages = [
        {
          role: "system",
          content: `You are a culturally affirming, trauma-informed maternal health educator creating personalized content for EmpowerHealth Watch. Create detailed, comprehensive learning modules that are warm, supportive, and empowering. Use plain language at a ${readingLevel} reading level. Emphasize: Your rights, Your choices, Your voice. Brand voice: "Your Health. Your Voice. Your Empowerment."

${SECOND_PERSON_VOICE_RULE}`,
        },
        {
          role: "user",
          content: `Create a detailed, comprehensive learning module about "${topic}" for ${trimester} trimester. Type: ${moduleType}.

${personalContext}

${userProfile?.insuranceType ? `Insurance Type: ${userProfile.insuranceType}. Tailor information for this insurance type, including coverage considerations, what's typically covered, and any cost considerations.` : "Provide insurance-agnostic guidance that applies regardless of insurance type."}

CRITICAL: This module must be DETAILED (not high-level) and follow this EXACT structure.

FORMATTING (required for the app):
- Each section starts on its own line as a markdown H2 heading with the number and title. Example: ## 1. What This Is (Simple Explanation)
- Do NOT wrap section titles in asterisks. Use **only** inside paragraphs for short emphasis on a word or phrase (not whole headings).
- After each heading, write 2–4 short paragraphs (not one long wall of text). Use a blank line between paragraphs.
- For lists, use lines starting with "- " (hyphen space). Reserve bullets mainly for "Key Points" and "Your Rights" sections.
- Do not use a giant numbered list for the whole module body; the numbered structure is only the ten section headings.

The ten sections (use these exact titles after ## and the number):

1. What This Is (Simple Explanation): clear, plain-language explanation of what this is
2. Why It Matters for Your Health: why this matters, what happens if ignored; be specific
3. What to Expect: step-by-step, concrete guidance
4. What You Can Ask or Say: at least 3 advocacy prompts you can use, written in your own voice (e.g. "Can you explain why this test is needed?") (can be bullet lines)
5. Risks, Options, and Alternatives: balanced, non-alarming
6. When to Seek Medical Help: when to call or seek emergency care
7. How This Connects to Your Empowerment: self-advocacy and informed choice
8. Key Points: 3–5 takeaways as "- " bullets
9. Your Rights: 2–3 rights as "- " bullets
10. Insurance Notes: ${userProfile?.insuranceType ? `Tailor for ${userProfile.insuranceType}: coverage, costs, what to ask.` : "Insurance-agnostic: what to ask about coverage and costs."}

TONE & VOICE REQUIREMENTS:
- Warm, supportive, nonjudgmental language
- Speak directly to her as "you/your" throughout; never "the patient" or "the mother"
- Sound like: "Here's what this test means and why it matters. You deserve clear explanations and the chance to ask questions."
- Trauma-informed: Acknowledge possible fears, past negative experiences, pressure. Use supportive language that reassures and centers safety.
- Cultural responsiveness: Reflect realities Black mothers may face (bias, being dismissed, rushed). Use validating, empowering language.
- Avoid: Fear-based language, provider-blaming, cultural stereotypes, overly technical explanations, long paragraphs without breaks
- Use: Short paragraphs, defined terms, bullets only where they help (especially Key Points and Rights)

Keep everything at ${readingLevel} reading level. Make it personally relevant based on the user's profile.`,
        },
      ];
    }

    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages,
      temperature: usePregnancyLossPrompt ? 0.5 : 0.8,
      max_tokens: 1500,
    });

    // Safety net: keep woman-facing module text in second person ("you/your")
    const content = toSecondPerson(response.choices[0].message.content);

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
          content: `You are a medical interpreter helping pregnant women understand their medical visits. 
Translate medical information into clear, accessible language at a 6th grade reading level. 
Use professional, clinical language. Avoid casual terms like "momma". 
Be supportive and factual. Organize information clearly with headers.

${SECOND_PERSON_VOICE_RULE}`,
        },
        {
          role: "user",
          content: `Create a visit summary that a 6th grader could understand, written directly to her as "you/your" (e.g. "You were referred to...", "Your next visit is..."), never "the patient":

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

    // Safety net: keep woman-facing summary text in second person ("you/your")
    const summary = toSecondPerson(response.choices[0].message.content);

    // Note: The app code saves the summary to Firestore with the correct appointmentDate
    // We only generate and return the summary here to avoid duplicate saves

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
          content: `You are a birth planning specialist helping create personalized birth plans. Create a comprehensive 
yet accessible birth plan that respects the mother's wishes while being medically informed. 
Use professional, clinical language and a 6th grade reading level. Avoid casual terms like "momma".

VOICE (required): The plan belongs to her and is shared with her care team, so write each preference in her own first-person voice (e.g. "I would like to move freely during labor", "My support person is..."). Any notes or explanations addressed to her use "you/your". Never refer to her as "the patient" or "the mother". Keep all clinical details accurate.`,
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
          content: `You are a healthcare coordinator helping pregnant women prepare for medical appointments. 
Create clear, actionable checklists at a 6th grade reading level. Use professional clinical language. 
Avoid casual terms like "momma". Be supportive and thorough.

${SECOND_PERSON_VOICE_RULE}`,
        },
        {
          role: "user",
          content: `Create an appointment preparation checklist for:

Appointment Type: ${appointmentType}
Trimester: ${trimester}
Her Concerns: ${concerns || "None specified"}
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

    const checklist = toSecondPerson(response.choices[0].message.content);

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
          content: `You are a healthcare advocate. Analyze text for emotional content, 
confusion, concerns, or distress. Identify moments that might need follow-up or support. 
Use professional, clinical language. Avoid casual terms. Provide clear, supportive recommendations.

${SECOND_PERSON_VOICE_RULE}`,
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
Be specific, actionable, and encouraging.

${SECOND_PERSON_VOICE_RULE}`,
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

    const content = toSecondPerson(response.choices[0].message.content);

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
      
      // If context is provided, use it as a custom system prompt for general AI assistant
      // Otherwise, use the default text simplification prompt
      const systemPrompt = textContext ? `${textContext}

${SECOND_PERSON_VOICE_RULE}` : `You are a medical communication expert who translates complex medical information 
into simple, clear language appropriate for a 6th grade reading level. Use short sentences, 
common words, and avoid medical jargon. When medical terms are necessary, explain them simply. 
Focus on what the person needs to know and do.

${SECOND_PERSON_VOICE_RULE}`;

      const userPrompt = textContext 
        ? text 
        : `Please simplify this to 6th grade reading level:\n\n${text}`;

      const response = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: systemPrompt,
          },
          {
            role: "user",
            content: userPrompt,
          },
        ],
        temperature: 0.7,
        max_tokens: 1000,
      });

      const simplified = toSecondPerson(response.choices[0].message.content);
      return {success: true, simplified};
    } catch (error) {
      console.error("Error simplifying text:", error);
      throw new Error("Failed to simplify text");
    }
  }
);

// 7. Upload file to Firebase Storage and return metadata
exports.uploadVisitSummaryFile = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "🔒 Authentication required. Please log in.");
      }

      const {fileName, fileData, appointmentDate, userProfile} = request.data;

      if (!fileName || !fileData) {
        throw new HttpsError("invalid-argument", "📄 Missing file data. Please select a PDF file.");
      }

      if (!appointmentDate) {
        throw new HttpsError("invalid-argument", "📅 Missing appointment date. Please select a date.");
      }

      // Validate file is PDF
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        throw new HttpsError("invalid-argument", "❌ Invalid file type. Please upload a PDF file.");
      }

      // Create storage path: visit_summaries/{userId}/{timestamp}_{fileName}
      const userId = request.auth.uid;
      const timestamp = Date.now();
      const storagePath = `visit_summaries/${userId}/${timestamp}_${fileName}`;
      
      const bucket = admin.storage().bucket();
      const file = bucket.file(storagePath);

      // Convert base64 to buffer if needed
      let fileBuffer;
      if (typeof fileData === 'string') {
        // Assume base64 encoded
        fileBuffer = Buffer.from(fileData, 'base64');
      } else {
        fileBuffer = Buffer.from(fileData);
      }

      // Upload to Storage
      console.log(`📤 Uploading file to ${storagePath}...`);
      await file.save(fileBuffer, {
        metadata: {
          contentType: 'application/pdf',
          metadata: {
            userId: userId,
            appointmentDate: appointmentDate,
            uploadedAt: new Date().toISOString(),
            userProfile: userProfile ? JSON.stringify(userProfile) : null,
          },
        },
      });

      // Make file publicly readable (or use signed URLs for security)
      await file.makePublic();

      console.log(`✅ File uploaded successfully: ${storagePath}`);

      // Save upload metadata to Firestore
      const uploadRef = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("file_uploads")
        .add({
          fileName: fileName,
          storagePath: storagePath,
          appointmentDate: appointmentDate,
          status: "uploaded",
          userProfile: userProfile,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      return {
        success: true,
        message: "📤 File uploaded successfully! Starting analysis...",
        storagePath: storagePath,
        uploadId: uploadRef.id,
        fileUrl: `https://storage.googleapis.com/${bucket.name}/${storagePath}`,
      };
    } catch (error) {
      console.error("❌ Error uploading file:", error);
      
      if (error instanceof HttpsError) {
        throw error;
      }
      
      // Provide user-friendly error messages with emojis
      if (error.code === 'storage/unauthorized') {
        throw new HttpsError("permission-denied", "🔒 Permission denied. Please check your account permissions.");
      } else if (error.code === 'storage/quota-exceeded') {
        throw new HttpsError("resource-exhausted", "💾 Storage quota exceeded. Please contact support.");
      } else if (error.message && error.message.includes("network")) {
        throw new HttpsError("unavailable", "🌐 Network error. Please check your connection and try again.");
      }
      
      throw new HttpsError("internal", `❌ Upload failed: ${error.message || "Unknown error"}`);
    }
  }
);

// 8. Storage trigger: Automatically process uploaded PDFs
// DISABLED: We're using direct function calls from the app instead to avoid duplicates
// This trigger is kept for reference but will not process files
exports.processUploadedVisitSummary = onObjectFinalized(
  {
    secrets: [openaiApiKey],
    region: "us-central1",
    bucket: "empower-health-watch.firebasestorage.app",
  },
  async (event) => {
    const filePath = event.data.name;
    const bucket = event.data.bucket;

    // Only process files in visit_summaries folder
    if (!filePath.startsWith('visit_summaries/')) {
      console.log(`⏭️ Skipping file outside visit_summaries: ${filePath}`);
      return;
    }

    // Only process PDFs
    if (!filePath.toLowerCase().endsWith('.pdf')) {
      console.log(`⏭️ Skipping non-PDF file: ${filePath}`);
      return;
    }

    // DISABLED: Skip all processing to prevent duplicates
    // The app now calls analyzeVisitSummaryPDF directly, so this trigger is not needed
    console.log(`⏭️ [DEBUG] Storage trigger DISABLED - file processing handled by direct function call: ${filePath}`);
    console.log(`⏭️ [DEBUG] Storage trigger would have processed: ${filePath}, but returning early to prevent duplicates`);
    return;

    console.log(`📄 Processing uploaded file: ${filePath}`);

    try {
      const bucketObj = admin.storage().bucket(bucket);
      const file = bucketObj.file(filePath);

      // Get file metadata
      const [metadata] = await file.getMetadata();
      const customMetadata = metadata.metadata || {};
      const userId = customMetadata.userId;
      const appointmentDate = customMetadata.appointmentDate;
      const userProfileStr = customMetadata.userProfile;

      if (!userId || !appointmentDate) {
        console.error("❌ Missing required metadata (userId or appointmentDate)");
        return;
      }

      // Download file
      console.log(`📥 Downloading file for processing...`);
      const [fileBuffer] = await file.download();

      // Extract text from PDF (using pdf-parse or similar)
      // For now, we'll need to use a PDF parsing library
      // Note: You may need to install pdf-parse: npm install pdf-parse
      let pdfText = '';
      try {
        // Try to use pdf-parse if available
        const pdfParse = require('pdf-parse');
        const pdfData = await pdfParse(fileBuffer);
        pdfText = pdfData.text;
      } catch (parseError) {
        console.error("❌ Error parsing PDF:", parseError);
        // Update status to error
        await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("file_uploads")
          .where("storagePath", "==", filePath)
          .get()
          .then((snapshot) => {
            snapshot.forEach((doc) => {
              doc.ref.update({
                status: "error",
                errorMessage: "❌ Could not extract text from PDF. The file might be image-based or encrypted.",
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            });
          });
        return;
      }

      if (!pdfText || pdfText.trim().length === 0) {
        throw new Error("📄 No text extracted from PDF");
      }

      console.log(`✅ Extracted ${pdfText.length} characters from PDF`);

      // Parse user profile if available
      let userProfile = null;
      if (userProfileStr) {
        try {
          userProfile = JSON.parse(userProfileStr);
        } catch (e) {
          console.warn("⚠️ Could not parse user profile metadata");
        }
      }

      // Get user's education level from profile if not in metadata
      let educationLevel = null;
      if (userProfile?.educationLevel) {
        educationLevel = userProfile.educationLevel;
      } else {
        // Try to get from user profile in Firestore
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          educationLevel = userData?.educationLevel || userData?.profile?.educationLevel;
        }
      }

      // Check if this file has already been processed by checking file_uploads status
      const uploadDocs = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("file_uploads")
        .where("storagePath", "==", filePath)
        .where("status", "in", ["completed", "analyzed"])
        .limit(1)
        .get();
      
      if (!uploadDocs.empty) {
        console.log(`⏭️ File ${filePath} has already been processed, skipping duplicate analysis`);
        return;
      }

      // Call the analysis function
      console.log(`🤖 Starting AI analysis...`);
      const analysisResult = await analyzeVisitSummaryPDF({
        pdfText, 
        appointmentDate, 
        educationLevel,
        userProfile,
        userId,
      });

      // Update upload status
      await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("file_uploads")
        .where("storagePath", "==", filePath)
        .get()
        .then((snapshot) => {
          snapshot.forEach((doc) => {
            doc.ref.update({
              status: "completed",
              summaryId: analysisResult.summaryId,
              processedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
        });

      console.log(`✅ Successfully processed file: ${filePath}`);
    } catch (error) {
      console.error(`❌ Error processing file ${filePath}:`, error);
      
      // Extract userId from path if possible
      const pathParts = filePath.split('/');
      if (pathParts.length >= 2) {
        const userId = pathParts[1];
        await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("file_uploads")
          .where("storagePath", "==", filePath)
          .get()
          .then((snapshot) => {
            snapshot.forEach((doc) => {
              doc.ref.update({
                status: "error",
                errorMessage: `❌ ${error.message || "Unknown error occurred during processing"}`,
                processedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            });
          });
      }
    }
  }
);

// ============================================================================
// VISIT SUMMARY ANALYSIS (shared by typed notes, text PDFs, scans and photos)
// ============================================================================
// All three entry points (analyzeVisitSummaryText, analyzeVisitSummaryPDF and
// the legacy summarizeAfterVisitPDF) produce the same JSON shape through Chat
// Completions. Text PDFs go through the text prompt; scanned PDFs and photos
// (which the app converts to a one-page PDF) go to a vision model as a file.
// The Assistants API that the PDF path used before was shut down by OpenAI in
// Aug 2026 and now returns 404.

const VISIT_SUMMARY_MODEL = "gpt-4o";
// Fewer non-whitespace characters than this means the PDF is a scan or photo.
const VISIT_SUMMARY_MIN_TEXT_CHARS = 200;
// Raw PDF cap. Base64 adds about a third, and OpenAI limits file input size.
const VISIT_SUMMARY_MAX_PDF_BYTES = 20 * 1024 * 1024;
// Cap on document text sent to the model so the prompt stays within limits.
const VISIT_SUMMARY_MAX_TEXT_CHARS = 60000;
// Per-request OpenAI timeout (the callables run with timeoutSeconds: 300).
const VISIT_SUMMARY_OPENAI_TIMEOUT_MS = 180000;

// Plain-language messages shown to the user (sent in HttpsError details.userMessage).
const VISIT_SUMMARY_MESSAGES = {
  unreadable_file: "We couldn't read that file. Try a clearer photo or paste the text instead.",
  unreadable_text: "We couldn't find visit details in that text. Please check it and try again.",
  too_large: "That file is too large. Try a smaller PDF, one clear photo, or paste the text instead.",
  file_not_found: "We couldn't find your uploaded file. Please try uploading it again.",
  busy: "We couldn't simplify this right now. Please try again in a moment.",
};

/** Error with a plain-language message that is safe to show to the user. */
class VisitSummaryUserError extends Error {
  constructor(code, reason, detail) {
    super(detail || VISIT_SUMMARY_MESSAGES[reason] || VISIT_SUMMARY_MESSAGES.busy);
    this.name = "VisitSummaryUserError";
    this.httpsCode = code;
    this.reason = reason;
    this.userMessage = VISIT_SUMMARY_MESSAGES[reason] || VISIT_SUMMARY_MESSAGES.busy;
  }
}

/**
 * Convert any error from the visit summary pipeline into an HttpsError whose
 * message is plain language. Details are logged server-side by the caller.
 * @param {Error} error
 * @param {string} unreadableReason reason to use when OpenAI rejects the input (400)
 * @return {HttpsError}
 */
function toVisitSummaryHttpsError(error, unreadableReason = "unreadable_file") {
  const make = (code, reason) => new HttpsError(code, VISIT_SUMMARY_MESSAGES[reason], {
    reason,
    userMessage: VISIT_SUMMARY_MESSAGES[reason],
  });
  if (error instanceof VisitSummaryUserError) {
    return make(error.httpsCode, error.reason);
  }
  if (error instanceof HttpsError) {
    return error;
  }
  const status = typeof error?.status === "number" ? error.status : null;
  if (status === 400) {
    // OpenAI could not use the document (corrupt PDF, unsupported content).
    return make("invalid-argument", unreadableReason);
  }
  if (status === 429) {
    return make("resource-exhausted", "busy");
  }
  const name = error?.name || "";
  const message = (error?.message || "").toLowerCase();
  if (name.includes("Timeout") || message.includes("timed out") || message.includes("timeout")) {
    return make("deadline-exceeded", "busy");
  }
  return make("internal", "busy");
}

function getVisitSummaryReadingLevel(educationLevel) {
  // Target ~5th grade for health literacy support (not diagnosis or care decisions)
  if (!educationLevel) return "about 5th grade";
  const level = educationLevel.toString();
  if (level.includes("Graduate") || level.includes("Bachelor")) {
    return "about 6th grade";
  }
  if (level.includes("High School") || level.includes("Some College")) {
    return "about 5th–6th grade";
  }
  return "about 5th grade";
}

/** Count of non-whitespace characters (used to tell text PDFs from scans). */
function countMeaningfulChars(text) {
  if (!text || typeof text !== "string") return 0;
  return text.replace(/\s+/g, "").length;
}

/**
 * Stable fingerprint of what the user submitted, used to catch accidental
 * double-submits (same date + same text or same file bytes).
 * @param {string} kind "text" or "pdf"
 * @param {string|Buffer} content
 * @return {string} hex sha256
 */
function computeVisitSourceHash(kind, content) {
  const hash = crypto.createHash("sha256");
  hash.update(`${kind}:`);
  if (Buffer.isBuffer(content)) {
    hash.update(content);
  } else {
    hash.update(String(content || "").replace(/\s+/g, " ").trim());
  }
  return hash.digest("hex");
}

/** Deterministic doc id so concurrent double-submits collide on create(). */
function visitSummaryDocId(calendarKey, sourceHash) {
  return `${calendarKey}_${sourceHash.substring(0, 24)}`;
}

/** Extract text from a PDF buffer. Returns "" when the PDF has no text layer. */
async function extractPdfText(pdfBuffer) {
  // Require the library entry directly (pdf-parse's index.js has a debug
  // branch that reads a test file when module.parent is missing).
  const pdfParse = require("pdf-parse/lib/pdf-parse.js");
  // pdf.js reads the underlying ArrayBuffer and ignores a Buffer's byteOffset,
  // so a pooled Node Buffer parses as garbage ("bad XRef entry"). Give it a
  // standalone copy. Fall back to the newer bundled pdf.js if the default fails.
  for (const version of [undefined, "v2.0.550"]) {
    try {
      const data = new Uint8Array(pdfBuffer.length);
      data.set(pdfBuffer);
      const pdfData = await pdfParse(data, version ? {version} : undefined);
      if (pdfData && typeof pdfData.text === "string") return pdfData.text;
    } catch (e) {
      console.warn(`⚠️ pdf-parse (${version || "default"}) could not read the PDF: ${e.message}`);
    }
  }
  console.warn("⚠️ No text layer extracted from PDF, will use the vision model");
  return "";
}

/**
 * Build the system + user prompts for visit summary analysis.
 * @return {{systemPrompt: string, userPrompt: string, readingLevel: string, trimester: string}}
 */
function buildVisitSummaryPrompts({documentText, educationLevel, userProfile}) {
  // Extract user context with safe defaults
  const trimester = (userProfile?.pregnancyStage || userProfile?.trimester || "Unknown").toString();
  const concerns = Array.isArray(userProfile?.concerns) ? userProfile.concerns : [];
  const birthPlanPreferences = Array.isArray(userProfile?.birthPlanPreferences) ? userProfile.birthPlanPreferences : [];
  const culturalPreferences = Array.isArray(userProfile?.culturalPreferences) ? userProfile.culturalPreferences : [];
  const traumaInformedPreferences = Array.isArray(userProfile?.traumaInformedPreferences) ? userProfile.traumaInformedPreferences : [];
  const learningStyle = (userProfile?.learningStyle || "visual").toString();
  const insuranceType = (userProfile?.insuranceType || "").toString();
  const readingLevel = getVisitSummaryReadingLevel(educationLevel);

  const systemPrompt = `You are a culturally affirming, trauma-informed health literacy educator for EmpowerHealth Watch (maternal health).

Your role is strictly to help the user READ and UNDERSTAND paperwork or visit-related text in plain language at a ${readingLevel} reading level.

You do NOT diagnose, treat, or interpret clinical findings as medical truth. You do not replace a clinician. Frame everything as understanding what the document or visit notes say, questions to ask the care team, and practical next steps, not as definitive medical advice.

Accept and work from: after-visit summaries, discharge instructions, provider or nurse notes, printed visit recaps, and similar documents, even if the text is partial or informal. Documents may be scanned pages or phone photos of paperwork; read them carefully.

Avoid casual terms like "momma".

${SECOND_PERSON_VOICE_RULE} This applies to every string value in the JSON (summary fields, todos, learning modules, notes, tips).

Your entire reply must be one JSON object only: no apologies, no "It seems…", no markdown fences, no text before or after the JSON. Only if the document has no readable content at all (blank, completely blurry, or not a document), reply with exactly {"unreadable": true}.`;

  const userPrompt = `From the following document or visit text, produce JSON that helps the user understand what they have in front of them.

Explain medical terms simply. Include "tap-to-explain" style entries in keyMedicalTerms (term + short explanation). Prefer short sentences and short paragraphs.

Tailor tone to trimester (${trimester}), concerns (${JSON.stringify(concerns)}), birth preferences (${JSON.stringify(birthPlanPreferences)}).

Document / visit text:
${documentText}

User Context:
- Trimester: ${trimester}
- Stated Concerns: ${concerns.join(", ") || "None specified"} (pain, safety, anxiety, postpartum issues)
- Birth Plan Preferences: ${birthPlanPreferences.join(", ") || "None specified"}
- Cultural/Trauma-Informed Preferences: ${culturalPreferences.concat(traumaInformedPreferences).join(", ") || "None specified"}
- Learning Style: ${learningStyle} (audio, visual, short summaries)
- Insurance Type: ${insuranceType || "Not specified - use insurance-agnostic guidance"}

Return a JSON object with the following structure:
{
  "summary": {
    "whatThisMeans": "1–3 short paragraphs at ${readingLevel} level, written to you: in plain words, what this visit or document is mainly about (literacy support only, not a diagnosis)",
    "importantNextSteps": "Plain language, written to you: what you need to do next, follow-ups, scheduling; separate from medication list (e.g. \"You were referred to a specialist. Call to schedule within 2 weeks.\")",
    "howBabyIsDoing": "If applicable: brief plain-language note on fetal/baby-related content; else empty string",
    "howYouAreDoing": "If applicable: brief plain-language note on your health topics mentioned, written to you; else empty string",
    "keyMedicalTerms": [
      {"term": "term name", "explanation": "plain language explanation for tap-to-read"}
    ],
    "nextSteps": "May repeat or align with importantNextSteps; plain language only",
    "questionsToAsk": [
      "Question 1",
      "Question 2"
    ],
    "visitNotes": [
      "Short affirming reminder or takeaway from this visit (1–2 sentences)",
      "Another supportive note for you to remember (e.g. \"You asked clear questions about your care today.\")"
    ],
    "empowermentTips": [
      "Advocacy tip 1",
      "Advocacy tip 2"
    ],
    "newDiagnoses": [
      {"diagnosis": "name", "explanation": "plain language explanation"}
    ],
    "testsProcedures": [
      {"name": "test/procedure name", "explanation": "what to expect", "whyNeeded": "reason"}
    ],
    "medications": [
      {"name": "medication name", "purpose": "why prescribed", "instructions": "how to take"}
    ],
    "followUpInstructions": "Follow-up care instructions written to you (e.g. \"You were referred to a specialist. Your next annual exam is in one year.\")",
    "providerCommunicationStyle": "Description of communication style if flagged (rushed, unclear, dismissive, etc.)",
    "emotionalMarkers": ["confused", "scared", "unsure", etc. if detected],
    "advocacyMoments": ["Your provider mentioned XYZ without explaining it", etc.],
    "contradictions": ["Any contradictions or missing explanations"]
  },
  "todos": [
    {"title": "Schedule your follow-up ultrasound", "description": "Your provider wants to check your baby's growth in 4 weeks. Call the office to book it.", "category": "advocacy|followup|medication|test"},
    ...
  ],
  "learningModules": [
    {
      "title": "Module title",
      "description": "Why this matters for you",
      "reason": "Based on what came up at your visit",
      "content": {
        "whatThisIs": "Simple explanation of what this is",
        "whyItMatters": "Why this matters for your health - explain the 'why' behind the 'what' in detail",
        "whatToExpect": "Step-by-step what to expect",
        "whatYouCanAsk": ["Advocacy question 1", "Advocacy question 2", "Advocacy question 3"],
        "risksOptionsAlternatives": "Balanced information about risks, options, and alternatives",
        "whenToSeekHelp": "When to seek medical help",
        "empowermentConnection": "How this connects to your empowerment",
        "keyPoints": ["Key point 1", "Key point 2", "Key point 3"],
        "yourRights": ["Your right 1", "Your right 2"],
        "insuranceNotes": "Insurance-specific information if applicable, otherwise insurance-agnostic guidance"
      }
    },
    ...
  ],
  "redFlags": [
    {"type": "mistreatment|unclear|dismissive", "description": "What was flagged"}
  ]
}

CRITICAL REQUIREMENTS:
0. Fill **whatThisMeans** and **importantNextSteps** clearly; they drive the main "What this means" and "Important next steps" sections in the app.
1. Explain key medical terms mentioned: add at least 3–8 items to keyMedicalTerms when the text includes clinical words (for tap-to-explain in the app).
2. Break down next steps in plain language: importantNextSteps and nextSteps should be consistent and actionable (who to call, what to schedule), not diagnostic conclusions.
3. **questionsToAsk**: At least 4 specific questions for the next visit (advocacy-focused); shown in the visit detail "Questions to ask" card in the app.
4. **visitNotes**: 2–4 short, affirming strings for the visit detail "Notes" card: warm reminders of what mattered, strengths, or gentle encouragement (not the same as empowermentTips; visitNotes are reflective, tips are action-oriented).
5. Provide empowerment + advocacy tips based on that specific encounter - add to empowermentTips AND create todos
6. Reinforce understanding of any new diagnoses, tests, or procedures - add to newDiagnoses/testsProcedures AND create learning modules
7. Flag potential mistreatment or unclear communication - add to redFlags
8. Tests or procedures recommended - add to testsProcedures AND create learning modules
9. Medications discussed - add to medications AND create learning modules
10. Follow-up instructions - turn into todos
11. Provider communication style (e.g., rushed, unclear, dismissive, if flagged by user or sentiment analysis) - add to providerCommunicationStyle AND create learning module
12. Emotional markers (mom tapped "confused," "scared," or "unsure") - add to emotionalMarkers
13. Advocacy moments (e.g., "Your provider mentioned XYZ without explaining it") - add to advocacyMoments
14. Any contradictions or missing explanations - add to contradictions AND create learning modules to bridge gap

TODOS: Create todos for:
- Empowerment/advocacy tips (category: "advocacy")
- Follow-up instructions (category: "followup")
- Medications to take (category: "medication")
- Tests to schedule (category: "test")
Each todo is a short plain-language next step written to her as "you": "title" is a short action that starts with a verb (8 words or fewer); "description" is a 1-2 sentence summary under 30 words saying what to do and why (e.g. "You were referred to a heart specialist. Call to book a visit in the next 2 weeks."). Keep extra clinical detail out of todos; it belongs in the summary or learning modules.

LEARNING MODULES: Create DETAILED, comprehensive learning modules (not high-level) for new diagnoses, tests/procedures discussed, medications, provider communication issues, contradictions/missing explanations.

Each learning module MUST follow this structure (in its "content" object) and be DETAILED:
1. **What This Is (Simple Explanation)** - Clear, plain-language explanation
2. **Why It Matters for Your Health** - Explain the "why" behind the "what" - why this matters, why it's important, what happens if ignored. Be detailed and specific.
3. **What to Expect** - Step-by-step, detailed guidance on what will happen
4. **What You Can Ask or Say** - At least 3 specific advocacy questions/prompts you can use (written in her own voice, e.g. "Can you explain why I need this?")
5. **Risks, Options, and Alternatives** - Balanced, non-fearful information
6. **When to Seek Medical Help** - Clear guidance on when to call provider
7. **How This Connects to Your Empowerment** - How this topic relates to self-advocacy and empowerment
8. **Key Points** - 3-5 key takeaways
9. **Your Rights** - 2-3 specific rights related to this topic
10. **Insurance Notes** - ${insuranceType ? `Tailor information for ${insuranceType} insurance. Include coverage considerations, what's typically covered, and any cost considerations.` : "Provide insurance-agnostic guidance that applies regardless of insurance type."}

TONE & VOICE REQUIREMENTS:
- Warm, supportive, nonjudgmental language
- Sound like: "Here's what this test means and why it matters. You deserve clear explanations and the chance to ask questions."
- Trauma-informed (acknowledge possible fears, past negative experiences)
- Emphasize: Your rights, Your choices, Your voice
- Cultural responsiveness (acknowledge mistrust, bias, communication issues Black mothers may face)
- Avoid: Fear-based language, provider-blaming, cultural stereotypes, overly technical explanations, long paragraphs
- Use: Short paragraphs, bulleted lists, defined terms

Brand Voice: "Your Health. Your Voice. Your Empowerment."

Use trauma-informed, culturally affirming language throughout. Make all explanations accessible at ${readingLevel} reading level. Return ONLY valid JSON.`;

  return {systemPrompt, userPrompt, readingLevel, trimester};
}

/** Placeholder for the "Document / visit text" slot when the PDF is attached as a file. */
const VISIT_SUMMARY_ATTACHED_PDF_TEXT =
  "(The document is attached to this message as a PDF file. It may be a scanned page or a phone photo of paperwork. Read every page carefully and work only from what it says.)";

/**
 * Chat Completions user content for the vision path: the PDF as a file
 * content part followed by the instructions. Matches OpenAI's documented
 * file input format: {type: "file", file: {filename, file_data: "data:application/pdf;base64,..."}}.
 */
function buildVisitSummaryPdfUserContent({pdfBuffer, filename, userPrompt}) {
  return [
    {
      type: "file",
      file: {
        filename: filename || "visit_summary.pdf",
        file_data: `data:application/pdf;base64,${pdfBuffer.toString("base64")}`,
      },
    },
    {type: "text", text: userPrompt},
  ];
}

/** Request body for the visit summary Chat Completions call. */
function buildVisitSummaryChatRequest({systemPrompt, userContent}) {
  return {
    model: VISIT_SUMMARY_MODEL,
    messages: [
      {role: "system", content: systemPrompt},
      {role: "user", content: userContent},
    ],
    temperature: 0.7,
    max_tokens: 8000,
    response_format: {type: "json_object"},
  };
}

/**
 * Parse and validate the model's JSON reply, then apply the second-person
 * safety net. Throws VisitSummaryUserError when the model says the document
 * is unreadable.
 */
function parseVisitSummaryResponse(responseContent, unreadableReason) {
  let parsedResponse;
  try {
    parsedResponse = parseJsonFromOpenAIContent(responseContent);
  } catch (parseError) {
    console.error("❌ JSON parse error:", parseError);
    console.error("Response content (start):", String(responseContent).substring(0, 500));
    throw new Error("Failed to parse AI response: " + parseError.message);
  }

  if (parsedResponse && parsedResponse.unreadable === true && !parsedResponse.summary) {
    throw new VisitSummaryUserError("invalid-argument", unreadableReason, "Model reported the document as unreadable");
  }

  if (!parsedResponse.summary || typeof parsedResponse.summary !== "object" || Array.isArray(parsedResponse.summary)) {
    throw new Error("AI JSON must include a \"summary\" object");
  }

  // Safety net: rewrite any third-person "the patient" phrasing in woman-facing
  // fields (summary, todos/next steps, learning modules) to second person.
  applySecondPersonToVisitAnalysis(parsedResponse);
  return parsedResponse;
}

async function requestVisitSummaryAnalysis({systemPrompt, userContent, unreadableReason}) {
  console.log(`🤖 Calling OpenAI (${VISIT_SUMMARY_MODEL}) for visit summary analysis (${Array.isArray(userContent) ? "PDF file input" : "text input"})...`);
  const openai = getOpenAIClient(openaiApiKey.value());
  const response = await openai.chat.completions.create(
    buildVisitSummaryChatRequest({systemPrompt, userContent}),
    {timeout: VISIT_SUMMARY_OPENAI_TIMEOUT_MS, maxRetries: 1},
  );

  const choice = response && Array.isArray(response.choices) ? response.choices[0] : null;
  const responseContent = choice && choice.message ? choice.message.content : null;
  if (!responseContent) {
    console.error("❌ OpenAI returned no content", {
      finishReason: choice?.finish_reason,
      refusal: choice?.message?.refusal ? "present" : "none",
    });
    throw new Error("OpenAI API returned an empty response");
  }
  if (choice.finish_reason === "length") {
    console.warn("⚠️ OpenAI response hit max_tokens; JSON may be truncated");
  }
  console.log(`✅ Received response (${responseContent.length} chars)`);
  return parseVisitSummaryResponse(responseContent, unreadableReason);
}

/** Same response shape as a fresh analysis, built from a stored summary doc. */
function visitSummaryResultFromDoc(snap) {
  const data = snap.data() || {};
  const learningModules = Array.isArray(data.learningModules) ? data.learningModules : [];
  let summary = typeof data.summary === "string" ? data.summary : "";
  if (!summary.trim()) {
    summary = formatSummaryForDisplay(data.summaryData || data.summary, learningModules);
  }
  return {
    summaryId: snap.id,
    summary,
    todos: Array.isArray(data.todos) ? data.todos : [],
    learningModules,
    redFlags: Array.isArray(data.redFlags) ? data.redFlags : [],
  };
}

function visitSummariesCollection(userId) {
  return admin.firestore().collection("users").doc(userId).collection("visit_summaries");
}

/**
 * Accidental double-submit guard: the same text or file for the same
 * appointment date already has a summary. A different note for a date that
 * already has a summary is NOT a duplicate and gets its own summary.
 * @return {Promise<object|null>} full result with duplicate: true, or null
 */
async function findDuplicateVisitSummary({userId, appointmentDate, sourceHash}) {
  if (!sourceHash) return null;
  const {y, m, d} = parseAppointmentCalendarParts(appointmentDate);
  const docId = visitSummaryDocId(calendarYmdKey(y, m, d), sourceHash);
  const snap = await visitSummariesCollection(userId).doc(docId).get();
  if (!snap.exists) return null;
  const result = visitSummaryResultFromDoc(snap);
  if (!result.summary || !result.summary.trim()) return null;
  console.log(`♻️ Same source already summarized for this date, returning existing summary ${snap.id}`);
  return {...result, duplicate: true};
}

/**
 * Save a parsed analysis: visit_summaries doc + learning_tasks for todos and
 * learning modules. Uses a deterministic doc id (date + source hash) with
 * create() so a concurrent double-submit returns the first summary instead of
 * writing a second one.
 */
async function saveVisitSummaryAnalysis({
  userId,
  appointmentDate,
  parsedResponse,
  readingLevel,
  trimester,
  sourceHash,
  docFields = {},
}) {
  // Same **calendar** date as the picker (YYYY-MM-DD from client). Store noon UTC so US TZs don't show prior day.
  const {y, m, d} = parseAppointmentCalendarParts(appointmentDate);
  const calendarKey = calendarYmdKey(y, m, d);
  const appointmentTimestamp = firestoreTimestampFromCalendarYmd(y, m, d);
  console.log(`📅 Appointment calendar key: ${calendarKey} → Firestore: ${appointmentTimestamp.toDate().toISOString()} (original: ${appointmentDate})`);

  const formattedSummary = formatSummaryForDisplay(
    parsedResponse.summary,
    parsedResponse.learningModules || []
  );
  if (typeof formattedSummary !== "string" || !formattedSummary.trim()) {
    throw new Error("Could not build visit summary text from AI output");
  }

  const summaries = visitSummariesCollection(userId);
  const summaryRef = sourceHash ?
    summaries.doc(visitSummaryDocId(calendarKey, sourceHash)) :
    summaries.doc();

  try {
    await summaryRef.create({
      ...docFields,
      appointmentDate: appointmentTimestamp,
      summary: formattedSummary,
      summaryData: parsedResponse.summary,
      todos: parsedResponse.todos || [],
      learningModules: parsedResponse.learningModules || [],
      redFlags: parsedResponse.redFlags || [],
      readingLevel: readingLevel,
      sourceHash: sourceHash || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    const alreadyExists = e && (e.code === 6 || e.code === "already-exists" ||
      /already exists/i.test(e.message || ""));
    if (alreadyExists) {
      const existing = await summaryRef.get();
      if (existing.exists) {
        console.log(`♻️ Concurrent submit already created summary ${summaryRef.id}, returning it`);
        return {...visitSummaryResultFromDoc(existing), duplicate: true};
      }
    }
    throw e;
  }
  console.log(`✅ Created visit summary ${summaryRef.id}`);

  // Create todos
  if (parsedResponse.todos && Array.isArray(parsedResponse.todos) && parsedResponse.todos.length > 0) {
    const todosBatch = admin.firestore().batch();
    parsedResponse.todos.forEach((todo) => {
      if (!todo || !todo.title) return;
      const todoRef = admin.firestore().collection("learning_tasks").doc();
      todosBatch.set(todoRef, {
        userId: userId,
        title: todo.title.toString(),
        description: (todo.description || "").toString(),
        category: (todo.category || "followup").toString(),
        visitSummaryId: summaryRef.id,
        isGenerated: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completed: false,
      });
    });
    await todosBatch.commit();
  }

  // Create learning modules
  if (parsedResponse.learningModules && Array.isArray(parsedResponse.learningModules) && parsedResponse.learningModules.length > 0) {
    const modulesBatch = admin.firestore().batch();
    parsedResponse.learningModules.forEach((module) => {
      if (!module || !module.title) return;
      const moduleRef = admin.firestore().collection("learning_tasks").doc();
      modulesBatch.set(moduleRef, {
        userId: userId,
        title: module.title.toString(),
        description: (module.description || module.reason || "").toString(),
        content: module.content || null, // Store detailed content structure
        trimester: trimester,
        isGenerated: true,
        visitSummaryId: summaryRef.id,
        moduleType: "visit_based",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await modulesBatch.commit();
  }

  return {
    summaryId: summaryRef.id,
    summary: formattedSummary,
    todos: parsedResponse.todos || [],
    learningModules: parsedResponse.learningModules || [],
    redFlags: parsedResponse.redFlags || [],
    duplicate: false,
  };
}

/**
 * Analyze a visit document and save it. Pass either `documentText` (typed
 * notes or text extracted from a PDF) or `pdfFile` ({buffer, filename}) for a
 * scanned PDF / photo, which goes to the vision model as a file.
 * @return {Promise<{summaryId, summary, todos, learningModules, redFlags, duplicate}>}
 */
async function analyzeAndSaveVisitSummary({
  userId,
  appointmentDate,
  educationLevel,
  userProfile,
  documentText,
  pdfFile,
  sourceHash,
  unreadableReason = "unreadable_text",
  docFields = {},
}) {
  const duplicate = await findDuplicateVisitSummary({userId, appointmentDate, sourceHash});
  if (duplicate) return duplicate;

  let prompts;
  let userContent;
  if (pdfFile) {
    prompts = buildVisitSummaryPrompts({
      documentText: VISIT_SUMMARY_ATTACHED_PDF_TEXT,
      educationLevel,
      userProfile,
    });
    userContent = buildVisitSummaryPdfUserContent({
      pdfBuffer: pdfFile.buffer,
      filename: pdfFile.filename,
      userPrompt: prompts.userPrompt,
    });
  } else {
    const text = String(documentText || "").substring(0, VISIT_SUMMARY_MAX_TEXT_CHARS);
    prompts = buildVisitSummaryPrompts({documentText: text, educationLevel, userProfile});
    userContent = prompts.userPrompt;
  }

  const parsedResponse = await requestVisitSummaryAnalysis({
    systemPrompt: prompts.systemPrompt,
    userContent,
    unreadableReason,
  });

  return saveVisitSummaryAnalysis({
    userId,
    appointmentDate,
    parsedResponse,
    readingLevel: prompts.readingLevel,
    trimester: prompts.trimester,
    sourceHash,
    docFields,
  });
}

// Helper used by analyzeVisitSummaryText, summarizeAfterVisitPDF and the
// (disabled) storage trigger: analyze plain text and save the summary.
async function analyzeVisitSummaryPDF({pdfText, appointmentDate, educationLevel, userProfile, userId}) {
  console.log(`🟢 analyzeVisitSummaryPDF helper called`, {
    userId: userId,
    appointmentDate: appointmentDate,
    pdfTextLength: pdfText?.length || 0,
    hasEducationLevel: !!educationLevel,
    hasUserProfile: !!userProfile,
  });
  return analyzeAndSaveVisitSummary({
    userId,
    appointmentDate,
    educationLevel,
    userProfile,
    documentText: pdfText,
    sourceHash: computeVisitSourceHash("text", pdfText),
    unreadableReason: "unreadable_text",
    docFields: {
      originalText: String(pdfText || "").substring(0, 10000),
      sourceType: "text",
    },
  });
}

// 9. Analyze an uploaded visit summary PDF (text PDF, scan, or photo converted to PDF)
exports.analyzeVisitSummaryPDF = onCall(
  {secrets: [openaiApiKey], timeoutSeconds: 300, memory: "1GiB"},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please sign in again, then try once more.");
    }
    const userId = request.auth.uid;

    const {
      storagePath,
      downloadUrl,
      appointmentDate,
      educationLevel,
      userProfile,
    } = request.data || {};

    console.log(`🔵 analyzeVisitSummaryPDF called`, {
      userId,
      storagePath: storagePath ? `${String(storagePath).substring(0, 60)}...` : "missing",
      downloadUrl: downloadUrl ? "present" : "missing",
      appointmentDate,
      hasEducationLevel: !!educationLevel,
      hasUserProfile: !!userProfile,
    });

    if (!storagePath || typeof storagePath !== "string") {
      throw new HttpsError("invalid-argument", VISIT_SUMMARY_MESSAGES.file_not_found, {
        reason: "file_not_found",
        userMessage: VISIT_SUMMARY_MESSAGES.file_not_found,
      });
    }
    // Only read files from the caller's own upload folder.
    if (!storagePath.startsWith(`visit_summaries/${userId}/`) || storagePath.includes("..")) {
      throw new HttpsError("permission-denied", "You can only summarize files you uploaded.");
    }
    if (!appointmentDate) {
      throw new HttpsError("invalid-argument", "Please choose your appointment date first.");
    }

    try {
      // Download PDF from Firebase Storage
      console.log(`📥 Downloading PDF from storage: ${storagePath}`);
      const file = admin.storage().bucket().file(storagePath);
      const [exists] = await file.exists();
      if (!exists) {
        throw new VisitSummaryUserError("not-found", "file_not_found", `PDF not found at ${storagePath}`);
      }
      const [pdfBuffer] = await file.download();
      console.log(`✅ Downloaded PDF: ${pdfBuffer.length} bytes`);
      if (pdfBuffer.length > VISIT_SUMMARY_MAX_PDF_BYTES) {
        throw new VisitSummaryUserError("invalid-argument", "too_large", `PDF is ${pdfBuffer.length} bytes`);
      }

      const sourceHash = computeVisitSourceHash("pdf", pdfBuffer);
      const docFields = {
        storagePath: storagePath,
        downloadUrl: downloadUrl || null,
      };

      // Cheap check before any parsing or AI call: same file, same date.
      const duplicate = await findDuplicateVisitSummary({userId, appointmentDate, sourceHash});
      let result = duplicate;
      if (!result) {
        const extractedText = await extractPdfText(pdfBuffer);
        const meaningfulChars = countMeaningfulChars(extractedText);
        const useText = meaningfulChars >= VISIT_SUMMARY_MIN_TEXT_CHARS;
        console.log(`📄 Extracted ${meaningfulChars} non-whitespace chars from PDF → ${useText ? "text analysis" : "vision (PDF file input)"}`);

        result = await analyzeAndSaveVisitSummary({
          userId,
          appointmentDate,
          educationLevel,
          userProfile,
          // Redact obvious identifiers before sending text, as the typed-notes path does.
          documentText: useText ? redactPHI(extractedText) : undefined,
          pdfFile: useText ? undefined : {buffer: pdfBuffer, filename: "visit_summary.pdf"},
          sourceHash,
          unreadableReason: "unreadable_file",
          docFields: {
            ...docFields,
            sourceType: useText ? "pdf_text" : "pdf_vision",
          },
        });
      }

      console.log(`✅ Visit summary ready: ${result.summaryId} (duplicate: ${!!result.duplicate})`);
      return {
        success: true,
        summaryId: result.summaryId,
        summary: result.summary,
        todos: result.todos || [],
        learningModules: result.learningModules || [],
        redFlags: result.redFlags || [],
        duplicate: !!result.duplicate,
      };
    } catch (error) {
      console.error("❌ Error in analyzeVisitSummaryPDF:", {
        name: error?.name,
        message: error?.message,
        status: error?.status,
        reason: error?.reason,
      });
      console.error("Error stack:", error?.stack);
      throw toVisitSummaryHttpsError(error, "unreadable_file");
    }
  }
);

// 10. After-Visit Summary - Summarize uploaded PDF with specific structure (kept for backward compatibility)
exports.summarizeAfterVisitPDF = onCall(
  {secrets: [openaiApiKey], timeoutSeconds: 300},
  async (request) => {
    try {
      if (!request.auth) {
        console.error("Authentication error: User not authenticated");
        throw new Error("User must be authenticated");
      }

      console.log("Function called with data:", {
        hasPdfText: !!request.data.pdfText,
        pdfTextLength: request.data.pdfText?.length || 0,
        appointmentDate: request.data.appointmentDate,
        hasUserProfile: !!request.data.userProfile,
      });

      const {
        pdfText, 
        appointmentDate, 
        educationLevel,
        userProfile // Include user profile data
      } = request.data;

      // Validate required fields
      if (!pdfText || typeof pdfText !== 'string' || pdfText.trim().length === 0) {
        console.error("❌ Validation error: pdfText is missing or empty");
        throw new HttpsError("invalid-argument", "📄 PDF text is required and cannot be empty");
      }

      if (!appointmentDate) {
        console.error("❌ Validation error: appointmentDate is missing");
        throw new HttpsError("invalid-argument", "📅 Appointment date is required");
      }

      // Extract user context with safe defaults
      const trimester = (userProfile?.pregnancyStage || userProfile?.trimester || "Unknown").toString();
      const concerns = Array.isArray(userProfile?.concerns) ? userProfile.concerns : [];
      const birthPlanPreferences = Array.isArray(userProfile?.birthPlanPreferences) ? userProfile.birthPlanPreferences : [];
      const culturalPreferences = Array.isArray(userProfile?.culturalPreferences) ? userProfile.culturalPreferences : [];
      const traumaInformedPreferences = Array.isArray(userProfile?.traumaInformedPreferences) ? userProfile.traumaInformedPreferences : [];
      const learningStyle = (userProfile?.learningStyle || "visual").toString();

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

      // Use the shared analysis function
      const analysisResult = await analyzeVisitSummaryPDF({
        pdfText,
        appointmentDate,
        educationLevel,
        userProfile,
        userId: request.auth.uid,
      });

      console.log("✅ Function completed successfully");
      return {
        success: true, 
        summary: analysisResult.summary,
        todos: analysisResult.todos,
        learningModules: analysisResult.learningModules,
        redFlags: analysisResult.redFlags,
        summaryId: analysisResult.summaryId,
        duplicate: !!analysisResult.duplicate,
      };
    } catch (error) {
      console.error("❌ Error in summarizeAfterVisitPDF:", error);
      console.error("Error stack:", error.stack);
      console.error("Error message:", error.message);

      // Provide more specific error messages with emojis
      if (error instanceof HttpsError) {
        throw error;
      }
      if (error instanceof VisitSummaryUserError || typeof error?.status === "number") {
        throw toVisitSummaryHttpsError(error, "unreadable_text");
      }

      if (error.message && error.message.includes("authentication")) {
        throw new HttpsError("unauthenticated", "🔒 Authentication required. Please log in.");
      } else if (error.message && (error.message.includes("required") || error.message.includes("missing"))) {
        throw new HttpsError("invalid-argument", `❌ ${error.message}`);
      } else if (error.message && error.message.includes("OpenAI") || error.message.includes("API")) {
        throw new HttpsError("internal", "🤖 AI service error. Please try again in a moment.");
      } else {
        throw new HttpsError("internal", `❌ Analysis failed: ${error.message || "Unknown error occurred"}`);
      }
    }
  }
);

// Helper function to format summary for display (matches image format)
function formatSummaryForDisplay(summary, learningModules = []) {
  if (summary == null || typeof summary !== "object" || Array.isArray(summary)) {
    return typeof summary === "string" ? summary : "";
  }
  let formatted = "";

  const whatMeansRaw = summary.whatThisMeans && String(summary.whatThisMeans).trim();
  const legacyBabyYou = [summary.howBabyIsDoing, summary.howYouAreDoing].filter(Boolean).join("\n\n");
  if (whatMeansRaw) {
    formatted += `## What This Means\n${whatMeansRaw}\n\n`;
  } else if (legacyBabyYou) {
    if (summary.howBabyIsDoing) {
      formatted += `## How Your Baby Is Doing\n${summary.howBabyIsDoing}\n\n`;
    }
    if (summary.howYouAreDoing) {
      formatted += `## How You Are Doing\n${summary.howYouAreDoing}\n\n`;
    }
  }

  const nextParts = [];
  if (summary.importantNextSteps && String(summary.importantNextSteps).trim()) {
    nextParts.push(String(summary.importantNextSteps).trim());
  }
  if (summary.nextSteps && String(summary.nextSteps).trim()) {
    nextParts.push(String(summary.nextSteps).trim());
  }
  if (summary.followUpInstructions && String(summary.followUpInstructions).trim()) {
    nextParts.push(String(summary.followUpInstructions).trim());
  }
  if (summary.empowermentTips && summary.empowermentTips.length > 0) {
    nextParts.push(...summary.empowermentTips.map((t) => String(t)));
  }
  if (nextParts.length > 0) {
    formatted += `## Important Next Steps\n${nextParts.join("\n\n")}\n\n`;
  } else {
    // Legacy: single "Actions To Take" blob (includes meds) for older AI output
    const actionsToTake = [];
    if (summary.nextSteps) actionsToTake.push(summary.nextSteps);
    if (summary.followUpInstructions) actionsToTake.push(summary.followUpInstructions);
    if (summary.empowermentTips && summary.empowermentTips.length > 0) {
      actionsToTake.push(...summary.empowermentTips);
    }
    if (summary.medications && summary.medications.length > 0) {
      summary.medications.forEach((med) => {
        let text = `Continue taking ${med.name}`;
        if (med.purpose) text += ` (${med.purpose})`;
        if (med.instructions) text += `. ${med.instructions}`;
        actionsToTake.push(text);
      });
    }
    if (actionsToTake.length > 0) {
      formatted += `## Actions To Take\n${actionsToTake.join(" ")}\n\n`;
    }
  }

  if (summary.medications && summary.medications.length > 0) {
    formatted += `## Medications Mentioned\n`;
    summary.medications.forEach((med) => {
      let line = `**${med.name || "Medication"}**`;
      if (med.purpose) line += `: ${med.purpose}`;
      if (med.instructions) line += `. ${med.instructions}`;
      formatted += `${line}\n`;
    });
    formatted += `\n`;
  }

  // Suggested Learning Topics (from learning modules)
  if (learningModules && learningModules.length > 0) {
    formatted += `## Suggested Learning Topics\n`;
    learningModules.forEach((module, index) => {
      const reason = module.reason || module.description || "This is important based on your visit.";
      formatted += `${index + 1}. ${module.title} (${reason})\n`;
    });
    formatted += `\n`;
  }

  // Key Medical Terms (tap-to-explain in app)
  if (summary.keyMedicalTerms && summary.keyMedicalTerms.length > 0) {
    formatted += `## Key Medical Terms (tap to read)\n`;
    summary.keyMedicalTerms.forEach((term) => {
      formatted += `**${term.term}**: ${term.explanation}\n`;
    });
    formatted += `\n`;
  }

  // Questions to Ask
  if (summary.questionsToAsk && summary.questionsToAsk.length > 0) {
    formatted += `## Questions to Ask\n`;
    summary.questionsToAsk.forEach((q, i) => {
      formatted += `${i + 1}. ${q}\n`;
    });
    formatted += `\n`;
  }

  // Affirming visit notes (visit detail "Notes" card)
  if (summary.visitNotes && summary.visitNotes.length > 0) {
    formatted += `## Notes\n`;
    summary.visitNotes.forEach((n) => {
      if (n && String(n).trim()) {
        formatted += `- ${String(n).trim()}\n`;
      }
    });
    formatted += `\n`;
  }
  
  // New Diagnoses Explained
  if (summary.newDiagnoses && summary.newDiagnoses.length > 0) {
    formatted += `## New Diagnoses Explained\n`;
    summary.newDiagnoses.forEach(diag => {
      formatted += `**${diag.diagnosis}**: ${diag.explanation}\n`;
    });
    formatted += `\n`;
  }
  
  // Tests & Procedures Discussed
  if (summary.testsProcedures && summary.testsProcedures.length > 0) {
    formatted += `## Tests & Procedures Discussed\n`;
    summary.testsProcedures.forEach(test => {
      formatted += `**${test.name}**: ${test.explanation}\n`;
      if (test.whyNeeded) {
        formatted += `   *Why needed: ${test.whyNeeded}*\n`;
      }
    });
    formatted += `\n`;
  }
  
  // Provider Communication Notes
  if (summary.providerCommunicationStyle) {
    formatted += `## Provider Communication Notes\n${summary.providerCommunicationStyle}\n\n`;
  }
  
  // Advocacy Moments
  if (summary.advocacyMoments && summary.advocacyMoments.length > 0) {
    formatted += `## Advocacy Moments\n`;
    summary.advocacyMoments.forEach((moment, i) => {
      formatted += `${i + 1}. ${moment}\n`;
    });
    formatted += `\n`;
  }
  
  // Important Notes (contradictions)
  if (summary.contradictions && summary.contradictions.length > 0) {
    formatted += `## Important Notes\n`;
    summary.contradictions.forEach((contradiction, i) => {
      formatted += `${i + 1}. ${contradiction}\n`;
    });
    formatted += `\n`;
  }
  
  return formatted;
}

// ============================================================================
// HIPAA COMPLIANCE UTILITIES
// ============================================================================

// PHI Redaction Utility - Remove PII/PHI before sending to AI
function redactPHI(text) {
  if (!text || typeof text !== 'string') return text;
  
  let redacted = text;
  
  // Redact email addresses
  redacted = redacted.replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL_REDACTED]');
  
  // Redact phone numbers (various formats)
  redacted = redacted.replace(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g, '[PHONE_REDACTED]');
  redacted = redacted.replace(/\b\(\d{3}\)\s?\d{3}[-.]?\d{4}\b/g, '[PHONE_REDACTED]');
  
  // Redact SSN patterns
  redacted = redacted.replace(/\b\d{3}-\d{2}-\d{4}\b/g, '[SSN_REDACTED]');
  
  // Redact MRN/Medical Record Numbers (common patterns)
  redacted = redacted.replace(/\bMRN[:\s]?\d{6,}\b/gi, '[MRN_REDACTED]');
  redacted = redacted.replace(/\bMedical Record[:\s]?\d{6,}\b/gi, '[MRN_REDACTED]');
  
  // Redact addresses (basic pattern - street numbers and common street terms)
  redacted = redacted.replace(/\b\d+\s+[A-Za-z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd|Court|Ct|Way|Circle|Cir)\b/gi, '[ADDRESS_REDACTED]');
  
  // Redact ZIP codes (5 or 9 digit)
  redacted = redacted.replace(/\b\d{5}(?:-\d{4})?\b/g, '[ZIP_REDACTED]');
  
  // Note: Full names are harder to redact reliably without NLP
  // We'll warn the user if we detect potential names
  
  return redacted;
}

// Safe Logger - Strip PHI from logs
function safeLog(level, message, data = {}) {
  // Create a sanitized copy of data
  const sanitized = JSON.parse(JSON.stringify(data));
  
  // Remove common PHI fields
  const phiFields = ['visitText', 'pdfText', 'content', 'notes', 'summary', 'originalText', 'email', 'phone', 'address', 'ssn', 'mrn'];
  phiFields.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  });
  
  // Log with sanitized data
  const logMessage = `[${level.toUpperCase()}] ${message}`;
  if (level === 'error') {
    console.error(logMessage, sanitized);
  } else if (level === 'warn') {
    console.warn(logMessage, sanitized);
  } else {
    console.log(logMessage, sanitized);
  }
}

// ============================================================================
// ANALYZE VISIT SUMMARY TEXT (Manual Input with Redaction)
// ============================================================================

exports.analyzeVisitSummaryText = onCall(
  {secrets: [openaiApiKey], timeoutSeconds: 300},
  async (request) => {
    // Verify authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = request.auth.uid;
    const {visitText, appointmentDate, educationLevel, userProfile, saveOriginalText = false} = request.data;
    
    // Validate input
    if (!visitText || typeof visitText !== 'string' || visitText.trim().length === 0) {
      throw new HttpsError('invalid-argument', 'Visit text is required');
    }
    
    if (!appointmentDate) {
      throw new HttpsError('invalid-argument', 'Appointment date is required');
    }
    
    safeLog('info', 'Analyzing visit summary text', {
      userId,
      textLength: visitText.length,
      appointmentDate,
      saveOriginalText
    });
    
    try {
      // Redact PHI before sending to AI
      const redactedText = redactPHI(visitText);
      
      // Check if redaction removed significant content
      const redactionRatio = redactedText.length / visitText.length;
      const hasRedaction = redactedText !== visitText;
      
      if (hasRedaction && redactionRatio < 0.9) {
        safeLog('warn', 'Significant PHI detected and redacted', {
          userId,
          originalLength: visitText.length,
          redactedLength: redactedText.length
        });
      }
      
      // Use the same analysis helper as PDF analysis
      const analysisResult = await analyzeVisitSummaryPDF({
        pdfText: redactedText,
        appointmentDate,
        educationLevel,
        userProfile,
        userId
      });
      
      // Return summary (not raw text unless user opted in).
      // duplicate: true means this exact text was already summarized for this
      // date; the existing summary is returned in the same shape.
      return {
        success: true,
        summaryId: analysisResult.summaryId,
        summary: analysisResult.summary,
        todos: analysisResult.todos || [],
        learningModules: analysisResult.learningModules || [],
        redFlags: analysisResult.redFlags || [],
        duplicate: !!analysisResult.duplicate,
        hasRedaction: hasRedaction,
        // Only include original text if user explicitly opted in
        ...(saveOriginalText ? {originalText: visitText} : {})
      };
    } catch (error) {
      safeLog('error', 'Error analyzing visit summary text', {
        userId,
        error: error.message,
        name: error.name,
        status: error.status,
        reason: error.reason,
      });
      throw toVisitSummaryHttpsError(error, 'unreadable_text');
    }
  }
);

// ============================================================================
// EXPORT USER DATA
// ============================================================================

exports.exportUserData = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = request.auth.uid;
    safeLog('info', 'Exporting user data', {userId});
    
    try {
      const db = admin.firestore();
      const userData = {
        userId,
        exportedAt: new Date().toISOString(),
        profile: null,
        researchParticipation: null,
        visitSummaries: [],
        notes: [],
        learningTasks: [],
        birthPlans: [],
        journalEntries: [],
        fileUploads: []
      };
      
      // Get user profile
      const profileDoc = await db.collection('users').doc(userId).get();
      if (profileDoc.exists) {
        const profileData = profileDoc.data();
        // Remove sensitive fields if needed
        userData.profile = profileData;

        // Derive research participation flag and recruitment source for export consumers
        const recruitmentSource = profileData.recruitmentSource || null;
        const privacySettings = profileData.privacySettings || {};
        const researchDataSharing =
          Object.prototype.hasOwnProperty.call(privacySettings, 'researchDataSharing')
            ? !!privacySettings.researchDataSharing
            : null;
        const isResearchParticipant =
          profileData.isResearchParticipant === true ||
          recruitmentSource === 'research_participant' ||
          researchDataSharing === true;

        userData.researchParticipation = {
          recruitmentSource,
          researchDataSharing,
          isResearchParticipant,
        };
      }
      
      // Get visit summaries
      const visitSummariesSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('visit_summaries')
        .get();
      userData.visitSummaries = visitSummariesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Get notes
      const notesSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('notes')
        .get();
      userData.notes = notesSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Get learning tasks
      const tasksSnapshot = await db
        .collection('learning_tasks')
        .where('userId', '==', userId)
        .get();
      userData.learningTasks = tasksSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Get birth plans
      const birthPlansSnapshot = await db
        .collection('birth_plans')
        .where('userId', '==', userId)
        .get();
      userData.birthPlans = birthPlansSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Get journal entries
      const journalSnapshot = await db
        .collection('journal_entries')
        .where('userId', '==', userId)
        .get();
      userData.journalEntries = journalSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // Get file uploads metadata
      const fileUploadsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('file_uploads')
        .get();
      userData.fileUploads = fileUploadsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      safeLog('info', 'User data export completed', {
        userId,
        visitSummariesCount: userData.visitSummaries.length,
        notesCount: userData.notes.length
      });
      
      return {
        success: true,
        data: userData,
        format: 'json'
      };
    } catch (error) {
      safeLog('error', 'Error exporting user data', {
        userId,
        error: error.message
      });
      throw new HttpsError('internal', 'Failed to export user data: ' + error.message);
    }
  }
);

// ============================================================================
// DELETE USER ACCOUNT
// ============================================================================

exports.deleteUserAccount = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = request.auth.uid;
    safeLog('info', 'Deleting user account', {userId});
    
    try {
      const db = admin.firestore();
      const storage = admin.storage();
      
      // Delete Firestore documents
      const batch = db.batch();
      
      // Delete user profile
      const userRef = db.collection('users').doc(userId);
      batch.delete(userRef);
      
      // Delete subcollections
      const collections = [
        'visit_summaries',
        'notes',
        'file_uploads',
        'learning_tasks'
      ];
      
      for (const collectionName of collections) {
        const snapshot = await db
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .get();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
      }
      
      // Delete top-level collections
      const topLevelCollections = [
        {name: 'learning_tasks', field: 'userId'},
        {name: 'birth_plans', field: 'userId'},
        {name: 'journal_entries', field: 'userId'},
        {name: 'visit_summaries', field: 'userId'}
      ];
      
      for (const {name, field} of topLevelCollections) {
        const snapshot = await db
          .collection(name)
          .where(field, '==', userId)
          .get();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
      }
      
      await batch.commit();
      
      // Delete Storage files
      try {
        const filesRef = storage.bucket().getFiles({
          prefix: `visit_summaries/${userId}/`
        });
        
        const [files] = await filesRef;
        await Promise.all(files.map(file => file.delete()));
      } catch (storageError) {
        safeLog('warn', 'Error deleting storage files', {
          userId,
          error: storageError.message
        });
        // Continue with deletion even if storage fails
      }
      
      // Delete Firebase Auth user
      try {
        await admin.auth().deleteUser(userId);
      } catch (authError) {
        safeLog('warn', 'Error deleting auth user', {
          userId,
          error: authError.message
        });
        // Continue even if auth deletion fails
      }
      
      safeLog('info', 'User account deleted successfully', {userId});
      
      return {
        success: true,
        message: 'Account and all data deleted successfully'
      };
    } catch (error) {
      safeLog('error', 'Error deleting user account', {
        userId,
        error: error.message
      });
      throw new HttpsError('internal', 'Failed to delete account: ' + error.message);
    }
  }
);

// ============================================================================
// COMMUNITY: delete reply (reply author or post author only)
// ============================================================================

exports.deleteCommunityReply = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const uid = request.auth.uid;
  const dataIn = request.data || {};
  const postId = dataIn.postId;
  const replyId = dataIn.replyId;
  const legacyContent = dataIn.legacyContent;
  const legacyCreatedAtSeconds = dataIn.legacyCreatedAtSeconds;

  if (!postId || typeof postId !== "string") {
    throw new HttpsError("invalid-argument", "postId is required");
  }

  const ref = admin.firestore().collection("community_posts").doc(postId);

  await admin.firestore().runTransaction(async (txn) => {
    const snap = await txn.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Post not found");
    }
    const data = snap.data();
    const postAuthorId = data.userId;
    const replies = Array.isArray(data.replies) ? [...data.replies] : [];

    let index = -1;
    if (replyId && typeof replyId === "string") {
      index = replies.findIndex((r) => r && r.replyId === replyId);
    }
    if (index === -1 && legacyContent != null && typeof legacyContent === "string") {
      index = replies.findIndex((r) => {
        if (!r || r.userId !== uid) return false;
        if (r.content !== legacyContent) return false;
        if (legacyCreatedAtSeconds != null && typeof legacyCreatedAtSeconds === "number") {
          const ca = r.createdAt;
          if (ca && typeof ca.seconds === "number") {
            return ca.seconds === legacyCreatedAtSeconds;
          }
          return false;
        }
        return true;
      });
    }

    if (index === -1) {
      throw new HttpsError("not-found", "Reply not found");
    }

    const target = replies[index];
    const replyAuthorId = target.userId;
    if (replyAuthorId !== uid && postAuthorId !== uid) {
      throw new HttpsError("permission-denied", "You cannot delete this reply");
    }

    replies.splice(index, 1);
    txn.update(ref, {
      replies,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {success: true};
});

// Firebase Cloud Function for Provider Search
// This function processes provider search requests from the client
// It calls Ohio Medicaid API and NPI Registry API, then returns combined results


// NPI Taxonomy Code mappings (matching lib/constants/npi_taxonomy_codes.dart)
const NPI_TAXONOMY_CODES = {
  "OB-GYN": "207V00000X",
  "Obstetrics": "207V00000X",
  "Gynecology": "207V00000X",
  "Maternal-Fetal Medicine": "207VM0101X",
  "Certified Nurse Midwife": "367A00000X",
  "Nurse Midwife Individual": "367A00000X",
  "Nurse Practitioner": "363L00000X",
  "Women's Health Nurse Practitioner": "363LW0102X",
  "Family Nurse Practitioner": "363LF0000X",
};

function getTaxonomyCode(specialty) {
  if (!specialty) return null;
  
  // Exact match
  if (NPI_TAXONOMY_CODES[specialty]) {
    return NPI_TAXONOMY_CODES[specialty];
  }
  
  // Case-insensitive match
  const lowerSpecialty = specialty.toLowerCase();
  for (const [key, value] of Object.entries(NPI_TAXONOMY_CODES)) {
    if (key.toLowerCase() === lowerSpecialty) {
      return value;
    }
  }
  
  // Partial match
  if (lowerSpecialty.includes("ob") && lowerSpecialty.includes("gyn")) {
    return "207V00000X";
  }
  if (lowerSpecialty.includes("midwife")) {
    return "367A00000X";
  }
  if (lowerSpecialty.includes("nurse practitioner")) {
    return "363L00000X";
  }
  
  return null;
}

// Reverse mapping: taxonomy code -> provider type IDs (many-to-many)
function taxonomyCodeToProviderTypeIds(taxonomyCode) {
  const taxonomyToTypeIds = {
    "207V00000X": ["01", "09", "19", "20"], // OB-GYN, Hospital, Osteopathic Physician, Physician Individual
    "367A00000X": ["46", "71"], // Certified Nurse Midwife, Nurse Midwife Individual
    "363L00000X": ["44"], // Nurse Practitioner
    "374J00000X": ["50", "36", "81"], // Doula, Postpartum Doula, Antepartum Doula
    "122300000X": ["54"], // Dentist
  };
  return taxonomyToTypeIds[taxonomyCode] || [];
}

/**
 * Get all taxonomy codes for given provider type IDs
 * Returns an array of taxonomy codes (not just one)
 */
function taxonomyCodesForProviderTypeIds(providerTypeIds) {
  // Map provider type IDs to arrays of taxonomy codes
  // Based on NPI Registry taxonomy codes
  // NOTE: Provider type IDs from API are single digits (1-9) WITH leading zeros ("01", "02", "09")
  const typeIdToTaxonomies = {
    "01": ["207V00000X"], // Hospital (with leading zero)
    "02": ["2084P0800X"], // Psychiatric Hospital (with leading zero)
    "03": ["2084P0800X"], // Psychiatric Residential Treatment Facility (with leading zero)
    "04": ["261Q00000X"], // Outpatient Health Facility (with leading zero)
    "05": ["261Q00000X"], // Rural Health Clinic (with leading zero)
    "06": ["251E00000X"], // Help Me Grow (with leading zero)
    "07": ["133V00000X", "133VN1004X"], // Registered Dietitian Nutritionist (with leading zero)
    "08": ["251E00000X"], // Pace (with leading zero)
    "09": [], // Doula - NOT in NPI Registry (with leading zero)
    "11": ["261Q00000X"], // Free Standing Birth Center
    "12": ["261Q00000X"], // Federally Qualified Health Center
    "16": ["251E00000X"], // Other Accredited Home Health Agency
    "19": ["207V00000X"], // Managed Care Organization Panel Provider Only
    "20": ["207V00000X"], // Physician/osteopath Individual
    "21": ["207V00000X"], // Professional Medical Group
    "23": ["171100000X"], // Acupuncturist
    "24": ["363A00000X"], // Physician Assistant
    "25": ["171M00000X"], // Non-agency Personal Care Aide
    "26": ["171M00000X"], // Non-agency Home Care Attendant
    "27": ["111N00000X"], // Chiropractor Individual
    "28": ["183500000X"], // Medicaid School Program
    "30": ["122300000X"], // Dentist Individual
    "31": ["122300000X"], // Professional Dental Group
    "35": ["152W00000X"], // Optometrist Individual
    "36": ["213E00000X"], // Podiatrist Individual
    "37": ["1041C0700X"], // Social Work
    "38": ["163W00000X"], // Non-agency Nurse -- Rn Or Lpn
    "39": ["225100000X", "2251H0200X"], // Physical Therapist, Individual
    "40": ["235Z00000X"], // Speech Language Pathologist Individual
    "41": ["225X00000X"], // Occupational Therapist, Individual
    "42": ["103T00000X"], // Psychology
    "43": ["231H00000X"], // Audiologist Individual
    "44": ["251E00000X"], // Hospice
    "45": ["251E00000X"], // Waivered Services Organization
    "46": ["261Q00000X"], // Ambulatory Surgery Center
    "47": ["101YP2500X"], // Clinical Counseling
    "50": ["261Q00000X"], // Clinic
    "51": ["261QM0801X"], // Mental Health Clinic
    "52": ["106H00000X"], // Marriage And Family Therapy
    "53": ["103K00000X"], // Adaptive Behavior Service Provider
    "54": ["101YA0400X"], // Chemical Dependency
    "55": ["171M00000X"], // Waivered Services Individual
    "59": ["261QE0800X"], // End-stage Renal Disease Clinic
    "60": ["251E00000X"], // Medicare Certified Home Health Agency
    "65": ["364S00000X"], // Clinical Nurse Specialist Individual
    "68": ["367500000X"], // Anesthesia Assistant Individual
    "69": ["183500000X"], // Pharmacist
    "70": ["333600000X"], // Pharmacy
    "71": ["367A00000X"], // Nurse Midwife Individual
    "72": ["363L00000X"], // Nurse Practitioner Individual
    "73": ["367500000X"], // Certified Registered Nurse Anesthetist Individual
    "74": ["251E00000X"], // Home And Community Based Oda Assisted Living
    "75": ["156F00000X"], // Optician/ocularist
    "76": ["332B00000X"], // Durable Medical Equipment Supplier
    "78": ["251E00000X"], // Enhanced Care Management
    "79": ["261Q00000X"], // Independent Diagnostic Testing Facility
    "80": ["291U00000X"], // Independent Laboratory
    "81": ["247200000X"], // Portable X-ray Supplier
    "82": ["341600000X"], // Ambulance
    "83": ["171M00000X"], // Wheelchair Van
    "84": ["251E00000X"], // Ohio Department Of Mental Health Provider
    "85": ["251E00000X"], // Dodd Targeted Case Management
    "86": ["314000000X"], // Nursing Facility
    "88": ["314000000X"], // State Operated Icf-dd
    "89": ["314000000X"], // Non-state Operated Icf-dd
    "95": ["251E00000X"], // Omhas Certified/licensed Treatment Program
    "96": ["171M00000X"], // Behavioral Health Para-professionals
  };
  
  // Normalize IDs - API uses single digits (1-9) WITH leading zeros ("01", "02", "09")
  // But we may receive them with or without leading zeros from frontend, so normalize to API format
  const normalizedIds = providerTypeIds.map(id => {
    // Add leading zeros for single digits (API format: "01", "02", "09")
    const numId = parseInt(id, 10);
    if (!isNaN(numId) && numId >= 1 && numId <= 9) {
      return id.padStart(2, '0'); // Add leading zero (API format)
    }
    return id; // Return as-is for double digits
  });
  
  console.log(`[taxonomyCodesForProviderTypeIds] Provider type IDs: ${JSON.stringify(normalizedIds)}`);
  
  const taxonomyCodes = new Set();
  for (const typeId of normalizedIds) {
    if (typeIdToTaxonomies[typeId]) {
      typeIdToTaxonomies[typeId].forEach(code => taxonomyCodes.add(code));
      console.log(`[taxonomyCodesForProviderTypeIds] Type ${typeId} maps to: ${JSON.stringify(typeIdToTaxonomies[typeId])}`);
    }
  }
  
  const result = Array.from(taxonomyCodes);
  console.log(`[taxonomyCodesForProviderTypeIds] Final taxonomy codes: ${JSON.stringify(result)}`);
  return result;
}

/**
 * Legacy function - returns first taxonomy code (for backward compatibility)
 * @deprecated Use taxonomyCodesForProviderTypeIds instead
 */
function inferTaxonomyFromProviderTypes(providerTypeIds) {
  const codes = taxonomyCodesForProviderTypeIds(providerTypeIds);
  return codes.length > 0 ? codes[0] : null;
}

/**
 * Check if provider type IDs are OB/maternity-related
 * Used to determine if AcceptsPregnantWomen filter should be applied
 */
function isMaternityProviderType(providerTypeIds) {
  const maternityTypes = ["01", "09", "11", "19", "20", "46", "71", "50", "36", "81", "24", "39"];
  const normalizedIds = providerTypeIds.map(id => {
    const numId = parseInt(id, 10);
    if (!isNaN(numId) && numId < 10) {
      return id.padStart(2, '0');
    }
    return id;
  });
  
  return normalizedIds.some(id => maternityTypes.includes(id));
}

/**
 * Map frontend health plan names to API-expected format
 * Based on Ohio Medicaid API documentation: https://ohiomedicaidprovider.com/PublicSearchAPI.aspx
 */
function normalizeHealthPlanName(healthplan) {
  // Map common variations to API-expected format
  const healthPlanMap = {
    'UnitedHealthcare': 'United HealthCare', // Frontend uses one word, API expects two words with space
    'United Healthcare': 'United HealthCare',
    'UnitedHealthCare': 'United HealthCare',
    'Buckeye': 'Buckeye',
    'CareSource': 'CareSource',
    'Molina': 'Molina',
    'Anthem': 'Anthem',
    'Aetna': 'Aetna',
    // "All plans" and "Not listed / not sure" search every Ohio Medicaid plan. The API's own
    // "All Plans" value does that in one query and reports each provider's plans
    // (PractitionerRole.organization), including plans the app does not list (Humana, AmeriHealth).
    'Not listed / not sure': 'All Plans',
    'All plans': 'All Plans',
    'All Plans': 'All Plans',
  };
  
  // Normalize: trim and check map
  const normalized = healthplan.trim();
  return healthPlanMap[normalized] || normalized; // Return mapped value or original if not found
}

// Upstream time budgets. The app calls OhioMaximusSearch with a 30 s client timeout and
// searchProviders with 60 s (lib/services/firebase_functions_service.dart), so each callable
// returns what it has (coverage.partial = true) before the app gives up.
const OMX_MEDICAID_DEADLINE_MS = Number(process.env.PROVIDER_SEARCH_OMX_DEADLINE_MS || 25000);
const SP_MEDICAID_DEADLINE_MS = Number(process.env.PROVIDER_SEARCH_SP_DEADLINE_MS || 40000);
const SP_NPI_DEADLINE_MS = 20000;

/** "1" -> "01" (the Ohio Medicaid API uses two-digit provider type codes). */
function normalizeProviderTypeId(id) {
  const s = String(id == null ? "" : id).trim();
  const n = parseInt(s, 10);
  if (/^\d+$/.test(s) && n >= 1 && n <= 9) return s.padStart(2, "0");
  return s;
}

exports.searchProviders = onCall({timeoutSeconds: 120, memory: "512MiB"}, async (request) => {
  // Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const {
    zip,
    city,
    healthPlan,
    providerTypeIds,
    radius,
    specialty,
    includeNpi = false,
    acceptsPregnantWomen,
    acceptsNewborns,
    telehealth,
    identityTags, // Identity & Cultural match filters
  } = request.data || {};

  // Validate required parameters
  if (!zip || !city || !healthPlan || !providerTypeIds || !radius) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: zip, city, healthPlan, providerTypeIds, radius",
    );
  }

  const normalizedProviderTypeIds = [...new Set(
    (Array.isArray(providerTypeIds) ? providerTypeIds : [providerTypeIds])
      .map(normalizeProviderTypeId)
      .filter((id) => id),
  )];
  if (normalizedProviderTypeIds.length === 0) {
    return {
      success: true,
      providers: [],
      count: 0,
      error: "Provider type IDs are required for search",
    };
  }

  const t0 = Date.now();
  const radiusMiles = Number(radius);
  const searchZip = engine.zip5(zip) || String(zip).trim();
  const normalizedHealthPlan = normalizeHealthPlanName(String(healthPlan));
  const taxonomyCodes = taxonomyCodesForProviderTypeIds(normalizedProviderTypeIds);
  const origin = engine.searchOrigin(searchZip, city, "OH");
  console.log(`[searchProviders] zip=${searchZip} city=${city} radius=${radiusMiles} plan="${healthPlan}"` +
    ` -> "${normalizedHealthPlan}" types=${normalizedProviderTypeIds.join(",")} includeNpi=${includeNpi}` +
    ` acceptsPregnantWomen=${acceptsPregnantWomen} acceptsNewborns=${acceptsNewborns} telehealth=${telehealth}` +
    ` origin=${origin ? `${origin.lat},${origin.lon} (${origin.precision})` : "unknown"}`);

  try {
    const timings = {};
    const timed = (label, p) => {
      const s = Date.now();
      return p.finally(() => {
        timings[label] = Date.now() - s;
      });
    };

    // 1-3. Ohio Medicaid, NPI Registry and the in-app directory run in parallel.
    const medicaidP = timed("medicaid", engine.searchMedicaid({
      zip: searchZip,
      city,
      state: "OH",
      plan: normalizedHealthPlan,
      typeIds: normalizedProviderTypeIds,
      radius: radiusMiles,
      telehealth,
      specialty,
      deadlineMs: SP_MEDICAID_DEADLINE_MS,
    })).catch((e) => {
      console.error("[searchProviders] Medicaid search failed:", e.message);
      return {providers: [], meta: {error: e.message, partial: true}};
    });

    let npiP = Promise.resolve(null);
    if (includeNpi === true) {
      const codes = [...taxonomyCodes];
      if (specialty) {
        const extra = getTaxonomyCode(specialty);
        if (extra && !codes.includes(extra)) codes.push(extra);
      }
      npiP = timed("npi", engine.searchNpi({
        zip: searchZip,
        city,
        state: "OH",
        taxonomyCodes: codes,
        radius: radiusMiles,
        deadlineMs: SP_NPI_DEADLINE_MS,
      })).catch((e) => {
        console.error("[searchProviders] NPI search failed:", e.message);
        return {providers: [], meta: {error: e.message, partial: true}};
      });
    }

    const firestoreP = timed("directory", searchFirestoreProviders({
      zip: searchZip,
      city,
      radius: radiusMiles,
      providerTypeIds: normalizedProviderTypeIds,
      specialty,
      origin,
    }));

    // 3b. BIPOC providers from the Excel directory (Clinical Counselor searches only)
    const isClinicalCounselorSearch = normalizedProviderTypeIds.some((id) =>
      id === "47" || id.toLowerCase().includes("counselor") || id.toLowerCase().includes("therapist"),
    );
    const excelP = isClinicalCounselorSearch ?
      readBipocProvidersFromExcel({zip: searchZip, city, radius: radiusMiles,
        providerTypeIds: normalizedProviderTypeIds, specialty})
        .then((list) => list.map((p) => {
          // Annotate distance; keep rows whose address can't be located (legacy behaviour).
          const placed = engine.placeLocations(p.locations, origin, radiusMiles);
          if (placed) return {...p, locations: placed.locations, distanceMiles: placed.distance, _dist: placed.distance};
          return origin && (p.locations || []).some((l) => engine.locatePoint(l)) ? null : p;
        }).filter(Boolean))
        .catch((e) => {
          console.error("[searchProviders] Error reading BIPOC providers from Excel:", e);
          return [];
        }) :
      Promise.resolve([]);

    const [medicaid, npi, firestoreProviders, excelProviders] = await Promise.all([medicaidP, npiP, firestoreP,
      excelP]);

    const providers = [
      ...medicaid.providers,
      ...(npi ? npi.providers : []),
      ...firestoreProviders,
      ...excelProviders,
    ];
    const medicaidCount = medicaid.providers.length;
    const npiCount = npi ? npi.providers.length : 0;

    // 4. Deduplicate providers by NPI or name+location
    const deduplicatedProviders = deduplicateProviders(providers);

    // 5. Enrich with Firestore data (reviews, identity tags, Mama Approved)
    const enrichedProviders = await timed("enrich", enrichProvidersWithFirestore(deduplicatedProviders));

    // 5a. Sort: BIPOC first when identity tags are selected, then Mama Approved, rating,
    // review count, and finally distance (nearest first).
    const hasIdentityTags = identityTags && Array.isArray(identityTags) && identityTags.length > 0;
    const hasBipocTag = (provider) => {
      if (!provider.identityTags || !Array.isArray(provider.identityTags)) return false;
      return provider.identityTags.some((tag) =>
        (tag.name && tag.name.toLowerCase() === "bipoc") ||
        (tag.id && tag.id.toLowerCase() === "bipoc"),
      );
    };
    const distOf = (p) => (p.distanceMiles == null ? Infinity : (p._dist != null ? p._dist : p.distanceMiles));
    enrichedProviders.sort((a, b) => {
      if (hasIdentityTags) {
        const aHasBipoc = hasBipocTag(a);
        const bHasBipoc = hasBipocTag(b);
        if (aHasBipoc && !bHasBipoc) return -1;
        if (!aHasBipoc && bHasBipoc) return 1;
      }
      if (a.mamaApproved && !b.mamaApproved) return -1;
      if (!a.mamaApproved && b.mamaApproved) return 1;
      const ratingA = a.rating || 0;
      const ratingB = b.rating || 0;
      if (ratingA !== ratingB) return ratingB - ratingA;
      const countA = a.reviewCount || 0;
      const countB = b.reviewCount || 0;
      if (countA !== countB) return countB - countA;
      return distOf(a) - distOf(b);
    });

    // 5b. Remove listings that were deleted via report moderation
    const visibleProviders = await timed("blocks", filterProvidersRemovedFromSearch(enrichedProviders));

    // 6. Serialize providers to a JSON-compatible format
    const serializedProviders = visibleProviders.map(serializeProvider);

    const completeWithin = [medicaid.meta && medicaid.meta.completeWithinMiles,
      npi && npi.meta && npi.meta.completeWithinMiles].filter((d) => d != null);
    const coverage = {
      origin: origin ? {lat: origin.lat, lon: origin.lon, precision: origin.precision} : null,
      radiusMiles,
      radiusLimitMiles: Math.round(engine.radiusLimit(radiusMiles) * 100) / 100,
      healthPlan: normalizedHealthPlan,
      completeWithinMiles: completeWithin.length ? Math.min(...completeWithin) : null,
      partial: !!(medicaid.meta && medicaid.meta.partial) || !!(npi && npi.meta && npi.meta.timedOut),
      medicaid: medicaid.meta,
      npi: npi ? npi.meta : null,
    };
    timings.total = Date.now() - t0;
    console.log(`[searchProviders] returned ${serializedProviders.length} (medicaid ${medicaidCount}, npi ${npiCount},` +
      ` directory ${firestoreProviders.length}, excel ${excelProviders.length}) in ${timings.total}ms` +
      ` ${JSON.stringify(timings)} medicaidQueries=${medicaid.meta && medicaid.meta.queries}` +
      ` cacheHits=${medicaid.meta && medicaid.meta.cacheHits} partial=${coverage.partial}`);

    return {
      success: true,
      providers: serializedProviders,
      count: serializedProviders.length,
      coverage,
      timingsMs: timings,
    };
  } catch (error) {
    console.error("Error in searchProviders:", error);
    throw new HttpsError("internal", "Provider search failed: " + error.message);
  }
});

// Deduplicate providers by NPI or name+location
function deduplicateProviders(providers) {
  const seen = new Map();
  const deduplicated = [];
  
  for (const provider of providers) {
    let key = null;
    
    // Use NPI as primary key
    if (provider.npi) {
      key = `npi_${provider.npi}`;
    } else if (provider.locations && provider.locations.length > 0) {
      // Use name + first location as key
      const loc = provider.locations[0];
      key = `name_${provider.name}_${loc.city}_${loc.zip}`.toLowerCase().replace(/[^a-z0-9_]/g, "_");
    } else {
      // Use name only as last resort
      key = `name_${provider.name}`.toLowerCase().replace(/[^a-z0-9_]/g, "_");
    }
    
    if (key && !seen.has(key)) {
      seen.set(key, true);
      deduplicated.push(provider);
    }
  }
  
  return deduplicated;
}

/** Firestore-safe id for provider_search_blocks (doc id cannot contain `/`). */
function blockDocIdForKey(key) {
  let s = String(key ?? "");
  if (s.length > 1400) s = s.slice(0, 1400);
  return s.replace(/\//g, "__");
}

/**
 * Keys that may appear in search results for this listing (matches deduplicateProviders + directory ids).
 */
function collectProviderSearchBlockKeys(obj) {
  const keys = new Set();
  const id = obj && (obj.id != null ? String(obj.id).trim() : "");
  if (id) keys.add(id);
  const npi = obj && obj.npi != null ? String(obj.npi).trim() : "";
  if (npi) keys.add(`npi_${npi}`);
  const name = obj && obj.name != null ? String(obj.name) : "";
  const locs = obj && Array.isArray(obj.locations) ? obj.locations : [];
  if (name && locs.length > 0 && !npi) {
    // One key per location: search results now list the nearest location first, so the
    // location a listing was reported/removed under may no longer be the first one.
    for (const loc of locs) {
      const l = loc || {};
      const city = l.city != null ? String(l.city) : "";
      const zip = l.zip != null ? String(l.zip) : "";
      keys.add(`name_${name}_${city}_${zip}`.toLowerCase().replace(/[^a-z0-9_]/g, "_"));
    }
  } else if (name && !npi && locs.length === 0) {
    keys.add(`name_${name}`.toLowerCase().replace(/[^a-z0-9_]/g, "_"));
  }
  return [...keys];
}

async function fetchProviderSearchBlockHits(logicalKeys) {
  const unique = [...new Set((logicalKeys || []).filter(Boolean))];
  const blocked = new Set();
  if (unique.length === 0) return blocked;
  const db = admin.firestore();
  const chunkSize = 100;
  const chunks = [];
  for (let i = 0; i < unique.length; i += chunkSize) chunks.push(unique.slice(i, i + chunkSize));
  await engine.mapLimit(chunks, 8, async (chunk) => {
    const refs = chunk.map((k) =>
      db.collection("provider_search_blocks").doc(blockDocIdForKey(k)),
    );
    const snaps = await db.getAll(...refs);
    chunk.forEach((k, idx) => {
      if (snaps[idx] && snaps[idx].exists) blocked.add(k);
    });
  });
  return blocked;
}

/** Drop providers that were administratively removed from directory search. */
async function filterProvidersRemovedFromSearch(providers) {
  if (!providers || providers.length === 0) return providers;
  // Check every known location of a listing (not only the in-radius ones shown).
  const keysFor = (p) => collectProviderSearchBlockKeys(
    Array.isArray(p._allLocations) ? {...p, locations: p._allLocations} : p);
  const keysToCheck = new Set();
  for (const p of providers) {
    keysFor(p).forEach((k) => keysToCheck.add(k));
  }
  const blocked = await fetchProviderSearchBlockHits([...keysToCheck]);
  return providers.filter((p) => {
    const keys = keysFor(p);
    return !keys.some((k) => blocked.has(k));
  });
}

async function deleteStoragePrefix(prefix) {
  if (!prefix || typeof prefix !== "string") return 0;
  const trimmed = prefix.endsWith("/") ? prefix : `${prefix}/`;
  try {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({prefix: trimmed, maxResults: 500});
    let n = 0;
    for (const f of files) {
      try {
        await f.delete();
        n++;
      } catch (e) {
        console.warn(`[deleteStoragePrefix] skip delete ${f.name}:`, e.message);
      }
    }
    return n;
  } catch (e) {
    console.warn(`[deleteStoragePrefix] list failed for ${trimmed}:`, e.message);
    return 0;
  }
}

async function assertAdminDashboardUser(auth) {
  if (!auth || !auth.uid) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const uid = auth.uid;
  const email = auth.token && auth.token.email ? String(auth.token.email) : null;
  const db = admin.firestore();
  const snaps = await Promise.all([
    db.doc(`ADMIN/${uid}`).get(),
    email ? db.doc(`ADMIN/${email}`).get() : Promise.resolve({exists: false}),
    db.doc(`RESEARCH_PARTNERS/${uid}`).get(),
    email ? db.doc(`RESEARCH_PARTNERS/${email}`).get() : Promise.resolve({exists: false}),
    db.doc(`COMMUNITY_MANAGERS/${uid}`).get(),
    email ? db.doc(`COMMUNITY_MANAGERS/${email}`).get() : Promise.resolve({exists: false}),
  ]);
  const hasRole = snaps.some((s) => s && s.exists);
  const legacyEmail =
    email && (email === "osrgnoi@gmail.com" || email === "corinntaylor@gmail.com");
  if (!hasRole && !legacyEmail) {
    throw new HttpsError("permission-denied", "Admin dashboard access required");
  }
}

// Helper function to serialize provider objects to JSON-compatible format
function serializeProvider(provider) {
  // Convert provider to plain object, handling Firestore Timestamps and nested objects
  const serialized = {
    name: provider.name || null,
    specialty: provider.specialty || null,
    practiceName: provider.practiceName || null,
    npi: provider.npi || null,
    id: provider.id || null,
    rating: provider.rating != null ? (typeof provider.rating === 'number' ? provider.rating : parseFloat(provider.rating)) : null,
    reviewCount: provider.reviewCount != null ? (typeof provider.reviewCount === 'number' ? provider.reviewCount : parseInt(provider.reviewCount)) : 0,
    mamaApproved: provider.mamaApproved === true,
    mamaApprovedCount: provider.mamaApprovedCount != null ? (typeof provider.mamaApprovedCount === 'number' ? provider.mamaApprovedCount : parseInt(provider.mamaApprovedCount)) : 0,
    phone: provider.phone || null,
    email: provider.email || null,
    website: provider.website || null,
    acceptingNewPatients: provider.acceptingNewPatients === true ? true : (provider.acceptingNewPatients === false ? false : null),
    acceptsPregnantWomen: provider.acceptsPregnantWomen === true ? true : (provider.acceptsPregnantWomen === false ? false : null),
    acceptsNewborns: provider.acceptsNewborns === true ? true : (provider.acceptsNewborns === false ? false : null),
    telehealth: provider.telehealth === true ? true : (provider.telehealth === false ? false : null),
    source: provider.source || null,
    providerTypes: Array.isArray(provider.providerTypes) ? provider.providerTypes.map(t => String(t)) : [],
    specialties: Array.isArray(provider.specialties) ? provider.specialties.map(s => String(s)) : [],
    locations: Array.isArray(provider.locations) ? provider.locations.map(loc => ({
      address: loc.address || null,
      address2: loc.address2 || null,
      city: loc.city || null,
      state: loc.state || null,
      zip: loc.zip || null,
      phone: loc.phone || null,
      // Distance from the searched ZIP (miles) and the point it was measured to
      // (street coordinates when known, else the ZIP/city centroid).
      latitude: typeof loc.latitude === "number" ? Math.round(loc.latitude * 1e5) / 1e5 : null,
      longitude: typeof loc.longitude === "number" ? Math.round(loc.longitude * 1e5) / 1e5 : null,
      distance: typeof loc.distance === "number" ? Math.round(loc.distance * 10) / 10 : null,
    })) : [],
    // Distance to the nearest in-radius location (= locations[0]), rounded to 0.1 mi.
    distanceMiles: typeof provider.distanceMiles === "number" ? Math.round(provider.distanceMiles * 10) / 10 : null,
    // Ohio Medicaid plans this provider is listed under (app plan names), when known.
    healthPlans: Array.isArray(provider.healthPlans) ? provider.healthPlans.map((p) => String(p)) : null,
    identityTags: Array.isArray(provider.identityTags) ? provider.identityTags.map(tag => {
      // Handle Firestore document data or plain objects
      if (tag && typeof tag === 'object') {
        return {
          id: tag.id || null,
          name: tag.name || null,
          category: tag.category || null,
          source: tag.source || null,
          verificationStatus: tag.verificationStatus || tag.verified ? "verified" : "pending",
          verified: tag.verified === true || tag.verificationStatus === "verified",
          verifiedAt: tag.verifiedAt || null,
          verifiedBy: tag.verifiedBy || null,
        };
      }
      return tag;
    }) : [],
  };
  
  return serialized;
}

/**
 * Create BIPOC identity tag
 */
function createBipocTag() {
  return {
    id: "bipoc",
    name: "BIPOC",
    category: "identity",
    source: "admin",
    verificationStatus: "verified",
    verifiedAt: new Date().toISOString(),
    verifiedBy: "system",
  };
}

/**
 * Parse phone number to standard format
 */
function parsePhone(phoneString) {
  if (!phoneString) return null;
  const digits = phoneString.toString().replace(/\D/g, "");
  if (digits.length === 10) {
    return `(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}`;
  }
  return phoneString;
}

/**
 * Parse address string into components
 */
function parseAddress(addressString) {
  if (!addressString) return null;
  const parts = addressString.toString().split(",").map(p => p.trim());
  
  if (parts.length >= 2) {
    // Try to extract ZIP from last part
    const lastPart = parts[parts.length - 1];
    const zipMatch = lastPart.match(/(\d{5}(?:-\d{4})?)/);
    const zip = zipMatch ? zipMatch[1].substring(0, 5) : null;
    
    return {
      address: parts[0],
      address2: parts.length > 3 ? parts.slice(1, -2).join(", ") : null,
      city: parts.length >= 3 ? parts[parts.length - 2] : (zip ? parts[parts.length - 1].replace(/\d{5}.*/, "").trim() : null),
      state: "OH",
      zip: zip,
    };
  }
  
  return {
    address: addressString.toString(),
    address2: null,
    city: null,
    state: "OH",
    zip: null,
  };
}

/**
 * Read BIPOC providers from Excel file and return as provider objects
 * This function reads from Firebase Storage or local file system
 */
async function readBipocProvidersFromExcel(searchParams) {
  const { zip, city, providerTypeIds } = searchParams;
  const providers = [];

  console.log(`[readBipocProvidersFromExcel] Starting - city: ${city}, zip: ${zip}`);

  // Only include BIPOC providers when user is in Cincinnati
  const isCincinnati = city && city.toLowerCase().includes("cincinnati");
  if (!isCincinnati) {
    console.log(`[readBipocProvidersFromExcel] Skipping - user is not in Cincinnati (city: ${city})`);
    return providers;
  }

  console.log(`[readBipocProvidersFromExcel] User is in Cincinnati, proceeding...`);

  try {
    let excelFilePath = null;
    let excelBuffer = null;

    // First, try to read from Firebase Storage
    try {
      console.log(`[readBipocProvidersFromExcel] Attempting to read from Firebase Storage...`);
      const bucket = admin.storage().bucket();
      // Try multiple possible storage paths
      const possibleStoragePaths = [
        "BIPOC Provider Directory.xlsx", // Root of bucket (where user uploaded it)
        "bipoc-directory/BIPOC Provider Directory.xlsx", // Subdirectory
      ];
      
      let storagePath = null;
      let file = null;
      
      for (const path of possibleStoragePaths) {
        const testFile = bucket.file(path);
        const [exists] = await testFile.exists();
        if (exists) {
          storagePath = path;
          file = testFile;
          break;
        }
      }
      
      if (!file) {
        console.log(`[readBipocProvidersFromExcel] File not found in Storage. Tried: ${possibleStoragePaths.join(", ")}`);
      } else {
        console.log(`[readBipocProvidersFromExcel] Found file in Firebase Storage: ${storagePath}`);
        const [buffer] = await file.download();
        excelBuffer = buffer;
        console.log(`[readBipocProvidersFromExcel] Downloaded ${buffer.length} bytes from Storage`);
      }
    } catch (storageError) {
      console.log(`[readBipocProvidersFromExcel] Error reading from Storage (will try local):`, storageError.message);
    }

    // If not in Storage, try local file system (for local development)
    if (!excelBuffer) {
      console.log(`[readBipocProvidersFromExcel] Trying local file system...`);
      const possiblePaths = [
        path.join(__dirname, "..", "BIPOC Provider Directory.xlsx"),
        path.join(process.cwd(), "BIPOC Provider Directory.xlsx"),
        path.join(__dirname, "BIPOC Provider Directory.xlsx"),
      ];

      for (const filePath of possiblePaths) {
        try {
          if (fs.existsSync(filePath)) {
            excelFilePath = filePath;
            console.log(`[readBipocProvidersFromExcel] Found local file: ${excelFilePath}`);
            break;
          }
        } catch (e) {
          // Continue to next path
        }
      }
    }

    if (!excelBuffer && !excelFilePath) {
      console.log("[readBipocProvidersFromExcel] Excel file not found in Storage or local filesystem");
      console.log("[readBipocProvidersFromExcel] To fix: Upload 'BIPOC Provider Directory.xlsx' to Firebase Storage at 'bipoc-directory/BIPOC Provider Directory.xlsx'");
      return providers;
    }

    // Read Excel file
    let workbook;
    if (excelBuffer) {
      console.log(`[readBipocProvidersFromExcel] Reading from buffer...`);
      workbook = XLSX.read(excelBuffer, { type: 'buffer' });
    } else {
      console.log(`[readBipocProvidersFromExcel] Reading from file: ${excelFilePath}`);
      workbook = XLSX.readFile(excelFilePath);
    }

    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    
    // Convert to JSON with headers
    const rows = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    if (rows.length < 2) {
      console.log("[readBipocProvidersFromExcel] Excel file is empty or has no data rows");
      return providers;
    }

    // First row is headers
    const headers = rows[0].map(h => h ? h.toString().trim() : "");
    console.log(`[readBipocProvidersFromExcel] Headers: ${headers.join(", ")}`);
    console.log(`[readBipocProvidersFromExcel] Total rows: ${rows.length}`);

    // Helper to get value from row by header name (case-insensitive)
    const getValue = (rowObj, headerVariations) => {
      for (const variation of headerVariations) {
        const key = headers.find(h => h.toLowerCase().includes(variation.toLowerCase()));
        if (key && rowObj[key] !== undefined && rowObj[key] !== null && rowObj[key] !== "") {
          return rowObj[key].toString().trim();
        }
      }
      return null;
    };

    // Process data rows
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      if (!row || row.length === 0) continue;

      // Convert row array to object
      const rowObj = {};
      headers.forEach((header, index) => {
        rowObj[header] = row[index] !== undefined && row[index] !== null ? row[index].toString().trim() : "";
      });

      const name = getValue(rowObj, ["Provider Name", "name", "provider name"]);
      if (!name || name === "") continue;

      const providerType = getValue(rowObj, ["Provider Type", "provider type", "type"]);
      const email = getValue(rowObj, ["Email", "email", "e-mail"]);
      const phone = parsePhone(getValue(rowObj, ["Phone number", "phone", "phone number", "telephone"]));
      const website = getValue(rowObj, ["Website", "website", "url", "web"]);
      const address = getValue(rowObj, ["Address", "address", "street"]);
      const specialties = getValue(rowObj, ["Specialities", "specialties", "specialty"]);

      // Check if searching for Clinical Counselor (provider type '47')
      // If so, include ALL BIPOC providers from the directory (they're all mental health providers)
      const isClinicalCounselorSearch = providerTypeIds && providerTypeIds.some(id => 
        id === "47" || id === "Clinical Counseling" || id.toLowerCase().includes("counselor") || id.toLowerCase().includes("therapist")
      );

      if (!isClinicalCounselorSearch) {
        continue; // Only include for Clinical Counselor searches
      }

      // Include all BIPOC providers when searching for Clinical Counselor
      // (The BIPOC directory contains mental health providers who can provide counseling/therapy)

      // Parse address
      const location = address ? parseAddress(address) : null;
      if (!location) {
        continue;
      }

      // Check if provider is in Cincinnati
      // Since user is searching in Cincinnati, include all BIPOC providers from the directory
      // (they're all in the Cincinnati area based on the directory)
      const providerCity = location.city ? location.city.toLowerCase() : "";
      const isProviderInCincinnati = providerCity.includes("cincinnati") || 
                                     providerCity.includes("cincy") ||
                                     (location.zip && location.zip.startsWith("45")); // Cincinnati ZIP codes start with 45

      // For now, include all providers from the BIPOC directory when user searches in Cincinnati
      // The directory is specifically for Cincinnati area providers
      if (!isProviderInCincinnati && location.zip && !location.zip.startsWith("45")) {
        console.log(`[readBipocProvidersFromExcel] Skipping ${name} - not in Cincinnati area (city: ${location.city}, zip: ${location.zip})`);
        continue;
      }

      console.log(`[readBipocProvidersFromExcel] Processing provider: ${name} (city: ${location.city}, zip: ${location.zip})`);

      // Create provider object
      const provider = {
        name: name,
        practiceName: null,
        specialty: specialties || "Clinical Counseling",
        npi: null,
        locations: location ? [{
          address: location.address || "",
          address2: location.address2 || null,
          city: location.city || "",
          state: location.state || "OH",
          zip: location.zip || "",
          phone: phone || null,
          latitude: null,
          longitude: null,
        }] : [],
        providerTypes: ["47"], // Clinical Counseling
        specialties: specialties ? [specialties] : ["Clinical Counseling"],
        phone: phone,
        email: email || null,
        website: website || null,
        acceptingNewPatients: null,
        acceptsPregnantWomen: null,
        acceptsNewborns: null,
        telehealth: null,
        rating: null,
        reviewCount: 0,
        mamaApproved: false,
        mamaApprovedCount: 0,
        identityTags: [createBipocTag()],
        source: "bipoc_directory_excel",
      };

      providers.push(provider);
      console.log(`[readBipocProvidersFromExcel] ✅ Added BIPOC provider: ${name} with BIPOC tag`);
    }

    console.log(`[readBipocProvidersFromExcel] ✅ Successfully processed ${providers.length} BIPOC providers from Excel`);
    return providers;
  } catch (error) {
    console.error(`[readBipocProvidersFromExcel] ❌ Error reading Excel file:`, error);
    console.error(`[readBipocProvidersFromExcel] Error stack:`, error.stack);
    return [];
  }
}

/**
 * Search Firestore for providers matching search criteria
 * This includes BIPOC directory providers and other Firestore-only providers
 */
async function searchFirestoreProviders(searchParams) {
  const {zip, city, radius, providerTypeIds, specialty} = searchParams;
  const origin = searchParams.origin !== undefined ? searchParams.origin : engine.searchOrigin(zip, city, "OH");
  const providers = [];

  try {
    // Firestore has no geo query here, so fetch the directory rows and filter by distance:
    // a listing matches when any of its locations is within the radius of the searched ZIP
    // (street coordinates when stored, else the ZIP or city centroid).
    const snapshot = await admin.firestore().collection("providers")
      .where("source", "in", ["bipoc_directory", "admin_added", "user_submission"])
      .limit(500) // Limit to avoid too many reads
      .get();

    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (data.directoryHidden === true) continue;
      if (!data.locations || !Array.isArray(data.locations) || data.locations.length === 0) continue;

      if (providerTypeIds && providerTypeIds.length > 0) {
        const providerTypes = data.providerTypes || [];
        const hasMatchingType = providerTypeIds.some((typeId) =>
          providerTypes.includes(typeId) || providerTypes.includes(typeId.padStart(2, "0")),
        );
        if (!hasMatchingType) continue;
      }
      if (specialty) {
        const specialties = data.specialties || [];
        const providerSpecialty = data.specialty || "";
        if (!specialties.includes(specialty) && providerSpecialty !== specialty) continue;
      }

      const rawLocations = data.locations.map((location) => ({
        address: location.address || "",
        address2: location.address2 || null,
        city: location.city || "",
        state: location.state || "OH",
        zip: location.zip || "",
        phone: location.phone || data.phone || null,
        latitude: location.latitude || null,
        longitude: location.longitude || null,
      }));
      let locations;
      let distance = null;
      if (origin) {
        const placed = engine.placeLocations(rawLocations, origin, radius);
        if (!placed) continue;
        locations = placed.locations;
        distance = placed.distance;
      } else {
        // Unknown search ZIP: fall back to the old exact-ZIP match.
        const z = String(zip || "").substring(0, 5);
        const match = rawLocations.find((l) => l.zip && String(l.zip).substring(0, 5) === z);
        if (!match) continue;
        locations = [match, ...rawLocations.filter((l) => l !== match)];
      }

      providers.push({
        id: doc.id,
        name: data.name || "",
        specialty: data.specialty || null,
        practiceName: data.practiceName || null,
        npi: data.npi || null,
        locations,
        providerTypes: data.providerTypes || [],
        specialties: data.specialties || [],
        phone: data.phone || null,
        email: data.email || null,
        website: data.website || null,
        acceptingNewPatients: data.acceptingNewPatients || null,
        acceptsPregnantWomen: data.acceptsPregnantWomen || null,
        acceptsNewborns: data.acceptsNewborns || null,
        telehealth: data.telehealth || null,
        rating: data.rating || null,
        reviewCount: data.reviewCount || 0,
        mamaApproved: data.mamaApproved || false,
        mamaApprovedCount: data.mamaApprovedCount || 0,
        identityTags: data.identityTags || [],
        source: data.source || "firestore",
        distanceMiles: distance,
        _dist: distance,
        _allLocations: rawLocations,
      });
    }

    console.log(`[searchFirestoreProviders] ${providers.length} of ${snapshot.size} directory rows within ${radius} mi`);
    return providers;
  } catch (error) {
    console.error(`[searchFirestoreProviders] Error:`, error);
    return [];
  }
}

// Helper function to enrich providers with Firestore data
async function enrichProvidersWithFirestore(providers) {
  // Runs with limited concurrency (it used to be one provider at a time); order is preserved.
  const results = await engine.mapLimit(providers, 16, async (provider) => {
    try {
      // Try to find provider in Firestore by NPI or name+location
      let firestoreProvider = null;
      let firestoreId = null;
      let matchedHiddenDirectory = false;

      // Try by NPI first (skip directory-hidden; if only hidden matches, drop this listing)
      if (provider.npi) {
        const npiQuery = await admin.firestore()
          .collection("providers")
          .where("npi", "==", provider.npi)
          .limit(10)
          .get();

        for (const doc of npiQuery.docs) {
          const data = doc.data();
          if (data.directoryHidden === true) {
            matchedHiddenDirectory = true;
            continue;
          }
          firestoreProvider = data;
          firestoreId = doc.id;
          matchedHiddenDirectory = false;
          break;
        }
      }

      // If not found by NPI, try by name+location
      if (!firestoreProvider && provider.locations && provider.locations.length > 0) {
        // Match on any of the listing's locations (the first one is now the nearest).
        const provLocs = Array.isArray(provider._allLocations) ? provider._allLocations : provider.locations;
        const nameQuery = await admin.firestore()
          .collection("providers")
          .where("name", "==", provider.name)
          .limit(10)
          .get();

        for (const doc of nameQuery.docs) {
          const data = doc.data();
          if (data.locations && Array.isArray(data.locations)) {
            const match = data.locations.find((l) =>
              provLocs.some((loc) => l.city === loc.city && l.zip === loc.zip)
            );
            if (match) {
              if (data.directoryHidden === true) {
                matchedHiddenDirectory = true;
                continue;
              }
              firestoreProvider = data;
              firestoreId = doc.id;
              matchedHiddenDirectory = false;
              break;
            }
          }
        }
      }

      if (!firestoreProvider && matchedHiddenDirectory) {
        return null;
      }
      
      // Calculate average rating from reviews
      let rating = firestoreProvider?.rating || null;
      let reviewCount = firestoreProvider?.reviewCount || 0;
      
      // Try to get reviews by Firestore ID first
      if (firestoreId) {
        try {
          const reviewsQuery = await admin.firestore()
            .collection("reviews")
            .where("providerId", "==", firestoreId)
            .limit(50)
            .get();
          
          if (!reviewsQuery.empty) {
            const reviews = reviewsQuery.docs.map((doc) => doc.data())
              .filter((r) => (r.status || "published") === "published");
            if (reviews.length > 0) {
              const totalRating = reviews.reduce((sum, r) => sum + (r.rating || 0), 0);
              rating = totalRating / reviews.length;
              reviewCount = reviews.length;
              console.log(`[Enrich] Provider ${firestoreId}: calculated rating ${rating} from ${reviews.length} reviews`);
            }
          }
        } catch (error) {
          console.error(`Error getting reviews for ${firestoreId}:`, error);
        }
      }
      
      // If no rating found and provider has NPI, try to find reviews by NPI (visible directory rows only)
      if ((rating == null || rating == 0) && provider.npi) {
        try {
          const npiProviderQuery = await admin.firestore()
            .collection("providers")
            .where("npi", "==", provider.npi)
            .limit(10)
            .get();

          for (const doc of npiProviderQuery.docs) {
            const pdata = doc.data();
            if (pdata.directoryHidden === true) continue;
            const npiProviderId = doc.id;
            const reviewsQuery = await admin.firestore()
              .collection("reviews")
              .where("providerId", "==", npiProviderId)
              .limit(50)
              .get();

            if (!reviewsQuery.empty) {
              const reviews = reviewsQuery.docs.map((d) => d.data())
              .filter((r) => (r.status || "published") === "published");
              if (reviews.length > 0) {
                const totalRating = reviews.reduce((sum, r) => sum + (r.rating || 0), 0);
                rating = totalRating / reviews.length;
                reviewCount = reviews.length;
                console.log(`[Enrich] Provider NPI ${provider.npi}: calculated rating ${rating} from ${reviews.length} reviews`);
              }
            }
            break;
          }
        } catch (error) {
          console.error(`Error getting reviews by NPI for ${provider.npi}:`, error);
        }
      }
      
      // If still no rating found and provider has NPI, try to find reviews by NPI-based providerId
      if ((rating == null || rating == 0) && provider.npi && !firestoreId) {
        try {
          // Try to find reviews with providerId starting with 'npi_'
          const npiProviderId = `npi_${provider.npi}`;
          const reviewsQuery = await admin.firestore()
            .collection("reviews")
            .where("providerId", "==", npiProviderId)
            .limit(50)
            .get();
          
          if (!reviewsQuery.empty) {
            const reviews = reviewsQuery.docs.map((doc) => doc.data())
              .filter((r) => (r.status || "published") === "published");
            if (reviews.length > 0) {
              const totalRating = reviews.reduce((sum, r) => sum + (r.rating || 0), 0);
              rating = totalRating / reviews.length;
              reviewCount = reviews.length;
              console.log(`[Enrich] Provider NPI ${provider.npi} (no Firestore ID): calculated rating ${rating} from ${reviews.length} reviews`);
            }
          }
        } catch (error) {
          console.error(`Error getting reviews by NPI ID for ${provider.npi}:`, error);
        }
      }
      
      // Merge Firestore data with API data
      const enrichedProvider = {
        ...provider,
        id: firestoreId || null,
        rating: rating,
        reviewCount: reviewCount,
        mamaApproved: firestoreProvider?.mamaApproved || false,
        mamaApprovedCount: firestoreProvider?.mamaApprovedCount || 0,
        identityTags: firestoreProvider?.identityTags || [],
        acceptsPregnantWomen: provider.acceptsPregnantWomen || firestoreProvider?.acceptsPregnantWomen || null,
        acceptsNewborns: provider.acceptsNewborns || firestoreProvider?.acceptsNewborns || null,
        telehealth: provider.telehealth || firestoreProvider?.telehealth || null,
      };

      return enrichedProvider;
    } catch (error) {
      console.error(`Error enriching provider ${provider.name}:`, error);
      // Add provider without enrichment
      return provider;
    }
  });

  return results.filter(Boolean);
}

/**
 * Permanently remove a directory listing after triage: delete `providers/{id}`,
 * block future search hits (Medicaid/NPI/Firestore merge), delete Storage prefix
 * `providers/{id}/`, and mark related reports. Callable — admin dashboard roles only.
 */
// Gen2 callables run on Cloud Run. Without `cors`, browsers block preflight from
// non-Firebase hosts (e.g. Railway admin). Auth + assertAdminDashboardUser still gate access.
exports.adminRemoveProviderListing = onCall(
  {cors: true},
  async (request) => {
  await assertAdminDashboardUser(request.auth);

  const providerId = request.data && request.data.providerId != null
    ? String(request.data.providerId).trim()
    : "";
  if (!providerId) {
    throw new HttpsError("invalid-argument", "providerId is required");
  }

  const uid = request.auth.uid;

  const db = admin.firestore();
  const pRef = db.collection("providers").doc(providerId);
  const pSnap = await pRef.get();
  const pData = pSnap.exists ? pSnap.data() : {};

  const keys = new Set(collectProviderSearchBlockKeys({
    id: providerId,
    npi: pData.npi,
    name: pData.name,
    locations: pData.locations,
  }));
  keys.add(providerId);

  const batch = db.batch();
  const ts = admin.firestore.FieldValue.serverTimestamp();
  for (const k of keys) {
    if (!k) continue;
    const docId = blockDocIdForKey(k);
    batch.set(
      db.collection("provider_search_blocks").doc(docId),
      {
        logicalKey: k,
        providerId,
        npi: pData.npi != null ? String(pData.npi) : null,
        removedAt: ts,
        removedBy: uid,
        source: "admin_remove_listing",
      },
      {merge: true},
    );
  }
  if (pSnap.exists) {
    batch.delete(pRef);
  }
  await batch.commit();

  const storageFilesDeleted = await deleteStoragePrefix(`providers/${providerId}`);

  const upQuery = await db
    .collection("UserProviders")
    .where("publishedProviderId", "==", providerId)
    .limit(25)
    .get();
  const upBatch = db.batch();
  upQuery.docs.forEach((d) => {
    upBatch.update(d.ref, {
      status: "removed_from_directory",
      publishedProviderId: null,
      mamaApproved: false,
      updatedAt: ts,
      moderatedAt: ts,
      moderationDecision: "removed_from_directory",
      ...(uid ? {moderatedBy: uid} : {}),
    });
  });
  if (!upQuery.empty) await upBatch.commit();

  const reportUpdate = {
    status: "listing_removed",
    listingRemovedAt: ts,
    ...(uid ? {listingRemovedBy: uid} : {}),
    updatedAt: ts,
  };
  const rq = await db
    .collection("provider_reports")
    .where("providerId", "==", providerId)
    .limit(500)
    .get();
  const chunk = 400;
  for (let i = 0; i < rq.docs.length; i += chunk) {
    const rb = db.batch();
    rq.docs.slice(i, i + chunk).forEach((d) => rb.update(d.ref, reportUpdate));
    await rb.commit();
  }

  return {
    success: true,
    providerId,
    blocksWritten: keys.size,
    providerDocExisted: pSnap.exists,
    storageFilesDeleted,
  };
  },
);

/**
 * Create missing provider_identity_claims rows for providers that already have
 * review-sourced identityTags with verificationStatus pending (e.g. written before
 * the app started enqueueing claims). Callable — admin dashboard roles only.
 */
exports.adminBackfillProviderIdentityClaims = onCall(
  {cors: true},
  async (request) => {
    await assertAdminDashboardUser(request.auth);
    const uid = request.auth.uid;
    const rawMax =
      request.data && request.data.maxProviders != null
        ? request.data.maxProviders
        : 150;
    const maxProviders = Math.min(
      Math.max(Number.parseInt(String(rawMax), 10) || 150, 1),
      500,
    );
    const startAfterId =
      request.data && request.data.startAfter != null
        ? String(request.data.startAfter).trim()
        : "";

    const db = admin.firestore();
    let q = db
      .collection("providers")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(maxProviders);
    if (startAfterId) {
      q = q.startAfter(startAfterId);
    }
    const snap = await q.get();
    if (snap.empty) {
      return {
        success: true,
        created: 0,
        scanned: 0,
        done: true,
        nextStartAfter: null,
      };
    }

    let writeBatch = db.batch();
    let writeCount = 0;
    let created = 0;
    let scanned = 0;

    const flush = async () => {
      if (writeCount === 0) return;
      await writeBatch.commit();
      writeBatch = db.batch();
      writeCount = 0;
    };

    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data() || {};
      if (data.directoryHidden === true) continue;

      const tags = Array.isArray(data.identityTags) ? data.identityTags : [];
      const pendingReview = tags.filter(
        (t) =>
          t &&
          typeof t === "object" &&
          t.source === "review" &&
          (t.verificationStatus === "pending" || t.verificationStatus == null),
      );
      if (!pendingReview.length) continue;

      const cq = await db
        .collection("provider_identity_claims")
        .where("providerId", "==", doc.id)
        .get();
      const existing = new Set();
      cq.forEach((c) => {
        const d = c.data();
        if (d.tagId != null) existing.add(String(d.tagId));
      });

      for (const tag of pendingReview) {
        const tagId = tag.id != null ? String(tag.id) : "";
        if (!tagId || existing.has(tagId)) continue;

        const cref = db.collection("provider_identity_claims").doc();
        writeBatch.set(cref, {
          providerId: doc.id,
          userId: `backfill:${uid}`,
          tagId,
          tagName: tag.name != null ? String(tag.name) : tagId,
          category: tag.category != null ? String(tag.category) : "identity",
          status: "pending",
          sourceType: "review_backfill",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          backfilledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        existing.add(tagId);
        created++;
        writeCount++;
        if (writeCount >= 400) await flush();
      }
    }

    await flush();

    const lastId = snap.docs[snap.docs.length - 1].id;
    return {
      success: true,
      created,
      scanned,
      done: snap.size < maxProviders,
      nextStartAfter: snap.size < maxProviders ? null : lastId,
    };
  },
);

// Admin function to add or update a provider manually (backend only)
// This allows admins to add providers and mark them as Mama Approved
exports.addProvider = onCall(async (request) => {
  // Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  // Check if user is admin (you can customize this check)
  // For now, we'll allow any authenticated user - you should add admin check
  const { uid } = request.auth;
  
  // TODO: Add admin check here
  // const userDoc = await admin.firestore().collection("users").doc(uid).get();
  // if (!userDoc.exists || userDoc.data().role !== "admin") {
  //   throw new HttpsError("permission-denied", "Admin access required");
  // }

  const {
    name,
    specialty,
    practiceName,
    npi,
    locations,
    providerTypes,
    specialties,
    phone,
    email,
    website,
    mamaApproved = false,
    identityTags = [],
    acceptsPregnantWomen,
    acceptsNewborns,
    telehealth,
  } = request.data;

  // Validate required fields
  if (!name) {
    throw new HttpsError("invalid-argument", "Provider name is required");
  }

  try {
    // Check if provider already exists by NPI
    let providerId = null;
    if (npi) {
      const existingQuery = await admin.firestore()
        .collection("providers")
        .where("npi", "==", npi)
        .limit(1)
        .get();
      
      if (!existingQuery.empty) {
        providerId = existingQuery.docs[0].id;
      }
    }

    // Prepare provider data
    const providerData = {
      name: name,
      specialty: specialty || null,
      practiceName: practiceName || null,
      npi: npi || null,
      locations: Array.isArray(locations) ? locations : [],
      providerTypes: Array.isArray(providerTypes) ? providerTypes : [],
      specialties: Array.isArray(specialties) ? specialties : [],
      phone: phone || null,
      email: email || null,
      website: website || null,
      mamaApproved: mamaApproved === true,
      mamaApprovedCount: mamaApproved ? 1 : 0,
      identityTags: Array.isArray(identityTags) ? identityTags : [],
      acceptsPregnantWomen: acceptsPregnantWomen !== undefined ? acceptsPregnantWomen : null,
      acceptsNewborns: acceptsNewborns !== undefined ? acceptsNewborns : null,
      telehealth: telehealth !== undefined ? telehealth : null,
      source: "admin_added",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (providerId) {
      // Update existing provider
      await admin.firestore()
        .collection("providers")
        .doc(providerId)
        .update({
          ...providerData,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(`[Admin] Updated provider ${providerId}: ${name}`);
    } else {
      // Create new provider
      const docRef = await admin.firestore()
        .collection("providers")
        .add(providerData);
      providerId = docRef.id;
      console.log(`[Admin] Created provider ${providerId}: ${name}`);
    }

    return {
      success: true,
      providerId: providerId,
      message: providerId ? "Provider updated" : "Provider created",
    };
  } catch (error) {
    console.error("Error in addProvider:", error);
    throw new HttpsError("internal", "Failed to add provider: " + error.message);
  }
});

/**
 * OhioMaximusSearch - Ohio Medicaid directory search (Maximus FHIR API).
 *
 * Request (unchanged): {zip, radius, city?, healthPlan, providerType (code/name or array), state?}
 * Response: {success, url, urls, providers, count, parameters, coverage, timingsMs}
 *   providers: one row per provider (duplicates merged), nearest in-radius location first,
 *   each location with distance/latitude/longitude, plus distanceMiles and healthPlans.
 * See functions/providerSearchEngine.js for how the API's 100-result cap is handled.
 */
exports.OhioMaximusSearch = onCall({timeoutSeconds: 120, memory: "512MiB"}, async (request) => {
  // Same behaviour as searchProviders for unauthenticated calls.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const t0 = Date.now();
  const {
    zip,
    radius,
    city,
    healthPlan,
    providerType,
    state = "OH",
  } = request.data || {};

  if (!zip || !radius || !healthPlan || !providerType) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: zip, radius, healthPlan, and providerType are required",
    );
  }
  const radiusMiles = Number(radius);
  if (!Number.isFinite(radiusMiles) || radiusMiles <= 0) {
    throw new HttpsError("invalid-argument", "radius must be a positive number of miles");
  }

  // Provider Type Code Mapping (exact as provided)
  const providerTypeCodeMap = {
      "Acupuncturist": "23",
      "Adaptive Behavior Service Provider": "53",
      "Ambulance": "82",
      "Ambulatory Surgery Center": "46",
      "Anesthesia Assistant Individual": "68",
      "Audiologist Individual": "43",
      "Behavioral Health Para-professionals": "96",
      "Certified Registered Nurse Anesthetist Individual": "73",
      "Chemical Dependency": "54",
      "Chiropractor Individual": "27",
      "Clinic": "50",
      "Clinical Counseling": "47",
      "Clinical Nurse Specialist Individual": "65",
      "Dentist Individual": "30",
      "Dodd Targeted Case Management": "85",
      "Doula": "09",
      "Durable Medical Equipment Supplier": "76",
      "End-stage Renal Disease Clinic": "59",
      "Enhanced Care Management": "78",
      "Federally Qualified Health Center": "12",
      "Free Standing Birth Center": "11",
      "Help Me Grow": "06",
      "Home And Community Based Oda Assisted Living": "74",
      "Hospice": "44",
      "Hospital": "01",
      "Independent Diagnostic Testing Facility": "79",
      "Independent Laboratory": "80",
      "Managed Care Organization Panel Provider Only": "19",
      "Marriage And Family Therapy": "52",
      "Medicaid School Program": "28",
      "Medicare Certified Home Health Agency": "60",
      "Mental Health Clinic": "51",
      "Non-agency Home Care Attendant": "26",
      "Non-agency Nurse -- Rn Or Lpn": "38",
      "Non-agency Personal Care Aide": "25",
      "Non-state Operated Icf-dd": "89",
      "Nurse Midwife Individual": "71",
      "Nurse Practitioner Individual": "72",
      "Nursing Facility": "86",
      "Occupational Therapist, Individual": "41",
      "Ohio Department Of Mental Health Provider": "84",
      "Omhas Certified/licensed Treatment Program": "95",
      "Optician/ocularist": "75",
      "Optometrist Individual": "35",
      "Other Accredited Home Health Agency": "16",
      "Outpatient Health Facility": "04",
      "Pace": "08",
      "Pediatric Recovery Center": "10",
      "Pharmacist": "69",
      "Pharmacy": "70",
      "Physical Therapist, Individual": "39",
      "Physician Assistant": "24",
      "Physician/osteopath Individual": "20",
      "Podiatrist Individual": "36",
      "Portable X-ray Supplier": "81",
      "Professional Dental Group": "31",
      "Professional Medical Group": "21",
      "Psychiatric Hospital": "02",
      "Psychiatric Residential Treatment Facility": "03",
      "Psychology": "42",
      "Registered Dietitian Nutritionist": "07",
      "Rural Health Clinic": "05",
      "Social Work": "37",
      "Speech Language Pathologist Individual": "40",
      "State Operated Icf-dd": "88",
      "Waivered Services Individual": "55",
      "Waivered Services Organization": "45",
      "Wheelchair Van": "83",
  };

  const toCode = (type) => {
    const trimmedType = String(type).trim();
    if (/^\d+$/.test(trimmedType)) return normalizeProviderTypeId(trimmedType);
    const code = providerTypeCodeMap[trimmedType];
    if (!code) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid provider type: "${trimmedType}". Please use a valid provider type name or code.`,
      );
    }
    return normalizeProviderTypeId(code);
  };
  const providerTypeIds = [...new Set((Array.isArray(providerType) ? providerType : [providerType]).map(toCode))];
  const searchZip = engine.zip5(zip) || String(zip).trim();
  const normalizedHealthPlan = normalizeHealthPlanName(String(healthPlan));

  try {
    const result = await engine.searchMedicaid({
      zip: searchZip,
      city,
      state: state || "OH",
      plan: normalizedHealthPlan,
      typeIds: providerTypeIds,
      radius: radiusMiles,
      deadlineMs: OMX_MEDICAID_DEADLINE_MS,
    });
    const providers = result.providers.map(serializeProvider);
    const ms = Date.now() - t0;
    console.log(`[OhioMaximusSearch] zip=${searchZip} radius=${radiusMiles} plan="${healthPlan}" -> ` +
      `"${normalizedHealthPlan}" types=${providerTypeIds.join(",")}: ${providers.length} providers in ${ms}ms ` +
      `(queries ${result.meta.queries}, cache hits ${result.meta.cacheHits}, partial ${result.meta.partial})`);
    return {
      success: true,
      url: result.meta.urls[0] || engine.buildMaximusUrl({zip: searchZip, state, plan: normalizedHealthPlan,
        typeId: providerTypeIds[0], radius: radiusMiles}),
      urls: result.meta.urls,
      providers,
      count: providers.length,
      parameters: {
        zip: searchZip,
        city: city || null,
        state: state,
        healthPlan: normalizedHealthPlan,
        providerTypeIds: providerTypeIds,
        providerTypeIdsDelimited: providerTypeIds.join(","),
        radius: String(radius),
      },
      coverage: {
        origin: result.meta.origin,
        radiusMiles,
        radiusLimitMiles: Math.round(engine.radiusLimit(radiusMiles) * 100) / 100,
        healthPlan: normalizedHealthPlan,
        completeWithinMiles: result.meta.completeWithinMiles,
        partial: result.meta.partial,
        medicaid: result.meta,
      },
      timingsMs: {total: ms, medicaid: result.meta.ms},
    };
  } catch (error) {
    console.error(`[OhioMaximusSearch] Error: ${error.message}`, error.stack);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "Ohio Medicaid search failed: " + error.message);
  }
});


/**
 * Import BIPOC providers from Excel file
 * Can be called with a file path or storage path
 */
exports.importBipocProviders = onCall(async (request) => {
  // Validate authentication
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { uid } = request.auth;
  
  // TODO: Add admin check here
  // const userDoc = await admin.firestore().collection("users").doc(uid).get();
  // if (!userDoc.exists || userDoc.data().role !== "admin") {
  //   throw new HttpsError("permission-denied", "Admin access required");
  // }

  const { filePath, storagePath } = request.data;

  if (!filePath && !storagePath) {
    throw new HttpsError(
      "invalid-argument",
      "Either filePath (local) or storagePath (Firebase Storage) is required"
    );
  }

  const importFn = getImportBipocProviders();
  if (!importFn) {
    throw new HttpsError(
      "unavailable",
      "Import function not available. Please ensure importBipocProviders.js is properly configured."
    );
  }

  try {
    let excelFilePath = filePath;

    // If storagePath is provided, download from Firebase Storage
    if (storagePath) {
      const bucket = admin.storage().bucket();
      const file = bucket.file(storagePath);
      const [exists] = await file.exists();
      
      if (!exists) {
        throw new HttpsError("not-found", `File not found in storage: ${storagePath}`);
      }

      // Download to temp location
      const path = require("path");
      const os = require("os");
      const fs = require("fs");
      const tempDir = os.tmpdir();
      const tempFilePath = path.join(tempDir, `bipoc_providers_${Date.now()}.xlsx`);
      
      await file.download({ destination: tempFilePath });
      excelFilePath = tempFilePath;
      
      console.log(`Downloaded file from storage to: ${tempFilePath}`);
    }

    // Import providers
    await importFn(excelFilePath);

    // Clean up temp file if it was downloaded
    if (storagePath && excelFilePath) {
      const fs = require("fs");
      try {
        fs.unlinkSync(excelFilePath);
      } catch (e) {
        console.warn("Failed to delete temp file:", e);
      }
    }

    return {
      success: true,
      message: "BIPOC providers imported successfully",
    };
  } catch (error) {
    console.error("Error importing BIPOC providers:", error);
    throw new HttpsError("internal", "Failed to import providers: " + error.message);
  }
});

// FCM push notifications (learning modules, weekly todos, trimester, community)
Object.assign(exports, require("./pushNotifications"));

// Pregnancy-loss support mode (emotional check-in → home)
Object.assign(exports, require("./enterPregnancyLossSupportMode"));
