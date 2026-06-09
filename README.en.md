# POKROV Client

<p align="center">
  <img src="assets/brand/pokrov-oss-hero.png" alt="POKROV Client open-source hero artwork" width="100%">
</p>

<p align="center">
  <a href="LICENSE"><img alt="License: GPLv3" src="https://img.shields.io/badge/license-GPLv3-0f766e?style=for-the-badge"></a>
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

- Community client: neutral, no POKROV branding, no POKROV API calls by
  default, local import for single `vless://`, `trojan://`, `ss://`, and
  `vmess://` keys, with one active local profile that can be replaced or
  removed.
- Operator client: a white-label path for companies that want to connect the
  app to their own backend, billing, support, and brand.
- POKROV service mode: reserved for official POKROV builds and official
  POKROV service endpoints.

Subscription URL refresh, QR import, multi-profile lists, and the optional free
VPN catalog are planned follow-ups with parser, license, and safety gates.

## Status

<p align="center">
  <img src="assets/brand/oss-status-card.png" alt="POKROV Client repository status artwork" width="100%">
</p>

| Area | Current state |
| --- | --- |
| Repository | Public foundation ready |
| Source code | Sanitized Android + Windows snapshot imported |
| Community mode | Local single-key import and active profile MVP |
| Operator mode | White-label contracts documented |
| Platforms | Android and Windows first |
| License | GNU GPLv3 |
| Official backend | Operated separately by POKROV |
| Public releases | Beta-safe claims only |

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
|   |-- SOURCE_IMPORT_PLAYBOOK.md
|   |-- PRODUCT_VARIANTS.md
|   |-- OPERATOR_INTEGRATION.md
|   `-- GOVERNANCE.md
`-- assets/
    |-- brand/
    `-- diagrams/
```

## Build From Source

Build instructions are available in
[docs/BUILD_FROM_SOURCE.md](docs/BUILD_FROM_SOURCE.md).

Source import tooling is available for maintainers:

```powershell
python -m pytest tests/test_source_import.py
python -m tools.source_import.safe_import --source <snapshot> --staging <stage> --manifest <manifest.json>
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
- [docs/MAINTAINER_CHECKLIST.md](docs/MAINTAINER_CHECKLIST.md)
- [docs/PROJECT_PRINCIPLES.md](docs/PROJECT_PRINCIPLES.md)
- [docs/SOURCE_IMPORT_PLAYBOOK.md](docs/SOURCE_IMPORT_PLAYBOOK.md)
- [docs/PRODUCT_VARIANTS.md](docs/PRODUCT_VARIANTS.md)
- [docs/OPERATOR_INTEGRATION.md](docs/OPERATOR_INTEGRATION.md)
- [docs/GOVERNANCE.md](docs/GOVERNANCE.md)

Please do not open public issues with secrets, personal connection links,
private backend details, account data, or vulnerability reproduction details.

## Official Links

- Website: https://pokrov.space/
- Cabinet: https://app.pokrov.space/
- Public channel: https://t.me/pokrov_vpn
- Support bot: https://t.me/pokrov_supportbot

Official binaries are published only through POKROV-owned release channels.
Forks and rebuilt clients must not imply that they are official POKROV builds.

## License

This repository is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).

The POKROV name, logos, domains, official channels, signing identities, and
release distribution channels are governed separately by [BRAND.md](BRAND.md).
