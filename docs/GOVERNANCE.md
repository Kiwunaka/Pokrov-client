# Governance

POKROV Client uses a maintainer-led open-source model.

## Maintainer Role

Maintainers are responsible for:

- protecting user security and privacy
- keeping official release claims evidence-based
- reviewing code, docs, dependencies, and assets before merge
- preserving the boundary between open client code and private service
  operations
- coordinating security reports privately

## Contribution Model

The project welcomes focused pull requests that improve:

- client code after the first source import
- build reproducibility
- platform compatibility
- documentation
- security process
- release hygiene
- dependency and asset license clarity

Maintainers may close broad, speculative, unsafe, or off-scope issues.

## Decision Rules

Project decisions should optimize for:

1. user safety
2. honest public claims
3. reproducible public builds
4. maintainable client architecture
5. clear official-build boundaries

## Release Authority

Only POKROV maintainers can publish official POKROV binaries or claim that a
build is official.

Fork maintainers can publish their own builds under the repository license, but
they are responsible for their own signing, support, backend compatibility,
release notes, and security claims.

## Security Authority

Security reports are handled privately through [SECURITY.md](../SECURITY.md).

Maintainers may temporarily withhold public technical details when disclosure
could put users or infrastructure at risk.
