# Связать телефон с ПК одной кнопкой: брандмауэр -> сервер LM Studio -> модель -> QR-код.
$Port  = 1235
$Model = 'ornith-1.5-35b-a3b'
$Ctx   = 8192
$Par   = 2

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
try { $Host.UI.RawUI.WindowTitle = 'Связать телефон с ПК' } catch {}
[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Step($t) { Write-Host ''; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)   { Write-Host $t -ForegroundColor Green }
function Warn($t) { Write-Host $t -ForegroundColor Yellow }
function Fail($t) {
  Write-Host ''; Write-Host "[!] $t" -ForegroundColor Red
  Read-Host 'Нажмите Enter, чтобы закрыть'; exit 1
}
function Get-Listen {
  Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
}
function Get-LoadedModels {
  try {
    $r = Invoke-RestMethod "http://127.0.0.1:$Port/api/v0/models" -TimeoutSec 5
    @($r.data | Where-Object { $_.state -eq 'loaded' -and ($_.type -eq 'llm' -or $_.type -eq 'vlm') } | ForEach-Object { $_.id })
  } catch { $null }
}

# --- lms ---
$lms = (Get-Command lms -ErrorAction SilentlyContinue).Source
if (-not $lms) {
  $p = Join-Path $env:USERPROFILE '.lmstudio\bin\lms.exe'
  if (Test-Path $p) { $lms = $p }
}
if (-not $lms) { Fail 'Не найдена программа lms. Откройте LM Studio один раз и запустите ярлык снова.' }

# --- 1. Брандмауэр ---
Step '1/4 Брандмауэр Windows'
$rule = "LM Studio $Port"
if (Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue) {
  Ok 'Порт уже открыт для домашней сети.'
} else {
  Warn 'Нужно один раз открыть порт. Windows спросит разрешение - нажмите «Да».'
  $cmd = "New-NetFirewallRule -DisplayName '$rule' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -Profile Private"
  try {
    Start-Process powershell -Verb RunAs -Wait -WindowStyle Hidden -ArgumentList "-NoProfile -Command $cmd"
  } catch { }
  if (Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue) { Ok 'Порт открыт.' }
  else { Warn 'Порт не открыт (разрешение не дано). Телефон может не увидеть ПК.' }
}
$net = Get-NetConnectionProfile -ErrorAction SilentlyContinue | Where-Object { $_.IPv4Connectivity -ne 'Disconnected' -and $_.InterfaceAlias -notmatch 'vEthernet|Tailscale|Clash|TUN|Loopback' }
foreach ($n in $net) {
  if ($n.NetworkCategory -eq 'Public') { Warn "Сеть «$($n.Name)» помечена как общественная - телефон её не пройдёт. В параметрах Wi-Fi выберите «Частная сеть»." }
}

# --- 2. Сервер ---
Step '2/4 Сервер LM Studio'
$open = Get-Listen | Where-Object { $_.LocalAddress -in @('0.0.0.0', '::') }
if ($open) {
  Ok "Сервер уже работает для домашней сети (порт $Port)."
} else {
  & $lms server stop 2>$null | Out-Null
  & $lms server start --port $Port --bind 0.0.0.0
  for ($i = 0; $i -lt 15 -and -not $open; $i++) {
    Start-Sleep -Seconds 1
    $open = Get-Listen | Where-Object { $_.LocalAddress -in @('0.0.0.0', '::') }
  }
  if (-not $open) {
    if (Get-Listen) { Fail 'Сервер слушает только этот компьютер. В LM Studio включите «Serve on Local Network» и запустите ярлык снова.' }
    Fail "Сервер не запустился на порту $Port. Проверьте, что LM Studio установлена, и запустите ярлык снова."
  }
  Ok "Сервер запущен для домашней сети (порт $Port)."
}

# --- 3. Модель ---
Step '3/4 Модель'
$loaded = Get-LoadedModels
if ($loaded -and ($loaded -contains $Model)) {
  Ok "Модель $Model уже загружена."
} elseif ($loaded -and $loaded.Count -gt 0) {
  Warn ("Загружена другая модель: " + ($loaded -join ', ') + ". Приложение будет использовать её.")
} else {
  Write-Host "Загружаю $Model (около минуты)..."
  & $lms load $Model -c $Ctx --parallel $Par -y
  $loaded = Get-LoadedModels
  if (-not $loaded) { Fail "Модель не загрузилась. Откройте LM Studio и проверьте, что модель $Model скачана." }
  Ok "Модель загружена: $($loaded -join ', ')"
}

# --- 4. QR-код ---
Step '4/4 QR-код для телефона'
$dart = (Get-Command dart -ErrorAction SilentlyContinue).Source
if (-not $dart) { Fail 'Не найден Dart/Flutter. QR-код не построить.' }
& $dart run tool/pair_pc.dart
if ($LASTEXITCODE -ne 0) { Fail 'Не удалось построить QR-код (подробности выше).' }

Write-Host ''
Ok 'Готово. В приложении на телефоне: Настройки -> «Подключить компьютер по QR-коду» -> навести камеру на QR.'
Write-Host 'Телефон должен быть в той же сети Wi-Fi. Окно можно закрыть - сервер продолжит работать.'
Read-Host 'Нажмите Enter, чтобы закрыть'
