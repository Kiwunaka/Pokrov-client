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
- [Release policy](docs/RELEASE_POLICY.md)
- [Dependency license audit](docs/DEPENDENCY_LICENSE_AUDIT.md)
- [Maintainer checklist](docs/MAINTAINER_CHECKLIST.md)
- [Project principles](docs/PROJECT_PRINCIPLES.md)
- [Source import playbook](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [Product variants](docs/PRODUCT_VARIANTS.md)
- [Operator integration](docs/OPERATOR_INTEGRATION.md)
- [Governance](docs/GOVERNANCE.md)
- [Brand policy](BRAND.md)
- [Security policy](SECURITY.md)

## License

This repository is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).

The POKROV name, logos, domains, support channels, signing identities, and
official release channels are governed separately by [BRAND.md](BRAND.md).
