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
