# Создаёт ярлык «Связать телефон с ПК» на рабочем столе.
$desk = [Environment]::GetFolderPath('Desktop')
$lnk  = Join-Path $desk 'Связать телефон с ПК.lnk'
$ws = New-Object -ComObject WScript.Shell
$s = $ws.CreateShortcut($lnk)
$s.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
$s.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\connect_phone.ps1`""
$s.WorkingDirectory = Split-Path -Parent $PSScriptRoot
$s.IconLocation = "$env:WINDIR\System32\shell32.dll,15"
$s.Description = 'Запустить сервер LM Studio и показать QR-код для телефона'
$s.Save()
if (Test-Path $lnk) { Write-Host "Ярлык создан: $lnk" -ForegroundColor Green }
else { Write-Host 'Ярлык создать не удалось.' -ForegroundColor Red }
