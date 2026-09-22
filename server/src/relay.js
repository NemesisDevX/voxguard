/**
 * PauseSignal Family Shield relay — core request handling.
 *
 * Receives a privacy-minimal alert request from the Flutter client,
 * validates it, and translates it into a OneSignal REST API call.
 * The OneSignal REST API key lives ONLY in server-side env vars —
 * the client never sees it.
 *
 * OneSignal contract (verified against the current official docs):
 *   POST https://api.onesignal.com/notifications
 *   Authorization: Key <ONESIGNAL_REST_API_KEY>
 *   Body: { app_id, headings: {en}, contents: {en},
 *           include_aliases: { external_id: [...] },
 *           target_channel: "push", data: {...} }
 */

import { handleTranscriptionRequest } from './transcription.js';

export const MAX_RECIPIENTS = 5; // Family Vault model — hard cap, no fan-out abuse.
const MAX_INCIDENT_ID_LEN = 64;
const MAX_TITLE_LEN = 100;
const MAX_BODY_LEN = 300;

const VALID_KINDS = new Set(['family_shield_alert', 'family_shield_response']);
// A danger alert is never 'safe' — safe is a human RESOLUTION sent via
// family_shield_response, not an alert risk band.
const ALERT_RISK_LEVELS = new Set(['suspicious', 'highRisk']);
const VALID_RESOLUTIONS = new Set(['safe', 'stillSuspicious']);
// How much of the analysis pipeline produced this alert — 'full'
// (acoustic + conversation) or 'partial' (acoustic signals only,
// e.g. an uploaded recording without conversation analysis).
const VALID_ANALYSIS_SCOPES = new Set(['full', 'partial']);

// Conservative identifier charset — letters, digits, _-:.@ only.
const SAFE_ID = /^[A-Za-z0-9_\-.:@]{1,64}$/;

// PauseSignal sender identities are exactly vg_<32 lowercase hex> —
// generated client-side by PushIdentityService.
const SENDER_ID = /^vg_[0-9a-f]{32}$/;

const ONESIGNAL_URL = 'https://api.onesignal.com/notifications';
const UPSTREAM_TIMEOUT_MS = 8000;

// ── Best-effort rate limiter (per isolate, per token) ────────────────
// Workers are isolate-scoped, so this is abuse resistance, not a hard
// guarantee — document it as such.
const RATE_LIMIT = 30; // requests
const RATE_WINDOW_MS = 60_000;
const buckets = new Map();

function rateLimited(key) {
  const now = Date.now();
  const bucket = buckets.get(key) ?? { count: 0, reset: now + RATE_WINDOW_MS };
  if (now > bucket.reset) {
    bucket.count = 0;
    bucket.reset = now + RATE_WINDOW_MS;
  }
  bucket.count++;
  buckets.set(key, bucket);
  return bucket.count > RATE_LIMIT;
}

// ── Helpers ──────────────────────────────────────────────────────────

function jsonResponse(status, body, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...extraHeaders },
  });
}

/**
 * Deliberate CORS — no `*`. Allowed origins come from
 * env.ALLOWED_ORIGINS (comma-separated); defaults cover the GitHub
 * Pages demo and local dev servers.
 */
function corsOrigin(request, env) {
  const origin = request.headers.get('Origin');
  if (!origin) return null;
  const allowed = (env.ALLOWED_ORIGINS ??
    'https://nemesisdevx.github.io,http://localhost,http://127.0.0.1')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  // Compare parsed URL parts, not string prefixes — prefix matching
  // would let lookalike origins like `http://localhost.evil.com`
  // or `http://localhost:8080.attacker.io` slip through.
  let o;
  try {
    o = new URL(origin);
  } catch {
    return null; // origins with garbage ports/hosts fail parsing
  }
  const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);
  const ok = allowed.some((a) => {
    try {
      const e = new URL(a);
      // Local dev entries may intentionally match any port on
      // localhost/127.0.0.1. Every other host requires an exact
      // origin match — a port-less allowlist entry must NOT bless
      // `https://prod.example.com:4444` or friends.
      if (LOCAL_HOSTS.has(e.hostname)) {
        return o.protocol === e.protocol && o.hostname === e.hostname;
      }
      return o.origin === e.origin;
    } catch {
      return false; // misconfigured allowlist entry — skip
    }
  });
  return ok ? origin : null;
}

function corsHeaders(request, env) {
  const origin = corsOrigin(request, env);
  if (!origin) return {};
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers':
      'Content-Type, Authorization, X-Audio-Format',
    'Vary': 'Origin',
  };
}

// ── Validation ───────────────────────────────────────────────────────

/** Returns { ok: true, value } or { ok: false, error }. */
export function validateAlertPayload(body) {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, error: 'body must be a JSON object' };
  }
  if (!VALID_KINDS.has(body.kind)) {
    return { ok: false, error: 'unknown kind' };
  }
  const incidentId = body.incident_id;
  if (
    typeof incidentId !== 'string' ||
    incidentId.length === 0 ||
    incidentId.length > MAX_INCIDENT_ID_LEN ||
    !SAFE_ID.test(incidentId)
  ) {
    return { ok: false, error: 'invalid incident_id' };
  }

  if (body.kind === 'family_shield_response') {
    return validateResponsePayload(body, incidentId);
  }

  if (!ALERT_RISK_LEVELS.has(body.risk_level)) {
    return { ok: false, error: 'invalid risk_level' };
  }
  if (!VALID_ANALYSIS_SCOPES.has(body.analysis_scope)) {
    return { ok: false, error: 'invalid analysis_scope' };
  }
  if (
    typeof body.sender_external_id !== 'string' ||
    !SENDER_ID.test(body.sender_external_id)
  ) {
    return { ok: false, error: 'invalid sender_external_id' };
  }
  const ids = body.family_external_ids;
  if (!Array.isArray(ids) || ids.length === 0) {
    return { ok: false, error: 'family_external_ids must be a non-empty array' };
  }
  if (ids.length > MAX_RECIPIENTS) {
    return { ok: false, error: `at most ${MAX_RECIPIENTS} recipients` };
  }
  for (const id of ids) {
    // Real Family Shield recipients are PauseSignal `vg_…` identities —
    // demo ids or arbitrary aliases never cross this boundary.
    if (typeof id !== 'string' || !SENDER_ID.test(id)) {
      return { ok: false, error: 'invalid recipient id' };
    }
  }
  const title = body.title ?? 'PauseSignal Family Shield';
  // Fallback copy is scope/risk-aware too — a partial acoustic warning
  // is never described as a "high-risk call".
  const text = body.body ??
    (body.analysis_scope === 'partial'
      ? 'Elevated acoustic signals were flagged on a monitored device. ' +
        'Verify with your family member directly.'
      : body.risk_level === 'highRisk'
        ? 'A high-risk call was flagged on a monitored device. ' +
          'Verify with your family member directly.'
        : 'A suspicious-call warning was flagged on a monitored device. ' +
          'Verify with your family member directly.');
  if (typeof title !== 'string' || title.length > MAX_TITLE_LEN) {
    return { ok: false, error: 'invalid title' };
  }
  if (typeof text !== 'string' || text.length > MAX_BODY_LEN) {
    return { ok: false, error: 'invalid body' };
  }
  return {
    ok: true,
    value: {
      kind: 'family_shield_alert',
      incidentId,
      riskLevel: body.risk_level,
      analysisScope: body.analysis_scope,
      senderExternalId: body.sender_external_id,
      // Dedupe — OneSignal rejects or double-counts duplicate
      // external_ids in include_aliases.
      recipients: [...new Set(ids)],
      title,
      body: text,
    },
  };
}

/**
 * A `family_shield_response` targets exactly one device — the
 * original sender. No fan-out, no client-controlled copy, no PII.
 */
function validateResponsePayload(body, incidentId) {
  if (!VALID_RESOLUTIONS.has(body.resolution)) {
    return { ok: false, error: 'invalid resolution' };
  }
  if (
    typeof body.responder_external_id !== 'string' ||
    !SENDER_ID.test(body.responder_external_id)
  ) {
    return { ok: false, error: 'invalid responder_external_id' };
  }
  if (
    typeof body.target_external_id !== 'string' ||
    !SENDER_ID.test(body.target_external_id)
  ) {
    return { ok: false, error: 'invalid target_external_id' };
  }
  return {
    ok: true,
    value: {
      kind: 'family_shield_response',
      incidentId,
      resolution: body.resolution,
      responderExternalId: body.responder_external_id,
      recipients: [body.target_external_id],
      title: 'PauseSignal Family Shield Update',
      // Neutral copy — responder_external_id is an opaque identity and
      // the shared relay does not cryptographically prove trust.
      body: 'A Family Shield response was received for your safety alert.',
    },
  };
}

/** Builds the OneSignal request body — safe metadata only. */
export function toOneSignalPayload(alert, appId) {
  const data =
    alert.kind === 'family_shield_response'
      ? {
          kind: 'family_shield_response',
          incident_id: alert.incidentId,
          resolution: alert.resolution,
          responder_external_id: alert.responderExternalId,
        }
      : {
          kind: 'family_shield_alert',
          incident_id: alert.incidentId,
          risk_level: alert.riskLevel,
          // Whether conversation-risk signals were analyzed — lets the
          // receiver describe a partial acoustic warning honestly.
          analysis_scope: alert.analysisScope,
          // Which trusted contact's device raised the alert — opaque
          // vg_… identity only, never a name or phone number.
          sender_external_id: alert.senderExternalId,
        };
  return {
    app_id: appId,
    headings: { en: alert.title },
    contents: { en: alert.body },
    include_aliases: { external_id: alert.recipients },
    target_channel: 'push',
    data,
  };
}

// ── Handler ──────────────────────────────────────────────────────────

/**
 * Handles one relay request. `fetchImpl` is injectable for tests —
 * production passes the global `fetch`.
 */
export async function handleRequest(request, env, fetchImpl = fetch) {
  const cors = corsHeaders(request, env);
  const url = new URL(request.url);

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: cors });
  }

  // Prerecorded-transcription relay routes (/transcription/*).
  if (url.pathname.startsWith('/transcription/')) {
    const res = await handleTranscriptionRequest(
      request, env, fetchImpl, cors,
    );
    if (res) return res;
  }

  if (request.method !== 'POST' || url.pathname !== '/alert') {
    return jsonResponse(404, { error: 'not found' }, cors);
  }

  // Abuse boundary: shared relay client token. This is NOT a
  // high-security credential — it resists casual abuse of a public
  // endpoint. Production should move to authenticated users / device
  // attestation. The OneSignal key stays server-side regardless.
  const expected = env.RELAY_CLIENT_TOKEN;
  if (!expected) {
    return jsonResponse(503, { error: 'relay not configured' }, cors);
  }
  const auth = request.headers.get('Authorization') ?? '';
  if (auth !== `Bearer ${expected}`) {
    return jsonResponse(401, { error: 'unauthorized' }, cors);
  }

  if (rateLimited(expected)) {
    return jsonResponse(429, { error: 'rate limited' }, cors);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonResponse(400, { error: 'malformed JSON' }, cors);
  }

  const parsed = validateAlertPayload(body);
  if (!parsed.ok) {
    return jsonResponse(400, { error: parsed.error }, cors);
  }
  const alert = parsed.value;

  if (!env.ONESIGNAL_APP_ID || !env.ONESIGNAL_REST_API_KEY) {
    return jsonResponse(503, { error: 'upstream not configured' }, cors);
  }

  const requestId = crypto.randomUUID();
  let upstream;
  try {
    upstream = await fetchImpl(ONESIGNAL_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Key ${env.ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(toOneSignalPayload(alert, env.ONESIGNAL_APP_ID)),
      signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
    });
  } catch {
    // Operational logging only — never the API key, auth header, or
    // raw request bodies containing recipient IDs.
    console.log(JSON.stringify({
      requestId,
      event: 'upstream_error',
      recipients: alert.recipients.length,
    }));
    return jsonResponse(503, { error: 'upstream unreachable' }, cors);
  }

  console.log(JSON.stringify({
    requestId,
    event: 'upstream_response',
    status: upstream.status,
    recipients: alert.recipients.length,
  }));

  if (upstream.status >= 200 && upstream.status < 300) {
    return jsonResponse(
      202,
      { ok: true, request_id: requestId },
      cors,
    );
  }
  return jsonResponse(502, { error: 'upstream rejected' }, cors);
}
