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
  "docs\\device-validation",
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
  "config\\github-ruleset.seed.json",
  "config\\android-device-validation.seed.json",
  "config\\release-evidence-bundle.seed.json",
  "config\\source-release-publication-dry-run.seed.json",
  "config\\source-tag-readiness.seed.json",
  "config\\release-merge-order.seed.json",
  "config\\release-stack-github-status.seed.json",
  "config\\release-merge-handoff.seed.json",
  "config\\source-publication-packet.seed.json",
  "config\\required-checks.seed.json",
  "config\\runtime-profile.seed.json",
  "config\\runtime-artifacts.seed.json",
  "config\\windows-release.seed.json",
  "config\\windows-bundle-verifier.seed.json",
  "config\\operator-api.fixture.json",
  "config\\enterprise-boundary.seed.json",
  "config\\free-vpn-catalog.seed.json",
  "config\\security-intake.seed.json",
  "config\\changelog-policy.seed.json",
  "config\\codeowners-review.seed.json",
  "config\\contributor-doctor.seed.json",
  "config\\dependabot-policy.seed.json",
  "config\\dependency-license-inventory.seed.json",
  "config\\generated-assets.seed.json",
  "config\\diagnostics-export-policy.seed.json",
  "config\\release-blocker-inventory.seed.json",
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
  "docs\\ENTERPRISE.md",
  "docs\\FREE_VPN_CATALOG_GATE.md",
  "docs\\WHITE_LABEL_BRANDING.md",
  "docs\\BUILD_FROM_SOURCE.md",
  "docs\\device-validation\\android.md",
  "docs\\DEPENDENCY_LICENSE_AUDIT.md",
  "docs\\DEPENDENCY_UPDATE_POLICY.md",
  "docs\\GITHUB_RULESET_SETUP.md",
  "docs\\DIAGNOSTICS_EXPORT_POLICY.md",
  "docs\\RELEASE_BLOCKERS.md",
  "docs\\RELEASE_CHECKLIST.md",
  "docs\\REQUIRED_CHECKS.md",
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
  "scripts\\android-device-smoke.ps1",
  "scripts\\bootstrap-local.ps1",
  "scripts\\check-github-ruleset.ps1",
  "scripts\\fetch-libcore-assets.ps1",
  "scripts\\check-source-release-copy.ps1",
  "scripts\\prepare-oss-import.ps1",
  "scripts\\prepare-release-evidence-bundle.ps1",
  "scripts\\validate-source-release-publication.ps1",
  "scripts\\check-source-tag-readiness.ps1",
  "scripts\\check-release-merge-order.ps1",
  "scripts\\check-release-stack-github-status.ps1",
  "scripts\\prepare-release-merge-handoff.ps1",
  "scripts\\prepare-source-publication-packet.ps1",
  "scripts\\verify-windows-bundle.ps1",
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
  "config\\github-ruleset.seed.json",
  "config\\android-device-validation.seed.json",
  "config\\release-evidence-bundle.seed.json",
  "config\\source-release-publication-dry-run.seed.json",
  "config\\source-tag-readiness.seed.json",
  "config\\release-merge-order.seed.json",
  "config\\release-stack-github-status.seed.json",
  "config\\release-merge-handoff.seed.json",
  "config\\source-publication-packet.seed.json",
  "config\\required-checks.seed.json",
  "config\\runtime-profile.seed.json",
  "config\\runtime-artifacts.seed.json",
  "config\\windows-release.seed.json",
  "config\\windows-bundle-verifier.seed.json",
  "config\\operator-api.fixture.json",
  "config\\enterprise-boundary.seed.json",
  "config\\free-vpn-catalog.seed.json",
  "config\\security-intake.seed.json",
  "config\\changelog-policy.seed.json",
  "config\\codeowners-review.seed.json",
  "config\\contributor-doctor.seed.json",
  "config\\dependabot-policy.seed.json",
  "config\\dependency-license-inventory.seed.json",
  "config\\generated-assets.seed.json",
  "config\\diagnostics-export-policy.seed.json",
  "config\\release-blocker-inventory.seed.json",
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

$windowsBundleVerifierPath = Join-Path $root "config\\windows-bundle-verifier.seed.json"
if (Test-Path -LiteralPath $windowsBundleVerifierPath -PathType Leaf) {
  $windowsBundleVerifier = Get-Content -Raw -LiteralPath $windowsBundleVerifierPath | ConvertFrom-Json

  if ($windowsBundleVerifier.script -ne "scripts/verify-windows-bundle.ps1") {
    $manifestErrors.Add("config\\windows-bundle-verifier.seed.json must point to scripts/verify-windows-bundle.ps1")
  }

  if ($windowsBundleVerifier.default_output_dir -ne "build/windows-bundle-verifier") {
    $manifestErrors.Add("config\\windows-bundle-verifier.seed.json must write under build/windows-bundle-verifier")
  }

  foreach ($field in @("read_only", "source_only", "no_flutter_build", "no_runtime_download", "no_signing", "no_packaging", "no_publish", "forbid_committed_windows_binaries")) {
    if ($windowsBundleVerifier.policy.$field -ne $true) {
      $manifestErrors.Add("config\\windows-bundle-verifier.seed.json policy.$field must be true")
    }
  }

  foreach ($requiredPath in @("apps/windows_shell/pubspec.yaml", "apps/windows_shell/lib/main.dart", "apps/windows_shell/windows/CMakeLists.txt", "apps/windows_shell/windows/runner/runner.exe.manifest", "config/windows-release.seed.json")) {
    if (@($windowsBundleVerifier.required_paths) -notcontains $requiredPath) {
      $manifestErrors.Add("config\\windows-bundle-verifier.seed.json must require '$requiredPath'")
    }
  }

  foreach ($extension in @(".dll", ".exe", ".msi", ".msix", ".pfx", ".p12", ".pem", ".key", ".cer", ".crt", ".zip")) {
    if (@($windowsBundleVerifier.forbidden_committed_extensions) -notcontains $extension) {
      $manifestErrors.Add("config\\windows-bundle-verifier.seed.json must forbid committed '$extension' files")
    }
  }

  foreach ($field in @("ships_exe", "store_release", "trusted_signing_claim", "runtime_binary_ready", "official_binary_claim")) {
    if ($windowsBundleVerifier.release_claim_boundary.$field -ne $false) {
      $manifestErrors.Add("config\\windows-bundle-verifier.seed.json release_claim_boundary.$field must remain false")
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

$enterpriseBoundaryPath = Join-Path $root "config\\enterprise-boundary.seed.json"
if (Test-Path -LiteralPath $enterpriseBoundaryPath -PathType Leaf) {
  $enterpriseBoundary = Get-Content -Raw -LiteralPath $enterpriseBoundaryPath | ConvertFrom-Json

  if ($enterpriseBoundary.doc -ne "docs/ENTERPRISE.md") {
    $manifestErrors.Add("config\\enterprise-boundary.seed.json must point to docs/ENTERPRISE.md")
  }

  if ($enterpriseBoundary.current_public_license -ne "GPL-3.0-only") {
    $manifestErrors.Add("config\\enterprise-boundary.seed.json must keep current_public_license GPL-3.0-only")
  }

  foreach ($field in @("does_not_change_license", "not_legal_advice", "operator_brings_own_backend", "operator_owns_distribution_claims", "no_private_pokrov_access_included", "no_commercial_license_offered_by_default", "dual_license_requires_owner_decision", "official_branding_forbidden_for_forks", "gpl_source_obligations_not_waived")) {
    if ($enterpriseBoundary.policy.$field -ne $true) {
      $manifestErrors.Add("config\\enterprise-boundary.seed.json policy.$field must remain true")
    }
  }

  foreach ($responsibility in @("backend and managed profile API", "billing, checkout, refunds, and abuse handling", "support and privacy policy", "signing identities and store or direct-download release channels", "checksums, release notes, source-compliance process, and user claims")) {
    if (@($enterpriseBoundary.operator_responsibilities) -notcontains $responsibility) {
      $manifestErrors.Add("config\\enterprise-boundary.seed.json must keep operator responsibility '$responsibility'")
    }
  }

  foreach ($forbiddenClaim in @("commercial license is available by default", "operator builds are official POKROV builds", "GPLv3 obligations are waived", "private POKROV backend access is included", "trusted signing, store release, or production readiness is included")) {
    if (@($enterpriseBoundary.forbidden_claims) -notcontains $forbiddenClaim) {
      $manifestErrors.Add("config\\enterprise-boundary.seed.json must forbid claim '$forbiddenClaim'")
    }
  }

  $enterpriseDocPath = Join-Path $root "docs\\ENTERPRISE.md"
  if (Test-Path -LiteralPath $enterpriseDocPath -PathType Leaf) {
    $enterpriseDoc = Get-Content -Raw -LiteralPath $enterpriseDocPath
    foreach ($requiredPhrase in @("This is not legal advice", "does not change [LICENSE](../LICENSE)", "does not waive GPLv3 obligations", "does not offer a commercial license by default", "Operator builds are not official POKROV builds", "No dual license is offered by default", "source-compliance path")) {
      if ($enterpriseDoc.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("docs\\ENTERPRISE.md must include '$requiredPhrase'")
      }
    }
  }

  foreach ($docPath in @("README.md", "README.en.md", "README.ru.md", "docs\\README.md", "docs\\OPERATOR_INTEGRATION.md", "docs\\OPEN_SOURCE_SCOPE.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("docs/ENTERPRISE.md", "Enterprise boundary", "commercial license")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase' for enterprise boundary")
        }
      }
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

$requiredChecksPath = Join-Path $root "config\\required-checks.seed.json"
if (Test-Path -LiteralPath $requiredChecksPath -PathType Leaf) {
  $requiredChecks = Get-Content -Raw -LiteralPath $requiredChecksPath | ConvertFrom-Json

  if ($requiredChecks.workflow -ne ".github/workflows/ci.yml") {
    $manifestErrors.Add("config\\required-checks.seed.json must point to .github/workflows/ci.yml")
  }

  foreach ($field in @("pull_request_ci_required", "main_push_ci_required", "contents_read_permission_required", "source_release_preflight_smoke_required", "clean_clone_source_boundary_required", "flutter_analyze_required", "workspace_tests_required", "branch_protection_documented_not_claimed", "skip_test_commands_forbidden_for_public_release")) {
    if ($requiredChecks.policy.$field -ne $true) {
      $manifestErrors.Add("config\\required-checks.seed.json policy.$field must remain true")
    }
  }

  $workflowPath = Join-Path $root ".github\\workflows\\ci.yml"
  if (Test-Path -LiteralPath $workflowPath -PathType Leaf) {
    $workflowText = Get-Content -Raw -LiteralPath $workflowPath

    foreach ($requiredPhrase in @("pull_request:", "branches:", "- main", "permissions:", "contents: read")) {
      if ($workflowText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\workflows\\ci.yml must include '$requiredPhrase' for required checks policy")
      }
    }

    foreach ($jobName in @($requiredChecks.required_jobs)) {
      if ($workflowText.IndexOf("name: $jobName", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\workflows\\ci.yml must include required job '$jobName'")
      }
    }

    foreach ($stepName in @($requiredChecks.required_steps)) {
      if ($workflowText.IndexOf("name: $stepName", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add(".github\\workflows\\ci.yml must include required step '$stepName'")
      }
    }
  }

  foreach ($docPath in @($requiredChecks.docs)) {
    $relativeDocPath = $docPath.Replace("/", [System.IO.Path]::DirectorySeparatorChar)
    $fullDocPath = Join-Path $root $relativeDocPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("Required checks", "Source import and public tree checks", "Flutter analyze and tests", "Android native Gradle unit tests", "-SkipTestCommands", "source-only")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase' for required checks policy")
        }
      }
    }
  }
}

$githubRulesetPath = Join-Path $root "config\\github-ruleset.seed.json"
if (Test-Path -LiteralPath $githubRulesetPath -PathType Leaf) {
  $githubRuleset = Get-Content -Raw -LiteralPath $githubRulesetPath | ConvertFrom-Json

  if ($githubRuleset.mode -ne "setup_guidance_not_remote_enforcement") {
    $manifestErrors.Add("config\\github-ruleset.seed.json must stay setup guidance, not a remote enforcement claim")
  }

  if ($githubRuleset.docs -ne "docs/GITHUB_RULESET_SETUP.md") {
    $manifestErrors.Add("config\\github-ruleset.seed.json must point to docs/GITHUB_RULESET_SETUP.md")
  }

  if ($githubRuleset.verifier_script -ne "scripts/check-github-ruleset.ps1") {
    $manifestErrors.Add("config\\github-ruleset.seed.json must point to scripts/check-github-ruleset.ps1")
  }

  if (@($githubRuleset.target_branches) -notcontains "main") {
    $manifestErrors.Add("config\\github-ruleset.seed.json must target main")
  }

  foreach ($field in @("repository_ruleset_preferred", "branch_protection_fallback_supported", "remote_enforcement_not_claimed", "pull_request_required", "required_status_checks_required", "codeowners_review_required", "conversation_resolution_required", "block_force_pushes_required", "block_branch_deletion_required", "bypass_must_be_explicit_and_minimal", "verifier_is_read_only", "verifier_report_only_supported", "verifier_not_required_in_ci_until_remote_settings_exist", "verifier_reports_checked_at", "verifier_reports_covered_required_status_checks")) {
    if ($githubRuleset.policy.$field -ne $true) {
      $manifestErrors.Add("config\\github-ruleset.seed.json policy.$field must remain true")
    }
  }

  if (Test-Path -LiteralPath $requiredChecksPath -PathType Leaf) {
    $requiredChecks = Get-Content -Raw -LiteralPath $requiredChecksPath | ConvertFrom-Json
    if ((@($githubRuleset.required_status_checks) -join "|") -ne (@($requiredChecks.required_jobs) -join "|")) {
      $manifestErrors.Add("config\\github-ruleset.seed.json required_status_checks must match config\\required-checks.seed.json required_jobs")
    }
  }

  foreach ($requiredVerification in @("GitHub repository ruleset or branch protection is active for main", "Required status checks exactly match config/required-checks.seed.json", "CODEOWNERS review is required for matching paths", "Conversations must be resolved before merge", "Force pushes and branch deletion are blocked for protected targets", "A test pull request without required checks cannot be merged")) {
    if (@($githubRuleset.manual_verification_required) -notcontains $requiredVerification) {
      $manifestErrors.Add("config\\github-ruleset.seed.json must require manual verification '$requiredVerification'")
    }
  }

  foreach ($forbiddenClaim in @("remote branch protection is enforced", "repository rulesets are active", "all maintainers are blocked from bypass", "GitHub settings prove binary release readiness", "GitHub settings prove trusted signing or store readiness")) {
    if (@($githubRuleset.forbidden_claims_until_observed) -notcontains $forbiddenClaim) {
      $manifestErrors.Add("config\\github-ruleset.seed.json must forbid claim '$forbiddenClaim' until observed")
    }
  }

  $githubRulesetDocPath = Join-Path $root "docs\\GITHUB_RULESET_SETUP.md"
  if (Test-Path -LiteralPath $githubRulesetDocPath -PathType Leaf) {
    $githubRulesetDoc = Get-Content -Raw -LiteralPath $githubRulesetDocPath
    foreach ($requiredPhrase in @("not proof that remote GitHub settings are already active", "scripts/check-github-ruleset.ps1", "Source import and public tree checks", "Flutter analyze and tests", "Android native Gradle unit tests", "CODEOWNERS review", "conversation resolution", "blocked force pushes", "blocked branch deletion", "a test pull request without required checks cannot be merged", "do not prove APK, EXE, store release, trusted signing")) {
      if ($githubRulesetDoc.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("docs\\GITHUB_RULESET_SETUP.md must include '$requiredPhrase'")
      }
    }
  }

  $githubRulesetScriptPath = Join-Path $root "scripts\\check-github-ruleset.ps1"
  if (Test-Path -LiteralPath $githubRulesetScriptPath -PathType Leaf) {
    $githubRulesetScript = Get-Content -Raw -LiteralPath $githubRulesetScriptPath
    foreach ($requiredPhrase in @("gh api", "-ReportOnly", "read_only", "checked_at", "required_status_checks", "covered_required_status_checks", "coveredRequiredChecks", "branch_protection", "ruleset")) {
      if ($githubRulesetScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\check-github-ruleset.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("-X POST", "-X PATCH", "-X PUT", "-X DELETE", "gh repo edit", "gh ruleset", "Invoke-RestMethod -Method Post", "Invoke-RestMethod -Method Patch", "Invoke-RestMethod -Method Put", "Invoke-RestMethod -Method Delete")) {
      if ($githubRulesetScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\check-github-ruleset.ps1 must stay read-only and not include '$forbiddenPhrase'")
      }
    }
  }
}

$androidDeviceValidationPath = Join-Path $root "config\android-device-validation.seed.json"
if (Test-Path -LiteralPath $androidDeviceValidationPath -PathType Leaf) {
  $androidDeviceValidation = Get-Content -Raw -LiteralPath $androidDeviceValidationPath | ConvertFrom-Json
  if ($androidDeviceValidation.script -ne "scripts/android-device-smoke.ps1") {
    $manifestErrors.Add("config\android-device-validation.seed.json must point to scripts/android-device-smoke.ps1")
  }
  if ($androidDeviceValidation.checklist_doc -ne "docs/device-validation/android.md") {
    $manifestErrors.Add("config\android-device-validation.seed.json must point to docs/device-validation/android.md")
  }
  if ($androidDeviceValidation.default_output_dir -ne "build/android-device-validation") {
    $manifestErrors.Add("config\android-device-validation.seed.json must keep default output under ignored build/android-device-validation")
  }
  foreach ($field in @("read_only", "no_device_mutation_by_default", "physical_device_result_is_manual_owner_test", "does_not_claim_store_or_trusted_signing", "does_not_replace_release_build_audit")) {
    if ($androidDeviceValidation.policy.$field -ne $true) {
      $manifestErrors.Add("config\android-device-validation.seed.json policy.$field must remain true")
    }
  }
  foreach ($requiredCheck in @("vpn_permission_flow", "foreground_service_special_use", "notification_disconnect", "system_vpn_revoke", "wifi_full_tunnel", "mobile_network_full_tunnel", "airplane_mode_recovery", "reconnect_loop", "subscription_refresh_failure_preserves_profile", "dns_no_desktop_loopback", "route_materialization", "false_connected_guard")) {
    if ($androidDeviceValidation.manual_checks -notcontains $requiredCheck) {
      $manifestErrors.Add("config\android-device-validation.seed.json must include manual check '$requiredCheck'")
    }
  }
  foreach ($field in @("store_ready", "trusted_signing", "production_ready", "official_binary_proof")) {
    if ($androidDeviceValidation.release_claims.$field -ne $false) {
      $manifestErrors.Add("config\android-device-validation.seed.json release_claims.$field must remain false")
    }
  }

  $androidDeviceScriptPath = Join-Path $root "scripts\android-device-smoke.ps1"
  if (Test-Path -LiteralPath $androidDeviceScriptPath -PathType Leaf) {
    $androidDeviceScript = Get-Content -Raw -LiteralPath $androidDeviceScriptPath
    foreach ($requiredPhrase in @("android-device-validation.seed.json", "MANUAL_OWNER_TEST", "android.permission.BIND_VPN_SERVICE", "FOREGROUND_SERVICE_TYPE_SPECIAL_USE", "notification disconnect", "build/android-device-validation")) {
      if ($androidDeviceScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\android-device-smoke.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("adb install", "adb uninstall", "adb shell", "Start-Process adb", "gradlew assembleRelease", "flutter build apk", "gh release", "git push", "gh api")) {
      if ($androidDeviceScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\android-device-smoke.ps1 must remain a read-only local precheck and must not include '$forbiddenPhrase'")
      }
    }
  }

  $androidDeviceDocPath = Join-Path $root "docs\device-validation\android.md"
  if (Test-Path -LiteralPath $androidDeviceDocPath -PathType Leaf) {
    $androidDeviceDoc = Get-Content -Raw -LiteralPath $androidDeviceDocPath
    foreach ($requiredPhrase in @("MANUAL_OWNER_TEST", "scripts\android-device-smoke.ps1", "VpnService permission", "Android 14 specialUse foreground service", "notification disconnect", "system VPN settings", "does not prove store readiness", "does not prove trusted signing", "does not replace the release-build audit")) {
      if ($androidDeviceDoc.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("docs\device-validation\android.md must include '$requiredPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\README.md", "apps\android_shell\README.md", "scripts\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("android-device-smoke.ps1", "Android device validation", "MANUAL_OWNER_TEST")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase' for Android device validation")
        }
      }
    }
  }
}

$releaseEvidencePath = Join-Path $root "config\\release-evidence-bundle.seed.json"
if (Test-Path -LiteralPath $releaseEvidencePath -PathType Leaf) {
  $releaseEvidence = Get-Content -Raw -LiteralPath $releaseEvidencePath | ConvertFrom-Json

  if ($releaseEvidence.script -ne "scripts/prepare-release-evidence-bundle.ps1") {
    $manifestErrors.Add("config\\release-evidence-bundle.seed.json must point to scripts/prepare-release-evidence-bundle.ps1")
  }

  if ($releaseEvidence.default_output_dir -ne "build/release-evidence") {
    $manifestErrors.Add("config\\release-evidence-bundle.seed.json must keep default output under ignored build/release-evidence")
  }

  foreach ($field in @("source_only_boundary_required", "no_publish_side_effects", "writes_only_ignored_build_output", "ruleset_report_may_be_failing", "failing_ruleset_report_blocks_enforcement_claims", "does_not_replace_full_preflight", "windows_bundle_verifier_required", "requires_input_fingerprints", "requires_preflight_generated_at", "requires_preflight_generated_at_freshness", "requires_ruleset_report_input_fingerprint_when_present", "requires_ruleset_report_shape", "requires_ruleset_report_target", "requires_ruleset_report_ok_consistency", "requires_ruleset_report_checked_at", "requires_ruleset_report_freshness", "requires_ruleset_report_check_entry_shape", "requires_ruleset_report_required_status_checks", "requires_ruleset_report_covered_required_status_checks", "requires_preflight_artifact_fingerprints", "requires_preflight_artifact_fingerprint_integrity", "requires_preflight_commit_sha_consistency", "requires_preflight_ref_commit_sha_consistency")) {
    if ($releaseEvidence.policy.$field -ne $true) {
      $manifestErrors.Add("config\\release-evidence-bundle.seed.json policy.$field must remain true")
    }
  }

  foreach ($flag in @("source_only", "no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim", "windows_bundle_verifier_ok")) {
    if (@($releaseEvidence.required_summary_flags) -notcontains $flag) {
      $manifestErrors.Add("config\\release-evidence-bundle.seed.json must require summary flag '$flag'")
    }
  }

  $releaseEvidenceScriptPath = Join-Path $root "scripts\\prepare-release-evidence-bundle.ps1"
  if (Test-Path -LiteralPath $releaseEvidenceScriptPath -PathType Leaf) {
    $releaseEvidenceScript = Get-Content -Raw -LiteralPath $releaseEvidenceScriptPath
    foreach ($requiredPhrase in @("Assert-SourceOnlySummary", "Assert-InputGeneratedAt", "check-github-ruleset.ps1 -ReportOnly -Json", "github_enforcement_claim_allowed", "github_ruleset_report", "ships_apk = `$false", "ships_exe = `$false", "store_release = `$false", "trusted_signing_claim = `$false", "official_binary_claim = `$false", "windows_bundle_verifier_ok", "windows_bundle_verifier_summary", "input_fingerprints", "without generated_at timestamp", "without parseable generated_at timestamp", "stale `$InputName generated_at timestamp", "Assert-RulesetReportShape", "ruleset report without schema_version 1", "ruleset report that is not read-only", "ruleset report without ok status", "ruleset report without checked_at timestamp", "stale ruleset report checked_at timestamp", "ruleset report repository mismatch", "ruleset report branch mismatch", "ruleset report ok status without checks", "ruleset report ok status with failed checks", "ruleset report check entry shape mismatch", "ruleset report required status checks mismatch", "ruleset report covered required status checks mismatch", "preflight_artifact_fingerprints", "preflight_commit_sha", "preflight_ref_commit_sha", "preflight commit SHA does not match current HEAD", "preflight commit SHA does not match resolved ref commit SHA", "preflight summary is missing artifact fingerprints", "artifact fingerprint mismatch", "SHA256", "ComputeHash", "build\release-evidence")) {
      if ($releaseEvidenceScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\prepare-release-evidence-bundle.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("gh release create", "git push", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($releaseEvidenceScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\prepare-release-evidence-bundle.ps1 must not publish or mutate remote state with '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\RELEASE_CHECKLIST.md", "docs\\RELEASE_POLICY.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("prepare-release-evidence-bundle.ps1", "release evidence bundle")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
        }
      }
    }
  }
}

$publicationDryRunPath = Join-Path $root "config\\source-release-publication-dry-run.seed.json"
if (Test-Path -LiteralPath $publicationDryRunPath -PathType Leaf) {
  $publicationDryRun = Get-Content -Raw -LiteralPath $publicationDryRunPath | ConvertFrom-Json

  if ($publicationDryRun.script -ne "scripts/validate-source-release-publication.ps1") {
    $manifestErrors.Add("config\\source-release-publication-dry-run.seed.json must point to scripts/validate-source-release-publication.ps1")
  }

  if ($publicationDryRun.default_output_dir -ne "build/source-release-publication") {
    $manifestErrors.Add("config\\source-release-publication-dry-run.seed.json must keep default output under ignored build/source-release-publication")
  }

  foreach ($field in @("read_only", "dry_run_only", "no_github_release_publish", "no_tag_push", "writes_only_ignored_build_output", "requires_source_only_evidence_bundle", "requires_release_copy_check", "requires_input_fingerprints", "requires_evidence_bundle_generated_at", "requires_evidence_bundle_generated_at_freshness", "requires_evidence_bundle_input_fingerprints", "requires_evidence_bundle_preflight_input_fingerprint_integrity", "requires_evidence_bundle_ruleset_report_input_fingerprint_integrity", "requires_evidence_bundle_ruleset_report_shape", "requires_evidence_bundle_ruleset_report_target", "requires_evidence_bundle_ruleset_report_ok_consistency", "requires_evidence_bundle_ruleset_report_checked_at", "requires_evidence_bundle_ruleset_report_freshness", "requires_evidence_bundle_ruleset_report_check_entry_shape", "requires_evidence_bundle_ruleset_report_required_status_checks", "requires_evidence_bundle_ruleset_report_covered_required_status_checks", "requires_evidence_bundle_preflight_artifact_fingerprints", "github_enforcement_claim_requires_bundle_approval", "windows_bundle_verifier_claim_requires_bundle_proof", "requires_evidence_bundle_preflight_artifact_fingerprint_integrity", "requires_evidence_bundle_preflight_commit_sha_consistency", "requires_evidence_bundle_preflight_ref_commit_sha_consistency")) {
    if ($publicationDryRun.policy.$field -ne $true) {
      $manifestErrors.Add("config\\source-release-publication-dry-run.seed.json policy.$field must remain true")
    }
  }

  foreach ($flag in @("source_only", "no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim", "windows_bundle_verifier_ok")) {
    if (@($publicationDryRun.required_evidence_flags) -notcontains $flag) {
      $manifestErrors.Add("config\\source-release-publication-dry-run.seed.json must require evidence flag '$flag'")
    }
  }

  foreach ($phrase in @("Source archive SHA-256:", "Source proof manifest:", "Verification date:", "This is a source-only release")) {
    if (@($publicationDryRun.required_release_note_phrases) -notcontains $phrase) {
      $manifestErrors.Add("config\\source-release-publication-dry-run.seed.json must require release-note phrase '$phrase'")
    }
  }

  $publicationDryRunScriptPath = Join-Path $root "scripts\\validate-source-release-publication.ps1"
  if (Test-Path -LiteralPath $publicationDryRunScriptPath -PathType Leaf) {
    $publicationDryRunScript = Get-Content -Raw -LiteralPath $publicationDryRunScriptPath
    foreach ($requiredPhrase in @("check-source-release-copy.ps1", "Assert-InputGeneratedAt", "github_enforcement_claim_allowed", "publish_performed = `$false", "tag_push_performed = `$false", "dry_run_only = `$true", "windows_bundle_verifier_ok", "windows_bundle_verifier_summary", "input_fingerprints", "without generated_at timestamp", "without parseable generated_at timestamp", "stale `$InputName generated_at timestamp", "evidence_bundle_input_fingerprints", "Assert-InputFingerprintIntegrity", "Assert-RulesetReportInputFingerprintIntegrity", "github ruleset report fingerprint mismatch", "ruleset report without schema_version 1", "ruleset report that is not read-only", "ruleset report without ok status", "ruleset report without checked_at timestamp", "stale ruleset report checked_at timestamp", "ruleset report repository mismatch", "ruleset report branch mismatch", "ruleset report ok status without checks", "ruleset report ok status with failed checks", "ruleset report check entry shape mismatch", "ruleset report required status checks mismatch", "ruleset report covered required status checks mismatch", "evidence_bundle_preflight_artifact_fingerprints", "evidence_bundle_preflight_commit_sha", "evidence_bundle_preflight_ref_commit_sha", "evidence commit SHA does not match preflight commit SHA", "evidence preflight commit SHA does not match resolved ref commit SHA", "evidence bundle is missing input fingerprints", "evidence bundle preflight summary fingerprint mismatch", "evidence bundle is missing preflight artifact fingerprints", "artifact fingerprint mismatch", "SHA256", "ComputeHash", "build\source-release-publication")) {
      if ($publicationDryRunScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\validate-source-release-publication.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("gh release create", "gh release upload", "git push", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($publicationDryRunScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\validate-source-release-publication.ps1 must not publish or mutate remote state with '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\RELEASE_CHECKLIST.md", "docs\\RELEASE_POLICY.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("validate-source-release-publication.ps1", "publication dry-run")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
        }
      }
    }
  }
}

$sourceTagReadinessPath = Join-Path $root "config\\source-tag-readiness.seed.json"
if (Test-Path -LiteralPath $sourceTagReadinessPath -PathType Leaf) {
  $sourceTagReadiness = Get-Content -Raw -LiteralPath $sourceTagReadinessPath | ConvertFrom-Json

  if ($sourceTagReadiness.script -ne "scripts/check-source-tag-readiness.ps1") {
    $manifestErrors.Add("config\\source-tag-readiness.seed.json must point to scripts/check-source-tag-readiness.ps1")
  }

  if ($sourceTagReadiness.default_output_dir -ne "build/source-tag-readiness") {
    $manifestErrors.Add("config\\source-tag-readiness.seed.json must keep default output under ignored build/source-tag-readiness")
  }

  foreach ($field in @("read_only", "no_tag_creation", "no_git_push", "no_github_release_publish", "nonzero_when_blocked", "writes_only_ignored_build_output", "requires_blocker_inventory", "requires_source_readiness_milestone", "requires_latest_candidate_tag_match", "requires_latest_stacked_pr_evidence_match", "requires_blocker_inventory_source_only_flags", "requires_source_readiness_milestone_source_only_flags", "requires_error_summary", "requires_open_blocker_evidence_fields", "requires_ready_status_open_blocker_consistency", "requires_tag_creation_allowed_blocker_consistency", "requires_tag_creation_allowed_status_consistency", "requires_source_readiness_milestone_ready_status_allowlist", "requires_tag_creation_allowed_milestone_status_consistency", "requires_source_readiness_milestone_evidence", "requires_source_readiness_milestone_evidence_repo_boundary", "requires_source_readiness_milestone_status", "requires_source_readiness_milestone_scope", "requires_read_only_summary", "requires_input_fingerprints")) {
    if ($sourceTagReadiness.policy.$field -ne $true) {
      $manifestErrors.Add("config\\source-tag-readiness.seed.json policy.$field must remain true")
    }
  }

  if ($sourceTagReadiness.inputs.blocker_inventory -ne "config/release-blocker-inventory.seed.json") {
    $manifestErrors.Add("config\\source-tag-readiness.seed.json must read config/release-blocker-inventory.seed.json")
  }

  if ($sourceTagReadiness.inputs.source_readiness -ne "config/source-release-readiness.seed.json") {
    $manifestErrors.Add("config\\source-tag-readiness.seed.json must read config/source-release-readiness.seed.json")
  }

  $sourceTagReadinessScriptPath = Join-Path $root "scripts\\check-source-tag-readiness.ps1"
  if (Test-Path -LiteralPath $sourceTagReadinessScriptPath -PathType Leaf) {
    $sourceTagReadinessScript = Get-Content -Raw -LiteralPath $sourceTagReadinessScriptPath
    foreach ($requiredPhrase in @("release-blocker-inventory.seed.json", "source-release-readiness.seed.json", "latest_candidate", "latest_stacked_pr", "expected_milestone_evidence", "read_only = `$true", "input_fingerprints", "ComputeHash", "requested tag does not match latest blocker inventory candidate", "source readiness milestone evidence does not match latest stacked PR", "source readiness milestone evidence does not match expected repository PR URL", "source readiness milestone is missing evidence", "source readiness milestone is missing status", "source readiness milestone is missing scope", "release blocker inventory has unsafe source-only release flags", "source readiness milestone has unsafe source-only release flags", "release blocker inventory status is ready while required blockers remain open", "tag creation is allowed while required blockers remain open", "tag creation is allowed while release blocker inventory status is not ready", "tag creation is allowed while source readiness milestone is not tagged", "tag creation is allowed while source readiness milestone status is not ready", "open blocker is missing id", "blocker `$blockerId is missing required_before_tag=true", "open blocker `$blockerId is missing status", "open blocker `$blockerId is missing evidence", "error_count", "errors", "open_blocker_count", "required_before_tag", "evidence", "build\source-tag-readiness", "exit 2")) {
      if ($sourceTagReadinessScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\check-source-tag-readiness.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("git tag", "git push", "gh release create", "gh release upload", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($sourceTagReadinessScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\check-source-tag-readiness.ps1 must remain read-only and must not include '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\RELEASE_BLOCKERS.md", "docs\\RELEASE_CHECKLIST.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("check-source-tag-readiness.ps1", "source tag readiness")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
        }
      }
    }
  }
}

$releaseMergeOrderPath = Join-Path $root "config\\release-merge-order.seed.json"
if (Test-Path -LiteralPath $releaseMergeOrderPath -PathType Leaf) {
  $releaseMergeOrder = Get-Content -Raw -LiteralPath $releaseMergeOrderPath | ConvertFrom-Json

  if ($releaseMergeOrder.script -ne "scripts/check-release-merge-order.ps1") {
    $manifestErrors.Add("config\\release-merge-order.seed.json must point to scripts/check-release-merge-order.ps1")
  }

  if ($releaseMergeOrder.default_output_dir -ne "build/release-merge-order") {
    $manifestErrors.Add("config\\release-merge-order.seed.json must keep default output under ignored build/release-merge-order")
  }

  foreach ($field in @("read_only", "no_merge", "no_git_push", "no_github_api_mutation", "requires_linear_base_to_head_chain", "writes_only_ignored_build_output")) {
    if ($releaseMergeOrder.policy.$field -ne $true) {
      $manifestErrors.Add("config\\release-merge-order.seed.json policy.$field must remain true")
    }
  }

  $stack = @($releaseMergeOrder.stack)
  if ($stack.Count -lt 2) {
    $manifestErrors.Add("config\\release-merge-order.seed.json must contain at least two stacked PR entries")
  }
  if ($stack.Count -gt 0) {
    $releaseBlockerInventoryPath = Join-Path $root "config\\release-blocker-inventory.seed.json"
    if (Test-Path -LiteralPath $releaseBlockerInventoryPath -PathType Leaf) {
      $releaseBlockerInventory = Get-Content -Raw -LiteralPath $releaseBlockerInventoryPath | ConvertFrom-Json
      $latestCandidate = [string]$releaseBlockerInventory.tracked_candidates.latest_candidate
      $latestStackedPr = [int]$releaseBlockerInventory.tracked_candidates.latest_stacked_pr
      $latestStackEntry = $stack[-1]
      if ([string]$latestStackEntry.candidate -ne $latestCandidate) {
        $manifestErrors.Add("config\\release-merge-order.seed.json latest candidate must match release blocker inventory")
      }
      if ([int]$latestStackEntry.pr -ne $latestStackedPr) {
        $manifestErrors.Add("config\\release-merge-order.seed.json latest PR must match release blocker inventory")
      }
    }
  }
  for ($index = 1; $index -lt $stack.Count; $index += 1) {
    $previous = $stack[$index - 1]
    $current = $stack[$index]
    if ($current.base -ne $previous.head) {
      $manifestErrors.Add("config\\release-merge-order.seed.json PR #$($current.pr) base must equal PR #$($previous.pr) head")
    }
    if ([int]$current.pr -le [int]$previous.pr) {
      $manifestErrors.Add("config\\release-merge-order.seed.json PR numbers must increase")
    }
  }

  $releaseMergeOrderScriptPath = Join-Path $root "scripts\\check-release-merge-order.ps1"
  if (Test-Path -LiteralPath $releaseMergeOrderScriptPath -PathType Leaf) {
    $releaseMergeOrderScript = Get-Content -Raw -LiteralPath $releaseMergeOrderScriptPath
    foreach ($requiredPhrase in @("release-merge-order.seed.json", "merge_order_ok = `$true", "build\release-merge-order", "stack_count", "linear_base_to_head_chain")) {
      if ($releaseMergeOrderScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\check-release-merge-order.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("git merge", "git push", "gh pr merge", "gh api", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($releaseMergeOrderScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\check-release-merge-order.ps1 must remain read-only and must not include '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\RELEASE_BLOCKERS.md", "docs\\RELEASE_CHECKLIST.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("check-release-merge-order.ps1", "release merge order")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
        }
      }
    }
  }
}

$releaseStackGithubStatusPath = Join-Path $root "config\\release-stack-github-status.seed.json"
if (Test-Path -LiteralPath $releaseStackGithubStatusPath -PathType Leaf) {
  $releaseStackGithubStatus = Get-Content -Raw -LiteralPath $releaseStackGithubStatusPath | ConvertFrom-Json

  if ($releaseStackGithubStatus.script -ne "scripts/check-release-stack-github-status.ps1") {
    $manifestErrors.Add("config\\release-stack-github-status.seed.json must point to scripts/check-release-stack-github-status.ps1")
  }

  if ($releaseStackGithubStatus.default_output_dir -ne "build/release-stack-github-status") {
    $manifestErrors.Add("config\\release-stack-github-status.seed.json must keep default output under ignored build/release-stack-github-status")
  }

  if ($releaseStackGithubStatus.input_manifest -ne "config/release-merge-order.seed.json") {
    $manifestErrors.Add("config\\release-stack-github-status.seed.json must read config/release-merge-order.seed.json")
  }

  foreach ($field in @("read_only", "no_merge", "no_git_push", "no_github_api_mutation", "uses_pr_status_snapshot", "writes_only_ignored_build_output", "requires_clean_prs", "requires_ci_success", "requires_pull_request_urls", "requires_expected_repository_pr_urls", "requires_per_pr_status_check_evidence", "requires_per_pr_status_check_trace_evidence", "requires_required_checks_seed_match")) {
    if ($releaseStackGithubStatus.policy.$field -ne $true) {
      $manifestErrors.Add("config\\release-stack-github-status.seed.json policy.$field must remain true")
    }
  }
  if ($releaseStackGithubStatus.expected_pr_url_prefix -ne "https://github.com/Kiwunaka/Pokrov-client/pull/") {
    $manifestErrors.Add("config\\release-stack-github-status.seed.json expected_pr_url_prefix must stay on Kiwunaka/Pokrov-client PR URLs")
  }

  foreach ($requiredCheck in @("Source import and public tree checks", "Flutter analyze and tests", "Android native Gradle unit tests")) {
    if (@($releaseStackGithubStatus.required_status_checks) -notcontains $requiredCheck) {
      $manifestErrors.Add("config\\release-stack-github-status.seed.json must require '$requiredCheck'")
    }
  }
  $requiredChecksSeedPath = Join-Path $root "config\\required-checks.seed.json"
  if (Test-Path -LiteralPath $requiredChecksSeedPath -PathType Leaf) {
    $requiredChecksSeed = Get-Content -Raw -LiteralPath $requiredChecksSeedPath | ConvertFrom-Json
    if ((@($releaseStackGithubStatus.required_status_checks) -join "|") -ne (@($requiredChecksSeed.required_jobs) -join "|")) {
      $manifestErrors.Add("config\\release-stack-github-status.seed.json required_status_checks must exactly match config\\required-checks.seed.json required_jobs")
    }
  }

  $releaseStackGithubStatusScriptPath = Join-Path $root "scripts\\check-release-stack-github-status.ps1"
  if (Test-Path -LiteralPath $releaseStackGithubStatusScriptPath -PathType Leaf) {
    $releaseStackGithubStatusScript = Get-Content -Raw -LiteralPath $releaseStackGithubStatusScriptPath
    foreach ($requiredPhrase in @("release-stack-github-status.seed.json", "release-merge-order.seed.json", "gh pr list", "url", "latest_pr_url", "expected_pr_url_prefix", "pull request URL is missing", "pull request URL does not match expected repository", "successful_check_count", "failed_check_count", "required_status_check_count", "checks = @(`$prChecks)", "detailsUrl", "workflowName", "details_url", "workflow_name", "mergeStateStatus", "statusCheckRollup", "build\release-stack-github-status", "github_status_ok = `$true")) {
      if ($releaseStackGithubStatusScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\check-release-stack-github-status.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("git merge", "git push", "gh pr merge", "gh api", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($releaseStackGithubStatusScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\check-release-stack-github-status.ps1 must remain read-only and must not include '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\RELEASE_BLOCKERS.md", "docs\\RELEASE_CHECKLIST.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("check-release-stack-github-status.ps1", "release stack GitHub status")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
        }
      }
    }
  }
}

$releaseMergeHandoffPath = Join-Path $root "config\\release-merge-handoff.seed.json"
if (Test-Path -LiteralPath $releaseMergeHandoffPath -PathType Leaf) {
  $releaseMergeHandoff = Get-Content -Raw -LiteralPath $releaseMergeHandoffPath | ConvertFrom-Json

  if ($releaseMergeHandoff.script -ne "scripts/prepare-release-merge-handoff.ps1") {
    $manifestErrors.Add("config\\release-merge-handoff.seed.json must point to scripts/prepare-release-merge-handoff.ps1")
  }

  if ($releaseMergeHandoff.default_output_dir -ne "build/release-merge-handoff") {
    $manifestErrors.Add("config\\release-merge-handoff.seed.json must keep default output under ignored build/release-merge-handoff")
  }

  foreach ($field in @("read_only", "no_merge", "no_git_push", "no_tag_creation", "no_github_release_publish", "writes_only_ignored_build_output", "requires_merge_order_summary", "requires_github_status_summary", "requires_tag_readiness_summary", "requires_publication_dry_run_summary", "requires_input_fingerprints", "requires_tag_readiness_input_fingerprints", "requires_tag_readiness_input_fingerprint_integrity", "requires_publication_dry_run_input_fingerprints", "requires_publication_dry_run_input_fingerprint_integrity", "requires_publication_dry_run_evidence_bundle_input_fingerprints", "requires_publication_dry_run_preflight_input_fingerprint_integrity", "requires_publication_dry_run_ruleset_report_input_fingerprint_integrity", "requires_publication_dry_run_ruleset_report_shape", "requires_publication_dry_run_ruleset_report_target", "requires_publication_dry_run_ruleset_report_ok_consistency", "requires_publication_dry_run_ruleset_report_checked_at", "requires_publication_dry_run_ruleset_report_freshness", "requires_publication_dry_run_ruleset_report_check_entry_shape", "requires_publication_dry_run_ruleset_report_required_status_checks", "requires_publication_dry_run_ruleset_report_covered_required_status_checks", "requires_publication_dry_run_evidence_bundle_preflight_artifact_fingerprints", "requires_source_only_summary_flags", "requires_canonical_build_input_roots", "requires_input_generated_at", "requires_input_generated_at_parseable", "requires_input_generated_at_freshness", "requires_input_schema_versions", "requires_read_only_input_summaries", "requires_input_stack_count_consistency", "requires_error_free_input_summaries", "requires_tag_readiness_blocker_absence_consistency", "requires_tag_readiness_blocker_evidence_fields", "requires_tag_readiness_latest_pr_consistency", "requires_blocker_inventory_latest_candidate_consistency", "requires_blocker_inventory_latest_pr_consistency", "requires_publication_dry_run_artifact_fingerprint_integrity", "requires_publication_dry_run_commit_sha_consistency", "requires_publication_dry_run_ref_commit_sha_consistency", "requires_latest_pr_url_consistency", "requires_expected_repository_pr_url_consistency", "requires_github_status_expected_pr_url_prefix_consistency", "requires_github_status_count_consistency", "requires_github_status_pull_request_entries", "requires_github_status_pr_sequence", "requires_github_status_pr_refs", "requires_github_status_pr_urls", "requires_github_status_pr_states", "requires_github_status_pr_checks", "requires_github_status_pr_check_trace")) {
    if ($releaseMergeHandoff.policy.$field -ne $true) {
      $manifestErrors.Add("config\\release-merge-handoff.seed.json policy.$field must remain true")
    }
  }

  if ($releaseMergeHandoff.inputs.merge_order -ne "build/release-merge-order/release-merge-order.json") {
    $manifestErrors.Add("config\\release-merge-handoff.seed.json must read the release merge order summary")
  }
  if ($releaseMergeHandoff.inputs.github_status -ne "build/release-stack-github-status/release-stack-github-status.json") {
    $manifestErrors.Add("config\\release-merge-handoff.seed.json must read the release stack GitHub status summary")
  }
  if ($releaseMergeHandoff.inputs.tag_readiness -notmatch "-tag-readiness\.json$") {
    $manifestErrors.Add("config\\release-merge-handoff.seed.json must read a source tag readiness summary")
  }
  if ($releaseMergeHandoff.inputs.publication_dry_run -notmatch "-publication-dry-run\.json$") {
    $manifestErrors.Add("config\\release-merge-handoff.seed.json must read a source publication dry-run summary")
  }
  $releaseBlockerInventoryPath = Join-Path $root "config\\release-blocker-inventory.seed.json"
  if (Test-Path -LiteralPath $releaseBlockerInventoryPath -PathType Leaf) {
    $releaseBlockerInventory = Get-Content -Raw -LiteralPath $releaseBlockerInventoryPath | ConvertFrom-Json
    $latestCandidate = [string]$releaseBlockerInventory.tracked_candidates.latest_candidate
    if (
      [string]::IsNullOrWhiteSpace($latestCandidate) -or
      $releaseMergeHandoff.inputs.tag_readiness.IndexOf($latestCandidate, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -or
      $releaseMergeHandoff.inputs.publication_dry_run.IndexOf($latestCandidate, [System.StringComparison]::OrdinalIgnoreCase) -lt 0
    ) {
      $manifestErrors.Add("config\\release-merge-handoff.seed.json inputs must track latest_candidate from config\\release-blocker-inventory.seed.json")
    }
  }
  $expectedMergeHandoffInputRoots = @{
    merge_order = "build/release-merge-order"
    github_status = "build/release-stack-github-status"
    tag_readiness = "build/source-tag-readiness"
    publication_dry_run = "build/source-release-publication"
  }
  foreach ($inputRootName in $expectedMergeHandoffInputRoots.Keys) {
    if ($releaseMergeHandoff.input_roots.$inputRootName -ne $expectedMergeHandoffInputRoots[$inputRootName]) {
      $manifestErrors.Add("config\\release-merge-handoff.seed.json input_roots.$inputRootName must stay under $($expectedMergeHandoffInputRoots[$inputRootName])")
    }
  }

  $releaseMergeHandoffScriptPath = Join-Path $root "scripts\\prepare-release-merge-handoff.ps1"
  if (Test-Path -LiteralPath $releaseMergeHandoffScriptPath -PathType Leaf) {
    $releaseMergeHandoffScript = Get-Content -Raw -LiteralPath $releaseMergeHandoffScriptPath
    foreach ($requiredPhrase in @("release-merge-handoff.seed.json", "release-stack-github-status.seed.json", "release-blocker-inventory.seed.json", "merge_order_ok", "github_status_ok", "publication_dry_run_ok", "ready_for_tag", "ready_for_manual_review", "windows_bundle_verifier_ok", "input_fingerprints", "tag_readiness_input_fingerprints", "tag readiness input fingerprints mismatch", "publication_dry_run_input_fingerprints", "publication dry-run input fingerprints mismatch", "publication_dry_run_evidence_bundle_input_fingerprints", "Assert-InputFingerprintIntegrity", "publication dry-run ruleset report input fingerprint mismatch", "publication dry-run ruleset report without schema_version 1", "publication dry-run ruleset report that is not read-only", "publication dry-run ruleset report without ok status", "publication dry-run ruleset report without checked_at timestamp", "publication dry-run stale ruleset report checked_at timestamp", "publication dry-run ruleset report repository mismatch", "publication dry-run ruleset report branch mismatch", "publication dry-run ruleset report ok status without checks", "publication dry-run ruleset report ok status with failed checks", "publication dry-run ruleset report check entry shape mismatch", "publication dry-run ruleset report required status checks mismatch", "publication dry-run ruleset report covered required status checks mismatch", "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints", "publication_dry_run_evidence_bundle_preflight_commit_sha", "publication_dry_run_evidence_bundle_preflight_ref_commit_sha", "tag readiness summary is missing input fingerprints", "publication dry-run summary is missing input fingerprints", "publication dry-run summary is missing evidence bundle input fingerprints", "publication dry-run preflight input fingerprint mismatch", "publication dry-run summary is missing evidence bundle preflight artifact fingerprints", "publication dry-run artifact fingerprints mismatch", "publication dry-run commit SHA mismatch", "publication dry-run ref commit SHA mismatch", "latest_pr_url", "expected_pr_url_prefix", "github_status_expected_pr_url_prefix", "github_status_counts", "github_status_pull_request_count", "github_status_pr_sequence", "github_status_pr_refs", "github_status_pr_urls", "github_status_pr_states", "github_status_pr_checks", "details_url", "workflow_name", "release stack GitHub status latest PR URL is missing", "release stack GitHub status latest PR URL mismatch", "release stack GitHub status latest PR URL repository mismatch", "release stack GitHub status expected PR URL prefix mismatch", "release stack GitHub status count mismatch", "release stack GitHub status pull request entries mismatch", "release stack GitHub status PR sequence mismatch", "release stack GitHub status PR refs mismatch", "release stack GitHub status PR URLs mismatch", "release stack GitHub status PR states mismatch", "release stack GitHub status PR checks mismatch", "release stack GitHub status PR check trace mismatch", "blocker_inventory_latest_candidate", "blocker_inventory_latest_pr", "input_generated_at", "must include parseable generated_at", "has stale generated_at", "input_schema_versions", "input_stack_counts", "input_error_count", "open_blocker_count", "tag readiness open blocker count mismatch", "tag readiness open blockers have invalid entries", "tag readiness open blockers are missing evidence fields", "tag readiness allows tag creation while blockers remain", "tag readiness denies tag creation without blockers", "tag readiness latest stacked PR mismatch", "release handoff latest candidate does not match blocker inventory", "release handoff latest PR does not match blocker inventory", "source_only = `$true", "no_apk = `$true", "no_exe = `$true", "no_store_release = `$true", "no_trusted_signing_claim = `$true", "Assert-BuildInputPath", "Assert-InputGeneratedAt", "Assert-InputSchemaVersion", "Assert-InputReadOnly", "input_roots", "SHA256", "ComputeHash", "handoff_ready_for_maintainer", "build\release-merge-handoff", "manual_merge_required = `$true")) {
      if ($releaseMergeHandoffScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\prepare-release-merge-handoff.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("git merge", "git push", "git tag", "gh pr merge", "gh release create", "gh release upload", "gh api", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($releaseMergeHandoffScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\prepare-release-merge-handoff.ps1 must remain read-only and must not include '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\RELEASE_BLOCKERS.md", "docs\\RELEASE_CHECKLIST.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("prepare-release-merge-handoff.ps1", "release merge handoff")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
        }
      }
    }
  }
}

$sourcePublicationPacketPath = Join-Path $root "config\\source-publication-packet.seed.json"
if (Test-Path -LiteralPath $sourcePublicationPacketPath -PathType Leaf) {
  $sourcePublicationPacket = Get-Content -Raw -LiteralPath $sourcePublicationPacketPath | ConvertFrom-Json

  if ($sourcePublicationPacket.script -ne "scripts/prepare-source-publication-packet.ps1") {
    $manifestErrors.Add("config\\source-publication-packet.seed.json must point to scripts/prepare-source-publication-packet.ps1")
  }

  if ($sourcePublicationPacket.default_output_dir -ne "build/source-publication-packet") {
    $manifestErrors.Add("config\\source-publication-packet.seed.json must keep default output under ignored build/source-publication-packet")
  }

  foreach ($field in @("read_only", "source_only", "manual_publish_only", "no_merge", "no_tag_creation", "no_tag_push", "no_github_release_publish", "no_asset_upload", "no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim", "requires_release_handoff_summary", "requires_publication_dry_run_summary", "requires_release_handoff_ready", "requires_publication_dry_run_ready", "requires_rendered_release_notes", "requires_proof_manifest", "requires_source_archive", "requires_release_evidence_bundle", "requires_clean_clone_or_import_proof", "requires_artifact_fingerprints", "requires_input_fingerprints", "requires_input_generated_at", "requires_input_generated_at_parseable", "requires_input_generated_at_freshness", "requires_release_handoff_publication_dry_run_input_fingerprint_integrity", "requires_publication_dry_run_carried_input_fingerprint_integrity", "requires_publication_dry_run_carried_artifact_fingerprint_integrity", "requires_publication_artifact_file_fingerprint_integrity", "requires_publication_artifact_root_boundaries", "requires_source_only_release_asset_allowlist", "requires_publication_artifact_file_extensions", "requires_publication_artifact_content_validation", "requires_source_only_flags", "writes_only_ignored_build_output")) {
    if ($sourcePublicationPacket.policy.$field -ne $true) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json policy.$field must remain true")
    }
  }

  if ($sourcePublicationPacket.inputs.release_handoff -ne "build/release-merge-handoff/release-merge-handoff.json") {
    $manifestErrors.Add("config\\source-publication-packet.seed.json must read the release merge handoff summary")
  }
  if ($sourcePublicationPacket.inputs.publication_dry_run -notmatch "-publication-dry-run\.json$") {
    $manifestErrors.Add("config\\source-publication-packet.seed.json must read a source publication dry-run summary")
  }

  $releaseBlockerInventoryPath = Join-Path $root "config\\release-blocker-inventory.seed.json"
  if (Test-Path -LiteralPath $releaseBlockerInventoryPath -PathType Leaf) {
    $releaseBlockerInventory = Get-Content -Raw -LiteralPath $releaseBlockerInventoryPath | ConvertFrom-Json
    $latestCandidate = [string]$releaseBlockerInventory.tracked_candidates.latest_candidate
    if (
      [string]::IsNullOrWhiteSpace($latestCandidate) -or
      $sourcePublicationPacket.inputs.publication_dry_run.IndexOf($latestCandidate, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -or
      $sourcePublicationPacket.output.packet.IndexOf($latestCandidate, [System.StringComparison]::OrdinalIgnoreCase) -lt 0
    ) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json inputs and output must track latest_candidate from config\\release-blocker-inventory.seed.json")
    }
  }

  $expectedPublicationPacketInputRoots = @{
    release_handoff = "build/release-merge-handoff"
    publication_dry_run = "build/source-release-publication"
  }
  foreach ($inputRootName in $expectedPublicationPacketInputRoots.Keys) {
    if ($sourcePublicationPacket.input_roots.$inputRootName -ne $expectedPublicationPacketInputRoots[$inputRootName]) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json input_roots.$inputRootName must stay under $($expectedPublicationPacketInputRoots[$inputRootName])")
    }
  }

  $expectedPublicationPacketArtifactRoots = @{
    release_notes = "build/source-release-preflight"
    release_evidence_bundle = "build/release-evidence"
    proof_manifest = "build/source-release-preflight"
    source_archive = "build/source-release-preflight"
    clean_clone_or_import_proof = "build/source-release-preflight"
    windows_bundle_verifier_summary = "build/windows-bundle-verifier"
    github_ruleset_report = "build/release-evidence"
  }
  foreach ($artifactRootName in $expectedPublicationPacketArtifactRoots.Keys) {
    if ($sourcePublicationPacket.artifact_roots.$artifactRootName -ne $expectedPublicationPacketArtifactRoots[$artifactRootName]) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json artifact_roots.$artifactRootName must stay under $($expectedPublicationPacketArtifactRoots[$artifactRootName])")
    }
  }

  $expectedPublicationPacketAllowedAssets = @("release_notes", "proof_manifest", "source_archive", "release_evidence_bundle", "clean_clone_or_import_proof", "windows_bundle_verifier_summary", "github_ruleset_report")
  if ((@($sourcePublicationPacket.allowed_release_assets) -join ",") -ne ($expectedPublicationPacketAllowedAssets -join ",")) {
    $manifestErrors.Add("config\\source-publication-packet.seed.json allowed_release_assets must stay source-only")
  }

  $expectedPublicationPacketArtifactFileExtensions = @{
    release_notes = ".md"
    release_evidence_bundle = ".json"
    proof_manifest = ".json"
    source_archive = ".zip"
    clean_clone_or_import_proof = ".json"
    windows_bundle_verifier_summary = ".json"
    github_ruleset_report = ".json"
  }
  foreach ($artifactExtensionName in $expectedPublicationPacketArtifactFileExtensions.Keys) {
    if ($sourcePublicationPacket.artifact_file_extensions.$artifactExtensionName -ne $expectedPublicationPacketArtifactFileExtensions[$artifactExtensionName]) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json artifact_file_extensions.$artifactExtensionName must stay $($expectedPublicationPacketArtifactFileExtensions[$artifactExtensionName])")
    }
  }

  $expectedPublicationPacketArtifactContentTypes = @{
    release_notes = "markdown"
    release_evidence_bundle = "json"
    proof_manifest = "json"
    source_archive = "zip"
    clean_clone_or_import_proof = "json"
    windows_bundle_verifier_summary = "json"
    github_ruleset_report = "json"
  }
  foreach ($artifactContentName in $expectedPublicationPacketArtifactContentTypes.Keys) {
    if ($sourcePublicationPacket.artifact_content_types.$artifactContentName -ne $expectedPublicationPacketArtifactContentTypes[$artifactContentName]) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json artifact_content_types.$artifactContentName must stay $($expectedPublicationPacketArtifactContentTypes[$artifactContentName])")
    }
  }

  foreach ($flag in @("source_only", "no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim")) {
    if (@($sourcePublicationPacket.required_source_only_flags) -notcontains $flag) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json must require source-only flag '$flag'")
    }
  }

  foreach ($artifact in @("release_notes", "proof_manifest", "source_archive", "release_evidence_bundle", "clean_clone_or_import_proof")) {
    if (@($sourcePublicationPacket.required_artifacts) -notcontains $artifact) {
      $manifestErrors.Add("config\\source-publication-packet.seed.json must require artifact '$artifact'")
    }
  }

  $sourcePublicationPacketScriptPath = Join-Path $root "scripts\\prepare-source-publication-packet.ps1"
  if (Test-Path -LiteralPath $sourcePublicationPacketScriptPath -PathType Leaf) {
    $sourcePublicationPacketScript = Get-Content -Raw -LiteralPath $sourcePublicationPacketScriptPath
    foreach ($requiredPhrase in @("source-publication-packet.seed.json", "release_handoff", "publication_dry_run", "handoff_ready_for_maintainer", "ready_for_manual_review", "packet_ready_for_manual_publish_review", "manual_publish_only", "asset_upload_performed = `$false", "release_notes", "proof_manifest", "source_archive", "release_evidence_bundle", "clean_clone_or_import_proof", "input_fingerprints", "input_generated_at", "must include generated_at timestamp", "must include parseable generated_at timestamp", "has stale generated_at timestamp", "release_handoff_publication_dry_run_input_fingerprints", "release handoff publication dry-run input", "handoff-carried publication dry-run", "artifact_file_fingerprints", "source publication packet artifact fingerprint mismatch", "fingerprint mismatch", "publication_dry_run_evidence_bundle_preflight_artifact_fingerprints", "artifact_roots", "source publication packet artifact path outside expected root", "allowed_release_assets", "source publication packet unexpected release asset fingerprint", "artifact_file_extensions", "source publication packet artifact file extension mismatch", "artifact_content_types", "source publication packet artifact content invalid", "ZipFile", "ConvertFrom-Json", "Test-PathUnderRoot", "Assert-BuildInputPath", "SHA256", "ComputeHash", "build\source-publication-packet")) {
      if ($sourcePublicationPacketScript.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        $manifestErrors.Add("scripts\\prepare-source-publication-packet.ps1 must include '$requiredPhrase'")
      }
    }
    foreach ($forbiddenPhrase in @("git merge", "git push", "git tag", "gh pr merge", "gh release create", "gh release upload", "gh api", "-X POST", "-X PATCH", "-X PUT", "-X DELETE")) {
      if ($sourcePublicationPacketScript.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $manifestErrors.Add("scripts\\prepare-source-publication-packet.ps1 must remain read-only and must not include '$forbiddenPhrase'")
      }
    }
  }

  foreach ($docPath in @("docs\\README.md", "docs\\RELEASE_BLOCKERS.md", "docs\\RELEASE_CHECKLIST.md", "scripts\\README.md")) {
    $fullDocPath = Join-Path $root $docPath
    if (Test-Path -LiteralPath $fullDocPath -PathType Leaf) {
      $docText = Get-Content -Raw -LiteralPath $fullDocPath
      foreach ($requiredPhrase in @("prepare-source-publication-packet.ps1", "source publication packet")) {
        if ($docText.IndexOf($requiredPhrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
          $manifestErrors.Add("$docPath must include '$requiredPhrase'")
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
  if ($sourceReadiness.policy.milestone_tags_must_be_unique -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must require unique milestone tags")
  }
  if ($sourceReadiness.policy.stacked_pr_milestone_evidence_must_be_canonical_pr_url -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must require stacked PR milestone evidence to use canonical PR URLs")
  }
  if ($sourceReadiness.policy.stacked_pr_milestone_evidence_urls_must_be_unique -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must require unique stacked PR milestone evidence URLs")
  }
  if ($sourceReadiness.policy.stacked_pr_milestone_evidence_pr_numbers_must_increase -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must require stacked PR milestone evidence PR numbers to increase")
  }
  if ($sourceReadiness.policy.stacked_pr_milestones_must_match_merge_order_stack -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must require stacked PR milestones to match release merge-order stack")
  }
  if ($sourceReadiness.policy.stacked_pr_milestones_must_be_covered_by_merge_order_stack -ne $true) {
    $manifestErrors.Add("config\\source-release-readiness.seed.json must require stacked PR milestones to be covered by release merge-order stack")
  }

  $releaseBlockerInventoryPath = Join-Path $root "config\\release-blocker-inventory.seed.json"
  if (Test-Path -LiteralPath $releaseBlockerInventoryPath -PathType Leaf) {
    $releaseBlockerInventory = Get-Content -Raw -LiteralPath $releaseBlockerInventoryPath | ConvertFrom-Json
    $baseCandidate = [string]$releaseBlockerInventory.tracked_candidates.base_candidate
    $latestCandidate = [string]$releaseBlockerInventory.tracked_candidates.latest_candidate
    $latestStackedPr = [int]$releaseBlockerInventory.tracked_candidates.latest_stacked_pr
    $coveredRange = [string]$releaseBlockerInventory.tracked_candidates.covered_range
    $expectedCoveredRange = "$baseCandidate through $latestCandidate"
    $expectedLatestEvidence = "https://github.com/Kiwunaka/Pokrov-client/pull/$latestStackedPr"
    $latestMilestone = @($sourceReadiness.milestones | Where-Object { $_.tag -eq $latestCandidate }) | Select-Object -First 1
    if ($coveredRange -ne $expectedCoveredRange) {
      $manifestErrors.Add("config\\release-blocker-inventory.seed.json covered_range must match base_candidate through latest_candidate")
    }
    if ($null -eq $latestMilestone) {
      $manifestErrors.Add("config\\source-release-readiness.seed.json must include latest_candidate from release blocker inventory")
    } elseif ([string]$latestMilestone.evidence -ne $expectedLatestEvidence) {
      $manifestErrors.Add("config\\source-release-readiness.seed.json latest_candidate evidence must match latest stacked PR URL")
    }
  }

  $sourceReadinessCanonicalPrPrefix = "https://github.com/Kiwunaka/Pokrov-client/pull/"
  $sourceReadinessTags = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  $sourceReadinessStackedEvidenceUrls = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  $sourceReadinessPreviousStackedPrNumber = 0
  $sourceReadinessMilestonesByTag = @{}
  foreach ($milestone in @($sourceReadiness.milestones)) {
    $milestoneTag = [string]$milestone.tag
    $milestoneStatus = [string]$milestone.status
    $milestoneEvidence = [string]$milestone.evidence
    $sourceReadinessMilestonesByTag[$milestoneTag] = $milestone
    if (-not $sourceReadinessTags.Add($milestoneTag)) {
      $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' tag must be unique")
    }
    if ($milestoneStatus.StartsWith("stacked_pr_", [System.StringComparison]::Ordinal)) {
      $sourceReadinessPrSuffix = ""
      if ($milestoneEvidence.StartsWith($sourceReadinessCanonicalPrPrefix, [System.StringComparison]::Ordinal)) {
        $sourceReadinessPrSuffix = $milestoneEvidence.Substring($sourceReadinessCanonicalPrPrefix.Length)
      }
      $sourceReadinessPrNumber = 0
      $sourceReadinessCanonicalPrEvidence = $true
      if (
        [string]::IsNullOrWhiteSpace($sourceReadinessPrSuffix) -or
        ([int]::TryParse($sourceReadinessPrSuffix, [ref]$sourceReadinessPrNumber) -ne $true) -or
        $sourceReadinessPrNumber -le 0 -or
        $sourceReadinessPrSuffix -ne ([string]$sourceReadinessPrNumber)
      ) {
        $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' stacked PR evidence must use canonical repository PR URL")
        $sourceReadinessCanonicalPrEvidence = $false
      }
      if ($sourceReadinessCanonicalPrEvidence) {
        if ($sourceReadinessPrNumber -le $sourceReadinessPreviousStackedPrNumber) {
          $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' stacked PR evidence PR number must increase")
        }
        $sourceReadinessPreviousStackedPrNumber = $sourceReadinessPrNumber
      }
    }
    if ($milestoneStatus.StartsWith("stacked_pr_", [System.StringComparison]::Ordinal) -and -not $sourceReadinessStackedEvidenceUrls.Add($milestoneEvidence)) {
      $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' stacked PR evidence URL must be unique")
    }
    if ($milestone.source_only -ne $true) {
      $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' must be source_only")
    }
    foreach ($field in @("ships_apk", "ships_exe", "store_release", "trusted_signing_claim")) {
      if ($milestone.$field -ne $false) {
        $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' must keep $field false")
      }
    }
    if ($milestoneStatus -ne "tagged" -and $milestoneStatus -notmatch "not_tagged") {
      $manifestErrors.Add("config\\source-release-readiness.seed.json pending milestone '$milestoneTag' must include not_tagged in status")
    }
  }

  $releaseMergeOrderPath = Join-Path $root "config\\release-merge-order.seed.json"
  if (Test-Path -LiteralPath $releaseMergeOrderPath -PathType Leaf) {
    $releaseMergeOrder = Get-Content -Raw -LiteralPath $releaseMergeOrderPath | ConvertFrom-Json
    $releaseMergeOrderPrNumbers = [System.Collections.Generic.HashSet[int]]::new()
    $releaseMergeOrderPrNumbersSorted = [System.Collections.Generic.List[int]]::new()
    foreach ($stackEntry in @($releaseMergeOrder.stack)) {
      $stackCandidate = [string]$stackEntry.candidate
      $stackPr = [int]$stackEntry.pr
      [void]$releaseMergeOrderPrNumbers.Add($stackPr)
      $releaseMergeOrderPrNumbersSorted.Add($stackPr)
      $expectedStackEvidence = "$sourceReadinessCanonicalPrPrefix$stackPr"
      $stackMilestone = $sourceReadinessMilestonesByTag[$stackCandidate]
      if ($null -eq $stackMilestone) {
        $manifestErrors.Add("config\\source-release-readiness.seed.json must include release merge-order candidate '$stackCandidate'")
      } elseif ([string]$stackMilestone.evidence -ne $expectedStackEvidence) {
        $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$stackCandidate' evidence must match release merge-order PR #$stackPr")
      }
    }
    if ($releaseMergeOrderPrNumbersSorted.Count -gt 0) {
      $releaseMergeOrderPrNumbersSorted.Sort()
      $releaseMergeOrderFirstPr = [int]$releaseMergeOrderPrNumbersSorted[0]
      $releaseMergeOrderLatestPr = [int]$releaseMergeOrderPrNumbersSorted[$releaseMergeOrderPrNumbersSorted.Count - 1]
      foreach ($milestone in @($sourceReadiness.milestones)) {
        $milestoneTag = [string]$milestone.tag
        $milestoneStatus = [string]$milestone.status
        $milestoneEvidence = [string]$milestone.evidence
        if (-not $milestoneStatus.StartsWith("stacked_pr_", [System.StringComparison]::Ordinal)) {
          continue
        }
        if (-not $milestoneEvidence.StartsWith($sourceReadinessCanonicalPrPrefix, [System.StringComparison]::Ordinal)) {
          continue
        }
        $sourceReadinessPrSuffix = $milestoneEvidence.Substring($sourceReadinessCanonicalPrPrefix.Length)
        $sourceReadinessPrNumber = 0
        if (
          ([int]::TryParse($sourceReadinessPrSuffix, [ref]$sourceReadinessPrNumber) -ne $true) -or
          $sourceReadinessPrNumber -lt $releaseMergeOrderFirstPr -or
          $sourceReadinessPrNumber -gt $releaseMergeOrderLatestPr
        ) {
          continue
        }
        if (-not $releaseMergeOrderPrNumbers.Contains($sourceReadinessPrNumber)) {
          $manifestErrors.Add("config\\source-release-readiness.seed.json milestone '$milestoneTag' stacked PR must be covered by release merge-order stack")
        }
      }
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
