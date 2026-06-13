# White-Label Branding

This repository includes a minimal color-token export path for independent
operator forks.

The source file is
[`config/white-label-color-tokens.seed.json`](../config/white-label-color-tokens.seed.json).
It records the editable color roles used by the shared shell, required contrast
checks, and the operator-owned branding boundary.

## Export

Generate local operator artifacts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-white-label-color-tokens.ps1
```

By default, generated files are written under `build/white_label_tokens/`, which
is ignored by git:

- `white-label-colors.json`
- `white_label_palette.dart`
- `white-label-colors.css`

Use `-Out` to write to another local directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-white-label-color-tokens.ps1 -Out build/acme-colors
```

## Rules

- Operator forks own their colors, app name, icons, support links, privacy
  policy, package IDs, signing, and release claims.
- Color changes do not make a fork an official POKROV build.
- Do not point operator branding config at official POKROV endpoints.
- Keep contrast checks green before shipping a public binary.
- Treat generated exports as local build artifacts until your fork wires them
  into its own branding pipeline.

## Native Host Metadata

The public Android and Windows hosts now default to neutral open-source native
metadata:

- Android app id: `org.pokrovclient.community`
- Android app label: `Open Client`
- Android runtime directory/subtype: `open-client-runtime`
- Windows executable: `open_client_windows.exe`
- Windows product name: `Open Client`

Flutter `--dart-define` values configure the shared shell. Native app labels,
package ids, notification channel names, executable names, and Windows version
resources must be set in the host build pipeline too. See
[Build From Source](BUILD_FROM_SOURCE.md#native-host-branding) for the Gradle
and CMake override knobs.

## Token Roles

The seed preserves the current shared shell roles:

- `canvas`
- `canvasAlt`
- `ink`
- `accent`
- `accentBright`
- `success`
- `warning`
- `surface`
- `surfaceMuted`
- `line`
- `muted`

The export is intentionally small. It gives operator forks a stable mapping
without pretending that this repository ships a full flavor/build system for
every brand.
