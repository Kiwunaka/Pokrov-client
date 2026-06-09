# Roadmap

This roadmap describes the public repository path. It is not a release promise.

## Phase 1: Repository Foundation

- Add public project documentation.
- Add security and contribution rules.
- Add issue and pull request templates.
- Define brand and official-build boundaries.
- Add bilingual README entrypoints.
- Add visual repository identity assets.

## Phase 2: Sanitized Source Import

- Import Android and Windows client source from the private client lane. Done in
  the first sanitized snapshot.
- Exclude private history, secrets, signing material, and operator evidence.
  Done for the first snapshot.
- Add build instructions and configuration examples. Initial docs added.
- Verify a clean clone can build without private files. Clean-clone proof
  script and CI source-boundary pass added; release candidates still need a
  full maintainer run before publishing binaries.
- Preserve the operator/company client track and personal key client track.

## Phase 3: Public Build And Release Hygiene

- Add CI for analysis and tests. Initial GitHub Actions workflow added.
- Add dependency license inventory.
- Add source import playbook and governance docs.
- Add product-track documentation and optional public-config catalog gates.
- Publish checksums with release artifacts.
- Keep official release claims aligned with current evidence.

## Phase 3.5: Optional Free VPN Catalog

- Research third-party public config feeds.
- Start with `AvenCores/goida-vpn-configs` as an opt-in candidate.
- Add parser fixtures and tests before shipping.
- Label all third-party feeds clearly in UI.
- Keep official POKROV service and third-party public feeds separate.

## Phase 3.6: Community Client UX

- Local multi-profile list with active selection. Initial MVP added.
- Manual subscription URL import. Initial MVP added.
- Decoded QR payload import. Initial MVP added.
- Camera-backed QR scanning remains a platform-host follow-up.
- Automatic subscription refresh remains behind freshness and failure-mode
  policy.

## Phase 4: Community Contributions

- Label good first issues.
- Document architecture and package boundaries.
- Accept focused bug fixes and platform-specific improvements.
- Keep security reports private until coordinated disclosure.
