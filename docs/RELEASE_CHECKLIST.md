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
- Subscription URL refresh remains manual unless a scheduler is explicitly
  tested and documented.
- QR import copy distinguishes decoded payload import from camera scanning.
- Free VPN catalog remains gated until feed review is complete.

## Operator Client

- Operator builds use operator-owned API, cabinet, checkout, support, privacy
  policy, package IDs, signing, and release channels.
- `config/operator-api.fixture.json` is updated only with placeholders.
- Fork builds do not imply official POKROV operation.

## Release Copy

- Version, source reference, checksums, platform, install note, known
  limitations, and signing/store status are documented.
- Claims stay beta-safe unless stronger public evidence exists.
