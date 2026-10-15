"use strict";

const crypto = require("crypto");

const ALLOWED_MODELS = new Set(
  (process.env.OPENAI_ALLOWED_MODELS || "gpt-4o-mini")
    .split(",")
    .map((model) => model.trim())
    .filter(Boolean),
);
const MAX_OUTPUT_TOKENS = 4096;
const MAX_TEXT_CHARS = 120000;
const MAX_IMAGE_DATA_URL_CHARS = 5 * 1024 * 1024;

function safeEqual(left, right) {
  const a = Buffer.from(left || "");
  const b = Buffer.from(right || "");
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function verifyRevenueCatSignature(req, now = Date.now()) {
  const signingSecret = process.env.REVENUECAT_WEBHOOK_SIGNING_SECRET || "";
  const header = req.get("X-RevenueCat-Webhook-Signature") || "";
  const parts = header.split(",").map((part) => part.trim());
  const timestamp = parts.find((part) => part.startsWith("t="))?.slice(2);
  const signatures = parts
    .filter((part) => part.startsWith("v1="))
    .map((part) => part.slice(3));
  const timestampNumber = Number(timestamp);
  if (!signingSecret || !timestamp || !Number.isFinite(timestampNumber) ||
      Math.abs(now / 1000 - timestampNumber) > 300 ||
      !req.rawBody || signatures.length === 0) {
    return false;
  }
  const expected = crypto
    .createHmac("sha256", signingSecret)
    .update(`${timestamp}.${req.rawBody.toString("utf8")}`)
    .digest("hex");
  return signatures.some((signature) => safeEqual(signature, expected));
}

function dateKeys(now = new Date()) {
  const day = now.toISOString().slice(0, 10);
  return { day, month: day.slice(0, 7) };
}

function isVerifiedPremium(userData) {
  return userData?.subscriptionVerified === true &&
    userData?.subscriptionPlan === "premium";
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

module.exports = {
  ALLOWED_MODELS,
  dateKeys,
  isVerifiedPremium,
  safeEqual,
  validateChatRequest,
  validateContent,
  verifyRevenueCatSignature,
};
