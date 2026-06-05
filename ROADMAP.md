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

- Import Android and Windows client source from the private client lane.
- Exclude private history, secrets, signing material, and operator evidence.
- Add build instructions and configuration examples.
- Verify a clean clone can build without private files.
- Preserve the operator/company client track and personal key client track.

## Phase 3: Public Build And Release Hygiene

- Add CI for analysis and tests.
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

## Phase 4: Community Contributions

- Label good first issues.
- Document architecture and package boundaries.
- Accept focused bug fixes and platform-specific improvements.
- Keep security reports private until coordinated disclosure.
