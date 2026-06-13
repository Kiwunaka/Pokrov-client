# Free VPN Catalog Gate

The community client may expose public third-party config feeds, but the shared
app must keep the catalog disabled until these gates are complete.

## Candidate

- Source: `AvenCores/goida-vpn-configs`
- URL: `https://github.com/AvenCores/goida-vpn-configs`
- License observed on 2026-06-09: `GPL-3.0`
- Intended UI label: third-party public configs
- Reviewed seed file: `config/free-vpn-catalog.seed.json`
- Manual import build define: `OPEN_CLIENT_ENABLE_FREE_CATALOG=false` by
  default
- Parser contract: `subscription-text-v1`
- Provenance policy: no network fetch in CI, no runtime fetch by default,
  reviewed feed hosts only, attribution required
- Supported in-client protocols for this gate: `vless`, `trojan`, `ss`, and
  `vmess`

## Required Before Enabling

- [x] Confirm license and attribution text.
- [x] Record feed URLs, update cadence, and freshness expectations.
- [x] Add parser fixtures for every enabled feed format.
- [x] Keep malformed entries isolated from valid entries.
- [x] Keep manual feed import behind `OPEN_CLIENT_ENABLE_FREE_CATALOG=true`.
- [x] Cache fetched feeds locally with manual refresh and clear actions.
- [x] Show copy that says these are not official POKROV nodes.
- [x] Avoid speed, safety, privacy, uptime, legality, or availability promises.
- [x] Require release-note copy that says: third-party public configs, not
  official POKROV nodes, user-initiated, and no speed, privacy, uptime, safety,
  legality, or availability promise.

## Parser Fixtures

The parser gate uses local fixtures under
`tests/fixtures/free_vpn_catalog/`. Tests do not fetch GitHub raw URLs; network
availability must not decide CI results.

Feed URLs are provenance metadata, not CI inputs. The reviewed catalog currently
allows `github.com` feed URLs only and must not point at official POKROV hosts,
legacy hosts, private mirrors, or unreviewed domains.

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
boundary and does not fetch or enable third-party feeds by default. Default
community builds show the warning/attribution preview only; the import button is
disabled unless the build is compiled with
`OPEN_CLIENT_ENABLE_FREE_CATALOG=true`. When enabled, users can manually import
the reviewed candidate feed, which stores accepted entries as local profiles
with `source_kind=third_party_catalog`, `sourceUrl`, refresh metadata, and
parser output from the shared local flow. The clear action removes only cached
third-party catalog profiles and leaves user-owned single keys, subscription
imports, and official/service profiles alone. The first candidate catalog is
recorded as a disabled opt-in source with attribution, manual refresh, local
cache, clear-action scope, feed freshness expectations, and local parser
fixtures.

Any release note that mentions enabling or previewing this catalog must say the
feeds are third-party public configs, not official POKROV nodes, user-initiated,
and no speed, privacy, uptime, safety, legality, or availability promise is
made for them.
