# Security Policy

## Supported Versions

This repository currently publishes source-only tags and stacked source
readiness PRs. Security reports should identify one of:

- a source-only tag such as `v0.1.0-source`
- a commit SHA
- an open pull request branch
- a public repository process, script, fixture, or source-release checklist

No APK/EXE, store, trusted-signing, or official binary security claim is made by
this source-only repository unless a future release note says so with evidence.

The machine-readable intake gate is
[`config/security-intake.seed.json`](config/security-intake.seed.json). It keeps
blank public issues disabled for vulnerability reports, records private
reporting paths, and preserves the source-only release claim boundary.

## Supported Scope

Security reports are accepted for the public POKROV client code and public
release process in this repository.

The official POKROV backend, billing system, admin tools, infrastructure, and
operator processes are operated separately. Do not publish suspected private
service vulnerabilities in public issues.

In scope:

- Personal Key / Community Client source behavior that could leak local keys,
  QR payloads, subscription URLs, public third-party config feeds, or local
  profile data
- Operator / Company Client public fixture, OpenAPI, build define, and
  white-label boundary issues
- release scripts, source archives, source proof manifests, and public
  dependency or asset provenance gates
- Android/Windows host code in this public source tree

## Unsupported Or Out Of Scope

- official POKROV backend, billing, admin, infrastructure, deploy, signing, or
  private service operations
- private operator backends or customer accounts
- third-party public config feed availability, speed, legality, privacy,
  safety, or uptime claims
- social engineering, spam, denial of service, or abuse instructions
- reports that require publishing secrets, account tokens, personal connection
  URLs, QR payloads, subscription URLs, or private backend details in public

## Private Reporting

Do not open a public issue for security vulnerabilities.

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

Expected triage flow:

1. acknowledge receipt when a maintainer sees the private report
2. reproduce or narrow the affected source scope
3. coordinate a fix, mitigation, or out-of-scope response
4. publish only redacted public details after private impact is understood

## Coordinated Disclosure

Give maintainers time to investigate before public disclosure. Do not publish
working exploit steps, private endpoints, tokens, account data, personal
connection links, QR payloads, or subscription URLs while triage is active.

## Public Issue Rule

Public issues are appropriate for ordinary bugs, build problems, docs gaps, and
feature requests. They are not appropriate for:

- secrets
- account tokens
- personal connection URLs
- private backend details
- bypass or abuse instructions
- unredacted logs containing user data
