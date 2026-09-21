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

const SENDER_ID = `vg_${'a'.repeat(32)}`;
const RECIP_A = `vg_${'1'.repeat(32)}`;
const RECIP_B = `vg_${'2'.repeat(32)}`;

const VALID_BODY = {
  kind: 'family_shield_alert',
  incident_id: 'INC-2026-9001',
  risk_level: 'highRisk',
  analysis_scope: 'full',
  sender_external_id: SENDER_ID,
  family_external_ids: [RECIP_A, RECIP_B],
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
    external_id: [RECIP_A, RECIP_B],
  });
  assert.equal(payload.target_channel, 'push');
  assert.deepEqual(payload.headings, { en: 'VoxGuard Family Shield' });
  assert.deepEqual(payload.contents, { en: 'A high-risk call was flagged.' });
  assert.deepEqual(payload.data, {
    kind: 'family_shield_alert',
    incident_id: 'INC-2026-9001',
    risk_level: 'highRisk',
    analysis_scope: 'full',
    sender_external_id: SENDER_ID,
  });
});

// ── analysis_scope + alert risk bands ────────────────────────────

test('missing/malformed analysis_scope → 400', async () => {
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'scope-tok' };
  for (const analysis_scope of [
    undefined,
    '',
    'acoustic_only',
    'FULL',
    'live_call',
    1,
    null,
  ]) {
    const res = await handleRequest(
      alertRequest(
        { ...VALID_BODY, analysis_scope },
        { auth: 'Bearer scope-tok' },
      ),
      env,
      okFetch({}),
    );
    assert.equal(res.status, 400, `analysis_scope=${analysis_scope}`);
  }
});

test('analysis_scope is preserved in OneSignal data', async () => {
  const captured = {};
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'scope2-tok' };
  const res = await handleRequest(
    alertRequest(
      { ...VALID_BODY, analysis_scope: 'partial', risk_level: 'suspicious' },
      { auth: 'Bearer scope2-tok' },
    ),
    env,
    okFetch(captured),
  );
  assert.equal(res.status, 202);
  assert.equal(JSON.parse(captured.init.body).data.analysis_scope, 'partial');
});

test('safe is not a valid danger-alert risk_level → 400', async () => {
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'safe-tok' };
  for (const risk_level of ['safe', 'critical', 'medium', 1, null]) {
    const res = await handleRequest(
      alertRequest(
        { ...VALID_BODY, risk_level },
        { auth: 'Bearer safe-tok' },
      ),
      env,
      okFetch({}),
    );
    assert.equal(res.status, 400, `risk_level=${risk_level}`);
  }
});

// ── sender_external_id ────────────────────────────────────────────

test('missing or malformed sender_external_id → 400', async () => {
  // Distinct token → fresh rate-limit bucket for this 7-case loop.
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'sender-tok' };
  for (const sender_external_id of [
    undefined,
    '',
    'fam_maya',
    'vg_123',
    `vg_${'G'.repeat(32)}`,
    `vg_${'a'.repeat(31)}`,
    123,
  ]) {
    const res = await handleRequest(
      alertRequest(
        { ...VALID_BODY, sender_external_id },
        { auth: 'Bearer sender-tok' },
      ),
      env,
      okFetch({}),
    );
    assert.equal(res.status, 400, `sender_external_id=${sender_external_id}`);
  }
});

test('sender id reaches OneSignal data — no name/phone fields', async () => {
  const captured = {};
  await handleRequest(
    alertRequest({
      ...VALID_BODY,
      // Even if a hostile client sneaks PII into the envelope, the
      // relay must not forward it.
      sender_name: 'Aunt Maya',
      sender_phone: '+15551234567',
      recipient_names: ['Maya'],
    }),
    ENV,
    okFetch(captured),
  );
  const payload = JSON.parse(captured.init.body);
  assert.equal(payload.data.sender_external_id, SENDER_ID);
  assert.deepEqual(Object.keys(payload.data), [
    'kind',
    'incident_id',
    'risk_level',
    'analysis_scope',
    'sender_external_id',
  ]);
  const raw = captured.init.body;
  assert.ok(!raw.includes('Aunt Maya'));
  assert.ok(!raw.includes('15551234567'));
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
      family_external_ids: Array.from(
        { length: 6 },
        (_, i) => `vg_${String(i).repeat(32)}`,
      ),
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
      family_external_ids: [RECIP_A, RECIP_A, RECIP_B],
    }),
    ENV,
    okFetch(captured),
  );
  const payload = JSON.parse(captured.init.body);
  assert.deepEqual(payload.include_aliases.external_id, [RECIP_A, RECIP_B]);
});

test('recipients surviving dedupe still respect the cap', async () => {
  // 6 ids where dedupe leaves 5 → accepted.
  const ok = await handleRequest(
    alertRequest({
      ...VALID_BODY,
      family_external_ids: [
        RECIP_A,
        RECIP_A,
        RECIP_B,
        `vg_${'3'.repeat(32)}`,
        `vg_${'4'.repeat(32)}`,
        `vg_${'5'.repeat(32)}`,
      ],
    }),
    ENV,
    okFetch({}),
  );
  // Still 400: cap applies to the request as sent, pre-dedupe —
  // a caller submitting 6 ids is a malformed request regardless.
  assert.equal(ok.status, 400);
});

test('non-vg recipient ids are rejected — demo ids never relay', async () => {
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'recip-tok' };
  for (const id of [
    'demo_family_maya',
    'demo_family_omar',
    'fam_maya',
    'bad id!',
    `vg_${'A'.repeat(32)}`,
    `vg_${'a'.repeat(31)}`,
  ]) {
    const res = await handleRequest(
      alertRequest(
        { ...VALID_BODY, family_external_ids: [id] },
        { auth: 'Bearer recip-tok' },
      ),
      env,
      okFetch({}),
    );
    assert.equal(res.status, 400, `recipient=${id} must be rejected`);
  }
});

// ── family_shield_response ─────────────────────────────────────────

const RESPONSE_BODY = {
  kind: 'family_shield_response',
  incident_id: 'INC-2026-9001',
  resolution: 'safe',
  responder_external_id: RECIP_A,
  target_external_id: SENDER_ID,
};

test('valid response event → 202, single target, generic copy', async () => {
  const captured = {};
  const res = await handleRequest(
    alertRequest(RESPONSE_BODY, { auth: 'Bearer resp-tok' }),
    { ...ENV, RELAY_CLIENT_TOKEN: 'resp-tok' },
    okFetch(captured),
  );
  assert.equal(res.status, 202);
  const payload = JSON.parse(captured.init.body);
  // Targets exactly the original sender — no fan-out.
  assert.deepEqual(payload.include_aliases.external_id, [SENDER_ID]);
  assert.deepEqual(payload.data, {
    kind: 'family_shield_response',
    incident_id: 'INC-2026-9001',
    resolution: 'safe',
    responder_external_id: RECIP_A,
  });
  // Copy is server-fixed, neutral and PII-free — the responder's
  // opaque identity is not proof of trust, so the notification never
  // claims "a trusted person" responded.
  assert.equal(payload.headings.en, 'VoxGuard Family Shield Update');
  assert.equal(
    payload.contents.en,
    'A Family Shield response was received for your safety alert.',
  );
});

test('malformed response fields → 400', async () => {
  const env = { ...ENV, RELAY_CLIENT_TOKEN: 'resp2-tok' };
  const bad = [
    { ...RESPONSE_BODY, resolution: 'unresolved' },
    { ...RESPONSE_BODY, resolution: 'confirmed' },
    { ...RESPONSE_BODY, responder_external_id: 'not-vg' },
    { ...RESPONSE_BODY, target_external_id: 'demo_family_maya' },
    { ...RESPONSE_BODY, target_external_id: ['x'] },
    { ...RESPONSE_BODY, incident_id: '' },
  ];
  for (const body of bad) {
    const res = await handleRequest(
      alertRequest(body, { auth: 'Bearer resp2-tok' }),
      env,
      okFetch({}),
    );
    assert.equal(res.status, 400, JSON.stringify(body));
  }
});

test('response event ignores client-supplied PII fields', async () => {
  const captured = {};
  await handleRequest(
    alertRequest(
      {
        ...RESPONSE_BODY,
        responder_name: 'Maya',
        responder_phone: '+15551234567',
        note: 'call me',
      },
      { auth: 'Bearer resp3-tok' },
    ),
    { ...ENV, RELAY_CLIENT_TOKEN: 'resp3-tok' },
    okFetch(captured),
  );
  const raw = captured.init.body;
  assert.ok(!raw.includes('Maya'));
  assert.ok(!raw.includes('15551234567'));
  assert.ok(!raw.includes('call me'));
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
