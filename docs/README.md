# Documentation Index

This repository is a source-only public client workspace. Start here when you
need to build from source, choose a product track, review the operator contract,
or prepare a source-only release.

## First Steps

- [Build from source](BUILD_FROM_SOURCE.md): local requirements, variants,
  dependency setup, tests, and clean-clone proof.
- [Troubleshooting](TROUBLESHOOTING.md): source checkout, dependency, Android,
  Windows, and clean-clone failure routing.
- [Open-source scope](OPEN_SOURCE_SCOPE.md): what is public, what remains
  private, and which claims are not made by this repository.
- [Product variants](PRODUCT_VARIANTS.md): community, operator, and official
  service-mode boundaries.
- [Client product tracks](CLIENT_PRODUCT_TRACKS.md): ordinary-user and
  company/operator client direction.

Before opening a build issue, run the read-only contributor doctor:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Json
```

The doctor checks local commands and required public files. It does not install
dependencies, build artifacts, fetch runtime binaries, copy config, or publish
anything.

## Users And Import

- [Free VPN catalog gate](FREE_VPN_CATALOG_GATE.md): gated third-party public
  config catalog rules and attribution boundaries.
- [GitHub triage](GITHUB_TRIAGE.md): issue routing, labels, and public
  redaction rules.
- [Governance](GOVERNANCE.md): maintainer-led decision rules and CODEOWNERS
  review routing.
- [Support](../SUPPORT.md): where to ask for help without posting private
  keys, QR payloads, subscription URLs, or backend details.
- [Security](../SECURITY.md): private reporting route for vulnerabilities.

## Operators

- [Operator integration](OPERATOR_INTEGRATION.md): expected backend surfaces,
  first-run operator path, and responsibilities.
- [Operator OpenAPI](operator/openapi.yaml): source fixture API contract.
- [White-label branding](WHITE_LABEL_BRANDING.md): neutral token roles and
  operator-owned branding boundary.

## Maintainers

- [Release policy](RELEASE_POLICY.md): source-only release rules.
- [Release checklist](RELEASE_CHECKLIST.md): pre-tag and release evidence
  checks.
- [Required checks](REQUIRED_CHECKS.md): CI job names, branch-protection
  guidance, and source-release gates.
- [Source release template](releases/SOURCE_RELEASE_TEMPLATE.md): GitHub
  Release body shape for source-only tags.
- [Source readiness](releases/source-readiness-v0.2-v0.3.md): tracked
  source-only candidates after `v0.1.0-source`.
- [Changelog](../CHANGELOG.md): evidence-honest release history.
- [Dependency license audit](DEPENDENCY_LICENSE_AUDIT.md): reviewed package
  inventory and remaining binary-release boundaries.
- [Dependency update policy](DEPENDENCY_UPDATE_POLICY.md): Dependabot scope,
  review gates, labels, and source-only boundaries.
