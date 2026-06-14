param(
  [string]$OutputDir = "build/android-device-validation",
  [switch]$Json
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$relativeOutput = "build/android-device-validation/android-device-validation-summary.json"

if ([System.IO.Path]::IsPathRooted($OutputDir)) {
  throw "OutputDir must be repository-relative and stay under build/android-device-validation."
}

$normalizedOutputDir = $OutputDir.Replace("/", "\").TrimEnd("\")
if ($normalizedOutputDir -ne "build\android-device-validation") {
  throw "OutputDir must stay under build/android-device-validation."
}

$manifestPath = Join-Path $root "apps/android_shell/android/app/src/main/AndroidManifest.xml"
$servicePath = Join-Path $root "apps/android_shell/android/app/src/main/kotlin/space/pokrov/pokrov_android_shell/PokrovRuntimeVpnService.kt"
$androidReadmePath = Join-Path $root "apps/android_shell/README.md"
$checklistPath = Join-Path $root "docs/device-validation/android.md"
$seedPath = Join-Path $root "config/android-device-validation.seed.json"

foreach ($path in @($manifestPath, $servicePath, $androidReadmePath, $checklistPath, $seedPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Required Android validation file is missing: $path"
  }
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath
$service = Get-Content -Raw -LiteralPath $servicePath
$androidReadme = Get-Content -Raw -LiteralPath $androidReadmePath
$checklist = Get-Content -Raw -LiteralPath $checklistPath

$manifestChecks = [System.Collections.Generic.List[string]]::new()
foreach ($needle in @(
    "android.permission.BIND_VPN_SERVICE",
    "android.permission.FOREGROUND_SERVICE_SPECIAL_USE",
    "android:foregroundServiceType=`"specialUse`"",
    "android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
  )) {
  if ($manifest.Contains($needle)) {
    $manifestChecks.Add($needle)
  } else {
    throw "Android manifest missing required validation marker: $needle"
  }
}
if (-not $manifestChecks.Contains("FOREGROUND_SERVICE_SPECIAL_USE")) {
  $manifestChecks.Add("FOREGROUND_SERVICE_SPECIAL_USE")
}

$serviceChecks = [System.Collections.Generic.List[string]]::new()
foreach ($check in @(
    @{ label = "FOREGROUND_SERVICE_SPECIAL_USE"; needle = "FOREGROUND_SERVICE_TYPE_SPECIAL_USE" },
    @{ label = "onRevoke"; needle = "onRevoke" },
    @{ label = "notification disconnect"; needle = "ACTION_STOP" },
    @{ label = "START_NOT_STICKY"; needle = "START_NOT_STICKY" },
    @{ label = "false connected guard"; needle = "tunEstablished = false" }
  )) {
  if ($service.Contains($check.needle)) {
    $serviceChecks.Add($check.label)
  } else {
    throw "Android runtime service missing required validation marker: $($check.label)"
  }
}

foreach ($needle in @(
    "physical-device release-build localhost/control-surface audit",
    "selected-apps parity is still not claimed",
    "Android 14",
    "Disconnect"
  )) {
  if (-not $androidReadme.Contains($needle)) {
    throw "apps/android_shell/README.md missing Android validation phrase: $needle"
  }
}

foreach ($needle in @(
    "MANUAL_OWNER_TEST",
    "does not prove store readiness",
    "does not prove trusted signing",
    "does not replace the release-build audit",
    "system VPN settings"
  )) {
  if (-not $checklist.Contains($needle)) {
    throw "docs/device-validation/android.md missing claim-boundary phrase: $needle"
  }
}

$summary = [ordered]@{
  schema_version = 1
  generated_at_utc = [DateTime]::UtcNow.ToString("o")
  local_precheck_passed = $true
  physical_device_status = "MANUAL_OWNER_TEST"
  manifest_checks = @($manifestChecks)
  service_checks = @($serviceChecks)
  manual_checks = @(
    "vpn_permission_flow",
    "foreground_service_special_use",
    "notification_disconnect",
    "system_vpn_revoke",
    "wifi_full_tunnel",
    "mobile_network_full_tunnel",
    "airplane_mode_recovery",
    "reconnect_loop",
    "subscription_refresh_failure_preserves_profile",
    "dns_no_desktop_loopback",
    "route_materialization",
    "false_connected_guard"
  )
  release_claims = [ordered]@{
    store_ready = $false
    trusted_signing = $false
    production_ready = $false
    official_binary_proof = $false
  }
  output_path = $relativeOutput
}

$outputPath = Join-Path $root $relativeOutput
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputPath) | Out-Null
$summaryJson = $summary | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($outputPath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

if ($Json) {
  Write-Output $summaryJson
} else {
  Write-Host "Android device validation local precheck OK"
  Write-Host "Physical device status: MANUAL_OWNER_TEST"
  Write-Host "Summary: $relativeOutput"
}
