/**
 * Script to manually initialize technology_features collection from FEATURES.md
 * Run with: npx ts-node scripts/initialize-features.ts
 */

import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';

// Initialize Firebase Admin
const serviceAccount = require('../serviceAccountKey.json'); // You'll need to download this from Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Feature name to ID mapping
const featureNameToId: Record<string, string> = {
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

// Domain mapping
const domainMap: Record<string, string> = {
  'provider-search': 'Care Navigation',
  'authentication-onboarding': 'User Experience',
  'user-feedback': 'User Engagement',
  'appointment-summarizing': 'Care Understanding',
  'journal': 'Self-Reflection',
  'learning-modules': 'Care Preparation',
  'birth-plan-generator': 'Care Preparation',
  'community': 'Community Support',
  'profile-editing': 'User Experience'
};

// Display order mapping
const displayOrderMap: Record<string, number> = {
  'provider-search': 1,
  'authentication-onboarding': 2,
  'user-feedback': 3,
  'appointment-summarizing': 4,
  'journal': 5,
  'learning-modules': 6,
  'birth-plan-generator': 7,
  'community': 8,
  'profile-editing': 9
};

function parseFeaturesMarkdown(content: string): Record<string, any> {
  const features: Record<string, any> = {};
  const sections = content.split(/^## \d+\. /m);
  
  sections.forEach((section, index) => {
    if (index === 0) return; // Skip header
    
    const lines = section.split('\n');
    const featureName = lines[0].trim();
    const featureId = featureNameToId[featureName] || featureName.toLowerCase().replace(/\s+/g, '-');
    
    let currentSection = '';
    let howItWorks = '';
    const changeHistory: any[] = [];
    const recentUpdates: string[] = [];
    
    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (line === '### Current Functionality') {
        currentSection = 'functionality';
        howItWorks = '';
      } else if (line === '### Change History') {
        currentSection = 'changes';
      } else if (line.startsWith('---')) {
        break;
      } else if (line.startsWith('- **') && currentSection === 'changes') {
        const matchWithCommit = line.match(/^- \*\*(\d{4}-\d{2}-\d{2})\*\* - \*\*([a-f0-9]+)\*\* - \*\*([^\*]+)\*\*: (.+)$/);
        const matchWithoutCommit = line.match(/^- \*\*(\d{4}-\d{2}-\d{2})\*\* - \*\*([^\*]+)\*\*: (.+)$/);
        
        if (matchWithCommit) {
          const updateText = `${matchWithCommit[3]}: ${matchWithCommit[4]}`;
          changeHistory.push({
            date: matchWithCommit[1],
            commitSha: matchWithCommit[2],
            title: matchWithCommit[3],
            description: matchWithCommit[4]
          });
          recentUpdates.push(updateText);
        } else if (matchWithoutCommit) {
          const updateText = `${matchWithoutCommit[2]}: ${matchWithoutCommit[3]}`;
          changeHistory.push({
            date: matchWithoutCommit[1],
            commitSha: null,
            title: matchWithoutCommit[2],
            description: matchWithoutCommit[3]
          });
          recentUpdates.push(updateText);
        }
      } else if (currentSection === 'functionality' && line && !line.startsWith('---')) {
        howItWorks += (howItWorks ? '\n' : '') + line;
      }
    }
    
    features[featureId] = {
      name: featureName,
      description: '', // Will be set from howItWorks
      howItWorks: howItWorks.trim(),
      recentUpdates: recentUpdates,
      changeHistory: changeHistory
    };
  });
  
  return features;
}

async function initializeFeatures() {
  try {
    // Read FEATURES.md
    const featuresPath = path.join(__dirname, '..', 'FEATURES.md');
    const featuresContent = fs.readFileSync(featuresPath, 'utf-8');
    
    // Parse features
    const features = parseFeaturesMarkdown(featuresContent);
    
    console.log(`Found ${Object.keys(features).length} features to initialize`);
    
    // Create/update features in Firestore
    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();
    
    for (const [featureId, featureData] of Object.entries(features)) {
      const featureRef = db.collection('technology_features').doc(featureId);
      
      const featureDoc = {
        id: featureId,
        name: featureData.name,
        description: featureData.howItWorks.substring(0, 200) + '...', // Short description
        howItWorks: featureData.howItWorks,
        recentUpdates: featureData.recentUpdates,
        domain: domainMap[featureId] || 'Other',
        category: featureData.name,
        status: 'active',
        displayOrder: displayOrderMap[featureId] || 999,
        tags: [featureId],
        visible: true,
        createdAt: now,
        updatedAt: now,
        updatedBy: 'system',
        lastUpdated: now
      };
      
      batch.set(featureRef, featureDoc, { merge: true });
      console.log(`Prepared feature: ${featureId} - ${featureData.name}`);
    }
    
    // Commit batch
    await batch.commit();
    console.log('Successfully initialized all features!');
    
    // Add change history entries
    for (const [featureId, featureData] of Object.entries(features)) {
      if (featureData.changeHistory && featureData.changeHistory.length > 0) {
        const featureRef = db.collection('technology_features').doc(featureId);
        
        for (const change of featureData.changeHistory) {
          await featureRef.collection('change_history').add({
            version: change.commitSha ? change.commitSha.substring(0, 7) : 'manual',
            date: admin.firestore.Timestamp.fromDate(new Date(change.date)),
            change: change.description,
            title: change.title,
            commitSha: change.commitSha,
            commitMessage: '',
            commitAuthor: 'system',
            releaseBuildNumber: null,
            createdBy: 'system',
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
        console.log(`Added ${featureData.changeHistory.length} change history entries for ${featureId}`);
      }
    }
    
    console.log('Done!');
    process.exit(0);
  } catch (error) {
    console.error('Error initializing features:', error);
    process.exit(1);
  }
}

initializeFeatures();
