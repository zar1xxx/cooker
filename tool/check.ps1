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

# Ensure precompiled sqlite3 native asset is present for Windows tests without network dependency.
# The hook cache directory has a hash in its name, so find it by mask instead of hardcoding it.
$sqliteBuildRoot = Join-Path $root '.dart_tool\hooks_runner\shared\sqlite3\build'
$sqliteDllSource = 'tool\bin\sqlite3.x64.windows.dll'
if (Test-Path $sqliteDllSource) {
  $sqliteHookDirs = @(Get-ChildItem -Path (Join-Path $sqliteBuildRoot '*') -Directory -ErrorAction SilentlyContinue)
  if ($sqliteHookDirs.Count -eq 0) {
    Write-Host "NOTE: sqlite3 hook cache not found under $sqliteBuildRoot; tests may download the native library."
  } else {
    $targetDirs = @($sqliteHookDirs | Where-Object { Test-Path (Join-Path $_.FullName 'sqlite3.dll') })
    if ($targetDirs.Count -eq 0) {
      $targetDirs = @($sqliteHookDirs | Where-Object { $_.Name -like 'download-*' })
    }
    foreach ($dir in $targetDirs) {
      $targetDll = Join-Path $dir.FullName 'sqlite3.dll'
      if (!(Test-Path $targetDll)) {
        Copy-Item $sqliteDllSource $targetDll -Force
      }
    }
  }
}

# ASSUMPTION: run build_runner only if declared in pubspec.yaml (before S0-02 it is not present)
$hasBuildRunner = Select-String -Path 'pubspec.yaml' -Pattern 'build_runner' -Quiet
$steps = @(
  @{ name = 'pub get';      cmd = 'flutter pub get' },
  @{ name = 'gen-l10n';     cmd = 'flutter gen-l10n' }
)
if ($hasBuildRunner) {
  $steps += @{ name = 'build_runner'; cmd = 'dart run build_runner build' }
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
