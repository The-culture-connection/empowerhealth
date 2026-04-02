/**
 * Migration Script: Fix ADMIN collection document IDs
 * 
 * This script migrates ADMIN documents from auto-generated IDs to uid-based IDs
 * 
 * Usage:
 * 1. Install firebase-admin: npm install firebase-admin
 * 2. Set GOOGLE_APPLICATION_CREDENTIALS environment variable to your service account key
 * 3. Update the PROJECT_ID below
 * 4. Run: node scripts/migrate-admin-docs.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
// Option 1: Use service account (recommended)
// Set GOOGLE_APPLICATION_CREDENTIALS environment variable
// Or uncomment and provide path:
// const serviceAccount = require('./path-to-service-account.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount)
// });

// Option 2: Use application default credentials
admin.initializeApp({
  projectId: 'your-project-id' // Replace with your Firebase project ID
});

const db = admin.firestore();

async function migrateAdminDocs() {
  console.log('Starting migration of ADMIN documents...\n');

  try {
    // Get all documents in ADMIN collection
    const adminSnapshot = await db.collection('ADMIN').get();
    
    console.log(`Found ${adminSnapshot.size} documents in ADMIN collection\n`);

    const migrations = [];
    const errors = [];

    for (const docSnap of adminSnapshot.docs) {
      const data = docSnap.data();
      const oldId = docSnap.id;
      const uid = data.uid;
      const email = data.email;

      // Skip if already using uid as document ID
      if (oldId === uid) {
        console.log(`✓ Document ${oldId} already uses uid as ID, skipping`);
        continue;
      }

      if (!uid) {
        console.error(`✗ Document ${oldId} has no uid field, skipping`);
        errors.push({ id: oldId, reason: 'No uid field' });
        continue;
      }

      // Check if document with uid already exists
      const existingDoc = await db.collection('ADMIN').doc(uid).get();
      if (existingDoc.exists) {
        console.log(`⚠ Document with uid ${uid} already exists, merging data...`);
        // Merge data (keep existing, add missing fields from old doc)
        const existingData = existingDoc.data();
        const mergedData = { ...existingData, ...data };
        await db.collection('ADMIN').doc(uid).set(mergedData);
        await db.collection('ADMIN').doc(oldId).delete();
        console.log(`✓ Merged and deleted old document ${oldId}`);
        migrations.push({ oldId, newId: uid, email, action: 'merged' });
      } else {
        // Create new document with uid as ID
        await db.collection('ADMIN').doc(uid).set(data);
        // Delete old document
        await db.collection('ADMIN').doc(oldId).delete();
        console.log(`✓ Migrated ${oldId} → ${uid} (${email || 'no email'})`);
        migrations.push({ oldId, newId: uid, email, action: 'migrated' });
      }
    }

    console.log('\n=== Migration Summary ===');
    console.log(`Total documents processed: ${adminSnapshot.size}`);
    console.log(`Successful migrations: ${migrations.length}`);
    console.log(`Errors: ${errors.length}`);

    if (migrations.length > 0) {
      console.log('\nMigrations:');
      migrations.forEach(m => {
        console.log(`  ${m.oldId} → ${m.newId} (${m.email || 'no email'}) [${m.action}]`);
      });
    }

    if (errors.length > 0) {
      console.log('\nErrors:');
      errors.forEach(e => {
        console.log(`  ${e.id}: ${e.reason}`);
      });
    }

    console.log('\n✓ Migration complete!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
migrateAdminDocs()
  .then(() => {
    console.log('\nDone!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
