param(
  [string]$Config = "config/white-label-color-tokens.seed.json",
  [string]$Out = "",
  [string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$argsList = @(
  "-m",
  "tools.white_label_tokens.export_color_tokens",
  "--config",
  $Config
)

if ($Out.Trim().Length -gt 0) {
  $argsList += @("--out", $Out)
}

Push-Location $repoRoot
try {
  & $Python @argsList
} finally {
  Pop-Location
}
