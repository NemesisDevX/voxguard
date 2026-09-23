import { test } from 'node:test';
import assert from 'node:assert/strict';

import { handleRequest } from '../src/relay.js';
import { MAX_TRANSCRIPT_CHARS } from '../src/semantic.js';

const ENV = {
  RELAY_CLIENT_TOKEN: 'relay-tok',
  GROQ_API_KEY: 'groq-secret-key',
  ALLOWED_ORIGINS: 'https://nemesisdevx.github.io,http://localhost',
};

const GOOD_SIGNALS = {
  urgency_score: 0.9,
  financial_demand_score: 0.7,
  secrecy_score: 0.4,
  detected_keywords: ['urgent', 'wire'],
  impersonation_claims: ['i am your son'],
};

function semanticRequest(body, { auth = 'Bearer relay-tok' } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth !== null) headers['Authorization'] = auth;
  return new Request('https://relay.test/semantic', {
    method: 'POST',
    headers,
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
}

/** Fake Groq chat-completions endpoint. */
function groqFetch(calls, { signals = GOOD_SIGNALS, status = 200, raw } = {}) {
  return async (url, init = {}) => {
    calls.push({ url, init });
    const content = raw !== undefined ? raw : JSON.stringify(signals);
    return new Response(
      JSON.stringify({ choices: [{ message: { content } }] }),
      { status },
    );
  };
}

// ── Auth boundary ──────────────────────────────────────────────────

test('semantic analysis requires relay authorization', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hello' }, { auth: null }),
    ENV,
    groqFetch([]),
  );
  assert.equal(res.status, 401);
});

test('wrong relay token → 401', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hello' }, { auth: 'Bearer wrong' }),
    ENV,
    groqFetch([]),
  );
  assert.equal(res.status, 401);
});

test('missing relay token env → 503', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }),
    { GROQ_API_KEY: 'k' },
    groqFetch([]),
  );
  assert.equal(res.status, 503);
});

// ── Request validation ─────────────────────────────────────────────

test('malformed JSON → 400', async () => {
  const res = await handleRequest(
    semanticRequest('{oops'), ENV, groqFetch([]),
  );
  assert.equal(res.status, 400);
});

test('missing/empty transcript → 400, provider never called', async () => {
  const calls = [];
  for (const body of [{}, { transcript: '' }, { transcript: '   ' },
    { transcript: 42 }]) {
    const res = await handleRequest(semanticRequest(body), ENV, groqFetch(calls));
    assert.equal(res.status, 400);
  }
  assert.equal(calls.length, 0);
});

test('oversized transcript → 400', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'x'.repeat(MAX_TRANSCRIPT_CHARS + 1) }),
    ENV,
    groqFetch([]),
  );
  assert.equal(res.status, 400);
});

// ── Happy path ─────────────────────────────────────────────────────

test('valid transcript → Groq call with Bearer key + strict JSON out',
  async () => {
    const calls = [];
    const res = await handleRequest(
      semanticRequest({ transcript: 'send money now' }),
      ENV,
      groqFetch(calls),
    );
    assert.equal(res.status, 200);
    const body = await res.json();
    assert.deepEqual(body, GOOD_SIGNALS);

    const up = calls.find((c) =>
      c.url === 'https://api.groq.com/openai/v1/chat/completions');
    assert.ok(up);
    assert.equal(up.init.headers['Authorization'], 'Bearer groq-secret-key');
    const sent = JSON.parse(up.init.body);
    assert.equal(sent.model, 'llama-3.3-70b-versatile');
    assert.equal(sent.temperature, 0);
    assert.deepEqual(sent.response_format, { type: 'json_object' });
    // Transcript reaches the provider as the user message only.
    assert.equal(sent.messages.at(-1).role, 'user');
    assert.equal(sent.messages.at(-1).content, 'send money now');
  });

test('permanent Groq key never appears in the response', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV, groqFetch([]),
  );
  const text = await res.text();
  assert.ok(!text.includes('groq-secret-key'));
});

test('out-of-range scores are clamped into 0..1', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }),
    ENV,
    groqFetch([], {
      signals: { ...GOOD_SIGNALS, urgency_score: 7, secrecy_score: -2 },
    }),
  );
  const body = await res.json();
  assert.equal(body.urgency_score, 1);
  assert.equal(body.secrecy_score, 0);
});

// ── Provider failure / malformed output → safe 502/503 ─────────────

test('provider non-2xx → 502', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    groqFetch([], { status: 500 }),
  );
  assert.equal(res.status, 502);
  assert.equal((await res.json()).error, 'semantic analysis failed');
});

test('provider unreachable → 503', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    async () => { throw new Error('dns fail'); },
  );
  assert.equal(res.status, 503);
});

test('malformed provider envelope → 502', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    async () => new Response(JSON.stringify({ nope: 1 }), { status: 200 }),
  );
  assert.equal(res.status, 502);
});

test('provider returns non-JSON content → 502', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    groqFetch([], { raw: 'not json at all' }),
  );
  assert.equal(res.status, 502);
});

test('provider JSON missing required score fields → 502', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    groqFetch([], { signals: { detected_keywords: [] } }),
  );
  assert.equal(res.status, 502);
});

test('non-numeric score field → 502', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    groqFetch([], { signals: { ...GOOD_SIGNALS, urgency_score: 'high' } }),
  );
  assert.equal(res.status, 502);
});

test('non-string entries are filtered from keyword/claim lists', async () => {
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }), ENV,
    groqFetch([], {
      signals: {
        ...GOOD_SIGNALS,
        detected_keywords: ['ok', 5, null],
        impersonation_claims: 'not-a-list',
      },
    }),
  );
  const body = await res.json();
  assert.deepEqual(body.detected_keywords, ['ok']);
  assert.deepEqual(body.impersonation_claims, []);
});

test('missing GROQ_API_KEY → 503, upstream never called', async () => {
  const calls = [];
  const res = await handleRequest(
    semanticRequest({ transcript: 'hi' }),
    { RELAY_CLIENT_TOKEN: 'relay-tok' },
    groqFetch(calls),
  );
  assert.equal(res.status, 503);
  assert.equal(calls.length, 0);
});

// ── Rate limiting ──────────────────────────────────────────────────

test('semantic analyses are rate-limited per bearer token', async () => {
  const auth = 'Bearer sem-flood';
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'sem-flood' };
  let last;
  for (let i = 0; i < 31; i++) {
    last = await handleRequest(
      semanticRequest({ transcript: 'hi' }, { auth }), env, groqFetch([]),
    );
  }
  assert.equal(last.status, 429);
});
