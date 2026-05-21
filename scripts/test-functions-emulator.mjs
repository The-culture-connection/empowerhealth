/**
 * Smoke-test all exported Cloud Functions against the local Functions emulator.
 * Run: npx firebase emulators:exec --only functions,firestore,pubsub "node scripts/test-functions-emulator.mjs"
 */

import http from "node:http";
import {createRequire} from "node:module";
import path from "node:path";
import {fileURLToPath} from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(__dirname, "../functions/package.json"));
const admin = require("firebase-admin");

const PROJECT_ID = "empower-health-watch";
const REGION = "us-central1";
const HOST = process.env.FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
const PUBSUB_HOST = process.env.PUBSUB_EMULATOR_HOST || "127.0.0.1:8085";

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
process.env.GCLOUD_PROJECT = PROJECT_ID;

if (!admin.apps.length) {
  admin.initializeApp({projectId: PROJECT_ID});
}
const db = admin.firestore();

/** @type {{ name: string; type: 'callable' | 'http' | 'firestore' | 'schedule' | 'storage'; collection?: string; doc?: object; payload?: object; scheduleTopic?: string }} */
const FUNCTIONS = [
  {name: "generateLearningContent", type: "callable"},
  {name: "summarizeVisitNotes", type: "callable"},
  {name: "generateBirthPlan", type: "callable"},
  {name: "generateAppointmentChecklist", type: "callable"},
  {name: "analyzeEmotionalContent", type: "callable"},
  {name: "generateRightsContent", type: "callable"},
  {name: "simplifyText", type: "callable", payload: {text: "test"}},
  {name: "uploadVisitSummaryFile", type: "callable"},
  {name: "analyzeVisitSummaryPDF", type: "callable"},
  {name: "summarizeAfterVisitPDF", type: "callable"},
  {name: "analyzeVisitSummaryText", type: "callable"},
  {name: "exportUserData", type: "callable"},
  {name: "deleteUserAccount", type: "callable"},
  {name: "deleteCommunityReply", type: "callable"},
  {name: "searchProviders", type: "callable", payload: {zip: "43215"}},
  {name: "adminRemoveProviderListing", type: "callable"},
  {name: "adminBackfillProviderIdentityClaims", type: "callable"},
  {name: "addProvider", type: "callable"},
  {name: "OhioMaximusSearch", type: "callable"},
  {name: "importBipocProviders", type: "callable"},
  {
    name: "onLearningModuleCreated",
    type: "firestore",
    collection: "learning_tasks",
    doc: {userId: "smoke-uid", moduleType: "article", content: "smoke", title: "smoke"},
  },
  {
    name: "onCommunityPostUpdated",
    type: "firestore",
    collection: "community_posts",
    doc: {userId: "smoke-uid", title: "smoke", body: "smoke", likeCount: 1},
    update: true,
  },
  {
    name: "onCommunityPostCreated",
    type: "firestore",
    collection: "community_posts",
    doc: {userId: "smoke-uid", title: "smoke", body: "smoke"},
  },
  {name: "scheduledWeeklyTodoReminders", type: "schedule"},
  {name: "scheduledTrimesterTransitionCheck", type: "schedule"},
  {name: "scheduledBirthHospitalBasicsReminder", type: "schedule"},
  {name: "processUploadedVisitSummary", type: "storage"},
  {name: "uploadBuildVersion", type: "callable"},
  {name: "logAnalyticsEvent", type: "callable", payload: {eventName: "emulator_smoke_test", feature: "system"}},
  {name: "getAnalyticsData", type: "callable"},
  {name: "generateReport", type: "callable"},
  {name: "lookupAuthUserByEmail", type: "callable", payload: {email: "smoke@test.local"}},
  {name: "getFeatureAnalytics", type: "callable"},
  {name: "updateFeature", type: "callable"},
  {name: "processFeatureChanges", type: "callable"},
  {name: "publishRelease", type: "http"},
  {name: "pollSystemHealth", type: "schedule"},
  {name: "runHealthCheckNow", type: "callable"},
  {name: "exportResearchDataset", type: "callable"},
  {name: "getResearchDashboardSummary", type: "callable"},
  {name: "createResearchParticipant", type: "callable"},
  {name: "deriveAgeGroup", type: "callable", payload: {age_years: 30}},
  {name: "submitBaselineResearchData", type: "callable"},
  {name: "validateResearchBaseline", type: "callable"},
  {name: "listRecruitmentPathways", type: "callable"},
  {name: "addRecruitmentPathway", type: "callable"},
  {name: "deleteRecruitmentPathway", type: "callable"},
  {name: "submitMicroMeasure", type: "callable"},
  {name: "validateMicroMeasure", type: "callable"},
  {name: "submitNeedsChecklist", type: "callable"},
  {name: "validateNeedsChecklist", type: "callable"},
  {name: "linkOutcomeToNeedsEvent", type: "callable"},
  {name: "submitNavigationOutcome", type: "callable"},
  {name: "validateNavigationOutcome", type: "callable"},
  {name: "getMilestoneTrackerSummary", type: "callable"},
  {name: "scheduleMilestonePrompt", type: "callable"},
  {name: "submitMilestoneCheckIn", type: "callable"},
  {name: "validateMilestoneCheckIn", type: "callable"},
  {name: "recordAvsUploadActivity", type: "callable"},
  {name: "recordHealthMadeSimpleAccess", type: "callable"},
  {name: "recordModuleCompletion", type: "callable"},
  {name: "recordProviderReviewActivity", type: "callable"},
  {name: "recomputeResearchSummaries", type: "callable"},
  {
    name: "onResearchActivityCreated",
    type: "firestore",
    collection: "research_app_activity",
    doc: {study_id: "99999", activity_type: "module_completion", module_id: "smoke"},
  },
  {
    name: "onResearchMicroMeasureCreated",
    type: "firestore",
    collection: "research_micro_measures",
    doc: {study_id: "99999", content_id: "smoke", content_type: "module", likert: 3},
  },
  {
    name: "onResearchNeedsChecklistCreated",
    type: "firestore",
    collection: "research_needs_checklists",
    doc: {study_id: "99999", need_transportation: 1},
  },
  {
    name: "onResearchOutcomeCreated",
    type: "firestore",
    collection: "research_navigation_outcomes",
    doc: {study_id: "99999", needs_event_id: "smoke-needs"},
  },
  {
    name: "onResearchMilestonePromptCreated",
    type: "firestore",
    collection: "research_milestone_prompts",
    doc: {study_id: "99999", milestone_type: 1},
  },
  {
    name: "onResearchParticipantCreated",
    type: "firestore",
    collection: "research_participants",
    doc: {study_id: "99999", recruitment_pathway: 1},
  },
  {
    name: "onAnalyticsEventCreated",
    type: "firestore",
    collection: "analytics_events",
    doc: {eventName: "smoke_test", feature: "system", source: "mobile"},
  },
  {name: "sendNotification", type: "callable"},
  {name: "getNotificationLogs", type: "callable"},
];

function wait(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function postJson(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = http.request(
      {
        hostname: u.hostname,
        port: u.port,
        path: u.pathname,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(data),
        },
      },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          let parsed = raw;
          try {
            parsed = JSON.parse(raw);
          } catch {
            /* keep string */
          }
          resolve({status: res.statusCode, body: parsed});
        });
      },
    );
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

async function waitForEmulator(maxAttempts = 90) {
  const base = `http://${HOST}`;
  for (let i = 0; i < maxAttempts; i++) {
    try {
      await postJson(`${base}/${PROJECT_ID}/${REGION}/deriveAgeGroup`, {data: {}});
      return;
    } catch {
      await wait(2000);
    }
  }
  throw new Error(`Functions emulator not reachable at ${HOST}`);
}

function callableOk(status) {
  return status != null && status !== 404;
}

async function testCallable(name, payload = {}) {
  const url = `http://${HOST}/${PROJECT_ID}/${REGION}/${name}`;
  const {status, body} = await postJson(url, {data: payload});
  const ok = callableOk(status);
  const hint = body?.error?.status || body?.error?.message || (body?.result != null ? "ok" : "");
  return {ok, status, hint: String(hint).slice(0, 120)};
}

async function testHttp(name) {
  const url = `http://${HOST}/${PROJECT_ID}/${REGION}/${name}`;
  const {status, body} = await postJson(url, {});
  const ok = status != null && status !== 404;
  return {ok, status, hint: typeof body === "object" ? JSON.stringify(body).slice(0, 120) : String(body).slice(0, 120)};
}

async function firestoreTrigger(fn) {
  const docId = `smoke_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  const ref = db.collection(fn.collection).doc(docId);
  if (fn.update) {
    await ref.set(fn.doc);
    await ref.update({likeCount: 2});
  } else {
    await ref.set(fn.doc);
  }
  await wait(2500);
  return {ok: true, status: 201, hint: `wrote ${fn.collection}/${docId}`};
}

function getJson(url) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    http.get({hostname: u.hostname, port: u.port, path: u.pathname}, (res) => {
      let raw = "";
      res.on("data", (c) => (raw += c));
      res.on("end", () => {
        try {
          resolve({status: res.statusCode, body: JSON.parse(raw)});
        } catch {
          resolve({status: res.statusCode, body: raw});
        }
      });
    }).on("error", reject);
  });
}

let pubsubTopicsCache;

async function listPubsubTopics() {
  if (pubsubTopicsCache) return pubsubTopicsCache;
  const {status, body} = await getJson(
    `http://${PUBSUB_HOST}/v1/projects/${PROJECT_ID}/topics`,
  );
  if (status !== 200 || !body?.topics) {
    pubsubTopicsCache = [];
    return pubsubTopicsCache;
  }
  pubsubTopicsCache = body.topics.map((t) => t.name.split("/").pop());
  return pubsubTopicsCache;
}

async function testSchedule(functionName) {
  const topics = await listPubsubTopics();
  const topic = topics.find((t) => t.includes(functionName));
  if (!topic) {
    return {
      ok: false,
      status: 404,
      hint: `no pubsub topic for ${functionName} (have: ${topics.join(", ") || "none"})`,
    };
  }
  const url = `http://${PUBSUB_HOST}/v1/projects/${PROJECT_ID}/topics/${topic}:publish`;
  const payload = Buffer.from(JSON.stringify({})).toString("base64");
  const {status, body} = await postJson(url, {messages: [{data: payload}]});
  if (status === 200 || status === 201) {
    await wait(3000);
    return {ok: true, status, hint: `pubsub ${topic}`};
  }
  return {ok: false, status, hint: JSON.stringify(body).slice(0, 120)};
}

async function main() {
  console.log(`Waiting for Functions emulator at ${HOST}...`);
  await waitForEmulator();
  console.log(`Testing ${FUNCTIONS.length} functions...\n`);

  const results = [];
  for (const fn of FUNCTIONS) {
    try {
      let result;
      if (fn.type === "callable") {
        result = await testCallable(fn.name, fn.payload ?? {});
      } else if (fn.type === "http") {
        result = await testHttp(fn.name);
      } else if (fn.type === "firestore") {
        result = await firestoreTrigger(fn);
      } else if (fn.type === "schedule") {
        result = await testSchedule(fn.name);
      } else if (fn.type === "storage") {
        result = {ok: true, status: 0, hint: "storage trigger (skipped — needs GCS event)"};
      } else {
        result = {ok: false, status: 0, hint: "unknown type"};
      }
      results.push({name: fn.name, type: fn.type, ...result});
      const mark = result.ok ? "PASS" : "FAIL";
      console.log(`${mark}  ${fn.name} (${fn.type}) — ${result.status} ${result.hint}`);
    } catch (e) {
      results.push({name: fn.name, type: fn.type, ok: false, status: 0, hint: e.message});
      console.log(`FAIL  ${fn.name} (${fn.type}) — ${e.message}`);
    }
  }

  const passed = results.filter((r) => r.ok).length;
  const failed = results.filter((r) => !r.ok);
  console.log(`\n--- Summary: ${passed}/${results.length} passed ---`);
  if (failed.length) {
    console.log("Failed:");
    for (const f of failed) {
      console.log(`  - ${f.name}: ${f.hint}`);
    }
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
