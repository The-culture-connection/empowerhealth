/**
 * Enters pregnancy-loss support mode for the signed-in user.
 * Uses Admin SDK merge writes so missing user docs do not fail like client .update().
 */
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const SUPPORT_STAGE_PREGNANCY_LOSS = "pregnancy_loss";
const MAX_OPTIONS = 12;
const MAX_OPTION_ID_LEN = 64;
const MAX_SOMETHING_ELSE_LEN = 500;

/**
 * @param {unknown} raw
 * @return {string[]}
 */
function sanitizeSelectedOptions(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const item of raw) {
    if (typeof item !== "string") continue;
    const id = item.trim();
    if (!id || id.length > MAX_OPTION_ID_LEN) continue;
    if (!out.includes(id)) out.push(id);
    if (out.length >= MAX_OPTIONS) break;
  }
  return out;
}

/**
 * @param {unknown} raw
 * @return {string}
 */
function sanitizeSomethingElseText(raw) {
  if (typeof raw !== "string") return "";
  return raw.trim().slice(0, MAX_SOMETHING_ELSE_LEN);
}

exports.enterPregnancyLossSupportMode = onCall(
  {region: "us-central1", timeoutSeconds: 30},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Please sign in to continue.",
      );
    }

    const uid = request.auth.uid;
    const data = request.data && typeof request.data === "object" ?
      request.data :
      {};

    const selectedOptions = sanitizeSelectedOptions(data.selectedOptions);
    const somethingElseText = sanitizeSomethingElseText(data.somethingElseText);

    const userRef = admin.firestore().collection("users").doc(uid);
    let alreadyInMode = false;

    try {
      await admin.firestore().runTransaction(async (tx) => {
        const snap = await tx.get(userRef);
        const existing = snap.exists ? snap.data() : {};
        alreadyInMode =
          existing.currentSupportStage === SUPPORT_STAGE_PREGNANCY_LOSS;

        const updates = {
          currentSupportStage: SUPPORT_STAGE_PREGNANCY_LOSS,
          hidePregnancyMilestones: true,
          emotionalSupportPregnancyLoss: true,
          pregnancyLossFlowStartedAt: admin.firestore.FieldValue.serverTimestamp(),
          emotionalSupportPregnancyLossAt: admin.firestore.FieldValue.serverTimestamp(),
          emotionalSupportCheckIn: {
            selectedOptions,
            somethingElseText,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          emotionalSupportLastCheckInAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (!snap.exists) {
          updates.userId = uid;
          updates.createdAt = admin.firestore.FieldValue.serverTimestamp();
        }

        tx.set(userRef, updates, {merge: true});
      });
    } catch (err) {
      console.error("enterPregnancyLossSupportMode failed", {uid, err});
      throw new HttpsError(
        "internal",
        "We could not save your support settings. Please try again.",
      );
    }

    return {
      success: true,
      alreadyInMode,
      currentSupportStage: SUPPORT_STAGE_PREGNANCY_LOSS,
    };
  },
);
