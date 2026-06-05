# Dependency License Audit

This file tracks dependency and asset license review before the client source
snapshot becomes public.

## Status

Current status: source snapshot pending.

The table below should be filled during the first sanitized source import.

| Package or asset | Version | Use | License | Bundled | GPL compatible | Action |
| --- | --- | --- | --- | --- | --- | --- |
| pending source import | pending | pending | pending | pending | pending | pending |

## Review Checklist

- Flutter and Dart packages.
- Android native dependencies.
- Windows native dependencies.
- Runtime binaries.
- Icons and logos.
- Fonts.
- Generated images and other generated assets.
- Build tools and GitHub Actions.

## Rules

- Do not add unknown-license assets.
- Do not add private or generated media without source notes.
- Do not bundle GPL-incompatible dependencies into public client releases.
- Keep official POKROV brand assets governed by `BRAND.md`.
