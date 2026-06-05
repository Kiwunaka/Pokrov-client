# Source Import Playbook

This playbook defines the minimum bar for importing the first sanitized client
source snapshot.

## Goal

Publish Android and Windows client source in a way that is useful to developers
without exposing private operations, secret-bearing history, signing material,
or unsupported release claims.

The public client should preserve two target product tracks:

- operator / company client for teams that want a configurable client for their
  own VPN service
- personal key client for users who paste a key, QR code, or subscription URL
  and connect without POKROV billing or account management

## Import Strategy

Use a clean snapshot import.

Do not import private development history into the public repository.

## Required Steps

1. Export the candidate source from the private client lane into a temporary
   staging folder.
2. Remove private history and local-only generated outputs.
3. Remove secrets, certificates, signing configs, private URLs, and tokens.
4. Replace private configuration with examples and placeholders.
5. Remove private logs, screenshots, release evidence, and operator notes.
6. Confirm assets have source and license notes.
7. Complete the dependency license audit.
8. Document which code paths belong to the operator/company track and which
   belong to the personal key track.
9. Keep optional third-party public config catalogs disabled unless their
   license, parser, safety-copy, and freshness gates are documented.
10. Run secret scanning.
11. Build from a clean clone without private files.
12. Record checks in `docs/MAINTAINER_CHECKLIST.md` or the release PR.

## Acceptance Criteria

- A new contributor can clone the repository and understand how to build.
- Basic local build does not require private files.
- Release metadata does not point to private repositories.
- No official store, signing, audit, or production-readiness claim is stronger
  than the available public evidence.
- Forks can understand what is official POKROV service territory and what is
  open client code.
- Users can understand the difference between official POKROV service mode,
  operator/custom-service mode, personal key mode, and optional third-party
  public config catalogs.

## Do Not Import

- backend source
- payment internals
- admin implementation
- deploy scripts
- node-management scripts
- signing keys
- certificates
- private release evidence
- personal connection URLs
- raw vulnerability details
- operator runbooks

## Third-Party Public Config Feeds

Do not import third-party public config feeds directly into the first source
snapshot unless they have a documented product gate.

The first research candidate is `AvenCores/goida-vpn-configs`. It must remain
an opt-in `Free VPN` catalog candidate until license, attribution, parser,
freshness, failure-mode, and safety-copy checks are complete.

## First Import PR Checklist

- [ ] Source snapshot added.
- [ ] Build docs added.
- [ ] Configuration examples added.
- [ ] Dependency license audit updated.
- [ ] Product tracks documented.
- [ ] Optional third-party config feeds documented or disabled.
- [ ] Secret scan completed.
- [ ] Clean clone build smoke completed.
- [ ] README status updated from `pending import`.
- [ ] Release policy still matches public evidence.
