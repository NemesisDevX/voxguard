# Brand Release Decision — PauseSignal

Status: `RESOLVED — public brand`

## Decision (final for Shipaton Next Gen submission)

- **Public product name: PauseSignal**
- **Public tagline: "Hear the signal. Pause. Verify."**
- `VoxGuard` was the old internal/project working name. It survives
  only inside technical contracts listed below and in historical
  references — it is no longer presented to users or judges as the
  product brand.

## Facts

- A published call-screening product previously used the public name
  "VoxGuard", and a trademark filing existed in a closely related
  category — the rename also retires that naming risk.
- The application identifier `com.nemesisdevx.voxguard` remains the
  technical identity for Android, iOS, macOS, Linux and Windows
  builds. A public display-name change does NOT change the package
  identity.

## What changed

- All user-facing surfaces now say **PauseSignal**: `appName` in all
  four ARBs, Android launcher label, iOS/macOS/Windows/Linux visible
  names, web title/OpenGraph/Twitter/manifest metadata, privacy and
  terms pages, README and judge-facing docs, submission assets.
- The launcher/submission icon is the SignalMark
  (`submission/pausesignal-icon-1024.png`) — the same symbol the app
  itself ships.

## What intentionally did NOT change

- GitHub repository name `voxguard`, Dart package name `voxguard`
  and `package:voxguard/...` imports.
- `applicationId` / `namespace` / bundle IDs
  `com.nemesisdevx.voxguard`.
- Kotlin package/directory names.
- `vg_...` Family Shield protocol identifiers.
- Persisted preference/storage keys (backwards compatibility).
- RevenueCat entitlement IDs (`sentinel`, `family_vault`) and package
  IDs (`sentinel_monthly`, `sentinel_annual`, `family_vault_monthly`,
  `family_vault_annual`).
- `REVENUECAT_*`, `ONESIGNAL_*`, `ASSEMBLYAI_*`, `VOXGUARD_*`
  environment/dart-define names, backend protocol fields.
- Historical Git data.

See `docs/BRAND_RENAME_INVENTORY.md` for the executed inventory.

## Non-claims

- This document makes no claim of trademark infringement.
- This document is not legal advice.
