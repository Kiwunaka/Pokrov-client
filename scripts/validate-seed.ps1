$root = Split-Path -Parent $PSScriptRoot

$requiredDirectories = @(
  ".github",
  ".github\\ISSUE_TEMPLATE",
  ".github\\workflows",
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
  "tools",
  "tools\\variant_build",
  "test"
)

$requiredFiles = @(
  "README.md",
  "CHANGELOG.md",
  ".gitignore",
  ".editorconfig",
  "melos.yaml",
  "program.seed.yaml",
  ".github\\CODEOWNERS",
  ".github\\dependabot.yml",
  "config\\product-contract.seed.json",
  "config\\platform-matrix.seed.json",
  "config\\runtime-profile.seed.json",
  "config\\runtime-artifacts.seed.json",
  "config\\windows-release.seed.json",
  "config\\operator-api.fixture.json",
  "config\\free-vpn-catalog.seed.json",
  "config\\security-intake.seed.json",
  "config\\changelog-policy.seed.json",
  "config\\codeowners-review.seed.json",
  "config\\contributor-doctor.seed.json",
  "config\\dependabot-policy.seed.json",
  "config\\dependency-license-inventory.seed.json",
  "config\\generated-assets.seed.json",
  "config\\source-release-readiness.seed.json",
  "config\\white-label-color-tokens.seed.json",
  "config\\white-label-color-tokens.schema.json",
  "config\\variants\\community-client.seed.json",
  "config\\variants\\operator-client.seed.json",
  "config\\variants\\pokrov-service.seed.json",
  "config\\templates\\local.env.example",
  "config\\templates\\device-overrides.seed.json",
  "docs\\README.md",
  "docs\\OPEN_SOURCE_SCOPE.md",
  "docs\\TROUBLESHOOTING.md",
  "docs\\PRODUCT_VARIANTS.md",
  "docs\\OPERATOR_INTEGRATION.md",
  "docs\\FREE_VPN_CATALOG_GATE.md",
  "docs\\WHITE_LABEL_BRANDING.md",
  "docs\\BUILD_FROM_SOURCE.md",
  "docs\\DEPENDENCY_LICENSE_AUDIT.md",
  "docs\\DEPENDENCY_UPDATE_POLICY.md",
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
  "scripts\\check-source-release-copy.ps1",
  "scripts\\prepare-oss-import.ps1",
  "scripts\\prepare-source-release.ps1",
  "scripts\\render-source-release-notes.ps1",
  "scripts\\print-build-variant-command.ps1",
  "scripts\\run-operator-fixture-smoke.ps1",
  "scripts\\run-tests.ps1",
  "scripts\\validate-seed.ps1",
  "scripts\\doctor.ps1",
  "scripts\\export-white-label-color-tokens.ps1",
  "tools\\variant_build\\__init__.py",
  "tools\\variant_build\\variant_command.py",
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
  "config\\security-intake.seed.json",
  "config\\changelog-policy.seed.json",
  "config\\codeowners-review.seed.json",
  "config\\contributor-doctor.seed.json",
  "config\\dependabot-policy.seed.json",
  "config\\dependency-license-inventory.seed.json",
  "config\\generated-assets.seed.json",
  "config\\source-release-readiness.seed.json",
  "config\\white-label-color-tokens.seed.json",
  "config\\white-label-color-tokens.schema.json",
  "config\\variants\\community-client.seed.json",
  "config\\variants\\operator-client.seed.json",
  "config\\variants\\pokrov-service.seed.json",
  "config\\templates\\device-overrides.seed.json"
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

  if ($runtimeArtifacts.libcore.license_review -notin @("pending", "approved")) {
    $manifestErrors.Add("config\\runtime-artifacts.seed.json must record libcore.license_review as pending or approved")
  }

  if ($runtimeArtifacts.libcore.binary_review -notin @("pending", "approved")) {
    $manifestErrors.Add("config\\runtime-artifacts.seed.json must record libcore.binary_review as pending or approved")
  }

  if ($runtimeArtifacts.libcore.source_release_scope -notmatch "not committed") {
    $manifestErrors.Add("config\\runtime-artifacts.seed.json must state runtime artifacts are not committed for source-only releases")
  }

  foreach ($target in @("android", "ios", "macos", "windows")) {
    $assetMetadata = $runtimeArtifacts.libcore.assets.$target
    if (-not $assetMetadata) {
      $manifestErrors.Add("config\\runtime-artifacts.seed.json must define libcore asset metadata for $target")
      continue
    }

    if ($assetMetadata.sha256 -ne "PENDING_PUBLIC_BINARY_REVIEW" -and $assetMetadata.sha256 -notmatch "^[a-f0-9]{64}$") {
      $manifestErrors.Add("config\\runtime-artifacts.seed.json $target asset must use PENDING_PUBLIC_BINARY_REVIEW or a lowercase 64-hex sha256")
    }

    if ($assetMetadata.license_review -notin @("pending", "approved")) {
      $manifestErrors.Add("config\\runtime-artifacts.seed.json $target asset must record license_review as pending or approved")
    }

    if ($assetMetadata.binary_review -notin @("pending", "approved")) {
      $manifestErrors.Add("config\\runtime-artifacts.seed.json $target asset must record binary_review as pending or approved")
    }

    if ($assetMetadata.sync_destination -match "(^|/|\\)\.\.($|/|\\)") {
      $manifestErrors.Add("config\\runtime-artifacts.seed.json $target sync_destination must stay repo-relative")
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

  if ($operatorFixture.endpoints.support_tickets.path -ne "/api/tickets") {
    $manifestErrors.Add("config\\operator-api.fixture.json must keep support_tickets on /api/tickets to match the app adapter")
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

  if ($freeVpnCatalog.manual_import_build_define -ne "OPEN_CLIENT_ENABLE_FREE_CATALOG") {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must bind manual import to OPEN_CLIENT_ENABLE_FREE_CATALOG")
  }

  if ($freeVpnCatalog.manual_import_default -ne $false) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must keep manual import disabled by default")
  }

  if ($freeVpnCatalog.requires_user_opt_in -ne $true) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must require user opt-in")
  }

  if ($freeVpnCatalog.official_pokrov_nodes -ne $false) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must not mark third-party entries as official POKROV nodes")
  }

  if ($freeVpnCatalog.provenance_policy.network_fetch_in_ci -ne $false) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must keep network_fetch_in_ci false")
  }

  if ($freeVpnCatalog.provenance_policy.runtime_fetch_default -ne $false) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must keep runtime_fetch_default false")
  }

  if (@($freeVpnCatalog.provenance_policy.allowed_feed_hosts) -notcontains "github.com") {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must allow only reviewed public feed hosts")
  }

  if ($freeVpnCatalog.provenance_policy.forbid_official_pokrov_hosts -ne $true) {
    $manifestErrors.Add("config\\free-vpn-catalog.seed.json must forbid official POKROV hosts in catalog feeds")
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
    if ($source.attribution_required -ne $true) {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must require attribution")
    }
    if ([string]::IsNullOrWhiteSpace($source.license_url)) {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must include a license_url")
    }
    if (@($source.observed_evidence).Count -lt 1) {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must include observed evidence notes")
    }
    if ($source.review_status -ne "reviewed_candidate_disabled") {
      $manifestErrors.Add("config\\free-vpn-catalog.seed.json first source must remain reviewed_candidate_disabled")
    }

    $allowedCatalogHosts = @($freeVpnCatalog.provenance_policy.allowed_feed_hosts)
    foreach ($feed in @($source.feeds)) {
      try {
        $feedUri = [System.Uri]::new($feed.url)
      } catch {
        $manifestErrors.Add("config\\free-vpn-catalog.seed.json feed '$($feed.id)' must use a valid URL")
        continue
      }

      if ($feedUri.Scheme -ne "https") {
        $manifestErrors.Add("config\\free-vpn-catalog.seed.json feed '$($feed.id)' must use https")
      }
      if ($allowedCatalogHosts -notcontains $feedUri.Host) {
        $manifestErrors.Add("config\\free-vpn-catalog.seed.json feed '$($feed.id)' must stay on reviewed allowed hosts")
      }
      if (Test-PokrovEndpoint $feed.url -or $feedUri.Host -eq "kiwunaka.space") {
        $manifestErrors.Add("config\\free-vpn-catalog.seed.json feed '$($feed.id)' must not point to official POKROV or legacy hosts")
      }
    }
  }
}

$changelogPolicyPath = Join-Path $root "config\\changelog-policy.seed.json"
if (Test-Path -LiteralPath $changelogPolicyPath -PathType Leaf) {
  $changelogPolicy = Get-Content -Raw -LiteralPath $changelogPolicyPath | ConvertFrom-Json

  if ($changelogPolicy.changelog_path -ne "CHANGELOG.md") {
    $manifestErrors.Add("config\\changelog-policy.seed.json must point to CHANGELOG.md")
  }

  if ($changelogPolicy.policy.keep_unreleased_section -ne $true) {
    $manifestErrors.Add("config\\changelog-policy.seed.json must keep the Unreleased section")
  }

  if ($changelogPolicy.policy.track_source_readiness_milestones -ne $true) {
    $manifestErrors.Add("config\\changelog-policy.seed.json must track source readiness milestones")
  }

  if ($changelogPolicy.policy.pending_prs_must_not_be_presented_as_tags -ne $true) {
    $manifestErrors.Add("config\\changelog-policy.seed.json must forbid presenting pending PRs as tags")
  }

  if ($changelogPolicy.policy.source_only_boundary_required -ne $true) {
    $manifestErrors.Add("config\\changelog-policy.seed.json must require source-only boundary copy")
  }

  if ($changelogPolicy.source_readiness_inventory -ne "config/source-release-readiness.seed.json") {
    $manifestErrors.Add("config\\changelog-policy.seed.json must point to config/source-release-readiness.seed.json")
  }

  $changelogPath = Join-Path $root "CHANGELOG.md"
  if (Test-Path -LiteralPath $changelogPath -PathType Leaf) {
    $changelogText = Get-Content -Raw -LiteralPath $changelogPath

    foreach ($section in @($changelogPolicy.required_sections)) {
      if ($changelogText.IndexOf($section, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("CHANGELOG.md must include section '$section'")
      }
    }

    foreach ($phrase in @($changelogPolicy.required_source_only_phrases)) {
      if ($changelogText.IndexOf($phrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("CHANGELOG.md must include source-only phrase '$phrase'")
      }
    }

    foreach ($claim in @($changelogPolicy.forbidden_unreleased_claims)) {
      if ($changelogText.IndexOf($claim, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("CHANGELOG.md must not include unsupported claim '$claim'")
      }
    }

    $changelogReadinessPath = Join-Path $root "config\\source-release-readiness.seed.json"
    if (Test-Path -LiteralPath $changelogReadinessPath -PathType Leaf) {
      $changelogReadiness = Get-Content -Raw -LiteralPath $changelogReadinessPath | ConvertFrom-Json
      foreach ($milestone in @($changelogReadiness.milestones)) {
        if ($changelogText.IndexOf($milestone.tag, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("CHANGELOG.md must mention source readiness milestone '$($milestone.tag)'")
        }

        if ($milestone.status -eq "stacked_pr_green_not_tagged") {
          $expectedStatus = "$($milestone.tag)`` | Pending stacked PR, not tagged"
          if ($changelogText.IndexOf($expectedStatus, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $manifestErrors.Add("CHANGELOG.md must list '$($milestone.tag)' as Pending stacked PR, not tagged")
          }
        } elseif ($milestone.status -eq "not_tagged") {
          $expectedStatus = "$($milestone.tag)`` | Not tagged"
          if ($changelogText.IndexOf($expectedStatus, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $manifestErrors.Add("CHANGELOG.md must list '$($milestone.tag)' as Not tagged")
          }
        }
      }
    }
  }
}

$contributorDoctorPath = Join-Path $root "config\\contributor-doctor.seed.json"
if (Test-Path -LiteralPath $contributorDoctorPath -PathType Leaf) {
  $contributorDoctor = Get-Content -Raw -LiteralPath $contributorDoctorPath | ConvertFrom-Json

  if ($contributorDoctor.script -ne "scripts/doctor.ps1") {
    $manifestErrors.Add("config\\contributor-doctor.seed.json must point to scripts/doctor.ps1")
  }

  foreach ($field in @("read_only_by_default", "no_dependency_install", "no_build_or_release_artifacts", "no_network_required", "json_output_supported", "command_checks_can_be_skipped", "ci_smoke_uses_skip_command_checks")) {
    if ($contributorDoctor.policy.$field -ne $true) {
      $manifestErrors.Add("config\\contributor-doctor.seed.json policy.$field must remain true")
    }
  }

  if ($contributorDoctor.troubleshooting_doc -ne "docs/TROUBLESHOOTING.md") {
    $manifestErrors.Add("config\\contributor-doctor.seed.json must point to docs/TROUBLESHOOTING.md")
  }

  if ($contributorDoctor.ci_smoke.workflow -ne ".github/workflows/ci.yml") {
    $manifestErrors.Add("config\\contributor-doctor.seed.json ci_smoke.workflow must point to .github/workflows/ci.yml")
  }

  if ($contributorDoctor.ci_smoke.command -notmatch "doctor\.ps1" -or $contributorDoctor.ci_smoke.command -notmatch "SkipCommandChecks") {
    $manifestErrors.Add("config\\contributor-doctor.seed.json ci_smoke.command must run doctor.ps1 with -SkipCommandChecks")
  }

  foreach ($commandName in @("git", "python", "flutter", "dart")) {
    if (@($contributorDoctor.required_commands) -notcontains $commandName) {
      $manifestErrors.Add("config\\contributor-doctor.seed.json must require command '$commandName'")
    }
  }

  foreach ($publicFile in @($contributorDoctor.required_public_files)) {
    $relativeFile = $publicFile.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath (Join-Path $root $relativeFile) -PathType Leaf)) {
      $manifestErrors.Add("config\\contributor-doctor.seed.json required public file '$publicFile' must exist")
    }
  }

  $doctorScriptPath = Join-Path $root "scripts\\doctor.ps1"
  if (Test-Path -LiteralPath $doctorScriptPath -PathType Leaf) {
    $doctorScriptText = Get-Content -Raw -LiteralPath $doctorScriptPath
    foreach ($requiredPhrase in @("-SkipCommandChecks", "-Json", "Contributor doctor OK.", "read_only")) {
      if ($doctorScriptText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\doctor.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("flutter pub get", "flutter build", "Copy-Item", "New-Item")) {
      if ($doctorScriptText.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\doctor.ps1 must stay read-only and not include '$forbiddenPhrase'")
      }
    }
  }

  $doctorDocsText = ""
  foreach ($docPath in @($contributorDoctor.required_docs)) {
    $relativeDocPath = $docPath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    $fullDocPath = Join-Path $root $relativeDocPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $doctorDocsText += "`n" + (Get-Content -Raw -LiteralPath $fullDocPath)
    }
  }

  $doctorDocsMentionScript = $false
  foreach ($needle in @("scripts\doctor.ps1", "scripts/doctor.ps1")) {
    if ($doctorDocsText.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
      $doctorDocsMentionScript = $true
    }
  }
  if (-not $doctorDocsMentionScript) {
    $manifestErrors.Add("Contributor docs must mention scripts\\doctor.ps1")
  }
  if ($doctorDocsText.IndexOf("read-only", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
    $manifestErrors.Add("Contributor docs must state that scripts\\doctor.ps1 is read-only")
  }

  $workflowPath = Join-Path $root ".github\\workflows\\ci.yml"
  if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflowText = Get-Content -Raw -LiteralPath $workflowPath
    foreach ($requiredPhrase in @("Run contributor doctor source-boundary smoke", "doctor.ps1 -SkipCommandChecks")) {
      if ($workflowText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\workflows\\ci.yml must include contributor doctor source-boundary smoke")
      }
    }
  }

  $troubleshootingPath = Join-Path $root "docs\\TROUBLESHOOTING.md"
  if (Test-Path -LiteralPath $troubleshootingPath -PathType Leaf) {
    $troubleshootingText = Get-Content -Raw -LiteralPath $troubleshootingPath
    $troubleshootingMentionsDoctor = $false
    foreach ($needle in @("scripts\doctor.ps1", "scripts/doctor.ps1")) {
      if ($troubleshootingText.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $troubleshootingMentionsDoctor = $true
      }
    }
    if (-not $troubleshootingMentionsDoctor) {
      $manifestErrors.Add("docs\\TROUBLESHOOTING.md must mention scripts\\doctor.ps1")
    }
    foreach ($requiredPhrase in @("-Json", "redacted", "Android", "Windows", "source-only", "does not install", "does not install dependencies", "runtime binaries")) {
      if ($troubleshootingText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("docs\\TROUBLESHOOTING.md must include '$requiredPhrase'")
      }
    }
  }
}

$codeownersReviewPath = Join-Path $root "config\\codeowners-review.seed.json"
if (Test-Path -LiteralPath $codeownersReviewPath -PathType Leaf) {
  $codeownersReview = Get-Content -Raw -LiteralPath $codeownersReviewPath | ConvertFrom-Json

  if ($codeownersReview.codeowners_path -ne ".github/CODEOWNERS") {
    $manifestErrors.Add("config\\codeowners-review.seed.json must point to .github/CODEOWNERS")
  }

  foreach ($field in @("maintainer_led_until_broader_governance", "default_owner_required", "security_and_release_routes_required", "android_and_windows_routes_required", "operator_contract_routes_required", "source_only_boundary_routes_required")) {
    if ($codeownersReview.policy.$field -ne $true) {
      $manifestErrors.Add("config\\codeowners-review.seed.json policy.$field must remain true")
    }
  }

  if (@($codeownersReview.allowed_owners) -notcontains "@Kiwunaka") {
    $manifestErrors.Add("config\\codeowners-review.seed.json must keep @Kiwunaka as an allowed owner")
  }

  $codeownersPath = Join-Path $root ".github\\CODEOWNERS"
  if (Test-Path -LiteralPath $codeownersPath -PathType Leaf) {
    $codeownersText = Get-Content -Raw -LiteralPath $codeownersPath
    $codeownersLines = $codeownersText -split "\r?\n" |
      ForEach-Object { $_.Trim() } |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith("#") }

    foreach ($route in @($codeownersReview.required_routes)) {
      $expectedLine = "$($route.pattern) $($route.owner)"
      if ($codeownersLines -notcontains $expectedLine) {
        $manifestErrors.Add(".github\\CODEOWNERS must include route '$expectedLine'")
      }
    }

    foreach ($line in $codeownersLines) {
      $parts = $line -split "\s+"
      foreach ($owner in @($parts | Select-Object -Skip 1)) {
        if (@($codeownersReview.allowed_owners) -notcontains $owner) {
          $manifestErrors.Add(".github\\CODEOWNERS owner '$owner' is not listed in config\\codeowners-review.seed.json")
        }
      }
    }

    foreach ($requiredPhrase in @("Source-only public review routing", "security intake", "runtime artifacts", "operator contracts")) {
      if ($codeownersText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\CODEOWNERS must document '$requiredPhrase'")
      }
    }
  }

  foreach ($docPath in @($codeownersReview.docs)) {
    $relativeDocPath = $docPath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    $fullDocPath = Join-Path $root $relativeDocPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("CODEOWNERS", "config/codeowners-review.seed.json", "maintainer-led")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase' for CODEOWNERS review routing")
        }
      }
    }
  }
}

$dependabotPolicyPath = Join-Path $root "config\\dependabot-policy.seed.json"
if (Test-Path -LiteralPath $dependabotPolicyPath -PathType Leaf) {
  $dependabotPolicy = Get-Content -Raw -LiteralPath $dependabotPolicyPath | ConvertFrom-Json

  if ($dependabotPolicy.dependabot_path -ne ".github/dependabot.yml") {
    $manifestErrors.Add("config\\dependabot-policy.seed.json must point to .github/dependabot.yml")
  }

  foreach ($field in @("github_actions_updates_required", "pub_workspace_updates_required", "weekly_schedule_required", "bounded_open_prs_required", "dependency_label_required", "human_review_required_before_merge", "source_only_release_boundaries_apply", "runtime_binary_review_remains_separate")) {
    if ($dependabotPolicy.policy.$field -ne $true) {
      $manifestErrors.Add("config\\dependabot-policy.seed.json policy.$field must remain true")
    }
  }

  foreach ($ecosystem in @("github-actions", "pub")) {
    if (@($dependabotPolicy.required_ecosystems) -notcontains $ecosystem) {
      $manifestErrors.Add("config\\dependabot-policy.seed.json must require ecosystem '$ecosystem'")
    }
  }

  $dependabotPath = Join-Path $root ".github\\dependabot.yml"
  if (Test-Path -LiteralPath $dependabotPath -PathType Leaf) {
    $dependabotText = Get-Content -Raw -LiteralPath $dependabotPath

    foreach ($ecosystem in @($dependabotPolicy.required_ecosystems)) {
      if ($dependabotText.IndexOf("package-ecosystem: `"$ecosystem`"", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\dependabot.yml must include ecosystem '$ecosystem'")
      }
    }

    foreach ($directory in @($dependabotPolicy.required_pub_directories)) {
      if ($dependabotText.IndexOf("directory: `"$directory`"", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\dependabot.yml must include pub directory '$directory'")
      }
    }

    foreach ($requiredPhrase in @("interval: `"weekly`"", "open-pull-requests-limit:", "labels:", "dependencies", "commit-message:", "include: `"scope`"")) {
      if ($dependabotText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\dependabot.yml must include '$requiredPhrase'")
      }
    }
  }

  $labelsPath = Join-Path $root ".github\\labels.yml"
  if (Test-Path -LiteralPath $labelsPath -PathType Leaf) {
    $labelsText = Get-Content -Raw -LiteralPath $labelsPath
    foreach ($label in @($dependabotPolicy.required_labels)) {
      if ($labelsText.IndexOf("- name: $label", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\labels.yml must define dependency update label '$label'")
      }
    }
  }

  foreach ($docPath in @($dependabotPolicy.docs)) {
    $relativeDocPath = $docPath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    $fullDocPath = Join-Path $root $relativeDocPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("Dependabot", "dependencies", "source-only", "license", "runtime binaries")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase' for dependency update policy")
        }
      }
    }
  }
}

$securityIntakePath = Join-Path $root "config\\security-intake.seed.json"
if (Test-Path -LiteralPath $securityIntakePath -PathType Leaf) {
  $securityIntake = Get-Content -Raw -LiteralPath $securityIntakePath | ConvertFrom-Json

  if ($securityIntake.policy.public_vulnerability_issues_allowed -ne $false) {
    $manifestErrors.Add("config\\security-intake.seed.json must forbid public vulnerability issues")
  }

  if ($securityIntake.policy.blank_issues_enabled -ne $false) {
    $manifestErrors.Add("config\\security-intake.seed.json must keep blank issues disabled")
  }

  if ($securityIntake.policy.private_security_policy_url -ne "https://github.com/Kiwunaka/Pokrov-client/security/policy") {
    $manifestErrors.Add("config\\security-intake.seed.json must point to GitHub private vulnerability reporting")
  }

  if ($securityIntake.policy.telegram_support_url -ne "https://t.me/pokrov_supportbot") {
    $manifestErrors.Add("config\\security-intake.seed.json must keep the public Telegram support fallback")
  }

  if ($securityIntake.policy.security_redirect_label -ne "security-private") {
    $manifestErrors.Add("config\\security-intake.seed.json must use the security-private redirect label")
  }

  foreach ($requiredPath in @("github-private-vulnerability-reporting", "telegram-support")) {
    $pathEntry = @($securityIntake.private_reporting_paths | Where-Object { $_.id -eq $requiredPath })
    if ($pathEntry.Count -ne 1) {
      $manifestErrors.Add("config\\security-intake.seed.json must define private reporting path '$requiredPath'")
    }
  }

  foreach ($forbidden in @("secrets", "account tokens", "QR payloads", "subscription URLs", "private backend details", "exploit steps", "signing material")) {
    if (@($securityIntake.forbidden_public_content) -notcontains $forbidden) {
      $manifestErrors.Add("config\\security-intake.seed.json must forbid public '$forbidden'")
    }
  }

  foreach ($scope in @("public client source code", "public source release process", "operator fixture and OpenAPI contracts", "Android and Windows host source")) {
    if (@($securityIntake.supported_scope) -notcontains $scope) {
      $manifestErrors.Add("config\\security-intake.seed.json must include supported scope '$scope'")
    }
  }

  foreach ($outOfScope in @("official backend, billing, admin, infrastructure, and private service operations", "private operator backends and customer accounts")) {
    if (@($securityIntake.out_of_scope) -notcontains $outOfScope) {
      $manifestErrors.Add("config\\security-intake.seed.json must keep out-of-scope boundary '$outOfScope'")
    }
  }

  foreach ($field in @("ships_apk", "ships_exe", "store_release", "trusted_signing_claim", "official_binary_claim")) {
    if ($securityIntake.release_claim_boundary.$field -ne $false) {
      $manifestErrors.Add("config\\security-intake.seed.json release_claim_boundary.$field must remain false")
    }
  }

  if ($securityIntake.release_claim_boundary.source_only_repository -ne $true) {
    $manifestErrors.Add("config\\security-intake.seed.json must keep source_only_repository true")
  }

  if ($securityIntake.release_claim_boundary.require_public_evidence_for_binary_claims -ne $true) {
    $manifestErrors.Add("config\\security-intake.seed.json must require public evidence before binary claims")
  }

  $issueConfigPath = Join-Path $root ".github\\ISSUE_TEMPLATE\\config.yml"
  if (Test-Path -LiteralPath $issueConfigPath -PathType Leaf) {
    $issueConfig = Get-Content -Raw -LiteralPath $issueConfigPath
    if ($issueConfig -notmatch "blank_issues_enabled:\s*false") {
      $manifestErrors.Add(".github\\ISSUE_TEMPLATE\\config.yml must keep blank issues disabled")
    }
    if ($issueConfig -notmatch [System.Text.RegularExpressions.Regex]::Escape($securityIntake.policy.private_security_policy_url)) {
      $manifestErrors.Add(".github\\ISSUE_TEMPLATE\\config.yml must link to private vulnerability reporting")
    }
  }

  $securityRedirectPath = Join-Path $root ".github\\ISSUE_TEMPLATE\\security_redirect.yml"
  if (Test-Path -LiteralPath $securityRedirectPath -PathType Leaf) {
    $securityRedirect = Get-Content -Raw -LiteralPath $securityRedirectPath
    foreach ($requiredPhrase in @("Do not open a public issue for vulnerabilities", "GitHub private vulnerability reporting", "security-private", "QR payloads", "subscription URLs", "signing material", "private backend details")) {
      if ($securityRedirect -notmatch [System.Text.RegularExpressions.Regex]::Escape($requiredPhrase)) {
        $manifestErrors.Add(".github\\ISSUE_TEMPLATE\\security_redirect.yml must include '$requiredPhrase'")
      }
    }
  }

  $labelsPath = Join-Path $root ".github\\labels.yml"
  if (Test-Path -LiteralPath $labelsPath -PathType Leaf) {
    $labelsText = Get-Content -Raw -LiteralPath $labelsPath
    if (-not $labelsText.Contains("- name: security-private")) {
      $manifestErrors.Add(".github\\labels.yml must define the security-private label")
    }
  }

  foreach ($docPath in @("SECURITY.md", "SUPPORT.md", "docs\\GITHUB_TRIAGE.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("secrets", "QR payloads", "subscription URLs", "private backend")) {
        if ($docText -notmatch [System.Text.RegularExpressions.Regex]::Escape($requiredPhrase)) {
          $manifestErrors.Add("$docPath must mention '$requiredPhrase' for public security intake redaction")
        }
      }
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

$sourceReadinessPath = Join-Path $root "config\\source-release-readiness.seed.json"
if (Test-Path -LiteralPath $sourceReadinessPath -PathType Leaf) {
  $sourceReadiness = Get-Content -Raw -LiteralPath $sourceReadinessPath | ConvertFrom-Json

  if ($sourceReadiness.policy.source_only_milestones_must_not_claim_binaries -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must enforce source-only binary claim boundaries")
  }

  foreach ($milestone in @($sourceReadiness.milestones)) {
    if ($milestone.source_only -ne $true) {
      $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$($milestone.tag)' must be source_only")
    }
    foreach ($field in @("ships_apk", "ships_exe", "store_release", "trusted_signing_claim")) {
      if ($milestone.$field -ne $false) {
        $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$($milestone.tag)' must keep $field false")
      }
    }
    if ($milestone.status -ne "tagged" -and $milestone.status -notmatch "not_tagged") {
      $manifestErrors.Add("config\\source-release-readiness.seed.json pending milestone '$($milestone.tag)' must include not_tagged in status")
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
  foreach ($requiredPath in @("/api/client/session/start-trial", "/api/client/route-policy", "/api/client/profile/managed", "/api/client/apps", "/api/tickets")) {
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
