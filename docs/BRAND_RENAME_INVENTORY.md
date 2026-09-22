# Brand Rename Inventory — executed

Status: `RESOLVED` — public brand is **PauseSignal**
(tagline: *Hear the signal. Pause. Verify.*).
"VoxGuard" remains only inside the Section B technical contracts and
historical references. Executed in commit `feat: finalize PauseSignal
Next Gen judging build`.

## A. User-facing brand strings — updated to PauseSignal

| Surface | Location | State |
|---|---|---|
| App display name (all locales) | `appName` + all name-bearing values in `lib/l10n/arb/app_*.arb` ×4 → regenerated `lib/l10n/generated/` | DONE |
| Android launcher label | `android/app/src/main/AndroidManifest.xml` — `android:label="PauseSignal"` | DONE |
| iOS display/bundle names | `ios/Runner/Info.plist` — `CFBundleDisplayName`, `CFBundleName` | DONE |
| macOS product name | `macos/Runner/Configs/AppInfo.xcconfig` — `PRODUCT_NAME = PauseSignal` | DONE |
| Windows visible strings | `windows/runner/main.cpp` window title; `windows/runner/Runner.rc` `FileDescription`, `ProductName` | DONE |
| Linux visible title | `linux/runner/my_application.cc` window/header title | DONE |
| Web title/meta/manifest | `web/index.html` (title, og:*, twitter, apple-mobile-web-app-title), `web/manifest.json` `name`/`short_name` | DONE |
| Privacy + terms pages | `web/privacy.html`, `web/terms.html` | DONE |
| In-app copy mentioning the name | All ARB values that embedded "VoxGuard" | DONE |
| Store metadata pack | `docs/STORE_METADATA.md` | DONE |
| Submission pack | `docs/SHIPATON_SUBMISSION.md`, `docs/DEMO_SCRIPT.md` | DONE |
| Docs/README | `README.md`, `docs/*.md` judge-facing references | DONE |
| Screenshots | `submission/screenshots/*` regenerated via `test/screenshot_capture_test.dart` | DONE |
| Submission icon | `submission/pausesignal-icon-1024.png` — SignalMark rendered by `tool/generate_icons.py` | DONE |
| GitHub Pages URLs | `nemesisdevx.github.io/voxguard` follows the repo name — unchanged by design (repo keeps `voxguard` name) | N/A |

## B. Identifiers that did NOT change (intentional)

| Identifier | Why |
|---|---|
| `applicationId`/`namespace` `com.nemesisdevx.voxguard` | Store identity — changing it creates a NEW app listing and breaks installs |
| iOS/macOS `PRODUCT_BUNDLE_IDENTIFIER` / Linux `APPLICATION_ID` | Same reason — store identity, not display |
| Kotlin package `com.nemesisdevx.voxguard` (`MainActivity.kt`, dir tree) | Must match `namespace` |
| `vg_…` Family Shield protocol IDs / external-id prefix | Wire protocol — renaming breaks interop between devices on different builds |
| `REVENUECAT_*`, `ONESIGNAL_*`, `ASSEMBLYAI_*`, `VOXGUARD_*` dart-define/env names | Config contract with CI/docs |
| `RevenueCatEntitlements` ids (`sentinel`, `family_vault`) and package ids | Dashboard-configured identifiers |
| `pubspec.yaml` `name: voxguard` and `package:voxguard/...` imports | Internal package name |
| Executable/binary names (`windows` `BINARY_NAME`, `linux` `BINARY_NAME`, `Runner.rc` `InternalName`/`OriginalFilename`) | Technical artifact names matching the package identity |
| `key.properties` field names / `VOXGUARD_KEYSTORE_*` env | Signing contract |
| Git history, prior release docs, `server/` relay contract | Historical fact |
| Repo name `voxguard` (and Pages URL `…/voxguard/`) | Repository identity — deliberately not renamed |
