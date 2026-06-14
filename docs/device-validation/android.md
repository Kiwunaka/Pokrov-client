# Android device validation

This checklist is the public open-source Android device validation lane for
the Community/Open Client source tree. It records what a maintainer must test
on a real Android device before making Android runtime or binary claims.

Status label: `MANUAL_OWNER_TEST`.

The local helper checks repository contracts only:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\android-device-smoke.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\android-device-smoke.ps1 -Json
```

The helper writes a local summary under `build/android-device-validation/`.
It is read-only, does not run ADB commands, does not mutate a phone, does not
install builds, and does not upload evidence.

## Local Precheck

The helper verifies that the public Android host still declares and wires:

- `VpnService permission` via `android.permission.BIND_VPN_SERVICE`
- `Android 14 specialUse foreground service`
- `FOREGROUND_SERVICE_SPECIAL_USE`
- foreground runtime service source
- `onRevoke` handling for permission removal from system VPN settings
- notification disconnect action through the runtime service stop path
- neutral open-source Android host branding defaults

Passing this precheck only means the public source tree still contains the
expected Android hooks.

## Manual Device Matrix

Run these checks on the exact release-build candidate and record the result as
`MANUAL_OWNER_TEST`, `OPERATOR_ATTESTED`, `BLOCKED_BY_ACCESS`, or
`SKIPPED_BY_OWNER`.

| Check | Expected result |
| --- | --- |
| First connect asks for `VpnService permission` | User sees the Android VPN consent flow before the TUN starts. |
| Foreground service on Android 14+ | Android accepts the `Android 14 specialUse foreground service` lane without a crash. |
| Wi-Fi full tunnel | Connection reaches `running` or `connected with warnings` with DNS/uplink diagnostics visible. |
| mobile network full tunnel | Same as Wi-Fi, without desktop loopback DNS or desktop inbounds. |
| airplane mode recovery | The app exits the failed state clearly and can reconnect after network returns. |
| Reconnect loop | Repeated connect/disconnect taps do not create duplicate runtime starts. |
| System VPN revoke | Revoking from system VPN settings triggers `onRevoke` and clears the connected state. |
| Notification disconnect | The foreground notification disconnect action stops the runtime. |
| Subscription refresh failure | A failed refresh keeps the old profile available; old profile must remain available. |
| Route materialization | Full tunnel and All except RU use the shared route materialization path. |
| False connected guard | The app does not show a clean connected state when TUN, DNS, or uplink diagnostics report failure. |

## Claim Boundary

This checklist does not prove store readiness, does not prove trusted signing,
does not replace the release-build audit, and does not authorize stable,
production, Google Play, or official binary claims.

Before any public Android binary release, maintainers still need the release
checklist, source proof, exact commit/tag, artifact hash, signing/store status,
known limitations, and final human review.
