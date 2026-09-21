/**
 * VoxGuard prerecorded-transcription relay — server-side proxy to the
 * configured speech-to-text provider (AssemblyAI).
 *
 * The provider API key lives ONLY in server-side env vars
 * (`ASSEMBLYAI_API_KEY`); the Flutter client authenticates with the
 * same shared relay token as Family Shield — abuse resistance, not
 * strong user authentication.
 *
 * AssemblyAI prerecorded contract (verified against the current
 * official docs):
 *   POST https://api.assemblyai.com/v2/upload
 *     Authorization: <key>  ·  body: raw audio bytes
 *     → { upload_url }
 *   POST https://api.assemblyai.com/v2/transcript
 *     { audio_url, speech_models: ["universal-3-5-pro","universal-2"],
 *       language_detection: true }
 *     → { id, status }
 *   GET https://api.assemblyai.com/v2/transcript/{id}
 *     → { status: queued|processing|completed|error, text }
 *
 * Privacy boundary: this module NEVER logs recording bytes,
 * transcript text, filenames, upload URLs, names, or phone numbers.
 * Operational logs carry requestId + status + byte count only.
 * Nothing is persisted — the provider job id is the opaque reference.
 */

const ASSEMBLYAI_BASE = 'https://api.assemblyai.com/v2';

// Mirrors the client cap — the recording is proxied in memory.
export const MAX_AUDIO_BYTES = 25 * 1024 * 1024; // 25 MB

// Job ids are provider UUIDs — conservative charset guard.
const JOB_ID = /^[A-Za-z0-9_\-]{1,64}$/;

// `X-Audio-Format` is a minimal decoder hint (e.g. `mp3`) — a few
// chars only, never a filename.
const FORMAT_HINT = /^[a-z0-9]{1,12}$/;

const UPLOAD_TIMEOUT_MS = 30_000;
const API_TIMEOUT_MS = 15_000;

function jsonResponse(status, body, extraHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...extraHeaders },
  });
}

/**
 * Shared relay auth — same `RELAY_CLIENT_TOKEN` boundary as /alert.
 * Returns null when authorized, else the error Response.
 */
export function checkRelayAuth(request, env) {
  const expected = env.RELAY_CLIENT_TOKEN;
  if (!expected) {
    return jsonResponse(503, { error: 'relay not configured' });
  }
  const auth = request.headers.get('Authorization') ?? '';
  if (auth !== `Bearer ${expected}`) {
    return jsonResponse(401, { error: 'unauthorized' });
  }
  return null;
}

/** POST /transcription/jobs — upload → submit → opaque job id. */
async function createJob(request, env, fetchImpl, cors) {
  const denied = checkRelayAuth(request, env);
  if (denied) return withCors(denied, cors);
  if (!env.ASSEMBLYAI_API_KEY) {
    return jsonResponse(503, { error: 'transcription not configured' }, cors);
  }

  // Reject obviously oversized uploads from Content-Length before
  // buffering the body.
  const declared = Number(request.headers.get('Content-Length') ?? 0);
  if (declared > MAX_AUDIO_BYTES) {
    return jsonResponse(413, { error: 'audio too large' }, cors);
  }

  const format = (request.headers.get('X-Audio-Format') ?? '')
    .toLowerCase();
  if (format && !FORMAT_HINT.test(format)) {
    return jsonResponse(400, { error: 'invalid format hint' }, cors);
  }

  let audio;
  try {
    audio = await request.arrayBuffer();
  } catch {
    return jsonResponse(400, { error: 'malformed request body' }, cors);
  }
  if (!audio || audio.byteLength === 0) {
    return jsonResponse(400, { error: 'empty audio body' }, cors);
  }
  if (audio.byteLength > MAX_AUDIO_BYTES) {
    return jsonResponse(413, { error: 'audio too large' }, cors);
  }

  const requestId = crypto.randomUUID();
  const byteCount = audio.byteLength;

  // 1 · Upload raw bytes → provider upload_url (never logged).
  let uploadUrl;
  try {
    const up = await fetchImpl(`${ASSEMBLYAI_BASE}/upload`, {
      method: 'POST',
      headers: {
        'Authorization': env.ASSEMBLYAI_API_KEY,
        'Content-Type': 'application/octet-stream',
      },
      body: audio,
      signal: AbortSignal.timeout(UPLOAD_TIMEOUT_MS),
    });
    if (!up.ok) {
      console.log(JSON.stringify({
        requestId, event: 'provider_upload_rejected',
        status: up.status, byteCount,
      }));
      return jsonResponse(502, { error: 'transcription upload failed' }, cors);
    }
    const data = await up.json();
    if (typeof data?.upload_url !== 'string' || !data.upload_url) {
      throw new Error('missing upload_url');
    }
    uploadUrl = data.upload_url;
  } catch {
    console.log(JSON.stringify({
      requestId, event: 'provider_upload_error', byteCount,
    }));
    return jsonResponse(502, { error: 'transcription upload failed' }, cors);
  }

  // 2 · Submit transcript job → opaque provider job id.
  try {
    const res = await fetchImpl(`${ASSEMBLYAI_BASE}/transcript`, {
      method: 'POST',
      headers: {
        'Authorization': env.ASSEMBLYAI_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        audio_url: uploadUrl,
        // Current documented model family + fallback; automatic
        // language detection covers English and Arabic.
        speech_models: ['universal-3-5-pro', 'universal-2'],
        language_detection: true,
      }),
      signal: AbortSignal.timeout(API_TIMEOUT_MS),
    });
    if (!res.ok) {
      console.log(JSON.stringify({
        requestId, event: 'provider_submit_rejected',
        status: res.status, byteCount,
      }));
      return jsonResponse(502, { error: 'transcription submit failed' }, cors);
    }
    const data = await res.json();
    if (typeof data?.id !== 'string' || !data.id) {
      throw new Error('missing job id');
    }
    console.log(JSON.stringify({
      requestId, event: 'job_created', byteCount,
    }));
    return jsonResponse(202, { job_id: data.id }, cors);
  } catch {
    console.log(JSON.stringify({
      requestId, event: 'provider_submit_error', byteCount,
    }));
    return jsonResponse(502, { error: 'transcription submit failed' }, cors);
  }
}

/** GET /transcription/jobs/{id} — compact VoxGuard status only. */
async function pollJob(request, env, fetchImpl, cors, jobId) {
  const denied = checkRelayAuth(request, env);
  if (denied) return withCors(denied, cors);
  if (!env.ASSEMBLYAI_API_KEY) {
    return jsonResponse(503, { error: 'transcription not configured' }, cors);
  }
  if (!JOB_ID.test(jobId)) {
    return jsonResponse(400, { error: 'invalid job id' }, cors);
  }

  const requestId = crypto.randomUUID();
  let res;
  try {
    res = await fetchImpl(`${ASSEMBLYAI_BASE}/transcript/${jobId}`, {
      headers: { 'Authorization': env.ASSEMBLYAI_API_KEY },
      signal: AbortSignal.timeout(API_TIMEOUT_MS),
    });
  } catch {
    console.log(JSON.stringify({
      requestId, event: 'provider_poll_error',
    }));
    return jsonResponse(502, { error: 'transcription poll failed' }, cors);
  }
  if (!res.ok) {
    console.log(JSON.stringify({
      requestId, event: 'provider_poll_rejected', status: res.status,
    }));
    return jsonResponse(502, { error: 'transcription poll failed' }, cors);
  }

  let data;
  try {
    data = await res.json();
  } catch {
    return jsonResponse(502, { error: 'transcription poll failed' }, cors);
  }

  // Map provider status onto the compact VoxGuard vocabulary — raw
  // provider error bodies never reach the client.
  const status = data?.status;
  console.log(JSON.stringify({
    requestId, event: 'provider_poll_status', providerStatus: status,
  }));
  switch (status) {
    case 'queued':
      return jsonResponse(200, { status: 'queued' }, cors);
    case 'processing':
      return jsonResponse(200, { status: 'processing' }, cors);
    case 'completed': {
      const text = typeof data.text === 'string' ? data.text : '';
      return jsonResponse(200, { status: 'completed', text }, cors);
    }
    default:
      // 'error' and anything unexpected → compact failure.
      return jsonResponse(200, { status: 'error' }, cors);
  }
}

function withCors(response, cors) {
  for (const [k, v] of Object.entries(cors)) {
    response.headers.set(k, v);
  }
  return response;
}

/**
 * Routes /transcription/* requests. Returns null when the path is not
 * a transcription route so the caller can fall through to other
 * handlers.
 */
export async function handleTranscriptionRequest(
  request, env, fetchImpl, cors,
) {
  const url = new URL(request.url);
  if (request.method === 'POST' && url.pathname === '/transcription/jobs') {
    return createJob(request, env, fetchImpl, cors);
  }
  const match = url.pathname.match(/^\/transcription\/jobs\/([^/]+)$/);
  if (request.method === 'GET' && match) {
    return pollJob(request, env, fetchImpl, cors, match[1]);
  }
  if (url.pathname.startsWith('/transcription/')) {
    return jsonResponse(404, { error: 'not found' }, cors);
  }
  return null;
}
