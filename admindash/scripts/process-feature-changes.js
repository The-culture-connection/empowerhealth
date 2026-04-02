/**
 * Process Feature Changes from FEATURES.md
 * Extracts feature changes and updates Firestore
 */

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// Initialize Firebase Admin
if (!admin.apps.length) {
  const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS || '../serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

/**
 * Parse FEATURES.md and extract feature information
 */
function parseFeaturesDocument() {
  const featuresPath = path.join(__dirname, '..', 'FEATURES.md');
  const content = fs.readFileSync(featuresPath, 'utf-8');
  
  const features = {};
  const sections = content.split(/^## \d+\. /m);
  
  sections.forEach((section, index) => {
    if (index === 0) return; // Skip header
    
    const lines = section.split('\n');
    const featureName = lines[0].trim();
    
    let currentSection = '';
    let description = '';
    let changeHistory = [];
    
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (line === '### Current Functionality') {
        currentSection = 'description';
      } else if (line === '### Change History') {
        currentSection = 'changes';
      } else if (line.startsWith('- **') && currentSection === 'changes') {
        // Parse change entry: - **[Date]** - **[Commit SHA]** - **[Title]**: [Description]
        const match = line.match(/^- \*\*(\d{4}-\d{2}-\d{2})\*\* - \*\*([a-f0-9]+)\*\* - \*\*([^\*]+)\*\*: (.+)$/);
        if (match) {
          changeHistory.push({
            date: match[1],
            commitSha: match[2],
            title: match[3],
            description: match[4]
          });
        }
      } else if (currentSection === 'description' && line && !line.startsWith('---')) {
        description += (description ? '\n' : '') + line;
      }
    }
    
    // Map feature names to IDs
    const featureIdMap = {
      'Provider Search': 'provider-search',
      'Authentication and Onboarding': 'authentication-onboarding',
      'User Feedback': 'user-feedback',
      'Appointment Summarizing': 'appointment-summarizing',
      'Journal': 'journal',
      'Learning Modules': 'learning-modules',
      'Birth Plan Generator': 'birth-plan-generator',
      'Community': 'community',
      'Profile Editing': 'profile-editing'
    };
    
    const featureId = featureIdMap[featureName] || featureName.toLowerCase().replace(/\s+/g, '-');
    
    features[featureId] = {
      name: featureName,
      description: description.trim(),
      changeHistory: changeHistory
    };
  });
  
  return features;
}

/**
 * Update feature documents in Firestore
 */
async function updateFeatures(features, commitSha, commitMessage, commitDate) {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  
  for (const [featureId, featureData] of Object.entries(features)) {
    const featureRef = db.collection('technology_features').doc(featureId);
    
    // Get existing feature or create new
    const featureDoc = await featureRef.get();
    const existingData = featureDoc.exists ? featureDoc.data() : {};
    
    // Update feature document
    const featureUpdate = {
      name: featureData.name,
      description: featureData.description,
      domain: getDomainFromFeatureId(featureId),
      status: existingData.status || 'active',
      displayOrder: existingData.displayOrder || 999,
      tags: existingData.tags || [featureId],
      updatedAt: now,
      updatedBy: 'system',
      ...(featureDoc.exists ? {} : { createdAt: now })
    };
    
    batch.set(featureRef, featureUpdate, { merge: true });
    
    // Add new change history entries
    const latestChanges = featureData.changeHistory.filter(change => 
      !existingData.lastProcessedCommit || 
      change.commitSha !== existingData.lastProcessedCommit
    );
    
    for (const change of latestChanges) {
      const changeRef = featureRef.collection('change_history').doc();
      batch.set(changeRef, {
        version: commitSha.substring(0, 7),
        date: admin.firestore.Timestamp.fromDate(new Date(change.date)),
        change: change.description,
        title: change.title,
        commitSha: change.commitSha,
        releaseBuildNumber: null, // Will be set when release is published
        createdBy: 'system',
        createdAt: now
      });
    }
    
    // Update last processed commit
    if (latestChanges.length > 0) {
      batch.update(featureRef, {
        lastProcessedCommit: latestChanges[latestChanges.length - 1].commitSha
      });
    }
  }
  
  await batch.commit();
  console.log(`Updated ${Object.keys(features).length} features`);
}

/**
 * Get domain from feature ID
 */
function getDomainFromFeatureId(featureId) {
  const domainMap = {
    'provider-search': 'Provider Search',
    'authentication-onboarding': 'Authentication',
    'user-feedback': 'User Engagement',
    'appointment-summarizing': 'After Visit Summary',
    'journal': 'Journal',
    'learning-modules': 'Learning',
    'birth-plan-generator': 'Birth Plan',
    'community': 'Community',
    'profile-editing': 'Profile'
  };
  
  return domainMap[featureId] || 'Other';
}

/**
 * Main function
 */
async function main() {
  const commitSha = process.env.GITHUB_SHA || process.argv[2];
  const commitMessage = process.env.GITHUB_COMMIT_MESSAGE || process.argv[3] || '';
  const commitDate = process.env.GITHUB_COMMIT_DATE || new Date().toISOString().split('T')[0];
  
  if (!commitSha) {
    console.error('Error: Commit SHA is required');
    console.error('Usage: node process-feature-changes.js <commitSha> [commitMessage]');
    process.exit(1);
  }
  
  console.log(`Processing feature changes for commit: ${commitSha}`);
  
  try {
    const features = parseFeaturesDocument();
    await updateFeatures(features, commitSha, commitMessage, commitDate);
    console.log('Feature changes processed successfully');
  } catch (error) {
    console.error('Error processing feature changes:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { parseFeaturesDocument, updateFeatures };
