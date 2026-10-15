const functions = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const express = require("express");
const { SecretManagerServiceClient } = require("@google-cloud/secret-manager");
const {
  ALLOWED_MODELS,
  dateKeys,
  isVerifiedPremium,
  safeEqual,
  validateChatRequest,
  verifyRevenueCatSignature,
} = require("./lib/core");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const app = express();
const secretClient = new SecretManagerServiceClient();

const PREMIUM_MONTHLY_TOKEN_LIMIT = 100000;
const RATE_LIMIT_PER_MINUTE = 10;

app.disable("x-powered-by");
app.use(express.json({
  limit: "6mb",
  verify: (req, _res, buffer) => {
    req.rawBody = Buffer.from(buffer);
  },
}));

async function getFetch() {
  if (typeof globalThis.fetch === "function") {
    return globalThis.fetch.bind(globalThis);
  }
  const mod = await import("node-fetch");
  return mod.default || mod;
}

let cachedOpenAIKey = null;
let cachedOpenAIKeyPromise = null;

async function getOpenAIApiKey() {
  if (cachedOpenAIKey) return cachedOpenAIKey;
  if (cachedOpenAIKeyPromise) return cachedOpenAIKeyPromise;

  cachedOpenAIKeyPromise = (async () => {
    if (process.env.OPENAI_API_KEY) {
      cachedOpenAIKey = process.env.OPENAI_API_KEY.trim();
      return cachedOpenAIKey;
    }

    const secretRef = process.env.OPENAI_SECRET;
    if (secretRef) {
      let name = secretRef;
      if (!secretRef.startsWith("projects/")) {
        const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
        if (!project) throw new Error("Unable to resolve GCP project for OPENAI_SECRET");
        name = `projects/${project}/secrets/${secretRef}/versions/latest`;
      }
      const [response] = await secretClient.accessSecretVersion({ name });
      const value = response.payload?.data?.toString("utf8").trim();
      if (value) {
        cachedOpenAIKey = value;
        return cachedOpenAIKey;
      }
    }

    // Legacy fallback. New deployments should use OPENAI_SECRET or OPENAI_API_KEY.
    try {
      const value = functions.config?.()?.openai?.key || functions.config?.()?.api?.key;
      if (value) cachedOpenAIKey = value;
    } catch (_) {
      // functions.config() is unavailable in some modern runtimes.
    }
    return cachedOpenAIKey;
  })().finally(() => {
    cachedOpenAIKeyPromise = null;
  });

  return cachedOpenAIKeyPromise;
}

async function verifyFirebaseIdToken(req, res, next) {
  const match = (req.get("Authorization") || "").match(/^Bearer ([^\s]+)$/);
  if (!match) return res.status(401).json({ error: "Authentication required" });

  try {
    req.user = await auth.verifyIdToken(match[1], true);
    return next();
  } catch (_) {
    return res.status(401).json({ error: "Invalid or revoked ID token" });
  }
}

async function resolveFirebaseUid(candidates) {
  for (const candidate of [...new Set(candidates.flat())]) {
    if (typeof candidate !== "string" || candidate.startsWith("$RCAnonymousID:")) {
      continue;
    }
    try {
      await auth.getUser(candidate);
      return candidate;
    } catch (error) {
      if (error.code !== "auth/user-not-found") throw error;
    }
  }
  return null;
}

async function enforceRateLimit(uid) {
  const ref = db.collection("rate_limits").doc(uid);
  const now = Date.now();
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.data() || {};
    const windowStartedAt = Number(data.windowStartedAt || 0);
    const inCurrentWindow = now - windowStartedAt < 60000;
    const count = inCurrentWindow ? Number(data.count || 0) : 0;
    if (count >= RATE_LIMIT_PER_MINUTE) {
      const error = new Error("Rate limit exceeded");
      error.statusCode = 429;
      throw error;
    }
    transaction.set(ref, {
      uid,
      windowStartedAt: inCurrentWindow ? windowStartedAt : now,
      count: count + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function reserveQuota(uid, estimatedTokens) {
  const { day, month } = dateKeys();
  const userRef = db.collection("users").doc(uid);
  const dailyRef = db.collection("daily_usage").doc(`${uid}_${day}`);
  const monthlyRef = db.collection("monthly_usage").doc(`${uid}_${month}`);

  return db.runTransaction(async (transaction) => {
    const userSnapshot = await transaction.get(userRef);
    const premium = isVerifiedPremium(userSnapshot.data());
    if (!premium) {
      const error = new Error("An active premium subscription is required");
      error.statusCode = 402;
      throw error;
    }

    const monthlySnapshot = await transaction.get(monthlyRef);
    const tokensUsed = Number(monthlySnapshot.data()?.tokensUsed || 0);
    if (tokensUsed + estimatedTokens > PREMIUM_MONTHLY_TOKEN_LIMIT) {
      const error = new Error("Monthly token quota exceeded");
      error.statusCode = 429;
      throw error;
    }
    transaction.set(monthlyRef, {
      uid,
      month,
      tokensUsed: tokensUsed + estimatedTokens,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { premium, day, month, tokensReserved: estimatedTokens };
  });
}

async function refundQuota(uid, reservation) {
  const ref = reservation.premium
    ? db.collection("monthly_usage").doc(`${uid}_${reservation.month}`)
    : db.collection("daily_usage").doc(`${uid}_${reservation.day}`);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) return;
    if (reservation.premium) {
      transaction.update(ref, {
        tokensUsed: Math.max(
          0,
          Number(snapshot.data()?.tokensUsed || 0) - reservation.tokensReserved,
        ),
        updatedAt: FieldValue.serverTimestamp(),
      });
    } else {
      transaction.update(ref, {
        quizCount: Math.max(0, Number(snapshot.data()?.quizCount || 0) - 1),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
}

async function recordTokenUsage(uid, reservation, tokensUsed) {
  if (!Number.isSafeInteger(tokensUsed) || tokensUsed <= 0) return;
  const batch = db.batch();
  batch.set(db.collection("app_settings").doc("usage_stats"), {
    totalTokensUsed: FieldValue.increment(tokensUsed),
    totalRequests: FieldValue.increment(1),
    lastUpdated: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (reservation.premium) {
    batch.set(db.collection("monthly_usage").doc(`${uid}_${reservation.month}`), {
      uid,
      month: reservation.month,
      tokensUsed: FieldValue.increment(tokensUsed - reservation.tokensReserved),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  await batch.commit();
}

async function getQuota(uid) {
  const { day, month } = dateKeys();
  const [userSnapshot, dailySnapshot, monthlySnapshot] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("daily_usage").doc(`${uid}_${day}`).get(),
    db.collection("monthly_usage").doc(`${uid}_${month}`).get(),
  ]);
  if (isVerifiedPremium(userSnapshot.data())) {
    const used = Number(monthlySnapshot.data()?.tokensUsed || 0);
    return {
      plan: "premium",
      tokensUsed: used,
      tokensRemaining: Math.max(0, PREMIUM_MONTHLY_TOKEN_LIMIT - used),
      monthlyLimit: PREMIUM_MONTHLY_TOKEN_LIMIT,
    };
  }
  const used = Number(dailySnapshot.data()?.quizCount || 0);
  return {
    plan: "free",
    dailyUsed: used,
    dailyRemaining: 0,
    dailyLimit: 0,
  };
}

app.get("/quota", verifyFirebaseIdToken, async (req, res) => {
  try {
    return res.status(200).json(await getQuota(req.user.uid));
  } catch (error) {
    console.error("Quota read failed", error);
    return res.status(500).json({ error: "Unable to read quota" });
  }
});

app.post("/openai/chat", verifyFirebaseIdToken, async (req, res) => {
  let reservation;
  try {
    await enforceRateLimit(req.user.uid);
    const validated = validateChatRequest(req.body, req.user.uid);
    reservation = await reserveQuota(req.user.uid, validated.estimatedTokens);
    const apiKey = await getOpenAIApiKey();
    if (!apiKey) throw new Error("OpenAI API key is not configured");

    const fetchFn = await getFetch();
    const upstream = await fetchFn("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify(validated.payload),
      signal: AbortSignal.timeout(60000),
    });
    const responseText = await upstream.text();
    if (!upstream.ok) {
      await refundQuota(req.user.uid, reservation);
      reservation = null;
      console.warn("OpenAI request failed", { status: upstream.status, uid: req.user.uid });
      return res.status(upstream.status).json({ error: "AI request failed" });
    }

    let parsed;
    try {
      parsed = JSON.parse(responseText);
    } catch (_) {
      throw new Error("OpenAI returned invalid JSON");
    }
    try {
      await recordTokenUsage(
        req.user.uid,
        reservation,
        Number(parsed.usage?.total_tokens || 0),
      );
    } catch (usageError) {
      // Keep the conservative reservation if reconciliation fails. Never turn
      // a successful model response into an unmetered retry opportunity.
      console.error("Usage reconciliation failed", usageError);
    }
    reservation = null;
    return res.status(200).json(parsed);
  } catch (error) {
    if (reservation) {
      try {
        await refundQuota(req.user.uid, reservation);
      } catch (refundError) {
        console.error("Quota refund failed", refundError);
      }
    }
    const validationError = error.message?.startsWith("Invalid") ||
      error.message?.includes("must") || error.message?.includes("allowed") ||
      error.message?.includes("Unsupported") || error.message?.includes("large") ||
      error.message?.includes("required");
    const status = error.statusCode || (validationError ? 400 : 502);
    console.error("Proxy request failed", { status, message: error.message, uid: req.user?.uid });
    return res.status(status).json({ error: status === 400 ? error.message : "Request failed" });
  }
});

// Return only the server allowlist, never the provider's complete model catalog.
app.get("/openai/models", verifyFirebaseIdToken, async (_req, res) => {
  return res.status(200).json({
    object: "list",
    data: [...ALLOWED_MODELS].map((id) => ({ id, object: "model" })),
  });
});

// Configure RevenueCat to send a bearer token matching REVENUECAT_WEBHOOK_SECRET.
// Only this verified server path may grant premium access.
app.post("/revenuecat/webhook", async (req, res) => {
  const configuredSecret = process.env.REVENUECAT_WEBHOOK_SECRET || "";
  const suppliedSecret = (req.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!configuredSecret || !safeEqual(suppliedSecret, configuredSecret) ||
      !verifyRevenueCatSignature(req)) {
    return res.status(401).json({ error: "Invalid webhook authorization or signature" });
  }

  const event = req.body?.event;
  if (!event || typeof event !== "object") {
    return res.status(400).json({ error: "Invalid webhook event" });
  }

  if (event.type === "TRANSFER") {
    const fromUid = await resolveFirebaseUid(event.transferred_from || []);
    const toUid = await resolveFirebaseUid(event.transferred_to || []);
    if (!fromUid && !toUid) {
      return res.status(400).json({ error: "No Firebase UID found for transfer" });
    }
    const batch = db.batch();
    if (fromUid) {
      batch.set(db.collection("users").doc(fromUid), {
        uid: fromUid,
        subscriptionPlan: "free",
        subscriptionVerified: true,
        subscriptionUpdatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    if (toUid) {
      batch.set(db.collection("users").doc(toUid), {
        uid: toUid,
        subscriptionPlan: "premium",
        subscriptionVerified: true,
        revenueCatAppUserId: toUid,
        subscriptionUpdatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await batch.commit();
    return res.status(200).json({ received: true, changed: true });
  }

  const uid = await resolveFirebaseUid([
    event.app_user_id,
    event.original_app_user_id,
    ...(Array.isArray(event.aliases) ? event.aliases : []),
  ]);
  if (!uid) {
    return res.status(400).json({ error: "A Firebase UID app_user_id is required" });
  }

  const inactiveEvents = new Set(["EXPIRATION"]);
  const activeEvents = new Set([
    "INITIAL_PURCHASE", "RENEWAL", "NON_RENEWING_PURCHASE",
    "PRODUCT_CHANGE", "UNCANCELLATION", "SUBSCRIPTION_EXTENDED",
    "TEMPORARY_ENTITLEMENT_GRANT", "PURCHASE_REDEEMED",
  ]);
  if (!activeEvents.has(event.type) && !inactiveEvents.has(event.type)) {
    return res.status(200).json({ received: true, changed: false });
  }

  const hasProEntitlement = Array.isArray(event.entitlement_ids) &&
    event.entitlement_ids.includes("pro");
  const premium = activeEvents.has(event.type) && hasProEntitlement;
  await db.collection("users").doc(uid).set({
    uid,
    subscriptionPlan: premium ? "premium" : "free",
    subscriptionVerified: true,
    revenueCatAppUserId: uid,
    subscriptionUpdatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return res.status(200).json({ received: true, changed: true });
});

app.get("/health", async (_req, res) => {
  try {
    return res.status(200).json({
      status: "ok",
      timestamp: new Date().toISOString(),
      hasApiKey: Boolean(await getOpenAIApiKey()),
      allowedModels: [...ALLOWED_MODELS],
    });
  } catch (error) {
    console.error("Health check failed", error);
    return res.status(500).json({ error: "Health check failed" });
  }
});

app.use((error, _req, res, _next) => {
  if (error?.type === "entity.too.large") {
    return res.status(413).json({ error: "Request body is too large" });
  }
  if (error instanceof SyntaxError) {
    return res.status(400).json({ error: "Invalid JSON body" });
  }
  console.error("Unhandled request error", error);
  return res.status(500).json({ error: "Internal server error" });
});

exports.api = functions.https.onRequest(app);
