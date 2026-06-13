# Free VPN Catalog Gate

The community client may expose public third-party config feeds, but the shared
app must keep the catalog disabled until these gates are complete.

## Candidate

- Source: `AvenCores/goida-vpn-configs`
- URL: `https://github.com/AvenCores/goida-vpn-configs`
- License observed on 2026-06-09: `GPL-3.0`
- Intended UI label: third-party public configs
- Reviewed seed file: `config/free-vpn-catalog.seed.json`
- Parser contract: `subscription-text-v1`
- Supported in-client protocols for this gate: `vless`, `trojan`, `ss`, and
  `vmess`

## Required Before Enabling

- [x] Confirm license and attribution text.
- [x] Record feed URLs, update cadence, and freshness expectations.
- [x] Add parser fixtures for every enabled feed format.
- [x] Keep malformed entries isolated from valid entries.
- [ ] Cache fetched feeds locally with manual refresh and clear actions.
- [x] Show copy that says these are not official POKROV nodes.
- [x] Avoid speed, safety, privacy, uptime, legality, or availability promises.

## Parser Fixtures

The parser gate uses local fixtures under
`tests/fixtures/free_vpn_catalog/`. Tests do not fetch GitHub raw URLs; network
availability must not decide CI results.

Covered fixture behavior:

- plaintext `subscription_text` feeds with `vless`, `trojan`, `ss`, and
  `vmess`
- base64-encoded subscription bodies
- duplicate isolation
- unsupported upstream protocols isolated without failing valid entries
- malformed non-proxy lines ignored or rejected without importing them

The upstream repository also advertises protocols that the open client does not
yet import. Those entries must remain isolated until the client parser and
runtime staging explicitly support them.

## Current State

The app has a gated `Free VPN catalog` profile action. It explains the safety
boundary and does not fetch or enable third-party feeds by default. The first
candidate catalog is recorded as a disabled opt-in source with attribution,
manual refresh, local cache, clear-action requirements, feed freshness
expectations, and local parser fixtures.
