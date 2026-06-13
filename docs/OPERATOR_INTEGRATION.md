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

## First-Run Path For Operators

1. choose the `operator` variant
2. run the local fixture backend with
   `powershell -ExecutionPolicy Bypass -File .\scripts\run-operator-fixture-smoke.ps1`
3. export white-label color tokens with
   `powershell -ExecutionPolicy Bypass -File .\scripts\export-white-label-color-tokens.ps1`
4. implement the minimal managed-profile contract from
   [`docs/operator/openapi.yaml`](operator/openapi.yaml)
5. replace placeholder API, cabinet, checkout, support, privacy, signing, and
   release channels with operator-owned surfaces
6. publish your own support policy, privacy policy, checksums, signing notes,
   and release notes

## Minimal API Contract

Operator mode can implement a compatible managed-profile contract for these
seed endpoints. The names are public examples, not access to the official
POKROV backend.

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
Invoke-RestMethod http://127.0.0.1:8765/api/client/profile/managed?mode=429
Invoke-RestMethod http://127.0.0.1:8765/api/client/profile/managed?mode=500
Invoke-RestMethod http://127.0.0.1:8765/api/client/profile/managed?mode=malformed-profile
```

## Contract Conventions

The current public operator contract is `2026-06-operator-v1`. It is intentionally
small, but operators should keep these conventions stable before shipping a
branded client:

- accept `X-Request-ID` on every client request and echo it on every response
- accept `X-Client-Version` so the backend can make compatibility decisions
- return `X-API-Version` on every response
- return `Retry-After` with HTTP `429` rate limits
- use `Deprecation` and `Sunset` headers before removing or changing a route,
  field, enum value, or error code
- keep `error.code` stable for client behavior and support triage
- keep `error.message` safe for logs and support, without secrets or profile
  URLs

Standard error response:

```json
{
  "ok": false,
  "error": {
    "code": "rate_limited",
    "message": "Too many requests. Retry after the advertised delay.",
    "request_id": "client-or-server-trace-id",
    "retryable": true,
    "retry_after_seconds": 60
  }
}
```

Stable error codes for this source milestone:

| Code | Meaning | Retry |
| --- | --- | --- |
| `bad_request` | Request shape or field value is invalid. | No, unless the user changes input. |
| `unauthorized` | Session token is missing, expired, or rejected. | After session refresh or sign-in. |
| `forbidden` | Account or policy does not allow the action. | No. |
| `not_found` | Route or resource does not exist. | No. |
| `rate_limited` | The operator service is throttling requests. | Yes, after `Retry-After`. |
| `server_error` | Operator backend failed unexpectedly. | Yes, with backoff. |

## Session Lifecycle

`POST /api/client/session/start-trial` creates or resumes a client session. The
response must include:

- `session.session_token`: short-lived bearer token for managed endpoints
- `session.token_type`: `Bearer`
- `session.expires_in`: token lifetime in seconds
- `session.refresh_after`: suggested refresh point before expiry
- `provisioning.managed_manifest.version`: profile contract version, currently
  `operator-v1`

Clients should refresh or restart the session before `expires_in` elapses. Do
not ask users to paste tokens into GitHub issues or support chats.

### `POST /api/client/session/start-trial`

Creates or resumes an app session.

Expected response shape:

```json
{
  "session": {
    "session_token": "short-lived-or-refreshable-client-token",
    "account_id": "operator-account-id",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_after": 3000
  },
  "provisioning": {
    "status": "ready",
    "sync_ok": true,
    "managed_manifest": {
      "url": "/api/client/profile/managed",
      "version": "operator-v1"
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
  --dart-define=OPEN_CLIENT_ANDROID_PACKAGE_NAME=com.acme.vpn `
  --dart-define=OPEN_CLIENT_API_BASE_URL="https://api.acme.example/" `
  --dart-define=OPEN_CLIENT_CABINET_URL="https://app.acme.example/" `
  --dart-define=OPEN_CLIENT_CHECKOUT_URL="https://pay.acme.example/checkout" `
  --dart-define=OPEN_CLIENT_SUPPORT_URL="https://support.acme.example/" `
  --dart-define=OPEN_CLIENT_PRIVACY_URL="https://acme.example/privacy/"
```

For Android, pass the same defines to `flutter build apk` or your Gradle-backed
Flutter build. Keep `OPEN_CLIENT_ANDROID_PACKAGE_NAME` aligned with the Gradle
`openClientApplicationId` property so Android self-bypass routing uses the
actual package name.

This is a build example only. Operators still own signing, store review,
privacy/legal review, update metadata, support, abuse handling, payment/refund
flows, checksums, and release evidence.

## Branding Checklist

- replace launcher icons
- replace `OPEN_CLIENT_BRAND_ASSET` or keep the neutral text mark
- set package/bundle identifiers, including both `OPEN_CLIENT_ANDROID_PACKAGE_NAME`
  and Android `openClientApplicationId`
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
