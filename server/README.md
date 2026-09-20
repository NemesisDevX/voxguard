# VoxGuard Family Shield Relay

Minimal edge relay between the Flutter app and OneSignal:

```
Flutter client  ──POST /alert──►  this relay  ──►  OneSignal REST API
 (privacy-minimal payload)      (validation +    (push to family
                                auth + secrets)   external_ids)
```

**Why it exists:** the OneSignal REST API key must never ship inside
the app. The client sends only `{kind, incident_id, risk_level,
family_external_ids, title, body}` — no audio, transcript, phone
numbers, or credentials.

## Runtime

Cloudflare Worker (`worker.js` + `src/relay.js`, zero runtime deps).
The handler is plain `fetch`-API code and also runs under
`node --test` for local verification.

## Server environment

| Variable | Purpose |
|---|---|
| `ONESIGNAL_APP_ID` | OneSignal App ID (UUID) |
| `ONESIGNAL_REST_API_KEY` | OneSignal REST key — **secret**, server-only |
| `RELAY_CLIENT_TOKEN` | Shared token the app sends as `Bearer …` — abuse resistance, not a real credential |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins (defaults: GitHub Pages + localhost) |

Copy `.env.example` for reference. **Never commit real values.**

## Deploy

```bash
cd server
npm install
npx wrangler secret put ONESIGNAL_REST_API_KEY
npx wrangler secret put RELAY_CLIENT_TOKEN
# edit wrangler.toml [vars] for ONESIGNAL_APP_ID + ALLOWED_ORIGINS
npx wrangler deploy
```

Then point the app at it:

```bash
flutter run \
  --dart-define=VOXGUARD_ALERT_RELAY_URL=https://<worker>.workers.dev/alert \
  --dart-define=VOXGUARD_RELAY_TOKEN=<same-as-RELAY_CLIENT_TOKEN>
```

## Test locally (no real pushes)

```bash
cd server
npm test          # 18 unit tests, upstream fetch mocked
npx wrangler dev  # local worker; stub OneSignal via env or watch logs
```

## Request contract

`POST /alert` · `Authorization: Bearer <RELAY_CLIENT_TOKEN>`

```json
{
  "kind": "family_shield_alert",
  "incident_id": "INC-2026-9001",
  "risk_level": "highRisk",
  "family_external_ids": ["fam_maya", "fam_omar"],
  "title": "VoxGuard Family Shield",
  "body": "A high-risk call was flagged on a protected device. Verify with your family member directly."
}
```

Validation: `kind` enum, `incident_id` safe string ≤64 chars,
`risk_level ∈ {safe, suspicious, highRisk}`, 1–5 recipients (hard cap,
Family Vault model), each a safe string ≤64, title ≤100 / body ≤300.

## Responses

| Code | Meaning |
|---|---|
| 202 | accepted — handed to OneSignal |
| 400 | invalid payload |
| 401 | bad/missing relay token |
| 429 | rate limited (30 req/min per token, best-effort per isolate) |
| 502 | OneSignal rejected |
| 503 | upstream unreachable / relay misconfigured |

## Honest security notes

- `RELAY_CLIENT_TOKEN` resists casual abuse of a public endpoint but is
  a shared secret distributed with the app — treat as demo-grade.
  Production should move to authenticated users or device attestation.
- Rate limiting is per-isolate (best-effort on Workers), not a
  distributed guarantee.
- Logs carry only request ID, recipient count, and upstream status —
  never the API key, auth headers, or recipient IDs.
