"use strict";

const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const test = require("node:test");

const {
  dateKeys,
  isVerifiedPremium,
  safeEqual,
  validateChatRequest,
  verifyRevenueCatSignature,
} = require("../lib/core");

test("dateKeys uses UTC day and month", () => {
  assert.deepEqual(dateKeys(new Date("2026-10-15T23:59:59Z")), {
    day: "2026-10-15",
    month: "2026-10",
  });
});

test("premium requires both verified state and premium plan", () => {
  assert.equal(isVerifiedPremium({
    subscriptionVerified: true,
    subscriptionPlan: "premium",
  }), true);
  assert.equal(isVerifiedPremium({
    subscriptionVerified: false,
    subscriptionPlan: "premium",
  }), false);
});

test("chat validation strips unsupported fields and hashes the user id", () => {
  const result = validateChatRequest({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: "Create a quiz" }],
    max_tokens: 250,
    temperature: 0.2,
  }, "firebase-user");

  assert.equal(result.payload.max_completion_tokens, 250);
  assert.equal(result.payload.max_tokens, undefined);
  assert.equal(result.payload.safety_identifier.length, 64);
  assert.equal(result.estimatedTokens, 254);
});

test("chat validation rejects model bypasses and oversized output", () => {
  assert.throws(() => validateChatRequest({
    model: "not-allowed",
    messages: [{ role: "user", content: "hello" }],
  }, "uid"), /not allowed/);
  assert.throws(() => validateChatRequest({
    model: "gpt-4o-mini",
    messages: [{ role: "user", content: "hello" }],
    max_tokens: 5000,
  }, "uid"), /Output token limit/);
});

test("RevenueCat signature accepts a current valid HMAC and rejects tampering", () => {
  const previousSecret = process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET;
  process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET = "webhook-secret";
  const now = Date.parse("2026-10-15T12:00:00Z");
  const timestamp = String(now / 1000);
  const rawBody = Buffer.from('{"event":{"type":"RENEWAL"}}');
  const signature = crypto
    .createHmac("sha256", "webhook-secret")
    .update(`${timestamp}.${rawBody.toString("utf8")}`)
    .digest("hex");
  const request = {
    rawBody,
    get: () => `t=${timestamp},v1=${signature}`,
  };

  assert.equal(verifyRevenueCatSignature(request, now), true);
  request.rawBody = Buffer.from("tampered");
  assert.equal(verifyRevenueCatSignature(request, now), false);
  if (previousSecret === undefined) {
    delete process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET;
  } else {
    process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET = previousSecret;
  }
});

test("safeEqual handles unequal lengths without throwing", () => {
  assert.equal(safeEqual("short", "much-longer"), false);
});
