import { test } from 'node:test';
import assert from 'node:assert/strict';

import { handleRequest } from '../src/relay.js';
import { MAX_AUDIO_BYTES } from '../src/transcription.js';

const ENV = {
  RELAY_CLIENT_TOKEN: 'relay-tok',
  ASSEMBLYAI_API_KEY: 'aai-secret-key',
  ALLOWED_ORIGINS: 'https://nemesisdevx.github.io,http://localhost',
};

function jobRequest(body, { auth = 'Bearer relay-tok', format = 'mp3' } = {}) {
  const headers = { 'Content-Type': 'application/octet-stream' };
  if (auth !== null) headers['Authorization'] = auth;
  if (format !== null) headers['X-Audio-Format'] = format;
  return new Request('https://relay.test/transcription/jobs', {
    method: 'POST',
    headers,
    body,
  });
}

function pollRequest(id, { auth = 'Bearer relay-tok' } = {}) {
  const headers = {};
  if (auth !== null) headers['Authorization'] = auth;
  return new Request(`https://relay.test/transcription/jobs/${id}`, {
    method: 'GET',
    headers,
  });
}

/** Fake AssemblyAI: upload → upload_url; submit → id; poll → status. */
function aaiFetch(calls, { transcriptStatus = 'completed', text = 'hi' } = {}) {
  return async (url, init = {}) => {
    calls.push({ url, init });
    if (url.endsWith('/upload')) {
      return new Response(
        JSON.stringify({ upload_url: 'https://aai.example/up-1' }),
        { status: 200 },
      );
    }
    if (url.endsWith('/transcript') && init.method === 'POST') {
      return new Response(
        JSON.stringify({ id: 'aai-job-42', status: 'queued' }),
        { status: 200 },
      );
    }
    const m = url.match(/\/transcript\/([^/]+)$/);
    if (m) {
      const body = { status: transcriptStatus };
      if (transcriptStatus === 'completed') body.text = text;
      return new Response(JSON.stringify(body), { status: 200 });
    }
    return new Response('not found', { status: 404 });
  };
}

// ── Auth boundary ──────────────────────────────────────────────────

test('transcription job creation requires relay authorization', async () => {
  const res = await handleRequest(
    jobRequest(new Uint8Array([1, 2, 3]), { auth: null }),
    ENV,
    aaiFetch([]),
  );
  assert.equal(res.status, 401);
});

test('transcription poll requires relay authorization', async () => {
  const res = await handleRequest(
    pollRequest('aai-job-42', { auth: null }),
    ENV,
    aaiFetch([]),
  );
  assert.equal(res.status, 401);
});

test('provider key never ships to the client', async () => {
  const calls = [];
  const res = await handleRequest(
    jobRequest(new Uint8Array([1, 2, 3])),
    ENV,
    aaiFetch(calls),
  );
  const body = await res.text();
  assert.ok(!body.includes('aai-secret-key'));
  // Provider URL is used server-side with the key in the header.
  const upload = calls.find((c) => c.url.endsWith('/upload'));
  assert.equal(upload.init.headers['Authorization'], 'aai-secret-key');
});

// ── Request validation ─────────────────────────────────────────────

test('oversized audio is rejected before reaching the provider',
    async () => {
  const calls = [];
  // Over the cap — rejected whether caught on Content-Length or the
  // post-read size check.
  const res = await handleRequest(
    jobRequest(new Uint8Array(MAX_AUDIO_BYTES + 1), { format: null }),
    { ...ENV },
    aaiFetch(calls),
  );
  assert.equal(res.status, 413);
  assert.equal(calls.length, 0);
});

test('empty audio body is rejected', async () => {
  const res = await handleRequest(
    jobRequest(new Uint8Array(0)),
    ENV,
    aaiFetch([]),
  );
  assert.equal(res.status, 400);
});

test('malformed format hint is rejected', async () => {
  const res = await handleRequest(
    jobRequest(new Uint8Array([1]), { format: 'evil/../..fmt' }),
    ENV,
    aaiFetch([]),
  );
  assert.equal(res.status, 400);
});

// ── Upload → submit contract ───────────────────────────────────────

test('job creation uploads bytes then submits the transcript job', async () => {
  const calls = [];
  const audio = new Uint8Array([9, 8, 7, 6]);
  const res = await handleRequest(
    jobRequest(audio),
    ENV,
    aaiFetch(calls),
  );
  assert.equal(res.status, 202);
  const { job_id } = await res.json();
  assert.equal(job_id, 'aai-job-42');

  const [upload, submit] = calls;
  // Upload carries the raw audio bytes.
  assert.equal(upload.url, 'https://api.assemblyai.com/v2/upload');
  assert.equal(upload.init.method, 'POST');
  assert.deepEqual(new Uint8Array(upload.init.body), audio);
  // Submit carries the provider upload_url + current model family.
  assert.equal(submit.url, 'https://api.assemblyai.com/v2/transcript');
  const submitBody = JSON.parse(submit.init.body);
  assert.equal(submitBody.audio_url, 'https://aai.example/up-1');
  assert.deepEqual(submitBody.speech_models,
    ['universal-3-5-pro', 'universal-2']);
  assert.equal(submitBody.language_detection, true);
});

// ── Poll contract ──────────────────────────────────────────────────

test('poll maps provider statuses onto the compact vocabulary', async () => {
  for (const [provider, expected] of [
    ['queued', 'queued'],
    ['processing', 'processing'],
    ['completed', 'completed'],
    ['error', 'error'],
  ]) {
    const res = await handleRequest(
      pollRequest('aai-job-42'),
      ENV,
      aaiFetch([], { transcriptStatus: provider, text: 'secret' }),
    );
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.equal(body.status, expected);
    // Transcript text only travels on completed.
    if (expected === 'completed') assert.equal(body.text, 'secret');
    else assert.equal(body.text, undefined);
  }
});

test('invalid job id is rejected without hitting the provider', async () => {
  const calls = [];
  const res = await handleRequest(
    pollRequest('bad%20id!'),
    ENV,
    aaiFetch(calls),
  );
  // Matches the route shape but fails the conservative id charset.
  assert.equal(res.status, 400);
  assert.equal(calls.length, 0);
});

test('provider upload failure → 502, never leaks provider detail', async () => {
  const res = await handleRequest(
    jobRequest(new Uint8Array([1])),
    ENV,
    async () => new Response('provider secret detail', { status: 500 }),
  );
  assert.equal(res.status, 502);
  const body = await res.text();
  assert.ok(!body.includes('provider secret detail'));
});

test('missing provider key → 503, client never sees why', async () => {
  const res = await handleRequest(
    jobRequest(new Uint8Array([1])),
    { ...ENV, ASSEMBLYAI_API_KEY: undefined },
    aaiFetch([]),
  );
  assert.equal(res.status, 503);
});
