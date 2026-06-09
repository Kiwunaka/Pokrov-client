# Product Variants

The public repository is split into three build modes. The first two are the
open-source product lines; the third exists only to keep the official POKROV
service build explicit.

## 1. Community Client

For ordinary users.

Goal: install the app, paste a local proxy key, choose routing, enable optional
WARP/routing features, and connect without a POKROV account, POKROV billing, or
POKROV branding. Subscription URL refresh is local/manual first; automatic
background refresh remains a planned follow-up.

Default properties:

- neutral name: `Open Client`
- no POKROV logo
- no managed-service API calls by default
- local profile import for single `vless://`, `trojan://`, `ss://`, and
  `vmess://` keys
- local multi-profile list with active selection, replace, and remove actions
- manual subscription URL import for supported public key feeds
- decoded QR payload import without adding a camera dependency to the shared
  shell
- support API disabled by default
- routing modes kept: full tunnel, selected apps, all-except-region
- optional public config catalogs stay disabled until parser/license/safety
  gates pass

Build define shape:

```powershell
flutter run --dart-define=OPEN_CLIENT_VARIANT=community --dart-define=OPEN_CLIENT_BRAND_NAME="Open Client"
```

## 2. Operator Client

For companies or teams with their own service.

Goal: let an operator replace branding, point the client at their backend, use
their own billing/support/account model, and ship a client that feels native to
their product.

Default properties:

- neutral placeholder name: `Operator Connect`
- no POKROV logo
- operator-owned API base URL
- operator-owned cabinet/support/billing surfaces
- same app shell, runtime bridge, WARP policy hooks, and routing UX
- required API contracts documented in
  [OPERATOR_INTEGRATION.md](OPERATOR_INTEGRATION.md)

Build define shape:

```powershell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=operator `
  --dart-define=OPEN_CLIENT_BRAND_NAME="Acme VPN" `
  --dart-define=OPEN_CLIENT_API_BASE_URL="https://api.acme.example/" `
  --dart-define=OPEN_CLIENT_CABINET_URL="https://app.acme.example/"
```

## 3. POKROV Service Mode

For official POKROV builds only.

This mode keeps the imported official-service flow reproducible without making
it the default open-source fork behavior.

Default properties:

- POKROV name and logo
- POKROV API/cabinet/checkout/support endpoints
- app-first trial/profile/redeem/bonus flows
- official-build and trademark restrictions from [BRAND.md](../BRAND.md)

Build define shape:

```powershell
flutter run `
  --dart-define=OPEN_CLIENT_VARIANT=pokrov `
  --dart-define=OPEN_CLIENT_BRAND_NAME=POKROV `
  --dart-define=OPEN_CLIENT_BRAND_ASSET=assets/brand/pokrov_mark.png
```

## Current Implementation Status

Implemented now:

- variant seed configs under `config/variants/`
- compile-time variant profile in the shared app shell
- community default avoids POKROV API bootstrap and POKROV support API calls
- community redeem/import sheet can stage a local single-key profile for the
  runtime without calling the POKROV API
- community profile screen shows the active local profile and supports
  list/select/replace/remove actions
- manual subscription URL import stores supported entries locally
- decoded QR payload import reuses the same safe local parser
- neutral fallback brand mark when no asset is supplied
- operator/pokrov modes can opt into managed-service API bootstrap

Still planned:

- camera-backed QR scanner in platform hosts
- automatic subscription refresh scheduler
- operator API fixture server
- white-label color token export
- free VPN catalog parser and safety-copy gate
