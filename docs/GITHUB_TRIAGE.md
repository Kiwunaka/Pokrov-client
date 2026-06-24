# GitHub Triage

This repository keeps GitHub labels boring on purpose: labels should route
public work without implying official POKROV support, binary readiness, or
security disclosure in public issues.

The canonical label catalog is [.github/labels.yml](../.github/labels.yml).
Maintainers can sync it with a standard GitHub label-sync tool, or apply labels
manually with the same names, colors, and descriptions.

The machine-readable security intake policy is
[config/security-intake.seed.json](../config/security-intake.seed.json). Keep it
in sync with `SECURITY.md`, `SUPPORT.md`, issue templates, and this triage
guide whenever the private reporting flow changes.

Review routing is defined in [.github/CODEOWNERS](../.github/CODEOWNERS) and
tracked by
[config/codeowners-review.seed.json](../config/codeowners-review.seed.json).
CODEOWNERS is maintainer-led while source-only releases stabilize; it routes
security, release, Android, Windows, runtime, operator contract, source-boundary,
and public-triage changes to the maintainer review path without implying
official support for forks.

## Required Labels

- `bug`: public client or repository process bug.
- `build`: local build, bootstrap, clean-clone, or toolchain problem.
- `docs`: README, docs, release notes, or public copy update.
- `enhancement`: public client or repository improvement request.
- `import`: local key, QR, subscription, file, or third-party catalog import.
- `operator`: operator API, fixture, OpenAPI, or white-label integration.
- `community`: Personal Key / Community Client behavior.
- `android`: Android shell, permissions, runtime, QR camera, or packaging.
- `windows`: Windows shell, runner metadata, runtime, QR camera, or packaging.
- `parser`: key, subscription, catalog, QR payload, or config parser behavior.
- `runtime`: runtime artifacts, routing, DNS, staging, connect/disconnect, or
  diagnostics.
- `release`: source-only proof, preflight, readiness, tags, checksums, or
  release copy.
- `source-boundary`: public/private boundary, source import, secret avoidance,
  or clean-room guard.
- `dependencies`: Dependabot, dependency update, lockfile, or dependency review
  work.
- `security-private`: redirect to private security reporting.
- `help wanted`: public help is welcome after scope and safety boundaries are
  clear.
- `good first issue`: reserved for small, self-contained public tasks after
  maintainer review.

## Safety Rules

- Do not use labels to imply official POKROV support for forks or operator
  builds.
- Do not discuss vulnerabilities, exploit details, private endpoints, leaked
  secrets, signing material, QR payloads, subscription URLs, or account data in
  public issues. Use [SECURITY.md](../SECURITY.md).
- Keep `security-private` as a redirect label, not a public investigation lane.
- When a public issue contains vulnerability details, secrets, QR payloads,
  subscription URLs, signing material, or private backend details, close or
  redact it and redirect the reporter to private security reporting.
- Do not apply `good first issue` until the task is safe for a newcomer, has a
  narrow public scope, and does not require private POKROV backend, signing, billing, deployment, node-management, or release-evidence access.
- Use `release` only for source-only and evidence-backed release work unless a
  separate binary release gate exists.
- CODEOWNERS review is a routing aid, not a guarantee that a pull request is
  official, trusted-signed, store-ready, or production-ready.
- Dependabot pull requests use `dependencies` plus a route-specific label, but
  still require license inventory review, tests, and source-only release
  boundary checks before merge; they do not approve runtime binaries.
