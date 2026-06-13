# Build From Source

This page covers the public source snapshot. It is for local development and
verification, not an official release-signing guide.

## Requirements

- Flutter SDK compatible with Dart `>=3.0.0 <4.0.0`
- PowerShell
- Android Studio or Android SDK for Android work
- Visual Studio with Desktop development workload for Windows work
- Git and network access for dependency resolution

## Workspace Layout

```text
apps/
  android_shell/      Android Flutter host and Android runtime bridge
  windows_shell/      Windows Flutter host and desktop runtime bridge
packages/
  app_shell/          Shared UI and app-first bootstrap flow
  core_domain/        Shared product/domain contracts
  platform_contracts/ Host/runtime contracts
  runtime_engine/     Runtime bridge abstractions
  support_context/    Support and diagnostics context
config/
  *.seed.json         Public seed configuration and runtime contracts
```

## Choose A Product Variant

The public client has two open-source product lines:

- `community`: neutral client for ordinary users with local single-key import;
  no POKROV logo and no POKROV API calls by default. The current local importer
  accepts `vless://`, `trojan://`, `ss://`, and `vmess://` keys, supports local
  multi-profile selection, manual/foreground subscription URL refresh,
  Android/Windows QR import, and gated third-party catalog metadata.
- `operator`: white-label client for companies with their own API, cabinet,
  support, billing, and branding.

The `pokrov` variant is reserved for official POKROV service builds.

Read [PRODUCT_VARIANTS.md](PRODUCT_VARIANTS.md) and
[OPERATOR_INTEGRATION.md](OPERATOR_INTEGRATION.md) before shipping a fork.

Example community run:

```powershell
flutter run --dart-define=OPEN_CLIENT_VARIANT=community --dart-define=OPEN_CLIENT_BRAND_NAME="Open Client"
```

Example operator run:

```powershell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=operator `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Acme VPN" `
  --dart-define=OPEN_CLIENT_API_BASE_URL="https://api.acme.example/" `
  --dart-define=OPEN_CLIENT_CABINET_URL="https://app.acme.example/" `
  --dart-define=OPEN_CLIENT_SUPPORT_URL="https://support.acme.example/" `
  --dart-define=OPEN_CLIENT_PRIVACY_URL="https://acme.example/privacy/"
```

Operator forks can export editable color tokens before wiring their own brand
pipeline:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-white-label-color-tokens.ps1
```

See [White-label branding](WHITE_LABEL_BRANDING.md) for the token roles,
contrast checks, and operator-owned branding boundary.

## Resolve Dependencies

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-workspace.ps1
```

For a fully offline pub-get attempt, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1 -OfflinePubGet
```

## Runtime Artifacts

Native runtime binaries are not committed to this repository. The public seed
tracks `hiddify/hiddify-core` in `config/runtime-artifacts.seed.json`.

To fetch and place runtime artifacts for local testing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fetch-libcore-assets.ps1 -Platforms @("windows","android") -SyncToHosts
```

Downloaded artifacts land under ignored local folders and must not be committed.

## Tests

Run the source-import tool tests:

```powershell
python -m pytest tests/test_source_import.py
```

Run the Flutter and Android unit lane:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

By default this runs Flutter tests for the shared packages and imported host
apps. The Android Gradle unit lane requires Android SDK/JDK compatibility and
the fetched `libcore.aar`, so it is opt-in:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fetch-libcore-assets.ps1 -Platforms @("android") -SyncToHosts
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1 -RunAndroidGradle
```

Windows runtime smoke requires the fetched native runtime artifacts.

## Clean Clone Proof

Maintainers can verify that the public tree works from a fresh clone and does
not require private files:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1
```

For a faster source-boundary-only pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1 -SkipFlutterTests
```

The GitHub Actions CI workflow runs the source-import tests, a clean-clone
source-boundary pass, `flutter analyze`, and the workspace Flutter tests.

## Local Config

The committed files under `config/` are seed examples and public contracts.
Generated local config belongs under ignored `config/local/`.

Preview local materialization:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-local.ps1 -DryRun
```

## Release Boundary

This source snapshot does not claim APK/EXE delivery, store readiness, trusted
Windows signing, production release maturity, raw physical-device audit proof,
or RU-origin readiness. Official binaries and signing remain a separate POKROV
release process.
