# Client Product Tracks

This document records the intended public product split for the open-source
client.

The first sanitized source snapshot is imported. Concrete build variants are
documented in [PRODUCT_VARIANTS.md](PRODUCT_VARIANTS.md), and the operator API
surface is documented in [OPERATOR_INTEGRATION.md](OPERATOR_INTEGRATION.md).

## Track A: Operator / Company Client

Audience:

- companies
- communities
- independent VPN operators
- teams that want a client for their own service

Goal:

- make the client adaptable for an operator-owned VPN service without opening
  the official POKROV backend, billing system, admin tools, signing identities,
  or deployment process

Expected capabilities:

- configurable service base URL
- configurable support links
- configurable public catalog and release metadata
- custom branding through documented build flavors and white-label color token
  export
- operator-managed profile delivery, plus optional local user-owned
  key/subscription import if the operator enables it
- managed profile endpoint examples
- operator-owned backend contract examples
- operator-owned color-token export with contrast checks

First-run path for operators:

1. choose the `operator` variant
2. run the local fixture backend
3. export white-label color tokens
4. implement the minimal managed-profile contract
5. replace support, billing, privacy, signing, and release channels with
   operator-owned surfaces

Boundaries:

- custom operator builds are not official POKROV builds
- operators own signing, support, backend compatibility, privacy policy,
  and release claims
- POKROV domains, bots, signing identities, and release channels stay official
  POKROV assets

## Track B: Personal Key Client

Audience:

- people who already have a key, profile, or subscription URL
- users who want a simple import-and-connect client

Goal:

- provide a no-account client mode where the user pastes a key, imports a QR
  code, or adds a subscription URL and connects without POKROV billing,
  cabinet, or account management

Expected capabilities:

- paste/import single key (`vless://`, `trojan://`, `ss://`, `vmess://`) -
  implemented as the first local-import MVP
- local multi-profile list with active selection, replace, and remove actions
- paste/import subscription URL with manual refresh and local storage
- foreground/manual subscription refresh that preserves old profiles on failure
- in-app foreground subscription scheduler with a freshness gate; no OS
  background service is claimed or required
- Android/Windows camera QR scanning through platform hosts, with scanned
  payloads handled by the shared local parser
- basic latency and connection checks
- clear unsupported-config errors

First-run path for ordinary users:

1. choose the `community` variant
2. build from source for Android or Windows
3. paste a `vless://`, `trojan://`, `ss://`, or `vmess://` key
4. scan a QR code for the same local parser flow
5. add a subscription URL only when you trust that provider
6. refresh manually or on foreground resume; OS background refresh is not
   claimed

Boundaries:

- personal profiles are local user-owned data
- the client must not silently upload third-party keys or subscriptions to
  POKROV
- POKROV support is for official builds and official service accounts, not
  arbitrary third-party configs
- advanced raw config editing should stay behind explicit advanced settings

## Optional Third-Party Public Config Catalog ("Free VPN" UI Label)

The open-source client may include an opt-in `Free VPN` section for public
third-party configuration feeds.

First research candidate:

- `AvenCores/goida-vpn-configs`
- URL: `https://github.com/AvenCores/goida-vpn-configs`
- observed license on 2026-06-05: `GPL-3.0`
- observed repo shape: public TXT subscription feeds under
  `githubmirror/*.txt`
- README describes V2Ray, VLESS, Hysteria, Trojan, VMess, Reality, and
  Shadowsocks config subscriptions
- README describes automatic updates every 9 minutes through GitHub Actions

Product rules:

- the catalog must be opt-in
- manual feed import must stay behind `OPEN_CLIENT_ENABLE_FREE_CATALOG=true`
  and default public builds must keep it disabled
- third-party feeds must be visibly labeled as third-party public configs
- third-party public configs must not be called official POKROV nodes
- the feature must not mix third-party feeds into the official POKROV node pool
- the client must not promise safety, speed, privacy, uptime, legality, or
  availability for third-party public configs

Implementation rules:

- parse feeds through a provider interface, not scattered UI code
- keep feed definitions in a reviewed catalog file
- store source, license, feed URL, last fetch time, parser version, and
  freshness for imported entries
- cache locally with expiry and manual refresh
- deduplicate entries before showing them
- reject malformed or unsupported configs with clear reasons
- provide a clear action to disable and clear imported public configs

Required gates:

1. license and attribution review for every feed source
2. parser fixtures and tests for every supported format
3. offline and GitHub-raw-unavailable behavior
4. UI copy that distinguishes public third-party configs from official POKROV
   service
5. release notes that do not imply POKROV operates or endorses third-party
   public feeds

Current implementation:

- `config/free-vpn-catalog.seed.json` records the first reviewed disabled
  candidate metadata for `AvenCores/goida-vpn-configs`
- parser fixtures cover the current `subscription_text` feed format, base64
  subscription bodies, supported protocols, duplicate isolation, and unsupported
  upstream protocol isolation
- the gated app action can manually import the reviewed candidate feed, cache
  accepted entries as local `third_party_catalog` profiles, preserve `sourceUrl`
  refresh metadata, and clear cached third-party catalog profiles without
  removing user-owned local keys or subscription imports when the build enables
  `OPEN_CLIENT_ENABLE_FREE_CATALOG=true`
- the catalog remains disabled by default and requires explicit user opt-in
- tests require license metadata, attribution, opt-in, and third-party boundary
  copy before release
