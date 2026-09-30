# Next Gen Judging — RevenueCat Test Store Setup

The Shipaton Next Gen judging path uses RevenueCat's official **Test
Store** through the real `purchases_flutter` SDK. This is a genuine
RevenueCat-hosted testing store — **not** PauseSignal's local Demo
Store (`MockSandboxPurchaseService`, an in-app simulation labelled
*DEMO STORE*). Test Store transactions are processed by RevenueCat,
return real `CustomerInfo`, and appear in the RevenueCat dashboard —
but never charge real money.

> Never paste a real API key into the repository, docs, or tickets.
> The key travels only through `--dart-define` at build time.

## One-time RevenueCat Dashboard setup

1. **Project**: create (or reuse) the PauseSignal project at
   `app.revenuecat.com`. Note the **Project ID** — it goes on the
   Devpost form.
2. **Test Store**: every project ships with a built-in Test Store
   (no App Store Connect / Play Console linking needed).
3. **Products** — create four Test Store products carrying the
   tier/cycle in the product identifier (the store product id is
   what makes each package unambiguous):

   | Store product id | Tier | Cycle |
   |---|---|---|
   | `sentinel_monthly` | Sentinel Shield | monthly |
   | `sentinel_annual` | Sentinel Shield | annual |
   | `family_vault_monthly` | Family Vault | monthly |
   | `family_vault_annual` | Family Vault | annual |

   As observed in the live offering (2026-09-30 SDK inspection):
   `$rc_monthly`→`sentinel_monthly` ($1.05), `$rc_annual`→
   `sentinel_annual` ($4.99), `$rc_two_month`→`family_vault_monthly`
   ($15.99), custom `Annual`→`family_vault_annual` ($55.99). Package
   identifiers may be standard RevenueCat ids (`$rc_monthly`,
   `$rc_annual`, `$rc_two_month`, …) or custom ids — the app
   resolves tier/cycle from package-identifier tokens, then
   `PackageType`, then the `StoreProduct` identifier, and drops any
   package whose signals conflict. Display titles and prices are
   never used for mapping.

   Note: the current dashboard attaches `sentinel_annual` (not a
   `sentinel_yearly` product) as the Sentinel annual product —
   verified at runtime. If the dashboard is later renamed to
   `sentinel_yearly`, the mapper resolves it identically.

   Test Store product names/prices are arbitrary — pick readable
   test values (e.g. `$4.99`/`$49.99`, `$9.99`/`$99.99`); the app
   renders whatever `priceString` RevenueCat returns.

4. **Entitlements** — attach products to the existing entitlement
   IDs (do NOT create new ones):
   - `sentinel` ← `sentinel_monthly`, `sentinel_annual`
   - `family_vault` ← `family_vault_monthly`, `family_vault_annual`
5. **Offering** — ensure the **current** Offering contains the four
   packages. The app reads the current offering only; packages it
   cannot resolve are dropped rather than fabricated.
6. **API key** — copy the **Test Store API key** from the project's
   API keys section.

## Build the judging APK

```bash
flutter build apk --debug \
  --dart-define=REVENUECAT_TEST_STORE_KEY=<test-store-key>
```

Selection truth (`purchase_service_factory_io.dart`):

| Build | Keys present | Backend selected |
|---|---|---|
| Android/iOS debug/judging | Test Store key | **RevenueCat Test Store** — real SDK |
| Android/iOS debug/judging | platform key + test key | production real store (key wins) |
| Android/iOS debug/judging | none | DEMO STORE (local simulation) |
| Android/iOS **release** | only Test Store key | **unavailable** — Test Store can never act as release config |
| Android/iOS release | platform key | production real store |
| Web/desktop | any | DEMO STORE |

## Judge walkthrough

1. Open the paywall — header shows **REVENUECAT TEST STORE** and the
   notice explains the backend truthfully.
2. Tap Subscribe on a paid tier → the RevenueCat Test Store purchase
   sheet appears; complete the test purchase.
3. Entitlement flips only when `CustomerInfo` reports the
   entitlement active — the app never unlocks merely because the
   call returned.
4. Verify the matching feature unlocks (e.g. Sentinel →
   transcript-backed analysis; Family Vault → outbound Family
   Shield).
5. **Restore Purchases** re-derives the same tier from RevenueCat.
6. In the RevenueCat dashboard, the transaction appears under the
   Test Store sandbox data — that is the observable external proof.
7. Test cancellation (dismiss the sheet → paywall stays interactive)
   and failure paths as desired.

## Boundaries

- `CustomerInfo` is the only entitlement authority — identical code
  path for Test Store and production store.
- A Test Store key alone **cannot** enable purchasing in a release
  build; release requires `REVENUECAT_ANDROID_KEY` /
  `REVENUECAT_IOS_KEY` and otherwise shows a truthful unavailable
  state.
- The Test Store must not be presented as real-money billing — the
  in-app badge and notice make the distinction explicit.
