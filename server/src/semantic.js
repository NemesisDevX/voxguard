/**
 * PauseSignal semantic-analysis proxy — server-side relay to the Groq
 * chat-completions API so the permanent `GROQ_API_KEY` never ships
 * inside the app.
 *
 * Client contract (`SemanticThreatService` proxy path):
 *   POST {base}/semantic
 *   Authorization: Bearer <RELAY_CLIENT_TOKEN>
 *   { "transcript": "…" }
 *   → 200 { urgency_score, financial_demand_score, secrecy_score,
 *           detected_keywords: [...], impersonation_claims: [...] }
 *
 * The response shape is the SAME compact signal vocabulary the local
 * rule engine produces — the proxy is a drop-in analyzer, never a new
 * authority. Malformed or out-of-shape provider output is rejected
 * here and the client falls back to the local bilingual engine.
 *
 * Privacy boundary: the transcript is proxied in memory only — never
 * persisted, never logged. Operational logs carry requestId +
 * upstream status + transcript length only. The provider key is
 * never logged or returned.
 */

import { checkRelayAuth } from './transcription.js';

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL = 'llama-3.3-70b-versatile';

// Transcript bound — generous for a full call while keeping prompt +
// memory use bounded. Matches nothing client-side on purpose: the
// client truncates before sending, this is the hard ceiling.
export const MAX_TRANSCRIPT_CHARS = 12000;

const UPSTREAM_TIMEOUT_MS = 10_000;

// ── Best-effort per-isolate rate limiter ─────────────────────────────
// Each call is a paid provider request. Isolate-scoped abuse
// resistance ONLY — not a security boundary.
const ANALYZE_LIMIT = 30;               // analyses
const ANALYZE_WINDOW_MS = 60_000;       // per minute
const MAX_BUCKETS = 5000;
const buckets = new Map();

function rateLimited(key) {
  const now = Date.now();
  const bucket = buckets.get(key) ?? { count: 0, reset: now + ANALYZE_WINDOW_MS };
  if (now > bucket.reset) {
    bucket.count = 0;
    bucket.reset = now + ANALYZE_WINDOW_MS;
  }
  bucket.count++;
  buckets.set(key, bucket);
  if (buckets.size > MAX_BUCKETS) {
    for (const [k, b] of buckets) {
      if (now > b.reset) buckets.delete(k);
    }
  }
  return bucket.count > ANALYZE_LIMIT;
}

function jsonResponse(status, body, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...extraHeaders },
  });
}

function withCors(response, cors) {
  for (const [k, v] of Object.entries(cors)) {
    response.headers.set(k, v);
  }
  return response;
}

/** Same prompt contract as the client-side dev path — one schema. */
const SYSTEM_PROMPT =
  'You are a scam-call detection engine. Analyze the call transcript ' +
  '(it may be Arabic or English) and respond ONLY with compact JSON: ' +
  '{"urgency_score":0.0-1.0,"financial_demand_score":0.0-1.0,' +
  '"secrecy_score":0.0-1.0,"detected_keywords":["..."],' +
  '"impersonation_claims":["..."]}';

/**
 * Strictly validates provider output. Returns the compact signal
 * object or null — the client treats any null (→ 502) as "fall back
 * to the local engine".
 */
function validateSignals(parsed) {
  if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
    return null;
  }
  const score = (v) =>
    typeof v === 'number' && Number.isFinite(v)
      ? Math.min(1, Math.max(0, v))
      : null;
  const urgency = score(parsed.urgency_score);
  const financial = score(parsed.financial_demand_score);
  const secrecy = score(parsed.secrecy_score);
  if (urgency === null || financial === null || secrecy === null) {
    return null;
  }
  const list = (v) =>
    Array.isArray(v) ? v.filter((s) => typeof s === 'string') : [];
  return {
    urgency_score: urgency,
    financial_demand_score: financial,
    secrecy_score: secrecy,
    detected_keywords: list(parsed.detected_keywords),
    impersonation_claims: list(parsed.impersonation_claims),
  };
}

/** POST /semantic — transcript in, validated signal JSON out. */
async function analyze(request, env, fetchImpl, cors) {
  const denied = checkRelayAuth(request, env);
  if (denied) return withCors(denied, cors);
  if (!env.GROQ_API_KEY) {
    return jsonResponse(503, { error: 'semantic proxy not configured' }, cors);
  }
  if (rateLimited(request.headers.get('Authorization') ?? 'anonymous')) {
    return jsonResponse(429, { error: 'rate limited' }, cors);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(400, { error: 'malformed JSON' }, cors);
  }
  const transcript = body?.transcript;
  if (
    typeof transcript !== 'string' ||
    transcript.trim().length === 0 ||
    transcript.length > MAX_TRANSCRIPT_CHARS
  ) {
    return jsonResponse(400, { error: 'invalid transcript' }, cors);
  }

  const requestId = crypto.randomUUID();
  const charCount = transcript.length;
  let upstream;
  try {
    upstream = await fetchImpl(GROQ_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: MODEL,
        temperature: 0,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: transcript },
        ],
      }),
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    });
  } catch {
    console.log(JSON.stringify({
      requestId, event: 'semantic_upstream_error', charCount,
    }));
    return jsonResponse(503, { error: 'semantic service unreachable' }, cors);
  }

  if (!upstream.ok) {
    console.log(JSON.stringify({
      requestId, event: 'semantic_upstream_rejected',
      status: upstream.status, charCount,
    }));
    return jsonResponse(502, { error: 'semantic analysis failed' }, cors);
  }

  // Strict envelope → strict payload — any deviation is a safe 502
  // and the client falls back to the local rule engine.
  let signals = null;
  try {
    const envelope = await upstream.json();
    const content = envelope?.choices?.[0]?.message?.content;
    if (typeof content === 'string') {
      signals = validateSignals(JSON.parse(content));
    }
  } catch {
    signals = null;
  }
  if (signals === null) {
    console.log(JSON.stringify({
      requestId, event: 'semantic_upstream_malformed', charCount,
    }));
    return jsonResponse(502, { error: 'semantic analysis failed' }, cors);
  }

  console.log(JSON.stringify({
    requestId, event: 'semantic_analyzed', charCount,
  }));
  return jsonResponse(200, signals, cors);
}

/**
 * Routes /semantic requests. Returns null when the path is not a
 * semantic route so the caller can fall through to other handlers.
 */
export async function handleSemanticRequest(request, env, fetchImpl, cors) {
  const url = new URL(request.url);
  if (request.method === 'POST' && url.pathname === '/semantic') {
    return analyze(request, env, fetchImpl, cors);
  }
  if (url.pathname === '/semantic' || url.pathname.startsWith('/semantic/')) {
    return jsonResponse(404, { error: 'not found' }, cors);
  }
  return null;
}
