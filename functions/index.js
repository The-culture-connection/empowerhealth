const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const {OpenAI} = require("openai");
const axios = require("axios");
const XLSX = require("xlsx");
const path = require("path");
const fs = require("fs");
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
          content: `You are a culturally affirming, trauma-informed maternal health educator creating personalized content for EmpowerHealth Watch. Create detailed, comprehensive learning modules that are warm, supportive, and empowering. Use plain language at a ${readingLevel} reading level. Emphasize: Your rights, Your choices, Your voice. Brand voice: "Your Health. Your Voice. Your Empowerment."`,
        },
        {
          role: "user",
          content: `Create a detailed, comprehensive learning module about "${topic}" for ${trimester} trimester. Type: ${moduleType}.

${personalContext}

${userProfile?.insuranceType ? `Insurance Type: ${userProfile.insuranceType}. Tailor information for this insurance type, including coverage considerations, what's typically covered, and any cost considerations.` : "Provide insurance-agnostic guidance that applies regardless of insurance type."}

CRITICAL: This module must be DETAILED (not high-level) and follow this EXACT structure:

1. **What This Is (Simple Explanation)** - Clear, plain-language explanation of what this is
2. **Why It Matters for Your Health** - Explain the "why" behind the "what" - why this matters, why it's important, what happens if ignored. Be detailed and specific.
3. **What to Expect** - Step-by-step, detailed guidance on what will happen. Be specific and clear.
4. **What You Can Ask or Say** - At least 3 specific advocacy questions/prompts the mother can use during appointments. Examples: "Can you explain why this test is needed?", "What are my options?", "What happens if I don't do this?"
5. **Risks, Options, and Alternatives** - Balanced, non-fearful information about risks, options, and alternatives. Be honest but not alarming.
6. **When to Seek Medical Help** - Clear, specific guidance on when to call provider or seek emergency care
7. **How This Connects to Your Empowerment** - How this topic relates to self-advocacy, empowerment, and informed decision-making
8. **Key Points** - 3-5 key takeaways in bullet format
9. **Your Rights** - 2-3 specific rights related to this topic (e.g., right to ask questions, right to refuse, right to second opinion)
10. **Insurance Notes** - ${userProfile?.insuranceType ? `Specific information for ${userProfile.insuranceType} insurance, including coverage, costs, and what to ask your insurance about.` : "Insurance-agnostic guidance on what to ask your insurance provider about coverage and costs."}

TONE & VOICE REQUIREMENTS:
- Warm, supportive, nonjudgmental language
- Sound like: "Here's what this test means and why it matters. You deserve clear explanations and the chance to ask questions."
- Trauma-informed: Acknowledge possible fears, past negative experiences, pressure. Use supportive language that reassures and centers safety.
- Cultural responsiveness: Reflect realities Black mothers may face (bias, being dismissed, rushed). Use validating, empowering language.
- Avoid: Fear-based language, provider-blaming, cultural stereotypes, overly technical explanations, long paragraphs without breaks
- Use: Short paragraphs, bulleted lists, defined terms

Keep everything at ${readingLevel} reading level. Make it personally relevant based on the user's profile. Return the content in a structured format with clear sections.`,
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
      
      // If context is provided, use it as a custom system prompt for general AI assistant
      // Otherwise, use the default text simplification prompt
      const systemPrompt = textContext || `You are a medical communication expert who translates complex medical information 
into simple, clear language appropriate for a 6th grade reading level. Use short sentences, 
common words, and avoid medical jargon. When medical terms are necessary, explain them simply. 
Focus on what the person needs to know and do.`;

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

      const simplified = response.choices[0].message.content;
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

// Helper function to analyze PDF (extracted from summarizeAfterVisitPDF)
async function analyzeVisitSummaryPDF({pdfText, appointmentDate, educationLevel, userProfile, userId}) {
      console.log(`🟢 [DEBUG] analyzeVisitSummaryPDF HELPER function called`);
      console.log(`🟢 [DEBUG] Helper function params:`, {
        userId: userId,
        appointmentDate: appointmentDate,
        appointmentDateType: typeof appointmentDate,
        pdfTextLength: pdfText?.length || 0,
        hasEducationLevel: !!educationLevel,
        hasUserProfile: !!userProfile,
      });
      
      // Extract user context with safe defaults
      const trimester = (userProfile?.pregnancyStage || userProfile?.trimester || "Unknown").toString();
      const concerns = Array.isArray(userProfile?.concerns) ? userProfile.concerns : [];
      const birthPlanPreferences = Array.isArray(userProfile?.birthPlanPreferences) ? userProfile.birthPlanPreferences : [];
      const culturalPreferences = Array.isArray(userProfile?.culturalPreferences) ? userProfile.culturalPreferences : [];
      const traumaInformedPreferences = Array.isArray(userProfile?.traumaInformedPreferences) ? userProfile.traumaInformedPreferences : [];
      const learningStyle = (userProfile?.learningStyle || "visual").toString();
      const insuranceType = (userProfile?.insuranceType || "").toString();

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

  console.log("🤖 Calling OpenAI API for analysis...");
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
- Stated Concerns: ${concerns.join(", ") || "None specified"} (pain, safety, anxiety, postpartum issues)
- Birth Plan Preferences: ${birthPlanPreferences.join(", ") || "None specified"}
- Cultural/Trauma-Informed Preferences: ${culturalPreferences.concat(traumaInformedPreferences).join(", ") || "None specified"}
- Learning Style: ${learningStyle} (audio, visual, short summaries)
- Insurance Type: ${insuranceType || "Not specified - use insurance-agnostic guidance"}

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

CRITICAL REQUIREMENTS:
1. Explain key medical terms mentioned - add to keyMedicalTerms array
2. Break down next steps in plain language - add to nextSteps
3. Highlight questions to ask at the next visit - add to questionsToAsk
4. Provide empowerment + advocacy tips based on that specific encounter - add to empowermentTips AND create todos
5. Reinforce understanding of any new diagnoses, tests, or procedures - add to newDiagnoses/testsProcedures AND create learning modules
6. Flag potential mistreatment or unclear communication - add to redFlags
7. Tests or procedures recommended - add to testsProcedures AND create learning modules
8. Medications discussed - add to medications AND create learning modules
9. Follow-up instructions - turn into todos
10. Provider communication style (e.g., rushed, unclear, dismissive — if flagged by user or sentiment analysis) - add to providerCommunicationStyle AND create learning module
11. Emotional markers (mom tapped "confused," "scared," or "unsure") - add to emotionalMarkers
12. Advocacy moments (e.g., "provider said XYZ without explanation") - add to advocacyMoments
13. Any contradictions or missing explanations - add to contradictions AND create learning modules to bridge gap

TODOS: Create todos for:
- Empowerment/advocacy tips (category: "advocacy")
- Follow-up instructions (category: "followup")
- Medications to take (category: "medication")
- Tests to schedule (category: "test")

LEARNING MODULES: Create DETAILED, comprehensive learning modules (not high-level) for new diagnoses, tests/procedures discussed, medications, provider communication issues, contradictions/missing explanations.

Each learning module MUST follow this structure and be DETAILED:
1. **What This Is (Simple Explanation)** - Clear, plain-language explanation
2. **Why It Matters for Your Health** - Explain the "why" behind the "what" - why this matters, why it's important, what happens if ignored. Be detailed and specific.
3. **What to Expect** - Step-by-step, detailed guidance on what will happen
4. **What You Can Ask or Say** - At least 3 specific advocacy questions/prompts the mother can use
5. **Risks, Options, and Alternatives** - Balanced, non-fearful information
6. **When to Seek Medical Help** - Clear guidance on when to call provider
7. **How This Connects to Your Empowerment** - How this topic relates to self-advocacy and empowerment
8. **Key Points** - 3-5 key takeaways
9. **Your Rights** - 2-3 specific rights related to this topic
10. **Insurance Notes** - ${userProfile?.insuranceType ? `Tailor information for ${userProfile.insuranceType} insurance. Include coverage considerations, what's typically covered, and any cost considerations.` : "Provide insurance-agnostic guidance that applies regardless of insurance type."}

TONE & VOICE REQUIREMENTS:
- Warm, supportive, nonjudgmental language
- Sound like: "Here's what this test means and why it matters. You deserve clear explanations and the chance to ask questions."
- Trauma-informed (acknowledge possible fears, past negative experiences)
- Emphasize: Your rights, Your choices, Your voice
- Cultural responsiveness (acknowledge mistrust, bias, communication issues Black mothers may face)
- Avoid: Fear-based language, provider-blaming, cultural stereotypes, overly technical explanations, long paragraphs
- Use: Short paragraphs, bulleted lists, defined terms

Brand Voice: "Your Health. Your Voice. Your Empowerment."

Use trauma-informed, culturally affirming language throughout. Make all explanations accessible at ${readingLevel} reading level.`,
          },
        ],
        temperature: 0.7,
        max_tokens: 4000,
      });

      if (!response.choices || response.choices.length === 0 || !response.choices[0].message.content) {
    throw new Error("❌ OpenAI API returned an invalid response");
      }

      const responseContent = response.choices[0].message.content;
      let parsedResponse;
      
      try {
        parsedResponse = JSON.parse(responseContent);
      } catch (parseError) {
    console.error("❌ JSON parse error:", parseError);
    throw new Error("❌ Failed to parse AI response");
  }

  // Check for existing summary with same appointment date to prevent duplicates
      // Normalize appointment date to start of day for comparison
      // Parse the date string consistently - handle ISO 8601 format
      console.log(`🟢 [DEBUG] Helper: Starting duplicate check`);
      let appointmentDateObj;
      if (typeof appointmentDate === 'string') {
        console.log(`🟢 [DEBUG] Helper: Parsing date string: ${appointmentDate}`);
        // Parse ISO 8601 date string (e.g., "2026-02-12T00:00:00.000Z" or "2026-02-12")
        const dateStr = appointmentDate.split('T')[0]; // Get just the date part
        console.log(`🟢 [DEBUG] Helper: Extracted date part: ${dateStr}`);
        const [year, month, day] = dateStr.split('-').map(Number);
        console.log(`🟢 [DEBUG] Helper: Parsed components: year=${year}, month=${month}, day=${day}`);
        appointmentDateObj = new Date(Date.UTC(year, month - 1, day)); // month is 0-indexed
        console.log(`🟢 [DEBUG] Helper: Created Date object: ${appointmentDateObj.toISOString()}`);
      } else if (appointmentDate instanceof Date) {
        console.log(`🟢 [DEBUG] Helper: Date is already a Date object: ${appointmentDate.toISOString()}`);
        appointmentDateObj = appointmentDate;
      } else {
        console.log(`🟢 [DEBUG] Helper: Date is unknown type, using current date`);
        appointmentDateObj = new Date();
      }
      
      // Normalize to start of day in UTC to avoid timezone issues
      const normalizedDate = new Date(Date.UTC(
        appointmentDateObj.getUTCFullYear(),
        appointmentDateObj.getUTCMonth(),
        appointmentDateObj.getUTCDate(),
        0, 0, 0, 0 // Set to midnight UTC
      ));
      const appointmentTimestamp = admin.firestore.Timestamp.fromDate(normalizedDate);
      
      console.log(`📅 Normalized appointment date (helper): ${normalizedDate.toISOString()} (original: ${appointmentDate})`);
      console.log(`🟢 [DEBUG] Helper: Normalized date components: year=${normalizedDate.getUTCFullYear()}, month=${normalizedDate.getUTCMonth() + 1}, day=${normalizedDate.getUTCDate()}`);
      console.log(`🟢 [DEBUG] Helper: Firestore Timestamp: ${appointmentTimestamp.toDate().toISOString()}`);
      
      // Check if summary already exists for this date using range query to catch timezone variations
      const dayStart = admin.firestore.Timestamp.fromDate(new Date(Date.UTC(
        normalizedDate.getUTCFullYear(),
        normalizedDate.getUTCMonth(),
        normalizedDate.getUTCDate(),
        0, 0, 0, 0
      )));
      const dayEnd = admin.firestore.Timestamp.fromDate(new Date(Date.UTC(
        normalizedDate.getUTCFullYear(),
        normalizedDate.getUTCMonth(),
        normalizedDate.getUTCDate(),
        23, 59, 59, 999
      )));
      
      console.log(`🟢 [DEBUG] Helper: Checking for existing summaries between ${dayStart.toDate().toISOString()} and ${dayEnd.toDate().toISOString()}`);
      console.log(`🟢 [DEBUG] Helper: Query path: users/${userId}/visit_summaries`);
      
      // DEBUG: List ALL summaries for this user to see what exists
      let allSummaries;
      try {
        allSummaries = await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("visit_summaries")
          .orderBy("createdAt", "desc")
          .limit(10)
          .get();
      } catch (e) {
        // If orderBy fails (no index), just get without ordering
        console.log(`🟢 [DEBUG] Helper: orderBy failed, getting without order: ${e.message}`);
        allSummaries = await admin.firestore()
          .collection("users")
          .doc(userId)
          .collection("visit_summaries")
          .limit(10)
          .get();
      }
      console.log(`🟢 [DEBUG] Helper: Total summaries for user: ${allSummaries.size}`);
      allSummaries.docs.forEach((doc, idx) => {
        const data = doc.data();
        // Safely extract appointmentDate - handle Timestamp, Date, or string
        let appointmentDateStr = 'unknown';
        if (data.appointmentDate) {
          if (data.appointmentDate.toDate && typeof data.appointmentDate.toDate === 'function') {
            appointmentDateStr = data.appointmentDate.toDate().toISOString();
          } else if (data.appointmentDate instanceof Date) {
            appointmentDateStr = data.appointmentDate.toISOString();
          } else if (typeof data.appointmentDate === 'string') {
            appointmentDateStr = data.appointmentDate;
          } else {
            appointmentDateStr = String(data.appointmentDate);
          }
        }
        
        let createdAtStr = 'unknown';
        if (data.createdAt) {
          if (data.createdAt.toDate && typeof data.createdAt.toDate === 'function') {
            createdAtStr = data.createdAt.toDate().toISOString();
          } else if (data.createdAt instanceof Date) {
            createdAtStr = data.createdAt.toISOString();
          } else if (typeof data.createdAt === 'string') {
            createdAtStr = data.createdAt;
          }
        }
        
        console.log(`🟢 [DEBUG] Helper: Summary ${idx + 1}:`, {
          id: doc.id,
          appointmentDate: appointmentDateStr,
          appointmentDateTimestamp: data.appointmentDate?.seconds,
          createdAt: createdAtStr,
        });
      });
      
      // Get ALL summaries and filter client-side to handle both Timestamp and string formats
      const allUserSummaries = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("visit_summaries")
        .get();
      
      console.log(`🟢 [DEBUG] Helper: Total summaries in collection: ${allUserSummaries.size}`);
      
      // Filter client-side to find matches (handles both Timestamp and string formats)
      const matchingSummaries = allUserSummaries.docs.filter((doc) => {
        const data = doc.data();
        const existingDate = data.appointmentDate;
        
        if (!existingDate) return false;
        
        // Try to normalize the existing date
        let existingDateObj;
        if (existingDate.toDate && typeof existingDate.toDate === 'function') {
          // It's a Firestore Timestamp
          existingDateObj = existingDate.toDate();
        } else if (existingDate instanceof Date) {
          existingDateObj = existingDate;
        } else if (typeof existingDate === 'string') {
          // It's a string - parse it
          try {
            const dateStr = existingDate.split('T')[0];
            const [year, month, day] = dateStr.split('-').map(Number);
            existingDateObj = new Date(Date.UTC(year, month - 1, day));
          } catch (e) {
            return false;
          }
        } else {
          return false;
        }
        
        // Normalize to start of day for comparison
        const existingNormalized = new Date(Date.UTC(
          existingDateObj.getUTCFullYear(),
          existingDateObj.getUTCMonth(),
          existingDateObj.getUTCDate(),
          0, 0, 0, 0
        ));
        
        // Compare normalized dates
        return existingNormalized.getTime() === normalizedDate.getTime();
      });
      
      console.log(`🟢 [DEBUG] Helper: Client-side filter found: ${matchingSummaries.length} matching summaries`);
      
      let existingSummaries = { empty: matchingSummaries.length === 0, docs: matchingSummaries, size: matchingSummaries.length };
      
      console.log(`🟢 [DEBUG] Helper: Existing summaries found: ${existingSummaries.size}`);
      if (existingSummaries.size > 0) {
        existingSummaries.docs.forEach((doc, idx) => {
          const data = doc.data();
          // Safely extract appointmentDate - handle Timestamp, Date, or string
          let appointmentDateStr = 'unknown';
          if (data.appointmentDate) {
            if (data.appointmentDate.toDate && typeof data.appointmentDate.toDate === 'function') {
              appointmentDateStr = data.appointmentDate.toDate().toISOString();
            } else if (data.appointmentDate instanceof Date) {
              appointmentDateStr = data.appointmentDate.toISOString();
            } else if (typeof data.appointmentDate === 'string') {
              appointmentDateStr = data.appointmentDate;
            } else {
              appointmentDateStr = String(data.appointmentDate);
            }
          }
          
          let createdAtStr = 'unknown';
          if (data.createdAt) {
            if (data.createdAt.toDate && typeof data.createdAt.toDate === 'function') {
              createdAtStr = data.createdAt.toDate().toISOString();
            } else if (data.createdAt instanceof Date) {
              createdAtStr = data.createdAt.toISOString();
            } else if (typeof data.createdAt === 'string') {
              createdAtStr = data.createdAt;
            }
          }
          
          console.log(`🟢 [DEBUG] Helper: Existing summary ${idx + 1}:`, {
            id: doc.id,
            appointmentDate: appointmentDateStr,
            createdAt: createdAtStr,
            hasSummary: !!data.summary,
          });
        });
      }
      
      if (!existingSummaries.empty) {
        console.log(`⚠️ Summary already exists for appointment date ${normalizedDate.toISOString()}, skipping duplicate creation`);
        console.log(`🟢 [DEBUG] Helper: Returning existing summary ID: ${existingSummaries.docs[0].id}`);
        return {
          summaryId: existingSummaries.docs[0].id,
          summary: formatSummaryForDisplay(
            parsedResponse.summary,
            parsedResponse.learningModules || []
          ),
          todos: parsedResponse.todos || [],
          learningModules: parsedResponse.learningModules || [],
          redFlags: parsedResponse.redFlags || [],
        };
      }
      
      console.log(`🟢 [DEBUG] Helper: No existing summary found, will create new one`);

  // Save to Firestore
      const formattedSummary = formatSummaryForDisplay(
        parsedResponse.summary,
        parsedResponse.learningModules || []
      );
      
      console.log(`🟢 [DEBUG] Helper: Creating new summary document`);
      const summaryRef = await admin.firestore()
          .collection("users")
    .doc(userId)
          .collection("visit_summaries")
          .add({
        appointmentDate: appointmentTimestamp,
      originalText: pdfText.substring(0, 10000),
        summary: formattedSummary,
        summaryData: parsedResponse.summary,
        todos: parsedResponse.todos || [],
        learningModules: parsedResponse.learningModules || [],
        redFlags: parsedResponse.redFlags || [],
        readingLevel: readingLevel,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`🟢 [DEBUG] Helper: Created new summary with ID: ${summaryRef.id}`);
      console.log(`🟢 [DEBUG] Helper: New summary appointmentDate: ${appointmentTimestamp.toDate().toISOString()}`);

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

  console.log(`🟢 [DEBUG] Helper: Returning from analyzeVisitSummaryPDF helper function`);
  return {
    summaryId: summaryRef.id,
    summary: formattedSummary,
    todos: parsedResponse.todos || [],
    learningModules: parsedResponse.learningModules || [],
    redFlags: parsedResponse.redFlags || [],
  };
}

// 9. Analyze PDF directly with OpenAI (NO text extraction)
// Analyze Visit Summary PDF - Recreated to match working function structure exactly
exports.analyzeVisitSummaryPDF = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    const functionCallId = `CF-${Date.now()}-${Math.random().toString(36).substring(7)}`;
    console.log(`🔵 [DEBUG] ========================================`);
    console.log(`🔵 [DEBUG] analyzeVisitSummaryPDF Cloud Function called`);
    console.log(`🔵 [DEBUG] Function Call ID: ${functionCallId}`);
    console.log(`🔵 [DEBUG] User ID: ${request.auth?.uid || 'NOT AUTHENTICATED'}`);
    console.log(`🔵 [DEBUG] Timestamp: ${new Date().toISOString()}`);
    
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "🔒 User must be authenticated. Please log in.");
    }

    const data = request.data;
    const {
      storagePath,
      downloadUrl,
      appointmentDate,
      educationLevel,
      userProfile,
    } = data;
    
    console.log(`🔵 [DEBUG] Input data:`, {
      storagePath: storagePath?.substring(0, 50) + '...',
      downloadUrl: downloadUrl ? 'present' : 'missing',
      appointmentDate: appointmentDate,
      appointmentDateType: typeof appointmentDate,
      hasEducationLevel: !!educationLevel,
      hasUserProfile: !!userProfile,
    });
    
    // Check for processing lock to prevent concurrent executions
    const lockDocRef = admin.firestore()
      .collection("users")
      .doc(request.auth.uid)
      .collection("processing_locks")
      .doc(`visit_summary_${storagePath?.replace(/\//g, '_') || 'unknown'}`);
    
    const lockDoc = await lockDocRef.get();
    if (lockDoc.exists) {
      const lockData = lockDoc.data();
      const lockTime = lockData.timestamp?.toDate();
      const now = new Date();
      const lockAge = now - lockTime;
      
      // If lock is less than 5 minutes old, another process is likely running
      if (lockAge < 5 * 60 * 1000) {
        console.log(`🔵 [DEBUG] Processing lock found - another process may be running`);
        console.log(`🔵 [DEBUG] Lock age: ${lockAge}ms, Lock function: ${lockData.functionCallId}`);
        // Don't throw error, just log - we'll check for duplicates later
      }
    }
    
    // Create processing lock
    await lockDocRef.set({
      functionCallId: functionCallId,
      storagePath: storagePath,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`🔵 [DEBUG] Created processing lock: ${functionCallId}`);

    if (!storagePath && !downloadUrl) {
      throw new HttpsError("invalid-argument", "📄 PDF file location is required (storagePath or downloadUrl)");
    }

    if (!appointmentDate) {
      throw new HttpsError("invalid-argument", "📅 Appointment date is required");
    }

    // Extract user context
    const trimester = (userProfile?.pregnancyStage || userProfile?.trimester || "Unknown").toString();
    const concerns = Array.isArray(userProfile?.concerns) ? userProfile.concerns : [];
    const birthPlanPreferences = Array.isArray(userProfile?.birthPlanPreferences) ? userProfile.birthPlanPreferences : [];
    const culturalPreferences = Array.isArray(userProfile?.culturalPreferences) ? userProfile.culturalPreferences : [];
    const traumaInformedPreferences = Array.isArray(userProfile?.traumaInformedPreferences) ? userProfile.traumaInformedPreferences : [];
    const learningStyle = (userProfile?.learningStyle || "visual").toString();
    const insuranceType = (userProfile?.insuranceType || "").toString();

    // Determine reading level
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

    try {
      // Download PDF from Firebase Storage
      console.log(`📥 Downloading PDF from storage: ${storagePath}`);
      const bucket = admin.storage().bucket();
      const file = bucket.file(storagePath);
      const [exists] = await file.exists();
      if (!exists) {
        throw new HttpsError("not-found", `📄 PDF file not found at: ${storagePath}`);
      }
      const [pdfBuffer] = await file.download();
      console.log(`✅ Downloaded PDF: ${pdfBuffer.length} bytes`);

      // Upload PDF to OpenAI
      console.log(`📤 Uploading PDF to OpenAI...`);
      const openai = getOpenAIClient(openaiApiKey.value());
      
      // Create File object - Node.js 20 has File API available
      // The OpenAI SDK expects a File object with name, type, and stream/buffer
      const pdfFile = new File([pdfBuffer], "visit_summary.pdf", {
        type: "application/pdf",
      });
      console.log(`📄 Created File: ${pdfFile.name}, ${pdfFile.size} bytes, type: ${pdfFile.type}`);
      
      // Upload PDF to OpenAI for analysis
      // Note: OpenAI SDK accepts File objects in Node.js 20+
      const fileUpload = await openai.files.create({
        file: pdfFile,
        purpose: "assistants",
      });
      console.log(`✅ File uploaded to OpenAI: ${fileUpload.id}`);

      // Wait for file to be processed
      console.log(`⏳ Waiting for file to be processed...`);
      let fileStatus = await openai.files.retrieve(fileUpload.id);
      let attempts = 0;
      while (fileStatus.status !== "processed" && attempts < 60) {
        await new Promise(resolve => setTimeout(resolve, 2000));
        fileStatus = await openai.files.retrieve(fileUpload.id);
        attempts++;
        if (fileStatus.status === "error") {
          throw new HttpsError("internal", "❌ OpenAI file processing failed. Please try again.");
        }
        if (attempts % 10 === 0) {
          console.log(`⏳ Still processing... (attempt ${attempts}/60)`);
        }
      }
      if (fileStatus.status !== "processed") {
        throw new HttpsError("deadline-exceeded", "⏱️ File processing timed out. Please try again.");
      }
      console.log(`✅ File processed successfully`);

      // Use Assistants API - attach file to message correctly
      console.log(`🤖 Creating OpenAI assistant...`);
      const assistant = await openai.beta.assistants.create({
        name: "Visit Summary Analyzer",
        instructions: `You are a culturally affirming, trauma-informed medical interpreter specializing in maternal health advocacy. Analyze the uploaded PDF visit summary and generate a comprehensive, plain-language summary at a ${readingLevel} reading level using professional clinical language. Avoid casual terms like "momma".`,
        model: "gpt-4o", // Use stable model name
        tools: [{ type: "code_interpreter" }],
      });
      console.log(`✅ Assistant created: ${assistant.id}`);

      const thread = await openai.beta.threads.create();
      console.log(`✅ Thread created: ${thread.id}`);

      // Add message with file attachment
      console.log(`📝 Adding message with file attachment...`);
      await openai.beta.threads.messages.create(thread.id, {
        role: "user",
        content: `Generate a culturally affirming, plain-language learning module for EmpowerHealth Watch based on the following visit summary PDF. Explain medical terms clearly, outline next steps, offer advocacy questions the mother can ask, and provide supportive, trauma-informed language. Tailor the content to her trimester (${trimester}), stated concerns (${JSON.stringify(concerns)}), and birth preferences (${JSON.stringify(birthPlanPreferences)}). Include a short explanation, what to expect, questions to ask, and when to seek help.

User Context:
- Trimester: ${trimester}
- Stated Concerns: ${concerns.join(", ") || "None specified"} (pain, safety, anxiety, postpartum issues)
- Birth Plan Preferences: ${birthPlanPreferences.join(", ") || "None specified"}
- Cultural/Trauma-Informed Preferences: ${culturalPreferences.concat(traumaInformedPreferences).join(", ") || "None specified"}
- Learning Style: ${learningStyle} (audio, visual, short summaries)
- Insurance Type: ${insuranceType || "Not specified - use insurance-agnostic guidance"}

Return a JSON object with this exact structure:
{
  "summary": {
    "howBabyIsDoing": "Brief summary of fetal health, measurements, heartbeat, movements, development",
    "howYouAreDoing": "Brief summary of maternal health, vitals, symptoms, concerns addressed",
    "keyMedicalTerms": [{"term": "term name", "explanation": "plain language explanation"}],
    "nextSteps": "Plain language breakdown of next steps",
    "questionsToAsk": ["Question 1", "Question 2"],
    "empowermentTips": ["Advocacy tip 1", "Advocacy tip 2"],
    "newDiagnoses": [{"diagnosis": "name", "explanation": "plain language explanation"}],
    "testsProcedures": [{"name": "test/procedure name", "explanation": "what to expect", "whyNeeded": "reason"}],
    "medications": [{"name": "medication name", "purpose": "why prescribed", "instructions": "how to take"}],
    "followUpInstructions": "Instructions for follow-up care",
    "providerCommunicationStyle": "Description of communication style if flagged (rushed, unclear, dismissive, etc.)",
    "emotionalMarkers": ["confused", "scared", "unsure", etc. if detected],
    "advocacyMoments": ["Provider said XYZ without explanation", etc.],
    "contradictions": ["Any contradictions or missing explanations"]
  },
  "todos": [
    {"title": "Todo title", "description": "Todo description", "category": "advocacy|followup|medication|test"}
  ],
  "learningModules": [
    {
      "title": "Module title",
      "description": "Why this is relevant",
      "reason": "Based on visit content",
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
    }
  ],
  "redFlags": [
    {"type": "mistreatment|unclear|dismissive", "description": "What was flagged"}
  ]
}

CRITICAL REQUIREMENTS:
1. Explain key medical terms mentioned - add to keyMedicalTerms array
2. Break down next steps in plain language - add to nextSteps
3. Highlight questions to ask at the next visit - add to questionsToAsk
4. Provide empowerment + advocacy tips based on that specific encounter - add to empowermentTips AND create todos
5. Reinforce understanding of any new diagnoses, tests, or procedures - add to newDiagnoses/testsProcedures AND create learning modules
6. Flag potential mistreatment or unclear communication - add to redFlags
7. Tests or procedures recommended - add to testsProcedures AND create learning modules
8. Medications discussed - add to medications AND create learning modules
9. Follow-up instructions - turn into todos
10. Provider communication style (e.g., rushed, unclear, dismissive — if flagged by user or sentiment analysis) - add to providerCommunicationStyle AND create learning module
11. Emotional markers (mom tapped "confused," "scared," or "unsure") - add to emotionalMarkers
12. Advocacy moments (e.g., "provider said XYZ without explanation") - add to advocacyMoments
13. Any contradictions or missing explanations - add to contradictions AND create learning modules to bridge gap

TODOS: Create todos for empowerment/advocacy tips (category: "advocacy"), follow-up instructions (category: "followup"), medications to take (category: "medication"), tests to schedule (category: "test").

LEARNING MODULES: Create DETAILED, comprehensive learning modules (not high-level) for new diagnoses, tests/procedures discussed, medications, provider communication issues, contradictions/missing explanations.

Each learning module MUST follow this structure and be DETAILED:
1. **What This Is (Simple Explanation)** - Clear, plain-language explanation
2. **Why It Matters for Your Health** - Explain the "why" behind the "what" - why this matters, why it's important, what happens if ignored. Be detailed and specific.
3. **What to Expect** - Step-by-step, detailed guidance on what will happen
4. **What You Can Ask or Say** - At least 3 specific advocacy questions/prompts the mother can use
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

Use trauma-informed, culturally affirming language throughout. Make all explanations accessible at ${readingLevel} reading level. Return ONLY valid JSON.`,
        attachments: [
          {
            file_id: fileUpload.id,
            tools: [{ type: "code_interpreter" }],
          },
        ],
      });

      console.log(`🚀 Starting analysis run...`);
      const run = await openai.beta.threads.runs.create(thread.id, {
        assistant_id: assistant.id,
      });

      let runStatus = await openai.beta.threads.runs.retrieve(thread.id, run.id);
      let runAttempts = 0;
      while (runStatus.status !== "completed" && runAttempts < 120) {
        if (runStatus.status === "failed") {
          const errorMsg = runStatus.last_error?.message || "Unknown error";
          console.error(`❌ Run failed: ${errorMsg}`);
          throw new HttpsError("internal", `🤖 OpenAI analysis failed: ${errorMsg}`);
        }
        if (runStatus.status === "cancelled" || runStatus.status === "expired") {
          throw new HttpsError("deadline-exceeded", "⏱️ Analysis was cancelled or expired. Please try again.");
        }
        await new Promise(resolve => setTimeout(resolve, 2000));
        runStatus = await openai.beta.threads.runs.retrieve(thread.id, run.id);
        runAttempts++;
        if (runAttempts % 15 === 0) {
          console.log(`⏳ Analysis in progress... (${runAttempts * 2}s elapsed)`);
        }
      }
      if (runStatus.status !== "completed") {
        throw new HttpsError("deadline-exceeded", "⏱️ Analysis timed out. Please try again with a smaller PDF.");
      }
      console.log(`✅ Analysis completed`);

      console.log(`📥 Retrieving analysis results...`);
      const messages = await openai.beta.threads.messages.list(thread.id);
      const assistantMessage = messages.data.find(m => m.role === "assistant");
      
      if (!assistantMessage || !assistantMessage.content[0]?.text?.value) {
        console.error("❌ No response from OpenAI assistant");
        throw new HttpsError("internal", "🤖 No response received from AI. Please try again.");
      }

      const responseContent = assistantMessage.content[0].text.value;
      console.log(`✅ Received response (${responseContent.length} chars)`);
      let parsedResponse;
      try {
        const jsonMatch = responseContent.match(/```json\s*([\s\S]*?)\s*```/) || 
                         responseContent.match(/```\s*([\s\S]*?)\s*```/);
        const jsonString = jsonMatch ? jsonMatch[1] : responseContent;
        parsedResponse = JSON.parse(jsonString);
        console.log(`✅ Parsed JSON response successfully`);
      } catch (parseError) {
        console.error("❌ JSON parse error:", parseError);
        console.error("Response content:", responseContent.substring(0, 500));
        throw new HttpsError("internal", `❌ Failed to parse AI response: ${parseError.message}`);
      }

      // Clean up uploaded file and assistant
      try {
        await openai.files.del(fileUpload.id);
        await openai.beta.assistants.del(assistant.id);
        console.log(`🧹 Cleaned up OpenAI resources`);
      } catch (e) {
        console.warn("⚠️ Failed to clean up OpenAI resources:", e);
      }

      // Save to Firestore
      console.log(`💾 Saving results to Firestore...`);
      console.log(`🔵 [DEBUG] Starting duplicate check process`);
      
      // Normalize appointment date to start of day in UTC to avoid timezone issues
      // Parse the date string consistently - handle ISO 8601 format
      let appointmentDateObj;
      if (typeof appointmentDate === 'string') {
        console.log(`🔵 [DEBUG] Parsing date string: ${appointmentDate}`);
        // Parse ISO 8601 date string (e.g., "2026-02-12T00:00:00.000Z" or "2026-02-12")
        const dateStr = appointmentDate.split('T')[0]; // Get just the date part
        console.log(`🔵 [DEBUG] Extracted date part: ${dateStr}`);
        const [year, month, day] = dateStr.split('-').map(Number);
        console.log(`🔵 [DEBUG] Parsed components: year=${year}, month=${month}, day=${day}`);
        appointmentDateObj = new Date(Date.UTC(year, month - 1, day)); // month is 0-indexed
        console.log(`🔵 [DEBUG] Created Date object: ${appointmentDateObj.toISOString()}`);
      } else if (appointmentDate instanceof Date) {
        console.log(`🔵 [DEBUG] Date is already a Date object: ${appointmentDate.toISOString()}`);
        appointmentDateObj = appointmentDate;
      } else {
        console.log(`🔵 [DEBUG] Date is unknown type, using current date`);
        appointmentDateObj = new Date();
      }
      
      // Normalize to start of day in UTC (ensure we're using UTC to avoid timezone shifts)
      const normalizedDate = new Date(Date.UTC(
        appointmentDateObj.getUTCFullYear(),
        appointmentDateObj.getUTCMonth(),
        appointmentDateObj.getUTCDate(),
        0, 0, 0, 0 // Set to midnight UTC
      ));
      const appointmentTimestamp = admin.firestore.Timestamp.fromDate(normalizedDate);
      
      console.log(`📅 Normalized appointment date: ${normalizedDate.toISOString()} (original: ${appointmentDate})`);
      console.log(`🔵 [DEBUG] Normalized date components: year=${normalizedDate.getUTCFullYear()}, month=${normalizedDate.getUTCMonth() + 1}, day=${normalizedDate.getUTCDate()}`);
      console.log(`🔵 [DEBUG] Firestore Timestamp: ${appointmentTimestamp.toDate().toISOString()}`);
      
      // Check if summary already exists for this date to prevent duplicates
      // Use a range query to catch any timezone-related variations (within 24 hours)
      const dayStart = admin.firestore.Timestamp.fromDate(new Date(Date.UTC(
        normalizedDate.getUTCFullYear(),
        normalizedDate.getUTCMonth(),
        normalizedDate.getUTCDate(),
        0, 0, 0, 0
      )));
      const dayEnd = admin.firestore.Timestamp.fromDate(new Date(Date.UTC(
        normalizedDate.getUTCFullYear(),
        normalizedDate.getUTCMonth(),
        normalizedDate.getUTCDate(),
        23, 59, 59, 999
      )));
      
      console.log(`🔵 [DEBUG] Checking for existing summaries between ${dayStart.toDate().toISOString()} and ${dayEnd.toDate().toISOString()}`);
      console.log(`🔵 [DEBUG] Normalized timestamp to match: ${appointmentTimestamp.toDate().toISOString()}`);
      console.log(`🔵 [DEBUG] Query path: users/${request.auth.uid}/visit_summaries`);
      
      // DEBUG: List ALL summaries for this user to see what exists
      let allSummaries;
      try {
        allSummaries = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .collection("visit_summaries")
          .orderBy("createdAt", "desc")
          .limit(10)
          .get();
      } catch (e) {
        // If orderBy fails (no index), just get without ordering
        console.log(`🔵 [DEBUG] orderBy failed, getting without order: ${e.message}`);
        allSummaries = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .collection("visit_summaries")
          .limit(10)
          .get();
      }
      console.log(`🔵 [DEBUG] Total summaries for user: ${allSummaries.size}`);
      allSummaries.docs.forEach((doc, idx) => {
        const data = doc.data();
        // Safely extract appointmentDate - handle Timestamp, Date, or string
        let appointmentDateStr = 'unknown';
        let appointmentTimestampValue = null;
        if (data.appointmentDate) {
          if (data.appointmentDate.toDate && typeof data.appointmentDate.toDate === 'function') {
            appointmentDateStr = data.appointmentDate.toDate().toISOString();
            appointmentTimestampValue = data.appointmentDate;
          } else if (data.appointmentDate instanceof Date) {
            appointmentDateStr = data.appointmentDate.toISOString();
          } else if (typeof data.appointmentDate === 'string') {
            appointmentDateStr = data.appointmentDate;
          } else {
            appointmentDateStr = String(data.appointmentDate);
          }
        }
        
        let createdAtStr = 'unknown';
        if (data.createdAt) {
          if (data.createdAt.toDate && typeof data.createdAt.toDate === 'function') {
            createdAtStr = data.createdAt.toDate().toISOString();
          } else if (data.createdAt instanceof Date) {
            createdAtStr = data.createdAt.toISOString();
          } else if (typeof data.createdAt === 'string') {
            createdAtStr = data.createdAt;
          }
        }
        
        // Check if this summary matches our date
        let matchesDate = false;
        if (appointmentTimestampValue && appointmentTimestampValue.seconds) {
          const isInRange = appointmentTimestampValue.seconds >= dayStart.seconds && 
                           appointmentTimestampValue.seconds <= dayEnd.seconds;
          matchesDate = isInRange;
          console.log(`🔵 [DEBUG] Summary ${idx + 1} date comparison:`, {
            summaryTimestamp: appointmentTimestampValue.seconds,
            dayStart: dayStart.seconds,
            dayEnd: dayEnd.seconds,
            matches: isInRange,
          });
        }
        
        console.log(`🔵 [DEBUG] Summary ${idx + 1}:`, {
          id: doc.id,
          appointmentDate: appointmentDateStr,
          appointmentDateTimestamp: data.appointmentDate?.seconds,
          createdAt: createdAtStr,
          matchesOurDate: matchesDate,
        });
      });
      
      // Get ALL summaries and filter client-side to handle both Timestamp and string formats
      // This is necessary because older summaries may have appointmentDate as a string
      const allUserSummaries = await admin.firestore()
        .collection("users")
        .doc(request.auth.uid)
        .collection("visit_summaries")
        .get();
      
      console.log(`🔵 [DEBUG] Total summaries in collection: ${allUserSummaries.size}`);
      
      // Filter client-side to find matches (handles both Timestamp and string formats)
      const matchingSummaries = allUserSummaries.docs.filter((doc) => {
        const data = doc.data();
        const existingDate = data.appointmentDate;
        
        if (!existingDate) return false;
        
        // Try to normalize the existing date
        let existingDateObj;
        if (existingDate.toDate && typeof existingDate.toDate === 'function') {
          // It's a Firestore Timestamp
          existingDateObj = existingDate.toDate();
        } else if (existingDate instanceof Date) {
          existingDateObj = existingDate;
        } else if (typeof existingDate === 'string') {
          // It's a string - parse it
          try {
            const dateStr = existingDate.split('T')[0];
            const [year, month, day] = dateStr.split('-').map(Number);
            existingDateObj = new Date(Date.UTC(year, month - 1, day));
          } catch (e) {
            return false;
          }
        } else {
          return false;
        }
        
        // Normalize to start of day for comparison
        const existingNormalized = new Date(Date.UTC(
          existingDateObj.getUTCFullYear(),
          existingDateObj.getUTCMonth(),
          existingDateObj.getUTCDate(),
          0, 0, 0, 0
        ));
        
        // Compare normalized dates
        const matches = existingNormalized.getTime() === normalizedDate.getTime();
        
        if (matches) {
          console.log(`🔵 [DEBUG] Found matching summary: ${doc.id}, existing date: ${existingDateObj.toISOString()}, normalized: ${existingNormalized.toISOString()}`);
        }
        
        return matches;
      });
      
      console.log(`🔵 [DEBUG] Client-side filter found: ${matchingSummaries.length} matching summaries`);
      
      let existingSummaries = { empty: matchingSummaries.length === 0, docs: matchingSummaries, size: matchingSummaries.length };
      
      // Also check for summaries created in the last 30 seconds with same storagePath (race condition protection)
      if (existingSummaries.empty && storagePath) {
        const thirtySecondsAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 30000));
        const recentSummaries = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .collection("visit_summaries")
          .where("createdAt", ">=", thirtySecondsAgo)
          .where("storagePath", "==", storagePath)
          .limit(1)
          .get();
        if (!recentSummaries.empty) {
          console.log(`🔵 [DEBUG] Found recent summary created in last 30 seconds with same storagePath, using that instead`);
          existingSummaries = recentSummaries;
        }
      }
      
      console.log(`🔵 [DEBUG] Existing summaries found: ${existingSummaries.size}`);
      if (existingSummaries.size > 0) {
        existingSummaries.docs.forEach((doc, idx) => {
          const data = doc.data();
          // Safely extract appointmentDate - handle Timestamp, Date, or string
          let appointmentDateStr = 'unknown';
          if (data.appointmentDate) {
            if (data.appointmentDate.toDate && typeof data.appointmentDate.toDate === 'function') {
              appointmentDateStr = data.appointmentDate.toDate().toISOString();
            } else if (data.appointmentDate instanceof Date) {
              appointmentDateStr = data.appointmentDate.toISOString();
            } else if (typeof data.appointmentDate === 'string') {
              appointmentDateStr = data.appointmentDate;
            } else {
              appointmentDateStr = String(data.appointmentDate);
            }
          }
          
          let createdAtStr = 'unknown';
          if (data.createdAt) {
            if (data.createdAt.toDate && typeof data.createdAt.toDate === 'function') {
              createdAtStr = data.createdAt.toDate().toISOString();
            } else if (data.createdAt instanceof Date) {
              createdAtStr = data.createdAt.toISOString();
            } else if (typeof data.createdAt === 'string') {
              createdAtStr = data.createdAt;
            }
          }
          
          console.log(`🔵 [DEBUG] Existing summary ${idx + 1}:`, {
            id: doc.id,
            appointmentDate: appointmentDateStr,
            createdAt: createdAtStr,
            hasSummary: !!data.summary,
          });
        });
      }
      
      // Format summary before using it (needed for both update and create paths)
      const formattedSummary = formatSummaryForDisplay(
        parsedResponse.summary,
        parsedResponse.learningModules || []
      );
      
      let summaryRef;
      if (!existingSummaries.empty) {
        console.log(`⚠️ Summary already exists for appointment date ${normalizedDate.toISOString()}, updating existing entry`);
        console.log(`🔵 [DEBUG] Updating existing summary ID: ${existingSummaries.docs[0].id}`);
        summaryRef = existingSummaries.docs[0].ref;
        await summaryRef.update({
          appointmentDate: appointmentTimestamp, // Update to normalized date
          storagePath: storagePath,
          downloadUrl: downloadUrl,
          summary: formattedSummary,
          summaryData: parsedResponse.summary,
          todos: parsedResponse.todos || [],
          learningModules: parsedResponse.learningModules || [],
          redFlags: parsedResponse.redFlags || [],
          readingLevel: readingLevel,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`🔵 [DEBUG] Successfully updated existing summary`);
      } else {
        console.log(`🔵 [DEBUG] No existing summary found, creating new one`);
        
        summaryRef = await admin.firestore()
          .collection("users")
          .doc(request.auth.uid)
          .collection("visit_summaries")
          .add({
            appointmentDate: appointmentTimestamp,
            storagePath: storagePath,
            downloadUrl: downloadUrl,
            summary: formattedSummary,
            summaryData: parsedResponse.summary,
            todos: parsedResponse.todos || [],
            learningModules: parsedResponse.learningModules || [],
            redFlags: parsedResponse.redFlags || [],
            readingLevel: readingLevel,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        console.log(`🔵 [DEBUG] Created new summary with ID: ${summaryRef.id}`);
        console.log(`🔵 [DEBUG] New summary appointmentDate: ${appointmentTimestamp.toDate().toISOString()}`);
      }

      // Create todos
      if (parsedResponse.todos && Array.isArray(parsedResponse.todos) && parsedResponse.todos.length > 0) {
        const todosBatch = admin.firestore().batch();
        parsedResponse.todos.forEach((todo) => {
          if (!todo || !todo.title) return;
          const todoRef = admin.firestore().collection("learning_tasks").doc();
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
      }

      // Create learning modules
      if (parsedResponse.learningModules && Array.isArray(parsedResponse.learningModules) && parsedResponse.learningModules.length > 0) {
        const modulesBatch = admin.firestore().batch();
        parsedResponse.learningModules.forEach((module) => {
          if (!module || !module.title) return;
          const moduleRef = admin.firestore().collection("learning_tasks").doc();
          modulesBatch.set(moduleRef, {
            userId: request.auth.uid,
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

      // Remove processing lock
      try {
        await lockDocRef.delete();
        console.log(`🔵 [DEBUG] Removed processing lock: ${functionCallId}`);
      } catch (e) {
        console.log(`🔵 [DEBUG] Failed to remove lock (non-critical): ${e.message}`);
      }
      
      console.log(`✅ Analysis complete! Summary ID: ${summaryRef.id}`);
      console.log(`🔵 [DEBUG] Function Call ID: ${functionCallId} - CREATED/UPDATED summary: ${summaryRef.id}`);
      console.log(`🔵 [DEBUG] Returning from analyzeVisitSummaryPDF Cloud Function`);
      return {
        success: true, 
        summaryId: summaryRef.id,
        summary: formattedSummary,
        todos: parsedResponse.todos || [],
        learningModules: parsedResponse.learningModules || [],
        redFlags: parsedResponse.redFlags || [],
      };
    } catch (error) {
      console.error("❌ Error in analyzeVisitSummaryPDF:", error);
      console.error("Error stack:", error.stack);
      
      // If it's already an HttpsError, rethrow it
      if (error instanceof HttpsError) {
        throw error;
      }
      
      // Convert other errors to HttpsError
      const errorMessage = error.message || "Unknown error";
      if (errorMessage.includes("authentication") || errorMessage.includes("auth")) {
        throw new HttpsError("unauthenticated", "🔒 Authentication error. Please log in again.");
      } else if (errorMessage.includes("not found") || errorMessage.includes("not-found")) {
        throw new HttpsError("not-found", `📄 ${errorMessage}`);
      } else if (errorMessage.includes("timeout") || errorMessage.includes("deadline")) {
        throw new HttpsError("deadline-exceeded", "⏱️ Analysis timed out. Please try again.");
      } else if (errorMessage.includes("OpenAI") || errorMessage.includes("API")) {
        throw new HttpsError("internal", `🤖 AI service error: ${errorMessage}`);
      } else {
        throw new HttpsError("internal", `❌ Failed to analyze PDF: ${errorMessage}`);
      }
    }
  }
);

// 10. After-Visit Summary - Summarize uploaded PDF with specific structure (kept for backward compatibility)
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
      };
    } catch (error) {
      console.error("❌ Error in summarizeAfterVisitPDF:", error);
      console.error("Error stack:", error.stack);
      console.error("Error message:", error.message);
      
      // Provide more specific error messages with emojis
      if (error instanceof HttpsError) {
        throw error;
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
  let formatted = "";
  
  // How Your Baby Is Doing (shown on card - put first)
  if (summary.howBabyIsDoing) {
    formatted += `## How Your Baby Is Doing\n${summary.howBabyIsDoing}\n\n`;
  }
  
  // How You Are Doing
  if (summary.howYouAreDoing) {
    formatted += `## How You Are Doing\n${summary.howYouAreDoing}\n\n`;
  }
  
  // Actions To Take section (combines next steps, follow-up, empowerment tips)
  let actionsToTake = [];
  
  if (summary.nextSteps) {
    actionsToTake.push(summary.nextSteps);
  }
  
  if (summary.followUpInstructions) {
    actionsToTake.push(summary.followUpInstructions);
  }
  
  if (summary.empowermentTips && summary.empowermentTips.length > 0) {
    actionsToTake.push(...summary.empowermentTips);
  }
  
  if (summary.medications && summary.medications.length > 0) {
    const medInstructions = summary.medications.map(med => {
      let text = `Continue taking ${med.name}`;
      if (med.purpose) text += ` (${med.purpose})`;
      if (med.instructions) text += `. ${med.instructions}`;
      return text;
    });
    actionsToTake.push(...medInstructions);
  }
  
  if (actionsToTake.length > 0) {
    formatted += `## Actions To Take\n${actionsToTake.join(' ')}\n\n`;
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
  
  // Key Medical Terms Explained
  if (summary.keyMedicalTerms && summary.keyMedicalTerms.length > 0) {
    formatted += `## Key Medical Terms Explained\n`;
    summary.keyMedicalTerms.forEach(term => {
      formatted += `**${term.term}**: ${term.explanation}\n`;
    });
    formatted += `\n`;
  }
  
  // Questions to Ask at Your Next Visit
  if (summary.questionsToAsk && summary.questionsToAsk.length > 0) {
    formatted += `## Questions to Ask at Your Next Visit\n`;
    summary.questionsToAsk.forEach((q, i) => {
      formatted += `${i + 1}. ${q}\n`;
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
  {secrets: [openaiApiKey]},
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
      
      // Return summary (not raw text unless user opted in)
      return {
        summary: analysisResult.summary,
        todos: analysisResult.todos || [],
        learningModules: analysisResult.learningModules || [],
        redFlags: analysisResult.redFlags || [],
        hasRedaction: hasRedaction,
        // Only include original text if user explicitly opted in
        ...(saveOriginalText ? {originalText: visitText} : {})
      };
    } catch (error) {
      safeLog('error', 'Error analyzing visit summary text', {
        userId,
        error: error.message
      });
      throw new HttpsError('internal', 'Failed to analyze visit summary: ' + error.message);
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
 * Build NPI Registry API URL with correct parameters
 * Based on official NPI Registry API: https://npiregistry.cms.hhs.gov/demo-api
 * 
 * @param {Object} params - Search parameters
 * @param {string} params.postal_code - ZIP code (REQUIRED - location must be included)
 * @param {string} params.state - State code (REQUIRED - location must be included, e.g., "OH")
 * @param {string} params.city - City name (REQUIRED - location must be included)
 * @param {string} params.taxonomy_code - Taxonomy code (REQUIRED - each provider type gets separate endpoint)
 * @param {number} params.limit - Results per page (default: 200)
 * @param {number} params.skip - Skip N results for pagination (default: 0)
 * @param {string} params.healthPlan - Health plan name (for logging context only - NPI API doesn't support this)
 * @returns {string} Full NPI API URL
 */
function buildNpiUrl({ postal_code, state, city, taxonomy_code, limit = 200, skip = 0, healthPlan = null }) {
  if (!taxonomy_code) {
    throw new Error("taxonomy_code is required for NPI search");
  }
  
  // Location parameters are REQUIRED for accurate NPI searches
  if (!postal_code || !state) {
    throw new Error("postal_code and state are required for NPI search (location must be included in all endpoints)");
  }
  
  const npiUrl = new URL("https://npiregistry.cms.hhs.gov/api/");
  const params = {
    version: "2.1",
    taxonomy_code: taxonomy_code, // Each provider type gets its own taxonomy_code
    state: state, // REQUIRED - location must be included
    limit: limit.toString(),
  };
  
  // postal_code is REQUIRED - location must be included in all endpoints
  params.postal_code = postal_code;
  
  // city is included if provided - location must be included in all endpoints
  if (city) {
    params.city = city;
  }
  
  // Pagination
  if (skip > 0) {
    params.skip = skip.toString();
  }
  
  // Note: healthPlan is NOT a valid NPI API parameter (that's Medicaid-specific)
  // We log it for context but don't include it in the URL
  if (healthPlan) {
    console.log(`[buildNpiUrl] Note: healthPlan "${healthPlan}" is for context only - NPI API doesn't support health plan filtering`);
  }
  
  Object.keys(params).forEach((key) => {
    npiUrl.searchParams.append(key, params[key]);
  });
  
  return npiUrl.toString();
}

/**
 * Fetch NPI results with pagination
 * Creates SEPARATE endpoints for each provider type (taxonomy code)
 * Location parameters (postal_code, state, city) are included in ALL endpoints
 * 
 * Fetches pages until: 1) enough results, 2) no more results, or 3) max pages hit
 * @param {Object} searchParams - Search parameters (must include zip, state, city)
 * @param {Array<string>} taxonomyCodes - Taxonomy codes to search (each gets separate endpoint)
 * @param {string} healthPlan - Health plan name (for logging context only)
 * @param {number} maxPages - Maximum pages to fetch (default: 5)
 * @param {number} targetResults - Target number of results (default: 200)
 * @returns {Promise<Array>} Array of NPI providers
 */
async function fetchNpiWithPagination(searchParams, taxonomyCodes, healthPlan = null, maxPages = 5, targetResults = 200) {
  const allProviders = [];
  const urlsUsed = []; // Track URLs for final summary
  
  console.log(`[fetchNpiWithPagination] Creating SEPARATE endpoints for ${taxonomyCodes.length} provider type(s)`);
  console.log(`[fetchNpiWithPagination] Location params (included in ALL endpoints): postal_code=${searchParams.zip}, state=${searchParams.state}, city=${searchParams.city}`);
  if (healthPlan) {
    console.log(`[fetchNpiWithPagination] Health plan context: ${healthPlan} (not used in NPI API - Medicaid only)`);
  }
  
  // Each taxonomy code gets its own separate endpoint
  for (const taxonomyCode of taxonomyCodes) {
    console.log(`[fetchNpiWithPagination] ==========================================`);
    console.log(`[fetchNpiWithPagination] Provider Type: ${taxonomyCode}`);
    console.log(`[fetchNpiWithPagination] Creating separate endpoint for this provider type`);
    console.log(`[fetchNpiWithPagination] ==========================================`);
    
    let page = 0;
    let skip = 0;
    const limit = 200;
    let hasMore = true;
    let firstPageUrl = null;
    
    while (hasMore && page < maxPages && allProviders.length < targetResults) {
      page++;
      skip = (page - 1) * limit;
      
      try {
        // Build URL with location params ALWAYS included + this specific taxonomy_code
        const npiUrl = buildNpiUrl({
          postal_code: searchParams.zip,
          state: searchParams.state || "OH",
          city: searchParams.city,
          taxonomy_code: taxonomyCode, // Separate endpoint per provider type
          limit: limit,
          skip: skip,
          healthPlan: healthPlan, // For logging context only
        });
        
        if (page === 1) {
          firstPageUrl = npiUrl;
          console.log(`[fetchNpiWithPagination] FINAL NPI URL (Page 1): ${npiUrl}`);
        } else {
          console.log(`[fetchNpiWithPagination] Page ${page} URL: ${npiUrl}`);
        }
        
        urlsUsed.push(npiUrl);
        
        const npiResponse = await axios.get(npiUrl);
        const npiData = npiResponse.data;
        
        if (npiData.results && Array.isArray(npiData.results)) {
          const pageProviders = parseNpiResponse(npiData.results);
          allProviders.push(...pageProviders);
          
          console.log(`[fetchNpiWithPagination] Page ${page}: ${npiData.results.length} results, ${pageProviders.length} parsed, total: ${allProviders.length}`);
          
          // Check if there are more results
          if (npiData.results.length < limit) {
            hasMore = false;
            console.log(`[fetchNpiWithPagination] No more results for taxonomy ${taxonomyCode} (got ${npiData.results.length} < limit ${limit})`);
          }
        } else {
          hasMore = false;
          console.log(`[fetchNpiWithPagination] No results array in response for taxonomy ${taxonomyCode}`);
        }
      } catch (error) {
        console.error(`[fetchNpiWithPagination] Error fetching page ${page} for taxonomy ${taxonomyCode}:`, error.message);
        if (error.response) {
          console.error(`[fetchNpiWithPagination] Response status: ${error.response.status}`);
          console.error(`[fetchNpiWithPagination] Response data:`, JSON.stringify(error.response.data, null, 2));
        }
        hasMore = false; // Stop pagination on error
      }
    }
    
    console.log(`[fetchNpiWithPagination] Completed taxonomy ${taxonomyCode}: ${allProviders.length} total providers so far`);
    if (firstPageUrl) {
      console.log(`[fetchNpiWithPagination] Base URL for ${taxonomyCode}: ${firstPageUrl}`);
    }
  }
  
  console.log(`[fetchNpiWithPagination] Total URLs used: ${urlsUsed.length}`);
  console.log(`[fetchNpiWithPagination] All URLs:`, urlsUsed);
  
  return allProviders;
}

/**
 * Filter NPI providers by taxonomy codes (safety check only)
 * Only keeps providers whose taxonomy list intersects with allowed taxonomy codes
 * This should be a light filter since upstream queries are already constrained
 */
function filterByTaxonomy(npiProviders, allowedTaxonomyCodes) {
  if (!allowedTaxonomyCodes || allowedTaxonomyCodes.length === 0) {
    console.log(`[filterByTaxonomy] No taxonomy codes provided, returning empty array`);
    return [];
  }
  
  console.log(`[filterByTaxonomy] Safety filtering ${npiProviders.length} providers by taxonomy codes: ${JSON.stringify(allowedTaxonomyCodes)}`);
  
  const filtered = npiProviders.filter(provider => {
    // Check if provider has any taxonomy codes that match allowed codes
    if (!provider.providerTypes || !Array.isArray(provider.providerTypes)) {
      console.log(`[filterByTaxonomy] Provider "${provider.name?.substring(0, 50)}" has no providerTypes, filtering out`);
      return false;
    }
    
    const hasMatchingTaxonomy = provider.providerTypes.some(providerTaxonomy => 
      allowedTaxonomyCodes.includes(providerTaxonomy)
    );
    
    if (!hasMatchingTaxonomy) {
      console.log(`[filterByTaxonomy] Provider "${provider.name?.substring(0, 50)}" filtered out - taxonomies ${JSON.stringify(provider.providerTypes)} don't match ${JSON.stringify(allowedTaxonomyCodes)}`);
    }
    
    return hasMatchingTaxonomy;
  });
  
  const filteredCount = npiProviders.length - filtered.length;
  if (filteredCount > 0) {
    console.log(`[filterByTaxonomy] ⚠️ Filtered out ${filteredCount} providers (${npiProviders.length} -> ${filtered.length})`);
    console.log(`[filterByTaxonomy] This suggests upstream query may not be correctly constrained`);
  } else {
    console.log(`[filterByTaxonomy] ✅ All ${filtered.length} providers match taxonomy codes (upstream filtering working correctly)`);
  }
  
  return filtered;
}

/**
 * Build Medicaid FHIR API URL with correct parameters
 * Based on official Ohio Medicaid API: https://ohiomedicaidprovider.com/PublicSearchAPI.aspx
 * 
 * @param {Object} params - Search parameters
 * @param {string} params.zip - ZIP code (REQUIRED - location must be included)
 * @param {string} params.city - City name (REQUIRED - location must be included)
 * @param {string} params.state - State code (REQUIRED, e.g., "OH")
 * @param {string} params.healthplan - Health plan name (REQUIRED - included in all endpoints)
 * @param {string} params.providerTypeId - Single provider type ID (REQUIRED - each provider type gets separate endpoint)
 * @param {string} params.radius - Search radius (REQUIRED)
 * @param {boolean} params.acceptsPregnantWomen - Accepts pregnant women filter (optional, only for maternity types)
 * @param {boolean} params.acceptsNewborns - Accepts newborns filter (optional, only for maternity types)
 * @param {boolean} params.telehealth - Telehealth filter (optional)
 * @returns {string} Full Medicaid FHIR API URL
 */
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
  };
  
  // Normalize: trim and check map
  const normalized = healthplan.trim();
  return healthPlanMap[normalized] || normalized; // Return mapped value or original if not found
}

/**
 * Build Medicaid FHIR API URL with comma-delimited provider types
 * Based on official Ohio Medicaid API: https://ohiomedicaidprovider.com/PublicSearchAPI.aspx
 * 
 * @param {Object} params - Search parameters
 * @param {string} params.zip - ZIP code (REQUIRED)
 * @param {string} params.state - State code (REQUIRED, e.g., "OH")
 * @param {string} params.healthplan - Health plan name (REQUIRED)
 * @param {Array<string>} params.providerTypeIds - Provider type IDs (REQUIRED, will be comma-delimited)
 * @param {string|number} params.radius - Search radius in miles (REQUIRED)
 * @param {boolean} params.acceptsPregnantWomen - Accepts pregnant women filter (optional, only if explicitly provided AND maternity type)
 * @param {boolean} params.acceptsNewborns - Accepts newborns filter (optional, only if explicitly provided AND maternity type)
 * @param {boolean} params.telehealth - Telehealth filter (optional)
 * @returns {string} Full Medicaid FHIR API URL
 */
function buildMedicaidUrl({ zip, state, healthplan, providerTypeIds, radius, acceptsPregnantWomen, acceptsNewborns, telehealth }) {
  if (!zip || !state || !healthplan || !providerTypeIds || !radius) {
    throw new Error("zip, state, healthplan, providerTypeIds (array), and radius are required for Medicaid search");
  }
  
  if (!Array.isArray(providerTypeIds) || providerTypeIds.length === 0) {
    throw new Error("providerTypeIds must be a non-empty array");
  }
  
  // Normalize health plan name to match API expectations
  const normalizedHealthPlan = normalizeHealthPlanName(healthplan);
  console.log(`\n╔════════════════════════════════════════════════════════════════╗`);
  console.log(`║  BUILDING MEDICAID URL                                           ║`);
  console.log(`╚════════════════════════════════════════════════════════════════╝`);
  console.log(`[buildMedicaidUrl] Health plan: "${healthplan}" → normalized to: "${normalizedHealthPlan}"`);
  
  // Join provider type IDs with commas (comma-delimited)
  const providerTypeIDsDelimited = providerTypeIds.join(',');
  
  console.log(`[buildMedicaidUrl] Provider type IDs: ${JSON.stringify(providerTypeIds)}`);
  console.log(`[buildMedicaidUrl] ProviderTypeIDsDelimited: "${providerTypeIDsDelimited}"`);
  
  const medicaidUrl = new URL("https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR");
  const params = {
    state: state, // REQUIRED
    zip: zip, // REQUIRED
    healthplan: normalizedHealthPlan, // REQUIRED - lowercase parameter name
    ProviderTypeIDsDelimited: providerTypeIDsDelimited, // REQUIRED - comma-delimited provider type codes
    radius: radius.toString(), // REQUIRED
  };
  
  // Only add optional filters if explicitly provided
  // IMPORTANT: Do not include AcceptsPregnantWomen/AcceptsNewborns unless user explicitly provides them
  // These filters often eliminate non-OB providers
  if (acceptsPregnantWomen !== undefined && acceptsPregnantWomen !== null) {
    params.AcceptsPregnantWomen = acceptsPregnantWomen ? "1" : "0";
  }
  if (acceptsNewborns !== undefined && acceptsNewborns !== null) {
    params.AcceptsNewborns = acceptsNewborns ? "1" : "0";
  }
  if (telehealth !== undefined && telehealth !== null) {
    params.Telehealth = telehealth ? "1" : "0";
  }
  
  // Build URL with all parameters
  Object.keys(params).forEach((key) => {
    medicaidUrl.searchParams.append(key, params[key]);
  });
  
  const finalUrl = medicaidUrl.toString();
  
  // Log URL prominently (CRITICAL FOR DEBUGGING)
  console.log(`\n\n\n`);
  console.log(`================================================================================`);
  console.log(`================================================================================`);
  console.log(`🔗 FINAL MEDICAID URL BUILT (buildMedicaidUrl):`);
  console.log(`${finalUrl}`);
  console.log(`================================================================================`);
  console.log(`================================================================================`);
  console.log(`\n[buildMedicaidUrl] URL Parameters:`);
  Object.keys(params).forEach(key => {
    console.log(`   ${key}: ${params[key]}`);
  });
  console.log(`\n`);
  
  return finalUrl;
}

/**
 * Fetch Medicaid FHIR results using a single endpoint with comma-delimited provider types
 * Provider type is the PRIMARY constraint - results must change by provider type selection
 * 
 * @param {Object} searchParams - Search parameters (must include zip, state, healthplan, radius)
 * @param {Array<string>} providerTypeIds - Provider type IDs (comma-delimited in URL)
 * @param {boolean} acceptsPregnantWomen - Accepts pregnant women filter (optional, only if explicitly provided)
 * @param {boolean} acceptsNewborns - Accepts newborns filter (optional, only if explicitly provided)
 * @param {boolean} telehealth - Telehealth filter (optional)
 * @param {number} maxPages - Maximum pages to fetch (default: 5)
 * @returns {Promise<Array>} Array of Medicaid provider entries
 */
async function fetchMedicaidResults(searchParams, providerTypeIds, acceptsPregnantWomen, acceptsNewborns, telehealth, maxPages = 5) {
  console.log(`\n╔════════════════════════════════════════════════════════════════╗`);
  console.log(`║  FETCHING MEDICAID RESULTS (SINGLE ENDPOINT)                  ║`);
  console.log(`╚════════════════════════════════════════════════════════════════╝`);
  console.log(`[fetchMedicaidResults] Provider type IDs: ${JSON.stringify(providerTypeIds)}`);
  console.log(`[fetchMedicaidResults] ProviderTypeIDsDelimited will be: "${providerTypeIds.join(',')}"`);
  
  try {
    // Build single URL with comma-delimited provider types
    const medicaidUrl = buildMedicaidUrl({
      zip: searchParams.zip,
      state: searchParams.state || "OH",
      healthplan: searchParams.healthplan,
      providerTypeIds: providerTypeIds, // Array - will be comma-delimited in URL
      radius: searchParams.radius,
      acceptsPregnantWomen: acceptsPregnantWomen,
      acceptsNewborns: acceptsNewborns,
      telehealth: telehealth,
    });
    
    // Log the URL prominently (CRITICAL FOR DEBUGGING)
    console.log(`\n\n\n`);
    console.log(`================================================================================`);
    console.log(`================================================================================`);
    console.log(`🔗 MEDICAID API URL - THIS IS THE URL BEING CALLED:`);
    console.log(`${medicaidUrl}`);
    console.log(`================================================================================`);
    console.log(`================================================================================`);
    console.log(`\n`);
    
    // Store URL in Firestore with timestamp
    try {
      const db = admin.firestore();
      await db.collection('medicaid_api_logs').add({
        url: medicaidUrl,
        providerTypeIds: providerTypeIds,
        zip: searchParams.zip,
        state: searchParams.state || "OH",
        healthplan: searchParams.healthplan,
        radius: searchParams.radius,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
      });
      console.log(`[fetchMedicaidResults] ✅ URL stored in Firestore collection 'medicaid_api_logs'`);
    } catch (firestoreError) {
      console.error(`[fetchMedicaidResults] ⚠️ Error storing URL in Firestore:`, firestoreError.message);
      // Don't fail the request if Firestore logging fails
    }
    
    // Fetch with pagination support
    console.log(`[fetchMedicaidResults] Fetching entries from Medicaid API...`);
    console.log(`[fetchMedicaidResults] URL: ${medicaidUrl}`);
    const entries = await fetchFhirBundleWithPaging(medicaidUrl, maxPages);
    
    console.log(`[fetchMedicaidResults] Total entries collected: ${entries.length}`);
    
    if (entries.length === 0) {
      console.log(`[fetchMedicaidResults] ⚠️ WARNING: No entries returned`);
      console.log(`[fetchMedicaidResults] URL used: ${medicaidUrl}`);
      console.log(`[fetchMedicaidResults] This may indicate: 1) No providers match criteria, 2) API parameter issue, 3) API error`);
    } else {
      // Log first 1-2 provider names to verify filtering
      const sampleEntries = entries.slice(0, 2);
      console.log(`[fetchMedicaidResults] Sample entries (first ${sampleEntries.length}):`);
      sampleEntries.forEach((entry, idx) => {
        if (entry.resource) {
          const resource = entry.resource;
          const name = resource.name?.[0] ? 
            `${resource.name[0].given?.join(' ') || ''} ${resource.name[0].family || ''}`.trim() :
            'N/A';
          const providerTypes = resource.code?.map(c => c.coding?.[0]?.code).filter(Boolean) || [];
          console.log(`[fetchMedicaidResults]   Entry ${idx + 1}: "${name}" - Provider Types: ${JSON.stringify(providerTypes)}`);
        }
      });
    }
    
    return entries;
    
  } catch (error) {
    console.error(`[fetchMedicaidResults] Error fetching Medicaid results:`, error.message);
    console.error(`[fetchMedicaidResults] Error stack:`, error.stack);
    if (error.response) {
      console.error(`[fetchMedicaidResults] Response status: ${error.response.status}`);
      console.error(`[fetchMedicaidResults] Response data:`, JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.error(`[fetchMedicaidResults] Request was made but no response received`);
    }
    throw error;
  }
}

/**
 * Fetch FHIR Bundle with pagination support
 * Handles cases where response has 'link' array instead of 'entry'
 */
async function fetchFhirBundleWithPaging(initialUrl, maxPages = 5) {
  const allEntries = [];
  let currentUrl = initialUrl;
  let pageCount = 0;
  
  console.log(`[fetchFhirBundleWithPaging] Starting fetch from: ${currentUrl}`);
  console.log(`\n\n\n`);
  console.log(`================================================================================`);
  console.log(`================================================================================`);
  console.log(`🌐 FETCHING MEDICAID API - URL BEING CALLED:`);
  console.log(`${currentUrl}`);
  console.log(`================================================================================`);
  console.log(`================================================================================`);
  console.log(`\n`);
  
  while (currentUrl && pageCount < maxPages) {
    pageCount++;
    console.log(`[fetchFhirBundleWithPaging] Fetching page ${pageCount}...`);
    console.log(`   Page ${pageCount}...`);
    
    try {
      // Log URL right before making the HTTP request
      console.log(`\n[fetchFhirBundleWithPaging] Making HTTP GET request to: ${currentUrl}`);
      console.log(`[fetchFhirBundleWithPaging] This is the exact URL being fetched\n`);
      
      const response = await axios.get(currentUrl);
      const bundle = response.data;
      
      const entryCount = bundle.entry && Array.isArray(bundle.entry) ? bundle.entry.length : 0;
      console.log(`   ✅ Response Status: ${response.status}`);
      console.log(`   📦 Resource Type: ${bundle.resourceType || 'N/A'}`);
      console.log(`   📄 Has Entry: ${!!bundle.entry}`);
      console.log(`   📄 Entry Count: ${entryCount}`);
      console.log(`   🔗 Has Link: ${!!bundle.link}`);
      
      console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} response status: ${response.status}`);
      console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} resourceType: ${bundle.resourceType || 'N/A'}`);
      console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} has entry: ${!!bundle.entry}`);
      console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} entry count: ${entryCount}`);
      console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} has link: ${!!bundle.link}`);
      
      if (bundle.link && Array.isArray(bundle.link)) {
        console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} link array:`, JSON.stringify(bundle.link, null, 2));
      }
      
      // If this bundle has entries, add them
      if (bundle.entry && Array.isArray(bundle.entry)) {
        const entryCount = bundle.entry.length;
        console.log(`   📋 Entries in page ${pageCount}: ${entryCount}`);
        console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} has ${entryCount} entries`);
        allEntries.push(...bundle.entry);
      } else if (bundle.entry && !Array.isArray(bundle.entry)) {
        console.log(`   ⚠️ Entry is not an array, converting...`);
        console.log(`[fetchFhirBundleWithPaging] Page ${pageCount} entry is not an array, converting...`);
        allEntries.push(bundle.entry);
      } else {
        console.log(`   ⚠️ No entries found in page ${pageCount}`);
      }
      
      // Check for next page link
      let nextUrl = null;
      if (bundle.link && Array.isArray(bundle.link)) {
        const nextLink = bundle.link.find(link => link.relation === "next");
        if (nextLink && nextLink.url) {
          nextUrl = nextLink.url;
          console.log(`[fetchFhirBundleWithPaging] Found next page link: ${nextUrl}`);
        } else {
          console.log(`[fetchFhirBundleWithPaging] No 'next' link found in link array`);
        }
      }
      
      // If no next link, we're done
      if (!nextUrl) {
        console.log(`   ✅ No more pages. Total entries: ${allEntries.length}`);
        console.log(`[fetchFhirBundleWithPaging] No more pages, total entries collected: ${allEntries.length}`);
        break;
      }
      
      currentUrl = nextUrl;
      
    } catch (error) {
      console.log(`   ❌ ERROR fetching page ${pageCount}: ${error.message}`);
      if (error.response) {
        console.log(`   ❌ Response Status: ${error.response.status}`);
        console.log(`   ❌ Response Data: ${JSON.stringify(error.response.data, null, 2)}`);
        console.error(`[fetchFhirBundleWithPaging] Response status: ${error.response.status}`);
        console.error(`[fetchFhirBundleWithPaging] Response data:`, JSON.stringify(error.response.data, null, 2));
      } else if (error.request) {
        console.log(`   ❌ No response received from server`);
        console.log(`   ❌ Request URL: ${currentUrl}`);
      }
      console.error(`[fetchFhirBundleWithPaging] Error fetching page ${pageCount}:`, error.message);
      // If we have some entries, return what we have; otherwise throw
      if (allEntries.length > 0) {
        console.log(`   ⚠️ Returning ${allEntries.length} entries despite error`);
        console.log(`[fetchFhirBundleWithPaging] Returning ${allEntries.length} entries despite error`);
        break;
      }
      throw error;
    }
  }
  
  if (pageCount >= maxPages) {
    console.log(`[fetchFhirBundleWithPaging] Reached max page limit (${maxPages}), stopping`);
  }
  
  console.log(`[fetchFhirBundleWithPaging] Final result: ${allEntries.length} entries from ${pageCount} page(s)`);
  return allEntries;
}

exports.searchProviders = onCall(async (request) => {
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
  } = request.data;

  // Validate required parameters
  if (!zip || !city || !healthPlan || !providerTypeIds || !radius) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: zip, city, healthPlan, providerTypeIds, radius"
    );
  }

  // Normalize provider type IDs
  // IMPORTANT: Ohio Medicaid API uses single digits (1-9) WITH leading zeros ("01", "02", "09")
  // Frontend may send with or without leading zeros, so normalize to API format (with leading zeros for 1-9)
  const normalizedProviderTypeIds = Array.isArray(providerTypeIds)
    ? providerTypeIds.map((id) => {
        const numId = parseInt(id, 10);
        if (!isNaN(numId) && numId >= 1 && numId <= 9) {
          return id.padStart(2, '0'); // Add leading zero (API format: "01", "02", "09")
        }
        return id; // Return as-is for double digits (10+)
      })
    : [providerTypeIds];

  // CRITICAL: Validate provider type IDs are not empty
  if (normalizedProviderTypeIds.length === 0 || normalizedProviderTypeIds.every(id => !id || id.trim() === '')) {
    console.log(`[searchProviders] ⚠️ ERROR: providerTypeIds is empty or invalid`);
    console.log(`[searchProviders] Returning empty results - provider type is required`);
    return {
      success: true,
      providers: [],
      count: 0,
      error: "Provider type IDs are required for search"
    };
  }

  console.log(`\n\n\n`);
  console.log(`╔════════════════════════════════════════════════════════════════╗`);
  console.log(`║          searchProviders FUNCTION CALLED                      ║`);
  console.log(`╚════════════════════════════════════════════════════════════════╝`);
  console.log(`\n[searchProviders] ==========================================`);
  console.log(`[searchProviders] SEARCH REQUEST DETAILS`);
  console.log(`[searchProviders] ==========================================`);
  console.log(`[searchProviders] ZIP: ${zip}`);
  console.log(`[searchProviders] City: ${city}`);
  console.log(`[searchProviders] Health Plan: ${healthPlan}`);
  console.log(`[searchProviders] Radius: ${radius}`);
  console.log(`[searchProviders] Raw provider type IDs: ${JSON.stringify(providerTypeIds)}`);
  console.log(`[searchProviders] Normalized provider type IDs: ${JSON.stringify(normalizedProviderTypeIds)}`);
  // Resolve taxonomy codes for provider types (for NPI filtering)
  const taxonomyCodes = taxonomyCodesForProviderTypeIds(normalizedProviderTypeIds);
  
  console.log(`[searchProviders] Provider type IDs delimited: ${normalizedProviderTypeIds.join(',')}`);
  console.log(`[searchProviders] Resolved taxonomy codes: ${JSON.stringify(taxonomyCodes)}`);
  console.log(`[searchProviders] Include NPI: ${includeNpi}`);
  console.log(`[searchProviders] Accepts Pregnant Women: ${acceptsPregnantWomen}`);
  console.log(`[searchProviders] Accepts Newborns: ${acceptsNewborns}`);
  console.log(`[searchProviders] Telehealth: ${telehealth}`);
  console.log(`[searchProviders] ==========================================\n`);

  try {
    const providers = [];

    // 1. Search Ohio Medicaid API
    // IMPORTANT: Use single endpoint with comma-delimited provider types
    // Provider type is the PRIMARY constraint - results must change by provider type selection
    try {
      console.log(`\n\n\n`);
      console.log(`╔════════════════════════════════════════════════════════════════╗`);
      console.log(`║          MEDICAID SEARCH STARTING                            ║`);
      console.log(`╚════════════════════════════════════════════════════════════════╝`);
      console.log(`[Medicaid] ==========================================`);
      console.log(`[Medicaid] STARTING MEDICAID SEARCH`);
      console.log(`[Medicaid] ==========================================`);
      console.log(`[Medicaid] Provider type IDs: ${JSON.stringify(normalizedProviderTypeIds)}`);
      console.log(`[Medicaid] ProviderTypeIDsDelimited: "${normalizedProviderTypeIds.join(',')}"`);
      console.log(`[Medicaid] ZIP: ${zip}, State: OH`);
      console.log(`[Medicaid] Health plan: ${healthPlan}`);
      console.log(`[Medicaid] Radius: ${radius}`);
      console.log(`[Medicaid] Using SINGLE endpoint with comma-delimited provider types`);
      console.log(`[Medicaid] ==========================================\n`);
      
      // Log what the URL will look like (before building it)
      const previewProviderTypes = normalizedProviderTypeIds.join(',');
      const previewUrl = `https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR?state=OH&zip=${zip}&healthplan=${encodeURIComponent(healthPlan)}&ProviderTypeIDsDelimited=${previewProviderTypes}&radius=${radius}`;
      console.log(`\n`);
      console.log(`================================================================================`);
      console.log(`🔗 MEDICAID URL PREVIEW (will be built and called):`);
      console.log(`${previewUrl}`);
      console.log(`================================================================================`);
      console.log(`\n`);
      
      // Determine if this is a maternity-related search
      const isMaternitySearch = isMaternityProviderType(normalizedProviderTypeIds);
      console.log(`[Medicaid] Is maternity provider type: ${isMaternitySearch}`);
      
      // IMPORTANT: Only include AcceptsPregnantWomen/AcceptsNewborns if:
      // 1. User explicitly provided them (not undefined/null)
      // 2. Provider type is maternity-related
      // These filters often eliminate non-OB providers
      let finalAcceptsPregnantWomen = undefined;
      let finalAcceptsNewborns = undefined;
      
      if (isMaternitySearch) {
        // Only use if explicitly provided
        if (acceptsPregnantWomen !== undefined && acceptsPregnantWomen !== null) {
          finalAcceptsPregnantWomen = acceptsPregnantWomen;
          console.log(`[Medicaid] Including AcceptsPregnantWomen filter: ${acceptsPregnantWomen}`);
        } else {
          console.log(`[Medicaid] Skipping AcceptsPregnantWomen filter (not explicitly provided)`);
        }
        
        if (acceptsNewborns !== undefined && acceptsNewborns !== null) {
          finalAcceptsNewborns = acceptsNewborns;
          console.log(`[Medicaid] Including AcceptsNewborns filter: ${acceptsNewborns}`);
        } else {
          console.log(`[Medicaid] Skipping AcceptsNewborns filter (not explicitly provided)`);
        }
      } else {
        console.log(`[Medicaid] Skipping AcceptsPregnantWomen/AcceptsNewborns filters (non-maternity provider type)`);
      }
      
      // Fetch Medicaid results with single endpoint
      const searchParams = {
        zip: zip,
        state: "OH",
        healthplan: healthPlan,
        radius: radius,
      };
      
      console.log(`\n╔════════════════════════════════════════════════════════════════╗`);
      console.log(`║  CALLING fetchMedicaidResults (SINGLE ENDPOINT)                ║`);
      console.log(`╚════════════════════════════════════════════════════════════════╝\n`);
      
      const allEntries = await fetchMedicaidResults(
        searchParams,
        normalizedProviderTypeIds, // Array - will be comma-delimited in URL
        finalAcceptsPregnantWomen,
        finalAcceptsNewborns,
        telehealth,
        5
      );
      
      // Parse entries
      console.log(`\n==========================================`);
      console.log(`📊 MEDICAID RESULTS (TERMINAL OUTPUT):`);
      console.log(`   Total entries fetched: ${allEntries.length}`);
      
      if (allEntries.length > 0) {
        console.log(`[Medicaid] Parsing ${allEntries.length} entries...`);
        const medicaidProviders = parseMedicaidResponse(allEntries, specialty);
        providers.push(...medicaidProviders);
        console.log(`   Providers after parsing: ${medicaidProviders.length}`);
        console.log(`[Medicaid] Found ${medicaidProviders.length} providers after parsing`);
        console.log(`[Medicaid] Medicaid source count: ${medicaidProviders.length}`);
        
        if (medicaidProviders.length === 0 && allEntries.length > 0) {
          console.log(`   ⚠️ WARNING: ${allEntries.length} entries but 0 providers parsed!`);
          console.log(`[Medicaid] WARNING: ${allEntries.length} entries but 0 providers parsed. Checking first entry...`);
          if (allEntries[0] && allEntries[0].resource) {
            const testProvider = parseFhirResource(allEntries[0].resource);
            console.log(`[Medicaid] Test parse result:`, JSON.stringify(testProvider, null, 2));
            console.log(`   First entry resource type: ${allEntries[0].resource?.resourceType || 'N/A'}`);
            console.log(`   First entry has code: ${!!allEntries[0].resource?.code}`);
          }
        }
      } else {
        console.log(`   ⚠️ No entries returned from API`);
        console.log("[Medicaid] No entries to parse after fetching");
      }
      console.log(`==========================================\n`);
      
      console.log(`[Medicaid] ==========================================\n`);
    } catch (error) {
      console.log(`\n\n\n`);
      console.log(`╔════════════════════════════════════════════════════════════════╗`);
      console.log(`║          ❌ MEDICAID SEARCH ERROR                                ║`);
      console.log(`╚════════════════════════════════════════════════════════════════╝`);
      console.log(`\n==========================================`);
      console.log(`❌ MEDICAID SEARCH ERROR (TERMINAL OUTPUT):`);
      console.log(`   Error: ${error.message}`);
      console.log(`   Error Type: ${error.constructor.name}`);
      if (error.response) {
        console.log(`   Response Status: ${error.response.status}`);
        console.log(`   Response Data: ${JSON.stringify(error.response.data, null, 2)}`);
        console.error("[Medicaid] Response status:", error.response.status);
        console.error("[Medicaid] Response data:", JSON.stringify(error.response.data, null, 2));
      } else if (error.request) {
        console.log(`   No response received from server`);
        console.log(`   Request URL (if available): ${error.config?.url || 'N/A'}`);
      }
      console.log(`   Stack Trace:`);
      console.log(error.stack);
      console.log(`==========================================\n`);
      console.error("[Medicaid] Error searching Medicaid API:", error.message);
      console.error("[Medicaid] Error stack:", error.stack);
      // Continue to NPI search if enabled
    }

    // 2. Search NPI Registry ONLY if explicitly requested (includeNpi=true)
    // IMPORTANT: Do NOT call NPI fallback unless explicitly requested
    // Provider type is the PRIMARY constraint - Medicaid directory should be sufficient
    if (includeNpi === true) {
      console.log(`\n[NPI] ==========================================`);
      console.log(`[NPI] STARTING NPI SEARCH`);
      console.log(`[NPI] ==========================================`);
      console.log(`[NPI] Include NPI: ${includeNpi}`);
      console.log(`[NPI] Providers found so far: ${providers.length}`);
      console.log(`[NPI] Provider type IDs: ${JSON.stringify(normalizedProviderTypeIds)}`);
      console.log(`[NPI] Resolved taxonomy codes: ${JSON.stringify(taxonomyCodes)}`);
      console.log(`[NPI] ==========================================\n`);
      
      // CRITICAL: Require taxonomy codes for NPI search
      if (taxonomyCodes.length === 0) {
        console.log(`[NPI] ⚠️ ERROR: No taxonomy codes resolved for provider type IDs: ${JSON.stringify(normalizedProviderTypeIds)}`);
        console.log(`[NPI] Skipping NPI search - provider type not supported for NPI fallback`);
        console.log(`[NPI] Returning only Medicaid results (if any)`);
        console.log(`[NPI] ⚠️ DO NOT perform broad NPI search without taxonomy codes`);
      } else {
        try {
          // Get additional taxonomy codes from specialty if provided
          let allTaxonomyCodes = [...taxonomyCodes];
          
          if (specialty) {
            const specialtyTaxonomy = getTaxonomyCode(specialty);
            if (specialtyTaxonomy && !allTaxonomyCodes.includes(specialtyTaxonomy)) {
              allTaxonomyCodes.push(specialtyTaxonomy);
              console.log(`[NPI] Added taxonomy code from specialty: ${specialtyTaxonomy}`);
            }
          }
          
          // Remove duplicates
          allTaxonomyCodes = [...new Set(allTaxonomyCodes)];
          
          console.log(`[NPI] Final taxonomy codes to search: ${JSON.stringify(allTaxonomyCodes)}`);
          console.log(`[NPI] Location params (included in ALL endpoints): zip=${zip}, city=${city}, state=OH`);
          console.log(`[NPI] Health plan context: ${healthPlan} (not used in NPI API - Medicaid only)`);
          console.log(`[NPI] Creating SEPARATE endpoints for each provider type (${allTaxonomyCodes.length} endpoint(s))`);
          
          // Fetch NPI results with pagination
          // Location parameters (zip, city, state) are REQUIRED and included in ALL endpoints
          const searchParams = {
            zip: zip,
            city: city,
            state: "OH",
          };
          
          console.log(`[NPI] Fetching NPI results with pagination (max 5 pages, target 200 results)...`);
          console.log(`[NPI] Each provider type will get its own separate endpoint call`);
          const allNpiProviders = await fetchNpiWithPagination(searchParams, allTaxonomyCodes, healthPlan, 5, 200);
          
          console.log(`[NPI] Total providers from NPI (before safety filter): ${allNpiProviders.length}`);
          
          // Safety filter: ensure all providers match taxonomy codes (should be minimal filtering)
          const filteredProviders = filterByTaxonomy(allNpiProviders, allTaxonomyCodes);
          
          console.log(`[NPI] Total providers from NPI (after safety filter): ${filteredProviders.length}`);
          
          // Log first 5 providers with their taxonomy codes
          if (filteredProviders.length > 0) {
            console.log(`[NPI] First 5 providers from NPI:`);
            filteredProviders.slice(0, 5).forEach((p, idx) => {
              console.log(`[NPI]   ${idx + 1}. ${p.name?.substring(0, 60)}`);
              console.log(`[NPI]      Taxonomies: ${JSON.stringify(p.providerTypes || [])}`);
              console.log(`[NPI]      Source: ${p.source}`);
            });
          }
          
          // Add filtered NPI providers
          providers.push(...filteredProviders);
          console.log(`[NPI] Total NPI providers added: ${filteredProviders.length}`);
          console.log(`[NPI] Total providers from all sources: ${providers.length}`);
        } catch (error) {
          console.error("[NPI] Error searching NPI API:", error.message);
          if (error.response) {
            console.error("[NPI] Response status:", error.response.status);
            console.error("[NPI] Response data:", JSON.stringify(error.response.data, null, 2));
          }
          // Continue with Medicaid results only
        }
      }
      console.log(`[NPI] ==========================================\n`);
    }

    // 3. Log counts from each source before deduplication
    const medicaidCount = providers.filter(p => p.source === 'medicaid').length;
    const npiCount = providers.filter(p => p.source === 'npi').length;
    console.log(`\n[searchProviders] ==========================================`);
    console.log(`[searchProviders] SOURCE COUNTS BEFORE DEDUPLICATION`);
    console.log(`[searchProviders] ==========================================`);
    console.log(`[searchProviders] Medicaid providers: ${medicaidCount}`);
    console.log(`[searchProviders] NPI providers: ${npiCount}`);
    console.log(`[searchProviders] Total providers: ${providers.length}`);
    console.log(`[searchProviders] ==========================================\n`);

    // 3. Search Firestore for providers that match search criteria (including BIPOC directory providers)
    try {
      console.log(`\n[searchProviders] ==========================================`);
      console.log(`[searchProviders] SEARCHING FIRESTORE FOR MATCHING PROVIDERS`);
      console.log(`[searchProviders] ==========================================`);
      
      // Search Firestore for providers with matching zip code and provider types
      // This includes BIPOC directory providers and other Firestore-only providers
      const firestoreProviders = await searchFirestoreProviders({
        zip: zip,
        city: city,
        radius: radius,
        providerTypeIds: normalizedProviderTypeIds,
        specialty: specialty,
      });
      
      if (firestoreProviders.length > 0) {
        console.log(`[searchProviders] Found ${firestoreProviders.length} providers in Firestore`);
        providers.push(...firestoreProviders);
      } else {
        console.log(`[searchProviders] No additional providers found in Firestore`);
      }
      console.log(`[searchProviders] ==========================================\n`);
    } catch (error) {
      console.error(`[searchProviders] Error searching Firestore:`, error);
      // Continue with API results only
    }

    // 3b. Read BIPOC providers from Excel file (for Clinical Counselor searches)
    try {
      console.log(`\n[searchProviders] ==========================================`);
      console.log(`[searchProviders] READING BIPOC PROVIDERS FROM EXCEL FILE`);
      console.log(`[searchProviders] ==========================================`);
      
      // Check if searching for Clinical Counselor (provider type '47')
      const isClinicalCounselorSearch = normalizedProviderTypeIds.some(id => 
        id === "47" || id.toLowerCase().includes("counselor") || id.toLowerCase().includes("therapist")
      );

      if (isClinicalCounselorSearch) {
        const excelProviders = await readBipocProvidersFromExcel({
          zip: zip,
          city: city,
          radius: radius,
          providerTypeIds: normalizedProviderTypeIds,
          specialty: specialty,
        });
        
        if (excelProviders.length > 0) {
          console.log(`[searchProviders] Found ${excelProviders.length} BIPOC providers from Excel file`);
          providers.push(...excelProviders);
        } else {
          console.log(`[searchProviders] No BIPOC providers found in Excel file`);
        }
      } else {
        console.log(`[searchProviders] Skipping Excel file (not a Clinical Counselor search)`);
      }
      console.log(`[searchProviders] ==========================================\n`);
    } catch (error) {
      console.error(`[searchProviders] Error reading BIPOC providers from Excel:`, error);
      // Continue with other results
    }

    // 4. Deduplicate providers by NPI or name+location
    const deduplicatedProviders = deduplicateProviders(providers);
    console.log(`[searchProviders] After deduplication: ${deduplicatedProviders.length} providers`);

    // 5. Enrich with Firestore data (reviews, identity tags, Mama Approved)
    const enrichedProviders = await enrichProvidersWithFirestore(deduplicatedProviders);
    console.log(`[searchProviders] After enrichment: ${enrichedProviders.length} providers`);

    // 5. Sort providers with prioritization
    console.log(`[searchProviders] Before sorting: ${enrichedProviders.length} providers`);
    
    // Check if identity tags are selected (Identity & Cultural match)
    const hasIdentityTags = identityTags && Array.isArray(identityTags) && identityTags.length > 0;
    console.log(`[searchProviders] Identity tags selected: ${hasIdentityTags ? identityTags.join(", ") : "none"}`);
    
    // Helper to check if provider has BIPOC tag
    const hasBipocTag = (provider) => {
      if (!provider.identityTags || !Array.isArray(provider.identityTags)) return false;
      return provider.identityTags.some(tag => 
        (tag.name && tag.name.toLowerCase() === "bipoc") || 
        (tag.id && tag.id.toLowerCase() === "bipoc")
      );
    };
    
    enrichedProviders.sort((a, b) => {
      const aHasBipoc = hasBipocTag(a);
      const bHasBipoc = hasBipocTag(b);
      
      // If identity tags are selected, prioritize BIPOC providers first
      if (hasIdentityTags) {
        if (aHasBipoc && !bHasBipoc) return -1;
        if (!aHasBipoc && bHasBipoc) return 1;
      }
      
      // Mama Approved providers next
      if (a.mamaApproved && !b.mamaApproved) return -1;
      if (!a.mamaApproved && b.mamaApproved) return 1;
      
      // If identity tags selected and both have BIPOC, prioritize BIPOC with Mama Approved
      if (hasIdentityTags && aHasBipoc && bHasBipoc) {
        if (a.mamaApproved && !b.mamaApproved) return -1;
        if (!a.mamaApproved && b.mamaApproved) return 1;
      }
      
      // Then by rating (highest first)
      const ratingA = a.rating || 0;
      const ratingB = b.rating || 0;
      if (ratingA !== ratingB) return ratingB - ratingA;
      
      // Then by review count (more reviews = higher priority)
      const countA = a.reviewCount || 0;
      const countB = b.reviewCount || 0;
      return countB - countA;
    });
    
    console.log(`[searchProviders] After sorting: ${enrichedProviders.length} providers`);
    const bipocCount = enrichedProviders.filter(p => hasBipocTag(p)).length;
    console.log(`[searchProviders] BIPOC providers in results: ${bipocCount}`);

    // 6. Serialize providers to ensure JSON-compatible format
    const serializedProviders = enrichedProviders.map(serializeProvider);
    
    // Final summary with comprehensive debugging
    console.log(`\n[searchProviders] ==========================================`);
    console.log(`[searchProviders] FINAL RESULTS SUMMARY`);
    console.log(`[searchProviders] ==========================================`);
    console.log(`[searchProviders] Total providers returned: ${serializedProviders.length}`);
    console.log(`[searchProviders] Medicaid source: ${medicaidCount}`);
    console.log(`[searchProviders] NPI source: ${npiCount}`);
    console.log(`[searchProviders] After deduplication: ${deduplicatedProviders.length}`);
    console.log(`[searchProviders] After enrichment: ${enrichedProviders.length}`);
    
    // Sanity checks
    if (providers.length === 0 && normalizedProviderTypeIds.length > 0) {
      console.log(`[searchProviders] ⚠️ WARNING: No providers found despite provider type IDs: ${JSON.stringify(normalizedProviderTypeIds)}`);
    }
    
    if (medicaidCount === 0 && npiCount === 0) {
      console.log(`[searchProviders] ⚠️ WARNING: No providers from either source`);
      console.log(`[searchProviders] Check: 1) API URLs, 2) Provider type IDs, 3) Location parameters`);
    }
    
    if (serializedProviders.length > 0) {
      const providerTypesFound = new Set();
      serializedProviders.forEach(p => {
        if (p.providerTypes && Array.isArray(p.providerTypes)) {
          p.providerTypes.forEach(t => providerTypesFound.add(t));
        }
      });
      console.log(`[searchProviders] Provider types in results: ${JSON.stringify(Array.from(providerTypesFound))}`);
      console.log(`[searchProviders] Searched for provider type IDs: ${JSON.stringify(normalizedProviderTypeIds)}`);
      console.log(`[searchProviders] Resolved taxonomy codes: ${JSON.stringify(taxonomyCodes)}`);
      console.log(`[searchProviders] Note: NPI URLs were logged during pagination (see [fetchNpiWithPagination] logs above)`);
      
      // Log first 5 providers with details
      const sampleProviders = serializedProviders.slice(0, 5);
      console.log(`[searchProviders] First ${sampleProviders.length} providers with taxonomy codes:`);
      sampleProviders.forEach((p, idx) => {
        console.log(`[searchProviders] Provider ${idx + 1}:`, JSON.stringify({
          name: p.name?.substring(0, 60),
          providerTypes: p.providerTypes,
          taxonomyCodes: p.providerTypes, // NPI taxonomy codes are stored in providerTypes
          source: p.source,
          mamaApproved: p.mamaApproved,
          rating: p.rating,
          reviewCount: p.reviewCount,
        }, null, 2));
      });
    }
    console.log(`[searchProviders] ==========================================\n`);

    return {
      success: true,
      providers: serializedProviders,
      count: serializedProviders.length,
    };
  } catch (error) {
    console.error("Error in searchProviders:", error);
    throw new HttpsError("internal", "Provider search failed: " + error.message);
  }
});

// Helper function to parse Medicaid FHIR Bundle entries
// Handles Organization and OrganizationAffiliation resources
function parseMedicaidResponse(entries, specialtyFilter) {
  const providers = [];
  let skippedCount = 0;
  let errorCount = 0;
  
  console.log(`[parseMedicaidResponse] Processing ${entries.length} entries`);
  console.log(`[parseMedicaidResponse] Specialty filter: ${specialtyFilter || 'none'}`);
  
  // Separate Organization and OrganizationAffiliation resources
  const organizations = new Map(); // id -> Organization resource
  const affiliations = []; // OrganizationAffiliation resources
  
  for (const entry of entries) {
    if (!entry.resource) {
      skippedCount++;
      continue;
    }
    
    const resource = entry.resource;
    if (resource.resourceType === 'Organization') {
      const orgId = resource.id || entry.fullUrl;
      organizations.set(orgId, resource);
    } else if (resource.resourceType === 'OrganizationAffiliation') {
      affiliations.push(resource);
    } else if (resource.resourceType === 'Practitioner' || resource.resourceType === 'PractitionerRole') {
      // Handle Practitioner/PractitionerRole if they exist
      const provider = parseFhirResource(resource);
      if (provider) {
        providers.push(provider);
      } else {
        skippedCount++;
      }
    } else {
      skippedCount++;
      console.log(`[parseMedicaidResponse] Skipping unknown resource type: ${resource.resourceType}`);
    }
  }
  
  console.log(`[parseMedicaidResponse] Found ${organizations.size} Organizations, ${affiliations.length} OrganizationAffiliations`);
  
  // Process OrganizationAffiliation resources to create providers
  for (const affiliation of affiliations) {
    try {
      // Get the organization reference
      const orgRef = affiliation.organization?.reference;
      if (!orgRef) {
        skippedCount++;
        continue;
      }
      
      // Extract organization ID from reference (format: "Organization/id" or just "id")
      const orgId = orgRef.includes('/') ? orgRef.split('/')[1] : orgRef;
      const organization = organizations.get(orgId);
      
      if (!organization) {
        skippedCount++;
        console.log(`[parseMedicaidResponse] Organization not found for affiliation: ${orgRef}`);
        continue;
      }
      
      // Extract provider name from Organization
      const name = organization.name || 'Unknown';
      
      // Extract provider types from OrganizationAffiliation.code
      const providerTypes = [];
      if (affiliation.code && Array.isArray(affiliation.code)) {
        for (const code of affiliation.code) {
          if (code.coding && Array.isArray(code.coding)) {
            for (const coding of code.coding) {
              // Check if this is a ProviderType (not SpecialtyType)
              if (coding.system && coding.system.includes('ProviderType') && coding.code) {
                providerTypes.push(coding.code.toString());
              }
            }
          }
        }
      }
      
      // Extract specialties from OrganizationAffiliation.code
      const specialties = [];
      if (affiliation.code && Array.isArray(affiliation.code)) {
        for (const code of affiliation.code) {
          if (code.coding && Array.isArray(code.coding)) {
            for (const coding of code.coding) {
              // Check if this is a SpecialtyType
              if (coding.system && coding.system.includes('SpecialtyType') && coding.display) {
                specialties.push(coding.display.toString());
              }
            }
          }
        }
      }
      
      // Apply specialty filter if provided
      if (specialtyFilter) {
        const matchesSpecialty = specialties.some(s => 
          s.toLowerCase().includes(specialtyFilter.toLowerCase())
        );
        if (!matchesSpecialty) {
          skippedCount++;
          continue;
        }
      }
      
      // Extract locations from Organization.contact
      const locations = [];
      if (organization.contact && Array.isArray(organization.contact)) {
        for (const contact of organization.contact) {
          if (contact.address) {
            const addr = contact.address;
            const addressLines = Array.isArray(addr.line) 
              ? addr.line.map(l => {
                  // Handle JSON string in line field
                  if (typeof l === 'string' && l.startsWith('[')) {
                    try {
                      const parsed = JSON.parse(l);
                      if (Array.isArray(parsed) && parsed[0] && parsed[0].ADDRESS_1) {
                        return parsed[0].ADDRESS_1;
                      }
                    } catch (e) {
                      // Not JSON, use as-is
                    }
                  }
                  return l.toString();
                }).filter(l => l && l.trim())
              : (addr.line ? [addr.line.toString()] : []);
            
            if (addressLines.length > 0 || addr.city) {
              locations.push({
                address: addressLines.join(', '),
                city: addr.city || '',
                state: addr.state || 'OH',
                zip: addr.postalCode || '',
              });
            }
          }
        }
      }
      
      // Extract phone from Organization.contact
      let phone = null;
      if (organization.contact && Array.isArray(organization.contact)) {
        for (const contact of organization.contact) {
          if (contact.telecom && Array.isArray(contact.telecom)) {
            for (const telecom of contact.telecom) {
              if (telecom.system === 'phone' && telecom.value) {
                phone = telecom.value.toString();
                break;
              }
            }
          }
          if (phone) break;
        }
      }
      
      // Create provider object
      const provider = {
        name: name,
        specialty: specialties.length > 0 ? specialties[0] : null,
        practiceName: name, // For organizations, name is the practice name
        npi: null, // Organizations don't have NPI
        locations: locations,
        providerTypes: providerTypes,
        specialties: specialties,
        phone: phone,
        email: null,
        source: 'medicaid',
      };
      
      providers.push(provider);
      
    } catch (error) {
      errorCount++;
      console.error(`[parseMedicaidResponse] Error parsing OrganizationAffiliation:`, error.message);
      continue;
    }
  }

  console.log(`[parseMedicaidResponse] Results: ${providers.length} providers, ${skippedCount} skipped, ${errorCount} errors`);
  
  // Log provider types summary
  if (providers.length > 0) {
    const allTypes = new Set();
    providers.forEach(p => {
      if (p.providerTypes && Array.isArray(p.providerTypes)) {
        p.providerTypes.forEach(t => allTypes.add(t));
      }
    });
    console.log(`[parseMedicaidResponse] Unique provider types found: ${JSON.stringify(Array.from(allTypes))}`);
  }
  
  return providers;
}

// Parse a single FHIR resource into a provider object
function parseFhirResource(resource) {
  try {
    // Extract name
    let name = "";
    if (resource.name) {
      if (Array.isArray(resource.name)) {
        const nameParts = resource.name.map((n) => {
          const given = Array.isArray(n.given) ? n.given.join(" ") : (n.given || "");
          const family = n.family || "";
          return `${given} ${family}`.trim();
        }).filter((n) => n.length > 0);
        name = nameParts.join(", ");
      } else if (typeof resource.name === "object") {
        const given = Array.isArray(resource.name.given) 
          ? resource.name.given.join(" ") 
          : (resource.name.given || "");
        const family = resource.name.family || "";
        name = `${given} ${family}`.trim();
      }
    }
    
    // Try organization name if no name found
    if (!name && resource.organization && resource.organization.name) {
      name = resource.organization.name;
    }
    
    if (!name) return null; // Skip if no name
    
    // Extract addresses
    const locations = [];
    if (resource.address) {
      const addresses = Array.isArray(resource.address) ? resource.address : [resource.address];
      
      for (const addr of addresses) {
        if (addr && (addr.line || addr.city)) {
          const addressLines = Array.isArray(addr.line) 
            ? addr.line.map((l) => {
                // Handle JSON string in line field (e.g., "[{\"ADDRESS_1\":\"4365 READING RD\",\"ADDRESS_2\":\" \"}]")
                const lineStr = l.toString();
                if (lineStr.startsWith('[') && lineStr.includes('ADDRESS_1')) {
                  try {
                    const parsed = JSON.parse(lineStr);
                    if (Array.isArray(parsed) && parsed[0]) {
                      const addrObj = parsed[0];
                      const addr1 = addrObj.ADDRESS_1 || '';
                      const addr2 = addrObj.ADDRESS_2 || '';
                      // Combine ADDRESS_1 and ADDRESS_2, filtering out empty strings
                      const combined = [addr1, addr2].filter(a => a && a.trim() !== '').join(' ');
                      return combined.trim();
                    }
                  } catch (e) {
                    // If JSON parsing fails, use the original string
                    console.log(`[parseFhirResource] Could not parse address JSON: ${lineStr.substring(0, 50)}`);
                  }
                }
                return lineStr;
              }).filter(l => l && l.trim() !== '')
            : (addr.line ? [addr.line.toString()] : []);
          
          // Only add location if we have address lines or city
          if (addressLines.length > 0 || addr.city) {
            locations.push({
              address: addressLines.join(", "),
              city: addr.city || "",
              state: addr.state || "OH",
              zip: addr.postalCode || "",
            });
          }
        }
      }
    }
    
    // Extract provider types
    const providerTypes = [];
    if (resource.type) {
      const types = Array.isArray(resource.type) ? resource.type : [resource.type];
      for (const type of types) {
        if (type && type.coding) {
          const codings = Array.isArray(type.coding) ? type.coding : [type.coding];
          for (const coding of codings) {
            if (coding && coding.code) {
              providerTypes.push(coding.code.toString());
            }
          }
        }
      }
    }
    
    // Log provider types for debugging
    if (providerTypes.length > 0) {
      console.log(`[parseFhirResource] Provider "${name.substring(0, 50)}" has provider types: ${JSON.stringify(providerTypes)}`);
    } else {
      console.log(`[parseFhirResource] Provider "${name.substring(0, 50)}" has NO provider types extracted`);
    }
    
    // Extract specialties
    const specialties = [];
    if (resource.specialty) {
      const specialtyList = Array.isArray(resource.specialty) 
        ? resource.specialty 
        : [resource.specialty];
      for (const spec of specialtyList) {
        if (spec && spec.text) {
          specialties.push(spec.text.toString());
        }
      }
    }
    
    // Extract telecom (phone, email)
    let phone = null;
    let email = null;
    if (resource.telecom) {
      const telecom = Array.isArray(resource.telecom) ? resource.telecom : [resource.telecom];
      for (const contact of telecom) {
        if (contact && contact.system && contact.value) {
          if (contact.system === "phone" && !phone) {
            phone = contact.value.toString();
          } else if (contact.system === "email" && !email) {
            email = contact.value.toString();
          }
        }
      }
    }
    
    // Extract NPI from identifiers
    let npi = null;
    if (resource.identifier) {
      const identifiers = Array.isArray(resource.identifier) 
        ? resource.identifier 
        : [resource.identifier];
      for (const id of identifiers) {
        if (id && id.system && id.system.includes("npi") && id.value) {
          npi = id.value.toString();
          break;
        }
      }
    }
    
    return {
      name: name,
      specialty: specialties.length > 0 ? specialties[0] : null,
      practiceName: resource.organization?.name || null,
      npi: npi,
      locations: locations,
      providerTypes: providerTypes,
      specialties: specialties,
      phone: phone,
      email: email,
      source: "medicaid",
    };
  } catch (error) {
    console.error("Error parsing FHIR resource:", error);
    return null;
  }
}

// Parse NPI Registry API response
function parseNpiResponse(results) {
  const providers = [];
  
  for (const result of results) {
    try {
      const provider = parseNpiResult(result);
      if (provider) {
        providers.push(provider);
      }
    } catch (error) {
      console.error("Error parsing NPI result:", error);
      continue;
    }
  }
  
  // Log provider types summary
  if (providers.length > 0) {
    const allTypes = new Set();
    providers.forEach(p => {
      if (p.providerTypes && Array.isArray(p.providerTypes)) {
        p.providerTypes.forEach(t => allTypes.add(t));
      }
    });
    console.log(`[parseNpiResponse] Unique provider types found: ${JSON.stringify(Array.from(allTypes))}`);
  }
  
  return providers;
}

// Parse a single NPI result into a provider object
function parseNpiResult(result) {
  try {
    const basicInfo = result.basic;
    if (!basicInfo) return null;
    
    // Extract name
    let name = "";
    if (basicInfo.organization_name) {
      name = basicInfo.organization_name;
    } else {
      const firstName = basicInfo.first_name || "";
      const middleName = basicInfo.middle_name || "";
      const lastName = basicInfo.last_name || "";
      const credential = basicInfo.credential || "";
      
      name = [firstName, middleName, lastName].filter((n) => n).join(" ");
      if (credential) {
        name = `${name}, ${credential}`;
      }
    }
    
    if (!name) return null;
    
    // Extract addresses
    const locations = [];
    if (result.addresses && Array.isArray(result.addresses)) {
      for (const addr of result.addresses) {
        if (addr.address_1 || addr.city) {
          locations.push({
            address: addr.address_1 || "",
            address2: addr.address_2 || null,
            city: addr.city || "",
            state: addr.state || "",
            zip: addr.postal_code || "",
            phone: addr.telephone_number || null,
          });
        }
      }
    }
    
    // Extract specialties from taxonomies
    const specialties = [];
    const providerTypes = [];
    if (result.taxonomies && Array.isArray(result.taxonomies)) {
      for (const tax of result.taxonomies) {
        if (tax.desc) {
          specialties.push(tax.desc);
        }
        if (tax.code) {
          providerTypes.push(tax.code);
        }
      }
    }
    
    // Log provider types for debugging
    if (providerTypes.length > 0) {
      console.log(`[parseNpiResult] Provider "${name.substring(0, 50)}" has provider types: ${JSON.stringify(providerTypes)}`);
    } else {
      console.log(`[parseNpiResult] Provider "${name.substring(0, 50)}" has NO provider types extracted`);
    }
    
    // Extract phone from first address
    let phone = null;
    if (locations.length > 0 && locations[0].phone) {
      phone = locations[0].phone;
    }
    
    return {
      name: name,
      npi: result.number || null,
      specialty: specialties.length > 0 ? specialties[0] : null,
      locations: locations,
      providerTypes: providerTypes,
      specialties: specialties,
      phone: phone,
      source: "npi",
    };
  } catch (error) {
    console.error("Error parsing NPI result:", error);
    return null;
  }
}

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
    })) : [],
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
  const { zip, city, radius, providerTypeIds, specialty } = searchParams;
  const providers = [];

  try {
    // Query Firestore for providers with matching zip code
    // Note: We'll need to filter by distance after fetching
    // Firestore doesn't support geospatial queries directly, so we'll fetch by zip and filter
    
    let query = admin.firestore().collection("providers");
    
    // If we have provider types, filter by them
    // Note: This is a simplified approach - Firestore doesn't support array-contains-any easily
    // We'll fetch and filter in memory
    
    const snapshot = await query
      .where("source", "in", ["bipoc_directory", "admin_added", "user_submission"])
      .limit(500) // Limit to avoid too many reads
      .get();

    console.log(`[searchFirestoreProviders] Found ${snapshot.size} Firestore-only providers to check`);

    // Filter providers by location and provider types
    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Check if provider has locations matching the search
      if (!data.locations || !Array.isArray(data.locations) || data.locations.length === 0) {
        continue;
      }

      // Check each location
      for (const location of data.locations) {
        // Check if zip matches (simple check - could be enhanced with radius calculation)
        if (location.zip && location.zip.substring(0, 5) === zip.substring(0, 5)) {
          // Check if provider types match (if specified)
          if (providerTypeIds && providerTypeIds.length > 0) {
            const providerTypes = data.providerTypes || [];
            const hasMatchingType = providerTypeIds.some(typeId => 
              providerTypes.includes(typeId) || providerTypes.includes(typeId.padStart(2, '0'))
            );
            if (!hasMatchingType) {
              continue;
            }
          }

          // Check specialty if specified
          if (specialty) {
            const specialties = data.specialties || [];
            const providerSpecialty = data.specialty || "";
            if (!specialties.includes(specialty) && providerSpecialty !== specialty) {
              continue;
            }
          }

          // Convert Firestore provider to API format
          const provider = {
            id: doc.id,
            name: data.name || "",
            specialty: data.specialty || null,
            practiceName: data.practiceName || null,
            npi: data.npi || null,
            locations: [{
              address: location.address || "",
              address2: location.address2 || null,
              city: location.city || "",
              state: location.state || "OH",
              zip: location.zip || "",
              phone: location.phone || data.phone || null,
              latitude: location.latitude || null,
              longitude: location.longitude || null,
            }],
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
          };

          providers.push(provider);
          break; // Only add provider once, even if multiple locations match
        }
      }
    }

    console.log(`[searchFirestoreProviders] Returning ${providers.length} matching providers`);
    return providers;
  } catch (error) {
    console.error(`[searchFirestoreProviders] Error:`, error);
    return [];
  }
}

// Helper function to enrich providers with Firestore data
async function enrichProvidersWithFirestore(providers) {
  const enriched = [];
  
  for (const provider of providers) {
    try {
      // Try to find provider in Firestore by NPI or name+location
      let firestoreProvider = null;
      let firestoreId = null;
      
      // Try by NPI first
      if (provider.npi) {
        const npiQuery = await admin.firestore()
          .collection("providers")
          .where("npi", "==", provider.npi)
          .limit(1)
          .get();
        
        if (!npiQuery.empty) {
          firestoreProvider = npiQuery.docs[0].data();
          firestoreId = npiQuery.docs[0].id;
        }
      }
      
      // If not found by NPI, try by name+location
      if (!firestoreProvider && provider.locations && provider.locations.length > 0) {
        const loc = provider.locations[0];
        const nameQuery = await admin.firestore()
          .collection("providers")
          .where("name", "==", provider.name)
          .limit(10)
          .get();
        
        // Find matching location
        for (const doc of nameQuery.docs) {
          const data = doc.data();
          if (data.locations && Array.isArray(data.locations)) {
            const match = data.locations.find((l) => 
              l.city === loc.city && l.zip === loc.zip
            );
            if (match) {
              firestoreProvider = data;
              firestoreId = doc.id;
              break;
            }
          }
        }
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
            const reviews = reviewsQuery.docs.map((doc) => doc.data());
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
      
      // If no rating found and provider has NPI, try to find reviews by NPI
      if ((rating == null || rating == 0) && provider.npi) {
        try {
          // Try to find provider by NPI to get Firestore ID
          const npiProviderQuery = await admin.firestore()
            .collection("providers")
            .where("npi", "==", provider.npi)
            .limit(1)
            .get();
          
          if (!npiProviderQuery.empty) {
            const npiProviderId = npiProviderQuery.docs[0].id;
            const reviewsQuery = await admin.firestore()
              .collection("reviews")
              .where("providerId", "==", npiProviderId)
              .limit(50)
              .get();
            
            if (!reviewsQuery.empty) {
              const reviews = reviewsQuery.docs.map((doc) => doc.data());
              if (reviews.length > 0) {
                const totalRating = reviews.reduce((sum, r) => sum + (r.rating || 0), 0);
                rating = totalRating / reviews.length;
                reviewCount = reviews.length;
                console.log(`[Enrich] Provider NPI ${provider.npi}: calculated rating ${rating} from ${reviews.length} reviews`);
              }
            }
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
            const reviews = reviewsQuery.docs.map((doc) => doc.data());
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

      enriched.push(enrichedProvider);
    } catch (error) {
      console.error(`Error enriching provider ${provider.name}:`, error);
      // Add provider without enrichment
      enriched.push(provider);
    }
  }

  return enriched;
}

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
 * OhioMaximusSearch - Builds the correct Ohio Medicaid API URL from user inputs
 * Based on: https://ohiomedicaidprovider.com/PublicSearchAPI.aspx
 * 
 * @param {string} zip - ZIP code (REQUIRED)
 * @param {string} radius - Search radius in miles (REQUIRED)
 * @param {string} city - City name (optional, for logging)
 * @param {string} healthPlan - Health plan name (REQUIRED)
 * @param {string|Array<string>} providerType - Provider type name(s) or code(s) (REQUIRED)
 * @param {string} state - State code (defaults to "OH")
 * @returns {Object} Object containing the built URL and normalized parameters
 */
exports.OhioMaximusSearch = onCall(async (request) => {
  // Log function call immediately
  console.log(`\n\n\n`);
  console.log(`╔════════════════════════════════════════════════════════════════╗`);
  console.log(`║          OhioMaximusSearch FUNCTION CALLED                    ║`);
  console.log(`╚════════════════════════════════════════════════════════════════╝`);
  console.log(`[OhioMaximusSearch] Function execution started at: ${new Date().toISOString()}`);
  console.log(`[OhioMaximusSearch] Request data:`, JSON.stringify(request.data, null, 2));
  
  try {
    const {
      zip,
      radius,
      city,
      healthPlan,
      providerType,
      state = "OH",
    } = request.data;

    console.log(`[OhioMaximusSearch] Parsed parameters:`);
    console.log(`   ZIP: ${zip}`);
    console.log(`   Radius: ${radius}`);
    console.log(`   City: ${city || 'N/A'}`);
    console.log(`   Health Plan: ${healthPlan}`);
    console.log(`   Provider Type: ${providerType}`);
    console.log(`   State: ${state}`);

    // Validate required parameters
    if (!zip || !radius || !healthPlan || !providerType) {
      const errorMsg = "Missing required parameters: zip, radius, healthPlan, and providerType are required";
      console.error(`[OhioMaximusSearch] ❌ VALIDATION ERROR: ${errorMsg}`);
      throw new HttpsError("invalid-argument", errorMsg);
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

    // Normalize provider type(s) to code(s)
    let providerTypeIds = [];
    
    if (Array.isArray(providerType)) {
    // Handle array of provider types
    providerTypeIds = providerType.map((type) => {
      const trimmedType = String(type).trim();
      // Check if it's already a code (numeric)
      if (/^\d+$/.test(trimmedType)) {
        // Normalize: add leading zero for single digits (1-9)
        const numId = parseInt(trimmedType, 10);
        if (numId >= 1 && numId <= 9) {
          return trimmedType.padStart(2, '0');
        }
        return trimmedType;
      }
      // Look up in map
      const code = providerTypeCodeMap[trimmedType];
      if (!code) {
        throw new HttpsError(
          "invalid-argument",
          `Invalid provider type: "${trimmedType}". Please use a valid provider type name or code.`
        );
      }
      // Normalize: add leading zero for single digits (1-9)
      const numId = parseInt(code, 10);
      if (numId >= 1 && numId <= 9) {
        return code.padStart(2, '0');
      }
      return code;
      });
    } else {
      // Handle single provider type
      const trimmedType = String(providerType).trim();
      // Check if it's already a code (numeric)
      if (/^\d+$/.test(trimmedType)) {
        // Normalize: add leading zero for single digits (1-9)
        const numId = parseInt(trimmedType, 10);
        if (numId >= 1 && numId <= 9) {
          providerTypeIds = [trimmedType.padStart(2, '0')];
        } else {
          providerTypeIds = [trimmedType];
        }
      } else {
        // Look up in map
        const code = providerTypeCodeMap[trimmedType];
        if (!code) {
          throw new HttpsError(
            "invalid-argument",
            `Invalid provider type: "${trimmedType}". Please use a valid provider type name or code.`
          );
        }
        // Normalize: add leading zero for single digits (1-9)
        const numId = parseInt(code, 10);
        if (numId >= 1 && numId <= 9) {
          providerTypeIds = [code.padStart(2, '0')];
        } else {
          providerTypeIds = [code];
        }
      }
    }

    // Normalize health plan name
    console.log(`[OhioMaximusSearch] Normalizing health plan: ${healthPlan}`);
    const normalizedHealthPlan = normalizeHealthPlanName(healthPlan);
    console.log(`[OhioMaximusSearch] Normalized health plan: ${normalizedHealthPlan}`);

    // Build URL using existing buildMedicaidUrl function
    console.log(`[OhioMaximusSearch] Building Medicaid URL...`);
    console.log(`[OhioMaximusSearch] Provider type IDs: ${JSON.stringify(providerTypeIds)}`);
    
    const medicaidUrl = buildMedicaidUrl({
      zip: zip,
      state: state,
      healthplan: normalizedHealthPlan,
      providerTypeIds: providerTypeIds,
      radius: radius.toString(),
    });

    // Log the URL prominently
    console.log(`\n`);
    console.log(`================================================================================`);
    console.log(`================================================================================`);
    console.log(`🔗 OHIO MAXIMUS SEARCH - GENERATED URL:`);
    console.log(`${medicaidUrl}`);
    console.log(`================================================================================`);
    console.log(`================================================================================`);
    console.log(`\n[OhioMaximusSearch] Final Parameters:`);
    console.log(`   ZIP: ${zip}`);
    console.log(`   City: ${city || 'N/A'}`);
    console.log(`   State: ${state}`);
    console.log(`   Health Plan: ${healthPlan} → ${normalizedHealthPlan}`);
    console.log(`   Provider Type: ${providerType} → ${providerTypeIds.join(',')}`);
    console.log(`   Provider Type IDs: ${JSON.stringify(providerTypeIds)}`);
    console.log(`   Radius: ${radius}`);
    
    // Fetch data from the URL
    console.log(`\n[OhioMaximusSearch] Fetching providers from Ohio Maximus API...`);
    let providers = [];
    let allEntries = [];
    
    try {
      // Use existing fetchFhirBundleWithPaging function to get entries
      allEntries = await fetchFhirBundleWithPaging(medicaidUrl, 5);
      console.log(`[OhioMaximusSearch] Fetched ${allEntries.length} entries from API`);
      
      // Parse entries using existing parseMedicaidResponse function
      if (allEntries.length > 0) {
        providers = parseMedicaidResponse(allEntries, null); // No specialty filter for now
        console.log(`[OhioMaximusSearch] Parsed ${providers.length} providers from entries`);
      } else {
        console.log(`[OhioMaximusSearch] No entries returned from API`);
      }
    } catch (fetchError) {
      console.error(`[OhioMaximusSearch] Error fetching/parsing providers:`, fetchError.message);
      console.error(`[OhioMaximusSearch] Stack trace:`, fetchError.stack);
      // Don't throw - return URL and empty providers list so user can see what was attempted
    }
    
    console.log(`\n[OhioMaximusSearch] ✅ Function completed successfully`);
    console.log(`[OhioMaximusSearch] Returning ${providers.length} providers`);
    console.log(`╚════════════════════════════════════════════════════════════════╝\n\n`);

    const result = {
      success: true,
      url: medicaidUrl,
      providers: providers,
      count: providers.length,
      parameters: {
        zip: zip,
        city: city || null,
        state: state,
        healthPlan: normalizedHealthPlan,
        providerTypeIds: providerTypeIds,
        providerTypeIdsDelimited: providerTypeIds.join(','),
        radius: radius.toString(),
      },
    };

    // Log the result being returned
    console.log(`[OhioMaximusSearch] Returning result with ${providers.length} providers`);
    
    return result;
  } catch (error) {
    // Log error details
    console.error(`\n`);
    console.error(`╔════════════════════════════════════════════════════════════════╗`);
    console.error(`║          ❌ OhioMaximusSearch ERROR                            ║`);
    console.error(`╚════════════════════════════════════════════════════════════════╝`);
    console.error(`[OhioMaximusSearch] Error occurred at: ${new Date().toISOString()}`);
    console.error(`[OhioMaximusSearch] Error message: ${error.message}`);
    console.error(`[OhioMaximusSearch] Error stack: ${error.stack}`);
    console.error(`[OhioMaximusSearch] Request data was:`, JSON.stringify(request.data, null, 2));
    console.error(`╚════════════════════════════════════════════════════════════════╝\n`);
    
    // Re-throw the error
    throw error;
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
