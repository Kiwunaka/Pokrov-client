# Enterprise Boundary

This page explains how companies and service operators can approach the public
client source without confusing it with official POKROV service operations.

This is not legal advice. Talk to qualified legal counsel before distributing
modified builds, offering a hosted service, or relying on any license
interpretation.

## Current License

The current public repository license is GNU GPLv3. This document does not change [LICENSE](../LICENSE), does not waive GPLv3 obligations, and does not offer a commercial license by default.

If you distribute a modified client build, you are responsible for understanding
and satisfying the license obligations that apply to your distribution,
including corresponding source obligations where required.

## What Is Free Open Source

- Android and Windows client source in this repository.
- Shared client packages, local profile import, routing UI, and source build
  instructions.
- Community client mode for users who bring their own keys, QR codes, or
  subscription URLs.
- Operator client mode, OpenAPI contract, fixture backend, and white-label
  configuration examples.
- Source-only release policy, proof helpers, and public contribution workflow.

This repository does not include the official POKROV backend, billing,
Telegram bots, admin tools, deployment scripts, node-management scripts,
signing material, private release evidence, or private operator runbooks.

## What Operators Bring

Operators and companies bring their own:

- backend and managed profile API
- billing, checkout, refunds, and abuse handling
- support process and privacy policy
- domains, app identity, package IDs, signing identities, and release channels
- checksums, release notes, store or direct-download claims, and source
  compliance process

Operator builds are not official POKROV builds. Do not use POKROV names,
logos, domains, support bots, signing identities, release channels, or official
service claims for your users.

## Paid Work Around The Client

POKROV may offer paid support, integration help, hosted backend/service work,
custom operator build assistance, release packaging guidance, or security
review as separate services.

Those services do not by themselves change the public repository license, grant
private POKROV backend access, waive source obligations, or make an operator
build an official POKROV build.

## Future Licensing Options

The current model is GPLv3 public client source plus optional paid services
around integration and operations.

Possible future business models:

- GPL-only: operators comply with GPLv3 while paying for support, integration,
  hosted services, or custom build help.
- Open core: the public client remains GPLv3 while backend, hosted operations,
  support, packaging, or other services provide commercial value separately.
- Dual license: possible only after an explicit owner decision and a contributor
  or copyright policy that supports it. No dual license is offered by default.

Do not describe this repository as dual-licensed, commercially licensed, or
closed-source-operator-ready unless a later owner-approved document and license
files make that true.

## Before Distributing A Fork

- Review GPLv3 obligations and consult legal counsel.
- Replace POKROV branding, endpoints, support channels, package IDs, and
  signing identities.
- Publish your own privacy policy, support policy, checksums, signing notes,
  release notes, and source-compliance path.
- Review runtime artifact, dependency, and third-party catalog licenses before
  shipping binaries.
- Keep release claims evidence-based: no trusted signing, store release,
  production readiness, official POKROV operation, or backend availability
  claims without your own current evidence.

For implementation details, start with [OPERATOR_INTEGRATION.md](OPERATOR_INTEGRATION.md)
and [PRODUCT_VARIANTS.md](PRODUCT_VARIANTS.md).
