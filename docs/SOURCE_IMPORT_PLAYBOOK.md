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

Use the checked-in source import tool before any source snapshot PR:

```powershell
python -m pytest tests/test_source_import.py
python -m tools.source_import.safe_import `
  --source <local-client-snapshot> `
  --staging <temporary-oss-stage> `
  --manifest <dry-run-manifest.json>
```

The command above is a dry-run. It writes the manifest only and does not copy
source files into staging.

When the dry-run result is reviewed, copy the allowlisted files into a temporary
staging folder:

```powershell
python -m tools.source_import.safe_import `
  --source <local-client-snapshot> `
  --staging <temporary-oss-stage> `
  --manifest <stage-manifest.json> `
  --apply
```

The tool must not be pointed at the public repository root as `--staging`.
Review the temporary staging folder first, then open a separate source import
PR.

## Required Steps

1. Export the candidate source from the private client lane into a temporary
   staging folder.
2. Run `python -m pytest tests/test_source_import.py`.
3. Run the source import tool in dry-run mode and review the manifest.
4. Remove private history and local-only generated outputs.
5. Remove secrets, certificates, signing configs, private URLs, and tokens.
6. Replace private configuration with examples and placeholders.
7. Remove private logs, screenshots, release evidence, and operator notes.
8. Confirm assets have source and license notes.
9. Complete the dependency license audit.
10. Document which code paths belong to the operator/company track and which
   belong to the personal key track.
11. Keep optional third-party public config catalogs disabled unless their
   license, parser, safety-copy, and freshness gates are documented.
12. Run secret scanning.
13. Build from a clean clone without private files.
14. Record checks in `docs/MAINTAINER_CHECKLIST.md` or the release PR.

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

The default import policy also blocks release handoff seed files, runtime
binaries, signing material, env files, local platform config, private keys, and
generated build folders.

## Local Preparation Note

On 2026-06-09, a local non-public preparation pass was run against a copied
client snapshot, not the production client checkout. The final dry-run
allowlisted 128 files for Android, Windows, shared Flutter packages, public seed
config, local scripts, and brand assets. The only policy block was
`config/release-handoff.seed.json`.

The sanitized staging copy then rescanned with `blocked=0`. Source files were
then imported through a dedicated source snapshot PR.

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
