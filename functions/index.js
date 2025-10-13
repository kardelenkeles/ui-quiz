const functions = require("firebase-functions");
const admin = require("firebase-admin");
const express = require("express");
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');

// Safe fetch getter: prefer global fetch (Node 18+/22), otherwise dynamically import node-fetch if available.
// This avoids bundling node-fetch in package.json which can cause Cloud Build resolution issues.
async function _getFetch() {
  if (typeof globalThis.fetch === 'function') return globalThis.fetch.bind(globalThis);
  // dynamic import of node-fetch if present at runtime
  try {
    const mod = await import('node-fetch');
    // node-fetch v3 exports default
    return mod.default || mod;
  } catch (e) {
    // If import fails, throw a clear error for easier debugging in Cloud Build logs
    throw new Error('No fetch implementation available (global fetch missing and dynamic import of node-fetch failed)');
  }
}

admin.initializeApp();
const app = express();
// Parse JSON bodies (incoming requests from the Flutter client)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Helper to read API key from environment variables with a safe fallback
function getOpenAIApiKey() {
  // This function is kept for backward-compat. Prefer getOpenAIApiKeyCached()
  // Prefer functions.config().openai.key (set via `firebase functions:config:set openai.key="..."`)
  try {
    if (typeof functions.config === 'function') {
      const cfg = functions.config() && functions.config().openai;
      if (cfg && cfg.key) return cfg.key;
    }
  } catch (e) {
    // ignore
  }

  if (process.env.OPENAI_API_KEY) return process.env.OPENAI_API_KEY;

  // legacy support for functions.config().api.key
  if (typeof functions.config === 'function') {
    const apiCfg = functions.config() && functions.config().api;
    return apiCfg && apiCfg.key;
  }
  return null;
}

// Cached getter for the OpenAI API key. Order of precedence:
// 1) Environment variable OPENAI_API_KEY
// 2) Secret Manager secret referenced by env OPENAI_SECRET (format: projects/PROJECT/secrets/NAME/versions/latest or just secret name)
// 3) functions.config().api.key (legacy)
// Returned value is cached in memory for the lifetime of the function instance.
const secretClient = new SecretManagerServiceClient();
let _cachedOpenAIKey = null;
let _cachedOpenAIKeyPromise = null;

async function getOpenAIApiKeyCached() {
  if (_cachedOpenAIKey) return _cachedOpenAIKey;
  if (_cachedOpenAIKeyPromise) return _cachedOpenAIKeyPromise;

  _cachedOpenAIKeyPromise = (async () => {
    // 1) Prefer functions.config().openai.key (set via firebase functions:config:set openai.key="...")
    try {
      if (typeof functions.config === 'function') {
        const cfg = functions.config() && functions.config().openai;
        if (cfg && cfg.key) {
          _cachedOpenAIKey = cfg.key;
          _cachedOpenAIKeyPromise = null;
          return _cachedOpenAIKey;
        }
      }
    } catch (e) {
      // ignore
    }

    // 2) env var
    if (process.env.OPENAI_API_KEY) {
      _cachedOpenAIKey = process.env.OPENAI_API_KEY;
      _cachedOpenAIKeyPromise = null;
      return _cachedOpenAIKey;
    }

    // 3) Secret Manager (env var OPENAI_SECRET specifies resource or name)
    const secretRef = process.env.OPENAI_SECRET;
    if (secretRef) {
      try {
        let name = secretRef;
        // If only secret id provided, build resource name
        if (!secretRef.startsWith('projects/')) {
          const project = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT || (process.env.FUNCTIONS_EMULATOR ? process.env.GCLOUD_PROJECT : null) || (functions.config && functions.config().project && functions.config().project.id);
          if (project) {
            name = `projects/${project}/secrets/${secretRef}/versions/latest`;
          }
        }
        const [accessResponse] = await secretClient.accessSecretVersion({ name });
        const payload = accessResponse.payload && accessResponse.payload.data ? accessResponse.payload.data.toString('utf8') : null;
        if (payload) {
          _cachedOpenAIKey = payload.trim();
          _cachedOpenAIKeyPromise = null;
          return _cachedOpenAIKey;
        }
      } catch (err) {
        console.warn('Failed to read secret from Secret Manager:', err && err.message ? err.message : err);
      }
    }

    // 3) legacy functions.config()
    try {
      if (typeof functions.config === 'function') {
        const apiCfg = functions.config() && functions.config().api;
        if (apiCfg && apiCfg.key) {
          _cachedOpenAIKey = apiCfg.key;
          _cachedOpenAIKeyPromise = null;
          return _cachedOpenAIKey;
        }
      }
    } catch (e) {
      // ignore
    }

    _cachedOpenAIKeyPromise = null;
    return null;
  })();

  return _cachedOpenAIKeyPromise;
}

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

app.get("/get-api-key", verifyFirebaseIdToken, async (req, res) => {
  try {
    const apiKey = await getOpenAIApiKeyCached();
    if (!apiKey) return res.status(500).json({ error: 'API key not configured' });
    return res.status(200).json({ apiKey });
  } catch (err) {
    console.error('Error fetching API key:', err);
    return res.status(500).json({ error: 'failed to read api key' });
  }
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
    const apiKey = await getOpenAIApiKeyCached();
    if (!apiKey) return res.status(500).json({ error: "API key not configured" });

    // Forward request body to OpenAI
    console.log('Forwarding request to OpenAI. Body length:', JSON.stringify(req.body).length);
    const fetchFn = await _getFetch();
    const upstreamResp = await fetchFn("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify(req.body),
    });

    const text = await upstreamResp.text();
    console.log('OpenAI response status:', upstreamResp.status);
    try {
      // Log a snippet of response to help debugging (avoid huge logs)
      console.log('OpenAI response snippet:', text && text.substring(0, 1000));
    } catch (e) {
      console.log('Unable to log response snippet:', e);
    }

    // Mirror status and body (pass-through)
    const contentType = upstreamResp.headers.get('content-type') || 'application/json';
    res.status(upstreamResp.status)
      .set('Content-Type', contentType)
      .send(text);
  } catch (err) {
    console.error("Proxy error:", err && err.stack ? err.stack : err);
    return res.status(502).json({ error: "Upstream request failed", details: String(err) });
  }
});

// Proxy for GET /v1/models
app.get("/openai/models", verifyFirebaseIdToken, async (req, res) => {
  try {
    const apiKey = await getOpenAIApiKeyCached();
    if (!apiKey) return res.status(500).json({ error: 'API key not configured' });

    console.log('Fetching models from OpenAI');
    const fetchFn = await _getFetch();
    const upstreamResp = await fetchFn("https://api.openai.com/v1/models", {
      method: "GET",
      headers: { Authorization: `Bearer ${apiKey}` },
    });
    const text = await upstreamResp.text();
    console.log('Models response status:', upstreamResp.status);
    const contentType = upstreamResp.headers.get('content-type') || 'application/json';
    res.status(upstreamResp.status)
      .set('Content-Type', contentType)
      .send(text);
  } catch (err) {
    console.error("Proxy error:", err);
    return res.status(502).json({ error: "Upstream request failed" });
  }
});

// Simple health check endpoint (async): uses cached getter so Secret Manager is checked
app.get("/health", async (req, res) => {
  try {
    const key = await getOpenAIApiKeyCached();
    const hasApiKey = !!key;
    res.status(200).json({
      status: "ok",
      timestamp: new Date().toISOString(),
      hasApiKey: hasApiKey,
    });
  } catch (err) {
    console.error('Health check error:', err);
    res.status(500).json({ error: 'health check failed' });
  }
});

exports.api = functions.https.onRequest(app);
