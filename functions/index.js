const {onCall, HttpsError} = require("firebase-functions/v2/https");
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

  try {
    const openai = getOpenAIClient(openaiApiKey.value());
    const response = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        {
          role: "system",
          content: `You are a maternal health educator creating personalized content for pregnant women. 
Create medically accurate, clear, and supportive content at a ${readingLevel} reading level. 
Use a professional, clinical tone. Avoid casual terms like "momma" or overly informal language.
Include practical medical information, evidence-based guidance, and when to seek medical attention.
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
          content: `You are a medical interpreter helping pregnant women understand their medical visits. 
Translate medical information into clear, accessible language at a 6th grade reading level. 
Use professional, clinical language. Avoid casual terms like "momma". 
Be supportive and factual. Organize information clearly with headers.`,
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
          content: `You are a birth planning specialist helping create personalized birth plans. Create a comprehensive 
yet accessible birth plan that respects the patient's wishes while being medically informed. 
Use professional, clinical language and a 6th grade reading level. Avoid casual terms like "momma".`,
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
Avoid casual terms like "momma". Be supportive and thorough.`,
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
          content: `You are a healthcare advocate. Analyze text for emotional content, 
confusion, concerns, or distress. Identify moments that might need follow-up or support. 
Use professional, clinical language. Avoid casual terms. Provide clear, supportive recommendations.`,
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

// 7. After-Visit Summary - Summarize uploaded PDF with specific structure
exports.summarizeAfterVisitPDF = onCall(
  {secrets: [openaiApiKey]},
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
        console.error("Validation error: pdfText is missing or empty");
        throw new Error("PDF text is required and cannot be empty");
      }

      if (!appointmentDate) {
        console.error("Validation error: appointmentDate is missing");
        throw new Error("Appointment date is required");
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

      const readingLevel = educationLevel ? getReadingLevel(educationLevel.toString()) : "6th grade";

      console.log("Calling OpenAI API...");
      const openai = getOpenAIClient(openaiApiKey.value());
      const response = await openai.chat.completions.create({
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: `You are a culturally affirming, trauma-informed medical interpreter specializing in maternal health advocacy. 
Generate a comprehensive, plain-language visit summary at a ${readingLevel} reading level using professional clinical language. 
Avoid casual terms like "momma". Structure your response as a JSON object with specific sections.`,
          },
          {
            role: "user",
            content: `Generate a culturally affirming, plain-language learning module for EmpowerHealth Watch based on the following visit summary. 
Explain medical terms clearly, outline next steps, offer advocacy questions the mother can ask, and provide supportive, trauma-informed language. 
Tailor the content to her trimester (${trimester}), stated concerns (${JSON.stringify(concerns)}), and birth preferences (${JSON.stringify(birthPlanPreferences)}). 
Include a short explanation, what to expect, questions to ask, and when to seek help.

Visit Summary:
${pdfText}

User Context:
- Trimester: ${trimester}
- Concerns: ${concerns.join(", ") || "None specified"}
- Birth Plan Preferences: ${birthPlanPreferences.join(", ") || "None specified"}
- Cultural/Trauma-Informed Preferences: ${culturalPreferences.concat(traumaInformedPreferences).join(", ") || "None specified"}
- Learning Style: ${learningStyle}

Return a JSON object with the following structure:
{
  "summary": {
    "howBabyIsDoing": "Brief summary of fetal health, measurements, heartbeat, movements, development",
    "howYouAreDoing": "Brief summary of maternal health, vitals, symptoms, concerns addressed",
    "keyMedicalTerms": [
      {"term": "term name", "explanation": "plain language explanation"}
    ],
    "nextSteps": "Plain language breakdown of next steps",
    "questionsToAsk": [
      "Question 1",
      "Question 2"
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
    "followUpInstructions": "Instructions for follow-up care",
    "providerCommunicationStyle": "Description of communication style if flagged (rushed, unclear, dismissive, etc.)",
    "emotionalMarkers": ["confused", "scared", "unsure", etc. if detected],
    "advocacyMoments": ["Provider said XYZ without explanation", etc.],
    "contradictions": ["Any contradictions or missing explanations"]
  },
  "todos": [
    {"title": "Todo title", "description": "Todo description", "category": "advocacy|followup|medication|test"},
    ...
  ],
  "learningModules": [
    {"title": "Module title", "description": "Why this is relevant", "reason": "Based on visit content"},
    ...
  ],
  "redFlags": [
    {"type": "mistreatment|unclear|dismissive", "description": "What was flagged"}
  ]
}

IMPORTANT: 
- Create todos for: empowerment/advocacy tips, follow-up instructions, medications to take, tests to schedule
- Create learning modules for: new diagnoses, tests/procedures discussed, medications, provider communication issues, contradictions/missing explanations
- Flag potential mistreatment, unclear communication, or dismissive behavior
- Use trauma-informed, culturally affirming language throughout
- Make all explanations accessible at ${readingLevel} reading level`,
          },
        ],
        temperature: 0.7,
        max_tokens: 4000,
        response_format: { type: "json_object" },
      });

      if (!response.choices || response.choices.length === 0 || !response.choices[0].message.content) {
        console.error("OpenAI API error: Empty or invalid response");
        throw new Error("OpenAI API returned an invalid response");
      }

      const responseContent = response.choices[0].message.content;
      console.log("OpenAI response received, length:", responseContent.length);
      
      let parsedResponse;
      
      try {
        parsedResponse = JSON.parse(responseContent);
        console.log("JSON parsed successfully");
      } catch (parseError) {
        console.error("JSON parse error:", parseError);
        console.error("Response content (first 500 chars):", responseContent.substring(0, 500));
        // Fallback if JSON parsing fails
        parsedResponse = {
          summary: {
            howBabyIsDoing: "Unable to parse response",
            howYouAreDoing: responseContent,
            keyMedicalTerms: [],
            nextSteps: "",
            questionsToAsk: [],
            empowermentTips: [],
            newDiagnoses: [],
            testsProcedures: [],
            medications: [],
            followUpInstructions: "",
            providerCommunicationStyle: "",
            emotionalMarkers: [],
            advocacyMoments: [],
            contradictions: []
          },
          todos: [],
          learningModules: [],
          redFlags: []
        };
      }

      // Save to Firestore under user's profile
      console.log("Saving summary to Firestore...");
      const summaryRef = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .collection("visit_summaries")
          .add({
        appointmentDate: appointmentDate,
        originalText: pdfText.substring(0, 10000), // Limit text size for Firestore
        summary: parsedResponse.summary,
        todos: parsedResponse.todos || [],
        learningModules: parsedResponse.learningModules || [],
        redFlags: parsedResponse.redFlags || [],
        readingLevel: readingLevel,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log("Summary saved with ID:", summaryRef.id);

      // Create todos in learning_tasks collection
      if (parsedResponse.todos && Array.isArray(parsedResponse.todos) && parsedResponse.todos.length > 0) {
        console.log("Creating todos:", parsedResponse.todos.length);
        const todosBatch = admin.firestore().batch();
        parsedResponse.todos.forEach((todo) => {
          if (!todo || !todo.title) {
            console.warn("Skipping invalid todo:", todo);
            return;
          }
          const todoRef = admin.firestore()
              .collection("learning_tasks")
              .doc();
          todosBatch.set(todoRef, {
            userId: request.auth.uid,
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
        console.log("Todos created successfully");
      }

      // Create learning modules
      if (parsedResponse.learningModules && Array.isArray(parsedResponse.learningModules) && parsedResponse.learningModules.length > 0) {
        console.log("Creating learning modules:", parsedResponse.learningModules.length);
        const modulesBatch = admin.firestore().batch();
        parsedResponse.learningModules.forEach((module) => {
          if (!module || !module.title) {
            console.warn("Skipping invalid module:", module);
            return;
          }
          const moduleRef = admin.firestore()
              .collection("learning_tasks")
              .doc();
          modulesBatch.set(moduleRef, {
            userId: request.auth.uid,
            title: module.title.toString(),
            description: (module.description || module.reason || "").toString(),
            trimester: trimester,
            isGenerated: true,
            visitSummaryId: summaryRef.id,
            moduleType: "visit_based",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        await modulesBatch.commit();
        console.log("Learning modules created successfully");
      }

      // Format summary for display
      const formattedSummary = formatSummaryForDisplay(parsedResponse.summary);

      console.log("Function completed successfully");
      return {
        success: true, 
        summary: formattedSummary,
        todos: parsedResponse.todos || [],
        learningModules: parsedResponse.learningModules || [],
        redFlags: parsedResponse.redFlags || []
      };
    } catch (error) {
      console.error("Error in summarizeAfterVisitPDF:", error);
      console.error("Error stack:", error.stack);
      console.error("Error message:", error.message);
      
      // Provide more specific error messages
      if (error.message && error.message.includes("authentication")) {
        throw new HttpsError("unauthenticated", error.message);
      } else if (error.message && (error.message.includes("required") || error.message.includes("missing"))) {
        throw new HttpsError("invalid-argument", error.message);
      } else {
        // For internal errors, include the error message in the response
        throw new HttpsError(
          "internal", 
          `Failed to summarize visit: ${error.message || "Unknown error"}`
        );
      }
    }
  }
);

// Helper function to format summary for display
function formatSummaryForDisplay(summary) {
  let formatted = "";
  
  if (summary.howBabyIsDoing) {
    formatted += `## How Your Baby Is Doing\n${summary.howBabyIsDoing}\n\n`;
  }
  
  if (summary.howYouAreDoing) {
    formatted += `## How You Are Doing\n${summary.howYouAreDoing}\n\n`;
  }
  
  if (summary.keyMedicalTerms && summary.keyMedicalTerms.length > 0) {
    formatted += `## Key Medical Terms Explained\n`;
    summary.keyMedicalTerms.forEach(term => {
      formatted += `**${term.term}**: ${term.explanation}\n`;
    });
    formatted += `\n`;
  }
  
  if (summary.nextSteps) {
    formatted += `## Next Steps\n${summary.nextSteps}\n\n`;
  }
  
  if (summary.questionsToAsk && summary.questionsToAsk.length > 0) {
    formatted += `## Questions to Ask at Your Next Visit\n`;
    summary.questionsToAsk.forEach((q, i) => {
      formatted += `${i + 1}. ${q}\n`;
    });
    formatted += `\n`;
  }
  
  if (summary.empowermentTips && summary.empowermentTips.length > 0) {
    formatted += `## Empowerment & Advocacy Tips\n`;
    summary.empowermentTips.forEach((tip, i) => {
      formatted += `${i + 1}. ${tip}\n`;
    });
    formatted += `\n`;
  }
  
  if (summary.newDiagnoses && summary.newDiagnoses.length > 0) {
    formatted += `## New Diagnoses Explained\n`;
    summary.newDiagnoses.forEach(diag => {
      formatted += `**${diag.diagnosis}**: ${diag.explanation}\n`;
    });
    formatted += `\n`;
  }
  
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
  
  if (summary.medications && summary.medications.length > 0) {
    formatted += `## Medications Discussed\n`;
    summary.medications.forEach(med => {
      formatted += `**${med.name}**: ${med.purpose}\n`;
      if (med.instructions) {
        formatted += `   *How to take: ${med.instructions}*\n`;
      }
    });
    formatted += `\n`;
  }
  
  if (summary.followUpInstructions) {
    formatted += `## Follow-Up Instructions\n${summary.followUpInstructions}\n\n`;
  }
  
  if (summary.providerCommunicationStyle) {
    formatted += `## Provider Communication Notes\n${summary.providerCommunicationStyle}\n\n`;
  }
  
  if (summary.advocacyMoments && summary.advocacyMoments.length > 0) {
    formatted += `## Advocacy Moments\n`;
    summary.advocacyMoments.forEach((moment, i) => {
      formatted += `${i + 1}. ${moment}\n`;
    });
    formatted += `\n`;
  }
  
  if (summary.contradictions && summary.contradictions.length > 0) {
    formatted += `## Important Notes\n`;
    summary.contradictions.forEach((contradiction, i) => {
      formatted += `${i + 1}. ${contradiction}\n`;
    });
    formatted += `\n`;
  }
  
  return formatted;
}

