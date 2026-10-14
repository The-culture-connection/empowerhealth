/**
 * Promote a UserProviders document into the public `providers` collection
 * using the same field shape the Flutter app and Cloud Functions expect.
 */

import { serverTimestamp, Timestamp } from "firebase/firestore";

function optStr(v: unknown): string | null {
  if (v == null) return null;
  const s = String(v).trim();
  return s.length > 0 ? s : null;
}

function normalizeLocation(loc: unknown): Record<string, unknown> | null {
  if (!loc || typeof loc !== "object") return null;
  const m = loc as Record<string, unknown>;
  const zip = m.zip != null ? String(m.zip) : "";
  const city = m.city != null ? String(m.city) : "";
  const state = m.state != null ? String(m.state) : "OH";
  const address = m.address != null ? String(m.address) : "";
  if (!zip.trim() && !city.trim() && !address.trim()) return null;
  const row: Record<string, unknown> = {
    address,
    city,
    state,
    zip,
  };
  if (m.address2 != null) row.address2 = m.address2;
  if (m.phone != null) row.phone = m.phone;
  if (m.latitude != null) row.latitude = m.latitude;
  if (m.longitude != null) row.longitude = m.longitude;
  if (m.distance != null) row.distance = m.distance;
  if (m.id != null) row.id = m.id;
  return row;
}

function normalizeLocations(raw: unknown): Record<string, unknown>[] {
  if (!Array.isArray(raw)) return [];
  return raw.map(normalizeLocation).filter((x): x is Record<string, unknown> => x != null);
}

function normalizeStringArray(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];
  return raw.map((x) => String(x)).filter((s) => s.length > 0);
}

function normalizeIdentityTags(raw: unknown): Record<string, unknown>[] {
  if (!Array.isArray(raw)) return [];
  const out: Record<string, unknown>[] = [];
  for (const t of raw) {
    if (!t || typeof t !== "object") continue;
    const m = t as Record<string, unknown>;
    out.push({
      id: m.id != null ? String(m.id) : "",
      name: m.name != null ? String(m.name) : "",
      category: m.category != null ? String(m.category) : "",
      source: m.source != null ? String(m.source) : "user_claim",
      verificationStatus:
        m.verificationStatus != null ? String(m.verificationStatus) : "pending",
      ...(m.verifiedBy != null ? { verifiedBy: m.verifiedBy } : {}),
      ...(m.verifiedAt instanceof Timestamp ? { verifiedAt: m.verifiedAt } : {}),
    });
  }
  return out;
}

/**
 * Stable id so re-approval overwrites the same directory row.
 */
export function publicProviderDocIdForUserProvider(userProviderId: string): string {
  return `up_${userProviderId}`;
}

/**
 * Build the `providers` document. `source` must stay `user_submission` so
 * `searchFirestoreProviders` in Cloud Functions includes this row in directory search.
 */
export function buildProvidersPayloadFromUserProvider(
  userProviderId: string,
  raw: Record<string, unknown>,
): Record<string, unknown> {
  const locations = normalizeLocations(raw.locations);
  if (locations.length === 0) {
    throw new Error(
      "Submission has no valid locations; add at least address/city/ZIP before approving.",
    );
  }

  const name = raw.name != null ? String(raw.name).trim() : "";
  if (!name) {
    throw new Error("Submission is missing a provider name.");
  }

  const createdAt =
    raw.createdAt instanceof Timestamp ? raw.createdAt : serverTimestamp();

  const reviewCount =
    typeof raw.reviewCount === "number" && Number.isFinite(raw.reviewCount)
      ? raw.reviewCount
      : 0;
  const mamaApprovedCount =
    typeof raw.mamaApprovedCount === "number" && Number.isFinite(raw.mamaApprovedCount)
      ? raw.mamaApprovedCount
      : 0;

  const rating =
    typeof raw.rating === "number" && Number.isFinite(raw.rating) ? raw.rating : null;

  const payload: Record<string, unknown> = {
    name,
    specialty: optStr(raw.specialty),
    practiceName: optStr(raw.practiceName),
    npi: optStr(raw.npi),
    locations,
    providerTypes: normalizeStringArray(raw.providerTypes),
    specialties: normalizeStringArray(raw.specialties),
    phone: optStr(raw.phone),
    email: optStr(raw.email),
    website: optStr(raw.website),
    acceptingNewPatients: raw.acceptingNewPatients ?? null,
    acceptsPregnantWomen: raw.acceptsPregnantWomen ?? null,
    acceptsNewborns: raw.acceptsNewborns ?? null,
    telehealth: raw.telehealth ?? null,
    rating,
    reviewCount,
    mamaApproved: true,
    mamaApprovedCount,
    identityTags: normalizeIdentityTags(raw.identityTags),
    source: "user_submission",
    acceptedHealthType: optStr(raw.acceptedHealthType),
    acceptedHealthTypes: normalizeStringArray(raw.acceptedHealthTypes),
    promotedFromUserProviderId: userProviderId,
    createdAt,
    updatedAt: serverTimestamp(),
  };

  return payload;
}
