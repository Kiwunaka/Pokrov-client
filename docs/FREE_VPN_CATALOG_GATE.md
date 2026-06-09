# Free VPN Catalog Gate

The community client may expose public third-party config feeds, but the shared
app must keep the catalog disabled until these gates are complete.

## Candidate

- Source: `AvenCores/goida-vpn-configs`
- URL: `https://github.com/AvenCores/goida-vpn-configs`
- Intended UI label: third-party public configs

## Required Before Enabling

- Confirm license and attribution text.
- Record feed URLs, update cadence, and freshness expectations.
- Add parser fixtures for every enabled feed format.
- Keep malformed entries isolated from valid entries.
- Cache fetched feeds locally with manual refresh and clear actions.
- Show copy that says these are not official POKROV nodes.
- Avoid speed, safety, privacy, uptime, legality, or availability promises.

## Current State

The app has a gated `Free VPN catalog` profile action. It explains the safety
boundary and does not fetch or enable third-party feeds yet.
