# RevenueCat Real-Device Purchase QA

Manual checklist for validating the live-store purchase path on a
physical Android/iOS device with RevenueCat sandbox/store testers.
**Nothing below has been executed yet** — every row starts as
`NOT RUN` until performed on hardware. Automated tests cover the
Dart logic only; they cannot observe real store sheets.

## Preconditions

- `REVENUECAT_ANDROID_KEY` / `REVENUECAT_IOS_KEY` provided at build
  time (`--dart-define`) for the platform under test.
- RevenueCat Dashboard: Sentinel + Family Vault products created,
  attached to entitlements, and placed in the **current Offering**.
- Store sandbox/tester account signed in on the device.
- Statuses: `PASS / FAIL / NOT RUN / BLOCKED_EXTERNAL`.

## Matrix

| # | Test | Expected | Result |
|---|------|----------|--------|
| 1 | Cold start, keyed build | Home subscription card shows real plan state, no Demo Store badge | NOT RUN |
| 2 | Open paywall | Packages render from current Offering only; `priceString` localized prices; no hard-coded prices | NOT RUN |
| 3 | First purchase (Sentinel) | Store sheet → entitlement activates without app restart | NOT RUN |
| 4 | Sentinel gate | Cloud/enhanced transcription paths unlock; free-tier prompts disappear | NOT RUN |
| 5 | Purchase Family Vault | Family Vault entitlement wins precedence over Sentinel | NOT RUN |
| 6 | Family Vault gate | Outbound Family Shield dispatch unlocks (real relay path) | NOT RUN |
| 7 | Cancellation (store side) | After expiry, entitlement revokes; gates re-lock | NOT RUN |
| 8 | Restore purchases | Restore button re-activates prior entitlement | NOT RUN |
| 9 | Entitlement update live | `CustomerInfo` listener reflects change without restart | NOT RUN |
| 10 | Management link | "Manage subscription" opens store subscription page | NOT RUN |
| 11 | Trial copy | Trial text appears only if the package actually offers one | NOT RUN |
| 12 | Keyless release build | Paywall shows locked/unavailable state — never a fake purchase | NOT RUN |
| 13 | Demo Store (web/desktop/keyless debug) | Always labelled `DEMO STORE`; simulated prices marked as simulation | NOT RUN |
| 14 | macOS build | Resolves to Demo Store even with a RevenueCat key present | NOT RUN |

## Notes

- Cancellation is initiated store-side (Play Console / App Store
  sandbox settings); the app only observes the resulting
  `CustomerInfo`.
- No row may be marked PASS from CI or `flutter test` alone —
  these require physical observation of store behavior.
