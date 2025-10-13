const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");

admin.initializeApp();
const app = express();

/**
 * Middleware to verify a Firebase ID token sent in the
 * `Authorization: Bearer <idToken>` header.
 *
 * If valid, attaches the decoded token to `req.user` and calls `next()`.
 * Otherwise responds with 401.
 *
 * @param {Object} req Express request
 * @param {Object} res Express response
 * @param {Function} next Express next
 */
async function verifyFirebaseIdToken(req, res, next) {
  const authHeader = req.get("Authorization") || "";
  const match = authHeader.match(/^Bearer (.*)$/);

  if (!match) {
    return res
      .status(401)
      .json({ error: "Missing or invalid Authorization header" });
  }

  const idToken = match[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.user = decoded;
    return next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid ID token" });
  }
}

app.get("/get-api-key", verifyFirebaseIdToken, (req, res) => {
  // Read API key from functions config: set with
  // firebase functions:config:set api.key="YOUR_API_KEY"
  const apiCfg = functions.config() && functions.config().api;
  const apiKey = apiCfg && apiCfg.key;
  if (!apiKey) {
    return res.status(500).json({ error: "API key not configured" });
  }

  // Optionally limit access by checking req.user.uid or claims here.
  return res.status(200).json({ apiKey });
});

/**
 * Proxy endpoint that forwards Chat Completions requests to OpenAI.
 * Expects the client to send the same JSON body that the OpenAI Chat
 * Completions endpoint expects (model, messages, max_tokens, temperature, ...).
 * This endpoint requires authentication and uses the API key stored in
 * functions.config().api.key.
 */
app.post("/openai/chat", verifyFirebaseIdToken, async (req, res) => {
  try {
    const apiCfg = functions.config() && functions.config().api;
    const apiKey = apiCfg && apiCfg.key;
    if (!apiKey) {
      return res.status(500).json({ error: "API key not configured" });
    }

    // Forward request body to OpenAI
    const upstreamResp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify(req.body),
    });

    const text = await upstreamResp.text();
    // Mirror status and body
    res.status(upstreamResp.status)
      .set("Content-Type", "application/json")
      .send(text);
  } catch (err) {
    console.error("Proxy error:", err);
    return res.status(502).json({ error: "Upstream request failed" });
  }
});

// Proxy for GET /v1/models
app.get("/openai/models", verifyFirebaseIdToken, async (req, res) => {
  try {
    const apiCfg = functions.config() && functions.config().api;
    const apiKey = apiCfg && apiCfg.key;
    if (!apiKey) {
      return res.status(500).json({ error: "API key not configured" });
    }

    const upstreamResp = await fetch("https://api.openai.com/v1/models", {
      method: "GET",
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    const text = await upstreamResp.text();
    res.status(upstreamResp.status)
      .set("Content-Type", "application/json")
      .send(text);
  } catch (err) {
    console.error("Proxy error:", err);
    return res.status(502).json({ error: "Upstream request failed" });
  }
});

// Simple health check endpoint
app.get("/health", (req, res) => {
  const config = functions.config();
  const hasApiKey = !!(config && config.api && config.api.key);
  res.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    hasApiKey: hasApiKey,
  });
});

exports.api = functions.https.onRequest(app);
