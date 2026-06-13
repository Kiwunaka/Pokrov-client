# Release Checklist

Use this checklist before publishing a public source or binary release.

## Source

- `flutter analyze` passes for changed packages.
- `powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1` passes.
- `python -m pytest tests` passes.
- `python -m pytest tests/test_release_provenance.py` confirms dependency and
  generated-asset inventories are publishable; when local `pubspec.lock` files
  exist, it also confirms inventory package names and versions match them.
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1`
  passes.
- `config/dependency-license-inventory.seed.json` matches local `pubspec.lock`
  files when they exist and contains no `REVIEW_REQUIRED` entries.
- `config/generated-assets.seed.json` lists every `assets/**/*.png` file with
  provenance and reuse scope.
- `powershell -ExecutionPolicy Bypass -File .\scripts\prepare-source-release.ps1`
  is run for the exact source reference and its proof manifest is reflected in
  the GitHub Release body.
- `safe_import` dry-run reports `blocked=0` for the public tree.
- `powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1`
  passes before a public source release.
- GitHub Actions CI is green on the release branch or tag.
- No generated build folders, local platform config, signing files, or runtime
  binaries are committed.

## Source Tag Flow

Run these commands on the exact commit that will be tagged:

```powershell
$tag = "v0.3.0-source"
$proof = Join-Path $env:TEMP "$tag-proof"
git status --short
git rev-parse HEAD
python -m pytest tests
python -m pytest tests/test_release_provenance.py
powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1 -Source .
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
git tag -a $tag -m "$tag"
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-source-release.ps1 `
  -Tag $tag `
  -Ref "refs/tags/$tag" `
  -OutDir $proof `
  -RequireTag
```

Annotated source tags are expected. The proof manifest records both
`tag_object_sha` and the peeled `commit_sha`; release notes must use the peeled
commit SHA as the source reference.

Before pushing the tag, copy the tag name, commit SHA, archive SHA-256, proof
manifest path, feature status, and known limitations into a release note based on
[SOURCE_RELEASE_TEMPLATE.md](releases/SOURCE_RELEASE_TEMPLATE.md).

Push only after the release note is accurate:

```powershell
git push origin $tag
```

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
- Pending milestones must say `not tagged` until the exact release tag exists.
- Claims stay beta-safe unless stronger public evidence exists.
