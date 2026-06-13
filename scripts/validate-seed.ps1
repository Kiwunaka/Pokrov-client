$root = Split-Path -Parent $PSScriptRoot

$requiredDirectories = @(
  "apps",
  "apps\\android_shell",
  "apps\\android_shell\\lib",
  "apps\\android_shell\\test",
  "apps\\windows_shell",
  "apps\\windows_shell\\lib",
  "apps\\windows_shell\\test",
  "packages",
  "packages\\app_shell",
  "packages\\app_shell\\lib",
  "packages\\app_shell\\test",
  "packages\\core_domain",
  "packages\\core_domain\\lib",
  "packages\\platform_contracts",
  "packages\\platform_contracts\\lib",
  "packages\\runtime_engine",
  "packages\\runtime_engine\\lib",
  "packages\\runtime_engine\\test",
  "packages\\support_context",
  "packages\\support_context\\lib",
  "config",
  "config\\templates",
  "config\\variants",
  "docs",
  "docs\\operator",
  "docs\\releases",
  "assets\\brand",
  "assets\\branding",
  "assets\\diagrams",
  "scripts",
  "test"
)

$requiredFiles = @(
  "README.md",
  ".gitignore",
  ".editorconfig",
  "melos.yaml",
  "program.seed.yaml",
  "config\\product-contract.seed.json",
  "config\\platform-matrix.seed.json",
  "config\\runtime-profile.seed.json",
  "config\\runtime-artifacts.seed.json",
  "config\\windows-release.seed.json",
  "config\\operator-api.fixture.json",
  "config\\free-vpn-catalog.seed.json",
  "config\\dependency-license-inventory.seed.json",
  "config\\generated-assets.seed.json",
  "config\\white-label-color-tokens.seed.json",
  "config\\white-label-color-tokens.schema.json",
  "config\\variants\\community-client.seed.json",
  "config\\variants\\operator-client.seed.json",
  "config\\variants\\pokrov-service.seed.json",
  "config\\templates\\local.env.example",
  "docs\\OPEN_SOURCE_SCOPE.md",
  "docs\\PRODUCT_VARIANTS.md",
  "docs\\OPERATOR_INTEGRATION.md",
  "docs\\FREE_VPN_CATALOG_GATE.md",
  "docs\\WHITE_LABEL_BRANDING.md",
  "docs\\BUILD_FROM_SOURCE.md",
  "docs\\DEPENDENCY_LICENSE_AUDIT.md",
  "docs\\RELEASE_CHECKLIST.md",
  "docs\\operator\\openapi.yaml",
  "apps\\README.md",
  "apps\\android_shell\\README.md",
  "apps\\android_shell\\pubspec.yaml",
  "apps\\android_shell\\lib\\main.dart",
  "apps\\android_shell\\lib\\community_qr_scanner.dart",
  "apps\\android_shell\\test\\widget_test.dart",
  "apps\\windows_shell\\README.md",
  "apps\\windows_shell\\pubspec.yaml",
  "apps\\windows_shell\\lib\\main.dart",
  "apps\\windows_shell\\lib\\community_qr_scanner.dart",
  "apps\\windows_shell\\test\\widget_test.dart",
  "packages\\README.md",
  "packages\\app_shell\\README.md",
  "packages\\app_shell\\pubspec.yaml",
  "packages\\app_shell\\lib\\app_shell.dart",
  "packages\\core_domain\\README.md",
  "packages\\core_domain\\pubspec.yaml",
  "packages\\core_domain\\lib\\core_domain.dart",
  "packages\\platform_contracts\\README.md",
  "packages\\platform_contracts\\pubspec.yaml",
  "packages\\platform_contracts\\lib\\platform_contracts.dart",
  "packages\\runtime_engine\\README.md",
  "packages\\runtime_engine\\pubspec.yaml",
  "packages\\runtime_engine\\lib\\runtime_engine.dart",
  "packages\\runtime_engine\\test\\runtime_engine_test.dart",
  "packages\\support_context\\README.md",
  "packages\\support_context\\pubspec.yaml",
  "packages\\support_context\\lib\\support_context.dart",
  "assets\\README.md",
  "assets\\brand\\pokrov-oss-hero.png",
  "assets\\brand\\oss-status-card.png",
  "assets\\branding\\README.md",
  "scripts\\README.md",
  "scripts\\bootstrap-workspace.ps1",
  "scripts\\bootstrap-local.ps1",
  "scripts\\fetch-libcore-assets.ps1",
  "scripts\\prepare-oss-import.ps1",
  "scripts\\run-operator-fixture-smoke.ps1",
  "scripts\\run-tests.ps1",
  "scripts\\validate-seed.ps1",
  "scripts\\export-white-label-color-tokens.ps1",
  "test\\README.md",
  "test\\seed-layout.ps1",
  "packages\\app_shell\\test\\pokrov_seed_app_test.dart"
)

$jsonFiles = @(
  "config\\product-contract.seed.json",
  "config\\platform-matrix.seed.json",
  "config\\runtime-profile.seed.json",
  "config\\runtime-artifacts.seed.json",
  "config\\windows-release.seed.json",
  "config\\operator-api.fixture.json",
  "config\\free-vpn-catalog.seed.json",
  "config\\dependency-license-inventory.seed.json",
  "config\\generated-assets.seed.json",
  "config\\white-label-color-tokens.seed.json",
  "config\\white-label-color-tokens.schema.json",
  "config\\variants\\community-client.seed.json",
  "config\\variants\\operator-client.seed.json",
  "config\\variants\\pokrov-service.seed.json"
)

$missing = [System.Collections.Generic.List[string]]::new()
$invalidJson = [System.Collections.Generic.List[string]]::new()
$manifestErrors = [System.Collections.Generic.List[string]]::new()
$expectedPublicTargets = @("android", "windows")
$expectedReadinessOnlyTargets = @("ios", "macos")
$expectedHostShells = @{
  android = "apps/android_shell"
  ios = "apps/ios_shell"
  macos = "apps/macos_shell"
  windows = "apps/windows_shell"
}

function Test-PokrovEndpoint {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $false
  }
  try {
    $uri = [System.Uri]::new($Value)
    $endpointHost = $uri.Host.ToLowerInvariant()
  } catch {
    $endpointHost = $Value.ToLowerInvariant()
  }
  return ($endpointHost -eq "pokrov.space" -or $endpointHost.EndsWith(".pokrov.space"))
}

function Test-PokrovBrand {
  param([string]$Value)
  return (-not [string]::IsNullOrWhiteSpace($Value)) -and $Value.ToLowerInvariant().Contains("pokrov")
}

foreach ($relativePath in $requiredDirectories) {
  $fullPath = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
    $missing.Add("DIR  $relativePath")
  }
}

foreach ($relativePath in $requiredFiles) {
  $fullPath = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    $missing.Add("FILE $relativePath")
  }
}

foreach ($relativePath in $jsonFiles) {
  $fullPath = Join-Path $root $relativePath
  if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
    try {
      Get-Content -Raw -LiteralPath $fullPath | ConvertFrom-Json | Out-Null
    } catch {
      $invalidJson.Add($relativePath)
    }
  }
}

$platformMatrixPath = Join-Path $root "config\\platform-matrix.seed.json"
if (Test-Path -LiteralPath $platformMatrixPath -PathType Leaf) {
  $platformMatrix = Get-Content -Raw -LiteralPath $platformMatrixPath | ConvertFrom-Json

  foreach ($target in $expectedPublicTargets) {
    if (@($platformMatrix.public_release_targets) -notcontains $target) {
      $manifestErrors.Add("config\\platform-matrix.seed.json must include public target '$target'")
    }
  }

  foreach ($target in $expectedReadinessOnlyTargets) {
    if (@($platformMatrix.readiness_only_targets) -notcontains $target) {
      $manifestErrors.Add("config\\platform-matrix.seed.json must include readiness-only target '$target'")
    }
  }

  if (@($platformMatrix.readiness_only_targets).Count -ne $expectedReadinessOnlyTargets.Count) {
    $manifestErrors.Add("config\\platform-matrix.seed.json must keep readiness_only_targets limited to ios and macos for the Android+Windows public lane")
  }

  foreach ($target in $expectedHostShells.Keys) {
    if ($platformMatrix.host_shells.$target -ne $expectedHostShells[$target]) {
      $manifestErrors.Add("config\\platform-matrix.seed.json must map '$target' to '$($expectedHostShells[$target])'")
    }
  }
}

$productContractPath = Join-Path $root "config\\product-contract.seed.json"
if (Test-Path -LiteralPath $productContractPath -PathType Leaf) {
  $productContract = Get-Content -Raw -LiteralPath $productContractPath | ConvertFrom-Json

  foreach ($target in $expectedPublicTargets) {
    if (@($productContract.public_scope) -notcontains $target) {
      $manifestErrors.Add("config\\product-contract.seed.json must include public scope '$target'")
    }
  }

  foreach ($target in $expectedReadinessOnlyTargets) {
    if (@($productContract.readiness_only_scope) -notcontains $target) {
      $manifestErrors.Add("config\\product-contract.seed.json must include readiness-only scope '$target'")
    }
  }

  if (@($productContract.readiness_only_scope).Count -ne $expectedReadinessOnlyTargets.Count) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep readiness_only_scope limited to ios and macos for the Android+Windows public lane")
  }

  if (@($productContract.public_routing_modes) -notcontains "selected_apps") {
    $manifestErrors.Add("config\\product-contract.seed.json must expose selected_apps in public_routing_modes")
  }

  if ($productContract.free_tier.node_pool -ne "NL-free") {
    $manifestErrors.Add("config\\product-contract.seed.json must keep free_tier.node_pool as NL-free")
  }

  if ([int]$productContract.free_tier.traffic_gb -ne 5) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep free_tier.traffic_gb at 5")
  }

  if ([int]$productContract.free_tier.speed_mbps -ne 50) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep free_tier.speed_mbps at 50")
  }

  if ($productContract.monetization.in_app_purchases -ne $false) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep monetization.in_app_purchases false")
  }

  if ($productContract.monetization.third_party_ads -ne $false) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep monetization.third_party_ads false")
  }

  if ($productContract.monetization.first_party_promos_only -ne $true) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep monetization.first_party_promos_only true")
  }

  $expectedVariantOrder = @("vless_reality", "vmess", "trojan", "xhttp")
  if ((@($productContract.location_variant_order) -join ",") -ne ($expectedVariantOrder -join ",")) {
    $manifestErrors.Add("config\\product-contract.seed.json must keep location_variant_order as vless_reality, vmess, trojan, xhttp")
  }
}

$runtimeProfilePath = Join-Path $root "config\\runtime-profile.seed.json"
if (Test-Path -LiteralPath $runtimeProfilePath -PathType Leaf) {
  $runtimeProfile = Get-Content -Raw -LiteralPath $runtimeProfilePath | ConvertFrom-Json

  if (@($runtimeProfile.public_routing_modes) -notcontains "selected_apps") {
    $manifestErrors.Add("config\\runtime-profile.seed.json must expose selected_apps in public_routing_modes")
  }

  if ($runtimeProfile.free_tier.node_pool -ne "NL-free") {
    $manifestErrors.Add("config\\runtime-profile.seed.json must keep free_tier.node_pool as NL-free")
  }

  if ([int]$runtimeProfile.free_tier.speed_mbps -ne 50) {
    $manifestErrors.Add("config\\runtime-profile.seed.json must keep free_tier.speed_mbps at 50")
  }

  if ($runtimeProfile.monetization.in_app_purchases -ne $false) {
    $manifestErrors.Add("config\\runtime-profile.seed.json must keep monetization.in_app_purchases false")
  }

  if ($runtimeProfile.monetization.third_party_ads -ne $false) {
    $manifestErrors.Add("config\\runtime-profile.seed.json must keep monetization.third_party_ads false")
  }

  if ($runtimeProfile.official_surfaces.checkout -ne "https://pay.pokrov.space/checkout/") {
    $manifestErrors.Add("config\\runtime-profile.seed.json must keep the checkout official surface on https://pay.pokrov.space/checkout/")
  }
}

$runtimeArtifactsPath = Join-Path $root "config\\runtime-artifacts.seed.json"
if (Test-Path -LiteralPath $runtimeArtifactsPath -PathType Leaf) {
  $runtimeArtifacts = Get-Content -Raw -LiteralPath $runtimeArtifactsPath | ConvertFrom-Json

  if ($runtimeArtifacts.libcore.release_tag -ne "v3.1.8") {
    $manifestErrors.Add("config\\runtime-artifacts.seed.json must keep libcore.release_tag pinned to v3.1.8 until the runtime lane moves in one tracked wave")
  }

  if ($runtimeArtifacts.libcore.repository -ne "hiddify/hiddify-core") {
    $manifestErrors.Add("config\\runtime-artifacts.seed.json must keep libcore.repository on hiddify/hiddify-core")
  }

  foreach ($target in @("android", "ios", "macos", "windows")) {
    if (-not $runtimeArtifacts.libcore.assets.$target) {
      $manifestErrors.Add("config\\runtime-artifacts.seed.json must define libcore asset metadata for $target")
    }
  }
}

$windowsReleaseConfigPath = Join-Path $root "config\\windows-release.seed.json"
if (Test-Path -LiteralPath $windowsReleaseConfigPath -PathType Leaf) {
  $windowsReleaseConfig = Get-Content -Raw -LiteralPath $windowsReleaseConfigPath | ConvertFrom-Json

  if ($windowsReleaseConfig.binary_name -ne "open_client_windows.exe") {
    $manifestErrors.Add("config\\windows-release.seed.json must keep binary_name as open_client_windows.exe")
  }

  if ($windowsReleaseConfig.runtime.platform -ne "windows") {
    $manifestErrors.Add("config\\windows-release.seed.json must keep runtime.platform as windows")
  }

  if ($windowsReleaseConfig.runtime.artifact_directory -ne "apps/windows_shell/windows/runner/resources/runtime") {
    $manifestErrors.Add("config\\windows-release.seed.json must keep runtime.artifact_directory on apps/windows_shell/windows/runner/resources/runtime")
  }

  foreach ($requiredPath in @("open_client_windows.exe", "libcore.dll", "data/app.so")) {
    if (@($windowsReleaseConfig.required_files) -notcontains $requiredPath) {
      $manifestErrors.Add("config\\windows-release.seed.json must list required build file '$requiredPath'")
    }
  }
}

$operatorFixturePath = Join-Path $root "config\\operator-api.fixture.json"
if (Test-Path -LiteralPath $operatorFixturePath -PathType Leaf) {
  $operatorFixture = Get-Content -Raw -LiteralPath $operatorFixturePath | ConvertFrom-Json

  if ($operatorFixture.variant -ne "operator") {
    $manifestErrors.Add("config\\operator-api.fixture.json must declare variant operator")
  }

  $localhostFixturePrefix = "http" + "://127.0.0.1:"
  if (-not $operatorFixture.base_url.StartsWith($localhostFixturePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    $manifestErrors.Add("config\\operator-api.fixture.json must use a localhost fixture base_url")
  }

  foreach ($endpointName in @("start_trial", "route_policy", "managed_profile", "apps", "cabinet_token", "support_tickets")) {
    if (-not $operatorFixture.endpoints.$endpointName) {
      $manifestErrors.Add("config\\operator-api.fixture.json must define endpoint '$endpointName'")
    }
  }

  if ($operatorFixture.endpoints.start_trial.path -ne "/api/client/session/start-trial") {
    $manifestErrors.Add("config\\operator-api.fixture.json must keep start_trial on /api/client/session/start-trial")
  }

  if ($operatorFixture.endpoints.managed_profile.response.materialized_for_runtime -ne $true) {
    $manifestErrors.Add("config\\operator-api.fixture.json managed_profile must be materialized_for_runtime")
  }

  $serializedOperatorFixture = $operatorFixture | ConvertTo-Json -Depth 50
  $forbiddenServiceHosts = @(
    "api" + ".pokrov.space",
    "app" + ".pokrov.space",
    "pay" + ".pokrov.space",
    "connect" + ".pokrov.space",
    "kiwunaka" + ".space"
  )
  foreach ($value in $forbiddenServiceHosts) {
    if ($serializedOperatorFixture.Contains($value)) {
      $manifestErrors.Add("config\\operator-api.fixture.json must not contain official POKROV or legacy service endpoints")
    }
  }
}

$freeVpnCatalogPath = Join-Path $root "config\\free-vpn-catalog.seed.json"
if (Test-Path -LiteralPath $freeVpnCatalogPath -PathType Leaf) {
  $freeVpnCatalog = Get-Content -Raw -LiteralPath $freeVpnCatalogPath | ConvertFrom-Json

  if ($freeVpnCatalog.enabled_by_default -ne $false) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must stay disabled by default")
  }

  if ($freeVpnCatalog.requires_user_opt_in -ne $true) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must require user opt-in")
  }

  if ($freeVpnCatalog.official_pokrov_nodes -ne $false) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must not mark third-party entries as official POKROV nodes")
  }

  if ($freeVpnCatalog.refresh_policy.clear_action_required -ne $true) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must require a clear action for cached public configs")
  }

  if ($freeVpnCatalog.parser_contract.version -ne "subscription-text-v1") {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must keep parser_contract.version subscription-text-v1")
  }

  foreach ($protocol in @("vless", "trojan", "ss", "vmess")) {
    if (@($freeVpnCatalog.parser_contract.supported_protocols) -notcontains $protocol) {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json must support parser protocol '$protocol'")
    }
  }

  if (@($freeVpnCatalog.sources).Count -lt 1) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must contain at least one reviewed source candidate")
  } else {
    $source = @($freeVpnCatalog.sources)[0]
    if ($source.license -ne "GPL-3.0") {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must keep GPL-3.0 license metadata")
    }
    if ([string]::IsNullOrWhiteSpace($source.attribution)) {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must include attribution")
    }
    if ($source.review_status -ne "reviewed_candidate_disabled") {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must remain reviewed_candidate_disabled")
    }
  }
}

$dependencyInventoryPath = Join-Path $root "config\\dependency-license-inventory.seed.json"
if (Test-Path -LiteralPath $dependencyInventoryPath -PathType Leaf) {
  $dependencyInventory = Get-Content -Raw -LiteralPath $dependencyInventoryPath | ConvertFrom-Json

  if ($dependencyInventory.policy.fail_on_missing_package_review -ne $true) {
    $manifestErrors.Add("config\\dependency-license-inventory.seed.json must fail on missing package review")
  }

  if (@($dependencyInventory.packages).Count -lt 1) {
    $manifestErrors.Add("config\\dependency-license-inventory.seed.json must contain reviewed packages")
  }

  $reviewRequiredPackages = @($dependencyInventory.packages | Where-Object { $_.review -eq "REVIEW_REQUIRED" -or [string]::IsNullOrWhiteSpace($_.review) })
  if ($reviewRequiredPackages.Count -gt 0) {
    $manifestErrors.Add("config\\dependency-license-inventory.seed.json must not contain REVIEW_REQUIRED or empty package reviews")
  }

  foreach ($packageName in @("mobile_scanner", "zxing2", "camera_windows", "pokrov_app_shell")) {
    $packageEntry = @($dependencyInventory.packages | Where-Object { $_.name -eq $packageName })
    if ($packageEntry.Count -ne 1) {
      $manifestErrors.Add("config\\dependency-license-inventory.seed.json must include reviewed package '$packageName'")
    }
  }
}

$generatedAssetsPath = Join-Path $root "config\\generated-assets.seed.json"
if (Test-Path -LiteralPath $generatedAssetsPath -PathType Leaf) {
  $generatedAssets = Get-Content -Raw -LiteralPath $generatedAssetsPath | ConvertFrom-Json

  if ($generatedAssets.policy.all_png_assets_must_be_listed -ne $true) {
    $manifestErrors.Add("config\\generated-assets.seed.json must require all PNG assets to be listed")
  }

  foreach ($assetPath in @(
      "assets/brand/pokrov-oss-hero.png",
      "assets/brand/oss-status-card.png",
      "assets/branding/pokrov-mark.png",
      "assets/diagrams/open-source-boundary.png"
    )) {
    $assetEntry = @($generatedAssets.assets | Where-Object { $_.path -eq $assetPath })
    if ($assetEntry.Count -ne 1) {
      $manifestErrors.Add("config\\generated-assets.seed.json must include '$assetPath'")
    }
  }

  $officialBrandAsset = @($generatedAssets.assets | Where-Object { $_.path -eq "assets/branding/pokrov-mark.png" }) | Select-Object -First 1
  if ($officialBrandAsset) {
    if ($officialBrandAsset.official_brand_asset -ne $true) {
      $manifestErrors.Add("config\\generated-assets.seed.json must mark assets/branding/pokrov-mark.png as an official brand asset")
    }
    if ($officialBrandAsset.fork_reuse_allowed -ne $false) {
      $manifestErrors.Add("config\\generated-assets.seed.json must forbid fork reuse of assets/branding/pokrov-mark.png")
    }
    if ($officialBrandAsset.reuse -notmatch "BRAND\.md") {
      $manifestErrors.Add("config\\generated-assets.seed.json must bind official brand asset reuse to BRAND.md")
    }
  }
}

$whiteLabelSeedPath = Join-Path $root "config\\white-label-color-tokens.seed.json"
if (Test-Path -LiteralPath $whiteLabelSeedPath -PathType Leaf) {
  $whiteLabelSeed = Get-Content -Raw -LiteralPath $whiteLabelSeedPath | ConvertFrom-Json

  if ($whiteLabelSeed.variant -ne "operator") {
    $manifestErrors.Add("config\\white-label-color-tokens.seed.json must declare variant operator")
  }

  if ($whiteLabelSeed.policy.operator_owned_branding -ne $true) {
    $manifestErrors.Add("config\\white-label-color-tokens.seed.json must require operator-owned branding")
  }

  if ($whiteLabelSeed.policy.official_pokrov_brand_allowed -ne $false) {
    $manifestErrors.Add("config\\white-label-color-tokens.seed.json must forbid official POKROV branding")
  }

  if ($whiteLabelSeed.policy.official_endpoint_allowed -ne $false) {
    $manifestErrors.Add("config\\white-label-color-tokens.seed.json must forbid official POKROV endpoints")
  }

  foreach ($role in @("canvas", "canvasAlt", "ink", "accent", "accentBright", "success", "warning", "surface", "surfaceMuted", "line", "muted")) {
    if (-not $whiteLabelSeed.roles.$role) {
      $manifestErrors.Add("config\\white-label-color-tokens.seed.json must define role '$role'")
    }
  }
}

$whiteLabelSchemaPath = Join-Path $root "config\\white-label-color-tokens.schema.json"
if (Test-Path -LiteralPath $whiteLabelSchemaPath -PathType Leaf) {
  $whiteLabelSchema = Get-Content -Raw -LiteralPath $whiteLabelSchemaPath | ConvertFrom-Json

  if ($whiteLabelSchema.title -ne "White-label color token export") {
    $manifestErrors.Add("config\\white-label-color-tokens.schema.json must keep the white-label token title")
  }

  foreach ($requiredKey in @("schema", "variant", "policy", "export", "roles")) {
    if (@($whiteLabelSchema.required) -notcontains $requiredKey) {
      $manifestErrors.Add("config\\white-label-color-tokens.schema.json must require '$requiredKey'")
    }
  }
}

$operatorOpenApiPath = Join-Path $root "docs\\operator\\openapi.yaml"
if (Test-Path -LiteralPath $operatorOpenApiPath -PathType Leaf) {
  $operatorOpenApi = Get-Content -Raw -LiteralPath $operatorOpenApiPath
  foreach ($requiredPath in @("/api/client/session/start-trial", "/api/client/route-policy", "/api/client/profile/managed", "/api/client/apps", "/api/client/support/tickets")) {
    if ($operatorOpenApi -notmatch [System.Text.RegularExpressions.Regex]::Escape($requiredPath)) {
      $manifestErrors.Add("docs\\operator\\openapi.yaml must document '$requiredPath'")
    }
  }
}

$communityVariantPath = Join-Path $root "config\\variants\\community-client.seed.json"
if (Test-Path -LiteralPath $communityVariantPath -PathType Leaf) {
  $communityVariant = Get-Content -Raw -LiteralPath $communityVariantPath | ConvertFrom-Json

  if ($communityVariant.variant -ne "community") {
    $manifestErrors.Add("config\\variants\\community-client.seed.json must declare variant community")
  }

  if ($communityVariant.service_model.uses_managed_service_api -ne $false) {
    $manifestErrors.Add("config\\variants\\community-client.seed.json must keep managed service API disabled")
  }

  if ($communityVariant.brand_policy.uses_pokrov_logo -ne $false) {
    $manifestErrors.Add("config\\variants\\community-client.seed.json must not use the POKROV logo")
  }

  if ($communityVariant.build_defines.OPEN_CLIENT_ANDROID_PACKAGE_NAME -ne "org.pokrovclient.community") {
    $manifestErrors.Add("config\\variants\\community-client.seed.json must keep OPEN_CLIENT_ANDROID_PACKAGE_NAME as org.pokrovclient.community")
  }

  foreach ($value in @($communityVariant.display_name, $communityVariant.build_defines.OPEN_CLIENT_BRAND_NAME, $communityVariant.build_defines.OPEN_CLIENT_BRAND_ASSET)) {
    if (Test-PokrovBrand $value) {
      $manifestErrors.Add("config\\variants\\community-client.seed.json must keep neutral community branding")
    }
  }

  foreach ($value in @(
      $communityVariant.build_defines.OPEN_CLIENT_API_BASE_URL,
      $communityVariant.build_defines.OPEN_CLIENT_CABINET_URL,
      $communityVariant.build_defines.OPEN_CLIENT_CHECKOUT_URL,
      $communityVariant.build_defines.OPEN_CLIENT_SUPPORT_URL,
      $communityVariant.build_defines.OPEN_CLIENT_PRIVACY_URL
    )) {
    if (Test-PokrovEndpoint $value) {
      $manifestErrors.Add("config\\variants\\community-client.seed.json must not contain official POKROV endpoints")
    }
  }
}

$operatorVariantPath = Join-Path $root "config\\variants\\operator-client.seed.json"
if (Test-Path -LiteralPath $operatorVariantPath -PathType Leaf) {
  $operatorVariant = Get-Content -Raw -LiteralPath $operatorVariantPath | ConvertFrom-Json

  if ($operatorVariant.variant -ne "operator") {
    $manifestErrors.Add("config\\variants\\operator-client.seed.json must declare variant operator")
  }

  if ($operatorVariant.service_model.uses_managed_service_api -ne $true) {
    $manifestErrors.Add("config\\variants\\operator-client.seed.json must declare managed service API usage")
  }

  foreach ($value in @($operatorVariant.display_name, $operatorVariant.build_defines.OPEN_CLIENT_BRAND_NAME, $operatorVariant.build_defines.OPEN_CLIENT_BRAND_ASSET)) {
    if (Test-PokrovBrand $value) {
      $manifestErrors.Add("config\\variants\\operator-client.seed.json must keep operator branding neutral by default")
    }
  }

  if ([string]::IsNullOrWhiteSpace($operatorVariant.build_defines.OPEN_CLIENT_API_BASE_URL)) {
    $manifestErrors.Add("config\\variants\\operator-client.seed.json must define OPEN_CLIENT_API_BASE_URL")
  }

  if ([string]::IsNullOrWhiteSpace($operatorVariant.build_defines.OPEN_CLIENT_PRIVACY_URL)) {
    $manifestErrors.Add("config\\variants\\operator-client.seed.json must define OPEN_CLIENT_PRIVACY_URL")
  }

  if ([string]::IsNullOrWhiteSpace($operatorVariant.build_defines.OPEN_CLIENT_ANDROID_PACKAGE_NAME)) {
    $manifestErrors.Add("config\\variants\\operator-client.seed.json must define OPEN_CLIENT_ANDROID_PACKAGE_NAME")
  }

  if (Test-PokrovBrand $operatorVariant.build_defines.OPEN_CLIENT_ANDROID_PACKAGE_NAME) {
    $manifestErrors.Add("config\\variants\\operator-client.seed.json must not use official POKROV Android package names by default")
  }

  foreach ($value in @(
      $operatorVariant.build_defines.OPEN_CLIENT_API_BASE_URL,
      $operatorVariant.build_defines.OPEN_CLIENT_CABINET_URL,
      $operatorVariant.build_defines.OPEN_CLIENT_CHECKOUT_URL,
      $operatorVariant.build_defines.OPEN_CLIENT_SUPPORT_URL,
      $operatorVariant.build_defines.OPEN_CLIENT_PRIVACY_URL
    )) {
    if (Test-PokrovEndpoint $value) {
      $manifestErrors.Add("config\\variants\\operator-client.seed.json must not contain official POKROV endpoints")
    }
  }
}

$pokrovVariantPath = Join-Path $root "config\\variants\\pokrov-service.seed.json"
if (Test-Path -LiteralPath $pokrovVariantPath -PathType Leaf) {
  $pokrovVariant = Get-Content -Raw -LiteralPath $pokrovVariantPath | ConvertFrom-Json

  if ($pokrovVariant.variant -ne "pokrov") {
    $manifestErrors.Add("config\\variants\\pokrov-service.seed.json must declare variant pokrov")
  }

  if ($pokrovVariant.brand_policy.official_build_only -ne $true) {
    $manifestErrors.Add("config\\variants\\pokrov-service.seed.json must remain official-build-only")
  }

  if ($pokrovVariant.build_defines.OPEN_CLIENT_OFFICIAL_BUILD -ne "true") {
    $manifestErrors.Add("config\\variants\\pokrov-service.seed.json must set OPEN_CLIENT_OFFICIAL_BUILD true")
  }

  if ([string]::IsNullOrWhiteSpace($pokrovVariant.build_defines.OPEN_CLIENT_ANDROID_PACKAGE_NAME)) {
    $manifestErrors.Add("config\\variants\\pokrov-service.seed.json must define OPEN_CLIENT_ANDROID_PACKAGE_NAME")
  }

  foreach ($value in @($pokrovVariant.display_name, $pokrovVariant.build_defines.OPEN_CLIENT_BRAND_NAME, $pokrovVariant.build_defines.OPEN_CLIENT_BRAND_ASSET)) {
    if (-not (Test-PokrovBrand $value)) {
      $manifestErrors.Add("config\\variants\\pokrov-service.seed.json must keep official POKROV branding")
    }
  }

  foreach ($value in @(
      $pokrovVariant.build_defines.OPEN_CLIENT_API_BASE_URL,
      $pokrovVariant.build_defines.OPEN_CLIENT_CABINET_URL,
      $pokrovVariant.build_defines.OPEN_CLIENT_CHECKOUT_URL,
      $pokrovVariant.build_defines.OPEN_CLIENT_SUPPORT_URL,
      $pokrovVariant.build_defines.OPEN_CLIENT_PRIVACY_URL
    )) {
    if (-not (Test-PokrovEndpoint $value)) {
      $manifestErrors.Add("config\\variants\\pokrov-service.seed.json must keep official POKROV endpoints")
    }
  }
}

$programSeed = Join-Path $root "program.seed.yaml"

if (Test-Path -LiteralPath $programSeed -PathType Leaf) {
  $seedText = Get-Content -Raw -LiteralPath $programSeed
  $seedLines = $seedText -split "\r?\n" | ForEach-Object { $_.Trim() }

  if ($seedText -notmatch "config/product-contract.seed.json") {
    $manifestErrors.Add("program.seed.yaml must reference config/product-contract.seed.json")
  }

  if ($seedText -notmatch "validation_script: scripts/validate-seed.ps1") {
    $manifestErrors.Add("program.seed.yaml must reference scripts/validate-seed.ps1")
  }

  if ($seedText -notmatch "bootstrap_script: scripts/bootstrap-local.ps1") {
    $manifestErrors.Add("program.seed.yaml must reference scripts/bootstrap-local.ps1")
  }

  if ($seedText -notmatch "workspace_bootstrap_script: scripts/bootstrap-workspace.ps1") {
    $manifestErrors.Add("program.seed.yaml must reference scripts/bootstrap-workspace.ps1")
  }

  if ($seedText -notmatch "test_script: scripts/run-tests.ps1") {
    $manifestErrors.Add("program.seed.yaml must reference scripts/run-tests.ps1")
  }

  foreach ($target in $expectedPublicTargets) {
    if ($seedLines -notcontains "- $target") {
      $manifestErrors.Add("program.seed.yaml must list public target '$target'")
    }
  }

  foreach ($target in $expectedReadinessOnlyTargets) {
    if ($seedLines -notcontains "- $target") {
      $manifestErrors.Add("program.seed.yaml must list readiness-only target '$target'")
    }
  }

  if ($seedText -notmatch "path: apps/ios_shell") {
    $manifestErrors.Add("program.seed.yaml must track apps/ios_shell")
  }

  if ($seedText -notmatch "path: apps/macos_shell") {
    $manifestErrors.Add("program.seed.yaml must track apps/macos_shell")
  }
}

if ($missing.Count -gt 0 -or $invalidJson.Count -gt 0 -or $manifestErrors.Count -gt 0) {
  Write-Host "Seed scaffold check failed." -ForegroundColor Red

  $missing | ForEach-Object { Write-Host $_ }
  $invalidJson | ForEach-Object { Write-Host "JSON $_" }
  $manifestErrors | ForEach-Object { Write-Host $_ }

  exit 1
}

Write-Host "Seed scaffold OK:" -ForegroundColor Green
Write-Host $root
exit 0
