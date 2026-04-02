/**
 * Script to import BIPOC providers from Excel file
 * Run with: node importBipocProviders.js
 */

const admin = require("firebase-admin");
const XLSX = require("xlsx");
const path = require("path");

// Initialize Firebase Admin only if running as standalone script
// When required as a module, admin should already be initialized by the parent module
let db;
if (require.main === module) {
  // Running as standalone script - initialize admin
  if (!admin.apps.length) {
    try {
      const serviceAccountPath = require("path").join(__dirname, "..", "serviceAccountKey.json");
      const fs = require("fs");
      if (fs.existsSync(serviceAccountPath)) {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
      } else {
        admin.initializeApp();
      }
    } catch (error) {
      try {
        admin.initializeApp();
      } catch (e) {
        console.error("Failed to initialize Firebase Admin:", e);
      }
    }
  }
  db = admin.firestore();
} else {
  // Being required as a module - use existing admin instance
  // Admin should already be initialized by the parent module (index.js)
  if (admin.apps.length > 0) {
    db = admin.firestore();
  } else {
    // Fallback: try to initialize if not already done
    try {
      admin.initializeApp();
      db = admin.firestore();
    } catch (e) {
      // Admin will be initialized by parent module
      db = null;
    }
  }
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
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    verifiedBy: "system",
  };
}

/**
 * Parse address string into components
 */
function parseAddress(addressString) {
  if (!addressString) return null;
  
  // Try to parse common address formats
  // Format: "123 Main St, City, State ZIP"
  const parts = addressString.split(",").map(p => p.trim());
  
  if (parts.length >= 3) {
    const zipStateMatch = parts[parts.length - 1].match(/([A-Z]{2})\s+(\d{5}(?:-\d{4})?)/);
    if (zipStateMatch) {
      return {
        address: parts[0],
        address2: parts.length > 3 ? parts.slice(1, -2).join(", ") : null,
        city: parts[parts.length - 2],
        state: zipStateMatch[1],
        zip: zipStateMatch[2].substring(0, 5), // Only first 5 digits
      };
    }
  }
  
  // Fallback: return as-is
  return {
    address: addressString,
    address2: null,
    city: null,
    state: "OH",
    zip: null,
  };
}

/**
 * Parse phone number to standard format
 */
function parsePhone(phoneString) {
  if (!phoneString) return null;
  // Remove all non-digits
  const digits = phoneString.replace(/\D/g, "");
  if (digits.length === 10) {
    return `(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}`;
  }
  return phoneString;
}

/**
 * Map Excel row to Provider data structure
 * Adjust column names based on your Excel file structure
 */
function mapRowToProvider(row, headers) {
  // Common column name variations - adjust based on your Excel file
  const getName = (variations) => {
    for (const variation of variations) {
      const key = headers.find(h => 
        h.toLowerCase().includes(variation.toLowerCase())
      );
      if (key) return row[key];
    }
    return null;
  };

  const name = getName(["name", "provider name", "provider", "full name"]) || "";
  const practiceName = getName(["practice", "practice name", "organization", "clinic"]);
  const specialty = getName(["specialty", "specialties", "type", "provider type"]);
  const npi = getName(["npi", "national provider identifier"]);
  const phone = parsePhone(getName(["phone", "telephone", "phone number", "contact"]));
  const email = getName(["email", "e-mail", "email address"]);
  const website = getName(["website", "url", "web"]);
  const address = getName(["address", "street", "street address"]);
  const city = getName(["city"]);
  const state = getName(["state"]) || "OH";
  const zip = getName(["zip", "zipcode", "zip code", "postal code"]);
  
  // Build location
  const location = address ? parseAddress(address) : null;
  if (location && city) location.city = city;
  if (location && state) location.state = state;
  if (location && zip) location.zip = zip.substring(0, 5);
  if (location && phone) location.phone = phone;

  const locations = location ? [location] : [];

  // Create provider data
  const providerData = {
    name: name.trim(),
    practiceName: practiceName ? practiceName.trim() : null,
    specialty: specialty ? specialty.trim() : null,
    npi: npi ? npi.toString().trim() : null,
    locations: locations,
    providerTypes: [], // Will need to be determined or left empty
    specialties: specialty ? [specialty.trim()] : [],
    phone: phone,
    email: email ? email.trim() : null,
    website: website ? website.trim() : null,
    acceptingNewPatients: null,
    acceptsPregnantWomen: null,
    acceptsNewborns: null,
    telehealth: null,
    rating: null,
    reviewCount: 0,
    mamaApproved: false,
    mamaApprovedCount: 0,
    identityTags: [createBipocTag()],
    source: "bipoc_directory",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  return providerData;
}

/**
 * Import providers from Excel file
 */
async function importBipocProviders(excelFilePath) {
  try {
    console.log(`Reading Excel file: ${excelFilePath}`);
    
    // Read Excel file
    const workbook = XLSX.readFile(excelFilePath);
    const sheetName = workbook.SheetNames[0]; // Use first sheet
    const worksheet = workbook.Sheets[sheetName];
    
    // Convert to JSON
    const rows = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
    
    if (rows.length < 2) {
      console.log("Excel file is empty or has no data rows");
      return;
    }

    // First row is headers
    const headers = rows[0].map(h => h ? h.toString().trim() : "");
    console.log("Headers found:", headers);

    // Process data rows
    const providers = [];
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      if (!row || row.length === 0) continue;

      // Convert row array to object
      const rowObj = {};
      headers.forEach((header, index) => {
        rowObj[header] = row[index] ? row[index].toString().trim() : "";
      });

      // Skip empty rows
      const name = rowObj[headers.find(h => 
        h.toLowerCase().includes("name")) || ""] || "";
      if (!name || name.trim() === "") {
        console.log(`Skipping row ${i + 1}: No name found`);
        continue;
      }

      const providerData = mapRowToProvider(rowObj, headers);
      
      if (!providerData.name || providerData.name.trim() === "") {
        console.log(`Skipping row ${i + 1}: Invalid provider data`);
        continue;
      }

      providers.push(providerData);
    }

    console.log(`\nFound ${providers.length} providers to import\n`);

    // Import to Firestore
    let imported = 0;
    let updated = 0;
    let errors = 0;

    for (const providerData of providers) {
      try {
        // Check if provider exists by NPI or name
        let providerId = null;
        
        if (providerData.npi) {
          const existingByNpi = await db.collection("providers")
            .where("npi", "==", providerData.npi)
            .limit(1)
            .get();
          
          if (!existingByNpi.empty) {
            providerId = existingByNpi.docs[0].id;
          }
        }

        // If not found by NPI, check by name and practice
        if (!providerId) {
          let query = db.collection("providers")
            .where("name", "==", providerData.name);
          
          if (providerData.practiceName) {
            query = query.where("practiceName", "==", providerData.practiceName);
          }
          
          const existingByName = await query.limit(1).get();
          
          if (!existingByName.empty) {
            providerId = existingByName.docs[0].id;
          }
        }

        if (providerId) {
          // Update existing provider - add BIPOC tag if not present
          const existingDoc = await db.collection("providers").doc(providerId).get();
          const existingData = existingDoc.data();
          
          const existingTags = existingData.identityTags || [];
          const hasBipocTag = existingTags.some(tag => 
            tag.name === "BIPOC" || tag.id === "bipoc"
          );

          const updateData = {
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };

          // Add BIPOC tag if not present
          if (!hasBipocTag) {
            updateData.identityTags = admin.firestore.FieldValue.arrayUnion(createBipocTag());
          }

          // Update other fields if they're missing
          if (!existingData.practiceName && providerData.practiceName) {
            updateData.practiceName = providerData.practiceName;
          }
          if (!existingData.specialty && providerData.specialty) {
            updateData.specialty = providerData.specialty;
          }
          if (!existingData.phone && providerData.phone) {
            updateData.phone = providerData.phone;
          }
          if (!existingData.email && providerData.email) {
            updateData.email = providerData.email;
          }
          if (!existingData.website && providerData.website) {
            updateData.website = providerData.website;
          }
          // Merge locations
          if (providerData.locations.length > 0) {
            const existingLocations = existingData.locations || [];
            const newLocations = providerData.locations.filter(newLoc => {
              // Check if location already exists
              return !existingLocations.some(existingLoc => 
                existingLoc.address === newLoc.address &&
                existingLoc.city === newLoc.city &&
                existingLoc.zip === newLoc.zip
              );
            });
            if (newLocations.length > 0) {
              // Combine existing and new locations
              updateData.locations = [...existingLocations, ...newLocations];
            }
          }

          await db.collection("providers").doc(providerId).update(updateData);
          console.log(`✓ Updated: ${providerData.name}${providerData.practiceName ? ` (${providerData.practiceName})` : ""}`);
          updated++;
        } else {
          // Create new provider
          const docRef = await db.collection("providers").add(providerData);
          console.log(`✓ Created: ${providerData.name}${providerData.practiceName ? ` (${providerData.practiceName})` : ""} [${docRef.id}]`);
          imported++;
        }
      } catch (error) {
        console.error(`✗ Error processing ${providerData.name}:`, error.message);
        errors++;
      }
    }

    console.log(`\n=== Import Summary ===`);
    console.log(`Imported: ${imported}`);
    console.log(`Updated: ${updated}`);
    console.log(`Errors: ${errors}`);
    console.log(`Total: ${providers.length}`);

  } catch (error) {
    console.error("Error importing providers:", error);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  const excelFilePath = process.argv[2] || path.join(__dirname, "..", "BIPOC Provider Directory.xlsx");
  
  console.log("Starting BIPOC provider import...");
  console.log(`Excel file: ${excelFilePath}\n`);
  
  importBipocProviders(excelFilePath)
    .then(() => {
      console.log("\nImport completed successfully!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("\nImport failed:", error);
      process.exit(1);
    });
}

module.exports = { importBipocProviders };
