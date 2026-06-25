# POKROV Client

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
  <a href="https://github.com/Kiwunaka/Pokrov-client/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Kiwunaka/Pokrov-client/ci.yml?branch=main&style=for-the-badge&label=CI"></a>
  <a href="https://github.com/Kiwunaka/Pokrov-client/releases/tag/v0.172.0-source"><img alt="Source release" src="https://img.shields.io/badge/source-v0.172.0--source-111827?style=for-the-badge"></a>
  <img alt="Platforms: Android and Windows" src="https://img.shields.io/badge/platforms-Android%20%2B%20Windows-2563eb?style=for-the-badge">
</p>

<p align="center">
  Public source-only Android and Windows client for local keys, subscription URLs,
  QR import, routing, and operator-owned builds.
</p>

---

<p align="center">
  <img src="assets/brand/open-source-showroom.png" alt="POKROV Client open-source tracks: personal client, operator-ready source, and honest source-only boundary" width="100%">
</p>

## Choose Your Track

| Track | For | Start |
| --- | --- | --- |
| [Personal Key Client](README.en.md#personal-key-client) | People using their own keys, QR codes, or subscription URLs. | Build the community variant and import locally. |
| [Operator / Company Client](README.en.md#operator--company-client) | Teams shipping a client for their own VPN service. | Read the operator contract, white-label docs, and API fixture. |
| [POKROV Service Mode](README.en.md#official-pokrov-service-mode) | Official POKROV builds only. | Use official private release gates and channels. |

## Flow Preview

<p align="center">
  <img src="assets/brand/client-flow-loop.gif" alt="Local-first import flow animation for keys, local parser, routing, and operator build boundary" width="100%">
</p>

This visual is a repository-safe product map, not a binary-release claim.

## Current Source Release

- Release: [`v0.172.0-source`](https://github.com/Kiwunaka/Pokrov-client/releases/tag/v0.172.0-source)
- Commit: `e1fef5520190dc6fb0efbe8c1bfd666fac07d2db`
- Source archive SHA-256: `84c53d20e5f53253fdaeb5cae1d310327e331c0a462683eb9eee7903d6846367`
- No APK, EXE, installer, store release, or trusted signing claim is included.

## Important Boundaries

- The community client makes no POKROV API calls by default.
- Local import covers `vless://`, `trojan://`, `ss://`, `vmess://`, QR codes,
  and subscription URLs.
- This repository does not provide POKROV nodes or a default free service.
- The optional Free VPN catalog is third-party, opt-in, and disabled by default.
- Operator builds must use their own backend, brand, support, privacy policy,
  signing, release notes, checksums, and distribution channels.
- Forks and operator builds are not official POKROV builds.
- Enterprise boundary and commercial license notes live in
  `docs/ENTERPRISE.md`; no commercial license is offered by default.

## Documentation

- [English README](README.en.md)
- [Русская версия](README.ru.md)
- [Build from source](docs/BUILD_FROM_SOURCE.md)
- [Product variants](docs/PRODUCT_VARIANTS.md)
- [Operator integration](docs/OPERATOR_INTEGRATION.md)
- [Free VPN catalog gate](docs/FREE_VPN_CATALOG_GATE.md)
- [Release policy](docs/RELEASE_POLICY.md)
- [Security policy](SECURITY.md)
- [Brand boundary](BRAND.md)
