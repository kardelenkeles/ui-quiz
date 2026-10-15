const crypto = require("crypto");
const functions = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const express = require("express");
const { SecretManagerServiceClient } = require("@google-cloud/secret-manager");

initializeApp();

const db = getFirestore();
const auth = getAuth();
const app = express();
const secretClient = new SecretManagerServiceClient();

const ALLOWED_MODELS = new Set(
  (process.env.OPENAI_ALLOWED_MODELS || "gpt-4o-mini")
    .split(",")
    .map((model) => model.trim())
    .filter(Boolean),
);
const FREE_DAILY_LIMIT = 30;
const PREMIUM_MONTHLY_TOKEN_LIMIT = 100000;
const RATE_LIMIT_PER_MINUTE = 10;
const MAX_OUTPUT_TOKENS = 4096;
const MAX_TEXT_CHARS = 120000;
const MAX_IMAGE_DATA_URL_CHARS = 5 * 1024 * 1024;

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

function safeEqual(left, right) {
  const a = Buffer.from(left || "");
  const b = Buffer.from(right || "");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function verifyRevenueCatSignature(req) {
  const signingSecret = process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET || "";
  const header = req.get("X-RevenueCat-Webhook-Signature") || "";
  const parts = header.split(",").map((part) => part.trim());
  const timestamp = parts.find((part) => part.startsWith("t="))?.slice(2);
  const signatures = parts
    .filter((part) => part.startsWith("v1="))
    .map((part) => part.slice(3));
  const timestampNumber = Number(timestamp);
  if (!signingSecret || !timestamp || !Number.isFinite(timestampNumber) ||
      Math.abs(Date.now() / 1000 - timestampNumber) > 300 ||
      !req.rawBody || signatures.length === 0) {
    return false;
  }
  const expected = crypto
    .createHmac("sha256", signingSecret)
    .update(`${timestamp}.${req.rawBody.toString("utf8")}`)
    .digest("hex");
  return signatures.some((signature) => safeEqual(signature, expected));
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

function dateKeys(now = new Date()) {
  const day = now.toISOString().slice(0, 10);
  return { day, month: day.slice(0, 7) };
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

function isVerifiedPremium(userData) {
  return userData?.subscriptionVerified === true &&
    userData?.subscriptionPlan === "premium";
}

async function reserveQuota(uid, estimatedTokens) {
  const { day, month } = dateKeys();
  const userRef = db.collection("users").doc(uid);
  const dailyRef = db.collection("daily_usage").doc(`${uid}_${day}`);
  const monthlyRef = db.collection("monthly_usage").doc(`${uid}_${month}`);

  return db.runTransaction(async (transaction) => {
    const userSnapshot = await transaction.get(userRef);
    const premium = isVerifiedPremium(userSnapshot.data());
    if (premium) {
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
    }

    const dailySnapshot = await transaction.get(dailyRef);
    const quizCount = Number(dailySnapshot.data()?.quizCount || 0);
    if (quizCount >= FREE_DAILY_LIMIT) {
      const error = new Error("Daily quiz quota exceeded");
      error.statusCode = 429;
      throw error;
    }
    transaction.set(dailyRef, {
      uid,
      date: day,
      quizCount: quizCount + 1,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: dailySnapshot.exists
        ? dailySnapshot.data().createdAt
        : FieldValue.serverTimestamp(),
    });
    return { premium, day, month };
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

function validateContent(content, totals) {
  if (typeof content === "string") {
    totals.text += content.length;
    return content;
  }
  if (!Array.isArray(content) || content.length === 0 || content.length > 4) {
    throw new Error("Invalid message content");
  }
  const sanitized = [];
  for (const part of content) {
    if (!part || typeof part !== "object") throw new Error("Invalid content part");
    if (part.type === "text" && typeof part.text === "string") {
      totals.text += part.text.length;
      sanitized.push({ type: "text", text: part.text });
      continue;
    }
    if (part.type === "image_url") {
      const url = part.image_url?.url;
      const validPrefix = typeof url === "string" &&
        /^data:image\/(jpeg|png|gif|webp);base64,/i.test(url);
      if (!validPrefix || url.length > MAX_IMAGE_DATA_URL_CHARS) {
        throw new Error("Invalid or oversized image");
      }
      totals.images += 1;
      const detail = ["auto", "low", "high"].includes(part.image_url?.detail)
        ? part.image_url.detail
        : "auto";
      sanitized.push({ type: "image_url", image_url: { url, detail } });
      continue;
    }
    throw new Error("Unsupported content part");
  }
  return sanitized;
}

function validateChatRequest(body, uid) {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new Error("JSON object body required");
  }
  const allowedKeys = new Set([
    "model", "messages", "max_tokens", "max_completion_tokens",
    "temperature", "response_format",
  ]);
  if (Object.keys(body).some((key) => !allowedKeys.has(key))) {
    throw new Error("Unsupported request parameter");
  }
  if (!ALLOWED_MODELS.has(body.model)) throw new Error("Model is not allowed");
  if (!Array.isArray(body.messages) || body.messages.length < 1 || body.messages.length > 8) {
    throw new Error("messages must contain between 1 and 8 items");
  }

  const totals = { text: 0, images: 0 };
  const sanitizedMessages = [];
  for (const message of body.messages) {
    if (!message || typeof message !== "object") throw new Error("Invalid message");
    if (!["system", "user", "assistant"].includes(message.role)) {
      throw new Error("Unsupported message role");
    }
    const content = validateContent(message.content, totals);
    sanitizedMessages.push({ role: message.role, content });
  }
  if (totals.text > MAX_TEXT_CHARS || totals.images > 1) {
    throw new Error("Request content is too large");
  }

  const outputTokens = body.max_completion_tokens ?? body.max_tokens ?? 1024;
  if (!Number.isInteger(outputTokens) || outputTokens < 1 || outputTokens > MAX_OUTPUT_TOKENS) {
    throw new Error(`Output token limit must be between 1 and ${MAX_OUTPUT_TOKENS}`);
  }
  if (body.temperature !== undefined &&
      (typeof body.temperature !== "number" || body.temperature < 0 || body.temperature > 1)) {
    throw new Error("temperature must be between 0 and 1");
  }

  const cleanBody = {
    model: body.model,
    messages: sanitizedMessages,
    max_completion_tokens: outputTokens,
    safety_identifier: crypto.createHash("sha256").update(uid).digest("hex"),
  };
  if (body.temperature !== undefined) cleanBody.temperature = body.temperature;
  if (body.response_format !== undefined) {
    if (body.response_format?.type !== "json_object") {
      throw new Error("Unsupported response format");
    }
    cleanBody.response_format = { type: "json_object" };
  }
  const estimatedTokens = Math.ceil(totals.text / 4) + outputTokens +
    (totals.images * 2000);
  return { payload: cleanBody, estimatedTokens };
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
    dailyRemaining: Math.max(0, FREE_DAILY_LIMIT - used),
    dailyLimit: FREE_DAILY_LIMIT,
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
