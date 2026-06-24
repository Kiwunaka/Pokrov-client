# Release Blockers

This document mirrors
[`config/release-blocker-inventory.seed.json`](../config/release-blocker-inventory.seed.json).
It records whether the current source-readiness candidate is ready for an
annotated source tag.

The current public source line is ready for tag only when every required blocker
is cleared for the exact source candidate. This page is about source tags only.
It does not authorize APK, EXE, store release, trusted signing, official binary,
runtime connectivity, or production support claims.

## Required Before Tag

Every source tag requires these manual maintainer step checks:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release preflight with `-RequireTag` and without
  `-SkipTestCommands`
- review the release evidence bundle, preflight summary, proof manifest, and
  rendered release notes
- review public release notes for feature status, known limitations, source
  proof, and no binary claims
- confirm no APK, EXE, store release, or trusted signing claim appears in the
  GitHub Release body, changelog, README, or source-readiness notes
- confirm Free VPN catalog and diagnostics boundaries still hold: catalog
  imports are gated third-party opt-in, diagnostics exports are local-only,
  user-initiated, and redacted

## Current Status

Status: ready for tag.

The blocker inventory uses `ready_for_tag` only after the source-readiness stack
is merged to `main`, the exact tag commit is selected, local gates are green,
and source-only release boundaries are reviewed. It still does not create the
annotated tag, push a tag, publish a GitHub Release, or upload any release
assets.

Run `scripts/check-source-tag-readiness.ps1 -Tag <tag>` for a local source tag readiness
summary. The command is read-only, writes ignored
`build/source-tag-readiness/` output, and returns non-zero while required
manual maintainer blockers remain open.

Run `scripts/check-release-merge-order.ps1` for a local release merge order
summary before manual merge or tag work. The command is read-only, writes
ignored `build/release-merge-order/` output, and checks that each stacked PR
base matches the previous PR head in the local manifest.

Run `scripts/check-release-stack-github-status.ps1` for a local release stack GitHub status
summary before manual merge or tag work. The command is read-only, writes
ignored `build/release-stack-github-status/` output, and checks that the PR
status snapshot matches the local stack manifest, is not draft, has clean merge
state, and has successful required CI checks.

Run `scripts/prepare-release-merge-handoff.ps1` for a local release merge handoff
summary after the merge-order, GitHub-status, source-tag-readiness, and
publication dry-run summaries exist. The command is read-only, writes ignored
`build/release-merge-handoff/` output, records input SHA-256 fingerprints, and
records input generated-at timestamps, schema versions, read-only input
summary checks, stack-count consistency, error-free input summary checks,
tag-readiness blocker-count consistency, tag-readiness blocker entry-shape
checks, tag-readiness ready-flag consistency, tag-readiness blocker-absence
consistency, open-blocker evidence fields, tag-readiness latest stacked PR
consistency, and explicit source-only no-binary flags plus the next manual
maintainer steps. The handoff seed defaults must track the blocker inventory
latest candidate, and the helper does not merge, tag, push, publish, or upload
anything. The input summaries must come from the expected ignored `build/`
output roots.

Run `scripts/prepare-source-publication-packet.ps1` for a local source publication packet
after the release handoff and publication dry-run summaries exist. The command is read-only, writes ignored
`build/source-publication-packet/` output, records input SHA-256 fingerprints,
and consolidates release notes, proof manifest, source archive, release
evidence bundle, clean-clone/import proof, source-only no-binary flags, and the
next manual maintainer steps. It also rejects missing, malformed, stale, or
too-far-future generated-at timestamps on its direct input summaries, plus
handoff-carried publication dry-run fingerprints that do not match the direct
publication dry-run summary, or release artifact file fingerprints that no
longer match the files on disk. Release artifact paths must also stay under
their expected ignored `build/` output roots, and any reported release asset
fingerprints must stay within the source-only allowlist. Release artifact file
extensions must match the source-only artifact contract. Release artifact
contents must also be readable: Markdown notes must be non-empty, JSON proof
files must parse, and source archives must be valid non-empty ZIP files. JSON
proof artifacts must also match their expected source-only schema contracts
before manual GitHub Release review. The packet is only a manual review aid; it
does not merge, tag, push, publish, or upload anything.

Run `scripts/check-source-publication-gate.ps1` as the final local source publication gate after the
source publication packet exists. The command is read-only, writes ignored
`build/source-publication-gate/` output, records the packet SHA-256 and carried
input/artifact fingerprints, and blocks manual source-only publication when the
packet is stale, unsafe, not ready for manual publish review, or points at
input summaries or artifact files whose current SHA-256 no longer matches the
packet. It does not merge, tag, push, publish, upload assets, or create a
GitHub Release.

## Evidence Rules

Do not mark a blocker complete from intent or memory. Use current evidence:

- merged PR state on GitHub
- exact commit SHA
- local full source release preflight output
- release evidence bundle
- proof manifest
- rendered release notes
- source-only copy check output
- final maintainer review of known limitations
