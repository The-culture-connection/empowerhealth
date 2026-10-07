#!/usr/bin/env node
/**
 * Live verification of provider search (standard + Expanded) against the
 * deployed Firebase callable functions `OhioMaximusSearch` and `searchProviders`
 * (project empower-health-watch, region us-central1).
 *
 * Calls the functions exactly the way the Flutter app does
 * (lib/providers/provider_quick_search_screen.dart,
 *  lib/providers/provider_search_entry_screen.dart,
 *  lib/providers/provider_search_results_screen.dart,
 *  lib/services/provider_repository.dart,
 *  lib/services/firebase_functions_service.dart)
 * and asserts radius / ZIP / plan / monotonicity / standard-vs-expanded rules.
 *
 * Usage:
 *   node scripts/search-check/check-search.mjs            # default matrix
 *   node scripts/search-check/check-search.mjs --quick    # small smoke subset
 * Options:
 *   --max-calls N     cap on callable-function calls (default 64, quick 12)
 *   --delay MS        pause between calls (default 1500)
 *   --tolerance MI    absolute slack added to the radius (default 2)
 *   --tolerance-pct P relative slack, percent of radius (default 10)
 *   --no-upstream     skip the raw Ohio Medicaid (Maximus) plan oracle fetches
 *   --zips a,b,c      override the ZIP list
 *   --verbose         print every offending provider
 *
 * No dependencies; Node >= 18 (global fetch).
 * Exit codes: 0 = no FAIL, 1 = at least one FAIL, 2 = fatal (auth / setup).
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Config mirrored from the app
// ---------------------------------------------------------------------------
const PROJECT = 'empower-health-watch';
const REGION = 'us-central1';
const FN_BASE = `https://${REGION}-${PROJECT}.cloudfunctions.net`;
// lib/services/firebase_service.dart (kIsWeb branch). Public web key.
const WEB_API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyAJOFoEdlGoWsq1JIzQs-xjIQSmupvbz2o';

// lib/constants/provider_types.dart ProviderTypes.mvpTypes — what both search
// screens send when no provider type is chosen (universal search).
const MVP_TYPES = ['01', '71', '11', '09', '20', '72', '37', '39'];

// lib/constants/provider_search_constants.dart
const PLAN_ALL = 'All plans';
const PLAN_NOT_LISTED = 'Not listed / not sure';
// Plan dropdown in both screens (_healthPlans)
const APP_PLANS = [PLAN_ALL, 'Buckeye', 'CareSource', 'Molina', 'UnitedHealthcare', 'Anthem', 'Aetna', PLAN_NOT_LISTED];

// functions/index.js normalizeHealthPlanName()
const BACKEND_PLAN_MAP = {
  UnitedHealthcare: 'United HealthCare',
  'United Healthcare': 'United HealthCare',
  UnitedHealthCare: 'United HealthCare',
  Buckeye: 'Buckeye',
  CareSource: 'CareSource',
  Molina: 'Molina',
  Anthem: 'Anthem',
  Aetna: 'Aetna',
  [PLAN_NOT_LISTED]: 'CareSource',
  [PLAN_ALL]: 'CareSource',
};
const backendPlan = (p) => BACKEND_PLAN_MAP[p.trim()] || p.trim();
const isPseudoPlan = (p) => p === PLAN_ALL || p === PLAN_NOT_LISTED;

// Search modes. OhioMaximusSearch payload is identical in both modes
// (repository always sends zip/radius/city/healthPlan/providerType/state).
const MODES = {
  // Quick ("standard") search: provider_quick_search_screen.dart _runSearch()
  standard: { includeNpi: true, acceptsPregnantWomen: true, acceptsNewborns: false, telehealth: false },
  // Expanded search opened directly: provider_search_entry_screen.dart defaults
  // (_includeNPI=false, _acceptsPregnant=true, _acceptsNewborns=false, _telehealth=false).
  // (When Expanded is opened FROM quick search, includeNpi is prefilled true and
  // the payload is identical to standard.)
  expanded: { includeNpi: false, acceptsPregnantWomen: true, acceptsNewborns: false, telehealth: false },
};

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
const argv = process.argv.slice(2);
const flag = (n) => argv.includes(n);
const opt = (n, d) => {
  const i = argv.indexOf(n);
  return i >= 0 && argv[i + 1] !== undefined ? argv[i + 1] : d;
};
const QUICK = flag('--quick');
const VERBOSE = flag('--verbose');
const UPSTREAM = !flag('--no-upstream');
const MAX_CALLS = Number(opt('--max-calls', QUICK ? 12 : 64));
const DELAY_MS = Number(opt('--delay', 1500));
const TOL_ABS = Number(opt('--tolerance', 2));
const TOL_PCT = Number(opt('--tolerance-pct', 10));
const CALL_TIMEOUT_MS = 120000;

const DEFAULT_ZIPS = ['43215', '44113', '45202', '43604', '43756']; // Columbus, Cleveland, Cincinnati, Toledo, McConnelsville (rural Morgan Co.)
const ZIPS = opt('--zips', null)?.split(',').map((s) => s.trim()).filter(Boolean) || (QUICK ? ['43215'] : DEFAULT_ZIPS);
const RADII = [3, 10, 25, 50];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const tolFor = (r) => TOL_ABS + (r * TOL_PCT) / 100;

// ---------------------------------------------------------------------------
// Auth (anonymous, like guest mode in the app)
// ---------------------------------------------------------------------------
let auth = null; // { idToken, obtainedAt }
async function signInAnonymously() {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${WEB_API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const body = await res.json().catch(() => ({}));
  if (!res.ok || !body.idToken) {
    const msg = body?.error?.message || `HTTP ${res.status}`;
    const hint = /OPERATION_NOT_ALLOWED|ADMIN_ONLY_OPERATION/.test(msg)
      ? ' -> Anonymous sign-in is DISABLED in Firebase Auth (enable it in Console > Authentication > Sign-in method).'
      : '';
    throw new Error(`Anonymous sign-up failed: ${msg}${hint}`);
  }
  auth = { idToken: body.idToken, uid: body.localId, obtainedAt: Date.now() };
  return auth;
}
async function token() {
  if (!auth || Date.now() - auth.obtainedAt > 50 * 60 * 1000) await signInAnonymously();
  return auth.idToken;
}

// ---------------------------------------------------------------------------
// Callable over HTTPS (same wire protocol as cloud_functions plugin)
// ---------------------------------------------------------------------------
let callsMade = 0;
let lastCallAt = 0;
class CapReached extends Error {}

async function callFn(name, data) {
  if (callsMade >= MAX_CALLS) throw new CapReached(`call cap ${MAX_CALLS} reached`);
  const wait = lastCallAt + DELAY_MS - Date.now();
  if (wait > 0) await sleep(wait);
  callsMade++;
  const t0 = Date.now();
  const doCall = async () => {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), CALL_TIMEOUT_MS);
    try {
      return await fetch(`${FN_BASE}/${name}`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${await token()}` },
        body: JSON.stringify({ data }),
        signal: ctrl.signal,
      });
    } finally {
      clearTimeout(timer);
    }
  };
  let res;
  try {
    res = await doCall();
    if (res.status === 401) {
      auth = null; // token rejected — get a fresh one once
      res = await doCall();
    }
  } catch (e) {
    lastCallAt = Date.now();
    return { ok: false, status: 0, ms: Date.now() - t0, error: e.name === 'AbortError' ? `timeout after ${CALL_TIMEOUT_MS}ms` : String(e) };
  }
  lastCallAt = Date.now();
  const text = await res.text();
  let body;
  try {
    body = JSON.parse(text);
  } catch {
    body = null;
  }
  const ms = Date.now() - t0;
  if (!res.ok || !body || body.error) {
    const err = body?.error ? `${body.error.status || ''} ${body.error.message || ''}`.trim() : text.slice(0, 300);
    return { ok: false, status: res.status, ms, error: err };
  }
  return { ok: true, status: res.status, ms, result: body.result };
}

// ---------------------------------------------------------------------------
// ZIP geocoding (zippopotam.us, cached on disk)
// ---------------------------------------------------------------------------
const CACHE_DIR = path.join(HERE, '.cache');
const ZIP_CACHE_FILE = path.join(CACHE_DIR, 'zips.json');
let zipCache = {};
try {
  zipCache = JSON.parse(fs.readFileSync(ZIP_CACHE_FILE, 'utf8'));
} catch {}
function saveZipCache() {
  fs.mkdirSync(CACHE_DIR, { recursive: true });
  fs.writeFileSync(ZIP_CACHE_FILE, JSON.stringify(zipCache));
}
async function geocodeOne(zip) {
  if (zip in zipCache) return zipCache[zip];
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const r = await fetch(`https://api.zippopotam.us/us/${zip}`, { signal: AbortSignal.timeout(10000) });
      if (r.status === 404) {
        zipCache[zip] = null;
        return null;
      }
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      const j = await r.json();
      const p = j.places?.[0];
      zipCache[zip] = p ? { lat: +p.latitude, lon: +p.longitude, city: p['place name'], state: p['state abbreviation'] } : null;
      return zipCache[zip];
    } catch {
      await sleep(500 * (attempt + 1));
    }
  }
  return undefined; // transient failure, not cached
}
async function geocodeMany(zips) {
  const todo = [...new Set(zips)].filter((z) => /^\d{5}$/.test(z) && !(z in zipCache));
  let i = 0;
  const worker = async () => {
    while (i < todo.length) {
      const z = todo[i++];
      await geocodeOne(z);
    }
  };
  await Promise.all([worker(), worker(), worker(), worker()]);
  if (todo.length) saveZipCache();
}
// Street-address geocoding (US Census geocoder, free/no key) — used ONLY to
// re-check providers that fail the ZIP-centroid radius test, so a big ZIP
// whose centroid is far from the actual office doesn't cause a false FAIL.
const ADDR_CACHE_FILE = path.join(CACHE_DIR, 'addresses.json');
let addrCache = {};
try {
  addrCache = JSON.parse(fs.readFileSync(ADDR_CACHE_FILE, 'utf8'));
} catch {}
let addrLookups = 0;
const MAX_ADDR_LOOKUPS = 80;
async function geocodeAddress(loc) {
  const line = String(loc.address || '').replace(/\s+/g, ' ').trim();
  if (!line || /^P\.?\s*O\.?\s*BOX/i.test(line)) return null;
  const one = `${line}, ${loc.city || ''}, ${loc.state || ''} ${zip5(loc.zip)}`;
  if (one in addrCache) return addrCache[one];
  if (addrLookups >= MAX_ADDR_LOOKUPS) return undefined;
  addrLookups++;
  try {
    const u = `https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?benchmark=Public_AR_Current&format=json&address=${encodeURIComponent(one)}`;
    const r = await fetch(u, { signal: AbortSignal.timeout(20000) });
    if (!r.ok) return undefined;
    const j = await r.json();
    const m = j.result?.addressMatches?.[0];
    addrCache[one] = m ? { lat: m.coordinates.y, lon: m.coordinates.x, matched: m.matchedAddress } : null;
    fs.mkdirSync(CACHE_DIR, { recursive: true });
    fs.writeFileSync(ADDR_CACHE_FILE, JSON.stringify(addrCache));
    return addrCache[one];
  } catch {
    return undefined;
  }
}
/** Re-check a ZIP-centroid offender with street-level geocodes. Returns min distance or null. */
async function addressMinDist(a, origin) {
  let best = null;
  for (const loc of a.locs) {
    const g = await geocodeAddress(loc);
    if (g) {
      const d = haversineMi(origin, g);
      if (best == null || d < best) best = d;
    }
  }
  return best;
}

function haversineMi(a, b) {
  const R = 3958.8;
  const toRad = (d) => (d * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLon = toRad(b.lon - a.lon);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}
const zip5 = (z) => String(z || '').trim().slice(0, 5);

// ---------------------------------------------------------------------------
// Provider helpers
// ---------------------------------------------------------------------------
// provider_repository.dart _getProviderKey (used to merge OMX + searchProviders)
const appKey = (p) => {
  const l = p.locations?.[0];
  const loc = l ? `${l.city ?? ''}_${l.zip ?? ''}` : 'no_location';
  return `${String(p.name || '').toLowerCase().trim()}_${loc}`;
};
const PLAN_FIELDS = ['healthPlan', 'healthPlans', 'plans', 'plan', 'networks', 'network', 'insurance', 'acceptedInsurance', 'acceptedPlans'];

function annotate(providers, origin) {
  return providers.map((p) => {
    const zips = (p.locations || []).map((l) => zip5(l.zip)).filter(Boolean);
    const dists = zips.map((z) => (zipCache[z] && origin ? haversineMi(origin, zipCache[z]) : null));
    const known = dists.filter((d) => d != null);
    return {
      name: p.name,
      npi: p.npi || null,
      source: p.source || '?',
      key: appKey(p),
      locs: p.locations || [],
      zips,
      minDist: known.length ? Math.min(...known) : null,
      firstDist: dists[0] ?? null,
      maxDist: known.length ? Math.max(...known) : null,
      planInfo: PLAN_FIELDS.filter((f) => p[f] != null).map((f) => ({ [f]: p[f] })),
    };
  });
}
const fmtMi = (d) => (d == null ? '?' : d.toFixed(1));
const describe = (a) =>
  `${a.name} [${a.source}${a.npi ? ' NPI ' + a.npi : ''}] ` +
  `${[...new Set(a.locs.map((l) => `${String(l.address || '').replace(/\s+/g, ' ').trim()}, ${l.city} ${l.state} ${zip5(l.zip)}`))].join(' / ') || 'no address'}` +
  ` | nearest ZIP-centroid ${fmtMi(a.minDist)}mi${a.addrDist !== undefined ? `, street-level ${fmtMi(a.addrDist)}mi` : ''}`;

// ---------------------------------------------------------------------------
// Results bookkeeping
// ---------------------------------------------------------------------------
const checks = []; // { caseId, check, status, detail, offenders? }
function record(caseId, check, status, detail, offenders) {
  checks.push({ caseId, check, status, detail, offenders: offenders?.slice(0, 25) });
  const icon = { PASS: 'ok  ', FAIL: 'FAIL', WARN: 'warn', SKIP: 'skip', INFO: 'info' }[status] || status;
  console.log(`    [${icon}] ${check}: ${detail}`);
  if (offenders?.length && (VERBOSE || status === 'FAIL')) {
    for (const o of offenders.slice(0, VERBOSE ? 50 : 5)) console.log(`           - ${o}`);
    if (!VERBOSE && offenders.length > 5) console.log(`           ... ${offenders.length - 5} more (see JSON)`);
  }
}

// ---------------------------------------------------------------------------
// Matrix
// ---------------------------------------------------------------------------
function buildMatrix() {
  const cases = [];
  const add = (zip, radius, plan, mode, tags, types = MVP_TYPES) => cases.push({ zip, radius, plan, mode, tags, types });
  // A single provider type the user can pick (Nurse Midwife Individual = "71"); used to
  // check that the universal (all-types) search doesn't crowd out maternity providers.
  const MIDWIFE = ['71'];
  if (QUICK) {
    const z = ZIPS[0];
    add(z, 3, PLAN_ALL, 'standard', ['radius']);
    add(z, 10, PLAN_ALL, 'standard', ['radius', 'plan']);
    add(z, 10, 'CareSource', 'standard', ['plan']);
    add(z, 10, 'Molina', 'standard', ['plan']);
    add(z, 10, PLAN_ALL, 'expanded', ['mode']);
    add(z, 10, PLAN_ALL, 'standard', ['types'], MIDWIFE);
    return cases;
  }
  // 1) Radius/ZIP sweep (highest priority), "All plans" (the default plan)
  for (const z of ZIPS) for (const r of RADII) add(z, r, PLAN_ALL, 'standard', z === ZIPS[0] ? ['radius', 'plan'] : ['radius']);
  // 2) Expanded vs standard at 10 mi (OhioMaximusSearch reused from #1)
  for (const z of ZIPS) add(z, 10, PLAN_ALL, 'expanded', ['mode']);
  // 3) Single-type search (midwives) vs universal search, first ZIP
  add(ZIPS[0], 10, PLAN_ALL, 'standard', ['types'], MIDWIFE);
  // 4) Plan sweep: every plan the app offers, first ZIP, 10 mi
  for (const p of APP_PLANS) if (p !== PLAN_ALL) add(ZIPS[0], 10, p, 'standard', ['plan']);
  return cases;
}

// ---------------------------------------------------------------------------
// Upstream oracle for plan: fetch the raw Ohio Medicaid FHIR bundle that
// OhioMaximusSearch built (it returns the URL) and read PractitionerRole.organization
// ("HealthPlan/<name>"), which the function's parser drops.
// ---------------------------------------------------------------------------
const upstreamCache = new Map();
async function upstreamPlans(url) {
  if (upstreamCache.has(url)) return upstreamCache.get(url);
  let out;
  try {
    const r = await fetch(url, { signal: AbortSignal.timeout(60000) });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    const b = await r.json();
    const entries = b.entry || [];
    const counts = {};
    const roleTypes = {};
    const typeCounts = {};
    for (const e of entries) {
      const res = e.resource || {};
      counts[res.resourceType] = (counts[res.resourceType] || 0) + 1;
      if (res.resourceType === 'PractitionerRole') {
        const ref = res.organization?.reference || '(none)';
        roleTypes[ref] = (roleTypes[ref] || 0) + 1;
        const t = res.code?.[0]?.coding?.[0]?.code || '?';
        typeCounts[t] = (typeCounts[t] || 0) + 1;
      }
    }
    out = { ok: true, counts, planRefs: roleTypes, typeCounts, hasNext: !!(b.link || []).find((l) => l.relation === 'next') };
  } catch (e) {
    out = { ok: false, error: String(e) };
  }
  upstreamCache.set(url, out);
  await sleep(500);
  return out;
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------
async function main() {
  const startedAt = new Date();
  console.log(`Provider search live check — ${startedAt.toISOString()}`);
  console.log(`Functions: ${FN_BASE}/{OhioMaximusSearch,searchProviders}`);
  console.log(`Mode: ${QUICK ? 'QUICK' : 'DEFAULT'} | max calls ${MAX_CALLS} | delay ${DELAY_MS}ms | radius tolerance +${TOL_ABS}mi +${TOL_PCT}% | upstream oracle ${UPSTREAM ? 'on' : 'off'}`);

  try {
    await signInAnonymously();
    console.log(`Auth: anonymous sign-up OK (uid ${auth.uid})`);
  } catch (e) {
    console.error(`FATAL: ${e.message}`);
    process.exit(2);
  }

  // City for each ZIP the same way the quick search screen derives it (_cityFromZip)
  await geocodeMany(ZIPS);
  const origins = {};
  for (const z of ZIPS) {
    if (!zipCache[z]) {
      console.error(`FATAL: could not geocode search ZIP ${z}`);
      process.exit(2);
    }
    origins[z] = zipCache[z];
  }

  const cases = buildMatrix();
  console.log(`Matrix: ${cases.length} searches over ZIPs ${ZIPS.join(', ')}\n`);

  const omxCache = new Map(); // OhioMaximusSearch payload is mode-independent
  const runs = []; // per case results
  let capped = false;

  for (const c of cases) {
    const origin = origins[c.zip];
    const city = origin.city;
    const id = `${c.zip} ${city} r=${c.radius} plan="${c.plan}" ${c.mode}${c.types === MVP_TYPES ? '' : ' types=' + c.types.join(',')}`;
    console.log(`\n=== ${id}`);
    const run = { ...c, id, city, omx: null, sp: null };
    runs.push(run);

    // --- OhioMaximusSearch (exact app payload: firebase_functions_service.dart ohioMaximusSearch)
    const omxPayload = { zip: c.zip, radius: String(c.radius), city, healthPlan: c.plan, providerType: c.types.length === 1 ? c.types[0] : c.types, state: 'OH' };
    const omxKey = JSON.stringify(omxPayload);
    // --- searchProviders (exact app payload: firebase_functions_service.dart searchProviders)
    const spPayload = { zip: c.zip, city, healthPlan: c.plan, providerTypeIds: c.types, radius: c.radius, ...MODES[c.mode] };

    try {
      if (omxCache.has(omxKey)) {
        run.omx = { ...omxCache.get(omxKey), reused: true };
        console.log(`  OhioMaximusSearch: reused identical call (${run.omx.ok ? run.omx.result.count + ' providers' : 'error'})`);
      } else {
        run.omx = await callFn('OhioMaximusSearch', omxPayload);
        omxCache.set(omxKey, run.omx);
        console.log(`  OhioMaximusSearch: HTTP ${run.omx.status} in ${run.omx.ms}ms -> ${run.omx.ok ? run.omx.result.count + ' providers' : run.omx.error}`);
      }
      run.sp = await callFn('searchProviders', spPayload);
      console.log(`  searchProviders:   HTTP ${run.sp.status} in ${run.sp.ms}ms -> ${run.sp.ok ? run.sp.result.count + ' providers' : run.sp.error}`);
    } catch (e) {
      if (e instanceof CapReached) {
        console.log(`  SKIPPED: ${e.message}`);
        run.skipped = true;
        capped = true;
        record(id, 'calls', 'SKIP', `not run — ${e.message} (raise with --max-calls)`);
        continue;
      }
      throw e;
    }
    run.omxPayload = omxPayload;
    run.spPayload = spPayload;

    // Call health
    for (const [lbl, r] of [['OhioMaximusSearch', run.omx], ['searchProviders', run.sp]]) {
      if (!r.ok) record(id, `call ${lbl}`, 'FAIL', `HTTP ${r.status}: ${r.error}`);
    }
    const omxProviders = run.omx.ok ? run.omx.result.providers || [] : [];
    const spProviders = run.sp.ok ? run.sp.result.providers || [] : [];

    // Geocode every provider ZIP
    await geocodeMany([...omxProviders, ...spProviders].flatMap((p) => (p.locations || []).map((l) => zip5(l.zip))));
    run.omxA = annotate(omxProviders, origin);
    run.spA = annotate(spProviders, origin);

    // App view: OMX first, then searchProviders, deduped by _getProviderKey
    const seen = new Set();
    run.merged = [];
    for (const a of [...run.omxA, ...run.spA]) if (!seen.has(a.key)) (seen.add(a.key), run.merged.push(a));
    const bySource = {};
    for (const a of run.spA) bySource[a.source] = (bySource[a.source] || 0) + 1;
    record(id, 'counts', 'INFO', `OMX=${run.omxA.length} SP=${run.spA.length} ${JSON.stringify(bySource)} app-merged=${run.merged.length}`);

    // (a) RADIUS — every provider has at least one location within radius (+tolerance)
    const limit = c.radius + tolFor(c.radius);
    for (const [lbl, list] of [['OMX', run.omxA], ['SP', run.spA]]) {
      if (!list.length) continue;
      const located = list.filter((a) => a.minDist != null);
      const unlocated = list.length - located.length;
      const centroidOut = located.filter((a) => a.minDist > limit);
      // Street-level re-check of ZIP-centroid offenders (dedupe by key so duplicates aren't looked up twice)
      const outside = [];
      for (const a of centroidOut) {
        a.addrDist = await addressMinDist(a, origin);
        if (a.addrDist == null || a.addrDist > c.radius + 1) outside.push(a);
      }
      const rescued = centroidOut.length - outside.length;
      const detail = `${located.length - outside.length}/${located.length} rows within ${c.radius}mi` +
        ` (ZIP-centroid +${fmtMi(tolFor(c.radius))}mi slack${rescued ? `, ${rescued} confirmed by street address` : ''})` +
        (unlocated ? `; unlocatable=${unlocated}` : '');
      const srcs = [...new Set(outside.map((o) => o.source))].join(',');
      const uniq = [...new Map(outside.map((o) => [o.key, o])).values()];
      record(id, `radius ${lbl}`, outside.length ? 'FAIL' : 'PASS',
        outside.length ? `${uniq.length} provider(s) OUTSIDE radius (sources: ${srcs}); ${detail}` : detail,
        uniq.sort((x, y) => y.minDist - x.minDist).map(describe));
      // The results card shows locations.first (provider_search_results_screen.dart ~L1444);
      // flag rows whose displayed address is outside the radius even though another address is inside.
      const firstOut = located.filter((a) => a.minDist <= limit && a.firstDist != null && a.firstDist > limit);
      const firstUniq = [...new Map(firstOut.map((o) => [o.key, o])).values()];
      if (firstUniq.length) {
        record(id, `first-address ${lbl}`, 'WARN',
          `${firstUniq.length} provider(s) match via a secondary address but the card shows an address outside ${c.radius}mi (locations.first)`,
          firstUniq.map(describe));
      }
    }
    // Upstream truncation: Ohio Medicaid API returns max 100 providers per query, no paging
    const omxUnique = new Set(run.omxA.map((a) => a.key)).size;
    if (run.omx.ok) {
      record(id, 'omx rows', 'INFO', `${run.omxA.length} rows -> ${omxUnique} unique providers (duplicate Practitioner rows per address)`);
      if (omxUnique >= 100) record(id, 'upstream-cap', 'WARN', `${omxUnique} unique Medicaid providers = Ohio Medicaid API hard cap of 100; more providers exist in this radius but are silently dropped (no next-page link)`);
    }

    // (d) ZIP — results are centred on the searched ZIP
    if (run.merged.length) {
      const ds = run.merged.map((a) => a.minDist).filter((d) => d != null).sort((x, y) => x - y);
      const nearest = ds[0];
      const median = ds[Math.floor(ds.length / 2)];
      const ok = nearest != null && nearest <= limit;
      record(id, 'zip-centred', ok ? 'PASS' : 'FAIL', `nearest=${fmtMi(nearest)}mi median=${fmtMi(median)}mi (limit ${fmtMi(limit)}mi)`);
    } else {
      record(id, 'zip-centred', c.radius >= 10 && !c.zip.startsWith('437') ? 'WARN' : 'INFO', 'no results returned');
    }

    // NPI rows must only appear when includeNpi=true, and should be in the searched ZIP
    const npiRows = run.spA.filter((a) => a.source === 'npi');
    if (!MODES[c.mode].includeNpi && npiRows.length) {
      record(id, 'npi-gating', 'FAIL', `${npiRows.length} NPI rows returned with includeNpi=false`, npiRows.map(describe));
    } else if (npiRows.length) {
      const notInZip = npiRows.filter((a) => !a.zips.includes(c.zip));
      record(id, 'npi-zip', notInZip.length ? 'WARN' : 'PASS',
        `${npiRows.length - notInZip.length}/${npiRows.length} NPI rows show an address in ${c.zip} (NPI query is exact postal_code+city, ignores radius; ` +
        `rows matched via NPI practiceLocations show only primary/mailing addresses)`,
        notInZip.map(describe));
    }

    // (b) PLAN
    const planEcho = run.omx.ok ? run.omx.result.parameters?.healthPlan : undefined;
    const expectedPlan = backendPlan(c.plan);
    if (planEcho !== undefined) {
      if (isPseudoPlan(c.plan)) {
        record(id, 'plan-param', 'WARN', `"${c.plan}" sent upstream as healthplan="${planEcho}" — searches ONE plan's network, not all plans (normalizeHealthPlanName)`);
      } else {
        record(id, 'plan-param', planEcho === expectedPlan ? 'PASS' : 'FAIL', `"${c.plan}" -> upstream healthplan="${planEcho}" (expected "${expectedPlan}")`);
      }
    }
    const planExposed = [...run.omxA, ...run.spA].some((a) => a.planInfo.length);
    if (!planExposed) {
      record(id, 'plan-in-response', 'SKIP', 'responses carry no plan/network field per provider — cannot assert plan membership from the function output');
    }
    if (UPSTREAM && c.tags.includes('plan') && run.omx.ok && run.omx.result.url) {
      const up = await upstreamPlans(run.omx.result.url);
      run.upstream = up;
      if (!up.ok) {
        record(id, 'plan-upstream', 'WARN', `could not fetch Maximus URL: ${up.error}`);
      } else {
        const refs = Object.keys(up.planRefs);
        const want = `HealthPlan/${expectedPlan}`;
        // Maximus spells plans inconsistently (e.g. "United Healthcare" vs the "United HealthCare" we send), so compare case/space-insensitively
        const norm = (x) => x.toLowerCase().replace(/\s+/g, '');
        const roles = Object.values(up.planRefs).reduce((s, n) => s + n, 0);
        const bad = refs.filter((r) => norm(r) !== norm(want));
        const good = roles - bad.reduce((n, r) => n + up.planRefs[r], 0);
        const detail = `Maximus PractitionerRole.organization: ${JSON.stringify(up.planRefs)}; resources ${JSON.stringify(up.counts)}`;
        record(id, 'upstream types', 'INFO', `provider types among the returned roles: ${JSON.stringify(up.typeCounts)} (searched ${c.types.join(',')})`);
        if (!roles) record(id, 'plan-upstream', 'INFO', `no PractitionerRole rows to check; ${detail}`);
        else if (isPseudoPlan(c.plan)) record(id, 'plan-upstream', 'WARN', `"${c.plan}" returns only ${refs.join(',')} roles; ${detail}`);
        else record(id, 'plan-upstream', bad.length ? 'FAIL' : 'PASS', `${good}/${roles} roles in ${want}; ${detail}`);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Cross-case checks
  // -------------------------------------------------------------------------
  console.log('\n=== Cross-case checks');
  const done = runs.filter((r) => !r.skipped && r.omx?.ok && r.sp?.ok);

  // (c) MONOTONICITY: larger radius >= smaller radius (same ZIP/plan/mode)
  const groups = {};
  for (const r of done) if (r.types === MVP_TYPES) (groups[`${r.zip}|${r.plan}|${r.mode}`] ||= []).push(r);
  for (const [g, rs] of Object.entries(groups)) {
    if (rs.length < 2) continue;
    rs.sort((a, b) => a.radius - b.radius);
    const [zip, plan, mode] = g.split('|');
    const gid = `${zip} plan="${plan}" ${mode}`;
    for (const [lbl, pick] of [
      ['OMX', (r) => r.omxA],
      ['SP medicaid', (r) => r.spA.filter((a) => a.source === 'medicaid')],
      ['app-merged', (r) => r.merged],
    ]) {
      const series = rs.map((r) => `${r.radius}mi:${new Set(pick(r).map((a) => a.key)).size}`).join(' ');
      const drops = [];
      const missing = [];
      for (let i = 1; i < rs.length; i++) {
        const small = new Set(pick(rs[i - 1]).map((a) => a.key));
        const big = new Set(pick(rs[i]).map((a) => a.key));
        if (big.size < small.size) drops.push(`${rs[i - 1].radius}->${rs[i].radius}mi: ${small.size} -> ${big.size}`);
        const lost = [...small].filter((k) => !big.has(k));
        if (lost.length) missing.push(`${rs[i - 1].radius}->${rs[i].radius}mi lost ${lost.length} (e.g. ${lost.slice(0, 3).join(' | ')})`);
      }
      record(gid, `monotonic ${lbl}`, drops.length ? 'FAIL' : 'PASS', `${series}${drops.length ? ' DECREASE: ' + drops.join('; ') : ''}`, drops);
      // A provider inside the small radius is also inside the big one, so it must still be returned.
      record(gid, `superset ${lbl}`, missing.length ? 'FAIL' : 'PASS',
        missing.length ? `larger radius DROPS providers returned by the smaller radius: ${missing.join('; ')}` : 'every provider from a smaller radius is still returned at the larger radius',
        missing);
    }
  }

  // Plan differentiation (same ZIP/radius/mode across plans) — OMX only (pure Medicaid query)
  const pg = {};
  for (const r of done) if (r.types === MVP_TYPES) (pg[`${r.zip}|${r.radius}|${r.mode}`] ||= []).push(r);
  for (const [g, rs] of Object.entries(pg)) {
    if (rs.length < 2) continue;
    const [zip, radius, mode] = g.split('|');
    const gid = `${zip} r=${radius} ${mode}`;
    const sets = Object.fromEntries(rs.map((r) => [r.plan, new Set(r.omxA.map((a) => a.key))]));
    const same = (a, b) => sets[a] && sets[b] && sets[a].size === sets[b].size && [...sets[a]].every((k) => sets[b].has(k));
    record(gid, 'plan counts', 'INFO', rs.map((r) => `${r.plan}=${r.omxA.length}`).join(', '));
    if (sets[PLAN_ALL] && sets.CareSource) {
      record(gid, 'all-plans', same(PLAN_ALL, 'CareSource') ? 'WARN' : 'INFO',
        same(PLAN_ALL, 'CareSource') ? `"All plans" returns exactly the CareSource result set (${sets.CareSource.size}) — other plans' providers are not included`
          : `"All plans" (${sets[PLAN_ALL].size}) differs from CareSource (${sets.CareSource.size})`);
      const union = new Set(rs.filter((r) => !isPseudoPlan(r.plan)).flatMap((r) => [...sets[r.plan]]));
      const notInAll = [...union].filter((k) => !sets[PLAN_ALL].has(k));
      if (union.size) record(gid, 'all-plans coverage', notInAll.length ? 'WARN' : 'PASS',
        `${union.size - notInAll.length}/${union.size} providers from the individual plan searches also appear under "All plans"`, notInAll.slice(0, 10));
    }
    if (sets[PLAN_NOT_LISTED] && sets.CareSource) {
      record(gid, 'not-listed', same(PLAN_NOT_LISTED, 'CareSource') ? 'WARN' : 'INFO',
        same(PLAN_NOT_LISTED, 'CareSource') ? '"Not listed / not sure" is identical to CareSource' : '"Not listed / not sure" differs from CareSource');
    }
    const specific = rs.filter((r) => !isPseudoPlan(r.plan) && sets[r.plan].size);
    if (specific.length >= 2) {
      const allSame = specific.every((r) => same(specific[0].plan, r.plan));
      record(gid, 'plan-filter-effective', allSame ? 'FAIL' : 'PASS',
        allSame ? 'every specific plan returned the identical provider set — plan filter appears to be ignored' : 'different plans return different provider sets');
    }
  }

  // (e) Expanded vs standard (same ZIP/radius/plan)
  // Provider-type crowding: providers returned by a single-type search must also be
  // in the universal (all mvpTypes) search for the same ZIP/radius/plan.
  for (const t of done.filter((r) => r.types !== MVP_TYPES)) {
    const u = done.find((r) => r.types === MVP_TYPES && r.mode === t.mode && r.zip === t.zip && r.radius === t.radius && r.plan === t.plan);
    if (!u) continue;
    const gid = `${t.zip} r=${t.radius} plan="${t.plan}" types=${t.types.join(',')}`;
    const uKeys = new Set(u.merged.map((a) => a.key));
    const tMed = [...new Map(t.omxA.map((a) => [a.key, a])).values()];
    const missing = tMed.filter((a) => !uKeys.has(a.key));
    record(gid, 'type-crowding', missing.length ? 'FAIL' : 'PASS',
      missing.length ? `${missing.length}/${tMed.length} providers returned by the type-${t.types.join(',')} search are MISSING from the universal search (same ZIP/radius/plan) — crowded out by the 100-result cap`
        : `all ${tMed.length} type-${t.types.join(',')} providers also appear in the universal search`,
      missing.map(describe));
  }

  for (const e of done.filter((r) => r.mode === 'expanded')) {
    const s = done.find((r) => r.mode === 'standard' && r.types === MVP_TYPES && r.zip === e.zip && r.radius === e.radius && r.plan === e.plan);
    const gid = `${e.zip} r=${e.radius} plan="${e.plan}"`;
    if (!s) {
      record(gid, 'expanded-vs-standard', 'SKIP', 'no matching standard run');
      continue;
    }
    const src = (r) => r.spA.reduce((m, a) => ((m[a.source] = (m[a.source] || 0) + 1), m), {});
    const sMed = new Set(s.spA.filter((a) => a.source !== 'npi').map((a) => a.key));
    const eMed = new Set(e.spA.filter((a) => a.source !== 'npi').map((a) => a.key));
    const onlyS = [...sMed].filter((k) => !eMed.has(k));
    const onlyE = [...eMed].filter((k) => !sMed.has(k));
    record(gid, 'expanded-vs-standard', 'INFO',
      `standard SP ${JSON.stringify(src(s))} app=${s.merged.length} | expanded SP ${JSON.stringify(src(e))} app=${e.merged.length} | non-NPI only-in-standard=${onlyS.length} only-in-expanded=${onlyE.length}`);
    record(gid, 'expanded non-NPI parity', onlyS.length || onlyE.length ? 'WARN' : 'PASS',
      onlyS.length || onlyE.length ? 'Medicaid/directory rows differ although only includeNpi changed' : 'Medicaid/directory rows identical; difference is only the NPI rows (includeNpi)',
      [...onlyS.map((k) => 'standard-only: ' + k), ...onlyE.map((k) => 'expanded-only: ' + k)]);
  }

  // -------------------------------------------------------------------------
  // Report
  // -------------------------------------------------------------------------
  const tally = checks.reduce((m, c) => ((m[c.status] = (m[c.status] || 0) + 1), m), {});
  const W = [44, 26, 5];
  const pad = (s, n) => (String(s).length > n ? String(s).slice(0, n - 1) + '…' : String(s).padEnd(n));
  console.log('\n\n' + '='.repeat(130));
  console.log(`${pad('CASE', W[0])} ${pad('CHECK', W[1])} ${pad('RESULT', W[2])}  DETAIL`);
  console.log('-'.repeat(130));
  for (const c of checks.filter((c) => c.status !== 'INFO')) {
    console.log(`${pad(c.caseId, W[0])} ${pad(c.check, W[1])} ${pad(c.status, W[2])}  ${pad(c.detail, 130 - W[0] - W[1] - W[2] - 5)}`);
  }
  console.log('='.repeat(130));
  console.log(`SUMMARY: PASS ${tally.PASS || 0} | FAIL ${tally.FAIL || 0} | WARN ${tally.WARN || 0} | SKIP ${tally.SKIP || 0}   (callable calls used: ${callsMade}/${MAX_CALLS}${capped ? ', cap reached — some cases skipped' : ''})`);
  const fails = checks.filter((c) => c.status === 'FAIL');
  if (fails.length) {
    console.log('\nFAILURES:');
    for (const f of fails) {
      console.log(`  * ${f.caseId} :: ${f.check} :: ${f.detail}`);
      for (const o of (f.offenders || []).slice(0, 3)) console.log(`      e.g. ${o}`);
    }
  }
  const warns = checks.filter((c) => c.status === 'WARN');
  if (warns.length) {
    console.log('\nWARNINGS (known backend behaviors / data caveats):');
    const uniq = new Map();
    for (const w of warns) {
      const k = `${w.check}`;
      if (!uniq.has(k)) uniq.set(k, []);
      uniq.get(k).push(w);
    }
    for (const [k, ws] of uniq) console.log(`  * ${k} (x${ws.length}): ${ws[0].detail.slice(0, 220)}`);
  }

  // Save JSON
  const outDir = path.join(HERE, 'results');
  fs.mkdirSync(outDir, { recursive: true });
  const stamp = startedAt.toISOString().replace(/[:.]/g, '-');
  const outFile = path.join(outDir, `${stamp}${QUICK ? '-quick' : ''}.json`);
  const slim = (list) => (list || []).map(({ name, npi, source, zips, minDist, firstDist, addrDist }) => ({ name, npi, source, zips: [...new Set(zips)], addrDist: addrDist == null ? addrDist : +addrDist.toFixed(2), minDist: minDist == null ? null : +minDist.toFixed(2), firstDist: firstDist == null ? null : +firstDist.toFixed(2) }));
  fs.writeFileSync(outFile, JSON.stringify({
    startedAt: startedAt.toISOString(),
    finishedAt: new Date().toISOString(),
    options: { QUICK, MAX_CALLS, DELAY_MS, TOL_ABS, TOL_PCT, UPSTREAM, ZIPS },
    callsMade,
    summary: tally,
    checks,
    runs: runs.map((r) => ({
      id: r.id, zip: r.zip, city: r.city, radius: r.radius, plan: r.plan, mode: r.mode, skipped: !!r.skipped,
      omxPayload: r.omxPayload, spPayload: r.spPayload,
      omx: r.omx && { ok: r.omx.ok, status: r.omx.status, ms: r.omx.ms, error: r.omx.error, reused: !!r.omx.reused, url: r.omx.result?.url, parameters: r.omx.result?.parameters, count: r.omx.result?.count },
      sp: r.sp && { ok: r.sp.ok, status: r.sp.status, ms: r.sp.ms, error: r.sp.error, count: r.sp.result?.count },
      upstream: r.upstream,
      omxProviders: slim(r.omxA),
      spProviders: slim(r.spA),
    })),
  }, null, 1));
  console.log(`\nJSON saved: ${path.relative(process.cwd(), outFile)}`);
  process.exit(fails.length ? 1 : 0);
}

main().catch((e) => {
  console.error('FATAL:', e);
  process.exit(2);
});
