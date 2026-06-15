<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="README.en.md"><strong>English</strong></a>
  &middot;
  <a href="README.ru.md"><strong>Русский</strong></a>
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
  <img alt="Source status: snapshot imported" src="https://img.shields.io/badge/source-snapshot%20imported-0f766e?style=for-the-badge">
  <img alt="Platforms: Android and Windows" src="https://img.shields.io/badge/platforms-Android%20%2B%20Windows-2563eb?style=for-the-badge">
  <img alt="Client modes: community and operator" src="https://img.shields.io/badge/modes-community%20%2B%20operator-111827?style=for-the-badge">
</p>

<p align="center">
  Public open-source home for the POKROV client app.
  The first sanitized Android and Windows source snapshot is imported.
</p>

---

## Choose Your README

- [English README](README.en.md)
- [Русская версия](README.ru.md)

## Choose Your Track

| Track | Who it is for | First step |
| --- | --- | --- |
| Personal Key Client | Ordinary users who already have a key, QR code, or subscription URL. | Build the `community` variant, then paste a `vless://`, `trojan://`, `ss://`, or `vmess://` key, scan a QR code, or add a subscription URL. |
| Operator / Company Client | Companies, teams, and communities shipping a client for their own service. | Run the local fixture backend, export white-label color tokens, then connect your own API, brand, support, privacy policy, signing, and release channels. |
| POKROV Service Mode | Official POKROV builds only. | Use official POKROV release channels; forks and operator builds are not official POKROV builds. |

The Personal Key Client has no POKROV API calls by default. This repository
does not provide POKROV nodes or a default free service.

## Current Status

<p align="center">
  <img src="assets/brand/oss-status-card.png" alt="POKROV Client repository status artwork" width="100%">
</p>

Current repository state:

- the public repository is ready for open-source collaboration
- the first sanitized Android and Windows app source snapshot is imported
- the community client can import local keys, subscription URLs, and Android/Windows QR payloads without POKROV API calls
- subscription refresh is manual, app-resume, and foreground-scheduled, preserving old local profiles on failure
- the optional third-party public config catalog is documented as gated metadata and disabled by default
- the operator client path is documented for companies with their own backend
- official POKROV backend and operations remain private
- the repository license is GNU GPLv3
- public release claims stay beta-safe and evidence-based

Source release status:

| Milestone | Status | Scope |
| --- | --- | --- |
| `v0.1.0-source` | Tagged | First source-only Android/Windows snapshot with local community import. No APK/EXE. |
| `v0.2.0-source` | Not tagged | Community import polish and source-import hardening are on `main`; release tag pending. |
| `v0.3.0-source` | Not tagged | Operator fixture, Free VPN catalog gate, white-label tokens, and foreground subscription scheduler are on `main`; release tag pending. |
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

## Which App Should I Use?

- Official POKROV users should use official POKROV release channels and
  support links.
- Community source users bring their own local keys or subscription URLs. This
  repository does not provide POKROV nodes or a default free service.
- Operator builds are supported by the operator that built and distributed
  them, not by POKROV official support.

## Official POKROV Service Links

These links are for the official POKROV service/app only. They are not support
or backend endpoints for community builds, forks, or operator builds.

- Website: https://pokrov.space/
- Cabinet: https://app.pokrov.space/
- Public channel: https://t.me/pokrov_vpn
- Support bot: https://t.me/pokrov_supportbot

## Public Boundary

<p align="center">
  <img src="assets/diagrams/open-source-boundary.png" alt="Open-source client and private service boundary artwork" width="100%">
</p>

Read the scope documents before opening issues or pull requests:

- [Open-source scope](docs/OPEN_SOURCE_SCOPE.md)
- [Docs index](docs/README.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Release policy](docs/RELEASE_POLICY.md)
- [Required checks](docs/REQUIRED_CHECKS.md)
- [Dependency license audit](docs/DEPENDENCY_LICENSE_AUDIT.md)
- [Dependency update policy](docs/DEPENDENCY_UPDATE_POLICY.md)
- [Maintainer checklist](docs/MAINTAINER_CHECKLIST.md)
- [Project principles](docs/PROJECT_PRINCIPLES.md)
- [GitHub triage](docs/GITHUB_TRIAGE.md)
- [Source import playbook](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [Product variants](docs/PRODUCT_VARIANTS.md)
- [Operator integration](docs/OPERATOR_INTEGRATION.md)
- [Enterprise boundary](docs/ENTERPRISE.md)
- [Governance](docs/GOVERNANCE.md)
- [Brand policy](BRAND.md)
- [Security policy](SECURITY.md)

## License

This repository is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).

See [Enterprise boundary](docs/ENTERPRISE.md) for the operator and commercial license boundary. It does not change the GPLv3 license or offer a commercial license by default.

The POKROV name, logos, domains, support channels, signing identities, and
official release channels are governed separately by [BRAND.md](BRAND.md).
