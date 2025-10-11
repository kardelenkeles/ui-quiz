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
        .json({error: "Missing or invalid Authorization header"});
  }

  const idToken = match[1];
  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.user = decoded;
    return next();
  } catch (err) {
    return res.status(401).json({error: "Invalid ID token"});
  }
}

app.get("/get-api-key", verifyFirebaseIdToken, (req, res) => {
  // Read API key from functions config: set with
  // firebase functions:config:set api.key="YOUR_API_KEY"
  const apiCfg = functions.config() && functions.config().api;
  const apiKey = apiCfg && apiCfg.key;
  if (!apiKey) {
    return res.status(500).json({error: "API key not configured"});
  }

  // Optionally limit access by checking req.user.uid or claims here.
  return res.status(200).json({apiKey});
});

exports.api = functions.https.onRequest(app);
