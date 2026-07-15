# POKROV Client v1.0.0 Source Release Design

**Status:** approved design, pending implementation plan

**Date:** 2026-07-15

**Public source repository:** `Kiwunaka/Pokrov-client`

**Private client repository:** `Kiwunaka/POKROV-app`

**Binary distribution repository:** `Kiwunaka/pokrov`

**Target release:** stable, source-only `v1.0.0-source`

## 1. Summary

POKROV Client will ship a stable public source release for Android and Windows
from `Kiwunaka/Pokrov-client`. The public repository will remain the canonical
open-source tree and will expose two independent product tracks:

1. a local-first Community client for user-owned keys, subscriptions, QR input,
   and local profiles; and
2. an Operator foundation for companies that provide their own backend,
   branding, policies, support, signing, and distribution.

The release will use a targeted-promotion model. Portable security and UX
improvements may be adapted from the private client, but the public tree will
not be replaced by a fresh private snapshot. The final repository experience
will combine an engineering-first visual language with explicit Community and
Operator product rails.

`v1.0.0-source` will contain a source archive, checksums, release notes, and a
publish-safe evidence manifest. The detailed maintainer evidence bundle remains
local because its current schema carries workstation paths. The release will not
contain APK, EXE, store, or trusted-signing artifacts or claims.

## 2. Decision Context

The design is based on the following audit state observed on 2026-07-15:

- Public `Pokrov-client/main` was clean and matched `origin/main` at audit SHA
  `ae47b04`.
- The latest source release was the prerelease `v0.172.0-source`; public `main`
  contained later repository-polish changes and had no current stable source
  tag.
- The public repository had no open pull requests. Of 169 closed, unmerged pull
  requests, 167 formed a promoted stack whose final tree was merged through
  PR `#193`. Dependabot PRs `#14` and `#106` were superseded.
- The private client had seven stale or conflicting pull requests. PRs `#1` and
  `#3` contain security/runtime ideas worth re-evaluating. PRs `#2`, `#4`, `#5`,
  `#6`, and `#7` duplicate signing and release-governance proposals that
  conflict with the accepted outside-store beta boundary.
- A scoped private-to-public import audit included 151 tracked files and blocked
  one expected private handoff seed. Among comparable allowlisted files, 65
  matched, 59 differed, and 27 were not present in the public tree. The missing
  files include public app-shell modularization boundaries, so a wholesale
  replacement would be unsafe.
- Public GitHub health and security features were strong, but remote `main`
  protection and repository rulesets were not enabled.
- The exact public `main` push CI was green. A broad local audit run that shared
  mutable fixtures with concurrent checks produced one transient pytest
  failure; the isolated release-evidence suite subsequently passed 28/28. The
  final release suite must run cleanly and sequentially before any release
  claim.

These observations are planning inputs, not release evidence. Implementation
must refresh every remote and local fact against the final candidate SHA.

## 3. Goals

The release must:

- make `Kiwunaka/Pokrov-client` the obvious canonical home for the public client;
- present Community and Operator as equally intentional, independently usable
  tracks;
- make a clean-source build and local fixture-backed evaluation straightforward;
- promote only reviewed, portable fixes from the private client;
- resolve stale pull-request state with explicit, reviewable dispositions;
- provide a premium, coherent, bilingual GitHub repository experience;
- enforce and observe the required GitHub governance and security settings;
- retain exact-SHA evidence for the release candidate;
- publish a stable annotated `v1.0.0-source` tag and source-only GitHub Release;
- preserve historical evidence and avoid rewriting release or pull-request
  history.

## 4. Non-goals

This release will not:

- publish APK, AAB, EXE, MSI, store, or signed binary artifacts;
- claim physical-device, store-review, trusted-signing, production-provider,
  official-backend, RU-origin, or binary-install readiness without separate
  current evidence;
- open the official POKROV backend, billing, bot, admin, deployment, signing, or
  provider operations;
- copy the private repository wholesale or publish private handoff material;
- merge stale or conflicting pull requests merely to reduce their count;
- rewrite or delete retained historical evidence, tags, branches, or pull
  requests;
- redesign unrelated client features or introduce a separate documentation site.

## 5. Approaches Considered

### 5.1 Targeted promotion — selected

Keep public `main` authoritative. Compare candidate private changes at the
behavior and module level, adapt only portable improvements, and land each
coherent change through public contracts and tests.

This preserves the current Community/Operator overlays, keeps diffs reviewable,
and minimizes accidental private dependency or secret exposure. It requires
more deliberate reconciliation than a snapshot replacement, but it provides the
strongest release provenance.

### 5.2 Fresh sanitized private snapshot

Re-export the current private tree and reapply public overlays. This starts from
newer private code but produces a broad, hard-to-review replacement and risks
losing public modularization, variants, documentation, and evidence boundaries.

### 5.3 Presentation-only release

Polish the public repository and release current code with minimal parity work.
This is fastest, but it leaves security/runtime candidates unresolved and does
not meet the credibility threshold for a stable `v1.0.0-source` release.

## 6. Repository and Product Boundaries

### 6.1 Public source lane

`Kiwunaka/Pokrov-client` owns:

- public Android and Windows source;
- shared client packages and public platform contracts;
- Community and Operator variants;
- fixture backend and safe public examples;
- build-from-source, security, contribution, and release documentation;
- source-only release artifacts and public evidence.

All public changes are implemented against this repository's contracts. Private
file layout alone is not sufficient reason to replace a public module.

### 6.2 Community track

The Community variant is usable without an Operator or official POKROV API. It
supports user-owned local keys, QR input, subscriptions, local profiles, and
documented optional third-party catalog behavior. It must not silently upload
user-owned material or fall back to a production service.

### 6.3 Operator track

The Operator variant is a foundation, not a hosted service. It exposes a
documented API contract, fixture implementation, brand tokens, support links,
and policy configuration. Operators own backend compatibility, legal terms,
privacy, support, signing, distribution, and runtime claims.

### 6.4 Official service boundary

The existing `pokrov` variant remains in the public source tree as a non-default
compatibility and reproducibility variant for official builds. It is not a third
open-source product track. Its public endpoints and trademark restrictions stay
explicit, and forks are directed to Community or Operator instead of reusing
POKROV identity or release channels. Neither Community nor fixture-backed
Operator evaluation depends on the `pokrov` variant or private infrastructure.

### 6.5 Private and binary lanes

`Kiwunaka/POKROV-app` is a candidate source of selected portable changes. Its
clean local state, unpushed commits, retained evidence, and private configuration
are not automatically authorized for publication or push.

`Kiwunaka/pokrov` remains the binary distribution repository. No binary asset is
copied from it into `v1.0.0-source`.

## 7. Portable Change Promotion

Each private candidate follows this flow:

```text
private behavior/diff
  -> explicit public allowlist
  -> secret and private-boundary scan
  -> adaptation to public interfaces
  -> Community and Operator tests
  -> focused public pull request
  -> required checks
  -> squash merge
```

Promotion rules:

- inspect behavior and tests before copying code;
- use the existing public module and package boundaries;
- reject private endpoints, identities, tokens, raw provider data, handoff
  packets, signing material, and release evidence;
- preserve the importer block for `config/release-handoff.seed.json` and extend
  deny rules only from concrete findings;
- add a regression test for every promoted security or failure-mode change;
- preserve Community independence and fixture-backed Operator evaluation;
- avoid unrelated refactoring and formatting churn.

The private-change scope for `v1.0.0-source` is bounded as follows:

| Candidate | v1 disposition | Required public behavior |
| --- | --- | --- |
| Private PR `#1`: Windows system proxy/TUN safety | Promote the behavior through a new public implementation; do not merge the stale patch | `fullTunnel` and `allExceptRu` stay TUN-backed; system-proxy compatibility is explicit and limited to `selectedApps`; host establishment and displayed protection state agree |
| Private PR `#3`: updater download trust | Promote an OSS-safe adaptation; do not copy private host rules unchanged | HTTPS, no userinfo, positive size, valid SHA-256, and a variant-owned trusted-origin policy are required before prompting; Community has no implicit production origin; the checksum is visible |
| Private app-shell/UI files missing from the public modular tree | Defer wholesale import | Existing public UI remains authoritative; only UI needed to expose the two security behaviors or produce truthful fixture-backed screenshots may change |
| Private signing/governance PRs `#2`, `#4`-`#7` | Reject as code input and close as superseded | Keep the accepted outside-store beta and source-only policy until separate binary evidence exists |
| Existing public `pokrov` service variant | Keep and audit | Non-default official-build compatibility variant; never a dependency of Community or fixture-backed Operator |

Each row must end with one recorded disposition: promoted with public tests,
already satisfied with exact test evidence, or rejected with a concrete reason.
The first two rows are release-blocking until that disposition exists. No other
private feature or UI drift is in scope for `v1.0.0-source`.

## 8. Pull-request Disposition and Merge Line

### 8.1 Existing public history

Do not reopen or merge the already promoted PR stack. Retain the historical
closed state and document only the audit conclusion when useful. Superseded
Dependabot PRs remain closed unless the current dependency action version still
requires a new, independently generated update.

### 8.2 Existing private pull requests

- PRs `#1` and `#3`: inspect and extract valid behavior into new focused PRs.
  Close the originals as superseded only after their useful changes have a clear
  destination or an evidence-backed rejection.
- PRs `#2`, `#4`, `#5`, `#6`, and `#7`: close with a concise explanation that
  points to the canonical outside-store beta and source-release policy. Do not
  merge contradictory governance proposals.
- Do not force-push or rewrite old PR branches.

### 8.3 New public merge sequence

The selected model for v1 is **sequential pull requests to `main`**, not another
long-lived stacked branch chain. The intended sequence is:

1. runtime and security parity;
2. Community and Operator UX, fixtures, and examples;
3. repository presentation, visual assets, and documentation;
4. GitHub governance, automation, and evidence hardening;
5. final release candidate PR.

Each PR targets the then-current `main`, is focused, carries its own tests and
canonical documentation impact, passes current required checks, and is
squash-merged before the next PR is opened or rebased. A change may be combined
with an adjacent step only when separating it would make review or rollback
less clear.

The current release evidence scripts encode the historical v0.172 stacked
branch chain and cannot prove this model. Before the first v1 release PR is
treated as release evidence, the evidence contract is migrated to a versioned
sequential-promotion manifest. `config/release-promotion.schema.json` owns the
generated contract. `config/release-promotion-policy.seed.json` is the tracked
policy and contains only facts knowable before merge: repository, previous
release baseline, merge strategy, required checks, allowed states, and output
root. It does not contain self-referential PR head, merge, or candidate SHAs.

After the final release PR merges, the read-only
`scripts/prepare-release-promotion.ps1` discovers every commit and associated
merged PR between the peeled previous release tag and the exact candidate,
queries current GitHub metadata, and writes the completed instance to ignored
`build/release-promotion/v1.0.0-source/release-promotion.json`. The instance
records, in order, each PR URL, head SHA, squash/merge SHA, PR-head check
conclusions, merged state, and resulting `main` SHA. Direct or unmapped commits,
multiple ambiguous PR mappings, a non-squash result, or a missing final release
PR are blockers.

The verifier proves that each recorded merge SHA is an ancestor of the next and
that the last resulting SHA equals the release candidate. PR-head checks prove
the promotion decision only; they are never projected as exact release-commit
CI. Because the completed instance is post-merge evidence rather than tracked
source, it can describe the final release PR without creating a recursive
follow-up PR.

The v0.172 stack manifest and its conclusions remain retained historical input;
they are not rewritten to look like sequential merges. Merge-order, GitHub
status, source-readiness, merge-handoff, publication-packet, and related tests
must consume the v1 manifest when the candidate tag is `v1.0.0-source`. The
release is blocked until that migration has tests and the canonical
documentation no longer instructs v1 maintainers to build another legacy stack.

## 9. Repository Experience and Visual System

### 9.1 Direction

The selected direction is **Protocol first, product rails**:

- warm technical background: `#F3F1E9`;
- primary ink: `#111827`;
- Community rail: `#D6FF3F`;
- Operator rail: `#FFB544`;
- verification accent: `#55EFC4`;
- optional deep product accent: `#2458FF`.

The engineering language is dominant: restrained grid, high-contrast typography,
monospace proof elements, and compact status labels. Bright product colors are
reserved for navigation between Community and Operator, not used as decoration.

### 9.2 README information architecture

The primary English README is a concise product and engineering landing page:

1. hero with one-sentence value proposition and source-only status;
2. Community and Operator route cards;
3. current capability and non-goal summary;
4. deterministic quick start using public fixtures;
5. real application screenshots;
6. architecture and configuration flow;
7. build, verify, security, contribution, and support links;
8. exact release and binary-repository boundary.

The Russian README mirrors the same claims and destinations. A language switch
is visible above the first long-form section. Badges remain compact and support
the content rather than replacing it.

### 9.3 Visual assets

Create reusable source assets under `assets/brand/` and documented renders for:

- the repository hero;
- Community and Operator track cards;
- public architecture and configuration flow;
- release verification/status card;
- the GitHub social preview.

Diagrams use SVG source with accessible text and alt text. Raster renders are
generated only where GitHub settings or predictable display require them. The
social preview uses the selected visual system and remains legible at small
sizes.

Application screenshots must come from the real app rendered with deterministic
fixture data. They must not show private endpoints, customer/provider data,
credentials, or imply that a source-only artifact is an installable release.

### 9.4 Documentation routes

The documentation index gives short, non-duplicative routes for:

- build from source;
- Community use and local import;
- Operator integration and white-label configuration;
- product variants and architecture;
- security and diagnostics;
- contribution and governance;
- source-release verification.

Canonical documents remain the owners of detailed behavior. README copy links
to those owners instead of duplicating release truth.

## 10. GitHub Governance

Remote settings must be configured and then observed, not merely documented.
The target `main` ruleset is:

- pull requests required for changes;
- force-push and branch deletion blocked;
- required status checks must pass on the current head;
- review conversations must be resolved;
- squash merge is the normal merge strategy;
- administrator or automation bypass is kept minimal and documented.

If a one-person maintainer setup cannot satisfy a mandatory human approval, the
ruleset may require a PR with zero approvals while still enforcing current-head
checks and conversation resolution. It must not claim an approval policy that
cannot operate in the actual repository.

Keep or improve:

- CODEOWNERS and contribution routing;
- Dependabot version and security updates;
- secret scanning and push protection;
- private vulnerability reporting;
- issue forms, pull-request template, labels, Discussions, topics, description,
  and social preview.

`scripts/check-github-ruleset.ps1` and the canonical ruleset seed must match the
observed remote configuration. A failed or inaccessible remote check is
`BLOCKED_BY_ACCESS`, not `PASS`.

For this stable v1 source release, configured and observed `main` governance is
a publication blocker. `BLOCKED_BY_ACCESS`, a missing ruleset, or missing
required checks prevents the final tag push and GitHub Release. This deliberately
tightens the older policy that merely prohibited enforcement claims; the
canonical ruleset, blocker inventory, source-readiness policy, release scripts,
and tests must be updated together. Work may continue locally while access is
blocked, but publication may not.

## 11. Runtime and Failure-mode Requirements

The release must preserve these invariants:

- Community startup never requires an Operator or official-service base URL.
- Operator startup requires explicit, valid configuration or a documented local
  fixture; it does not silently select production.
- Malformed or incomplete configuration produces actionable user and developer
  errors.
- Updater metadata fails closed when required URL, integrity, version, or policy
  fields are invalid.
- Windows proxy/TUN integration does not report a protected state that the host
  did not establish.
- Subscription refresh preserves the last valid local state on transient
  failure and surfaces the failure honestly.
- Examples and screenshots contain only synthetic data.

No fallback may cross from an open-source track into private production merely
to keep a demo or test green.

## 12. Verification Design

### 12.1 Change-level checks

Every focused PR runs the smallest checks proving its change, plus affected
regressions. Security/runtime promotions include negative tests. Documentation
and asset changes include link, render, contract, and `git diff --check`
validation.

### 12.2 Release-candidate checks

The final candidate runs sequentially in a clean worktree or clone:

1. source-import and private-boundary checks;
2. secret and forbidden-artifact checks;
3. seed, schema, link, and documentation validation;
4. Flutter format, analyze, unit, and widget tests;
5. Python policy and release-tool tests;
6. Android native tests and an Android source build smoke;
7. Windows source build smoke on a compatible Windows runner;
8. Community, Operator fixture, invalid-config, updater, and Windows runtime
   regression coverage;
9. v1 sequential-promotion, GitHub status, tag-readiness, and ruleset contract
   tests;
10. all required GitHub Actions jobs on the final post-squash `main` push, with
    every job conclusion bound to the exact candidate SHA;
11. clean-clone and the complete local publication chain through the final
    source-publication gate;
12. public evidence projection schema, exact-SHA binding, path-leak,
    secret-pattern, and artifact
    fingerprint tests;
13. final clean status and `git diff --check`.

Tests that currently mutate tracked seed files must use temporary copies or
serialize and restore state reliably. The release run must not share its
working tree with doctor, fixture, or policy commands running concurrently.

### 12.3 Evidence labels

Evidence uses only explicit labels such as `PASS`, `MANUAL_OWNER_TEST`,
`OPERATOR_ATTESTED`, `SKIPPED_BY_OWNER`, `SKIPPED_BY_OPERATOR`,
`BLOCKED_BY_ACCESS`, and `NOT_REQUESTED`.

Physical-device, store, signing, provider-dashboard, and external-origin checks
remain manual unless fresh evidence for the exact candidate is retained. Their
absence does not block a source-only release unless the canonical source gate
explicitly requires them, but they are never converted into a pass.

## 13. Release Data Flow

The release proceeds through the complete canonical chain, extended for the v1
sequential-promotion contract:

```text
sequential focused PRs -> protected main
  -> final release PR with final feature/limitation source copy
  -> squash merge -> exact main SHA -> exact-main required CI
  -> post-merge v1 promotion manifest generation
  -> v1 merge-order verification
  -> v1 GitHub PR/status verification
  -> observed ruleset verification
  -> clean untagged source preflight on exact SHA
  -> source-tag readiness
  -> local annotated v1.0.0-source tag
  -> clean tag-required source preflight
  -> deterministic final release-body render and copy check
  -> local maintainer evidence bundle
  -> source-publication dry-run
  -> release merge handoff
  -> source-publication packet
  -> publish-safe manifest generation and safety validation
  -> final source-publication gate over packet and public assets
  -> push exact tag
  -> stable GitHub Release with allowlisted assets
  -> remote tag/release/assets/checks/ruleset verification
```

Current canonical tools remain the owners of tag readiness, merge-order status,
GitHub status, preflight, evidence bundle, publication dry-run, merge handoff,
publication packet, and final publication gate. Their seeds, documentation, and
tests are migrated together so the v1 summaries all identify the same tag,
exact commit, final release PR, promotion manifest, and input fingerprints.
For v1, `check-source-publication-gate.ps1` is extended to consume the generated
public evidence manifest and `SHA256SUMS`, recalculate their contents and
fingerprints, and include them in its final ready/not-ready decision.

The tag is annotated. Before it is pushed, `source-release-preflight.ps1` runs
with `-RequireTag`, and every downstream local artifact through
`check-source-publication-gate.ps1` must resolve to the intended tag object and
peeled commit. After push, the tag is immutable for operational purposes; any
defect is corrected through a new patch release, never by moving the tag.

The final release PR includes `docs/releases/v1.0.0-source.md` as the complete
human-authored source for feature status and known limitations. It contains no
manually guessed SHA or checksum. Tag-required preflight combines that tracked
copy with the tag proof and archive checksum to render the final release body,
runs `check-source-release-copy.ps1`, and fingerprints the exact rendered file.
The evidence bundle, dry-run, handoff, packet, and final gate carry that same
fingerprint, calculated from canonical UTF-8/LF bytes. GitHub publication uses
the exact content unchanged. A copy change
after the final PR changes the candidate SHA and requires a new local tag plus a
complete rerun; a generated-body change after preflight also requires rerunning
the full downstream fingerprint chain.

### 13.1 Artifact classification

| Phase | Producer | Main output | Classification | Blocking condition |
| --- | --- | --- | --- | --- |
| Promotion discovery | `prepare-release-promotion.ps1` | Completed sequential promotion manifest | Local maintainer | Direct/unmapped commit, ambiguous PR, wrong merge strategy, or incomplete range |
| Promotion order | v1 mode of `check-release-merge-order.ps1` | Sequential promotion summary | Local maintainer | Missing, unordered, unmerged, or candidate SHA mismatch |
| GitHub PR status | v1 mode of `check-release-stack-github-status.ps1` | PR/check snapshot | Local maintainer | Wrong repository, state, SHA, URL, or required check |
| Exact candidate CI | GitHub Actions `push` run on `main` | Required job conclusions and public run URLs | Remote public evidence | Any required job missing, stale, non-successful, or checked against another SHA |
| Remote governance | `check-github-ruleset.ps1` | Ruleset report | Local maintainer | Report inaccessible, stale, or not passing |
| Tag readiness | `check-source-tag-readiness.ps1` | Tag-readiness summary | Local maintainer | Any required blocker or candidate inconsistency |
| Source proof | `source-release-preflight.ps1 -RequireTag` | Archive, final rendered body, proof, preflight summary | Mixed; raw summary stays local | Tests, tag proof, clean-clone, source, Windows, final copy, or fingerprint check fails |
| Evidence | `prepare-release-evidence-bundle.ps1` | Detailed evidence bundle | Local maintainer only | Missing or mismatched preflight/ruleset evidence |
| Publication dry-run | `validate-source-release-publication.ps1` | Dry-run summary | Local maintainer | Claims, artifacts, or fingerprints fail |
| Merge handoff | `prepare-release-merge-handoff.ps1` | Merge handoff | Local maintainer | Promotion, GitHub, tag, or dry-run summary fails |
| Publication packet | `prepare-source-publication-packet.ps1` | Full publication packet | Local maintainer only | Input freshness, schema, root, or fingerprint failure |
| Public projection | New `scripts/prepare-public-release-manifest.ps1` | `v1.0.0-source-public-evidence.json` and `SHA256SUMS` | Public release asset | Any non-allowlisted field, path, secret pattern, or hash mismatch |
| Final gate | Extended `check-source-publication-gate.ps1` | Publication-gate summary | Local maintainer | Packet or public asset unsafe, stale, inconsistent, hash-mismatched, or not ready |

“Local maintainer” artifacts remain in ignored build output and are retained by
the maintainer as release evidence. They are not uploaded, committed, pasted
into release notes, or copied into public artifacts.

### 13.2 Public evidence schema

The public manifest is a projection, not a renamed copy of the local bundle. Its
canonical schema is `config/public-release-evidence.schema.json`. Its field
allowlist is limited to:

- schema version and repository identifier;
- tag, tag object SHA, and peeled commit SHA;
- source archive basename, size, and SHA-256;
- required-check names, conclusions, exact `checked_sha` values, public GitHub
  run URLs, workflow run IDs, and run-attempt numbers;
- observed ruleset result and observation time;
- source-only flags and UTC generation time.

It contains no absolute or repository-local paths, usernames, home/temp
directories, hostnames, environment variables, tool command lines, private PR
URLs, raw provider responses, or arbitrary nested fields. Artifact references
are basenames only. Tests reject Windows drive paths, UNC paths, `/Users/`,
`/home/`, temp/build roots, path traversal, secret patterns, and fields outside
the schema before upload.

Every required-check entry must have `checked_sha` equal to the manifest's
peeled release `commit_sha`. PR-head checks whose SHA differs after squash are
promotion evidence only and cannot appear in the public required-check list.
The manifest renderer fetches or consumes the final `main` push run for the
candidate SHA and refuses missing, duplicate, stale, or non-successful required
jobs.

`config/release-promotion.schema.json` and
`config/public-release-evidence.schema.json` start with independent
`schema_version: 1` contracts, declare JSON Schema Draft 2020-12, and use stable
`$id` values `urn:pokrov-client:schema:release-promotion:1` and
`urn:pokrov-client:schema:public-release-evidence:1`. Breaking changes increment
the relevant version and `$id`; validators retain read support for
already-published versions and refuse unknown newer versions. The historical
v0.172 stack seed remains under its existing schema and is never silently
reinterpreted as a v1 promotion manifest.

### 13.3 Checksum file

`SHA256SUMS` is UTF-8 with LF endings. Each line is lowercase 64-character
SHA-256, two ASCII spaces, and an asset basename. Lines are sorted by basename.
It covers the uploaded source archive and public evidence manifest, but not
itself. Paths, comments, wildcard syntax, and duplicate basenames are refused.
The final gate recalculates both hashes immediately before upload.

Release assets are limited to the allowlisted source archive, SHA-256 checksum
file, and public evidence manifest. Release notes live in the GitHub Release
body. Raw preflight summaries, proof working files, ruleset reports, evidence
bundles, merge handoffs, and publication packets are never release assets.
GitHub-generated source links may coexist with the project archive, but the
release notes identify exactly which checksum applies to which uploaded asset.

The final GitHub Release is stable rather than a prerelease and explicitly says:

- source-only;
- no APK or EXE;
- no store publication;
- no trusted-signing claim;
- what Community and Operator currently support;
- known limitations and verification instructions.

## 14. Failure Handling and Recovery

- A failed required check blocks merge.
- A dirty or concurrently mutated release worktree invalidates that run; rerun
  from a clean isolated candidate.
- A source-boundary or secret finding blocks promotion until the candidate is
  removed or safely redesigned.
- An inaccessible or failing GitHub governance check blocks tag push and release
  publication for v1; it is reported as `BLOCKED_BY_ACCESS` or failed and is not
  represented as enabled.
- A failed local tag proof prevents tag push. An unpushed candidate tag may be
  recreated only after the candidate is corrected and reverified.
- A failure discovered after publication produces a documented patch release or
  withdrawal notice. Published tag history is not rewritten.

Generated evidence remains under ignored build output unless an artifact is
explicitly classified as public and included in the release allowlist.
Generating the public projection never mutates or sanitizes the retained local
bundle in place.

## 15. Acceptance Criteria

The project is complete when all of the following are true for the exact release
candidate:

- Community and Operator variants satisfy their independence and configuration
  contracts;
- selected private security/runtime candidates have an explicit promoted,
  rejected, or superseded disposition;
- all seven stale private PRs and all public PR history are left in an accurate,
  understandable state;
- the bilingual README, documentation index, runnable fixture examples, real
  screenshots, SVG diagrams, and social preview use the approved visual system;
- canonical documentation matches implemented behavior and release limits;
- the required local and CI checks pass sequentially on the exact candidate;
- each public required-check entry records `checked_sha` equal to the tagged
  commit, and no PR-head-only result is presented as release-candidate proof;
- remote `main` governance is configured and verified with the required checks;
- the v1 sequential-promotion contract, merge handoff, publication packet, and
  final publication gate all resolve to the exact release candidate;
- an annotated `v1.0.0-source` tag points to the verified public commit;
- the stable GitHub Release contains only the allowlisted source archive,
  checksum file, public evidence manifest, and source-only release body;
- the published release body is content-identical, after canonical UTF-8/LF
  normalization, to the final checked and fingerprinted rendered body carried
  through the publication packet and gate;
- no local maintainer evidence artifact or absolute workstation path appears in
  a public asset;
- the remote release is re-read after publication and matches retained evidence;
- no unrun, manual, inaccessible, binary, store, signing, or provider check is
  described as passed.

## 16. Implementation Planning Boundary

This document defines the approved design. The implementation plan must split
work into reviewable PR-sized tasks, refresh all audit facts before remote
mutation, identify exact canonical documents and tests for each promoted
behavior, and keep GitHub publication as the final guarded phase.
