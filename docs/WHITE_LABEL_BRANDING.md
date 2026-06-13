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
