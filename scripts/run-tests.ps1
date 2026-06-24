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
  & (Join-Path $PSScriptRoot "run-android-native-tests.ps1")
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
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
