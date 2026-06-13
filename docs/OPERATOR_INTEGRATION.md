# Operator Integration

This guide is for teams that want to ship their own branded client using the
public source.

## What You Bring

- service API
- account/session model
- managed profile delivery
- billing/checkout if you sell subscriptions
- support process
- signing identities and release channels
- brand assets, app name, package identifiers, and privacy policy

POKROV does not provide your backend, billing, support, signing, or release
claims.

## Minimal API Contract

The current imported service mode expects these endpoints when
`OPEN_CLIENT_VARIANT=operator`.

The machine-readable contract lives in
[`docs/operator/openapi.yaml`](operator/openapi.yaml). A local fixture backend
is available through
[`tools/operator_fixture_server`](../tools/operator_fixture_server) and
[`config/operator-api.fixture.json`](../config/operator-api.fixture.json). The
fixture is only for local contract development and must not contain real tokens,
private URLs, production endpoints, or official POKROV infrastructure.

Run a local smoke:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-operator-fixture-smoke.ps1
```

Or start the server manually:

```powershell
python -m tools.operator_fixture_server --port 8765
```

The fixture supports error modes for client testing:

```powershell
Invoke-RestMethod http://127.0.0.1:8765/api/client/profile/managed?mode=401
Invoke-RestMethod http://127.0.0.1:8765/api/client/profile/managed?mode=500
Invoke-RestMethod http://127.0.0.1:8765/api/client/profile/managed?mode=malformed-profile
```

### `POST /api/client/session/start-trial`

Creates or resumes an app session.

Expected response shape:

```json
{
  "session": {
    "session_token": "short-lived-or-refreshable-client-token",
    "account_id": "operator-account-id"
  },
  "provisioning": {
    "status": "ready",
    "sync_ok": true,
    "managed_manifest": {
      "url": "/api/client/profile/managed"
    }
  }
}
```

### `POST /api/client/route-policy`

Stores the current route mode before the client fetches a managed profile.

Expected response shape:

```json
{
  "ok": true,
  "applied": true
}
```

### `GET /api/client/profile/managed`

Returns a runtime profile for sing-box/libcore materialization.

Expected response shape:

```json
{
  "profile_name": "operator-managed",
  "profile_revision": "operator-demo-rev-1",
  "provisioning": {
    "status": "ready",
    "sync_ok": true
  },
  "config": {
    "outbounds": [],
    "route": {
      "final": "proxy"
    }
  },
  "materialized_for_runtime": true
}
```

### `POST /api/redeem`

Optional code/key activation endpoint.

`POST /api/client/redeem` may be exposed as a compatibility alias, but the
current open client adapter calls `/api/redeem`.

### `GET /api/client/apps`

Optional app metadata and update prompt endpoint.

Return prompt-style metadata only. Do not claim silent updates, store
availability, trusted signing, or official POKROV binaries unless your fork has
separate evidence for those claims.

### Support Endpoints

Optional if you want in-app support:

- `GET /api/client/support/tickets`
- `POST /api/client/support/tickets`
- `GET /api/client/support/tickets/{ticket_id}`
- `POST /api/client/support/tickets/{ticket_id}/messages`

### Optional App-First Endpoints

These endpoints are useful for richer branded forks, but not required for the
first operator smoke:

- `POST /api/client/cabinet-token`
- `POST /api/client/telegram/link`
- `GET /api/client/bonus/summary`
- `POST /api/client/warp/consent`
- `POST /api/client/warp/revoke`
- `POST /api/client/nodes/preference`

## Build Defines

```powershell
flutter build windows --release `
  --dart-define=OPEN_CLIENT_VARIANT=operator `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Acme VPN" `
  --dart-define=OPEN_CLIENT_API_BASE_URL="https://api.acme.example/" `
  --dart-define=OPEN_CLIENT_CABINET_URL="https://app.acme.example/" `
  --dart-define=OPEN_CLIENT_CHECKOUT_URL="https://pay.acme.example/checkout"
```

For Android, pass the same defines to `flutter build apk` or your Gradle-backed
Flutter build.

## Branding Checklist

- replace launcher icons
- replace `OPEN_CLIENT_BRAND_ASSET` or keep the neutral text mark
- set package/bundle identifiers
- set Windows runner metadata
- update privacy policy/support links
- remove all claims that imply official POKROV operation

## Runtime Artifacts

Native runtime artifacts are intentionally not committed. Use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\fetch-libcore-assets.ps1 -Platforms @("windows","android") -SyncToHosts
```

Review upstream runtime licenses before releasing binaries.

## Operator Launch Checklist

- Replace brand name, mark, package IDs, and platform metadata.
- Point API, cabinet, checkout, support, privacy, and release URLs at your own
  service.
- Implement the minimal managed-profile endpoint before enabling paid flows.
- Keep subscription/key import behavior clear: local community profiles are
  user-owned, operator-managed profiles are service-owned.
- Publish your own checksums, signing notes, support policy, and privacy policy.
