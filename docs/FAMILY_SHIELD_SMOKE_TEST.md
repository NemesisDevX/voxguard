# Family Shield — Two-Device Smoke Test

Proves the real push path end-to-end:

```
Device A (protected)  →  relay  →  OneSignal  →  Device B (receiver)
```

> ⚠️ This procedure requires **physical or push-capable emulated
> devices** and manual OneSignal/Firebase dashboard setup. It has NOT
> been executed in CI — run it manually.

## Prerequisites (manual, one-time)

1. **OneSignal app** — create an app at onesignal.com → copy the
   **App ID** (Settings → Keys & IDs).
2. **Android/FCM** — in the OneSignal dashboard, configure *Google
   Android (FCM)* by uploading a Firebase project's service-account
   credentials. This is dashboard-side only — the current
   `onesignal_flutter` SDK does **not** need a `google-services.json`
   file in the app project. (iOS: APNs key + push capability —
   untested in this repo.)
3. **Relay** — deploy `server/` (`npx wrangler deploy`) with
   `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY` (secret),
   `RELAY_CLIENT_TOKEN`, `ALLOWED_ORIGINS` set. See `server/README.md`.

## Device B — the receiver (family member)

```bash
flutter run --dart-define=ONESIGNAL_APP_ID=<app-id>
```

1. Open **Settings → Family Shield Receiver**.
2. Tap **Enable Family Alerts** → grant the native notification
   permission (this is the only place the prompt fires).
3. Wait for status **"Ready to receive alerts"**.
4. Tap **Copy Family Shield ID** — looks like `vg_8f3a…92`.

## Device A — the monitored device

```bash
flutter run \
  --dart-define=ONESIGNAL_APP_ID=<app-id> \
  --dart-define=VOXGUARD_ALERT_RELAY_URL=https://<worker>.workers.dev/alert \
  --dart-define=VOXGUARD_RELAY_TOKEN=<relay-token> \
  --dart-define=VOXGUARD_TEST_FAMILY_EXTERNAL_ID=<device-B-vg-id>
```

(or set the `vg_…` id in Settings → *DEV · Test alert recipient* on a
debug build)

1. Run **SafeCall → Demo Attack → Simulate Scam** → reach HIGH RISK.
2. End the call → post-call sheet → **Alert Family Shield**.

## Expected — and how to read it honestly

| Stage | Observable | Meaning |
|---|---|---|
| Relay | `Alert accepted for delivery to 1 family member(s)` | relay validated + OneSignal API accepted. **Not** confirmed delivery. |
| OneSignal | dashboard → notification shows `sent` | OneSignal queued push to the subscription |
| Device B | system notification appears: "VoxGuard Family Shield — A high-risk call was flagged…" | **actual delivery** — the only stage that proves it |

If the relay accepts but B shows nothing: check OneSignal dashboard →
the notification's delivery stats, the device subscription's
`optedIn`/token state, and FCM key mismatch (most common failure).

## Privacy check

- Notification content is generic — no transcript, audio, names, or
  numbers travel in the payload.
- Device B's identity is the opaque `vg_…` id — never a phone number
  or email.
