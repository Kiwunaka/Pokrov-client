# Contributing

Thank you for helping improve the POKROV client.

This repository is in source-open client mode. The first sanitized Android and
Windows source snapshot has landed, so contributions can target local profile
import, QR import, subscription refresh, parser fixtures, documentation,
release hygiene, and operator integration.

## Before You Start

Read:

- [README.md](README.md)
- [SECURITY.md](SECURITY.md)
- [BRAND.md](BRAND.md)
- [docs/OPEN_SOURCE_SCOPE.md](docs/OPEN_SOURCE_SCOPE.md)
- [docs/PRODUCT_VARIANTS.md](docs/PRODUCT_VARIANTS.md)
- [docs/FREE_VPN_CATALOG_GATE.md](docs/FREE_VPN_CATALOG_GATE.md)

## Contribution Rules

- Keep changes focused and easy to review.
- Do not commit secrets, private URLs, tokens, signing material, or personal
  connection links.
- Routine PRs must not add public claims about store availability, stable
  releases, trusted signing, production readiness, RU-origin readiness, or WARP
  production readiness. Maintainers may update release policy only after
  explicit public evidence and approval.
- Do not present forks as official POKROV builds.
- Keep community-client keys, QR payloads, subscription URLs, and public catalog
  imports local-only unless a future policy explicitly says otherwise.
- Keep third-party public config feeds labeled as third-party configs, not
  official POKROV nodes.
- Use calm, factual language in public documentation and release notes.

## Pull Requests

Good pull requests include:

- a short explanation of the change
- why the change is useful
- how it was checked
- any remaining risk or follow-up

For source changes, include platform-specific checks for Android or Windows
when applicable. For parser, subscription, QR, or catalog changes, include
fixtures or widget tests that prove malformed inputs do not erase existing local
profiles.

## Licensing

By contributing, you agree that your contribution is provided under the
repository license unless a file clearly states a different compatible license.

Do not add third-party code, assets, fonts, icons, or generated media unless
their license and source are documented.
