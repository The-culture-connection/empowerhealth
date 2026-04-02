// Firebase Cloud Function for Provider Search
// This function processes provider search requests from the client
// It calls Ohio Medicaid API and NPI Registry API, then returns combined results

const {onCall} = require("firebase-functions/v2/https");
const {HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const axios = require("axios");

// Note: axios is already in package.json dependencies

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

function inferTaxonomyFromProviderTypes(providerTypeIds) {
  // Map provider type IDs to taxonomy codes
  const typeIdMap = {
    "09": "207V00000X", // OB-GYN
    "01": "207V00000X", // Hospital (may have OB-GYN)
    "71": "367A00000X", // Nurse Midwife Individual
    "46": "367A00000X", // Certified Nurse Midwife
    "44": "363L00000X", // Nurse Practitioner
    "19": "207V00000X", // Osteopathic Physician
    "20": "207V00000X", // Physician / Osteopath Individual
  };
  
  for (const typeId of providerTypeIds) {
    if (typeIdMap[typeId]) {
      return typeIdMap[typeId];
    }
  }
  
  return null;
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
  } = request.data;

  // Validate required parameters
  if (!zip || !city || !healthPlan || !providerTypeIds || !radius) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required parameters: zip, city, healthPlan, providerTypeIds, radius"
    );
  }

  try {
    const providers = [];

    // 1. Search Ohio Medicaid API
    try {
      const medicaidUrl = new URL("https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR");
      const medicaidParams = {
        state: "OH",
        zip: zip,
        City: city, // Note: Capital C
        healthplan: healthPlan, // lowercase
        ProviderTypeIDsDelimited: Array.isArray(providerTypeIds) 
          ? providerTypeIds.join(",") 
          : providerTypeIds,
        radius: radius.toString(),
        Program: "1", // Capital P, always '1'
      };

      if (acceptsPregnantWomen !== undefined) {
        medicaidParams.AcceptsPregnantWomen = acceptsPregnantWomen ? "1" : "0";
      }
      if (acceptsNewborns !== undefined) {
        medicaidParams.AcceptsNewborns = acceptsNewborns ? "1" : "0";
      }
      if (telehealth !== undefined) {
        medicaidParams.Telehealth = telehealth ? "1" : "0";
      }

      Object.keys(medicaidParams).forEach((key) => {
        medicaidUrl.searchParams.append(key, medicaidParams[key]);
      });

      console.log(`[Medicaid] Searching: ${medicaidUrl.toString()}`);

      const medicaidResponse = await axios.get(medicaidUrl.toString());
      const medicaidData = medicaidResponse.data;

      // Parse FHIR Bundle
      if (medicaidData.entry && Array.isArray(medicaidData.entry)) {
        const medicaidProviders = parseMedicaidResponse(medicaidData.entry, specialty);
        providers.push(...medicaidProviders);
        console.log(`[Medicaid] Found ${medicaidProviders.length} providers`);
      } else {
        console.log("[Medicaid] No entry field or empty results");
      }
    } catch (error) {
      console.error("Error searching Medicaid API:", error.message);
      // Continue to NPI search if enabled
    }

    // 2. Search NPI Registry if enabled or if Medicaid returned no results
    if (includeNpi || providers.length === 0) {
      try {
        // Determine taxonomy code
        let taxonomyCode = null;
        
        if (specialty) {
          taxonomyCode = getTaxonomyCode(specialty);
        }
        
        if (!taxonomyCode && Array.isArray(providerTypeIds)) {
          taxonomyCode = inferTaxonomyFromProviderTypes(providerTypeIds);
        }
        
        if (!taxonomyCode) {
          console.log("[NPI] Cannot infer taxonomy code, skipping NPI search");
        } else {
          const npiUrl = new URL("https://npiregistry.cms.hhs.gov/api/");
          const npiParams = {
            version: "2.1",
            state: "OH",
            taxonomy_code: taxonomyCode,
            limit: "50",
          };
          
          if (zip) {
            npiParams.postal_code = zip;
          }
          if (city) {
            npiParams.city = city;
          }
          
          Object.keys(npiParams).forEach((key) => {
            npiUrl.searchParams.append(key, npiParams[key]);
          });
          
          console.log(`[NPI] Searching: ${npiUrl.toString()}`);
          
          const npiResponse = await axios.get(npiUrl.toString());
          const npiData = npiResponse.data;
          
          if (npiData.results && Array.isArray(npiData.results)) {
            const npiProviders = parseNpiResponse(npiData.results);
            providers.push(...npiProviders);
            console.log(`[NPI] Found ${npiProviders.length} providers`);
          }
        }
      } catch (error) {
        console.error("Error searching NPI API:", error.message);
        // Continue with Medicaid results only
      }
    }

    // 3. Deduplicate providers by NPI or name+location
    const deduplicatedProviders = deduplicateProviders(providers);

    // 4. Enrich with Firestore data (reviews, identity tags, Mama Approved)
    const enrichedProviders = await enrichProvidersWithFirestore(deduplicatedProviders);

    return {
      providers: enrichedProviders,
      count: enrichedProviders.length,
    };
  } catch (error) {
    console.error("Error in searchProviders:", error);
    throw new HttpsError("internal", "Provider search failed: " + error.message);
  }
});

// Helper function to parse Medicaid FHIR Bundle entries
function parseMedicaidResponse(entries, specialtyFilter) {
  const providers = [];
  
  for (const entry of entries) {
    if (!entry.resource) continue;
    
    try {
      const resource = entry.resource;
      const provider = parseFhirResource(resource);
      
      if (provider) {
        // Apply specialty filter if provided
        if (!specialtyFilter || 
            !provider.specialty ||
            provider.specialty.toLowerCase().includes(specialtyFilter.toLowerCase())) {
          providers.push(provider);
        }
      }
    } catch (error) {
      console.error("Error parsing Medicaid entry:", error);
      continue;
    }
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
            ? addr.line.map((l) => l.toString()) 
            : (addr.line ? [addr.line.toString()] : []);
          
          locations.push({
            address: addressLines.join(", "),
            city: addr.city || "",
            state: addr.state || "OH",
            zip: addr.postalCode || "",
          });
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
            }
          }
        } catch (error) {
          console.error(`Error getting reviews for ${firestoreId}:`, error);
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
