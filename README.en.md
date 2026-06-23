# POKROV Client

<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
  <a href="https://github.com/Kiwunaka/Pokrov-client/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Kiwunaka/Pokrov-client/ci.yml?branch=main&style=for-the-badge&label=CI"></a>
  <img alt="Source status: snapshot imported" src="https://img.shields.io/badge/source-snapshot%20imported-0f766e?style=for-the-badge">
  <img alt="Platforms: Android and Windows" src="https://img.shields.io/badge/platforms-Android%20%2B%20Windows-2563eb?style=for-the-badge">
  <img alt="Client modes: community and operator" src="https://img.shields.io/badge/modes-community%20%2B%20operator-111827?style=for-the-badge">
</p>

<p align="center">
  <strong>An open client for a calm, app-first connection experience.</strong>
  <br>
  Android and Windows first. GPLv3. Sanitized source snapshot imported.
</p>

<p align="center">
  <a href="README.md">Language index</a>
  &middot;
  <a href="README.ru.md">Русский</a>
  &middot;
  <a href="docs/OPEN_SOURCE_SCOPE.md">Scope</a>
  &middot;
  <a href="docs/ENTERPRISE.md">Enterprise</a>
  &middot;
  <a href="SECURITY.md">Security</a>
  &middot;
  <a href="BRAND.md">Brand</a>
</p>

---

## What This Is

POKROV Client is the public source home for the POKROV Android and Windows
client app.

The repository contains the public project structure, contribution rules,
security policy, release policy, brand boundary, source-import checklist, and
the first sanitized Android + Windows client source snapshot.

## Product Modes

- Personal Key Client / Community client: neutral, no POKROV branding, no POKROV API calls by
  default, local import for single `vless://`, `trojan://`, `ss://`, and
  `vmess://` keys, local multi-profile selection, subscription URL import and
  refresh, Android/Windows QR import, and gated third-party catalog metadata.
- Operator / Company Client: a white-label path for companies that want to connect the
  app to their own backend, billing, support, and brand.
- POKROV Service Mode: documented for official POKROV builds only. Forks and
  operators must not distribute builds using POKROV names, logos, endpoints,
  support, or release claims.

The optional third-party public config catalog remains disabled by default and
must stay clearly labeled as not official POKROV nodes. It is not a default free
POKROV service and does not promise availability, safety, privacy, speed, or
uptime.

The Personal Key Client makes no POKROV API calls by default. This repository
does not provide POKROV nodes or a default free service.

## First-Run Paths

| Track | Use it when | Start here |
| --- | --- | --- |
| Personal Key Client | You already have a key, QR code, or subscription URL and want a local-only client. | Build the `community` variant, paste a `vless://`, `trojan://`, `ss://`, or `vmess://` key, scan a QR code, or add a subscription URL. |
| Operator / Company Client | You run a service and want your own branded client. | Run the local fixture backend, export white-label color tokens, implement the minimal managed-profile contract, then wire your own API, support, billing, signing, and release channels. |
| POKROV Service Mode | You are producing an official POKROV build. | Use official POKROV release channels and private release gates. Forks and operator builds are not official POKROV builds. |

## Which App Should I Use?

- Official POKROV users should use official POKROV release channels and
  support links.
- Community source users bring their own local keys or subscription URLs. This
  repository does not provide POKROV nodes or a default free service.
- Operator builds are supported by the operator that built and distributed
  them, not by POKROV official support.

## Status

<p align="center">
  <img src="assets/brand/oss-status-card.png" alt="POKROV Client repository status artwork" width="100%">
</p>

| Area | Current state |
| --- | --- |
| Repository | Public foundation ready |
| Source code | Sanitized Android + Windows snapshot imported |
| Community mode | Local profiles, subscription import/refresh, Android/Windows QR import |
| Operator mode | Fixture API, OpenAPI contract, and white-label token export documented |
| Platforms | Android and Windows first |
| License | GNU GPLv3 |
| Official backend | Operated separately by POKROV |
| Public releases | Beta-safe claims only |

## Source Release Status

| Milestone | Status | Scope |
| --- | --- | --- |
| `v0.1.0-source` | Tagged | First source-only Android/Windows snapshot with local community import. No APK/EXE. |
| `v0.2.0-source` | Not tagged | Community import hub polish, variant-boundary enforcement, and source-import hardening are on `main`; release tag pending. |
| `v0.3.0-source` | Not tagged | Operator fixture, Free VPN catalog gate, white-label token export, and foreground subscription scheduler are on `main`; release tag pending. |
| `v0.4.0-source` | Pending stacked PR, not tagged | Native Android/Windows host brand-boundary hardening is in the stacked PR queue. |
| `v0.5.0-source` | Pending stacked PR, not tagged | Community routing and WARP copy honesty hardening is in the stacked PR queue. |
| `v0.6.0-source` | Pending stacked PR, not tagged | Dependency/license and generated-asset provenance gates are in the stacked PR queue. |
| `v0.7.0-source` | Pending stacked PR, not tagged | Source-release proof helper for archive SHA-256 and proof manifests is in the stacked PR queue. |
| `v0.8.0-source` | Pending stacked PR, not tagged | Source readiness matrix for tracked source-only milestones is in the stacked PR queue. |
| `v0.9.0-source` | Pending stacked PR, not tagged | Public onboarding and triage hardening is in the stacked PR queue. |
| `v0.10.0-source` | Pending stacked PR, not tagged | Operator API contract hardening is in the stacked PR queue. |
| `v0.11.0-source` | Pending stacked PR, not tagged | Gated Free VPN catalog cache actions are in the stacked PR queue. |
| `v0.12.0-source` | Pending stacked PR, not tagged | Source-readiness synchronization through the catalog cache slice is in the stacked PR queue. |
| `v0.13.0-source` | Pending stacked PR, not tagged | Default-disabled `OPEN_CLIENT_ENABLE_FREE_CATALOG` import gate is in the stacked PR queue. |
| `v0.14.0-source` | Pending stacked PR, not tagged | Source-readiness synchronization through the feature-flag slice is in the stacked PR queue. |
| `v0.15.0-source` | Pending stacked PR, not tagged | Operator support ticket path canonicalization is in the stacked PR queue. |
| `v0.16.0-source` | Pending stacked PR, not tagged | Community local-access wording and model guards are in the stacked PR queue. |
| `v0.17.0-source` | Pending stacked PR, not tagged | Seed-backed variant command preview tooling is in the stacked PR queue. |
| `v0.18.0-source` | Pending stacked PR, not tagged | Proof-backed source release notes rendering is in the stacked PR queue. |
| `v0.19.0-source` | Pending stacked PR, not tagged | Annotated source tag enforcement is in the stacked PR queue. |
| `v0.20.0-source` | Pending stacked PR, not tagged | End-to-end proof-to-release-notes smoke is in the stacked PR queue. |
| `v0.21.0-source` | Pending stacked PR, not tagged | Self-documenting release-note verification is in the stacked PR queue. |
| `v0.22.0-source` | Pending stacked PR, not tagged | One-command source-release preflight is in the stacked PR queue. |
| `v0.23.0-source` | Pending stacked PR, not tagged | CI source-release preflight smoke is in the stacked PR queue. |
| `v0.24.0-source` | Pending stacked PR, not tagged | Specialized GitHub triage templates are in the stacked PR queue. |
| `v0.25.0-source` | Pending stacked PR, not tagged | GitHub label catalog and triage policy are in the stacked PR queue. |
| `v0.26.0-source` | Pending stacked PR, not tagged | Runtime artifact manifest gate and local-only libcore review metadata are in the stacked PR queue. |
| `v0.27.0-source` | Pending stacked PR, not tagged | Source release copy-claims gate is in the stacked PR queue. |
| `v0.28.0-source` | Pending stacked PR, not tagged | Free VPN catalog provenance gate is in the stacked PR queue. |
| `v0.29.0-source` | Pending stacked PR, not tagged | Private security intake gate is in the stacked PR queue. |
| `v0.30.0-source` | Pending stacked PR, not tagged | Changelog and release-history gate is in the stacked PR queue. |
| `v0.31.0-source` | Pending stacked PR, not tagged | Contributor doctor and docs index gate is in the stacked PR queue. |
| `v0.32.0-source` | Pending stacked PR, not tagged | Build troubleshooting router is in the stacked PR queue. |
| `v0.33.0-source` | Pending stacked PR, not tagged | CODEOWNERS review-routing gate is in the stacked PR queue. |
| `v0.34.0-source` | Pending stacked PR, not tagged | Dependabot dependency update policy gate is in the stacked PR queue. |
| `v0.35.0-source` | Pending stacked PR, not tagged | Required checks policy gate is in the stacked PR queue. |
| `v0.36.0-source` | Pending stacked PR, not tagged | GitHub ruleset setup gate is in the stacked PR queue. |
| `v0.37.0-source` | Pending stacked PR, not tagged | GitHub ruleset verifier is in the stacked PR queue. |
| `v0.38.0-source` | Pending stacked PR, not tagged | Release evidence bundle helper is in the stacked PR queue. |
| `v0.39.0-source` | Pending stacked PR, not tagged | Source release publication dry-run validator is in the stacked PR queue. |
| `v0.40.0-source` | Pending stacked PR, not tagged | Enterprise boundary and operator commercial-license guard is in the stacked PR queue. |
| `v0.41.0-source` | Pending stacked PR, not tagged | Safe diagnostics copy/export for support without keys or subscription links is in the stacked PR queue. |
| `v0.42.0-source` | Pending stacked PR, not tagged | Privacy-first diagnostics export policy gate is in the stacked PR queue. |
| `v0.43.0-source` | Pending stacked PR, not tagged | Release blocker inventory for source tag readiness is in the stacked PR queue. |
| `v0.44.0-source` | Pending stacked PR, not tagged | Source tag readiness command is in the stacked PR queue. |
| `v0.45.0-source` | Pending stacked PR, not tagged | Release merge-order verifier is in the stacked PR queue. |
| `v0.46.0-source` | Pending stacked PR, not tagged | Release stack GitHub status verifier is in the stacked PR queue. |
| `v0.47.0-source` | Pending stacked PR, not tagged | Release merge handoff helper is in the stacked PR queue. |
| `v0.48.0-source` | Pending stacked PR, not tagged | Android device validation and release merge handoff default-path fix are in the stacked PR queue. |
| `v0.49.0-source` | Pending stacked PR, not tagged | Operator request trace and client-version headers are in the stacked PR queue. |
| `v0.50.0-source` | Pending stacked PR, not tagged | Android native Gradle CI through source-only stubs is in the stacked PR queue. |
| `v0.51.0-source` | Pending stacked PR, not tagged | Windows bundle verifier source-only proof is in the stacked PR queue. |
| `v0.52.0-source` | Pending stacked PR, not tagged | Runtime archive extraction hardening is in the stacked PR queue. |
| `v0.53.0-source` | Pending stacked PR, not tagged | Windows verifier CI/preflight enforcement is in the stacked PR queue. |
| `v0.54.0-source` | Pending stacked PR, not tagged | Release evidence bundle Windows proof gate is in the stacked PR queue. |
| `v0.55.0-source` | Pending stacked PR, not tagged | Publication dry-run Windows proof gate is in the stacked PR queue. |
| `v0.56.0-source` | Pending stacked PR, not tagged | Release merge handoff publication proof gate is in the stacked PR queue. |
| `v0.57.0-source` | Pending stacked PR, not tagged | Release merge handoff input fingerprints are in the stacked PR queue. |
| `v0.58.0-source` | Pending stacked PR, not tagged | Release merge handoff source-only flags are in the stacked PR queue. |
| `v0.59.0-source` | Pending stacked PR, not tagged | Release merge handoff canonical input roots are in the stacked PR queue. |
| `v0.60.0-source` | Pending stacked PR, not tagged | Release merge handoff input timestamps are in the stacked PR queue. |
| `v0.61.0-source` | Pending stacked PR, not tagged | Release merge handoff input schema/read-only checks are in the stacked PR queue. |
| `v0.62.0-source` | Pending stacked PR, not tagged | Release merge handoff stack-count consistency checks are in the stacked PR queue. |
| `v0.63.0-source` | Pending stacked PR, not tagged | Release merge handoff input-error checks are in the stacked PR queue. |
| `v0.64.0-source` | Pending stacked PR, not tagged | Release merge handoff tag-readiness input-error coverage is in the stacked PR queue. |
| `v0.65.0-source` | Pending stacked PR, not tagged | Release merge handoff tag-readiness blocker-count consistency is in the stacked PR queue. |
| `v0.66.0-source` | Pending stacked PR, not tagged | Release merge handoff tag-readiness blocker entry-shape checks are in the stacked PR queue. |
| `v0.67.0-source` | Pending stacked PR, not tagged | Release merge handoff tag-readiness ready-flag consistency is in the stacked PR queue. |
| `v0.68.0-source` | Pending stacked PR, not tagged | Release merge handoff tag-readiness blocker-absence consistency is in the stacked PR queue. |
| `v0.69.0-source` | Pending stacked PR, not tagged | Source tag-readiness open-blocker evidence fields are in the stacked PR queue. |
| `v0.70.0-source` | Pending stacked PR, not tagged | Release merge handoff tag-readiness latest stacked PR consistency is in the stacked PR queue. |
| `v0.71.0-source` | Pending stacked PR, not tagged | Release merge handoff default candidate paths are kept in sync with blocker inventory. |
| `v0.72.0-source` | Pending stacked PR, not tagged | Release merge handoff runtime candidate and PR checks are matched to blocker inventory. |
| `v0.73.0-source` | Pending stacked PR, not tagged | Source tag readiness rejects stale requested tags outside blocker inventory latest candidate. |
| `v0.74.0-source` | Pending stacked PR, not tagged | Source tag readiness checks milestone evidence against blocker inventory latest PR. |
| `v0.75.0-source` | Pending stacked PR, not tagged | Source tag readiness checks milestone release flags remain source-only. |
| `v0.76.0-source` | Pending stacked PR, not tagged | Source tag readiness checks blocker inventory release flags remain source-only. |
| `v0.77.0-source` | Pending stacked PR, not tagged | Source tag readiness checks open blocker evidence is present. |
| `v0.78.0-source` | Pending stacked PR, not tagged | Source tag readiness checks open blocker identifiers are present. |
| `v0.79.0-source` | Pending stacked PR, not tagged | Source tag readiness checks open blocker status is present. |
| `v0.80.0-source` | Pending stacked PR, not tagged | Source tag readiness checks blocker required-before-tag flags are explicit. |
| `v0.81.0-source` | Pending stacked PR, not tagged | Source tag readiness checks source-readiness milestone status is present. |
| `v0.82.0-source` | Pending stacked PR, not tagged | Source tag readiness checks source-readiness milestone evidence is present. |
| `v0.83.0-source` | Pending stacked PR, not tagged | Source tag readiness checks source-readiness milestone scope is present. |
| `v0.84.0-source` | Pending stacked PR, not tagged | Source tag readiness writes read-only summaries for release merge handoff. |
| `v0.85.0-source` | Pending stacked PR, not tagged | Source tag readiness records input fingerprints for release evidence. |
| `v0.86.0-source` | Pending stacked PR, not tagged | Release merge handoff carries tag-readiness input fingerprints into maintainer evidence. |
| `v0.87.0-source` | Pending stacked PR, not tagged | Publication dry-run fingerprints evidence bundle and release notes for handoff proof. |
| `v0.88.0-source` | Pending stacked PR, not tagged | Release evidence bundle records and carries source preflight input fingerprints. |
| `v0.89.0-source` | Pending stacked PR, not tagged | Source preflight records artifact fingerprints for release proof. |
| `v0.90.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff verify artifact fingerprint integrity. |
| `v0.91.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff verify commit SHA consistency. |
| `v0.92.0-source` | Pending stacked PR, not tagged | Source preflight and handoff verify resolved ref commit SHA consistency. |
| `v0.93.0-source` | Pending stacked PR, not tagged | Release stack status and handoff carry the latest PR URL for maintainer review. |
| `v0.94.0-source` | Pending stacked PR, not tagged | Release stack status and handoff verify latest PR URLs stay inside the expected public repo. |
| `v0.95.0-source` | Pending stacked PR, not tagged | Release handoff verifies GitHub status expected PR URL prefixes match the public repo boundary. |
| `v0.96.0-source` | Pending stacked PR, not tagged | Release handoff verifies GitHub status counts match the stack and required checks. |
| `v0.97.0-source` | Pending stacked PR, not tagged | Release handoff verifies GitHub status pull request entries are present and aligned. |
| `v0.98.0-source` | Pending stacked PR, not tagged | Release handoff verifies GitHub status PR sequence matches the merge-order stack. |
| `v0.99.0-source` | Pending stacked PR, not tagged | Release handoff verifies GitHub status PR base/head refs match the merge-order stack. |
| `v0.100.0-source` | Pending stacked PR, not tagged | Release handoff verifies every GitHub status PR URL matches the expected public repo and PR number. |
| `v0.101.0-source` | Pending stacked PR, not tagged | Release handoff verifies every GitHub status PR is clean and not draft. |
| `v0.102.0-source` | Pending stacked PR, not tagged | Release handoff verifies per-PR required GitHub status checks before maintainer review. |
| `v0.103.0-source` | Pending stacked PR, not tagged | Release handoff verifies per-check GitHub Actions trace evidence before maintainer review. |
| `v0.104.0-source` | Pending stacked PR, not tagged | Publication dry-run verifies the evidence bundle preflight input fingerprint before maintainer review. |
| `v0.105.0-source` | Pending stacked PR, not tagged | Release handoff verifies publication dry-run preflight input fingerprints before maintainer review. |
| `v0.106.0-source` | Pending stacked PR, not tagged | Release handoff verifies publication dry-run evidence-bundle and release-notes input fingerprints before maintainer review. |
| `v0.107.0-source` | Pending stacked PR, not tagged | Release handoff verifies tag readiness blocker-inventory and source-readiness input fingerprints before maintainer review. |
| `v0.108.0-source` | Pending stacked PR, not tagged | Release handoff verifies publication dry-run artifact fingerprints against the real proof files before maintainer review. |
| `v0.109.0-source` | Pending stacked PR, not tagged | Release handoff verifies optional GitHub ruleset report input fingerprints before maintainer review. |
| `v0.110.0-source` | Pending stacked PR, not tagged | Release evidence rejects malformed GitHub ruleset reports before enforcement claims can reach maintainer review. |
| `v0.111.0-source` | Pending stacked PR, not tagged | Publication dry-run rejects malformed GitHub ruleset reports before manual release review. |
| `v0.112.0-source` | Pending stacked PR, not tagged | Release handoff rejects malformed GitHub ruleset reports before maintainer handoff. |
| `v0.113.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff reject GitHub ruleset reports for the wrong repository or branch. |
| `v0.114.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff reject `ok` ruleset reports with missing or failed verifier checks. |
| `v0.115.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff reject ruleset report checks without traceable name or status fields. |
| `v0.116.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff reject ruleset reports whose required status checks do not match the canonical CI list. |
| `v0.117.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff reject ruleset reports whose passing checks do not cover every canonical required CI job. |
| `v0.118.0-source` | Pending stacked PR, not tagged | GitHub ruleset verifier reports covered required status checks explicitly, and release gates reject `ok` reports whose covered checks do not match the canonical CI list. |
| `v0.119.0-source` | Pending stacked PR, not tagged | Release evidence, publication dry-run, and handoff reject GitHub ruleset reports without a fresh `checked_at` timestamp. |

## Architecture Boundary

<p align="center">
  <img src="assets/diagrams/open-source-boundary.png" alt="Open-source client and private service boundary artwork" width="100%">
</p>

This repository is for the client app. It does not contain the official POKROV
backend, billing system, admin tools, deployment scripts, signing material,
private release evidence, or operator runbooks.

Read [docs/OPEN_SOURCE_SCOPE.md](docs/OPEN_SOURCE_SCOPE.md) for the full
boundary.

## Repository Map

```text
.
|-- README.md                  Language gateway
|-- README.en.md               English project README
|-- README.ru.md               Russian project README
|-- apps/                      Android and Windows Flutter hosts
|-- packages/                  Shared Flutter packages
|-- config/                    Public seed config and runtime contracts
|-- scripts/                   Local bootstrap, runtime-fetch, and test scripts
|-- BRAND.md                   Brand and official-build boundary
|-- SECURITY.md                Private security-reporting process
|-- CONTRIBUTING.md            Contribution rules
|-- ROADMAP.md                 Public repository roadmap
|-- docs/
|   |-- OPEN_SOURCE_SCOPE.md
|   |-- RELEASE_POLICY.md
|   |-- DEPENDENCY_LICENSE_AUDIT.md
|   |-- MAINTAINER_CHECKLIST.md
|   |-- PROJECT_PRINCIPLES.md
|   |-- GITHUB_TRIAGE.md
|   |-- SOURCE_IMPORT_PLAYBOOK.md
|   |-- PRODUCT_VARIANTS.md
|   |-- OPERATOR_INTEGRATION.md
|   |-- ENTERPRISE.md
|   `-- GOVERNANCE.md
`-- assets/
    |-- brand/
    `-- diagrams/
```

## Build From Source

Build instructions are available in
[docs/BUILD_FROM_SOURCE.md](docs/BUILD_FROM_SOURCE.md).
Troubleshooting is available in
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

Source import tooling is available for maintainers:

```powershell
python -m pytest tests/test_source_import.py
python -m tools.source_import.safe_import --source <snapshot> --staging <stage> --manifest <manifest.json>
```

Clean-clone verification is available for maintainers:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1
```

The acceptance bar for source work is simple:

- a clean clone must build without private files
- no secrets, certificates, or signing identities may be required
- configuration examples must use placeholders
- official release metadata must not point to private repositories

## Contributing

Contributions are welcome, especially around documentation, release hygiene,
build reproducibility, local profile import, operator integration, and
public-source readiness.

Before contributing, read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [BRAND.md](BRAND.md)
- [docs/README.md](docs/README.md)
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- [docs/REQUIRED_CHECKS.md](docs/REQUIRED_CHECKS.md)
- [docs/DEPENDENCY_UPDATE_POLICY.md](docs/DEPENDENCY_UPDATE_POLICY.md)
- [docs/MAINTAINER_CHECKLIST.md](docs/MAINTAINER_CHECKLIST.md)
- [docs/PROJECT_PRINCIPLES.md](docs/PROJECT_PRINCIPLES.md)
- [docs/GITHUB_TRIAGE.md](docs/GITHUB_TRIAGE.md)
- [docs/SOURCE_IMPORT_PLAYBOOK.md](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [docs/PRODUCT_VARIANTS.md](docs/PRODUCT_VARIANTS.md)
- [docs/OPERATOR_INTEGRATION.md](docs/OPERATOR_INTEGRATION.md)
- [docs/ENTERPRISE.md](docs/ENTERPRISE.md)
- [docs/FREE_VPN_CATALOG_GATE.md](docs/FREE_VPN_CATALOG_GATE.md)
- [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)
- [docs/GOVERNANCE.md](docs/GOVERNANCE.md)

Please do not open public issues with secrets, QR payloads, subscription URLs,
personal connection links, private backend details, account data, or
vulnerability reproduction details.

## Official POKROV Service Links

These links are for the official POKROV service/app only. They are not support
or backend endpoints for community builds, forks, or operator builds.

- Website: https://pokrov.space/
- Cabinet: https://app.pokrov.space/
- Public channel: https://t.me/pokrov_vpn
- Support bot: https://t.me/pokrov_supportbot

Official binaries are published only through POKROV-owned release channels.
Forks and rebuilt clients must not imply that they are official POKROV builds.

## License

This repository is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).

See [Enterprise boundary](docs/ENTERPRISE.md) for the operator and commercial license boundary. It does not change the GPLv3 license or offer a commercial license by default.

The POKROV name, logos, domains, official channels, signing identities, and
release distribution channels are governed separately by [BRAND.md](BRAND.md).
