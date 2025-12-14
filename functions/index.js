const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
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

  // Save to Firestore
      const summaryRef = await admin.firestore()
          .collection("users")
    .doc(userId)
          .collection("visit_summaries")
          .add({
        appointmentDate: appointmentDate,
      originalText: pdfText.substring(0, 10000),
        summary: parsedResponse.summary,
        todos: parsedResponse.todos || [],
        learningModules: parsedResponse.learningModules || [],
        redFlags: parsedResponse.redFlags || [],
        readingLevel: readingLevel,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

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
    summary: formatSummaryForDisplay(
      parsedResponse.summary,
      parsedResponse.learningModules || []
    ),
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
    if (!request.auth) {
      throw new Error("User must be authenticated");
    }

    const data = request.data;
    const {
      storagePath,
      downloadUrl,
      appointmentDate,
      educationLevel,
      userProfile,
    } = data;

    if (!storagePath && !downloadUrl) {
      throw new Error("PDF file location is required");
    }

    if (!appointmentDate) {
      throw new Error("Appointment date is required");
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
      const bucket = admin.storage().bucket();
      const file = bucket.file(storagePath);
      const [exists] = await file.exists();
      if (!exists) {
        throw new Error(`PDF file not found at: ${storagePath}`);
      }
      const [pdfBuffer] = await file.download();

      // Upload PDF to OpenAI
      const openai = getOpenAIClient(openaiApiKey.value());
      let pdfFile;
      try {
        pdfFile = new File([pdfBuffer], "visit_summary.pdf", {type: "application/pdf"});
      } catch (e) {
        const { Readable } = require("stream");
        const stream = Readable.from(pdfBuffer);
        stream.name = "visit_summary.pdf";
        pdfFile = stream;
      }
      
      // Upload PDF to OpenAI for analysis
      const fileUpload = await openai.files.create({
        file: pdfFile,
        purpose: "assistants",
      });

      // Wait for file to be processed
      let fileStatus = await openai.files.retrieve(fileUpload.id);
      let attempts = 0;
      while (fileStatus.status !== "processed" && attempts < 30) {
        await new Promise(resolve => setTimeout(resolve, 1000));
        fileStatus = await openai.files.retrieve(fileUpload.id);
        attempts++;
        if (fileStatus.status === "error") {
          throw new Error("File processing failed");
        }
      }

      // Use Assistants API - attach file to message correctly
      const assistant = await openai.beta.assistants.create({
        name: "Visit Summary Analyzer",
        instructions: `You are a culturally affirming, trauma-informed medical interpreter specializing in maternal health advocacy. Analyze the uploaded PDF visit summary and generate a comprehensive, plain-language summary at a ${readingLevel} reading level using professional clinical language. Avoid casual terms like "momma".`,
        model: "gpt-4-turbo-preview",
        tools: [{ type: "code_interpreter" }],
      });

      const thread = await openai.beta.threads.create();

      // Add message with file attachment
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

      const run = await openai.beta.threads.runs.create(thread.id, {
        assistant_id: assistant.id,
      });

      let runStatus = await openai.beta.threads.runs.retrieve(thread.id, run.id);
      while (runStatus.status !== "completed") {
        if (runStatus.status === "failed") {
          throw new Error("OpenAI analysis failed");
        }
        await new Promise(resolve => setTimeout(resolve, 1000));
        runStatus = await openai.beta.threads.runs.retrieve(thread.id, run.id);
      }

      const messages = await openai.beta.threads.messages.list(thread.id);
      const assistantMessage = messages.data.find(m => m.role === "assistant");
      
      if (!assistantMessage || !assistantMessage.content[0]?.text?.value) {
        throw new Error("No response from OpenAI");
      }

      const responseContent = assistantMessage.content[0].text.value;
      let parsedResponse;
      try {
        const jsonMatch = responseContent.match(/```json\s*([\s\S]*?)\s*```/) || 
                         responseContent.match(/```\s*([\s\S]*?)\s*```/);
        const jsonString = jsonMatch ? jsonMatch[1] : responseContent;
        parsedResponse = JSON.parse(jsonString);
      } catch (parseError) {
        throw new Error("Failed to parse AI response");
      }

      // Clean up uploaded file
      try {
        await openai.files.del(fileUpload.id);
      } catch (e) {
        console.warn("Failed to delete uploaded file:", e);
      }

      // Save to Firestore
      const appointmentTimestamp = admin.firestore.Timestamp.fromDate(new Date(appointmentDate));
      const formattedSummary = formatSummaryForDisplay(
        parsedResponse.summary,
        parsedResponse.learningModules || []
      );
      
      const summaryRef = await admin.firestore()
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

      return {
        success: true, 
        summaryId: summaryRef.id,
        summary: formattedSummary,
        todos: parsedResponse.todos || [],
        learningModules: parsedResponse.learningModules || [],
        redFlags: parsedResponse.redFlags || [],
      };
    } catch (error) {
      console.error("Error in analyzeVisitSummaryPDF:", error);
      throw new Error(`Failed to analyze PDF: ${error.message || "Unknown error"}`);
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

