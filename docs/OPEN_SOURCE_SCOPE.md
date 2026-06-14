# Open Source Scope

This repository is the public open-source home for the POKROV client app.

## In Scope

- Android client source.
- Windows client source.
- Shared client packages.
- Client build instructions.
- Public configuration examples.
- Public release notes, checksums, and source references.
- Public issue and contribution workflow.
- Enterprise boundary documentation for GPLv3, commercial license limits, and
  operator distribution responsibilities.

## Out Of Scope

- Backend API implementation.
- Telegram bot implementation.
- Payment and billing internals.
- Admin tools.
- Deployment scripts.
- Node-management scripts.
- Private release evidence.
- Signing keys and certificates.
- Operator runbooks.
- Commercial license grants by default.
- Secret-bearing development history.

## Public Claim Boundary

The repository may describe the client code and public build process. It must
not make stronger official-service claims than the current public evidence
supports.

Avoid unsupported claims about:

- store availability
- stable `1.0.0`
- trusted Windows signing
- raw Android physical-audit proof
- RU-origin readiness
- production WARP readiness

## Backend Boundary

The official POKROV service backend remains operated separately. Forks can adapt
the client to their own service contracts, but they are responsible for their
own backend, release process, user support, and security claims.

See [ENTERPRISE.md](ENTERPRISE.md) (`docs/ENTERPRISE.md`) for the Enterprise
boundary and commercial license boundary. That document does not change the
repository license or waive operator source/distribution obligations.
