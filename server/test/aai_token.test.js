import { test } from 'node:test';
import assert from 'node:assert/strict';

import { handleRequest } from '../src/relay.js';
import { TOKEN_TTL_SECONDS } from '../src/aai_token.js';

const ENV = {
  RELAY_CLIENT_TOKEN: 'relay-tok',
  ASSEMBLYAI_API_KEY: 'aai-secret-key',
  ALLOWED_ORIGINS: 'https://nemesisdevx.github.io,http://localhost',
};

function tokenRequest({ auth = 'Bearer relay-tok', method = 'GET' } = {}) {
  const headers = {};
  if (auth !== null) headers['Authorization'] = auth;
  return new Request('https://relay.test/aai-token', { method, headers });
}

/** Fake AssemblyAI streaming-token endpoint. */
function tokenFetch(calls, { token = 'tmp-stream-token', status = 200 } = {}) {
  return async (url, init = {}) => {
    calls.push({ url, init });
    if (url.startsWith('https://streaming.assemblyai.com/v3/token')) {
      return new Response(JSON.stringify({ token }), { status });
    }
    return new Response('not found', { status: 404 });
  };
}

// ── Auth boundary ──────────────────────────────────────────────────

test('token mint requires relay authorization', async () => {
  const res = await handleRequest(
    tokenRequest({ auth: null }), ENV, tokenFetch([]),
  );
  assert.equal(res.status, 401);
});

test('wrong relay token → 401', async () => {
  const res = await handleRequest(
    tokenRequest({ auth: 'Bearer wrong' }), ENV, tokenFetch([]),
  );
  assert.equal(res.status, 401);
});

test('missing relay token env → 503 relay not configured', async () => {
  const res = await handleRequest(
    tokenRequest(), { ASSEMBLYAI_API_KEY: 'k' }, tokenFetch([]),
  );
  assert.equal(res.status, 503);
});

// ── Happy path ─────────────────────────────────────────────────────

test('GET mints a short-lived token via the documented endpoint', async () => {
  const calls = [];
  const res = await handleRequest(tokenRequest(), ENV, tokenFetch(calls));
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.token, 'tmp-stream-token');
  assert.equal(body.expires_in_seconds, TOKEN_TTL_SECONDS);

  // Upstream call hits the documented streaming-token URL with the
  // permanent key in the Authorization header — server-side only.
  const up = calls.find((c) =>
    c.url.startsWith('https://streaming.assemblyai.com/v3/token'));
  assert.ok(up);
  assert.ok(up.url.includes(`expires_in_seconds=${TOKEN_TTL_SECONDS}`));
  assert.equal(up.init.headers['Authorization'], 'aai-secret-key');
});

test('POST also mints (same contract)', async () => {
  const res = await handleRequest(
    tokenRequest({ method: 'POST' }), ENV, tokenFetch([]),
  );
  assert.equal(res.status, 200);
  assert.equal((await res.json()).token, 'tmp-stream-token');
});

test('permanent provider key never appears in the response', async () => {
  const res = await handleRequest(tokenRequest(), ENV, tokenFetch([]));
  const text = await res.text();
  assert.ok(!text.includes('aai-secret-key'));
});

test('successful token response is Cache-Control: no-store', async () => {
  const res = await handleRequest(tokenRequest(), ENV, tokenFetch([]));
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('Cache-Control'), 'no-store');
});

test('no-store applies to error responses on the token route too',
  async () => {
    const res = await handleRequest(
      tokenRequest({ auth: null }), ENV, tokenFetch([]),
    );
    assert.equal(res.status, 401);
    assert.equal(res.headers.get('Cache-Control'), 'no-store');
  });

// ── Provider failure mapping ───────────────────────────────────────

test('provider non-2xx → 502 with no provider detail', async () => {
  const res = await handleRequest(
    tokenRequest(), ENV,
    tokenFetch([], { status: 401 }),
  );
  assert.equal(res.status, 502);
  const body = await res.json();
  assert.equal(body.error, 'token mint failed');
});

test('provider unreachable → 503', async () => {
  const res = await handleRequest(
    tokenRequest(), ENV,
    async () => { throw new Error('network down'); },
  );
  assert.equal(res.status, 503);
  assert.equal((await res.json()).error, 'token service unreachable');
});

test('malformed provider body (missing token) → 502', async () => {
  const res = await handleRequest(
    tokenRequest(), ENV,
    async () => new Response(JSON.stringify({ nope: 1 }), { status: 200 }),
  );
  assert.equal(res.status, 502);
});

test('non-JSON provider body → 502', async () => {
  const res = await handleRequest(
    tokenRequest(), ENV,
    async () => new Response('<html>', { status: 200 }),
  );
  assert.equal(res.status, 502);
});

test('missing ASSEMBLYAI_API_KEY → 503, upstream never called', async () => {
  const calls = [];
  const res = await handleRequest(
    tokenRequest(), { RELAY_CLIENT_TOKEN: 'relay-tok' }, tokenFetch(calls),
  );
  assert.equal(res.status, 503);
  assert.equal(calls.length, 0);
});

// ── Rate limiting ──────────────────────────────────────────────────

test('token mints are rate-limited per bearer token', async () => {
  const auth = 'Bearer mint-flood';
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'mint-flood' };
  let last;
  for (let i = 0; i < 21; i++) {
    last = await handleRequest(
      tokenRequest({ auth }), env, tokenFetch([]),
    );
  }
  assert.equal(last.status, 429);
});

// ── Routing ────────────────────────────────────────────────────────

test('unknown method on /aai-token → 404', async () => {
  const res = await handleRequest(
    new Request('https://relay.test/aai-token', {
      method: 'DELETE',
      headers: { 'Authorization': 'Bearer relay-tok' },
    }),
    ENV,
    tokenFetch([]),
  );
  assert.equal(res.status, 404);
});
