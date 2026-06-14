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
  multi-profile selection, manual/foreground/in-app scheduled subscription URL
  refresh,
  Android/Windows QR import, and gated third-party catalog metadata. Manual
  catalog import is disabled unless
  `OPEN_CLIENT_ENABLE_FREE_CATALOG=true` is supplied.
- `operator`: white-label client for companies with their own API, cabinet,
  support, billing, and branding.

The `pokrov` variant is reserved for official POKROV service builds.

Read [PRODUCT_VARIANTS.md](PRODUCT_VARIANTS.md) and
[OPERATOR_INTEGRATION.md](OPERATOR_INTEGRATION.md) before shipping a fork.

First-run path for ordinary users:

1. choose the `community` variant
2. run the dependency bootstrap
3. start the Android or Windows shell from source
4. paste a `vless://`, `trojan://`, `ss://`, or `vmess://` key
5. scan a QR code or add a subscription URL when that is how your provider
   shares profiles

OS background refresh is not claimed for this source milestone.

First-run path for operators:

1. choose the `operator` variant
2. run the local fixture backend
3. export white-label color tokens
4. implement the minimal managed-profile contract
5. replace all API, support, privacy, signing, and release surfaces with your
   own

Generate a seed-backed command before running or building a variant:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\print-build-variant-command.ps1 -Variant community -Platform android
powershell -ExecutionPolicy Bypass -File .\scripts\print-build-variant-command.ps1 -Variant operator -Platform windows -Action build -Release
```

The helper prints a PowerShell preview only. It reads
`config/variants/*.seed.json`, anchors the command inside `apps/android_shell`
or `apps/windows_shell`, and does not build, sign, write local config, or create
release artifacts.

Example community run shape:

```powershell
Push-Location apps/android_shell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=community `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Open Client" `
  --dart-define=OPEN_CLIENT_ANDROID_PACKAGE_NAME=org.pokrovclient.community `
  --dart-define=OPEN_CLIENT_ENABLE_FREE_CATALOG=false
Pop-Location
```

The Free VPN catalog preview is visible in community mode so users can inspect
the third-party boundary. Manual feed import stays disabled unless you compile
with `--dart-define=OPEN_CLIENT_ENABLE_FREE_CATALOG=true`; even then, imports
remain user-initiated and are not official POKROV nodes.

Example operator run shape:

```powershell
Push-Location apps/windows_shell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=operator `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Acme VPN" `
  --dart-define=OPEN_CLIENT_ANDROID_PACKAGE_NAME=com.acme.vpn `
  --dart-define=OPEN_CLIENT_API_BASE_URL="https://api.acme.example/" `
  --dart-define=OPEN_CLIENT_CABINET_URL="https://app.acme.example/" `
  --dart-define=OPEN_CLIENT_SUPPORT_URL="https://support.acme.example/" `
  --dart-define=OPEN_CLIENT_PRIVACY_URL="https://acme.example/privacy/"
Pop-Location
```

Operator forks can export editable color tokens before wiring their own brand
pipeline:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-white-label-color-tokens.ps1
```

See [White-label branding](WHITE_LABEL_BRANDING.md) for the token roles,
contrast checks, and operator-owned branding boundary.

## Native Host Branding

Dart `--dart-define` values configure the shared Flutter shell. Native Android
and Windows host metadata have their own build knobs so distributable
community/operator artifacts do not inherit official POKROV labels.

Android defaults to neutral open-source values:

- `applicationId`: `org.pokrovclient.community`
- app label: `Open Client`
- foreground-service subtype: `open-client-runtime`

Override them through Gradle project properties in an operator release
pipeline. Keep `openClientApplicationId` aligned with the Dart
`OPEN_CLIENT_ANDROID_PACKAGE_NAME` define so Android route bypass rules point at
the actual app package:

```powershell
Push-Location apps/android_shell/android
.\gradlew.bat assembleRelease `
  -PopenClientApplicationId=com.acme.vpn `
  -PopenClientAppLabel="Acme VPN" `
  -PopenClientRuntimeDirectory=acme-vpn-runtime `
  -PopenClientRuntimeNotificationChannelName="Acme VPN connection"
Pop-Location
```

Windows defaults to `open_client_windows.exe` and neutral `Open Client`
resource metadata. Override the CMake cache values when configuring an
operator build in your Windows release pipeline:

```powershell
cmake -S apps/windows_shell/windows -B apps/windows_shell/build/windows/x64 `
  -DOPEN_CLIENT_WINDOWS_BINARY_NAME=acme_vpn `
  -DOPEN_CLIENT_WINDOWS_APP_NAME="Acme VPN" `
  -DOPEN_CLIENT_WINDOWS_COMPANY_NAME="Acme Inc."
```

## Resolve Dependencies

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

The contributor doctor is read-only. It checks local commands and required
public files, then exits without installing dependencies, building artifacts,
fetching runtime binaries, copying config, or publishing anything. Use JSON
output when filing a build issue:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Json
```

After the doctor passes, resolve workspace dependencies:

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
That manifest is source-only release metadata: it records the upstream release,
expected archive names, local sync destinations, and current license/binary
review state without shipping those binaries.

To fetch and place runtime artifacts for local testing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fetch-libcore-assets.ps1 -Platforms @("windows","android") -SyncToHosts
```

Downloaded artifacts land under ignored local folders and must not be committed.
When an asset entry still uses `PENDING_PUBLIC_BINARY_REVIEW`, the fetch helper
prints a warning and treats the archive as local-only test material. After a
public binary review records a real 64-character SHA-256 in the manifest, the
helper verifies the downloaded archive before extraction or host sync.

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

The GitHub Actions CI workflow runs the source-import tests, source-release
preflight smoke, a clean-clone source-boundary pass, `flutter analyze`, and the
workspace Flutter tests.

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
