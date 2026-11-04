# Runs all project checks. Exit code 0 = green.
# Usage: powershell -ExecutionPolicy Bypass -File tool\check.ps1 [-Apk]
param([switch]$Apk)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$log = Join-Path $root 'docs\reports\last_check.txt'
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
"check.ps1 started $(Get-Date -Format s)" | Out-File $log -Encoding utf8

# keep assets in sync with spec (schemas, prompts)
New-Item -ItemType Directory -Force -Path 'assets\ai\schemas','assets\ai\prompts' | Out-Null
Copy-Item 'spec\ai\schemas\*.json' 'assets\ai\schemas\' -Force
Copy-Item 'spec\ai\prompts\*.md' 'assets\ai\prompts\' -Force
Copy-Item 'spec\ai\safety_minimums.json' 'assets\ai\' -Force
if (Test-Path 'test') {
  New-Item -ItemType Directory -Force -Path 'test\fixtures\ai' | Out-Null
  Copy-Item 'spec\fixtures\ai\*' 'test\fixtures\ai\' -Force
}

# ASSUMPTION: run build_runner only if declared in pubspec.yaml (before S0-02 it is not present)
$hasBuildRunner = Select-String -Path 'pubspec.yaml' -Pattern 'build_runner' -Quiet
$steps = @(
  @{ name = 'pub get';      cmd = 'flutter pub get' }
)
if ($hasBuildRunner) {
  $steps += @{ name = 'build_runner'; cmd = 'dart run build_runner build --delete-conflicting-outputs' }
}
$steps += @(
  @{ name = 'format';       cmd = 'dart format --output=none --set-exit-if-changed lib test' },
  @{ name = 'analyze';      cmd = 'flutter analyze' },
  @{ name = 'test';         cmd = 'flutter test' }
)
if ($Apk) { $steps += @{ name = 'build apk'; cmd = 'flutter build apk --debug' } }

function Log-Text($text) {
  Write-Host $text
  $text | Out-File -FilePath $log -Append -Encoding utf8
}

$failed = @()
foreach ($s in $steps) {
  Log-Text "`n===== $($s.name): $($s.cmd) ====="
  $out = cmd /c "$($s.cmd) 2>&1"
  $code = $LASTEXITCODE
  Log-Text ($out -join "`n")
  Log-Text "----- exit code: $code"
  if ($code -ne 0) { $failed += $s.name }
}

if ($failed.Count -eq 0) {
  Log-Text "`nRESULT: GREEN ($(Get-Date -Format s))"
  exit 0
} else {
  Log-Text "`nRESULT: RED - failed: $($failed -join ', ') ($(Get-Date -Format s))"
  exit 1
}
