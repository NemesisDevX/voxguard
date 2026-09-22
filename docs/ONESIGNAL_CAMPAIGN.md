# OneSignal Campaign — technical reference

> **Note:** the active submission is the Shipaton 2026 **Next Gen**
> Award only — this document records the implemented OneSignal
> integration as technical work, not a category claim for this
> submission.

## Integration status

`onesignal_flutter` is integrated and **implemented**:

- Explicit opt-in: notification permission is requested only from
  the Family Shield receiver card's "Enable Family Alerts" button —
  never at app launch.
- Identity: each device mints an opaque `vg_…` external ID, linked
  via `OneSignal.login`; the relay targets `external_id` only.
- Transactional notifications live: Family Shield danger alerts
  (Device A → relay → Device B) and human-resolution responses
  (Device B → relay → Device A).
- Tap routing: alert taps → `FamilyAlertScreen`; response taps →
  incident detail / response-update screen. Foreground arrival shows
  an in-app "View" affordance — never auto-navigates.

## Campaign status

**BLOCKED_EXTERNAL — campaign must be deployed manually.**

No OneSignal Dashboard credentials are available to this
environment, so no campaign has been deployed. The App ID is
supplied at build time via `ONESIGNAL_APP_ID`; the dashboard-side
campaign below is designed and ready to deploy.

## Campaign concept: Family Safety Check-In

| Field | Value |
|-------|-------|
| Purpose | Re-engage dormant users to rehearse independent verification and confirm their Trusted Circle is ready — the behavior that actually protects families. |
| Audience | All subscribed devices with push permission granted; segment: last session > 7 days. |
| Notification title | `Family Safety Check-In` |
| Notification body | `Could your family verify a suspicious voice today? Review your Trusted Circle and agree on an independent callback plan.` |
| Deep-link destination | App open → Home → Trusted Circle section (default open lands on Home; the receiver/trusted-circle cards are one scroll away). |
| Frequency | At most once per 14 days; send-time optimization on. |
| Goal metric | Trusted Circle opened / contact added / receiver card "Enable Family Alerts" completed within 24h of delivery. |
| Tone rules | No fearbait. No fake incident. No implication the user is currently at risk. The notification is a rehearsal prompt, not an alarm. |

## Deployment checklist (manual — OneSignal Dashboard)

1. OneSignal Dashboard → app matching `ONESIGNAL_APP_ID`.
2. Messages → New Push → name it `Family Safety Check-In`.
3. Audience: `Subscribed Users` filtered to last-session > 7 days.
4. Paste title/body above. No images, no action buttons needed.
5. Launch URL: leave blank (default app open is the correct
   destination — no in-app deep-link scheme is registered).
6. Schedule: recurring, max 1 per user per 14 days, intelligent
   delivery on.
7. Record the campaign ID and delivery stats for the submission.

## Evidence

- Campaign ID: _pending manual deployment_
- Deployment date: _pending_
- Dashboard URL (from OneSignal console): _pending_
