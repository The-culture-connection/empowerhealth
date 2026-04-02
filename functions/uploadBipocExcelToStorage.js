/**
 * Script to upload BIPOC Provider Directory Excel file to Firebase Storage
 * Run with: node uploadBipocExcelToStorage.js
 */

const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

// Initialize Firebase Admin
if (!admin.apps.length) {
  try {
    const serviceAccountPath = path.join(__dirname, "..", "serviceAccountKey.json");
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      admin.initializeApp();
    }
  } catch (error) {
    admin.initializeApp();
  }
}

async function uploadBipocExcelToStorage() {
  try {
    const excelFilePath = path.join(__dirname, "..", "BIPOC Provider Directory.xlsx");
    
    if (!fs.existsSync(excelFilePath)) {
      console.error(`❌ Excel file not found: ${excelFilePath}`);
      console.log("Please ensure 'BIPOC Provider Directory.xlsx' is in the project root directory");
      process.exit(1);
    }

    console.log(`📤 Uploading Excel file to Firebase Storage...`);
    console.log(`   Source: ${excelFilePath}`);
    
    const bucket = admin.storage().bucket();
    const storagePath = "bipoc-directory/BIPOC Provider Directory.xlsx";
    const file = bucket.file(storagePath);

    // Read file
    const fileBuffer = fs.readFileSync(excelFilePath);
    console.log(`   File size: ${fileBuffer.length} bytes`);

    // Upload to Storage
    await file.save(fileBuffer, {
      metadata: {
        contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        metadata: {
          uploadedAt: new Date().toISOString(),
          description: "BIPOC Provider Directory for Cincinnati area",
        },
      },
    });

    // Make file publicly readable (or use signed URLs)
    await file.makePublic();

    console.log(`✅ Successfully uploaded to: ${storagePath}`);
    console.log(`✅ File is now accessible in Firebase Storage`);
    console.log(`\nThe BIPOC providers will now be included in search results for Clinical Counselor searches in Cincinnati.`);

  } catch (error) {
    console.error("❌ Error uploading file:", error);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  uploadBipocExcelToStorage()
    .then(() => {
      console.log("\n✅ Upload completed!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("\n❌ Upload failed:", error);
      process.exit(1);
    });
}

module.exports = { uploadBipocExcelToStorage };
