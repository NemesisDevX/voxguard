# VoxGuard Relay

Minimal edge relay between the Flutter app and OneSignal + the
prerecorded-transcription provider (AssemblyAI):

```
Flutter client  ──POST /alert────────►  this relay  ──►  OneSignal REST API
 (privacy-minimal payload)           (validation +    (push to family
                                      auth + secrets)   external_ids)

Flutter client  ──POST /transcription/jobs──►  relay  ──►  AssemblyAI /v2
 (raw audio bytes, ≤25 MB)                  (server-side provider key)
                ◄──GET /transcription/jobs/{id}──  compact status only
```

**Why it exists:** the OneSignal REST API key and the AssemblyAI API
key must never ship inside the app. The alert client sends only
`{kind, incident_id, risk_level, family_external_ids, title, body}` —
no audio, transcript, phone numbers, or credentials. The
transcription client sends raw audio bytes with a minimal
`X-Audio-Format` hint — filenames never leave the device.

## Runtime

Cloudflare Worker (`worker.js` + `src/relay.js` + `src/transcription.js`,
zero runtime deps). The handler is plain `fetch`-API code and also runs
under `node --test` for local verification.

## Server environment

| Variable | Purpose |
|---|---|
| `ONESIGNAL_APP_ID` | OneSignal App ID (UUID) |
| `ONESIGNAL_REST_API_KEY` | OneSignal REST key — **secret**, server-only |
| `ASSEMBLYAI_API_KEY` | AssemblyAI key for prerecorded transcription — **secret**, server-only |
| `RELAY_CLIENT_TOKEN` | Shared token the app sends as `Bearer …` — abuse resistance, not a real credential |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins (defaults: GitHub Pages + localhost) |

Copy `.env.example` for reference. **Never commit real values.**

## Deploy

```bash
cd server
npm install
npx wrangler secret put ONESIGNAL_REST_API_KEY
npx wrangler secret put RELAY_CLIENT_TOKEN
npx wrangler secret put ASSEMBLYAI_API_KEY   # transcription jobs only
# edit wrangler.toml [vars] for ONESIGNAL_APP_ID + ALLOWED_ORIGINS
npx wrangler deploy
```

Then point the app at it:

```bash
flutter run \
  --dart-define=VOXGUARD_ALERT_RELAY_URL=https://<worker>.workers.dev/alert \
  --dart-define=VOXGUARD_RELAY_TOKEN=<same-as-RELAY_CLIENT_TOKEN> \
  --dart-define=VOXGUARD_RECORDING_TRANSCRIPTION_URL=https://<worker>.workers.dev
```

## Test locally (no real pushes)

```bash
cd server
npm test          # 35 unit tests, upstream fetch mocked
npx wrangler dev  # local worker; stub OneSignal via env or watch logs
```

## Transcription routes

`POST /transcription/jobs` · `Authorization: Bearer <RELAY_CLIENT_TOKEN>`
· `Content-Type: application/octet-stream` · `X-Audio-Format: mp3`
(optional hint, ≤12 lowercase chars)

Body: raw audio bytes, ≤ 25 MB (checked on `Content-Length` and
post-read). Server uploads to AssemblyAI `/v2/upload`, submits a
transcript job (`speech_models: ["universal-3-5-pro","universal-2"]`,
`language_detection: true` — covers English and Arabic), and returns
`202 {job_id}` — the opaque provider transcript id.

`GET /transcription/jobs/{id}` · same auth → compact status only:
`{status: "queued"|"processing"|"completed"|"error"}` (+ `text` on
completed). Raw provider errors never reach the client.

**Privacy boundary:** the relay never logs recording bytes, transcript
text, filenames, upload URLs, names, or phone numbers — operational
logs carry request id, status, byte count, and provider job status
only. Nothing is persisted.

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
