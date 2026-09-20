import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  handleRequest,
  validateAlertPayload,
  toOneSignalPayload,
  MAX_RECIPIENTS,
} from '../src/relay.js';

const ENV = {
  ONESIGNAL_APP_ID: 'test-app-id',
  ONESIGNAL_REST_API_KEY: 'test-rest-key',
  RELAY_CLIENT_TOKEN: 'relay-tok',
  ALLOWED_ORIGINS: 'https://nemesisdevx.github.io,http://localhost',
};

function alertRequest(body, { auth = 'Bearer relay-tok', origin } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth !== null) headers['Authorization'] = auth;
  if (origin) headers['Origin'] = origin;
  return new Request('https://relay.test/alert', {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
}

const VALID_BODY = {
  kind: 'family_shield_alert',
  incident_id: 'INC-2026-9001',
  risk_level: 'highRisk',
  family_external_ids: ['fam_maya', 'fam_omar'],
  title: 'VoxGuard Family Shield',
  body: 'A high-risk call was flagged.',
};

function okFetch(captured) {
  return async (url, init) => {
    captured.url = url;
    captured.init = init;
    return new Response(JSON.stringify({ id: 'notif-1' }), {
      status: 200,
    });
  };
}

// ── Happy path ───────────────────────────────────────────────────────

test('valid alert → 202 + correct OneSignal payload + Key auth', async () => {
  const captured = {};
  const res = await handleRequest(
    alertRequest(VALID_BODY),
    ENV,
    okFetch(captured),
  );
  assert.equal(res.status, 202);

  const { url, init } = captured;
  assert.equal(url, 'https://api.onesignal.com/notifications');
  assert.equal(init.method, 'POST');
  assert.equal(
    init.headers['Authorization'],
    'Key test-rest-key',
  );

  const payload = JSON.parse(init.body);
  assert.equal(payload.app_id, 'test-app-id');
  assert.deepEqual(payload.include_aliases, {
    external_id: ['fam_maya', 'fam_omar'],
  });
  assert.equal(payload.target_channel, 'push');
  assert.deepEqual(payload.headings, { en: 'VoxGuard Family Shield' });
  assert.deepEqual(payload.contents, { en: 'A high-risk call was flagged.' });
  assert.deepEqual(payload.data, {
    kind: 'family_shield_alert',
    incident_id: 'INC-2026-9001',
    risk_level: 'highRisk',
  });
});

test('notification payload carries no audio/transcript fields', async () => {
  const captured = {};
  await handleRequest(
    alertRequest({ ...VALID_BODY, transcript: 'secret', audio: 'raw' }),
    ENV,
    okFetch(captured),
  );
  const payload = JSON.parse(captured.init.body);
  const flat = JSON.stringify(payload);
  assert.equal(payload.transcript, undefined);
  assert.equal(payload.audio, undefined);
  assert.ok(!flat.includes('secret'));
});

// ── Validation rejections ────────────────────────────────────────────

test('empty recipient list → 400', async () => {
  const res = await handleRequest(
    alertRequest({ ...VALID_BODY, family_external_ids: [] }),
    ENV,
    okFetch({}),
  );
  assert.equal(res.status, 400);
});

test(`more than ${MAX_RECIPIENTS} recipients → 400`, async () => {
  const res = await handleRequest(
    alertRequest({
      ...VALID_BODY,
      family_external_ids: Array.from({ length: 6 }, (_, i) => `f${i}`),
    }),
    ENV,
    okFetch({}),
  );
  assert.equal(res.status, 400);
});

test('invalid risk level → 400', async () => {
  const res = await handleRequest(
    alertRequest({ ...VALID_BODY, risk_level: 'extreme' }),
    ENV,
    okFetch({}),
  );
  assert.equal(res.status, 400);
});

test('malformed incident_id → 400', async () => {
  for (const bad of ['', 'x'.repeat(65), 'INC <script>', 42]) {
    const res = await handleRequest(
      alertRequest({ ...VALID_BODY, incident_id: bad }),
      ENV,
      okFetch({}),
    );
    assert.equal(res.status, 400, `incident_id=${bad}`);
  }
});

test('unsafe recipient id → 400', async () => {
  const res = await handleRequest(
    alertRequest({ ...VALID_BODY, family_external_ids: ['bad id!'] }),
    ENV,
    okFetch({}),
  );
  assert.equal(res.status, 400);
});

test('malformed JSON → 400', async () => {
  const req = new Request('https://relay.test/alert', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer relay-tok',
    },
    body: '{not json',
  });
  const res = await handleRequest(req, ENV, okFetch({}));
  assert.equal(res.status, 400);
});

// ── Auth boundary ────────────────────────────────────────────────────

test('missing / wrong relay token → 401', async () => {
  for (const auth of [null, 'Bearer wrong', 'Basic abc']) {
    const res = await handleRequest(
      alertRequest(VALID_BODY, { auth }),
      ENV,
      okFetch({}),
    );
    assert.equal(res.status, 401, `auth=${auth}`);
  }
});

// ── Upstream mapping ─────────────────────────────────────────────────

test('OneSignal non-2xx → 502, no credential leak in response', async () => {
  const res = await handleRequest(
    alertRequest(VALID_BODY),
    ENV,
    async () => new Response('{"errors":["bad"]}', { status: 400 }),
  );
  assert.equal(res.status, 502);
  const text = await res.text();
  assert.ok(!text.includes('test-rest-key'));
  assert.ok(!text.includes('Authorization'));
});

test('upstream network failure → 503', async () => {
  const res = await handleRequest(
    alertRequest(VALID_BODY),
    ENV,
    async () => {
      throw new Error('socket hangup');
    },
  );
  assert.equal(res.status, 503);
});

// ── CORS ─────────────────────────────────────────────────────────────

test('allowed origin gets CORS header; disallowed origin does not', async () => {
  const allowed = await handleRequest(
    alertRequest(VALID_BODY, {
      origin: 'https://nemesisdevx.github.io',
    }),
    ENV,
    okFetch({}),
  );
  assert.equal(
    allowed.headers.get('Access-Control-Allow-Origin'),
    'https://nemesisdevx.github.io',
  );

  const denied = await handleRequest(
    alertRequest(VALID_BODY, { origin: 'https://evil.example.com' }),
    ENV,
    okFetch({}),
  );
  assert.equal(
    denied.headers.get('Access-Control-Allow-Origin'),
    null,
  );
});

test('OPTIONS preflight → 204 with CORS headers', async () => {
  const res = await handleRequest(
    new Request('https://relay.test/alert', {
      method: 'OPTIONS',
      headers: { 'Origin': 'http://localhost:8080' },
    }),
    ENV,
    okFetch({}),
  );
  assert.equal(res.status, 204);
  assert.equal(
    res.headers.get('Access-Control-Allow-Origin'),
    'http://localhost:8080',
  );
});

test('CORS rejects lookalike origins that prefix-match allowlist '
    + 'entries', async () => {
  const lookalikes = [
    'http://localhost.evil.com',
    'http://localhost:8080.evil.com',
    'https://nemesisdevx.github.io.evil.com',
    'https://evil-nemesisdevx.github.io',
    'http://localhostx:8080',
    'https://nemesisdevx.github.io.attacker.dev',
    'not a url',
    'http://localhost:evil',
    // Production hosts must match the allowlisted origin exactly —
    // an unexpected port is not covered by a port-less entry.
    'https://nemesisdevx.github.io:8443',
    'http://nemesisdevx.github.io',
  ];
  for (const origin of lookalikes) {
    const res = await handleRequest(
      alertRequest(VALID_BODY, { origin }),
      ENV,
      okFetch({}),
    );
    assert.equal(
      res.headers.get('Access-Control-Allow-Origin'),
      null,
      `origin=${origin} must not receive CORS`,
    );
  }
});

test('duplicate recipients are deduped before forwarding', async () => {
  const captured = {};
  await handleRequest(
    alertRequest({
      ...VALID_BODY,
      family_external_ids: ['vg_a', 'vg_a', 'vg_b'],
    }),
    ENV,
    okFetch(captured),
  );
  const payload = JSON.parse(captured.init.body);
  assert.deepEqual(payload.include_aliases.external_id, ['vg_a', 'vg_b']);
});

test('recipients surviving dedupe still respect the cap', async () => {
  // 6 ids where dedupe leaves 5 → accepted.
  const ok = await handleRequest(
    alertRequest({
      ...VALID_BODY,
      family_external_ids: ['a1', 'a1', 'a2', 'a3', 'a4', 'a5'],
    }),
    ENV,
    okFetch({}),
  );
  // Still 400: cap applies to the request as sent, pre-dedupe —
  // a caller submitting 6 ids is a malformed request regardless.
  assert.equal(ok.status, 400);
});

// ── Unit-level validation ────────────────────────────────────────────

test('validateAlertPayload accepts the documented shape', () => {
  const r = validateAlertPayload(VALID_BODY);
  assert.equal(r.ok, true);
  assert.equal(r.value.recipients.length, 2);
});

test('toOneSignalPayload uses external_id aliases + target_channel', () => {
  const p = toOneSignalPayload(
    validateAlertPayload(VALID_BODY).value,
    'app-1',
  );
  assert.equal(p.target_channel, 'push');
  assert.ok(Array.isArray(p.include_aliases.external_id));
});
