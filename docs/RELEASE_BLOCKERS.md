# Release Blockers

This document mirrors
[`config/release-blocker-inventory.seed.json`](../config/release-blocker-inventory.seed.json).
It records why the current source-readiness candidates are not ready for tag by
default.

The current public source line is not ready for tag until every required blocker
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

Status: not ready for tag.

The blocker inventory deliberately uses `pending_maintainer_review` and
`manual_owner_test` status labels. Local CI can prove many source gates, but it
cannot choose the release commit, merge the PR stack, create the annotated tag,
review final public copy, or manually publish a GitHub Release.

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
publication dry-run summary. The packet
is only a manual review aid; it does not merge, tag, push, publish, or upload
anything.

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
