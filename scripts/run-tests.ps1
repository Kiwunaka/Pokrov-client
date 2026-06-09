param(
  [switch]$OfflinePubGet,
  [switch]$RunAndroidGradle
)

$root = Split-Path -Parent $PSScriptRoot

$bootstrapArgs = @()
if ($OfflinePubGet) {
  $bootstrapArgs += "-OfflinePubGet"
}
& (Join-Path $PSScriptRoot "bootstrap-workspace.ps1") @bootstrapArgs
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

function Invoke-WorkspaceFlutterTests {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  Write-Host "Running flutter test in $RelativePath" -ForegroundColor Cyan
  Push-Location (Join-Path $root $RelativePath)
  try {
    flutter test
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  } finally {
    Pop-Location
  }
}

function Invoke-AndroidGradleUnitTests {
  $androidProjectPath = Join-Path $root "apps\android_shell\android"
  $gradleWrapper = Join-Path $androidProjectPath "gradlew.bat"
  $libcoreAar = Join-Path $androidProjectPath "app\libs\libcore.aar"

  if (-not (Test-Path $gradleWrapper)) {
    Write-Error "Android Gradle wrapper not found at $gradleWrapper"
    exit 1
  }

  if (-not (Test-Path -LiteralPath $libcoreAar)) {
    Write-Error "Android runtime artifact not found at $libcoreAar. Run scripts\fetch-libcore-assets.ps1 -Platforms @('android') -SyncToHosts before -RunAndroidGradle."
    exit 1
  }

  Write-Host "Running Android Gradle unit tests in apps\android_shell" -ForegroundColor Cyan
  Push-Location $androidProjectPath
  try {
    & $gradleWrapper testDebugUnitTest
    if ($LASTEXITCODE -ne 0) {
      exit $LASTEXITCODE
    }
  } finally {
    Pop-Location
  }
}

$flutterTestPackages = @(
  "packages\\app_shell",
  "packages\\runtime_engine",
  "apps\\android_shell",
  "apps\\windows_shell"
)

foreach ($relativePath in $flutterTestPackages) {
  Invoke-WorkspaceFlutterTests -RelativePath $relativePath
}

if ($RunAndroidGradle) {
  Invoke-AndroidGradleUnitTests
} else {
  Write-Host "Skipping Android Gradle unit tests. Pass -RunAndroidGradle after fetching runtime artifacts to enable them." -ForegroundColor Yellow
}

Write-Host "Workspace test lane completed." -ForegroundColor Green
