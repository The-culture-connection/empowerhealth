/**
 * Provider search engine shared by the `OhioMaximusSearch` and `searchProviders`
 * callables (functions/index.js).
 *
 * What it does
 * ------------
 * 1. Geography. Distances are computed offline from functions/data/zip-centroids.json
 *    (US Census 2023 ZCTA + Place internal points, public domain; built by
 *    scripts/geo/build-zip-centroids.mjs). A location uses street coordinates when the
 *    upstream gives them, else its ZIP centroid, else its city centroid. Locations
 *    farther than radiusLimit(radius) from the searched ZIP are dropped; a provider with
 *    no in-radius location is dropped; the nearest in-radius location is listed first.
 *
 * 2. Ohio Medicaid directory (Maximus FHIR, psapi.ohpnm.omes.maximus.com).
 *    The API returns at most 100 providers per query, has no paging, and the 100 are
 *    not nearest-first. So:
 *      - every provider type is queried separately (a universal search can no longer be
 *        crowded out by physicians/NPs);
 *      - "All plans" / "Not listed / not sure" use the API's own `healthplan=All Plans`
 *        value (one query covers every Ohio Medicaid plan, and PractitionerRole.organization
 *        tells us each provider's plans);
 *      - each (plan, type) is queried on a radius ladder that matches the app's radius
 *        options (3, 5, 10, 15, 25, 50 mi), smallest first, stopping at the first rung that
 *        hits the 100 cap. When a small rung is capped, its 100 providers are all nearer
 *        than anything a bigger rung could add on average, and a larger search repeats the
 *        exact same rung queries, so a larger radius never drops a provider that a smaller
 *        radius returned (results are a superset, up to the per-type cap below);
 *      - responses are cached (memory + Firestore `provider_search_cache`, 12 h) so the two
 *        callables the app makes share one upstream fetch and repeat searches are fast.
 *
 * 3. NPI Registry. `taxonomy_code` is NOT an NPI API parameter (it was silently ignored),
 *    so the registry is queried by `taxonomy_description` and the codes are checked
 *    afterwards. Areas queried: the 6 nearest ZIPs inside the radius (exact) plus every
 *    3-digit ZIP prefix that intersects the radius (wildcard). Practice locations
 *    (`practiceLocations`) are included and the nearest one is shown.
 *
 * 4. Caps. Results are nearest-first, de-duplicated by provider identity, and capped per
 *    provider type (Medicaid) / per taxonomy (NPI), so no single type can crowd out the
 *    others. `coverage.completeWithinMiles` reports the distance up to which the list is
 *    complete (null when nothing was cut).
 */

const axios = require("axios");
const crypto = require("crypto");
const admin = require("firebase-admin");
const {Timestamp} = require("firebase-admin/firestore");

// ---------------------------------------------------------------------------
// Tunables
// ---------------------------------------------------------------------------
const RADIUS_RUNGS = [3, 5, 10, 15, 25, 50]; // provider_quick_search_screen.dart _radiusOptions
const MAXIMUS_BASE = "https://psapi.ohpnm.omes.maximus.com/fhir/PublicSearchFHIR";
const MAXIMUS_CAP = 100; // hard cap of the Ohio Medicaid API (unique providers per query)
const MAXIMUS_CONCURRENCY = Number(process.env.PROVIDER_SEARCH_MAXIMUS_CONCURRENCY || 10); // per instance
const MAXIMUS_TIMEOUT_MS = 30000;
const MEDICAID_PER_TYPE_CAP = 60;
const NPI_BASE = "https://npiregistry.cms.hhs.gov/api/";
const NPI_CONCURRENCY = 8;
const NPI_TIMEOUT_MS = 15000;
const NPI_PAGE_SIZE = 200;
const NPI_NEAREST_ZIPS = 6;
const NPI_PER_TAXONOMY_CAP = 30;
const MEM_TTL_MS = 30 * 60 * 1000;
const FS_TTL_MS = 12 * 60 * 60 * 1000;
const CACHE_COLLECTION = "provider_search_cache";
const CACHE_VERSION = 2;

// Ohio Medicaid plan names as Maximus writes them in PractitionerRole.organization
// ("HealthPlan/<name>") -> the names the app shows.
const PLAN_DISPLAY = {
  "caresource": "CareSource",
  "buckeye": "Buckeye",
  "molina": "Molina",
  "unitedhealthcare": "UnitedHealthcare",
  "anthem": "Anthem",
  "aetna": "Aetna",
  "amerihealth": "AmeriHealth Caritas",
  "amerihealthcaritas": "AmeriHealth Caritas",
  "humana": "Humana",
};
const ALL_PLANS = "All Plans"; // Maximus' own "every plan" value

function planDisplayName(raw) {
  const s = String(raw || "").replace(/^HealthPlan\//i, "").trim();
  if (!s) return null;
  return PLAN_DISPLAY[s.toLowerCase().replace(/[^a-z]/g, "")] || s;
}

// ---------------------------------------------------------------------------
// Geography
// ---------------------------------------------------------------------------
let GEO = null;
function geoTables() {
  if (GEO) return GEO;
  const raw = require("./data/zip-centroids.json");
  const placesNoSpace = {};
  for (const [k, v] of Object.entries(raw.places || {})) placesNoSpace[k.replace(/\s+/g, "")] = v;
  GEO = {zips: raw.zips || {}, places: raw.places || {}, placesNoSpace};
  return GEO;
}

function zip5(z) {
  const m = String(z || "").match(/\d{5}/);
  return m ? m[0] : null;
}

function normCity(c) {
  return String(c || "").toLowerCase().replace(/\./g, "").replace(/^saint\s+/, "st ").replace(/\s+/g, " ").trim();
}

function pointForZip(zip) {
  const z = zip5(zip);
  const p = z ? geoTables().zips[z] : null;
  return p ? {lat: p[0], lon: p[1], precision: "zip"} : null;
}

function pointForPlace(city, state) {
  const c = normCity(city);
  if (!c) return null;
  const st = String(state || "OH").trim().toUpperCase().slice(0, 2);
  const t = geoTables();
  const p = t.places[`${st}|${c}`] || t.placesNoSpace[`${st}|${c}`.replace(/\s+/g, "")];
  return p ? {lat: p[0], lon: p[1], precision: "city"} : null;
}

/** Best point for a location: street coordinates, then ZIP centroid, then city centroid. */
function locatePoint(loc) {
  const lat = Number(loc && loc.latitude);
  const lon = Number(loc && loc.longitude);
  if (loc && loc.latitude != null && loc.longitude != null && Number.isFinite(lat) && Number.isFinite(lon) &&
      Math.abs(lat) > 0.01) {
    return {lat, lon, precision: "street"};
  }
  return pointForZip(loc && loc.zip) || pointForPlace(loc && loc.city, loc && loc.state);
}

function haversineMi(a, b) {
  const R = 3958.8;
  const r = (d) => (d * Math.PI) / 180;
  const h = Math.sin(r(b.lat - a.lat) / 2) ** 2 +
    Math.cos(r(a.lat)) * Math.cos(r(b.lat)) * Math.sin(r(b.lon - a.lon) / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/**
 * A location counts as inside the radius when its (centroid) distance is at most
 * radius + 0.5 mi + 5%. The slack absorbs ZIP-centroid error (the upstream APIs filter on
 * street addresses) without letting obviously distant offices through.
 */
function radiusLimit(radius) {
  const r = Number(radius) || 0;
  return r + 0.5 + 0.05 * r;
}

/** Search origin: the searched ZIP's centroid, else the city's centroid. */
function searchOrigin(zip, city, state = "OH") {
  return pointForZip(zip) || pointForPlace(city, state);
}

const round1 = (d) => (d == null ? null : Math.round(d * 10) / 10);

/**
 * Adds distance/latitude/longitude to each location, removes locations outside the radius
 * and sorts the rest nearest-first. Returns {locations, distance} or null when the provider
 * has no location inside the radius. With no origin, nothing is filtered.
 */
function placeLocations(locations, origin, radius, {keepUnlocatedWithoutOrigin = true} = {}) {
  const locs = Array.isArray(locations) ? locations : [];
  if (!origin) {
    return keepUnlocatedWithoutOrigin ? {locations: locs.map((l) => ({...l})), distance: null} : null;
  }
  const limit = radiusLimit(radius);
  const inRadius = [];
  for (const l of locs) {
    const p = locatePoint(l);
    if (!p) continue;
    const d = haversineMi(origin, p);
    if (d > limit) continue;
    inRadius.push({
      ...l,
      latitude: p.lat,
      longitude: p.lon,
      distance: round1(d),
      _d: d,
    });
  }
  if (!inRadius.length) return null;
  inRadius.sort((a, b) => a._d - b._d);
  const distance = inRadius[0]._d;
  return {locations: inRadius.map(({_d, ...rest}) => rest), distance};
}

/** ZCTAs inside the radius, nearest first: [{zip, d}] */
function zipsWithinRadius(origin, radius) {
  if (!origin) return [];
  const limit = radiusLimit(radius);
  const out = [];
  for (const [z, p] of Object.entries(geoTables().zips)) {
    const d = haversineMi(origin, {lat: p[0], lon: p[1]});
    if (d <= limit) out.push({zip: z, d});
  }
  out.sort((a, b) => a.d - b.d || a.zip.localeCompare(b.zip));
  return out;
}

// ---------------------------------------------------------------------------
// Concurrency + caching
// ---------------------------------------------------------------------------
function createLimiter(n) {
  let active = 0;
  const queue = [];
  const next = () => {
    if (active >= n || !queue.length) return;
    active++;
    const {fn, resolve, reject} = queue.shift();
    Promise.resolve().then(fn).then(resolve, reject).finally(() => {
      active--;
      next();
    });
  };
  return (fn) => new Promise((resolve, reject) => {
    queue.push({fn, resolve, reject});
    next();
  });
}

async function mapLimit(items, n, fn) {
  const out = new Array(items.length);
  let i = 0;
  const worker = async () => {
    while (i < items.length) {
      const idx = i++;
      out[idx] = await fn(items[idx], idx);
    }
  };
  await Promise.all(Array.from({length: Math.min(n, items.length)}, worker));
  return out;
}

const maximusLimit = createLimiter(MAXIMUS_CONCURRENCY);
const npiLimit = createLimiter(NPI_CONCURRENCY);
const memCache = new Map();
const inflight = new Map();

function memGet(key) {
  const hit = memCache.get(key);
  if (!hit) return undefined;
  if (Date.now() - hit.at > MEM_TTL_MS) {
    memCache.delete(key);
    return undefined;
  }
  return hit.value;
}
function memSet(key, value) {
  if (memCache.size > 2000) memCache.delete(memCache.keys().next().value);
  memCache.set(key, {at: Date.now(), value});
}

/**
 * Cached loader. `persist` also uses Firestore so separate function instances (and the two
 * callables) share results. Only results with ok:true are cached.
 */
async function cachedFetch(key, loader, {persist = false} = {}) {
  const m = memGet(key);
  if (m !== undefined) return {...m, cache: "memory"};
  if (inflight.has(key)) return inflight.get(key);
  const p = (async () => {
    const docId = crypto.createHash("sha1").update(`${CACHE_VERSION}|${key}`).digest("hex");
    if (persist) {
      try {
        const snap = await admin.firestore().collection(CACHE_COLLECTION).doc(docId).get();
        if (snap.exists) {
          const d = snap.data();
          const at = d.fetchedAt && d.fetchedAt.toMillis ? d.fetchedAt.toMillis() : 0;
          if (d.v === CACHE_VERSION && Date.now() - at < FS_TTL_MS && typeof d.payload === "string") {
            const value = JSON.parse(d.payload);
            memSet(key, value);
            return {...value, cache: "firestore"};
          }
        }
      } catch (e) {
        console.warn(`[providerSearch] cache read failed: ${e.message}`);
      }
    }
    const value = await loader();
    if (value && value.ok) {
      memSet(key, value);
      if (persist) {
        const payload = JSON.stringify(value);
        if (payload.length < 900000) {
          try {
            await admin.firestore().collection(CACHE_COLLECTION).doc(docId).set({
              v: CACHE_VERSION,
              key: key.slice(0, 1400),
              payload,
              fetchedAt: Timestamp.now(),
              expireAt: Timestamp.fromMillis(Date.now() + FS_TTL_MS),
            });
          } catch (e) {
            console.warn(`[providerSearch] cache write failed: ${e.message}`);
          }
        }
      }
    }
    return {...value, cache: "miss"};
  })();
  inflight.set(key, p);
  try {
    return await p;
  } finally {
    inflight.delete(key);
  }
}

// ---------------------------------------------------------------------------
// Ohio Medicaid (Maximus FHIR)
// ---------------------------------------------------------------------------
function buildMaximusUrl({zip, state = "OH", plan, typeId, radius, telehealth}) {
  const u = new URL(MAXIMUS_BASE);
  u.searchParams.append("state", state || "OH");
  u.searchParams.append("zip", zip);
  u.searchParams.append("healthplan", plan);
  u.searchParams.append("ProviderTypeIDsDelimited", typeId);
  u.searchParams.append("radius", String(radius));
  // AcceptsPregnantWomen / AcceptsNewborns are not sent: the API returns identical results
  // with and without them (checked 2026-10 for types 01, 71, 72), and leaving them out lets
  // both callables share cached responses. Telehealth is sent only when asked for.
  if (telehealth === true) u.searchParams.append("Telehealth", "1");
  return u.toString();
}

/** Maximus address lines are JSON strings like [{"ADDRESS_1":"..","ADDRESS_2":".."}]. */
function maximusAddressLine(line) {
  const lines = Array.isArray(line) ? line : (line ? [line] : []);
  const parts = [];
  for (const l of lines) {
    const s = String(l || "");
    if (s.trim().startsWith("[") && s.includes("ADDRESS_1")) {
      try {
        const arr = JSON.parse(s);
        for (const o of arr) {
          for (const v of [o.ADDRESS_1, o.ADDRESS_2]) {
            const t = String(v || "").replace(/\s+/g, " ").trim();
            if (t) parts.push(t);
          }
        }
        continue;
      } catch (e) {
        // fall through to raw text
      }
    }
    const t = s.replace(/\s+/g, " ").trim();
    if (t) parts.push(t);
  }
  return parts.join(" ");
}

function locKey(l) {
  return `${String(l.address || "").toLowerCase().replace(/[^a-z0-9]/g, "")}|${zip5(l.zip) || ""}`;
}

function addLocation(rec, loc) {
  if (!loc || (!loc.address && !loc.city)) return;
  const k = locKey(loc);
  if (rec._locKeys.has(k)) return;
  rec._locKeys.add(k);
  rec.locations.push(loc);
}

function codingsOf(codeList, systemPart) {
  const out = [];
  for (const c of Array.isArray(codeList) ? codeList : []) {
    for (const cd of (c && Array.isArray(c.coding)) ? c.coding : []) {
      if (cd && cd.system && String(cd.system).includes(systemPart)) out.push(cd);
    }
  }
  return out;
}

function practitionerName(res) {
  const names = Array.isArray(res.name) ? res.name : (res.name ? [res.name] : []);
  return names.map((n) => {
    const given = Array.isArray(n.given) ? n.given.join(" ") : (n.given || "");
    return `${given} ${n.family || ""}`.trim();
  }).filter(Boolean).join(", ");
}

/**
 * Parses a Maximus bundle into compact provider records, merging the duplicate
 * Practitioner/Organization entries the API emits (one per phone/address/plan).
 */
function parseMaximusBundle(bundle, {queriedPlan, queriedType}) {
  const entries = Array.isArray(bundle && bundle.entry) ? bundle.entry : [];
  const recs = new Map();
  const specificPlan = queriedPlan && queriedPlan !== ALL_PLANS ? planDisplayName(queriedPlan) : null;
  const get = (key, kind) => {
    let r = recs.get(key);
    if (!r) {
      r = {key, kind, name: "", phone: null, types: [], specialties: [], plans: [], locations: [], _locKeys: new Set()};
      recs.set(key, r);
    }
    return r;
  };
  const addUnique = (arr, v) => {
    if (v != null && v !== "" && !arr.includes(v)) arr.push(v);
  };
  const roles = [];
  const affiliations = [];
  for (const e of entries) {
    const res = e && e.resource;
    if (!res) continue;
    if (res.resourceType === "Practitioner") {
      const r = get(`mx:p:${res.id}`, "practitioner");
      if (!r.name) r.name = practitionerName(res);
      for (const t of Array.isArray(res.telecom) ? res.telecom : []) {
        if (t && t.system === "phone" && t.value && !r.phone) r.phone = String(t.value);
      }
      for (const a of Array.isArray(res.address) ? res.address : []) {
        addLocation(r, {
          address: maximusAddressLine(a.line),
          city: a.city || "",
          state: a.state || "OH",
          zip: a.postalCode || "",
          ...(a.latitude != null ? {latitude: a.latitude, longitude: a.longitude} : {}),
        });
      }
    } else if (res.resourceType === "Organization") {
      const r = get(`mx:o:${res.id}`, "organization");
      if (!r.name) r.name = res.name || "";
      for (const c of Array.isArray(res.contact) ? res.contact : []) {
        let phone = null;
        for (const t of Array.isArray(c.telecom) ? c.telecom : []) {
          if (t && t.system === "phone" && t.value && !phone) phone = String(t.value);
        }
        if (phone && !r.phone) r.phone = phone;
        const a = c.address;
        if (a) {
          addLocation(r, {
            address: maximusAddressLine(a.line),
            city: a.city || "",
            state: a.state || "OH",
            zip: a.postalCode || "",
            phone,
          });
        }
      }
    } else if (res.resourceType === "Location" && res.position) {
      // Not emitted by Maximus today; kept so street coordinates are used if they appear.
      const a = res.address || {};
      const ref = res.managingOrganization && res.managingOrganization.reference;
      const id = ref ? String(ref).split("/").pop() : null;
      if (id) {
        addLocation(get(`mx:o:${id}`, "organization"), {
          address: maximusAddressLine(a.line), city: a.city || "", state: a.state || "OH", zip: a.postalCode || "",
          latitude: res.position.latitude, longitude: res.position.longitude,
        });
      }
    } else if (res.resourceType === "PractitionerRole") {
      roles.push(res);
    } else if (res.resourceType === "OrganizationAffiliation") {
      affiliations.push(res);
    }
  }
  for (const role of roles) {
    const ref = role.practitioner && role.practitioner.reference;
    if (!ref) continue;
    const r = get(`mx:p:${String(ref).split("/").pop()}`, "practitioner");
    if (!r.name && role.practitioner.display) r.name = String(role.practitioner.display);
    for (const cd of codingsOf(role.code, "ProviderType")) addUnique(r.types, String(cd.code));
    for (const cd of codingsOf(role.specialty, "SpecialtyType")) addUnique(r.specialties, cd.display && String(cd.display));
    const orgRef = role.organization && role.organization.reference;
    if (orgRef && /^HealthPlan\//i.test(orgRef)) addUnique(r.plans, planDisplayName(orgRef));
  }
  for (const aff of affiliations) {
    const ref = aff.organization && aff.organization.reference;
    if (!ref) continue;
    const r = get(`mx:o:${String(ref).split("/").pop()}`, "organization");
    if (!r.name && aff.organization.display) r.name = String(aff.organization.display);
    for (const cd of codingsOf(aff.code, "ProviderType")) addUnique(r.types, String(cd.code));
    for (const cd of codingsOf(aff.code, "SpecialtyType")) addUnique(r.specialties, cd.display && String(cd.display));
  }
  const records = [];
  for (const r of recs.values()) {
    if (!r.name) continue;
    if (!r.types.length && queriedType) r.types.push(queriedType);
    if (specificPlan) addUnique(r.plans, specificPlan);
    delete r._locKeys;
    records.push(r);
  }
  return records;
}

async function fetchMaximus(params) {
  const url = buildMaximusUrl(params);
  return cachedFetch(`maximus|${url}`, async () => {
    const t0 = Date.now();
    try {
      const res = await maximusLimit(() => axios.get(url, {timeout: MAXIMUS_TIMEOUT_MS}));
      const records = parseMaximusBundle(res.data, {queriedPlan: params.plan, queriedType: params.typeId});
      return {ok: true, url, capped: records.length >= MAXIMUS_CAP, count: records.length, records,
        ms: Date.now() - t0};
    } catch (e) {
      const status = e.response ? e.response.status : null;
      console.warn(`[maximus] ${url} failed after ${Date.now() - t0}ms: ${status || ""} ${e.message}`);
      return {ok: false, url, error: `${status || ""} ${e.message}`.trim(), ms: Date.now() - t0};
    }
  }, {persist: true}).then((v) => ({...v, url}));
}

function rungsFor(radius) {
  const r = Number(radius);
  const lower = RADIUS_RUNGS.filter((x) => x < r);
  return [...lower, r];
}

/**
 * Radius-ladder query for one (plan, type). Rungs are queried smallest first; the result is
 * the union of rungs up to and including the first rung that hits the 100-provider cap.
 * Rungs that cannot change the result are skipped (see the rounds below), so a dense type
 * costs one upstream call and a sparse type two or three.
 */
async function medicaidChain({zip, state, plan, typeId, radius, telehealth}, state0) {
  const rungs = rungsFor(radius);
  state0.rungs = rungs;
  state0.results = new Array(rungs.length).fill(null);
  const q = (i) => fetchMaximus({zip, state, plan, typeId, radius: rungs[i], telehealth}).then((r) => {
    state0.results[i] = r;
    return r;
  });
  // Round 1: smallest rung. Capped -> done (dense types: one upstream call).
  // Round 2: the next rung and the requested radius together.
  //   - next rung capped -> done;
  //   - requested radius NOT capped -> it holds every provider of every smaller rung, done;
  //   - otherwise round 3: the remaining middle rungs in parallel.
  const n = rungs.length;
  const first = await q(0);
  if (!first.ok || first.capped || n === 1) return;
  const p1 = n > 2 ? q(1) : null;
  const pLast = q(n - 1);
  if (p1) {
    const second = await p1;
    if (!second.ok || second.capped) return;
  }
  const last = await pLast;
  if (!last.ok) return;
  if (!last.capped) {
    st0MarkCovered(state0, n - 1);
    return;
  }
  await Promise.all(rungs.slice(2, n - 1).map((_, i) => q(i + 2)));
}

/** The largest rung came back uncapped, so it contains every smaller rung's providers. */
function st0MarkCovered(st, lastIdx) {
  st.coveredBy = lastIdx;
}

/** Contiguous prefix of finished rungs, up to the first capped one. */
function finalizeChain(st) {
  const used = [];
  let complete = false;
  let partial = false;
  if (st.coveredBy != null && st.results[0] && st.results[st.coveredBy]) {
    return {used: [st.results[0], st.results[st.coveredBy]], partial: false};
  }
  for (let i = 0; i < (st.rungs || []).length; i++) {
    const r = st.results[i];
    if (!r) {
      partial = true;
      break;
    }
    if (!r.ok) {
      partial = true;
      break;
    }
    used.push(r);
    if (r.capped) {
      complete = true;
      break;
    }
    if (i === st.rungs.length - 1) complete = true;
  }
  if (!st.rungs) partial = true;
  if (partial) {
    // Deadline/timeout: use every rung that did come back (up to the first capped one) so the
    // user still sees providers from the larger rungs. Such a response is flagged partial.
    used.length = 0;
    for (const r of st.results || []) {
      if (!r || !r.ok) continue;
      used.push(r);
      if (r.capped) break;
    }
  }
  return {used, partial: partial || !complete};
}

function sortByDistance(list) {
  return list.sort((a, b) => {
    const da = a.distanceMiles == null ? Infinity : a._dist;
    const db = b.distanceMiles == null ? Infinity : b._dist;
    if (da !== db) return da - db;
    const n = String(a.name || "").localeCompare(String(b.name || ""));
    if (n) return n;
    return String(a._key || "").localeCompare(String(b._key || ""));
  });
}

/**
 * Picks the nearest `cap` providers for each group (type / taxonomy). Returns the selected
 * providers (union, nearest-first) and the distance below which every group is complete.
 */
function selectPerGroup(providers, groupsOf, groupIds, cap) {
  const selected = new Set();
  let completeWithin = null;
  const perGroup = {};
  for (const g of groupIds) {
    const members = sortByDistance(providers.filter((p) => groupsOf(p).includes(g)));
    const take = members.slice(0, cap);
    take.forEach((p) => selected.add(p));
    const cut = members[cap];
    perGroup[g] = {found: members.length, returned: take.length, cutoffMiles: cut ? round1(cut._dist) : null};
    if (cut && cut._dist != null && (completeWithin == null || cut._dist < completeWithin)) completeWithin = cut._dist;
  }
  return {list: sortByDistance([...selected]), completeWithinMiles: round1(completeWithin), perGroup};
}

/**
 * Ohio Medicaid search. `plan` is the normalized Maximus plan (e.g. "CareSource", "All Plans").
 * Returns {providers, meta}.
 */
async function searchMedicaid({zip, city, state = "OH", plan, typeIds, radius, telehealth, specialty, deadlineMs}) {
  const t0 = Date.now();
  const origin = searchOrigin(zip, city, state);
  const chains = typeIds.map((typeId) => ({typeId}));
  const work = Promise.all(chains.map((st) =>
    medicaidChain({zip, state, plan, typeId: st.typeId, radius, telehealth}, st).catch((e) => {
      st.error = e.message;
    })));
  let timedOut = false;
  if (deadlineMs) {
    let timer;
    await Promise.race([work, new Promise((r) => {
      timer = setTimeout(() => {
        timedOut = true;
        r();
      }, deadlineMs);
    })]);
    clearTimeout(timer);
  } else {
    await work;
  }

  const byKey = new Map();
  const urls = [];
  const perType = {};
  let partial = false;
  let queries = 0;
  let cacheHits = 0;
  for (const st of chains) {
    const {used, partial: p} = finalizeChain(st);
    if (p) partial = true;
    for (const r of st.results || []) {
      if (!r) continue;
      queries++;
      if (r.cache && r.cache !== "miss") cacheHits++;
    }
    perType[st.typeId] = {
      rungsQueried: used.map((r) => Number(new URL(r.url).searchParams.get("radius"))),
      upstreamCapped: used.length ? !!used[used.length - 1].capped : false,
      partial: p,
    };
    for (const r of used) {
      urls.push(r.url);
      for (const rec of r.records) {
        let m = byKey.get(rec.key);
        if (!m) {
          m = {...rec, types: [...rec.types], specialties: [...rec.specialties], plans: [...rec.plans],
            locations: [...rec.locations], matchedTypes: []};
          byKey.set(rec.key, m);
        } else {
          for (const t of rec.types) if (!m.types.includes(t)) m.types.push(t);
          for (const s of rec.specialties) if (!m.specialties.includes(s)) m.specialties.push(s);
          for (const pl of rec.plans) if (!m.plans.includes(pl)) m.plans.push(pl);
          const seen = new Set(m.locations.map(locKey));
          for (const l of rec.locations) if (!seen.has(locKey(l))) m.locations.push(l);
          if (!m.phone && rec.phone) m.phone = rec.phone;
        }
        if (!m.matchedTypes.includes(st.typeId)) m.matchedTypes.push(st.typeId);
      }
    }
  }

  const providers = [];
  for (const rec of byKey.values()) {
    if (specialty) {
      const want = String(specialty).toLowerCase();
      if (!rec.specialties.some((s) => String(s).toLowerCase().includes(want))) continue;
    }
    const placed = placeLocations(rec.locations, origin, radius);
    if (!placed) continue;
    const plans = [...rec.plans].sort();
    providers.push({
      name: rec.name,
      specialty: rec.specialties[0] || null,
      practiceName: rec.kind === "organization" ? rec.name : null,
      npi: null,
      locations: placed.locations,
      providerTypes: rec.types,
      specialties: rec.specialties,
      phone: rec.phone || null,
      email: null,
      source: "medicaid",
      distanceMiles: round1(placed.distance),
      healthPlans: plans,
      medicaidId: rec.key,
      _dist: placed.distance,
      _key: rec.key,
      _allLocations: rec.locations,
      _matchedTypes: rec.matchedTypes,
    });
  }
  const sel = selectPerGroup(providers, (p) => p._matchedTypes, typeIds, MEDICAID_PER_TYPE_CAP);
  for (const t of typeIds) Object.assign(perType[t], sel.perGroup[t]);
  return {
    providers: sel.list,
    meta: {
      origin: origin ? {lat: origin.lat, lon: origin.lon, precision: origin.precision} : null,
      plan,
      urls,
      queries,
      cacheHits,
      partial: partial || timedOut,
      timedOut,
      completeWithinMiles: sel.completeWithinMiles,
      perTypeCap: MEDICAID_PER_TYPE_CAP,
      perType,
      ms: Date.now() - t0,
    },
  };
}

// ---------------------------------------------------------------------------
// NPI Registry
// ---------------------------------------------------------------------------
// taxonomy code -> text for the NPI API's `taxonomy_description` (partial match);
// results are then filtered on the exact code.
const NPI_TAXONOMY_DESCRIPTIONS = {
  "207V00000X": "Obstetrics & Gynecology",
  "367A00000X": "Advanced Practice Midwife",
  "363L00000X": "Nurse Practitioner",
  "261Q00000X": "Clinic/Center",
  "261QM0801X": "Clinic/Center",
  "261QE0800X": "Clinic/Center",
  "1041C0700X": "Social Worker",
  "225100000X": "Physical Therapist",
  "2251H0200X": "Physical Therapist",
  "2084P0800X": "Psychiatry",
  "251E00000X": "Home Health",
  "133V00000X": "Dietitian",
  "133VN1004X": "Nutritionist",
  "171100000X": "Acupuncturist",
  "363A00000X": "Physician Assistant",
  "171M00000X": "Case Manager",
  "111N00000X": "Chiropractor",
  "183500000X": "Pharmacist",
  "122300000X": "Dentist",
  "152W00000X": "Optometrist",
  "213E00000X": "Podiatrist",
  "163W00000X": "Registered Nurse",
  "235Z00000X": "Speech-Language Pathologist",
  "225X00000X": "Occupational Therapist",
  "103T00000X": "Psychologist",
  "231H00000X": "Audiologist",
  "101YP2500X": "Counselor",
  "101YA0400X": "Counselor",
  "106H00000X": "Marriage & Family Therapist",
  "103K00000X": "Behavior Analyst",
  "364S00000X": "Clinical Nurse Specialist",
  "367500000X": "Nurse Anesthetist",
  "333600000X": "Pharmacy",
  "332B00000X": "Durable Medical Equipment",
  "291U00000X": "Clinical Medical Laboratory",
  "341600000X": "Ambulance",
  "314000000X": "Skilled Nursing Facility",
};

function buildNpiAreaUrl({description, postal, skip = 0}) {
  const u = new URL(NPI_BASE);
  u.searchParams.append("version", "2.1");
  u.searchParams.append("taxonomy_description", description);
  u.searchParams.append("postal_code", postal);
  u.searchParams.append("limit", String(NPI_PAGE_SIZE));
  if (skip) u.searchParams.append("skip", String(skip));
  return u.toString();
}

async function fetchNpiPage(url) {
  return cachedFetch(`npi|${url}`, async () => {
    try {
      const res = await npiLimit(() => axios.get(url, {timeout: NPI_TIMEOUT_MS}));
      const data = res.data || {};
      if (data.Errors) return {ok: false, error: JSON.stringify(data.Errors)};
      return {ok: true, results: Array.isArray(data.results) ? data.results : []};
    } catch (e) {
      return {ok: false, error: e.message};
    }
  });
}

/** NPI result -> provider, with practice locations (LOCATION address + practiceLocations). */
function parseNpiRecord(result) {
  const b = result && result.basic;
  if (!b) return null;
  let name = "";
  if (b.organization_name) {
    name = b.organization_name;
  } else {
    name = [b.first_name, b.middle_name, b.last_name].filter(Boolean).join(" ");
    if (b.credential) name = `${name}, ${b.credential}`;
  }
  if (!name) return null;
  const toLoc = (a) => ({
    address: a.address_1 || "",
    address2: a.address_2 || null,
    city: a.city || "",
    state: a.state || "",
    zip: a.postal_code || "",
    phone: a.telephone_number || null,
  });
  const addresses = Array.isArray(result.addresses) ? result.addresses : [];
  const practice = addresses.filter((a) => String(a.address_purpose || "").toUpperCase() === "LOCATION");
  const locs = [];
  const seen = new Set();
  const push = (l) => {
    const k = locKey(l);
    if ((l.address || l.city) && !seen.has(k)) {
      seen.add(k);
      locs.push(l);
    }
  };
  (practice.length ? practice : addresses).forEach((a) => push(toLoc(a)));
  (Array.isArray(result.practiceLocations) ? result.practiceLocations : []).forEach((a) => push(toLoc(a)));
  const specialties = [];
  const providerTypes = [];
  for (const t of Array.isArray(result.taxonomies) ? result.taxonomies : []) {
    if (t.desc) specialties.push(t.desc);
    if (t.code) providerTypes.push(t.code);
  }
  return {
    name,
    npi: result.number != null ? String(result.number) : null,
    specialty: specialties[0] || null,
    locations: locs,
    providerTypes,
    specialties,
    phone: (locs[0] && locs[0].phone) || null,
    source: "npi",
  };
}

/**
 * NPI search limited to the radius. Areas: the NPI_NEAREST_ZIPS nearest ZIPs (exact match)
 * and the 3-digit prefixes of every ZIP in the radius (wildcard, first page). Both sets grow
 * monotonically with the radius, so a larger search always repeats a smaller one's queries.
 */
async function searchNpi({zip, city, state = "OH", taxonomyCodes, radius, deadlineMs}) {
  const t0 = Date.now();
  const origin = searchOrigin(zip, city, state);
  const codes = [...new Set(taxonomyCodes || [])];
  const descriptions = [...new Set(codes.map((c) => NPI_TAXONOMY_DESCRIPTIONS[c]).filter(Boolean))];
  const skippedCodes = codes.filter((c) => !NPI_TAXONOMY_DESCRIPTIONS[c]);
  if (!descriptions.length) {
    return {providers: [], meta: {queries: 0, skippedCodes, ms: 0}};
  }
  let areas;
  if (origin) {
    const within = zipsWithinRadius(origin, radius);
    const exact = within.slice(0, NPI_NEAREST_ZIPS).map((z) => z.zip);
    const sz = zip5(zip);
    if (sz && !exact.includes(sz)) exact.unshift(sz);
    const prefixes = [...new Set(within.map((z) => z.zip.slice(0, 3)))].map((p) => `${p}*`);
    areas = [...exact, ...prefixes];
  } else {
    areas = [zip5(zip)].filter(Boolean);
  }
  const jobs = [];
  for (const description of descriptions) for (const postal of areas) jobs.push({description, postal});
  let timedOut = false;
  const pages = [];
  const work = mapLimit(jobs, NPI_CONCURRENCY * 2, async (job) => {
    const url = buildNpiAreaUrl(job);
    const r = await fetchNpiPage(url);
    pages.push({job, r});
  });
  if (deadlineMs) {
    let timer;
    await Promise.race([work, new Promise((r) => {
      timer = setTimeout(() => {
        timedOut = true;
        r();
      }, deadlineMs);
    })]);
    clearTimeout(timer);
  } else {
    await work;
  }
  const byNpi = new Map();
  let failed = 0;
  for (const {r} of pages) {
    if (!r.ok) {
      failed++;
      continue;
    }
    for (const raw of r.results) {
      const p = parseNpiRecord(raw);
      if (!p || !p.npi || byNpi.has(p.npi)) continue;
      byNpi.set(p.npi, p);
    }
  }
  const providers = [];
  for (const p of byNpi.values()) {
    const matched = codes.filter((c) => p.providerTypes.includes(c));
    if (!matched.length) continue;
    const placed = placeLocations(p.locations, origin, radius);
    if (!placed) continue;
    providers.push({
      ...p,
      locations: placed.locations,
      phone: (placed.locations[0] && placed.locations[0].phone) || p.phone,
      distanceMiles: round1(placed.distance),
      _dist: placed.distance,
      _key: `npi_${p.npi}`,
      _allLocations: p.locations,
      _matchedCodes: matched,
    });
  }
  const sel = selectPerGroup(providers, (p) => p._matchedCodes, codes, NPI_PER_TAXONOMY_CAP);
  return {
    providers: sel.list,
    meta: {
      queries: pages.length,
      failed,
      areas,
      descriptions,
      skippedCodes,
      timedOut,
      completeWithinMiles: sel.completeWithinMiles,
      perTaxonomy: sel.perGroup,
      ms: Date.now() - t0,
    },
  };
}

module.exports = {
  ALL_PLANS,
  RADIUS_RUNGS,
  MAXIMUS_CAP,
  MEDICAID_PER_TYPE_CAP,
  NPI_PER_TAXONOMY_CAP,
  planDisplayName,
  zip5,
  searchOrigin,
  placeLocations,
  radiusLimit,
  haversineMi,
  locatePoint,
  mapLimit,
  buildMaximusUrl,
  parseMaximusBundle,
  searchMedicaid,
  searchNpi,
  parseNpiRecord,
  sortByDistance,
};
