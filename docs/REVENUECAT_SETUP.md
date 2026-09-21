# RevenueCat Setup

VoxGuard gates premium capabilities through RevenueCat entitlements.
This document is the complete configuration reference — the app is
fully functional (and honest about it) without any of this.

## Architecture

```
IPurchaseService (lib/features/paywall/domain/services/)
  ├─ RevenueCatPurchaseService   real store, Android/iOS
  ├─ MockSandboxPurchaseService  labeled demo store — web/desktop
  │                              (incl. macOS) + keyless debug builds
  └─ UnavailablePurchaseService  release builds with no key —
                                 paywall locks, nothing faked
```

`PurchaseServiceFactory` picks the backend at first use. Real-store
purchasing is scoped to **Android and iOS only** for this release —
macOS has no configured or validated RevenueCat app, so it follows
the Desktop Demo Store path:

| Condition | Backend |
|---|---|
| Android/iOS + `REVENUECAT_*_KEY` set | `RevenueCatPurchaseService` |
| Android/iOS, debug, no key | `MockSandboxPurchaseService` (DEMO STORE badge) |
| Android/iOS, release, no key | `UnavailablePurchaseService` (truthful lock) |
| Web / Windows / Linux / macOS | `MockSandboxPurchaseService` |

`PurchaseServiceLocator.instance` is the singleton every consumer
resolves — bloc, gates, and UI share one entitlement stream.
`purchases_flutter` is only compiled on store platforms (conditional
import); web builds never link the SDK.

## Entitlements

One entitlement per paid tier, configured in the RevenueCat
dashboard. The identifiers are compile-time constants
(`RevenueCatEntitlements` in `revenuecat_purchase_service.dart`) —
create them in the dashboard spelled exactly:

| Entitlement identifier | Unlocks |
|---|---|
| `sentinel` | Cloud/transcript-backed analysis, streaming STT in SafeCall |
| `family_vault` | Everything in Sentinel + outbound Family Shield dispatch |

`EntitlementState` is a reactive `ValueListenable` — entitlement
changes (purchase, restore, expiry, cross-device grant) propagate
without restart. `ProductAccess` maps tier → capabilities:

| Capability | Free | Sentinel | Family Vault |
|---|---|---|---|
| On-device recording analysis | ✅ | ✅ | ✅ |
| Demo SafeCall | ✅ | ✅ | ✅ |
| Family Shield receive/respond | ✅ | ✅ | ✅ |
| Cloud transcription (recording + live) | — | ✅ | ✅ |
| Outbound Family Shield dispatch | — | — | ✅ |

## Products

Create one product per tier × billing cycle, attach each to the
matching entitlement, and group them into the **current Offering**.
The paywall renders only what that offering returns — missing
packages are simply absent (a tier with no package falls back to
truthful "not available" copy rather than a dead button).

Package identifiers are **required, spelled exactly** — the service
maps `Package.identifier` → (tier, cycle) via `RevenueCatPackageIds`
and silently ignores unknown identifiers, never fabricating a row:

| Package | Product | Entitlement |
|---|---|---|
| `sentinel_monthly` | monthly auto-renewing | `sentinel` |
| `sentinel_annual` | annual auto-renewing | `sentinel` |
| `family_vault_monthly` | monthly auto-renewing | `family_vault` |
| `family_vault_annual` | annual auto-renewing | `family_vault` |

- **Prices**: always the store-localized `priceString` + `/mo` or
  `/yr` suffix — no hard-coded marketing prices anywhere.
- **Trials/intro offers**: rendered only when the store package
  actually provides one (`StoreProduct.introductoryPrice` /
  subscription offers). No unconditional trial banner exists.
- **Billing-cycle toggle**: appears only when the offering contains
  both monthly and annual packages.

## dart-defines

| Define | Purpose |
|---|---|
| `REVENUECAT_ANDROID_KEY` | `goog_…` public SDK key (Play/App Store connected app) |
| `REVENUECAT_IOS_KEY` | `appl_…` public SDK key |
| `VOXGUARD_TERMS_URL` | renders the Terms button on the paywall — dead links never render |
| `VOXGUARD_PRIVACY_POLICY_URL` | renders the Privacy button — dead links never render |

SDK keys are client-safe identifiers (they identify the app, not
secrets — entitlement authority always lives on RevenueCat's
servers).

## Lifecycle

`main.dart` calls `purchaseService.initialize()` at startup:
`Purchases.configure` runs once (guarded by `Purchases.isConfigured`
for hot-restart safety), then `addCustomerInfoUpdateListener` keeps
`EntitlementState` live. Purchase → `Purchases.purchase(PurchaseParams
.package)` → `PurchaseResult.customerInfo` updates state; cancellation
is detected via `PurchasesErrorHelper.getErrorCode` and surfaces a
neutral "purchase cancelled" — never an error banner. Restore maps
`CustomerInfo.entitlements` back to a tier.

## Demo Store

`MockSandboxPurchaseService` simulates the full lifecycle —
packages, checkout delay, entitlement grant, restore — and the
paywall labels itself **DEMO STORE** with "no real charge" copy and
an "Activate Demo Plan" CTA. It exists so web/desktop and keyless
debug builds can demo the upgrade journey; it can never masquerade
as a real purchase.

## Unavailable backend

Release builds on store platforms without a key get
`UnavailablePurchaseService`: the paywall shows "Subscriptions
aren't configured in this build," renders no Subscribe/Restore CTAs,
and purchase/restore calls complete with an error. Free-tier
capabilities still work — nothing is fake-purchasable.
