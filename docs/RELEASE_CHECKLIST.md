# Release Checklist

Use this checklist before publishing a public source or binary release.

## Source

- `flutter analyze` passes for changed packages.
- `powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1` passes.
- `python -m pytest tests/test_source_import.py` passes.
- `safe_import` dry-run reports `blocked=0` for the public tree.
- `powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1`
  passes before a public source release.
- GitHub Actions CI is green on the release branch or tag.
- No generated build folders, local platform config, signing files, or runtime
  binaries are committed.

## Community Client

- Local profile import works for the documented key schemes.
- Subscription URL import, foreground/manual refresh, and the in-app scheduler
  preserve old profiles when refresh fails.
- Android and Windows QR camera import stay local-only and reuse the safe local
  parser.
- Free VPN catalog remains disabled by default and opt-in with third-party copy.

## Operator Client

- Operator builds use operator-owned API, cabinet, checkout, support, privacy
  policy, package IDs, signing, and release channels.
- `config/operator-api.fixture.json` is updated only with placeholders.
- Fork builds do not imply official POKROV operation.

## Release Copy

- Version, source reference, checksums, platform, install note, known
  limitations, and signing/store status are documented.
- Source-only releases must explicitly say that no APK, EXE, store release, or
  trusted-signed binary is included.
- Claims stay beta-safe unless stronger public evidence exists.
