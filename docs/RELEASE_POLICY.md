# Release Policy

Official public releases must be easy to verify and honest about their status.

## Source-Only Releases

Source-only releases, such as `v0.1.0-source`, should include:

- tag name
- commit SHA
- source archive checksum or reproducible checksum note
- source proof manifest from `scripts/prepare-source-release.ps1`
- matching `CHANGELOG.md` entry or source-readiness candidate note
- current feature status
- known limitations
- explicit note that no APK, EXE, store release, or trusted-signed binary is
  shipped in that release

Source-only release tags must be annotated tags. Lightweight tags are refused by
the proof script because the release proof must record both the tag object SHA
and the peeled commit SHA.

Use [releases/SOURCE_RELEASE_TEMPLATE.md](releases/SOURCE_RELEASE_TEMPLATE.md)
for GitHub Release bodies. Milestones that are implemented on `main` but not
tagged yet must be labeled `not tagged` or `pending tag`; do not present them as
published releases.

Run `scripts/prepare-source-release.ps1` on the exact source reference before
publishing release copy. The generated proof manifest is local evidence for the
commit SHA, archive SHA-256, source-only boundary, and absence of committed
binary/signing artifacts in the archived tree.

Use `scripts/render-source-release-notes.ps1` with that proof manifest to render
the first GitHub Release body draft. The renderer refuses manifests that do not
preserve the source-only flags, then prints the tag, commit SHA, archive
checksum, public proof manifest label, and release-honesty copy.

Use `scripts/source-release-preflight.ps1` when you want the full source release
gate in one command. It runs the local tests and clean-clone checks, delegates
proof generation to `prepare-source-release.ps1`, renders the release-note draft,
checks the draft with `scripts/check-source-release-copy.ps1`, and writes a
local preflight summary. The `-SkipTestCommands` switch is only for local or CI
smoke coverage and must not be used for publishing a public source release.

Use `scripts/prepare-release-evidence-bundle.ps1` after source preflight to
collect the preflight summary, source-only flags, proof paths, and optional
GitHub ruleset report into one release evidence bundle under ignored `build/`
output. The bundle requires the preflight Windows bundle verifier proof before
it can be treated as complete release evidence. The bundle is a maintainer
handoff artifact, not a release publisher.

Use `scripts/validate-source-release-publication.ps1` as the publication dry-run
before manual GitHub Release creation. It validates the release
evidence bundle and rendered release notes, writes ignored local output, and
requires the release evidence bundle's Windows verifier proof. It does not
publish, push tags, or upload assets.

Use `scripts/prepare-source-publication-packet.ps1` after the release merge
handoff and publication dry-run exist. The source publication packet
consolidates release notes, proof manifest, source archive, release evidence
bundle, clean-clone/import proof, input fingerprints, and source-only
no-binary flags for final manual review. It rejects missing, malformed, stale,
or too-far-future generated-at timestamps on its direct input summaries, and
handoff-carried publication dry-run fingerprints that do not match the direct
publication dry-run summary, or release artifact file fingerprints that no
longer match the files on disk. Release artifact paths must also stay under
their expected ignored `build/` output roots, and any reported release asset
fingerprints must stay within the source-only allowlist. Release artifact file
extensions must match the source-only artifact contract, and artifact contents
must be readable Markdown, parseable JSON, or valid non-empty ZIP as configured.
JSON proof artifacts must also match their expected source-only schema
contracts. It is
not a publisher and does not merge, tag, push, publish, or upload assets.

Use `scripts/check-source-publication-gate.ps1` as the final source publication gate
after the source publication packet exists. It consumes
`build/source-publication-packet/<tag>/source-publication-packet.json`, records
the packet SHA-256 and carried input/artifact fingerprints, and blocks manual
source-only publication when the packet is stale, unsafe, not ready for manual
publish review, or points at artifact files whose current SHA-256 no longer
matches the packet. It writes only ignored `build/source-publication-gate/`
output and does not merge, tag, push, publish, upload assets, or create a GitHub
Release.

Required checks and release gates are summarized in
[REQUIRED_CHECKS.md](REQUIRED_CHECKS.md). That page documents the expected
GitHub check names, including `Source import and public tree checks` and
`Flutter analyze and tests`, `Android native Gradle unit tests`, and
branch-protection guidance without claiming
that remote repository settings are already enforced.

Repository ruleset and branch protection setup is tracked in
[GITHUB_RULESET_SETUP.md](GITHUB_RULESET_SETUP.md) and
`config/github-ruleset.seed.json`. Release copy must not claim remote GitHub
enforcement until those settings are configured and observed in GitHub.
Use `scripts/check-github-ruleset.ps1` as the read-only verification helper
after manual GitHub setup.

Run `scripts/check-source-release-copy.ps1 -ReleaseNotesPath <file>` again after
manual edits to the GitHub Release body. It verifies that source-only releases
still say no APK/EXE, no store release, no trusted signing claim, no official
backend/private evidence, and no stronger binary/readiness claim without
separate public evidence.

Keep `CHANGELOG.md` synchronized with
`config/source-release-readiness.seed.json` and
`config/changelog-policy.seed.json`. Pending stacked PR milestones must remain
listed as not tagged until the exact annotated source tag exists.

## Binary Release Requirements

Every official binary release should include:

- version label
- target platform
- artifact filename
- SHA-256 checksum
- source reference
- install note
- known limitations
- signing or store-trust status

## Beta Wording

Use `0.x.x-beta` labels until a stable release is approved.

Do not describe a release as stable, store-ready, trusted-signed, or production
complete unless current public evidence supports that claim.

## Artifact Names

Preferred artifact names:

- `pokrov-android-universal.apk`
- `pokrov-windows-setup-x64.exe`
- `pokrov-windows-portable-x64.zip`

Additional artifacts can be published when the release notes explain their
purpose.

## Official Source Reference

When the source snapshot exists, each binary release should point to the commit
or tag used to build it.

## Fork Releases

Fork maintainers are responsible for their own versioning, checksums, signing,
support, and release claims. Fork releases must not imply official POKROV
approval.
