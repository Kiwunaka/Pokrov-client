# Product Variants

The public repository is split into three build modes. The first two are the
open-source product lines; the third exists only to keep the official POKROV
service build explicit.

## 1. Community Client

For ordinary users who bring their own local keys or subscription URLs. This is
not an official POKROV account flow and not a free POKROV service by default.

Goal: install the app, paste a local proxy key, choose routing, enable optional
advanced routing/privacy controls where they are implemented and user-enabled,
and connect without a POKROV account, POKROV billing, or POKROV branding.
Subscription URL refresh is local/manual, refreshes on app resume when stale,
and can use an in-app foreground scheduler. OS background refresh is not
claimed.

First-run path for ordinary users:

1. choose the `community` variant
2. build from source for Android or Windows
3. paste a `vless://`, `trojan://`, `ss://`, or `vmess://` key
4. scan a QR code if the key is on another screen
5. add a subscription URL when a provider gives a managed public feed
6. choose routing locally and connect without a POKROV account

Default properties:

- neutral name: `Open Client`
- no POKROV logo
- no managed-service API calls by default
- local profile import for single `vless://`, `trojan://`, `ss://`, and
  `vmess://` keys
- local multi-profile list with active selection, replace, and remove actions
- manual, foreground, and in-app scheduled subscription URL refresh for
  supported public key feeds
- Android/Windows camera QR import through platform hosts; scanned payloads
  still flow through the shared local parser
- support API disabled by default
- routing modes kept: full tunnel, selected apps, all-except-region
- optional public config catalogs stay disabled until parser/license/safety
  gates pass; manual import also requires
  `OPEN_CLIENT_ENABLE_FREE_CATALOG=true`

Build define shape:

Preview the current seed-backed command with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\print-build-variant-command.ps1 -Variant community -Platform android
```

```powershell
Push-Location apps/android_shell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=community `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Open Client" `
  --dart-define=OPEN_CLIENT_ANDROID_PACKAGE_NAME=org.pokrovclient.community `
  --dart-define=OPEN_CLIENT_ENABLE_FREE_CATALOG=false
Pop-Location
```

## 2. Operator Client

For companies or teams with their own service.

Goal: let an operator replace branding, point the client at their backend, use
their own billing/support/account model, and ship a client that feels native to
their product.

First-run path for operators:

1. choose the `operator` variant
2. run the local fixture backend
3. export white-label color tokens for your own brand review
4. implement the minimal managed-profile contract
5. replace API, cabinet, checkout, support, privacy, signing, and release
   channels with operator-owned surfaces

Default properties:

- neutral placeholder name: `Operator Connect`
- no POKROV logo
- operator-owned API base URL
- operator-owned cabinet/support/billing surfaces
- white-label color token export for operator-owned branding pipelines
- same app shell, runtime bridge, WARP policy hooks, and routing UX
- required API contracts documented in
  [OPERATOR_INTEGRATION.md](OPERATOR_INTEGRATION.md)

Build define shape:

Preview the current seed-backed command with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\print-build-variant-command.ps1 -Variant operator -Platform windows
```

```powershell
Push-Location apps/windows_shell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=operator `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Acme VPN" `
  --dart-define=OPEN_CLIENT_ANDROID_PACKAGE_NAME=com.acme.vpn `
  --dart-define=OPEN_CLIENT_API_BASE_URL="https://api.acme.example/" `
  --dart-define=OPEN_CLIENT_CABINET_URL="https://app.acme.example/" `
  --dart-define=OPEN_CLIENT_SUPPORT_URL="https://support.acme.example/" `
  --dart-define=OPEN_CLIENT_PRIVACY_URL="https://acme.example/privacy/"
Pop-Location
```

## 3. POKROV Service Mode

For official POKROV builds only.

This mode keeps the imported official-service flow reproducible without making
it the default open-source fork behavior. Forks and operators must not
distribute builds using the POKROV name, logo, endpoints, support, or release
claims.

Default properties:

- POKROV name and logo
- POKROV API/cabinet/checkout/support endpoints
- app-first trial/profile/redeem/bonus flows
- official-build and trademark restrictions from [BRAND.md](../BRAND.md)

Build define shape:

Preview the current seed-backed command with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\print-build-variant-command.ps1 -Variant pokrov -Platform android
```

```powershell
Push-Location apps/android_shell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=pokrov `
  --dart-define=OPEN_CLIENT_OFFICIAL_BUILD=true `
  --dart-define=OPEN_CLIENT_BRAND_NAME=POKROV `
  --dart-define=OPEN_CLIENT_ANDROID_PACKAGE_NAME=space.pokrov.app `
  --dart-define=OPEN_CLIENT_BRAND_ASSET=assets/brand/pokrov_mark.png
Pop-Location
```

## Current Implementation Status

Implemented now:

- variant seed configs under `config/variants/`
- seed-backed variant command preview helper for Android and Windows
- compile-time variant profile in the shared app shell
- community default avoids POKROV API bootstrap and POKROV support API calls
- community redeem/import sheet can stage a local single-key profile for the
  runtime without calling the POKROV API
- community profile screen shows the active local profile and supports
  list/select/replace/remove actions
- manual subscription URL import stores supported entries locally
- manual, foreground, and in-app scheduled subscription refresh stores metadata
  and preserves old profiles on failed refresh
- Android/Windows camera QR import reuses the same safe local parser
- reviewed disabled Free VPN catalog seed for `AvenCores/goida-vpn-configs`
- Free VPN catalog parser fixtures for the reviewed `subscription_text` feed
  format
- gated Free VPN catalog action can manually import the reviewed candidate feed,
  cache accepted entries as local third-party catalog profiles, refresh through
  the existing subscription refresh flow, and clear only those cached catalog
  entries when `OPEN_CLIENT_ENABLE_FREE_CATALOG=true`; default builds keep the
  preview visible but import disabled
- community WARP/enhanced-protection public copy avoids official-service
  claims while keeping technical diagnostics internal
- neutral fallback brand mark when no asset is supplied
- neutral Android/Windows native host defaults for community artifacts
- white-label color token seed, contrast checks, and export helper for operator
  forks
- operator/pokrov modes can opt into managed-service API bootstrap

Still planned:

- broader reviewed feed selection and any enabled-by-default catalog experience;
  the current catalog remains gated, manual, and opt-in
