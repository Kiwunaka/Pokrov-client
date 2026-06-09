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

### `POST /api/client/session/start-trial`

Creates or resumes an app session.

Expected response shape:

```json
{
  "session_token": "short-lived-or-refreshable-client-token",
  "profile": {
    "url": "/api/client/profile/managed"
  }
}
```

### `GET /api/client/profile/managed`

Returns a runtime profile for sing-box/libcore materialization.

Expected response shape:

```json
{
  "profile_name": "operator-managed",
  "config": {
    "outbounds": [],
    "route": {
      "final": "proxy"
    }
  },
  "materialized_for_runtime": true
}
```

### `POST /api/client/redeem`

Optional code/key activation endpoint.

### `GET /api/client/apps`

Optional app metadata and update prompt endpoint.

### Support Endpoints

Optional if you want in-app support:

- `GET /api/client/support/tickets`
- `POST /api/client/support/tickets`
- `GET /api/client/support/tickets/{ticket_id}`
- `POST /api/client/support/tickets/{ticket_id}/messages`

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
