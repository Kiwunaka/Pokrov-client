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
- `config/security-intake.seed.json` still forbids public vulnerability issues,
  keeps blank issues disabled, points to private reporting, and preserves the
  source-only no-APK/no-EXE/no-store/no-trusted-signing boundary.
- `CHANGELOG.md` is updated for the exact source milestone and still matches
  `config/changelog-policy.seed.json` without presenting pending PRs as tags.
- `config/dependency-license-inventory.seed.json` matches local `pubspec.lock`
  files when they exist and contains no `REVIEW_REQUIRED` entries.
- `config/generated-assets.seed.json` lists every `assets/**/*.png` file with
  provenance and reuse scope.
- `powershell -ExecutionPolicy Bypass -File .\scripts\prepare-source-release.ps1`
  is run for the exact source reference and its proof manifest is reflected in
  the GitHub Release body.
- `powershell -ExecutionPolicy Bypass -File .\scripts\source-release-preflight.ps1`
  can be used as the single local gate that runs tests, clean-clone proof,
  Windows bundle verification, source proof generation, release-note rendering,
  and preflight summary generation. Do not use `-SkipTestCommands` for
  publishing.
- `powershell -ExecutionPolicy Bypass -File .\scripts\prepare-release-evidence-bundle.ps1`
  writes the release evidence bundle after source preflight and optional
  GitHub ruleset report review; it requires the preflight Windows bundle
  verifier proof and does not publish a release.
- `powershell -ExecutionPolicy Bypass -File .\scripts\validate-source-release-publication.ps1`
  runs the publication dry-run against the release evidence bundle and rendered
  release notes before any manual GitHub Release publication; it requires the
  release evidence bundle's Windows verifier proof.
- `powershell -ExecutionPolicy Bypass -File .\scripts\check-source-tag-readiness.ps1`
  runs the source tag readiness check against the release blocker inventory and
  source-readiness list before a source tag is attempted; it writes ignored
  `build/source-tag-readiness/` output and returns non-zero while manual
  maintainer blockers remain open.
- `powershell -ExecutionPolicy Bypass -File .\scripts\check-release-merge-order.ps1`
  runs the release merge order check against the local stacked PR manifest
  before manual merge or tag work; it writes ignored
  `build/release-merge-order/` output and does not merge, push, or publish
  anything.
- `powershell -ExecutionPolicy Bypass -File .\scripts\check-release-stack-github-status.ps1`
  runs the release stack GitHub status check against a read-only PR status
  snapshot before manual merge or tag work; it writes ignored
  `build/release-stack-github-status/` output and does not merge, push, or
  publish anything.
- `powershell -ExecutionPolicy Bypass -File .\scripts\prepare-release-merge-handoff.ps1`
  creates a release merge handoff report by bundling the release merge order,
  release stack GitHub status, source tag readiness, and publication dry-run
  readiness summaries into an ignored `build/release-merge-handoff/` maintainer
  handoff report with input SHA-256 fingerprints, input generated-at
  timestamps, and explicit source-only no-binary flags. The handoff accepts
  prerequisite summaries only from their expected ignored `build/` output
  roots; it does not merge, tag, push, publish, or upload anything.
- `powershell -ExecutionPolicy Bypass -File .\scripts\verify-windows-bundle.ps1`
  runs the Windows bundle verifier and writes source-only Windows bundle proof
  under ignored `build/windows-bundle-verifier/`; it checks required Windows
  shell source paths and refuses committed Windows binaries, archives, signing
  files, or local runtime artifacts. It does not build, sign, package, publish,
  or download runtime artifacts.
- `powershell -ExecutionPolicy Bypass -File .\scripts\check-source-release-copy.ps1`
  passes for the release policy, checklist, source release template, renderer,
  and final rendered release note.
- `safe_import` dry-run reports `blocked=0` for the public tree.
- `powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1`
  passes before a public source release.
- GitHub Actions CI is green on the release branch or tag.
- Required checks policy in [REQUIRED_CHECKS.md](REQUIRED_CHECKS.md) still
  matches `.github/workflows/ci.yml` and `config/required-checks.seed.json`,
  including `Source import and public tree checks` and
  `Flutter analyze and tests`, and `Android native Gradle unit tests`.
- GitHub ruleset setup in [GITHUB_RULESET_SETUP.md](GITHUB_RULESET_SETUP.md)
  still matches `config/github-ruleset.seed.json`; do not claim remote
  enforcement until GitHub settings are configured and observed.
- `powershell -ExecutionPolicy Bypass -File .\scripts\check-github-ruleset.ps1`
  passes before claiming remote GitHub ruleset or branch-protection
  enforcement.
- No generated build folders, local platform config, signing files, or runtime
  binaries are committed.

## Source Tag Flow

Run these commands on the exact commit that will be tagged:

```powershell
$tag = "v0.3.0-source"
$preflight = Join-Path $env:TEMP "$tag-preflight"
git status --short
git rev-parse HEAD
git tag -a $tag -m "$tag"
powershell -ExecutionPolicy Bypass -File .\scripts\source-release-preflight.ps1 `
  -Tag $tag `
  -Ref "refs/tags/$tag" `
  -OutDir $preflight `
  -RequireTag
```

Annotated source tags are required. `source-release-preflight.ps1 -RequireTag`
delegates proof generation to `prepare-source-release.ps1`, which refuses
lightweight tags. The proof manifest records both `tag_object_sha` and the
peeled `commit_sha`; release notes must use the peeled commit SHA as the source
reference.

Before pushing the tag, review the rendered release note and preflight summary,
then add the exact feature status and known limitations based on
[SOURCE_RELEASE_TEMPLATE.md](releases/SOURCE_RELEASE_TEMPLATE.md). The rendered
body must keep the proof manifest's source-only boundaries. The source-release
preflight runs `check-source-release-copy.ps1` against the rendered draft; run
the same checker again after manual edits to the GitHub Release body.

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
- Default community builds keep
  `OPEN_CLIENT_ENABLE_FREE_CATALOG=false`; turning it on requires release notes
  that state the imported feeds are third-party public configs, not official
  POKROV nodes, user-initiated, and no speed, privacy, uptime, safety,
  legality, or availability promise is made.

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
