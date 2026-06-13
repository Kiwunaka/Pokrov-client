param(
  [ValidateSet("community", "operator", "pokrov")]
  [string]$Variant = "community",

  [ValidateSet("android", "windows")]
  [string]$Platform = "android",

  [ValidateSet("run", "build")]
  [string]$Action = "run",

  [switch]$Release
)

$root = Split-Path -Parent $PSScriptRoot
$arguments = @(
  "-m",
  "tools.variant_build.variant_command",
  "--variant",
  $Variant,
  "--platform",
  $Platform,
  "--action",
  $Action,
  "--root",
  $root
)

if ($Release) {
  $arguments += "--release"
}

Push-Location $root
try {
  python @arguments
} finally {
  Pop-Location
}
