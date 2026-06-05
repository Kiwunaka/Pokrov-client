# Security Policy

## Supported Scope

Security reports are accepted for the public POKROV client code and public
release process in this repository.

The official POKROV backend, billing system, admin tools, infrastructure, and
operator processes are operated separately. Do not publish suspected private
service vulnerabilities in public issues.

## Reporting A Vulnerability

Please do not open a public issue for security vulnerabilities.

Use one of these private channels:

- Telegram support: https://t.me/pokrov_supportbot
- If you already have a maintainer contact, use that private channel directly.

Include:

- affected platform: Android, Windows, or repository process
- app version or commit SHA if available
- reproduction steps
- expected impact
- logs or screenshots with tokens, personal data, and connection URLs redacted

## Handling Expectations

Maintainers will triage reports privately before public disclosure. Public
advisories, fixes, or credit will be coordinated after the issue is understood.

## Public Issue Rule

Public issues are appropriate for ordinary bugs, build problems, docs gaps, and
feature requests. They are not appropriate for:

- secrets
- account tokens
- personal connection URLs
- private backend details
- bypass or abuse instructions
- unredacted logs containing user data
