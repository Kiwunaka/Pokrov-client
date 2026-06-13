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

Operator builds are not POKROV builds. Do not use POKROV names, logos,
endpoints, support bots, signing identities, release channels, or official
service claims for your users.

## Minimal API Contract

Operator mode can implement a compatible managed-profile contract for these
seed endpoints. The names are public examples, not access to the official
POKROV backend.

A placeholder fixture is available at
[`config/operator-api.fixture.json`](../config/operator-api.fixture.json). It is
not a server and must not contain real tokens, private URLs, or production
secrets.

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
  --dart-define=OPEN_CLIENT_CHECKOUT_URL="https://pay.acme.example/checkout" `
  --dart-define=OPEN_CLIENT_SUPPORT_URL="https://support.acme.example/" `
  --dart-define=OPEN_CLIENT_PRIVACY_URL="https://acme.example/privacy/"
```

For Android, pass the same defines to `flutter build apk` or your Gradle-backed
Flutter build.

This is a build example only. Operators still own signing, store review,
privacy/legal review, update metadata, support, abuse handling, payment/refund
flows, checksums, and release evidence.

## Branding Checklist

- replace launcher icons
- replace `OPEN_CLIENT_BRAND_ASSET` or keep the neutral text mark
- set package/bundle identifiers
- set Windows runner metadata
- update privacy policy/support links
- remove all claims that imply official POKROV operation
- do not route your users to POKROV support bots or POKROV security contacts

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
