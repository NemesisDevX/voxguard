/**
 * PauseSignal AssemblyAI streaming-token broker — mints the
 * short-lived, one-time-use token the Flutter client puts on the
 * realtime WebSocket `?token=` parameter.
 *
 * The permanent provider key lives ONLY in server-side env vars
 * (`ASSEMBLYAI_API_KEY`); the client authenticates with the shared
 * `RELAY_CLIENT_TOKEN` bearer — abuse resistance, not strong user
 * authentication.
 *
 * AssemblyAI streaming-token contract (verified against the current
 * official docs):
 *   GET https://streaming.assemblyai.com/v3/token
 *       ?expires_in_seconds=600        (documented maximum)
 *     Authorization: <permanent API key>
 *     → { token: "…", expires_in_seconds: 600 }
 *
 * The client contract (`BrokeredTokenProvider`):
 *   GET|POST {base}/aai-token → 200 { "token": "…" }
 *
 * Privacy boundary: this module NEVER logs the permanent key, minted
 * tokens, or auth headers. Operational logs carry requestId +
 * upstream status only. Nothing is persisted.
 */

import { checkRelayAuth } from './transcription.js';

const TOKEN_ENDPOINT = 'https://streaming.assemblyai.com/v3/token';

// Documented maximum lifetime for AssemblyAI temporary streaming
// tokens — matches kAssemblyAiTokenTtlSeconds in the Flutter client.
export const TOKEN_TTL_SECONDS = 600;

const UPSTREAM_TIMEOUT_MS = 8000;

// ── Best-effort per-isolate rate limiter ─────────────────────────────
// Token mints are cheap but provider-bound; a burst cap resists
// casual abuse of the shared endpoint. Isolate-scoped — abuse
// resistance ONLY, not a security boundary.
const MINT_LIMIT = 20;                  // token mints
const MINT_WINDOW_MS = 60_000;          // per minute
const MAX_BUCKETS = 5000;
const buckets = new Map();

function rateLimited(key) {
  const now = Date.now();
  const bucket = buckets.get(key) ?? { count: 0, reset: now + MINT_WINDOW_MS };
  if (now > bucket.reset) {
    bucket.count = 0;
    bucket.reset = now + MINT_WINDOW_MS;
  }
  bucket.count++;
  buckets.set(key, bucket);
  if (buckets.size > MAX_BUCKETS) {
    for (const [k, b] of buckets) {
      if (now > b.reset) buckets.delete(k);
    }
  }
  return bucket.count > MINT_LIMIT;
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

/** Every /aai-token response is uncacheable — minted tokens are
 *  one-time-use secrets and must never sit in a shared cache. */
function noStore(response) {
  response.headers.set('Cache-Control', 'no-store');
  return response;
}

/** GET|POST /aai-token — mint one short-lived streaming token. */
async function mintToken(request, env, fetchImpl, cors) {
  const denied = checkRelayAuth(request, env);
  if (denied) return withCors(denied, cors);
  if (!env.ASSEMBLYAI_API_KEY) {
    return jsonResponse(503, { error: 'token broker not configured' }, cors);
  }
  if (rateLimited(request.headers.get('Authorization') ?? 'anonymous')) {
    return jsonResponse(429, { error: 'rate limited' }, cors);
  }

  const requestId = crypto.randomUUID();
  let upstream;
  try {
    upstream = await fetchImpl(
      `${TOKEN_ENDPOINT}?expires_in_seconds=${TOKEN_TTL_SECONDS}`,
      {
        headers: { 'Authorization': env.ASSEMBLYAI_API_KEY },
        signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
      },
    );
  } catch {
    console.log(JSON.stringify({ requestId, event: 'token_upstream_error' }));
    return jsonResponse(503, { error: 'token service unreachable' }, cors);
  }

  if (!upstream.ok) {
    console.log(JSON.stringify({
      requestId, event: 'token_upstream_rejected', status: upstream.status,
    }));
    // Auth failure vs provider failure are indistinguishable to the
    // client on purpose — raw provider detail never crosses out.
    return jsonResponse(502, { error: 'token mint failed' }, cors);
  }

  let data;
  try {
    data = await upstream.json();
  } catch {
    return jsonResponse(502, { error: 'token mint failed' }, cors);
  }

  const token = data?.token;
  if (typeof token !== 'string' || !token) {
    console.log(JSON.stringify({
      requestId, event: 'token_upstream_malformed',
    }));
    return jsonResponse(502, { error: 'token mint failed' }, cors);
  }

  console.log(JSON.stringify({ requestId, event: 'token_minted' }));
  return jsonResponse(
    200,
    { token, expires_in_seconds: TOKEN_TTL_SECONDS },
    cors,
  );
}

/**
 * Routes /aai-token requests. Returns null when the path is not a
 * token route so the caller can fall through to other handlers.
 */
export async function handleTokenRequest(request, env, fetchImpl, cors) {
  const url = new URL(request.url);
  if (
    (request.method === 'GET' || request.method === 'POST') &&
    url.pathname === '/aai-token'
  ) {
    return noStore(await mintToken(request, env, fetchImpl, cors));
  }
  if (url.pathname === '/aai-token' || url.pathname.startsWith('/aai-token/')) {
    return noStore(jsonResponse(404, { error: 'not found' }, cors));
  }
  return null;
}
