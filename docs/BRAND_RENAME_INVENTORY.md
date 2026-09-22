# Brand Rename Inventory — preparation only

Status: `BLOCKED_DECISION` — the human has not chosen a public name.
This is a technical inventory for the future rename pass; **nothing
here is renamed yet**. "VoxGuard" remains the internal project name.

## A. User-facing brand strings — change with the new name

| Surface | Location |
|---|---|
| App display name (all locales) | `appName` key in `lib/l10n/arb/app_*.arb` ×4 → regen `lib/l10n/generated/` |
| Android launcher label | `android/app/src/main/AndroidManifest.xml` — `android:label="VoxGuard"` |
| iOS display/bundle names | `ios/Runner/Info.plist` — `CFBundleDisplayName`, `CFBundleName` |
| macOS product name | `macos/Runner/Configs/AppInfo.xcconfig` — `PRODUCT_NAME` |
| Windows runner strings | `windows/runner/Runner.rc` — `FileDescription`, `InternalName`, `ProductName`; `windows/CMakeLists.txt` `BINARY_NAME` |
| Linux binary name | `linux/CMakeLists.txt` — `BINARY_NAME` |
| Web title/meta/manifest | `web/index.html` (title, og:*, twitter, apple-mobile-web-app-title), `web/manifest.json` `name`/`short_name` |
| Privacy + terms pages | `web/privacy.html`, `web/terms.html` — visible product name + contact copy |
| In-app copy mentioning the name | ARB strings that embed "VoxGuard" (audit `app_en.arb` values, not just `appName`) |
| Store metadata pack | `docs/STORE_METADATA.md` — listing title/copy |
| Submission pack | `docs/SHIPATON_SUBMISSION.md`, `docs/DEMO_SCRIPT.md` |
| Docs/README | `README.md`, `docs/*.md` visible references |
| Screenshots | `submission/screenshots/*` — regenerate via `test/screenshot_capture_test.dart --update-goldens --dart-define=CAPTURE_SHOTS=true` |
| Submission icon | `submission/voxguard-icon-1024.png` — filename + any baked wordmark (SignalMark glyph itself is name-agnostic) |
| GitHub Pages URLs | `nemesisdevx.github.io/voxguard` follows the repo name — repo rename moves privacy/terms URLs; update `LegalLinks` defaults in `lib/core/constants/legal_links.dart` and any recorded links |

## B. Identifiers that must NOT change just because the display brand changes

| Identifier | Why |
|---|---|
| `applicationId`/`namespace` `com.nemesisdevx.voxguard` | Already published-identity-agnostic (reverse-DNS under `nemesisdevx`); changing it creates a NEW app listing and breaks installs |
| iOS/macOS `PRODUCT_BUNDLE_IDENTIFIER` / Linux `APPLICATION_ID` | Same reason — store identity, not display |
| Kotlin package `com.nemesisdevx.voxguard` (`MainActivity.kt`, dir tree) | Must match `namespace` |
| `vg_…` Family Shield protocol IDs / external-id prefix | Wire protocol — renaming breaks interop between devices on different builds |
| `REVENUECAT_*`, `ONESIGNAL_*`, `ASSEMBLYAI_*`, `VOXGUARD_*` dart-define/env names | Config contract with CI/docs; renaming requires coordinated doc + operator changes |
| `RevenueCatEntitlements` ids (`sentinel`, `family_vault`) | Dashboard-configured identifiers |
| `pubspec.yaml` `name: voxguard` | Package name — internal; renaming churns every import for zero user-visible gain |
| `key.properties` field names / `VOXGUARD_KEYSTORE_*` env | Signing contract |
| Git history, prior release docs, `server/` relay contract | Historical fact |

## Rename execution checklist (for that future pass)

1. Human supplies final name + any legal clearance note.
2. Update Section A surfaces; regenerate `lib/l10n/generated/`
   (`flutter gen-l10n`) and launcher assets if the mark changes.
3. Sweep for stragglers: `grep -ri voxguard` over tracked files,
   then split hits into A (rename) / B (leave) per this inventory.
4. Regenerate screenshots + submission icon.
5. Re-run the full verification battery before submission.
